/// One charge that already happened. Logged automatically when a
/// subscription's billing date passes. Kept even if the subscription is removed.
class Payment {
  final String id;
  final String subscriptionId;
  final String name;
  final double amount;
  final String currency;
  final DateTime date;
  final int colorValue;

  const Payment({
    required this.id,
    required this.subscriptionId,
    required this.name,
    required this.amount,
    required this.currency,
    required this.date,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subscriptionId': subscriptionId,
        'name': name,
        'amount': amount,
        'currency': currency,
        'date': date.toIso8601String(),
        'colorValue': colorValue,
      };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String,
        subscriptionId: j['subscriptionId'] as String,
        name: j['name'] as String,
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] as String? ?? 'USD',
        date: DateTime.parse(j['date'] as String),
        colorValue: j['colorValue'] as int? ?? 0xFF607D8B,
      );
}
