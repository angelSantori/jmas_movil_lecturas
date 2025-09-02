import 'package:flutter/material.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';
import 'package:jmas_movil_lecturas/screens/general/home_screen.dart';
import 'package:jmas_movil_lecturas/screens/general/login2.dart';
import 'package:jmas_movil_lecturas/screens/general/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthService.ensureInitialized();

  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lecturas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginPage(),
      routes: {
        //'/login': (context) => const LoginScreen(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
