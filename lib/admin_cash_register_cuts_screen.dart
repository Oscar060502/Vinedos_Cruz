import 'package:flutter/material.dart';
import 'db_helper.dart';

class AdminCashRegisterCutsScreen extends StatefulWidget {
  @override
  _AdminCashRegisterCutsScreenState createState() => _AdminCashRegisterCutsScreenState();
}

class _AdminCashRegisterCutsScreenState extends State<AdminCashRegisterCutsScreen> {
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadSales();
  }
  
  Future<void> _loadSales() async {
    setState(() { _isLoading = true; });
    final sales = await DatabaseHelper.getSalesHistory();
    setState(() {
      _sales = sales;
      _isLoading = false;
    });
  }
  
  // Filtra ventas en un rango de fechas
  List<Map<String, dynamic>> _filterSales(DateTime start, DateTime end) {
    return _sales.where((sale) {
      DateTime saleDate = DateTime.parse(sale['date']);
      return saleDate.isAfter(start) && saleDate.isBefore(end);
    }).toList();
  }
  
  double _calculateTotal(List<Map<String, dynamic>> sales) {
    return sales.fold(0.0, (sum, sale) => sum + (sale['total'] as double));
  }
  
  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startDay = DateTime(now.year, now.month, now.day);
    DateTime endDay = startDay.add(Duration(days: 1));
    
    DateTime startWeek = now.subtract(Duration(days: now.weekday - 1)); // Inicio de semana (lunes)
    DateTime endWeek = startWeek.add(Duration(days: 7));
    
    DateTime startMonth = DateTime(now.year, now.month, 1);
    DateTime endMonth = DateTime(now.year, now.month + 1, 1);
    
    List<Map<String, dynamic>> salesDay = _filterSales(startDay, endDay);
    List<Map<String, dynamic>> salesWeek = _filterSales(startWeek, endWeek);
    List<Map<String, dynamic>> salesMonth = _filterSales(startMonth, endMonth);
    
    double totalDay = _calculateTotal(salesDay);
    double totalWeek = _calculateTotal(salesWeek);
    double totalMonth = _calculateTotal(salesMonth);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Cortes de Caja'),
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ventas del Día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Total: \$${totalDay.toStringAsFixed(2)}'),
              SizedBox(height: 10),
              Text('Ventas de la Semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Total: \$${totalWeek.toStringAsFixed(2)}'),
              SizedBox(height: 10),
              Text('Ventas del Mes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Total: \$${totalMonth.toStringAsFixed(2)}'),
              Divider(),
              Text('Historial de Ventas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _sales.length,
                itemBuilder: (context, index) {
                  final sale = _sales[index];
                  return ListTile(
                    title: Text('Venta #${sale['id']} - \$${(sale['total'] as double).toStringAsFixed(2)}'),
                    subtitle: Text('Fecha: ${sale['date']}'),
                  );
                },
              ),
            ],
          ),
        ),
    );
  }
}
