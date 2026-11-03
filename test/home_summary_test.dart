import 'package:costing_master/client/notifier/home_summary.dart';
import 'package:costing_master/model/costing.dart';
import 'package:flutter_test/flutter_test.dart';

Costing _costing(String guid, String client, DateTime? savedAt) =>
    Costing.fromMap({
      'guid': guid,
      'createdBy': '',
      'clientGuid': client,
      'updatedAt': savedAt?.millisecondsSinceEpoch,
    });

void main() {
  final now = DateTime(2026, 10, 26, 12);

  test('summarises counts, this month, recency and per-client stats', () {
    final summary = HomeSummary.of([
      _costing('old', 'a', DateTime(2026, 9, 30)),
      _costing('new', 'a', DateTime(2026, 10, 25)),
      _costing('mid', 'b', DateTime(2026, 10, 1)),
      _costing('legacy', 'b', null),
    ], now: now);

    expect(summary.total, 4);
    expect(summary.thisMonth, 2);
    expect([for (final c in summary.recent) c.guid],
        ['new', 'mid', 'old', 'legacy']);
    expect(summary.byClient['a']!.count, 2);
    expect(summary.byClient['a']!.lastUpdated, DateTime(2026, 10, 25));
    expect(summary.byClient['b']!.lastUpdated, DateTime(2026, 10, 1));
  });

  test('keeps only the latest costings in the recent strip', () {
    final summary = HomeSummary.of([
      for (var day = 1; day <= 12; day++)
        _costing('d$day', 'a', DateTime(2026, 10, day)),
    ], now: now);

    expect(summary.recent, hasLength(HomeSummary.recentLimit));
    expect(summary.recent.first.guid, 'd12');
  });
}
