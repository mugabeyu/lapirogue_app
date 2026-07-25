import 'package:intl/intl.dart';

/// Shared formatting so the same value never renders two different ways.
///
/// Amounts were previously grouped by a hand-written regex in some screens
/// and left ungrouped in others, and the currency was written as both "MUR"
/// and "Rs" depending on the file.

final NumberFormat _wholeMoney = NumberFormat.decimalPattern('en');

/// `Rs 12,500`. Rounded to whole rupees, which is how the hotel quotes.
String formatMoney(num amount) => 'Rs ${_wholeMoney.format(amount.round())}';

/// `12 Aug 2026`
String formatDate(DateTime date) => DateFormat('d MMM yyyy').format(date);

/// `Wed, 12 Aug`
String formatDayAndDate(DateTime date) => DateFormat('EEE, d MMM').format(date);

/// `14:30`
String formatTime(DateTime date) => DateFormat('HH:mm').format(date);

/// `3 nights` / `1 night`
String formatNights(int nights) => '$nights ${nights == 1 ? 'night' : 'nights'}';

/// `2 adults, 1 child`
String formatOccupancy(int adults, int children) {
  final parts = <String>[
    '$adults ${adults == 1 ? 'adult' : 'adults'}',
    if (children > 0) '$children ${children == 1 ? 'child' : 'children'}',
  ];
  return parts.join(', ');
}

/// Turns `CHECKED_IN` into `Checked in` for display.
String humanizeStatus(String status) {
  final cleaned = status.replaceAll('_', ' ').toLowerCase().trim();
  if (cleaned.isEmpty) return status;
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}
