import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'map_page.dart';
import '../ui/theme/themed_scaffold.dart';
import '../ui/theme/app_themes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final login = _loginController.text.trim();
    final password = _passwordController.text;
    if (login.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите логин и пароль')));
      return;
    }
    setState(() => _loading = true);
    final ok = await _auth.login(login, password);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MapPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неверный логин или пароль')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      variant: AppThemeVariant.calm,
      appBar: AppBar(title: const Text('Вход')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _loginController,
              decoration: const InputDecoration(labelText: 'Логин'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const CircularProgressIndicator.adaptive() : const Text('Войти'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
              },
              child: const Text('Зарегистрироваться'),
            )
          ],
        ),
      ),
    );
  }
}
