import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/home/main_layout.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/expense/capture_screen.dart';
import '../../presentation/screens/expense/expense_form_screen.dart';
import '../../presentation/screens/expense/expense_detail_screen.dart';
import '../../data/models/expense_model.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) => const CaptureScreen(),
      ),
      GoRoute(
        path: '/expense-form',
        builder: (context, state) {
          final imagePath = state.extra as String;
          return ExpenseFormScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: '/expense/:id',
        builder: (context, state) {
          final expense = state.extra as ExpenseModel;
          return ExpenseDetailScreen(expense: expense);
        },
      ),
    ],
  );
}
