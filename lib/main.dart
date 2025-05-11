import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'admin_main_screen.dart';  
import 'cashier_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(),
      routes: {
        '/admin': (context) => AdminMainScreen(), // Cambiado a AdminMainScreen
        '/cashier': (context) => CashierScreen(),
      },
    );
  }
}
