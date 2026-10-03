import '../../services/brain.dart';
import '../../services/outbox.dart';

/// What the My farm and Officer screens read and change. The default just
/// forwards to [Brain] and [Outbox]; `main_preview.dart` swaps in fake data so
/// the UI runs in a browser without models or plugins.
class FarmData {
  const FarmData();

  Future<List<MemoryItem>> memories() => Brain.memories();
  Future<void> forget(String id) => Brain.forget(id);

  Future<List<OutboxItem>> outbox() => Outbox.items();
  Future<SendReport> sendPending() => Outbox.sendPending();
  Future<void> removeFromOutbox(OutboxItem item) => Outbox.remove(item);
}
