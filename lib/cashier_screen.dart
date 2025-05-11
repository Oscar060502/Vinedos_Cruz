import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'menu_screen.dart';
import 'order_screen.dart';

class CashierScreen extends StatefulWidget {
  @override
  _CashierScreenState createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  int _selectedIndex = 0;
  // GlobalKey para acceder al estado de OrderScreen y poder refrescarlo
  final GlobalKey<OrderScreenState> orderScreenKey = GlobalKey<OrderScreenState>();

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Elimina la sesión guardada

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Si se selecciona la pestaña de Comandas, se refrescan las órdenes
    if (index == 1) {
      orderScreenKey.currentState?.refreshOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se definen las pantallas: Menú y Comandas
    List<Widget> screens = [
      MenuScreen(),
      OrderScreen(key: orderScreenKey),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Cajero'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: "Menú"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Comanda"),
        ],
      ),
    );
  }
}
