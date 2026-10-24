import 'package:flutter/material.dart';

import 'app_session.dart';
import 'app_ui.dart';
import 'auth_error_message.dart';
import 'bmi_screen.dart';
import 'registration_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.session});
  final AppSession session;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _isLoading = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Введите email и пароль');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.session.signIn(_email.text, _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BmiScreen(session: widget.session),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(context).push<RegistrationResult>(
      MaterialPageRoute(
        builder: (_) => RegistrationScreen(session: widget.session),
      ),
    );
    if (!mounted || result == null) return;
    _email.text = result.email;
    _password.clear();
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: Text(
          result.requiresEmailConfirmation
              ? 'Проверьте почту и подтвердите email по ссылке в письме, затем войдите. Если аккаунт уже существует, используйте свой пароль.'
              : 'Аккаунт создан. Введите пароль для входа.',
        ),
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
            child: AbsorbPointer(
              absorbing: _isLoading,
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
                    onPressed: _isLoading ? null : _register,
                    child: const Text(
                      'Зарегистрироваться',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: _isLoading ? null : _signIn,
            child: Text(_isLoading ? 'ВХОД…' : 'ВОЙТИ'),
          ),
          ErrorMessage(_error),
        ],
      ),
    ),
  );
}
