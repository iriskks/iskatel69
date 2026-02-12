import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../ui/theme/themed_scaffold.dart';
import '../ui/theme/app_themes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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
    final taken = await _auth.isLoginTaken(login);
    if (!mounted) return;
    if (taken) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Логин уже занят')));
      return;
    }
    final ok = await _auth.register(login, password);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Регистрация успешна')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось зарегистрироваться')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      variant: AppThemeVariant.neutral,
      appBar: AppBar(title: const Text('Регистрация')),
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
              child: _loading ? const CircularProgressIndicator.adaptive() : const Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
