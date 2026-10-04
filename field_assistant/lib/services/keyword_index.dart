import 'dart:math' as math;

/// One knowledge passage as stored in the index.
class Passage {
  const Passage(this.id, this.source, this.text);
  final String id, source, text;
}

/// A passage picked by [fuseRankings]; [similarity] is the embedding score,
/// or null when only the keyword search found it.
class Fused {
  const Fused(this.passage, this.similarity);
  final Passage passage;
  final double? similarity;
}

/// Tiny BM25 keyword search over the knowledge passages, run fully on the
/// phone. Embeddings blur rare but decisive words ("iron", "lime", "purple"),
/// so a passage that names them can lose to one that merely shares the crop;
/// this list catches those passages and [fuseRankings] merges both lists.
class KeywordIndex {
  KeywordIndex(this.passages) {
    for (final p in passages) {
      final t = tokenize(p.text);
      _tokens.add(t);
      _totalLen += t.length;
      for (final w in t.toSet()) {
        _df[w] = (_df[w] ?? 0) + 1;
      }
    }
  }

  final List<Passage> passages;
  final _tokens = <List<String>>[];
  final _df = <String, int>{};
  var _totalLen = 0;

  static const _stop = {
    'the', 'and', 'for', 'with', 'that', 'this', 'what', 'how', 'can', 'are', 'you', 'your', 'from',
    'have', 'has', 'but', 'not', 'all', 'any', 'its', 'into', 'out', 'who', 'why', 'when', 'where',
    'which', 'here', 'there', 'lot', 'lots', 'much', 'many', 'some', 'about', 'our', 'around', 'them',
    'they', 'their', 'will', 'would', 'should', 'could', 'does', 'did', 'also', 'very', 'just', 'don',
    'get', 'was', 'were', 'been', 'being', 'than', 'then', 'too', 'use',
  };

  /// Lowercase words of 3+ letters, stop words dropped, a plural "s" trimmed.
  static List<String> tokenize(String text) {
    final out = <String>[];
    for (final m in RegExp(r'[a-zà-ÿ]+').allMatches(text.toLowerCase())) {
      var w = m.group(0)!;
      if (w.length < 3 || _stop.contains(w)) continue;
      if (w.length > 4 && w.endsWith('s') && !w.endsWith('ss')) w = w.substring(0, w.length - 1);
      out.add(w);
    }
    return out;
  }

  /// The best [k] passages for [query], best first (only those sharing a word).
  List<Passage> search(String query, {int k = 12}) {
    if (passages.isEmpty) return [];
    final q = tokenize(query).toSet();
    final n = passages.length;
    final avg = _totalLen / n;
    const k1 = 1.2, lengthNorm = 0.75;
    final scored = <(double, int)>[];
    for (var i = 0; i < n; i++) {
      final t = _tokens[i];
      var s = 0.0;
      for (final w in q) {
        final tf = t.where((x) => x == w).length;
        if (tf == 0) continue;
        final df = _df[w]!;
        final idf = math.log(1 + (n - df + 0.5) / (df + 0.5));
        s += idf * tf * (k1 + 1) / (tf + k1 * (1 - lengthNorm + lengthNorm * t.length / avg));
      }
      if (s > 0) scored.add((s, i));
    }
    scored.sort((x, y) => y.$1.compareTo(x.$1));
    return [for (final x in scored.take(k)) passages[x.$2]];
  }
}

/// Merges the embedding ranking and the keyword ranking (reciprocal rank
/// fusion), then keeps at most [perSource] passages per guide so one crop's
/// guides cannot fill every slot. Returns up to [k] passages, best first.
List<Fused> fuseRankings({
  required List<(Passage, double)> semantic,
  required List<Passage> keyword,
  int k = 4,
  int perSource = 2,
  int rrfK = 60,
}) {
  final score = <String, double>{};
  final byId = <String, Passage>{};
  final sim = <String, double>{};
  for (var r = 0; r < semantic.length; r++) {
    final (p, s) = semantic[r];
    byId[p.id] = p;
    sim[p.id] = s;
    score[p.id] = (score[p.id] ?? 0) + 1 / (rrfK + r + 1);
  }
  for (var r = 0; r < keyword.length; r++) {
    final p = keyword[r];
    byId.putIfAbsent(p.id, () => p);
    score[p.id] = (score[p.id] ?? 0) + 1 / (rrfK + r + 1);
  }
  final ids = score.keys.toList()..sort((a, b) => score[b]!.compareTo(score[a]!));
  final perGuide = <String, int>{};
  final out = <Fused>[];
  for (final id in ids) {
    final p = byId[id]!;
    if ((perGuide[p.source] ?? 0) >= perSource) continue;
    perGuide[p.source] = (perGuide[p.source] ?? 0) + 1;
    out.add(Fused(p, sim[id]));
    if (out.length == k) break;
  }
  return out;
}
