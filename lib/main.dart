import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/network/dio_client.dart';
import 'data/models/expense_model.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'logic/auth_bloc/auth_bloc.dart';
import 'logic/expense_bloc/expense_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  
  // Register Adapters
  Hive.registerAdapter(ExpenseModelAdapter()); 
  
  // Open Boxes
  await Hive.openBox<ExpenseModel>('expensesBox');

  // Setup Dependencies
  final dioClient = DioClient();
  final authRepository = AuthRepository(dioClient);
  final expenseRepository = ExpenseRepository(dioClient);

  runApp(ExpenseTrackerApp(
    authRepository: authRepository,
    expenseRepository: expenseRepository,
  ));
}

class ExpenseTrackerApp extends StatelessWidget {
  final AuthRepository authRepository;
  final ExpenseRepository expenseRepository;

  const ExpenseTrackerApp({
    super.key,
    required this.authRepository,
    required this.expenseRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(authRepository)..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => ExpenseBloc(expenseRepository)..add(LoadExpenses()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Expense Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
