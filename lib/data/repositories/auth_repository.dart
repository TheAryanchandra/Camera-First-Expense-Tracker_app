import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token to Hive
      var box = Hive.box('authBox');
      await box.put('token', authResponse.token);
      
      return authResponse;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }

  Future<AuthResponse> signup(String email, String password) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.signup,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token to Hive
      var box = Hive.box('authBox');
      await box.put('token', authResponse.token);
      
      return authResponse;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Signup failed');
    }
  }
  
  Future<void> logout() async {
    var box = Hive.box('authBox');
    await box.delete('token');
  }
  
  bool isLoggedIn() {
    var box = Hive.box('authBox');
    return box.containsKey('token');
  }
}
