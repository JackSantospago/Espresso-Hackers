import 'package:flutter/services.dart';

/// One readable topic from the sourced guides in assets/knowledge/: the same
/// files the assistant answers from, shown as they are so the farmer (and the
/// judges) can see where answers come from. No models needed.
class Guide {
  const Guide({required this.title, required this.text, required this.source});
  final String title, text, source;
}

/// Reads every .md/.txt in assets/knowledge/. A file with `## ` headings gives
/// one guide per heading; otherwise each paragraph is a guide, titled by its
/// lead-in ("Managing coffee leaf rust: …"), its subject ("Coffee leaf rust is …")
/// or its first sentence.
Future<List<Guide>> loadGuides([AssetBundle? bundle]) async {
  final b = bundle ?? rootBundle;
  final manifest = await AssetManifest.loadFromAssetBundle(b);
  final files = manifest
      .listAssets()
      .where((a) => a.startsWith('assets/knowledge/') && (a.endsWith('.md') || a.endsWith('.txt')))
      .toList()
    ..sort();
  final out = <Guide>[];
  for (final f in files) {
    out.addAll(parseGuides(await b.loadString(f), f.split('/').last));
  }
  return out;
}

List<Guide> parseGuides(String text, String source) {
  if (RegExp(r'^## ', multiLine: true).hasMatch(text)) {
    return [
      for (final part in text.split(RegExp(r'^## ', multiLine: true)).skip(1))
        if (part.trim().isNotEmpty)
          Guide(
            title: part.split('\n').first.trim(),
            text: part.split('\n').skip(1).join('\n').trim(),
            source: source,
          ),
    ];
  }
  return [
    for (final p in text.split(RegExp(r'\n\s*\n')).map((p) => p.trim()))
      // Skip empty paragraphs and the "SAMPLE CONTENT" banner of placeholder files.
      if (p.isNotEmpty && !p.startsWith('SAMPLE CONTENT')) Guide(title: _title(p), text: p, source: source),
  ];
}

String _title(String p) {
  final colon = p.indexOf(':');
  if (colon > 0 && colon <= 60) return p.substring(0, colon);
  // "Coffee leaf rust is caused by …" -> "Coffee leaf rust"
  final subject = RegExp(r'^(.{3,40}?) (is|are) ').firstMatch(p);
  if (subject != null) return subject.group(1)!;
  final dot = p.indexOf('. ');
  final first = dot > 0 ? p.substring(0, dot) : p;
  return first.length <= 60 ? first : '${first.substring(0, 57).trimRight()}…';
}
