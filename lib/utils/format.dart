const currencies = [
  'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'INR', 'BDT', 'PKR', 'AED', 'SAR',
  'JPY', 'SGD', 'MYR', 'NGN', 'BRL', 'TRY', 'ZAR', 'MXN', 'IDR', 'PHP',
];

const _symbols = {
  'USD': '\$', 'EUR': '€', 'GBP': '£', 'CAD': 'C\$', 'AUD': 'A\$',
  'INR': '₹', 'BDT': '৳', 'PKR': 'Rs ', 'AED': 'AED ', 'SAR': 'SAR ',
  'JPY': '¥', 'SGD': 'S\$', 'MYR': 'RM', 'NGN': '₦', 'BRL': 'R\$',
  'TRY': '₺', 'ZAR': 'R', 'MXN': 'MX\$', 'IDR': 'Rp', 'PHP': '₱',
};

const _noDecimals = {'JPY', 'IDR'};

String formatMoney(double value, String currency) {
  final fixed = value.toStringAsFixed(_noDecimals.contains(currency) ? 0 : 2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  final number = parts.length > 1 ? '$buf.${parts[1]}' : buf.toString();
  final symbol = _symbols[currency] ?? '$currency ';
  return '$symbol$number';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Sun, Nov 16"
String formatDayDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';

const _fullMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String formatMonthYear(DateTime d) => '${_fullMonths[d.month - 1]} ${d.year}';

/// "$12.99 + ৳500.00" for totals in more than one currency.
String formatTotals(Map<String, double> totals) {
  if (totals.isEmpty) return formatMoney(0, 'USD');
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.map((e) => formatMoney(e.value, e.key)).join(' + ');
}

String relativeDays(int days) {
  if (days < 0) return 'overdue';
  if (days == 0) return 'today';
  if (days == 1) return 'tomorrow';
  return 'in $days days';
}

/// Reads a typed price: "9.99", "9,99", "1,200", "1,299.50", "1 200".
/// Returns null if it is not a sensible price.
double? parsePrice(String input) {
  var t = input.trim().replaceAll(RegExp(r'[\s\u00A0]'), '');
  if (t.isEmpty) return null;
  final hasDot = t.contains('.');
  final hasComma = t.contains(',');
  if (hasDot && hasComma) {
    // The last one is the decimal mark: "1,299.50" or "1.299,50".
    if (t.lastIndexOf(',') > t.lastIndexOf('.')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else {
      t = t.replaceAll(',', '');
    }
  } else if (hasComma) {
    // "1,200" = thousands; "9,99" = decimal.
    final after = t.substring(t.lastIndexOf(',') + 1);
    final commas = ','.allMatches(t).length;
    t = (after.length == 3 || commas > 1)
        ? t.replaceAll(',', '')
        : t.replaceAll(',', '.');
  }
  final v = double.tryParse(t);
  if (v == null || !v.isFinite || v < 0 || v > 100000000) return null;
  return v;
}

/// Turns "netflix.com/cancel" into a full https link. null if it can't be one.
Uri? webLink(String input) {
  final t = input.trim();
  if (t.isEmpty || t.contains(' ')) return null;
  final uri = Uri.tryParse(t.startsWith(RegExp(r'https?://', caseSensitive: false))
      ? t
      : 'https://$t');
  if (uri == null || !uri.host.contains('.')) return null;
  return uri;
}
