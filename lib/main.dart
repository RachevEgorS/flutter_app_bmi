import 'package:flutter/material.dart';

import 'app_session.dart';
import 'app_ui.dart';
import 'auth_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _session = AppSession();
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Индекс массы тела',
    theme: buildAppTheme(),
    home: AuthScreen(session: _session),
  );
}
