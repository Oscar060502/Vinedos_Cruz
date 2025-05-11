import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'restaurant.db');
    return await openDatabase(
      path,
      version: 7,  // bump a 7 para forzar recrear el CHECK corregido
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            role TEXT CHECK(role IN ('admin','cajero','super_cajero')),
            permissions TEXT DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE menu (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price REAL,
            category_id INTEGER,
            measurement_type TEXT,
            FOREIGN KEY (category_id) REFERENCES categories(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total REAL NOT NULL,
            waiter_name TEXT,
            table_number INTEGER,
            date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_paid INTEGER DEFAULT 0,
            comment TEXT,
            order_discount REAL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER,
            name TEXT,
            price REAL,
            discount REAL DEFAULT 0,
            FOREIGN KEY (order_id) REFERENCES orders(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE sales(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total REAL NOT NULL,
            cash REAL DEFAULT 0,
            card_invoice REAL DEFAULT 0,
            waiter_name TEXT,
            table_number INTEGER,
            card_no_invoice REAL DEFAULT 0,
            date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            number_of_people INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE sale_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER,
            name TEXT,
            price REAL,
            discount REAL DEFAULT 0,
            FOREIGN KEY (sale_id) REFERENCES sales(id)
          )
        ''');

        // usuarios iniciales
        await db.insert('users', {
          'username': 'admin',
          'password': '1234',
          'role': 'admin'
        });
        await db.insert('users', {
          'username': 'cajero',
          'password': '5678',
          'role': 'cajero'
        });
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 7) {
          // Para un esquema limpio, habitualmente eliminarías & recrearías la tabla users
          // para actualizar el CHECK. En desarrollo, basta con borrar la BD antigua.
        }
      },
    );
  }

  // —— Usuarios ——
  static Future<Map<String, dynamic>?> authenticate(
      String username, String password) async {
    final db = await database;
    final res = await db.query('users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password]);
    return res.isNotEmpty ? res.first : null;
  }

  static Future<List<Map<String, dynamic>>> getUsers({String? role}) async {
    final db = await database;
    if (role != null) {
      return db.query('users', where: 'role = ?', whereArgs: [role]);
    }
    return db.query('users');
  }

  static Future<int> insertUser(
      String username, String password, String role) async {
    final db = await database;
    return db.insert('users', {
      'username': username,
      'password': password,
      'role': role,
    });
  }

  static Future<int> updateUserRole(int userId, String newRole) async {
    final db = await database;
    return db.update('users', {'role': newRole},
        where: 'id = ?', whereArgs: [userId]);
  }

  static Future<int> deleteUser(int id) async {
    final db = await database;
    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // —— Categorías ——
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query('categories');
  }

  static Future<int> insertCategory(String name) async {
    final db = await database;
    return db.insert('categories', {'name': name});
  }

  static Future<int> updateCategory(int id, String newName) async {
    final db = await database;
    return db.update('categories', {'name': newName},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // —— Menú ——
  static Future<List<Map<String, dynamic>>> getMenuItems(
      {int? categoryId}) async {
    final db = await database;
    if (categoryId != null) {
      return db.query('menu',
          where: 'category_id = ?', whereArgs: [categoryId]);
    }
    return db.query('menu');
  }

  static Future<int> insertMenuItem(String name, double price,
      int? categoryId,
      {String? measurementType}) async {
    final db = await database;
    return db.insert('menu', {
      'name': name,
      'price': price,
      'category_id': categoryId,
      'measurement_type': measurementType
    });
  }

  static Future<int> updateMenuItem(int id, String name, double price,
      int? categoryId,
      {String? measurementType}) async {
    final db = await database;
    return db.update('menu', {
      'name': name,
      'price': price,
      'category_id': categoryId,
      'measurement_type': measurementType
    }, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteMenuItem(int id) async {
    final db = await database;
    return db.delete('menu', where: 'id = ?', whereArgs: [id]);
  }

  // —— Órdenes & OrderItems ——
  static Future<int> insertOrder(
      List<Map<String, dynamic>> items,
      double total,
      String waiterName,
      int tableNumber, {
      String? comment,
      double orderDiscount = 0,
  }) async {
    final db = await database;
    final oid = await db.insert('orders', {
      'total': total,
      'waiter_name': waiterName,
      'table_number': tableNumber,
      'comment': comment,
      'order_discount': orderDiscount
    });
    for (var it in items) {
      await db.insert('order_items', {
        'order_id': oid,
        'name': it['name'],
        'price': it['price'],
      });
    }
    return oid;
  }

  static Future<List<Map<String, dynamic>>> getActiveOrders() async {
    final db = await database;
    return db.query('orders', where: 'is_paid = 0', orderBy: 'date DESC');
  }

  static Future<List<Map<String, dynamic>>> getOrderItems(
      int orderId) async {
    final db = await database;
    return db.query('order_items',
        where: 'order_id = ?', whereArgs: [orderId]);
  }

  /// Actualiza el total de la orden en la tabla
  static Future<int> updateOrderTotal(int orderId, double newTotal) async {
    final db = await database;
    return db.update('orders', {'total': newTotal},
        where: 'id = ?', whereArgs: [orderId]);
  }

  /// Aplica descuento a un item
  static Future<int> updateOrderItemDiscount(
      int itemId, double discount) async {
    final db = await database;
    return db.update('order_items', {'discount': discount},
        where: 'id = ?', whereArgs: [itemId]);
  }

  /// Agrega un item a una orden activa
  static Future<int> addOrderItem(
      int orderId, String name, double price) async {
    final db = await database;
    return db.insert('order_items', {
      'order_id': orderId,
      'name': name,
      'price': price,
      'discount': 0.0
    });
  }

  static Future<void> markOrderAsPaid(
      int orderId,
      double cash,
      double cardInvoice,
      double cardNoInvoice,
      int numberOfPeople) async {
    final db = await database;
    final ord = await db.query('orders',
        where: 'id = ?', whereArgs: [orderId]);
    if (ord.isNotEmpty) {
      final o = ord.first;
      final saleId = await db.insert('sales', {
        'total': o['total'],
        'cash': cash,
        'card_invoice': cardInvoice,
        'card_no_invoice': cardNoInvoice,
        'waiter_name': o['waiter_name'],
        'table_number': o['table_number'],
        'number_of_people': numberOfPeople
      });
      final items = await db.query('order_items',
          where: 'order_id = ?', whereArgs: [orderId]);
      for (var it in items) {
        await db.insert('sale_items', {
          'sale_id': saleId,
          'name': it['name'],
          'price': it['price'],
          'discount': it['discount']
        });
      }
      await db.update('orders', {'is_paid': 1},
          where: 'id = ?', whereArgs: [orderId]);
    }
  }

  // —— Historial de ventas ——
  static Future<List<Map<String, dynamic>>> getSalesHistory() async {
    final db = await database;
    return db.query('sales', orderBy: 'date DESC');
  }

  static Future<List<Map<String, dynamic>>> getSaleItems(
      int saleId) async {
    final db = await database;
    return db.query('sale_items',
        where: 'sale_id = ?', whereArgs: [saleId]);
  }
}
