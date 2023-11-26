import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfinal/pages/GraphicPage.dart';
import 'package:flutterfinal/pages/LoginPage.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  double saldo = 0.0;
  TextEditingController _valorController = TextEditingController();
  TextEditingController _nomeController = TextEditingController();
  TextEditingController _tipoController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> transacoes = [];
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GraphicPage()),
        );
      }
    });
  }

  Future<void> _getUserData() async {
    DocumentSnapshot userData =
        await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
    if (userData.exists) {
      QuerySnapshot transactionsSnapshot = await _firestore
          .collection('extract')
          .where('uid', isEqualTo: _auth.currentUser!.uid)
          .get();
      double total = 0.0;
      transactionsSnapshot.docs.forEach((doc) {
        Map<String, dynamic> transactionData =
            doc.data() as Map<String, dynamic>;
        total += transactionData['valor'];
      });
      setState(() {
        saldo = total;
      });
    }
  }

  Future<void> _getTransactions() async {
    CollectionReference transactionsCollection =
        _firestore.collection('extract');
    transactionsCollection
        .where('uid', isEqualTo: _auth.currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((QuerySnapshot transactionsSnapshot) {
      setState(() {
        transacoes = transactionsSnapshot.docs.map((DocumentSnapshot doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
          return data;
        }).toList();
      });
    });
  }

  Future<void> _initializeBalance() async {
    QuerySnapshot transactionsSnapshot = await _firestore
        .collection('extract')
        .where('uid', isEqualTo: _auth.currentUser!.uid)
        .get();
    double total = 0.0;
    transactionsSnapshot.docs.forEach((doc) {
      Map<String, dynamic> transactionData = doc.data() as Map<String, dynamic>;
      total += transactionData['valor'];
    });
    setState(() {
      saldo = total;
    });
  }

  Future<void> _initializeData() async {
    await _getUserData();
    await _getTransactions();
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: FutureBuilder<User?>(
          future: Future.value(_auth.currentUser),
          builder: (context, AsyncSnapshot<User?> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              User? user = snapshot.data;
              return ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  UserAccountsDrawerHeader(
                    accountName: Text("Bem-Vindo(a)!"),
                    accountEmail: Text(user?.email ?? ""),
                    currentAccountPicture: CircleAvatar(),
                  ),
                  ListTile(
                    title: Text("Sair do App"),
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Saldo Atual",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "R\$ ${NumberFormat.currency(locale: 'pt_BR', decimalDigits: 2, symbol: '').format(saldo)}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: saldo >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _exibirDialogReceita(context);
                  },
                  child: Text("Adicionar Receita"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _exibirDialogDespesa(context);
                  },
                  child: Text("Adicionar Despesa"),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: transacoes.length,
                itemBuilder: (context, index) {
                  var transacao = transacoes[index];
                  bool isReceita = transacao['tipo'] == 'Receita';
                  Color valorColor = isReceita ? Colors.green : Colors.red;
                  return ListTile(
                    title: Text(transacao['nome']),
                    subtitle: Text(
                      "${transacao['tipo']} - ${transacao['tipoTransacao']}",
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${_formatDate(transacao['timestamp'])}",
                          style: TextStyle(fontSize: 10),
                        ),
                        Text(
                          "R\$ ${NumberFormat.currency(locale: 'pt_BR', decimalDigits: 2, symbol: '').format(transacao['valor'])}",
                          style: TextStyle(
                            color: valorColor,
                            fontWeight: FontWeight.bold,
                          ),
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
        onTap: _onItemTapped,
      ),
    );
  }

  String _formatDate(DateTime timestamp) {
    var formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(timestamp.toLocal());
  }

  String? _tipoReceitaSelecionado;

  void _exibirDialogReceita(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Receita'),
          content: Column(
            children: [
              TextField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField(
                value: _tipoReceitaSelecionado,
                items: [
                  DropdownMenuItem(
                    value: 'Rendimentos',
                    child: Text('Rendimentos'),
                  ),
                  DropdownMenuItem(
                    value: 'Salário',
                    child: Text('Salário'),
                  ),
                  DropdownMenuItem(
                    value: 'Outros',
                    child: Text('Outros'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipoReceitaSelecionado = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Tipo'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  hintText: 'Digite o valor desejado',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _limparCampos();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_camposReceitaValidos()) {
                  _adicionarReceita();
                  Navigator.of(context).pop();
                  _limparCampos();
                } else {
                  _exibirAlerta("Preencha todos os campos!");
                }
              },
              child: Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  bool _camposReceitaValidos() {
    return _nomeController.text.isNotEmpty &&
        _tipoReceitaSelecionado != null &&
        _valorController.text.isNotEmpty &&
        double.tryParse(_valorController.text) != null;
  }

  void _adicionarReceita() {
    if (_valorController.text.isNotEmpty &&
        double.parse(_valorController.text) != 0) {
      double valor = double.parse(_valorController.text);
      setState(
        () {
          saldo += valor;
          transacoes.insert(
            0,
            {
              'tipo': 'Receita',
              'nome': _nomeController.text,
              'tipoTransacao': _tipoReceitaSelecionado!,
              'valor': valor,
              'timestamp': DateTime.now(),
            },
          );
        },
      );
      salvarReceita(
          'Receita', _nomeController.text, _tipoReceitaSelecionado!, valor);
    }
  }

  void salvarReceita(
      String tipo, String nome, String tipoTransacao, double valor) {
    String uid = _auth.currentUser!.uid;
    _firestore.collection('extract').add(
      {
        'uid': uid,
        'tipo': tipo,
        'nome': nome,
        'tipoTransacao': tipoTransacao,
        'valor': valor,
        'timestamp': FieldValue.serverTimestamp(),
      },
    );
    _firestore.collection('users').doc(uid).update(
      {
        'saldo': saldo,
      },
    );
  }

  String? _tipoDespesaSelecionado;

  void _exibirDialogDespesa(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Despesa'),
          content: Column(
            children: [
              TextField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _tipoDespesaSelecionado,
                items: [
                  DropdownMenuItem(
                    value: 'Alimentação',
                    child: Text('Alimentação'),
                  ),
                  DropdownMenuItem(
                    value: 'Moradia',
                    child: Text('Moradia'),
                  ),
                  DropdownMenuItem(
                    value: 'Saúde',
                    child: Text('Saúde'),
                  ),
                  DropdownMenuItem(
                    value: 'Transporte',
                    child: Text('Transporte'),
                  ),
                  DropdownMenuItem(
                    value: 'Outros',
                    child: Text('Outros'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipoDespesaSelecionado = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Tipo'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  hintText: 'Digite o valor desejado',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _limparCampos();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_camposDespesaValidos()) {
                  _adicionarDespesa();
                  Navigator.of(context).pop();
                  _limparCampos();
                } else {
                  _exibirAlerta("Preencha todos os campos!");
                }
              },
              child: Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  bool _camposDespesaValidos() {
    return _nomeController.text.isNotEmpty &&
        _tipoDespesaSelecionado != null &&
        _valorController.text.isNotEmpty &&
        double.tryParse(_valorController.text) != null;
  }

  void _adicionarDespesa() async {
    if (_valorController.text.isNotEmpty &&
        double.parse(_valorController.text) != 0) {
      double valor = double.parse(_valorController.text);
      if (_tipoDespesaSelecionado != null) {
        setState(() {
          saldo -= valor;
          transacoes.insert(
            0,
            {
              'tipo': 'Despesa',
              'nome': _nomeController.text,
              'tipoTransacao': _tipoDespesaSelecionado!,
              'valor': -valor,
              'timestamp': DateTime.now(),
            },
          );
        });
        salvarDespesa(_nomeController.text, _tipoDespesaSelecionado!, valor);
      } else {
        _exibirAlerta("Selecione um tipo de despesa!");
      }
    }
  }

  void salvarDespesa(String nome, String tipo, double valor) {
    String uid = _auth.currentUser!.uid;
    _firestore.collection('extract').add(
      {
        'uid': uid,
        'tipo': 'Despesa',
        'nome': nome,
        'tipoTransacao': tipo,
        'valor': -valor,
        'timestamp': FieldValue.serverTimestamp(),
      },
    );
    _firestore.collection('users').doc(uid).update(
      {
        'saldo': saldo,
      },
    );
  }

  void _exibirAlerta(String mensagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Atenção'),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _limparCampos() {
    _nomeController.clear();
    _tipoController.clear();
    _valorController.clear();
  }
}
