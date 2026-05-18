import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>((event, emit) async {
      final loggedIn = await _authRepository.isLoggedIn();
      if (loggedIn) {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('user_email') ?? '';
        final id = prefs.getString('user_id') ?? '';
        emit(AuthAuthenticated(UserModel(id: id, username: email.split('@')[0], email: email)));
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await _authRepository.login(event.email, event.password);
        emit(AuthAuthenticated(response.user));
      } catch (e) {
        emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      }
    });

    on<AuthSignupRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await _authRepository.signup(event.email, event.password);
        emit(AuthAuthenticated(response.user));
      } catch (e) {
        emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      await _authRepository.logout();
      emit(AuthUnauthenticated());
    });
  }
}
