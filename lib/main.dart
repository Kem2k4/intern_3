import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:videocall/src/infrastructure/services/fcm_token_manager.dart';
import 'package:videocall/src/presentation/bloc/video_call_bloc.dart';
import 'package:videocall/src/infrastructure/services/video_call_service.dart';
import 'package:videocall/src/data/repositories/video_call_repository.dart';
import 'package:videocall/src/data/datasources/video_call_firebase_data_source.dart';
import 'package:videocall/src/infrastructure/services/agora_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'config/firebase_options.dart';
import 'presentation/pages/home_page.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // debugPrint('🔔 Background message received: ${message.messageId}');
  // debugPrint('📦 Data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (critical - must be sync)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM Service asynchronously (non-blocking)
  FCMService.instance.initialize();

  // Initialize FCM Token Manager
  final authRepository = FirebaseAuthRepository();
  final fcmTokenManager = FCMTokenManager(authRepository);
  await fcmTokenManager.initialize();

  // Start app immediately without waiting for database warmup
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create global VideoCallBloc instance
    final database = FirebaseDatabase.instance;
    final dataSource = VideoCallFirebaseDataSource(database);
    final repository = VideoCallRepositoryImpl(dataSource);
    final agoraService = AgoraServiceImpl();
    final authRepository = FirebaseAuthRepository();
    final videoCallService = VideoCallService(repository, agoraService, authRepository);
    final videoCallBloc = VideoCallBloc(videoCallService);

    return MultiRepositoryProvider(
      providers: [
        // Lazy initialization of repositories
        RepositoryProvider<AppDatabase>(
          create: (context) => AppDatabase(),
          lazy: false, // Initialize eagerly in background
        ),
        RepositoryProvider<FirebaseAuthRepository>(
          create: (context) => FirebaseAuthRepository(),
          lazy: true,
        ),
      ],
      child: BlocProvider<VideoCallBloc>(
        create: (context) => videoCallBloc,
        child: MaterialApp(
          title: 'Vietravel',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: ThemeMode.system,
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/home': (context) => const HomePage(),
            '/login': (context) => BlocProvider(
              create: (context) => LoginBloc(
                RepositoryProvider.of<FirebaseAuthRepository>(context),
                RepositoryProvider.of<AppDatabase>(context),
              )..add(const CheckSavedLoginEvent()),
              child: const LoginPage(),
            ),
            '/register': (context) => BlocProvider(
              create: (context) =>
                  RegisterBloc(RepositoryProvider.of<FirebaseAuthRepository>(context)),
              child: const RegisterPage(),
            ),
          },
        ),
      ),
    );
  }
}

/// Wrapper widget that checks authentication status
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final LoginBloc _loginBloc;

  @override
  void initState() {
    super.initState();
    _loginBloc = LoginBloc(FirebaseAuthRepository(), AppDatabase())
      ..add(const CheckSavedLoginEvent());
  }

  @override
  void dispose() {
    _loginBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _loginBloc,
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          if (state is LoginSuccess) {
            return const HomePage();
          } else if (state is LoginLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();

//   FirebaseMessaging messaging = FirebaseMessaging.instance;
//   String? token = await messaging.getToken();
//   print("🔥 FCM Token: $token");
// }
