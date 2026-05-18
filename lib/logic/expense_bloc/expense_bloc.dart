import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/models/expense_model.dart';

// --- Events ---
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
  final File receiptImage;

  const AddExpense({
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.receiptImage,
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

// --- States ---
abstract class ExpenseState extends Equatable {
  const ExpenseState();
  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}
class ExpenseLoading extends ExpenseState {}
class ExpenseLoaded extends ExpenseState {
  final List<ExpenseModel> expenses;
  const ExpenseLoaded(this.expenses);
  @override
  List<Object?> get props => [expenses];
}
class ExpenseError extends ExpenseState {
  final String message;
  const ExpenseError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseBloc(this._repository) : super(ExpenseInitial()) {
    on<LoadExpenses>((event, emit) async {
      emit(ExpenseLoading());
      try {
        final expenses = await _repository.getExpenses();
        emit(ExpenseLoaded(expenses));
      } catch (e) {
        emit(ExpenseError(e.toString()));
      }
    });

    on<AddExpense>((event, emit) async {
      if (state is ExpenseLoaded) {
        final currentExpenses = (state as ExpenseLoaded).expenses;
        try {
          final newExpense = await _repository.createExpense(
            amount: event.amount,
            category: event.category,
            note: event.note,
            date: event.date,
            receiptImage: event.receiptImage,
          );
          emit(ExpenseLoaded([newExpense, ...currentExpenses]));
        } catch (e) {
          emit(ExpenseError(e.toString()));
          // Still emit old state so UI doesn't break entirely
          emit(ExpenseLoaded(currentExpenses));
        }
      }
    });

    on<DeleteExpense>((event, emit) async {
      if (state is ExpenseLoaded) {
        final currentExpenses = (state as ExpenseLoaded).expenses;
        try {
          await _repository.deleteExpense(event.id);
          final updated = currentExpenses.where((e) => e.id != event.id).toList();
          emit(ExpenseLoaded(updated));
        } catch (e) {
          emit(ExpenseError(e.toString()));
          emit(ExpenseLoaded(currentExpenses));
        }
      }
    });
  }
}
