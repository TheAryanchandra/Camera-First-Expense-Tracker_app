import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/dio_error_parser.dart';
import '../../core/constants/api_constants.dart';
import '../models/expense_model.dart';
import 'package:path/path.dart';

class ExpenseRepository {
  final DioClient _dioClient;

  ExpenseRepository(this._dioClient);

  Future<List<ExpenseModel>> getExpenses() async {
    try {
      print('=== EXPENSE REPOSITORY: GET EXPENSES REQUEST ===');
      final response = await _dioClient.dio.get(ApiConstants.expenses);
      
      print('=== EXPENSE REPOSITORY: GET EXPENSES RESPONSE DATA ===');
      print(response.data);

      final payload = response.data;
      final dynamic data;

      if (payload is List) {
        data = payload;
      } else if (payload is Map<String, dynamic>) {
        data = payload['expenses'] ?? payload['data'] ?? payload['items'] ?? <dynamic>[];
      } else {
        data = <dynamic>[];
      }

      final expenseList = data is List ? data : <dynamic>[];
      return expenseList
          .whereType<Map<String, dynamic>>()
          .map(ExpenseModel.fromJson)
          .toList();
    } catch (e) {
      throw Exception(DioErrorParser.parse(e));
    }
  }

  Future<ExpenseActionResult> createExpense({
    required double amount,
    required String category,
    required String date,
    required String note,
    File? receiptImage,
  }) async {
    try {
      final Map<String, dynamic> fields = {
        'amount': amount,
        'category': category,
        'date': date,
        'notes': note,
      };

      if (receiptImage != null) {
        fields['receiptImage'] = await MultipartFile.fromFile(
          receiptImage.path,
          filename: basename(receiptImage.path),
        );
      }

      print('=== EXPENSE REPOSITORY: CREATE EXPENSE REQUEST PAYLOAD ===');
      print(fields);

      FormData formData = FormData.fromMap(fields);

      final response = await _dioClient.dio.post(
        ApiConstants.expenses,
        data: formData,
      );

      print('=== EXPENSE REPOSITORY: CREATE EXPENSE RESPONSE DATA ===');
      print(response.data);

      final payload = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final expenseJson = _extractExpenseJson(payload);

      return ExpenseActionResult(
        expense: ExpenseModel.fromJson(expenseJson),
        message: (payload['message'] ?? 'Expense created successfully').toString(),
      );
    } catch (e) {
      throw Exception(DioErrorParser.parse(e));
    }
  }

  Future<String> deleteExpense(String id) async {
    try {
      print('=== EXPENSE REPOSITORY: DELETE EXPENSE REQUEST FOR ID: $id ===');
      final response = await _dioClient.dio.delete('${ApiConstants.expenses}/$id');
      
      print('=== EXPENSE REPOSITORY: DELETE EXPENSE RESPONSE DATA ===');
      print(response.data);

      final payload = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return (payload['message'] ?? 'Expense deleted successfully').toString();
    } catch (e) {
      throw Exception(DioErrorParser.parse(e));
    }
  }

  Map<String, dynamic> _extractExpenseJson(Map<String, dynamic> payload) {
    final nestedExpense = payload['expense'];
    if (nestedExpense is Map<String, dynamic>) {
      return nestedExpense;
    }

    final nestedData = payload['data'];
    if (nestedData is Map<String, dynamic>) {
      if (nestedData['expense'] is Map<String, dynamic>) {
        return nestedData['expense'] as Map<String, dynamic>;
      }
      return nestedData;
    }

    return payload;
  }
}

class ExpenseActionResult {
  final ExpenseModel expense;
  final String message;

  const ExpenseActionResult({
    required this.expense,
    required this.message,
  });
}
