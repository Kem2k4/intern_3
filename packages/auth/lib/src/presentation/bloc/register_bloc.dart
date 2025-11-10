import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:dartz/dartz.dart' show Either;
import 'package:auth/auth.dart';

/// States for the registration process
abstract class RegisterState {
  const RegisterState();
}

class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

class RegisterSuccess extends RegisterState {
  final User user;
  const RegisterSuccess(this.user);
}

class RegisterFailure extends RegisterState {
  final String message;
  const RegisterFailure(this.message);
}

/// Events for the registration BLoC
abstract class RegisterEvent {
  const RegisterEvent();
}

class RegisterUserEvent extends RegisterEvent {
  final String email;
  final String password;
  final String userName;
  final String fullName;
  final String address;
  final String avatar;
  final String birthday;

  const RegisterUserEvent({
    required this.email,
    required this.password,
    required this.userName,
    required this.fullName,
    required this.address,
    required this.avatar,
    required this.birthday,
  });
}

/// BLoC for handling user registration
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _authRepository;

  RegisterBloc(this._authRepository) : super(const RegisterInitial()) {
    on<RegisterUserEvent>(_onRegisterUser);
  }

  Future<void> _onRegisterUser(RegisterUserEvent event, Emitter<RegisterState> emit) async {
    emit(const RegisterLoading());

    final result = await _authRepository.registerUser(
      email: event.email,
      password: event.password,
      userName: event.userName,
      fullName: event.fullName,
      address: event.address,
      avatar: event.avatar,
      birthday: event.birthday,
    );

    result.fold(
      (failure) => emit(RegisterFailure(_mapFailureToMessage(failure))),
      (user) => emit(RegisterSuccess(user)),
    );
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
