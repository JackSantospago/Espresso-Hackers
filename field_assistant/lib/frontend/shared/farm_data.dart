import '../../core/strings.dart';
import '../../services/brain.dart';
import '../../services/outbox.dart';
import 'guides.dart';

/// What the Grow screens read and change. The default just
/// forwards to [Brain] and [Outbox]; `main_preview.dart` swaps in fake data so
/// the UI runs in a browser without models or plugins.
class FarmData {
  const FarmData();

  Future<List<MemoryItem>> memories() => Brain.memories();
  Future<void> forget(String id) => Brain.forget(id);

  /// A fact the farmer typed in herself ("Add a note"); same memory the chat uses.
  Future<void> remember(String fact) => Brain.remember(fact);

  /// The sourced guides on the phone in [language] (read straight from assets, no models).
  Future<List<Guide>> guides([AppLanguage language = AppLanguage.en]) => loadGuides(null, language);

  Future<List<OutboxItem>> outbox() => Outbox.items();
  Future<SendReport> sendPending() => Outbox.sendPending();
  Future<void> removeFromOutbox(OutboxItem item) => Outbox.remove(item);
}
