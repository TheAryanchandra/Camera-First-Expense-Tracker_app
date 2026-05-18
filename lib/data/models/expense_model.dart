import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String note;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String? imageUrl; // Server URL or local file path

  @HiveField(6)
  final bool synced;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    this.imageUrl,
    this.synced = true,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final amountValue = json['amount'];

    return ExpenseModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      amount: amountValue is num
          ? amountValue.toDouble()
          : double.tryParse(amountValue?.toString() ?? '') ?? 0,
      category: (json['category'] ?? '').toString(),
      note: (json['note'] ?? json['notes'] ?? '').toString(),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      imageUrl: (json['receiptImage'] ??
              json['receiptUrl'] ??
              json['imageUrl'] ??
              json['receiptImageUrl'])
          ?.toString(),
      synced: json['synced'] is bool ? json['synced'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'receiptImage': imageUrl,
      'synced': synced,
    };
  }

  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    String? imageUrl,
    bool? synced,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      synced: synced ?? this.synced,
    );
  }
}
