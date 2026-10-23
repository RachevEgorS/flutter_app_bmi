import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

const _green = Color(0xFF4CAF50);
const _background = Color(0xFFF5F5F5);
const _gray = Color(0xFF808080);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Регистрация',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _green),
        scaffoldBackgroundColor: _background,
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: _gray, fontSize: 16),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFAAAAAA)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: _green, width: 2),
          ),
          errorMaxLines: 2,
        ),
      ),
      home: const RegistrationPage(),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = false;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchPage() {
    FocusScope.of(context).unfocus();
    _formKey.currentState?.reset();
    _password.clear();
    setState(() {
      _isLogin = !_isLogin;
      _submitted = false;
    });
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Подключите запрос к серверу здесь. Пароль не сохраняется на устройстве.
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Данные проверены'),
        content: Text(
          _isLogin
              ? 'Это демонстрация формы входа. Сервер авторизации пока не подключён.'
              : 'Форма заполнена верно. Для создания аккаунта нужно подключить сервер регистрации.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  String? _requiredName(String? value) =>
      value == null || value.trim().isEmpty ? 'Заполните это поле' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = (constraints.maxWidth / 12).clamp(
              20.0,
              40.0,
            );
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isLogin ? 'Вход' : 'Регистрация',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _green,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x26A18B8B),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _submitted
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!_isLogin) ...[
                                    _field(
                                      label: 'Имя',
                                      hint: 'Введите ваше имя',
                                      controller: _name,
                                      validator: _requiredName,
                                      capitalization: TextCapitalization.words,
                                      autofillHint: AutofillHints.givenName,
                                    ),
                                    const SizedBox(height: 18),
                                    _field(
                                      label: 'Фамилия',
                                      hint: 'Введите вашу фамилию',
                                      controller: _surname,
                                      validator: _requiredName,
                                      capitalization: TextCapitalization.words,
                                      autofillHint: AutofillHints.familyName,
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  _field(
                                    label: 'Email',
                                    hint: 'example@gmail.com',
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHint: AutofillHints.email,
                                    validator: (value) {
                                      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                          .hasMatch(value?.trim() ?? '')) {
                                        return 'Введите корректный email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  _field(
                                    label: 'Пароль',
                                    hint: 'Введите пароль',
                                    controller: _password,
                                    isPassword: true,
                                    autofillHint: _isLogin
                                        ? AutofillHints.password
                                        : AutofillHints.newPassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Введите пароль';
                                      }
                                      if (!_isLogin && value.length < 8) {
                                        return 'Используйте минимум 8 символов';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _switchPage,
                                    style: TextButton.styleFrom(
                                      foregroundColor: _green,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      _isLogin
                                          ? 'Перейти к регистрации'
                                          : 'Вернуться к странице входа',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isLogin ? 'ВОЙТИ' : 'СОЗДАТЬ АККАУНТ',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required String autofillHint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _gray, fontSize: 16)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: isPassword,
          autocorrect: !isPassword && keyboardType == TextInputType.text,
          enableSuggestions: !isPassword,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          autofillHints: [autofillHint],
          textInputAction: isPassword
              ? TextInputAction.done
              : TextInputAction.next,
          onFieldSubmitted: isPassword ? (_) => _submit() : null,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: const TextStyle(fontSize: 16, color: Color(0xFF424242)),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
