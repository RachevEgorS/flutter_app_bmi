import 'package:flutter/material.dart';

import 'app_session.dart';
import 'app_ui.dart';
import 'auth_error_message.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.session});
  final AppSession session;
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _surname, _email, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (_isLoading) return;
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final result = await widget.session.register(
        name: _name.text,
        surname: _surname.text,
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Заполните это поле' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ScreenBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeading('Регистрация'),
          const SizedBox(height: 20),
          AppCard(
            child: AbsorbPointer(
              absorbing: _isLoading,
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppField(
                      label: 'Имя',
                      hint: 'Введите ваше имя',
                      controller: _name,
                      validator: _required,
                      capitalization: TextCapitalization.words,
                      autofillHint: AutofillHints.givenName,
                    ),
                    const SizedBox(height: 18),
                    AppField(
                      label: 'Фамилия',
                      hint: 'Введите вашу фамилию',
                      controller: _surname,
                      validator: _required,
                      capitalization: TextCapitalization.words,
                      autofillHint: AutofillHints.familyName,
                    ),
                    const SizedBox(height: 18),
                    AppField(
                      label: 'Email',
                      hint: 'example@gmail.com',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHint: AutofillHints.email,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      validator: (value) =>
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Введите корректный email',
                    ),
                    const SizedBox(height: 18),
                    AppField(
                      label: 'Пароль',
                      hint: 'Введите пароль',
                      controller: _password,
                      password: true,
                      autofillHint: AutofillHints.newPassword,
                      onSubmitted: _register,
                      validator: (value) =>
                          (value?.length ?? 0) >= 6 && value!.trim().isNotEmpty
                          ? null
                          : 'Используйте минимум 6 символов',
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text(
                        'Вернуться к странице входа',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoading ? null : _register,
            child: Text(
              _isLoading ? 'СОЗДАЁМ АККАУНТ…' : 'СОЗДАТЬ АККАУНТ',
              textAlign: TextAlign.center,
            ),
          ),
          if (_error != null) ErrorMessage(_error),
        ],
      ),
    ),
  );
}
