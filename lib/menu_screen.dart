import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _orderItems = [];
  List<Map<String, dynamic>> _categories = [];
  List<int> _availableTables = [];
  int? _selectedCategoryId;
  String _waiterName = '';
  int _tableNumber = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWaiterName();
    _loadCategories();
    _loadAvailableTables();
    _loadMenu();
  }

  Future<void> _loadWaiterName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _waiterName = prefs.getString('username') ?? '';
    });
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.getCategories();
    setState(() {
      _categories = cats;
      if (_categories.isNotEmpty && _selectedCategoryId == null)
        _selectedCategoryId = _categories.first['id'] as int;
    });
  }

  Future<void> _loadAvailableTables() async {
    final active = await DatabaseHelper.getActiveOrders();
    final used = active.map((o) => o['table_number'] as int).toList();
    final free = List<int>.generate(7, (i) => i + 1)
        .where((m) => !used.contains(m))
        .toList();
    setState(() {
      _availableTables = free;
      _tableNumber = free.isNotEmpty ? free.first : 0;
    });
  }

  Future<void> _loadMenu() async {
    final items = await DatabaseHelper.getMenuItems(
        categoryId: _selectedCategoryId);
    setState(() => _menuItems = items);
  }

  double get _total {
    return _orderItems.fold(0.0, (sum, item) {
      final price = item['price'] as double;
      final disc = item['discount'] as double? ?? 0.0;
      return sum + (price - disc);
    });
  }

  Future<void> _createOrder() async {
    if (_waiterName.isEmpty ||
        _orderItems.isEmpty ||
        _tableNumber == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faltan datos para crear la comanda')));
      return;
    }
    final orderId = await DatabaseHelper.insertOrder(
      _orderItems,
      _total,
      _waiterName,
      _tableNumber,
      comment: _commentController.text.trim(),
    );
    setState(() {
      _orderItems.clear();
      _commentController.clear();
      _loadAvailableTables();
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Comanda creada #$orderId')));
  }

  Future<void> _editOrderItemDiscount(Map<String, dynamic> item) async {
    // NO aplicamos aquí: ahora en OrderDetailScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menú')),
      body: Column(children: [
        if (_categories.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(8),
            child: DropdownButton<int>(
              isExpanded: true,
              value: _selectedCategoryId,
              items: _categories
                  .map((c) => DropdownMenuItem(
                      value: c['id'] as int, child: Text(c['name']!)))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedCategoryId = v;
                _loadMenu();
              }),
              hint: Text('Categoría'),
            ),
          ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text('Cajero: $_waiterName'),
        ),
        if (_availableTables.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(8),
            child: DropdownButton<int>(
              value: _tableNumber,
              items: _availableTables
                  .map((m) =>
                      DropdownMenuItem(value: m, child: Text('Mesa $m')))
                  .toList(),
              onChanged: (v) => setState(() => _tableNumber = v!),
            ),
          ),
        Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
            controller: _commentController,
            decoration:
                InputDecoration(labelText: 'Comentario (opcional)'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _menuItems.length,
            itemBuilder: (_, i) {
              final it = _menuItems[i];
              return ListTile(
                title: Text(it['name']),
                subtitle: Text(
                    '\$${(it['price'] as double).toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _orderItems.add({
                        'name': it['name'],
                        'price': it['price'],
                        'discount': 0.0,
                      });
                    });
                  },
                ),
              );
            },
          ),
        ),
        if (_orderItems.isNotEmpty)
          Container(
            height: 150,
            color: Colors.grey[200],
            child: ListView.builder(
              itemCount: _orderItems.length,
              itemBuilder: (_, i) {
                final oi = _orderItems[i];
                return ListTile(
                  title: Text(oi['name']),
                  subtitle: Text(
                      'Precio: \$${(oi['price'] as double).toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        setState(() => _orderItems.removeAt(i)),
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
              'Total: \$${_total.toStringAsFixed(2)}'),
        ),
        ElevatedButton(
          onPressed: _createOrder,
          child: Text('Crear Comanda'),
        ),
      ]),
    );
  }
}
