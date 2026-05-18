import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import 'expense_event.dart';
import 'expense_state.dart';

export 'expense_event.dart';
export 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseBloc(this._repository) : super(ExpenseInitial()) {
    on<LoadExpenses>((event, emit) async {
      emit(ExpenseLoading());
      try {
        final expenses = await _repository.getExpenses();
        emit(ExpenseLoaded(expenses));
      } catch (e) {
        emit(ExpenseError(e.toString().replaceAll('Exception: ', '')));
      }
    });

    on<AddExpense>((event, emit) async {
      final currentExpenses = state is ExpenseLoaded
          ? (state as ExpenseLoaded).expenses
          : <ExpenseModel>[];

      emit(ExpenseLoading());
      try {
        final result = await _repository.createExpense(
          amount: event.amount,
          category: event.category,
          note: event.note,
          date: event.date,
          receiptImage: event.receiptImage,
        );
        emit(ExpenseActionSuccess([result.expense, ...currentExpenses], result.message));
      } catch (e) {
        emit(ExpenseError(e.toString().replaceAll('Exception: ', '')));
        emit(ExpenseLoaded(currentExpenses));
      }
    });

    on<DeleteExpense>((event, emit) async {
      final currentExpenses = state is ExpenseLoaded
          ? (state as ExpenseLoaded).expenses
          : <ExpenseModel>[];

      emit(ExpenseLoading());
      try {
        final message = await _repository.deleteExpense(event.id);
        final updated = currentExpenses.where((e) => e.id != event.id).toList();
        emit(ExpenseActionSuccess(updated, message));
      } catch (e) {
        emit(ExpenseError(e.toString().replaceAll('Exception: ', '')));
        emit(ExpenseLoaded(currentExpenses));
      }
    });
  }
}
