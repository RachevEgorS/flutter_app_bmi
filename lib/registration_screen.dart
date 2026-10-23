import 'package:flutter/material.dart';

import 'app_session.dart';
import 'app_ui.dart';

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
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _surname, _email, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _register() {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;
    final created = widget.session.register(
      name: _name.text,
      surname: _surname.text,
      email: _email.text,
      password: _password.text,
    );
    if (!created) {
      setState(() => _error = 'Этот email уже зарегистрирован');
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_email.text.trim());
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
                    validator: (value) => (value?.trim().length ?? 0) >= 6
                        ? null
                        : 'Используйте минимум 6 символов',
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Вернуться к странице входа',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _register,
            child: const Text('СОЗДАТЬ АККАУНТ', textAlign: TextAlign.center),
          ),
          if (_error != null) ErrorMessage(_error),
        ],
      ),
    ),
  );
}
