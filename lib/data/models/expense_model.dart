import 'package:hive/hive.dart';
import 'dart:convert';

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
    return ExpenseModel(
      id: json['_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      note: json['notes'] ?? '', // Based on backend 'notes'
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      imageUrl: json['receiptUrl'],
      synced: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'amount': amount,
      'category': category,
      'notes': note,
      'date': date.toIso8601String(),
      'receiptUrl': imageUrl,
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
