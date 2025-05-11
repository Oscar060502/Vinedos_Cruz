import 'package:flutter/material.dart';
import 'db_helper.dart';

class AdminCategoriesScreen extends StatefulWidget {
  @override
  _AdminCategoriesScreenState createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  final TextEditingController _categoryNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final data = await DatabaseHelper.getCategories();
    setState(() {
      _categories = data;
    });
  }

  Future<void> _addCategory() async {
    String name = _categoryNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingresa un nombre de categoría')),
      );
      return;
    }
    await DatabaseHelper.insertCategory(name);
    _categoryNameController.clear();
    _loadCategories();
  }

  Future<void> _deleteCategory(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Deseas eliminar esta categoría?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.deleteCategory(id);
      _loadCategories();
    }
  }

  Future<void> _editCategory(int id, String currentName) async {
    final TextEditingController editController = TextEditingController(text: currentName);
    bool saved = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Categoría'),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved == true) {
      String newName = editController.text.trim();
      if (newName.isNotEmpty) {
        await DatabaseHelper.updateCategory(id, newName);
        _loadCategories();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrar Categorías'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulario para agregar una nueva categoría
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryNameController,
                    decoration: InputDecoration(labelText: 'Nueva categoría'),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addCategory,
                  child: Text('Agregar'),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Lista de categorías existentes
            Expanded(
              child: _categories.isEmpty
                  ? Center(child: Text('No hay categorías registradas'))
                  : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return ListTile(
                          title: Text(category['name'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editCategory(
                                  category['id'],
                                  category['name'] ?? '',
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCategory(category['id']),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
