import 'package:flutter/material.dart';
import 'db_helper.dart';

class AdminEmployeePanelScreen extends StatefulWidget {
  @override
  _AdminEmployeePanelScreenState createState() =>
      _AdminEmployeePanelScreenState();
}

class _AdminEmployeePanelScreenState extends State<AdminEmployeePanelScreen> {
  List<Map<String, dynamic>> _employees = [];
  final _uCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  String _newRole = 'cajero';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final emps = await DatabaseHelper.getUsers();
    setState(() => _employees = emps);
  }

  Future<void> _addEmployee() async {
    final u = _uCtrl.text.trim();
    final p = _pCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario y contraseña requeridos')));
      return;
    }
    await DatabaseHelper.insertUser(u, p, _newRole);
    _uCtrl.clear();
    _pCtrl.clear();
    _loadEmployees();
  }

  Future<void> _changeRole(int id, String current) async {
    final next = (current == 'cajero') ? 'super_cajero' : 'cajero';
    await DatabaseHelper.updateUserRole(id, next);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Rol cambiado a $next')));
    _loadEmployees();
  }

  Future<void> _delete(int id) async {
    await DatabaseHelper.deleteUser(id);
    _loadEmployees();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text('Panel de Empleados')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Crear Usuario',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _uCtrl,
                  decoration: InputDecoration(labelText: 'Usuario'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _pCtrl,
                  decoration: InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _newRole,
                  onChanged: (v) => setState(() => _newRole = v!),
                  items: [
                    DropdownMenuItem(
                        value: 'cajero', child: Text('Cajero')),
                    DropdownMenuItem(
                        value: 'super_cajero',
                        child: Text('Super Cajero')),
                  ],
                  decoration: InputDecoration(labelText: 'Rol'),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(onPressed: _addEmployee, child: Text('Crear')),
            ]),
            Divider(height: 32),
            Text('Usuarios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _employees.length,
                itemBuilder: (_, i) {
                  final u = _employees[i];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(u['username']),
                      subtitle: Text('Rol: ${u['role']}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'change') _changeRole(u['id'], u['role']);
                          if (v == 'delete') _delete(u['id']);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 'change',
                              child: Text('Cambiar Rol')),
                          PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
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
