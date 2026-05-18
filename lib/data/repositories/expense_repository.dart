import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/expense_model.dart';
import 'package:path/path.dart';

class ExpenseRepository {
  final DioClient _dioClient;

  ExpenseRepository(this._dioClient);

  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.expenses);
      final List<dynamic> data = response.data;
      return data.map((json) => ExpenseModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch expenses');
    }
  }

  Future<ExpenseModel> createExpense({
    required double amount,
    required String category,
    required String date,
    required String note,
    required File receiptImage,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'amount': amount,
        'category': category,
        'date': date,
        'notes': note,
        'receipt': await MultipartFile.fromFile(
          receiptImage.path,
          filename: basename(receiptImage.path),
        ),
      });

      final response = await _dioClient.dio.post(
        ApiConstants.expenses,
        data: formData,
      );

      return ExpenseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create expense');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _dioClient.dio.delete('${ApiConstants.expenses}/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete expense');
    }
  }
}
