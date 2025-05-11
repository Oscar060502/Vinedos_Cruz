import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'admin_categories_screen.dart'; // Pantalla para administrar categorías (ya existente)

class AdminInventoryScreen extends StatefulWidget {
  @override
  _AdminInventoryScreenState createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCategories();
  }
  
  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    final menuItems = await DatabaseHelper.getMenuItems();
    setState(() {
      _menuItems = menuItems;
      _isLoading = false;
    });
  }
  
  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.getCategories();
    setState(() {
      _categories = categories;
      if (_categories.isNotEmpty && _selectedCategoryId == null) {
        _selectedCategoryId = _categories.first['id'] as int;
      }
    });
  }
  
  Future<void> _addMenuItem() async {
    String name = _nameController.text.trim();
    double price = double.tryParse(_priceController.text) ?? -1;
    if (name.isEmpty || price <= 0 || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor ingresa datos válidos')),
      );
      return;
    }
    await DatabaseHelper.insertMenuItem(name, price, _selectedCategoryId);
    _nameController.clear();
    _priceController.clear();
    _loadData();
  }
  
  Future<void> _deleteMenuItem(int id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar'),
        content: Text('¿Estás seguro de eliminar este platillo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.deleteMenuItem(id);
              Navigator.pop(context);
              _loadData();
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Agregar Platillo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _selectedCategoryId,
                        items: _categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category['id'] as int,
                            child: Text(category['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        hint: Text('Selecciona una categoría'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.category, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminCategoriesScreen()),
                        ).then((_) => _loadCategories());
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addMenuItem,
                  child: Text('Agregar'),
                ),
                SizedBox(height: 20),
                Text('Inventario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _menuItems.isEmpty
                  ? Text('No hay platillos en el menú', style: TextStyle(fontSize: 16, color: Colors.red))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _menuItems.length,
                      itemBuilder: (context, index) {
                        final item = _menuItems[index];
                        return ListTile(
                          title: Text('${item['name']} - \$${(item['price'] as double).toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteMenuItem(item['id']),
                          ),
                        );
                      },
                    ),
              ],
            ),
      ),
    );
  }
}
