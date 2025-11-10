import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:auth/auth.dart';

/// States for the login process
abstract class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  final User user;
  const LoginSuccess(this.user);
}

class LoginFailure extends LoginState {
  final String message;
  const LoginFailure(this.message);
}

/// Events for the login BLoC
abstract class LoginEvent {
  const LoginEvent();
}

class LoginUserEvent extends LoginEvent {
  final String email;
  final String password;

  const LoginUserEvent({required this.email, required this.password});
}

class CheckSavedLoginEvent extends LoginEvent {
  const CheckSavedLoginEvent();
}

/// BLoC for handling user login
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;
  final AppDatabase _appDatabase;

  LoginBloc(this._authRepository, this._appDatabase) : super(const LoginInitial()) {
    on<LoginUserEvent>(_onLoginUser);
    on<CheckSavedLoginEvent>(_onCheckSavedLogin);
  }

  Future<void> _onLoginUser(LoginUserEvent event, Emitter<LoginState> emit) async {
    emit(const LoginLoading());

    try {
      final result = await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      await result.fold((failure) async => emit(LoginFailure(_mapFailureToMessage(failure))), (
        user,
      ) async {
        try {
          // Save login information to local database
          await _appDatabase.setAllUsersLoggedOut(); // Logout all users first
          await _appDatabase.saveUserLogin(
            UserLogin(
              id: user.id,
              email: event.email,
              userName: user.userName,
              fullName: user.fullName,
              isLoggedIn: true,
              lastLogin: DateTime.now(),
            ),
          );

          emit(LoginSuccess(user));
        } catch (dbError) {
          // If database save fails, still allow login but show warning
          emit(LoginSuccess(user));
          // Could emit a warning state here if needed
        }
      });
    } catch (e) {
      emit(const LoginFailure('Lỗi kết nối. Vui lòng thử lại.'));
    }
  }

  Future<void> _onCheckSavedLogin(CheckSavedLoginEvent event, Emitter<LoginState> emit) async {
    emit(const LoginLoading());

    try {
      final savedUser = await _appDatabase.getCurrentUser();
      if (savedUser != null) {
        // Try to get fresh user data from Firebase
        final currentUserResult = await _authRepository.getCurrentUser();
        if (currentUserResult.isSome()) {
          emit(
            LoginSuccess(currentUserResult.getOrElse(() => throw Exception('Should not happen'))),
          );
        } else {
          emit(const LoginInitial());
        }
      } else {
        emit(const LoginInitial());
      }
    } catch (e) {
      emit(const LoginInitial());
    }
  }

  String _mapFailureToMessage(AuthFailure failure) {
    if (failure is EmailAlreadyInUseFailure) {
      return 'Email đã được sử dụng';
    } else if (failure is WeakPasswordFailure) {
      return 'Mật khẩu quá yếu';
    } else if (failure is InvalidEmailFailure) {
      return 'Email không hợp lệ';
    } else if (failure is NetworkFailure) {
      return 'Lỗi mạng';
    } else if (failure is UnknownFailure) {
      return failure.message;
    } else {
      return 'Đã xảy ra lỗi không xác định';
    }
  }
}
