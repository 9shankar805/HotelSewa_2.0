class EarningsData {
  final DateTime date;
  final double amount;

  EarningsData({required this.date, required this.amount});

  factory EarningsData.fromJson(Map<String, dynamic> j) => EarningsData(
        date: j['date'] != null
            ? DateTime.tryParse(j['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'amount': amount,
      };
}

class Transaction {
  final String id;
  final String type;
  final String status;
  final double amount;
  final String description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id']?.toString() ?? '',
        type: j['type'] as String? ?? '',
        status: j['status'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        description: j['description'] as String? ?? j['desc'] as String? ?? '',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'status': status,
        'amount': amount,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };
}
