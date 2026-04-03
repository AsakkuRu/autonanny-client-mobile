import 'package:flutter_test/flutter_test.dart';
import 'package:nanny_client/utils/active_trip_order_filter.dart';

void main() {
  test('selectActiveOrderFromList excludes cancelled and completed statuses', () {
    final raw = [
      {'id_order': 1, 'id_status': 3, 'token': 'a'},
      {'id_order': 2, 'id_status': 11, 'token': 'b'},
      {'id_order': 3, 'id_status': 4, 'token': 'c'},
    ];
    final pick = selectActiveOrderFromList(raw);
    expect(pick!['id_order'], 3);
    expect(pick['token'], 'c');
  });

  test('selectActiveOrderFromList returns null when only terminal orders', () {
    final raw = [
      {'id_order': 1, 'id_status': 3, 'token': 'a'},
    ];
    expect(selectActiveOrderFromList(raw), isNull);
  });

  test('isTerminalTripInvalidationEvent', () {
    expect(isTerminalTripInvalidationEvent('trip.cancelled'), true);
    expect(isTerminalTripInvalidationEvent('order.expired'), true);
    expect(isTerminalTripInvalidationEvent('trip.status_changed'), false);
    expect(isTerminalTripInvalidationEvent(null), false);
  });
}
