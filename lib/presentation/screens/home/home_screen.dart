import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/expense_model.dart';
import '../../../logic/expense_bloc/expense_bloc.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ExpenseModel> _cachedExpenses = const [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshExpenses() async {
    FocusScope.of(context).unfocus();
    context.read<ExpenseBloc>().add(LoadExpenses());
  }

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
                _refreshExpenses();
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(86),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by category or note',
                hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                suffixIcon: _searchQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppTheme.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppTheme.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseLoaded) {
            setState(() {
              _cachedExpenses = state.expenses;
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is ExpenseLoading;
          final hasCachedData = _cachedExpenses.isNotEmpty;
          final loadedExpenses = state is ExpenseLoaded ? state.expenses : null;

          if (state is ExpenseError && !hasCachedData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 52, color: Colors.redAccent.withOpacity(0.8)),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load expenses',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _refreshExpenses,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (isLoading && !hasCachedData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (!hasCachedData && loadedExpenses == null) {
            return const SizedBox.shrink();
          }

          final expenses = _sortExpenses(hasCachedData ? _cachedExpenses : loadedExpenses!);
          final filteredExpenses = _filterExpenses(expenses, _searchQuery);
          final now = DateTime.now();
          final todayTotal = expenses
              .where((expense) => _isSameDay(expense.date, now))
              .fold(0.0, (sum, expense) => sum + expense.amount);
          final weekTotal = expenses
              .where((expense) => _isWithinCurrentWeek(expense.date, now))
              .fold(0.0, (sum, expense) => sum + expense.amount);
          final monthTotal = expenses
              .where((expense) => expense.date.year == now.year && expense.date.month == now.month)
              .fold(0.0, (sum, expense) => sum + expense.amount);

          return Stack(
            children: [
              GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _refreshExpenses,
                  child: CustomScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Spending Summary',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Track your spending at a glance and find receipts quickly.',
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildSummaryCard('Today', todayTotal, AppTheme.primary, Colors.white),
                                    const SizedBox(width: 12),
                                    _buildSummaryCard('This Week', weekTotal, Colors.white, AppTheme.textPrimary),
                                    const SizedBox(width: 12),
                                    _buildSummaryCard('This Month', monthTotal, Colors.white, AppTheme.textPrimary),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _searchQuery.trim().isEmpty ? 'Recent Transactions' : 'Search Results',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${filteredExpenses.length} result${filteredExpenses.length == 1 ? '' : 's'}',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      if (expenses.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(
                            icon: Icons.receipt_long_rounded,
                            title: 'No expenses yet',
                            subtitle: 'Tap the camera button to add your first expense.',
                          ),
                        )
                      else if (filteredExpenses.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No matching expenses',
                            subtitle: 'Try a different note or category keyword.',
                            actionLabel: 'Clear Search',
                            onAction: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final expense = filteredExpenses[index];
                              return _buildExpenseTile(context, expense);
                            },
                            childCount: filteredExpenses.length,
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading && hasCachedData)
                Positioned(
                  top: 12,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Refreshing',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<ExpenseModel> _sortExpenses(List<ExpenseModel> expenses) {
    final sorted = List<ExpenseModel>.from(expenses);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  List<ExpenseModel> _filterExpenses(List<ExpenseModel> expenses, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return expenses;
    }

    return expenses.where((expense) {
      final category = expense.category.toLowerCase();
      final note = expense.note.toLowerCase();
      return category.contains(normalizedQuery) || note.contains(normalizedQuery);
    }).toList();
  }

  bool _isSameDay(DateTime value, DateTime reference) {
    return value.year == reference.year &&
        value.month == reference.month &&
        value.day == reference.day;
  }

  bool _isWithinCurrentWeek(DateTime value, DateTime reference) {
    final startOfWeek = DateTime(reference.year, reference.month, reference.day)
        .subtract(Duration(days: reference.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return !value.isBefore(startOfWeek) && value.isBefore(endOfWeek);
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color backgroundColor, Color textColor) {
    final isPrimary = backgroundColor == AppTheme.primary;
    return Container(
      width: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: isPrimary ? null : Border.all(color: AppTheme.inputBorder),
        boxShadow: [
          BoxShadow(
            color: isPrimary ? AppTheme.primary.withOpacity(0.28) : Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: isPrimary ? Colors.white.withOpacity(0.85) : AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 26,
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
