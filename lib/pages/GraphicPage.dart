import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'HomePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GraphicPage extends StatefulWidget {
  const GraphicPage({Key? key}) : super(key: key);

  @override
  State<GraphicPage> createState() => _GraphicPageState();
}

class _GraphicPageState extends State<GraphicPage> {
  int _selectedIndex = 1;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<PieChartSectionData> _chartSections = [];

  @override
  void initState() {
    super.initState();
    _updateChartSections();
    _firestore.collection('extract').snapshots().listen(
      (event) {
        _updateChartSections();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateToHomePage();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Despesas'),
        ),
        body: Center(
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: _chartSections,
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Despesas',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          onTap: (index) {
            if (index == 0) {
              _navigateToHomePage();
            }
          },
        ),
      ),
    );
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  Future<Map<String, double>> _getExpensesFromFirebase() async {
    String uid = _auth.currentUser!.uid;
    QuerySnapshot expensesSnapshot = await _firestore
        .collection('extract')
        .where('uid', isEqualTo: uid)
        .where('tipo', isEqualTo: 'Despesa')
        .get();
    Map<String, double> expensesMap = {};
    expensesSnapshot.docs.forEach(
      (doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String tipoTransacao = data['tipoTransacao'];
        double valor = -data['valor']; 
        if (expensesMap.containsKey(tipoTransacao)) {
          expensesMap[tipoTransacao] = expensesMap[tipoTransacao]! + valor;
        } else {
          expensesMap[tipoTransacao] = valor;
        }
      },
    );
    return expensesMap;
  }

  Future<void> _updateChartSections() async {
    Map<String, double> expenses = await _getExpensesFromFirebase();
    setState(
      () {
        _chartSections = expenses.entries.map(
          (entry) {
            final isTouched = entry.key == expenses.keys.first;
            return PieChartSectionData(
              color: _getColor(entry.key.hashCode),
              value: entry.value,
              title:
                  '${entry.key}\n${_formatPercentage(_calculatePercentage(entry.value, expenses.values))}%',
              radius: isTouched ? 80 : 60,
              titleStyle: TextStyle(
                fontSize: isTouched ? 16 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ).toList();
      },
    );
  }

  Color _getColor(int hashCode) {
    return Color(hashCode & 0xFFFFFF).withOpacity(1.0);
  }

  double _calculatePercentage(double value, Iterable<double> totalValues) {
    double total = totalValues.reduce((sum, element) => sum + element);
    return (value / total) * 100;
  }

  String _formatPercentage(double percentage) {
    return percentage.toStringAsFixed(2);
  }
}
