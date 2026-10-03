import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'config.dart';
import 'leaf_classifier.dart';

/// One photo the farmer chose to send to an extension officer.
class OutboxItem {
  OutboxItem({
    required this.id,
    required this.created,
    required this.note,
    required this.modelGuess,
    required this.photo,
    this.sentAt,
  });

  final String id;
  final DateTime created;
  final String note;

  /// What the phone's classifier thought (label, probability, top-3) — or null.
  final Map<String, dynamic>? modelGuess;
  final File photo;
  DateTime? sentAt;

  bool get sent => sentAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'created': created.toIso8601String(),
        'note': note,
        'model_guess': modelGuess,
        'sent_at': sentAt?.toIso8601String(),
      };
}

/// Store-and-forward queue: photos are saved on the phone (shrunk to ~60 KB)
/// and uploaded the next time there is signal. Only what the farmer agreed to
/// is stored: the leaf photo, her note and the app's guess. No name, no GPS.
class Outbox {
  static Future<Directory> _dir() async {
    final d = Directory('${(await getApplicationDocumentsDirectory()).path}/outbox');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<List<OutboxItem>> items() async {
    final d = await _dir();
    final out = <OutboxItem>[];
    await for (final f in d.list()) {
      if (f is! File || !f.path.endsWith('.json')) continue;
      try {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        out.add(OutboxItem(
          id: j['id'] as String,
          created: DateTime.parse(j['created'] as String),
          note: j['note'] as String? ?? '',
          modelGuess: j['model_guess'] as Map<String, dynamic>?,
          photo: File('${d.path}/${j['id']}.jpg'),
          sentAt: j['sent_at'] == null ? null : DateTime.parse(j['sent_at'] as String),
        ));
      } catch (_) {/* skip a corrupt entry */}
    }
    out.sort((a, b) => b.created.compareTo(a.created));
    return out;
  }

  static Future<int> pendingCount() async => (await items()).where((i) => !i.sent).length;

  static Future<OutboxItem> add({required Uint8List photo, required String note, Diagnosis? diagnosis}) async {
    final d = await _dir();
    final id = 'p${DateTime.now().millisecondsSinceEpoch}';
    final small = await _shrinkInBackground(photo);
    final file = File('${d.path}/$id.jpg');
    await file.writeAsBytes(small, flush: true);
    final item = OutboxItem(
      id: id,
      created: DateTime.now(),
      note: note,
      modelGuess: diagnosis?.toJson(),
      photo: file,
    );
    await _save(item);
    return item;
  }

  static Future<void> _save(OutboxItem item) async {
    final d = await _dir();
    await File('${d.path}/${item.id}.json').writeAsString(jsonEncode(item.toJson()), flush: true);
  }

  static Future<void> remove(OutboxItem item) async {
    final d = await _dir();
    for (final f in [item.photo, File('${d.path}/${item.id}.json')]) {
      if (await f.exists()) await f.delete();
    }
  }

  static Future<Uint8List> _shrinkInBackground(Uint8List bytes) => Isolate.run(() => _shrink(bytes));

  /// Longest side 640 px, JPEG quality 75: small enough for a 3G bundle.
  static Uint8List _shrink(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    var im = img.bakeOrientation(decoded);
    if (im.width > 640 || im.height > 640) {
      im = im.width >= im.height
          ? img.copyResize(im, width: 640, interpolation: img.Interpolation.average)
          : img.copyResize(im, height: 640, interpolation: img.Interpolation.average);
    }
    return img.encodeJpg(im, quality: 75);
  }

  /// Uploads every unsent item. Safe to call any time: offline it just fails
  /// quietly and the items wait for the next try. Returns a short status line.
  static Future<String> sendPending() async {
    final pending = (await items()).where((i) => !i.sent).toList();
    if (pending.isEmpty) return 'Nothing waiting to send.';
    if (kOutboxUrl.isEmpty) {
      return 'No review server set in this build (run with --dart-define=OUTBOX_URL=…). '
          '${pending.length} photo(s) stay safely on the phone.';
    }
    var sent = 0;
    for (final item in pending) {
      try {
        final req = http.MultipartRequest('POST', Uri.parse(kOutboxUrl))
          ..fields['id'] = item.id
          ..fields['created'] = item.created.toIso8601String()
          ..fields['note'] = item.note
          ..fields['model_guess'] = jsonEncode(item.modelGuess)
          ..files.add(await http.MultipartFile.fromPath('photo', item.photo.path));
        final res = await req.send().timeout(const Duration(seconds: 30));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          item.sentAt = DateTime.now();
          await _save(item);
          sent++;
        }
      } catch (_) {
        break; // no signal — stop and try again later
      }
    }
    final left = pending.length - sent;
    return sent == 0
        ? 'No connection. ${pending.length} photo(s) will be sent when there is signal.'
        : 'Sent $sent photo(s).${left > 0 ? ' $left still waiting.' : ''}';
  }
}

/// The farmer can see everything queued, send it now, or delete it before it goes.
class OutboxPage extends StatefulWidget {
  const OutboxPage({super.key});
  @override
  State<OutboxPage> createState() => _OutboxPageState();
}

class _OutboxPageState extends State<OutboxPage> {
  List<OutboxItem> _items = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final items = await Outbox.items();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _sendNow() async {
    setState(() => _sending = true);
    final msg = await Outbox.sendPending();
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _items.where((i) => !i.sent).length;
    return Scaffold(
      appBar: AppBar(title: const Text('For the extension officer')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'These photos are sent to your extension officer for review the next time the phone has signal. '
              'Only the leaf photo, your note and the app\'s guess are sent — no name or location. '
              'Delete any photo you do not want to send.',
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Nothing saved.'))
                : ListView(
                    children: [
                      for (final item in _items)
                        ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(item.photo, width: 56, height: 56, fit: BoxFit.cover),
                          ),
                          title: Text(item.note.isEmpty ? '(no note)' : item.note, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${item.created.toLocal().toString().substring(0, 16)} · '
                            '${item.sent ? 'sent' : 'waiting for signal'}'
                            '${item.modelGuess == null ? '' : ' · app guess: ${item.modelGuess!['label']}'}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await Outbox.remove(item);
                              await _refresh();
                            },
                          ),
                        ),
                    ],
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: pending == 0 || _sending ? null : _sendNow,
                icon: _sending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(pending == 0 ? 'Nothing to send' : 'Send $pending now'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
