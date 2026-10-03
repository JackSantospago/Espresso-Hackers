import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../core/config.dart';
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
  /// quietly and the items wait for the next try.
  static Future<SendReport> sendPending() async {
    final pending = (await items()).where((i) => !i.sent).toList();
    if (pending.isEmpty) return const SendReport(sent: 0, waiting: 0);
    if (kOutboxUrl.isEmpty) return SendReport(sent: 0, waiting: pending.length, noServer: true);
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
    return SendReport(sent: sent, waiting: pending.length - sent);
  }
}

/// Result of one [Outbox.sendPending] attempt (the UI words it for the farmer).
class SendReport {
  const SendReport({required this.sent, required this.waiting, this.noServer = false});
  final int sent, waiting;

  /// No OUTBOX_URL in this build: photos stay on the phone (demo mode).
  final bool noServer;
}
