import 'package:flutter/material.dart';

import 'app_session.dart';
import 'app_ui.dart';
import 'bmi_screen.dart';
import 'registration_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.session});
  final AppSession session;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController(text: demoEmail);
  final _password = TextEditingController(text: demoPassword);
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signIn() {
    FocusScope.of(context).unfocus();
    if (!widget.session.signIn(_email.text, _password.text)) {
      setState(() => _error = 'Неверный email или пароль');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BmiScreen(session: widget.session),
      ),
    );
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => RegistrationScreen(session: widget.session),
      ),
    );
    if (!mounted || email == null) return;
    _email.text = email;
    _password.clear();
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Учебный аккаунт создан. Введите пароль для входа.'),
      ),
    );
  }

  void _clearError(String _) {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ScreenBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeading('Вход в приложение'),
          const SizedBox(height: 28),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppField(
                  label: 'Email',
                  hint: 'example@gmail.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHint: AutofillHints.username,
                  onChanged: _clearError,
                ),
                const SizedBox(height: 20),
                AppField(
                  label: 'Пароль',
                  hint: 'Введите пароль',
                  controller: _password,
                  password: true,
                  autofillHint: AutofillHints.password,
                  onChanged: _clearError,
                  onSubmitted: _signIn,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _register,
                  child: const Text(
                    'Зарегистрироваться',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          FilledButton(onPressed: _signIn, child: const Text('ВОЙТИ')),
          ErrorMessage(_error),
        ],
      ),
    ),
  );
}
