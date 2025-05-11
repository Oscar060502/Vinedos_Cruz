import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'order_detail_screen.dart'; // Nuevo

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);
  @override
  OrderScreenState createState() => OrderScreenState();
}

class OrderScreenState extends State<OrderScreen> {
  late Future<List<Map<String, dynamic>>> _activeOrdersFuture;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  void _refreshOrders() {
    setState(() {
      _activeOrdersFuture = DatabaseHelper.getActiveOrders();
    });
  }

  void refreshOrders() => _refreshOrders();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comandas Activas'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _refreshOrders)
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _activeOrdersFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snap.hasError)
            return Center(child: Text('Error al cargar comandas'));
          final orders = snap.data ?? [];
          if (orders.isEmpty)
            return Center(child: Text('No hay comandas activas'));
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final o = orders[i];
              return Card(
                margin: EdgeInsets.all(6),
                child: ListTile(
                  title: Text(
                      'Mesa ${o['table_number']} • Cajero: ${o['waiter_name']}'),
                  subtitle: Text(
                      'Total: \$${(o['total'] as double).toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailScreen(orderId: o['id'] as int),
                      ),
                    ).then((_) => _refreshOrders());
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
