class ApiConstants {
  // Deployed Live Render Server Base URL
  static const String baseUrl = 'https://camera-first-expense-tracker.onrender.com/api';
  
  // Auth
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';

  // Expenses
  static const String expenses = '/expenses';
  static String expenseById(String id) => '$expenses/$id';

  // User Profile
  static const String uploadProfileImage = '/user/profile/image';
  static const String userProfile = '/user/profile';
}
