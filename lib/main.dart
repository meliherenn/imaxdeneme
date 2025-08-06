import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:imaxip/screens/home_screen.dart';
import 'package:imaxip/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp'i ScreenUtilInit ile sarmalıyoruz
    return ScreenUtilInit(
      // Referans tasarım boyutları (örneğin bir iPhone 13 Pro ekranı)
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'iMax IP',
          theme: ThemeData.dark().copyWith(
            primaryColor: Colors.amber,
            scaffoldBackgroundColor: Colors.blueGrey[900],
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.blueGrey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          // ScreenUtilInit'in child'ını home olarak atıyoruz.
          home: child,
        );
      },
      // Boyutlandırmadan etkilenmemesi için AuthCheck'i child olarak veriyoruz.
      child: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return authProvider.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}