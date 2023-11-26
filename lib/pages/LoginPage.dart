import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfinal/auth/Autentication.dart';
import 'package:flutterfinal/pages/HomePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthService _authService = AuthService();
  TextEditingController emailController = TextEditingController();
  TextEditingController loginPasswordController = TextEditingController();
  TextEditingController registerPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool _loginPasswordVisible = false;
  bool _registerPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildTextField('Email', emailController),
              _buildPasswordTextField(
                loginPasswordController,
                _loginPasswordVisible,
                _toggleLoginPasswordVisibility,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _signIn,
                child: Text('Entrar'),
              ),
              SizedBox(height: 16.0),
              GestureDetector(
                onTap: () {
                  _showRegistrationDialog(context);
                },
                child: Text(
                  'Criar conta',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildPasswordTextField(
    TextEditingController controller,
    bool isVisible,
    Function() toggleVisibility,
  ) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Senha',
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }

  void _toggleLoginPasswordVisibility() {
    setState(() {
      _loginPasswordVisible = !_loginPasswordVisible;
    });
  }

  void _toggleRegisterPasswordVisibility() {
    setState(() {
      _registerPasswordVisible = !_registerPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _confirmPasswordVisible = !_confirmPasswordVisible;
    });
  }

  void _signIn() async {
    String email = emailController.text;
    String password = loginPasswordController.text;
    User? user = await _authService.signInWithEmailAndPassword(email, password);
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => HomePage(),
        ),
      );
    } else {
      _showErrorDialog("Credenciais inválidas");
      emailController.clear();
      loginPasswordController.clear();
    }
  }

  void _showRegistrationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cadastro'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Email', emailController),
                _buildPasswordTextField(
                  registerPasswordController,
                  _registerPasswordVisible,
                  _toggleRegisterPasswordVisibility,
                ),
                _buildPasswordTextField(
                  confirmPasswordController,
                  _confirmPasswordVisible,
                  _toggleConfirmPasswordVisibility,
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _register(registerPasswordController.text,
                    confirmPasswordController.text);
              },
              child: Text('Cadastrar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _register(String password, String confirmPassword) async {
    String email = emailController.text;
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog('Todos os campos são obrigatórios');
      return;
    }
    if (password != confirmPassword) {
      _showErrorDialog('Senha e Confirme a senha não coincidem');
      return;
    }
    User? user =
        await _authService.registerWithEmailAndPassword(email, password);
    if (user != null) {
      Navigator.of(context).pop();
    } else {
      _showErrorDialog('Erro ao cadastrar usuário');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erro de Autenticação'),
          content: Text(message),
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
}
