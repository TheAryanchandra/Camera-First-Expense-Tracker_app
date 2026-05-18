import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/expense_model.dart';
import '../../../logic/expense_bloc/expense_bloc.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Overview',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.sync_rounded, color: AppTheme.primary),
              onPressed: () {
                context.read<ExpenseBloc>().add(LoadExpenses());
              },
            ),
          ),
        ],
      ),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          } else if (state is ExpenseError) {
            return Center(
              child: Text(
                'Error loading expenses:\n${state.message}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.redAccent),
              ),
            );
          } else if (state is ExpenseLoaded) {
            final expenses = state.expenses;
            
            // Calculate totals
            final today = DateTime.now();
            final todayTotal = expenses
                .where((e) => e.date.year == today.year && e.date.month == today.month && e.date.day == today.day)
                .fold(0.0, (sum, e) => sum + e.amount);
                
            final weekTotal = expenses
                .where((e) => e.date.isAfter(today.subtract(const Duration(days: 7))))
                .fold(0.0, (sum, e) => sum + e.amount);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Custom Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard('Today', todayTotal, true),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryCard('This Week', weekTotal, false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Recent Transactions',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (expenses.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No expenses yet. Tap the camera to add one!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = expenses[index];
                        return _buildExpenseTile(context, expense);
                      },
                      childCount: expenses.length,
                    ),
                  ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? AppTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isPrimary ? AppTheme.primary.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: isPrimary ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              color: isPrimary ? Colors.white : AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(BuildContext context, ExpenseModel expense) {
    IconData categoryIcon = Icons.receipt_long;
    Color categoryColor = Colors.grey;

    switch (expense.category.toLowerCase()) {
      case 'food':
        categoryIcon = Icons.fastfood_rounded;
        categoryColor = Colors.orange;
        break;
      case 'travel':
        categoryIcon = Icons.flight_takeoff_rounded;
        categoryColor = Colors.blue;
        break;
      case 'shopping':
        categoryIcon = Icons.shopping_bag_rounded;
        categoryColor = Colors.purple;
        break;
      case 'utilities':
        categoryIcon = Icons.bolt_rounded;
        categoryColor = Colors.amber;
        break;
      case 'health':
        categoryIcon = Icons.medical_services_rounded;
        categoryColor = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(categoryIcon, color: categoryColor),
        ),
        title: Text(
          expense.note.isNotEmpty ? expense.note : expense.category,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            DateFormat.yMMMd().format(expense.date),
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '-₹${expense.amount.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  expense.synced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  size: 14,
                  color: expense.synced ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  expense.synced ? 'Synced' : 'Pending',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: expense.synced ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          context.push('/expense/${expense.id}', extra: expense);
        },
      ),
    );
  }
}
