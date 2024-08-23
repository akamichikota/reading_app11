
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reading_app9/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmText = !_obscureConfirmText;
    });
  }

  void _signUp(BuildContext context) async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.signUp(
      _emailController.text,
      _passwordController.text,
      _usernameController.text,
    );
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign Up Failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ReadApp'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSerifJP',
          fontSize: 32,
          color: Colors.black,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'サインアップ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 40),
                Container(
                  width: 300,
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'ユーザー名',
                      filled: true,
                      fillColor: Color.fromRGBO(238, 238, 238, 1),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      labelStyle: TextStyle(color: Color.fromRGBO(131, 131, 135, 1)),
                    ),
                    style: TextStyle(color: Color.fromRGBO(131, 131, 135, 1)),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: 300,
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'メールアドレス',
                      filled: true,
                      fillColor: Color.fromRGBO(238, 238, 238, 1),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      labelStyle: TextStyle(color: Color.fromRGBO(131, 131, 135, 1)),
                    ),
                    style: TextStyle(color: Color.fromRGBO(131, 131, 135, 1)),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: 300,
                  child: TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'パスワード',
                      filled: true,
                      fillColor: Color.fromRGBO(238, 238, 238, 1),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off : Icons.visibility,
                          color: Color.fromRGBO(131, 131, 135, 1),
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                      labelStyle: TextStyle(color: Color.fromRGBO(131, 131, 135, 1)),
                    ),
                    style: TextStyle(color: Color.fromRGBO(131, 131, 135, 1)),
                    obscureText: _obscureText,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: 300,
                  child: TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'パスワードを確認',
                      filled: true,
                      fillColor: Color.fromRGBO(238, 238, 238, 1),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmText ? Icons.visibility_off : Icons.visibility,
                          color: Color.fromRGBO(131, 131, 135, 1),
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                      labelStyle: TextStyle(color: Color.fromRGBO(131, 131, 135, 1)),
                    ),
                    style: TextStyle(color: Color.fromRGBO(131, 131, 135, 1)),
                    obscureText: _obscureConfirmText,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: () => _signUp(context),
                    child: Text('登録する'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(30, 120, 186, 1),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'アカウントをお持ちですか？',
                      style: TextStyle(
                        color: Color.fromRGBO(131, 131, 135, 1),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Text(
                        'ログインする',
                        style: TextStyle(
                          color: Color.fromRGBO(30, 120, 186, 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
