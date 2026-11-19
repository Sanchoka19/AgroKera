import 'package:flutter/foundation.dart';

/// Structured delivery date and time slots option for a farmer's schedule.
@immutable
class DeliveryDateSchedule {
  final DateTime date;
  final String weekdayName;
  final String dayMonthFormatted;
  final List<String> timeSlots;

  const DeliveryDateSchedule({
    required this.date,
    required this.weekdayName,
    required this.dayMonthFormatted,
    this.timeSlots = const ['10:00 - 13:00', '14:00 - 18:00'],
  });

  /// Short tab label, e.g. "შაბათი, 22 ნოემ"
  String get tabLabel => '$weekdayName, $dayMonthFormatted';

  /// Full formatted slot string, e.g. "შაბათი, 22 ნოემბერი, 10:00 - 13:00"
  String fullSlotString(String timeSlot) => '$weekdayName, $dayMonthFormatted, $timeSlot';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryDateSchedule &&
          runtimeType == other.runtimeType &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          weekdayName == other.weekdayName;

  @override
  int get hashCode => Object.hash(date.year, date.month, date.day, weekdayName);
}

