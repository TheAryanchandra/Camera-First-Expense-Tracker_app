import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {}

class AddExpense extends ExpenseEvent {
  final double amount;
  final String category;
  final String note;
  final String date;
  final File? receiptImage;

  const AddExpense({
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    this.receiptImage,
  });

  @override
  List<Object?> get props => [amount, category, note, date, receiptImage];
}

class DeleteExpense extends ExpenseEvent {
  final String id;

  const DeleteExpense(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateExpense extends ExpenseEvent {
  final String id;
  final double amount;
  final String category;
  final String note;
  final String date;

  const UpdateExpense({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  @override
  List<Object?> get props => [id, amount, category, note, date];
}
