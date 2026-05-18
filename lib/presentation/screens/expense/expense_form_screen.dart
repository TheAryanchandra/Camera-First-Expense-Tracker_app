import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_toast.dart';
import '../../../logic/expense_bloc/expense_bloc.dart';
import '../../../data/models/expense_model.dart';

class ExpenseFormScreen extends StatefulWidget {
  final String imagePath;
  final ExpenseModel? expense;

  const ExpenseFormScreen({
    super.key,
    this.imagePath = '',
    this.expense,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Food',
    'Travel',
    'Utilities',
    'Shopping',
    'Health',
    'Other'
  ];

  bool get _isEditMode => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense != null) {
      _amountController.text = expense.amount.toStringAsFixed(2);
      _noteController.text = expense.note;
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      CustomToast.show(
        context,
        message: 'Please enter a valid amount',
        isError: true,
      );
      return;
    }

    final event = _isEditMode
        ? UpdateExpense(
            id: widget.expense!.id,
            amount: amount,
            category: _selectedCategory,
            note: _noteController.text.trim(),
            date: _selectedDate.toUtc().toIso8601String(),
          )
        : AddExpense(
            amount: amount,
            category: _selectedCategory,
            note: _noteController.text.trim(),
            date: _selectedDate.toUtc().toIso8601String(),
            receiptImage: widget.imagePath.isEmpty ? null : File(widget.imagePath),
          );

    context.read<ExpenseBloc>().add(event);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseActionSuccess) {
          context.go('/home');
          CustomToast.show(
            context,
            message: state.message,
          );
        } else if (state is ExpenseError) {
          CustomToast.show(
            context,
            message: state.message,
            isError: true,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Expense' : 'Add Details'),
        ),
        body: BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, state) {
            final isSaving = state is ExpenseLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isEditMode || widget.imagePath.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildExpenseImage(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: isSaving
                        ? null
                        : (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: isSaving ? null : () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat.yMMMd().format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: _isEditMode ? 'Update Expense' : 'Save Expense',
                    isLoading: isSaving,
                    onPressed: isSaving ? null : _saveExpense,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpenseImage() {
    if (!_isEditMode && widget.imagePath.isNotEmpty) {
      return Image.file(
        File(widget.imagePath),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final imageUrl = widget.expense?.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => _imageFallback(),
        );
      }

      return Image.file(
        File(imageUrl),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(),
      );
    }

    return _imageFallback();
  }

  Widget _imageFallback() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: const Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey),
    );
  }
}
