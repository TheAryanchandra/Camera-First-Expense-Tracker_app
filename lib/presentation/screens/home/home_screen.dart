import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/expense_model.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy expenses for now until BLoC is fully connected
    final expenses = [
      ExpenseModel(
        id: '1',
        amount: 25.0,
        category: 'Food',
        note: 'Lunch at Cafe',
        date: DateTime.now(),
        synced: false,
      ),
      ExpenseModel(
        id: '2',
        amount: 50.0,
        category: 'Travel',
        note: 'Gas station',
        date: DateTime.now().subtract(const Duration(days: 1)),
        synced: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              // Trigger sync
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Column(
                  children: [
                    Text('Today'),
                    Text('\$25.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                Column(
                  children: [
                    Text('This Week'),
                    Text('\$150.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      expense.category == 'Food' ? Icons.fastfood : Icons.directions_car,
                    ),
                  ),
                  title: Text(expense.note),
                  subtitle: Text('${expense.category} • ${DateFormat.yMMMd().format(expense.date)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${expense.amount.toStringAsFixed(2)}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Icon(
                        expense.synced ? Icons.cloud_done : Icons.cloud_off,
                        size: 14,
                        color: expense.synced ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to detail
                    context.push('/expense/${expense.id}', extra: expense);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
