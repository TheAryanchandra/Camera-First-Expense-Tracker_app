import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
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

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(
          imageFile.path,
          filename: basename(imageFile.path),
        ),
      });

      print('=== AUTH REPOSITORY: UPLOAD PROFILE IMAGE REQUEST ===');

      final response = await _dioClient.dio.post(
        ApiConstants.uploadProfileImage,
        data: formData,
      );

      print('=== AUTH REPOSITORY: UPLOAD PROFILE IMAGE RESPONSE ===');
      print(response.data);

      // Extract the image URL from response
      final data = response.data;
      String? imageUrl;
      if (data is Map<String, dynamic>) {
        final nestedData = data['data'];
        imageUrl = _readImageUrl(data);
        if ((imageUrl == null || imageUrl.isEmpty) && nestedData is Map<String, dynamic>) {
          imageUrl = _readImageUrl(nestedData);
        }
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_url', imageUrl);
      }

      return imageUrl ?? '';
    } catch (e) {
      throw Exception(DioErrorParser.parse(e));
    }
  }

  Future<String?> getCachedProfileImageUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image_url');
  }

  String? _readImageUrl(Map<String, dynamic> json) {
    final value = json['profileImage'] ??
        json['profileImageUrl'] ??
        json['imageUrl'] ??
        json['url'];
    if (value == null) {
      return null;
    }
    return value.toString();
  }
}
