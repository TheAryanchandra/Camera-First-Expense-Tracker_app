class ApiConstants {
  // Use 10.0.2.2 for Android emulator to connect to localhost, or your actual local IP
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // Auth
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';

  // Expenses
  static const String expenses = '/expenses';
}
