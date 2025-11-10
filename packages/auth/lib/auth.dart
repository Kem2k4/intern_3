export 'src/domain/entities/user.dart';

/// Export domain repositories
export 'src/domain/repositories/auth_repository.dart';

/// Export infrastructure services
export 'src/infrastructure/services/firebase_auth_repository.dart';

/// Export presentation blocs
export 'src/presentation/bloc/login_bloc.dart';
export 'src/presentation/bloc/register_bloc.dart';

/// Export presentation pages
export 'src/presentation/pages/login_page.dart';
export 'src/presentation/pages/register_page.dart';

// Export all auth-related classes from their respective files
export 'src/domain/repositories/auth_repository.dart'
    show
        AuthFailure,
        EmailAlreadyInUseFailure,
        WeakPasswordFailure,
        InvalidEmailFailure,
        NetworkFailure,
        UnknownFailure,
        AuthRepository;

export 'src/presentation/bloc/login_bloc.dart'
    show
        LoginBloc,
        LoginState,
        LoginInitial,
        LoginLoading,
        LoginSuccess,
        LoginFailure,
        CheckSavedLoginEvent,
        LoginUserEvent;

export 'src/presentation/bloc/register_bloc.dart'
    show
        RegisterBloc,
        RegisterState,
        RegisterInitial,
        RegisterLoading,
        RegisterSuccess,
        RegisterFailure,
        RegisterUserEvent;
