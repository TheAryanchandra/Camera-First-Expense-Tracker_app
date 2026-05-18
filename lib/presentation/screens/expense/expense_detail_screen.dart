import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/expense_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_toast.dart';
import '../../../logic/expense_bloc/expense_bloc.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ExpenseBloc>().add(DeleteExpense(expense.id));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
          title: const Text('Expense Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/expense/${expense.id}/edit', extra: expense);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (expense.imageUrl != null && expense.imageUrl!.isNotEmpty)
                InteractiveViewer(
                  panEnabled: false,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: expense.imageUrl!.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: expense.imageUrl!,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : Image.file(
                          File(expense.imageUrl!),
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 100),
                        ),
                )
              else
                Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.image_not_supported, size: 50)),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        Chip(
                          label: Text(expense.category),
                          avatar: const Icon(Icons.category, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(DateFormat.yMMMd().format(expense.date)),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notes),
                      title: const Text('Note'),
                      subtitle: Text(expense.note.isNotEmpty ? expense.note : 'No note added'),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        expense.synced ? Icons.cloud_done : Icons.cloud_off,
                        color: expense.synced ? Colors.green : Colors.grey,
                      ),
                      title: const Text('Sync Status'),
                      subtitle: Text(expense.synced ? 'Synced with server' : 'Pending sync'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
