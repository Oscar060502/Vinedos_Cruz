import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({required this.orderId});

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<Map<String, dynamic>> _items = [];
  int _people = 1;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await DatabaseHelper.getOrderItems(widget.orderId);
    double sum = items.fold(0.0, (s, it) {
      final p = it['price'] as double;
      final d = it['discount'] as double? ?? 0.0;
      return s + (p - d);
    });
    setState(() {
      _items = items;
      _total = sum;
    });
    // Actualiza el total en la tabla orders
    await DatabaseHelper.updateOrderTotal(widget.orderId, sum);
  }

  double get _share => (_people > 1) ? (_total / _people) : _total;

  Future<bool> _authenticateSuper() async {
    String u = '', p = '';
    bool ok = false;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Autorizar Super Cajero'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Usuario'),
              onChanged: (v) => u = v,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
              onChanged: (v) => p = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancelar')),
          TextButton(onPressed: () async {
            final usr = await DatabaseHelper.authenticate(u, p);
            if (usr != null && usr['role'] == 'super_cajero') {
              ok = true;
              Navigator.pop(c);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Credenciales inválidas')));
            }
          }, child: Text('Autorizar')),
        ],
      ),
    );
    return ok;
  }

  Future<void> _applyDiscount(int itemId, String name) async {
    if (!await _authenticateSuper()) return;
    double d = 0.0;
    await showDialog(
      context: context,
      builder: (c) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text('Descuento a $name'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Monto'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancelar')),
            TextButton(onPressed: () async {
              d = double.tryParse(ctrl.text) ?? 0.0;
              await DatabaseHelper.updateOrderItemDiscount(itemId, d);
              Navigator.pop(c);
              await _loadItems();
            }, child: Text('Aplicar')),
          ],
        );
      },
    );
  }

  Future<void> _addProduct() async {
    final menu = await DatabaseHelper.getMenuItems();
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Agregar Producto'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: menu.length,
            itemBuilder: (_, i) {
              final m = menu[i];
              return ListTile(
                title: Text(m['name']),
                subtitle: Text('\$${(m['price'] as double).toStringAsFixed(2)}'),
                onTap: () async {
                  await DatabaseHelper.addOrderItem(
                      widget.orderId, m['name'] as String, m['price'] as double);
                  Navigator.pop(c);
                  await _loadItems();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pay() async {
    double cash = 0, tf = 0, tsf = 0;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Pagando \$${_share.toStringAsFixed(2)}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            decoration: InputDecoration(labelText: 'Efectivo'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => cash = double.tryParse(v) ?? 0.0,
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Tarjeta c/ factura'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => tf = double.tryParse(v) ?? 0.0,
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Tarjeta s/ factura'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => tsf = double.tryParse(v) ?? 0.0,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancelar')),
          TextButton(onPressed: () async {
            final sum = cash + tf + tsf;
            if (sum != _share) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                  'Debe pagar exactamente \$${_share.toStringAsFixed(2)}'
                )),
              );
              return;
            }
            // Marca la orden como pagada (usa el total completo desde la tabla)
            await DatabaseHelper.markOrderAsPaid(
                widget.orderId, cash, tf, tsf, _people);
            Navigator.pop(c);
            Navigator.pop(context); // Regresa a la lista
          }, child: Text('Cobrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comanda #${widget.orderId}'),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final it = _items[i];
              return ListTile(
                title: Text(it['name']),
                subtitle: Text(
                  'Precio: \$${(it['price'] as double).toStringAsFixed(2)}'
                  ' • Desc: \$${(it['discount'] as double).toStringAsFixed(2)}',
                ),
                onTap: () =>
                    _applyDiscount(it['id'] as int, it['name'] as String),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Row(children: [
            Text('Personas:'),
            SizedBox(width: 8),
            DropdownButton<int>(
              value: _people,
              items: List.generate(10, (i) => i + 1)
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) => setState(() => _people = v!),
            ),
            Spacer(),
            Text('Por persona: \$${_share.toStringAsFixed(2)}'),
          ]),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: _addProduct,
            child: Text('Agregar Producto'),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: ElevatedButton(
            onPressed: _pay,
            child:
                Text(_people > 1 ? 'Cobrar Parte (\$${_share.toStringAsFixed(2)})' : 'Cobrar \$${_total.toStringAsFixed(2)}'),
          ),
        ),
      ]),
    );
  }
}
