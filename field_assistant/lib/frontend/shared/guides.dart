import 'package:flutter/services.dart';

/// Which crop a guide is about, from its file name (coffee_leaf_rust.md → coffee).
enum GuideCrop { coffee, maize, beans, more }

/// One part of a guide: "Symptoms", "Management, part 1", … and where it comes from.
class GuideSection {
  const GuideSection({required this.heading, required this.text, required this.sources});
  final String heading, text;

  /// The paragraph's "(Source: …)" note, e.g. "KALRO; Wikipedia". Empty if none.
  final String sources;
}

/// One topic from the sourced guides in assets/knowledge/: the same files the
/// assistant answers from, shown as they are so the farmer (and the judges)
/// can see where answers come from. No models needed.
class Guide {
  const Guide({
    required this.title,
    required this.summary,
    required this.sections,
    required this.source,
    required this.crop,
  });
  final String title, summary, source;
  final List<GuideSection> sections;
  final GuideCrop crop;

  /// All the text, for search.
  String get text => [title, summary, for (final s in sections) '${s.heading} ${s.text}'].join(' ');
}

/// Reads every .md/.txt in assets/knowledge/ (one topic per file).
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

final _sourceNote = RegExp(r'\s*\(Sources?:\s*([^)]*)\)\s*$');

/// The knowledge files look like (see KNOWLEDGE_SOURCES.md):
///
///     Coffee leaf rust: what it is, how to recognise it, …      ← title: summary
///
///     Coffee leaf rust symptoms: look at the underside … (Source: KALRO)
///
/// so a file is one guide whose paragraphs become sections ("Symptoms").
/// A file with `## ` headings gives one guide per heading instead.
List<Guide> parseGuides(String text, String source) {
  final crop = _crop(source);
  if (RegExp(r'^## ', multiLine: true).hasMatch(text)) {
    return [
      for (final part in text.split(RegExp(r'^## ', multiLine: true)).skip(1))
        if (part.trim().isNotEmpty)
          _guide(part.split('\n').first.trim(), '', _paragraphs(part.split('\n').skip(1).join('\n')), source, crop),
    ];
  }
  final paras = _paragraphs(text).where((p) => !p.startsWith('SAMPLE CONTENT')).toList();
  if (paras.isEmpty) return const [];
  // A short first line without a source note is the file's "title: what it covers".
  final first = paras.first;
  final colon = first.indexOf(':');
  if (colon > 0 && colon <= 80 && first.length < 240 && !_sourceNote.hasMatch(first)) {
    return [_guide(first.substring(0, colon).trim(), first.substring(colon + 1).trim(), paras.skip(1), source, crop)];
  }
  return [_guide(_titleFromFile(source), '', paras, source, crop)];
}

Guide _guide(String title, String summary, Iterable<String> paras, String source, GuideCrop crop) => Guide(
      title: title,
      summary: summary,
      source: source,
      crop: crop,
      sections: [for (final p in paras) _section(p, title)],
    );

GuideSection _section(String p, String title) {
  final note = _sourceNote.firstMatch(p);
  final body = note == null ? p : p.substring(0, note.start).trim();
  final colon = body.indexOf(':');
  if (colon <= 0 || colon > 70) return GuideSection(heading: '', text: body, sources: note?.group(1)?.trim() ?? '');
  // "Coffee leaf rust symptoms: …" → "Symptoms" (the guide's title is already on screen).
  var heading = body.substring(0, colon).trim();
  if (heading.toLowerCase().startsWith(title.toLowerCase())) {
    heading = heading.substring(title.length).trim().replaceFirst(RegExp(r'^(and|,)\s*'), '');
  }
  if (heading.isNotEmpty) heading = heading[0].toUpperCase() + heading.substring(1);
  return GuideSection(heading: heading, text: body.substring(colon + 1).trim(), sources: note?.group(1)?.trim() ?? '');
}

Iterable<String> _paragraphs(String text) =>
    text.split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty);

GuideCrop _crop(String file) => file.startsWith('coffee')
    ? GuideCrop.coffee
    : file.startsWith('maize')
        ? GuideCrop.maize
        : file.startsWith('bean')
            ? GuideCrop.beans
            : GuideCrop.more;

String _titleFromFile(String file) {
  final name = file.replaceAll(RegExp(r'\.(md|txt)$'), '').replaceAll('_', ' ');
  return name.isEmpty ? file : name[0].toUpperCase() + name.substring(1);
}
