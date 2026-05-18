import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/dio_error_parser.dart';
import '../../core/constants/api_constants.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final payload = {
        'email': email,
        'password': password,
      };
      print('=== AUTH REPOSITORY: LOGIN REQUEST PAYLOAD ===');
      print(payload);

      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: payload,
      );
      
      print('=== AUTH REPOSITORY: LOGIN RESPONSE DATA ===');
      print(response.data);
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token and email details to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', authResponse.token);
      await prefs.setString('user_email', authResponse.user.email);
      await prefs.setString('user_id', authResponse.user.id);
      
      return authResponse;
    } catch (e) {
      throw Exception(DioErrorParser.parse(e));
    }
  }

  Future<AuthResponse> signup(String email, String password) async {
    try {
      final payload = {
        'email': email,
        'password': password,
      };
      print('=== AUTH REPOSITORY: SIGNUP REQUEST PAYLOAD ===');
      print(payload);

      final response = await _dioClient.dio.post(
        ApiConstants.signup,
        data: payload,
      );
      
      print('=== AUTH REPOSITORY: SIGNUP RESPONSE DATA ===');
      print(response.data);
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token and email details to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', authResponse.token);
      await prefs.setString('user_email', authResponse.user.email);
      await prefs.setString('user_id', authResponse.user.id);
      
      return authResponse;
    } catch (e) {
      throw Exception(DioErrorParser.parse(e));
    }
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
    await prefs.remove('user_id');
  }
  
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }
}
