import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/auth_error_message.dart';
import 'package:flutter_application_1/auth_screen.dart';
import 'package:flutter_application_1/bmi_screen.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/app_session.dart';

import 'auth_test_support.dart';
import 'widget_test.dart' show tapText;

Future<void> fillRegistration(WidgetTester tester, AppSession session) async {
  await tester.pumpWidget(MyApp(session: session));
  await tapText(tester, 'Зарегистрироваться');
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), ' Анна ');
  await tester.enterText(fields.at(1), ' Иванова ');
  await tester.enterText(fields.at(2), ' Anna@Example.com ');
  await tester.enterText(fields.at(3), ' secret123 ');
}

void main() {
  testWidgets('Login starts empty and does not send incomplete credentials', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      MyApp(
        session: testSession((_) {
          requests++;
          return jsonResponse({});
        }),
      ),
    );
    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.controller!.text, isEmpty);
    }
    await tapText(tester, 'ВОЙТИ');
    expect(requests, 0);
    expect(find.text('Введите email и пароль'), findsOneWidget);
  });

  testWidgets('Registration sends metadata and preserves password whitespace', (
    tester,
  ) async {
    var requests = 0;
    final session = testSession((request) {
      requests++;
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/v1/signup');
      expect(request.headers['apikey'], 'test-publishable-key');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['email'], 'anna@example.com');
      expect(body['password'], ' secret123 ');
      expect(body['data'], {'name': 'Анна', 'surname': 'Иванова'});
      return jsonResponse(authUser('anna@example.com'));
    });
    await fillRegistration(tester, session);
    await tapText(tester, 'СОЗДАТЬ АККАУНТ');
    expect(requests, 1);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(BmiScreen), findsNothing);
    expect(find.textContaining('Проверьте почту'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets(
    'Pending registration ignores double submit and survives leaving',
    (tester) async {
      var requests = 0;
      final response = Completer<http.Response>();
      final session = testSession((_) {
        requests++;
        return response.future;
      });
      await fillRegistration(tester, session);
      final callback = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      callback();
      callback();
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.text('СОЗДАЁМ АККАУНТ…'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      response.complete(jsonResponse(authUser('anna@example.com')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AuthScreen), findsOneWidget);
    },
  );

  testWidgets('Server failure keeps form and allows retry', (tester) async {
    var requests = 0;
    final session = testSession((_) {
      requests++;
      return requests == 1
          ? jsonResponse({
              'code': 'over_email_send_rate_limit',
              'msg': 'Too many requests',
            }, 429)
          : jsonResponse(authUser('anna@example.com'));
    });
    await fillRegistration(tester, session);
    await tapText(tester, 'СОЗДАТЬ АККАУНТ');
    expect(find.textContaining('Слишком много попыток'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tapText(tester, 'СОЗДАТЬ АККАУНТ');
    expect(requests, 2);
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('Unconfirmed email cannot enter calculator', (tester) async {
    await tester.pumpWidget(
      MyApp(
        session: testSession(
          (_) => jsonResponse({
            'code': 'email_not_confirmed',
            'msg': 'Email not confirmed',
          }, 400),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, demoEmail);
    await tester.enterText(find.byType(TextFormField).last, demoPassword);
    await tapText(tester, 'ВОЙТИ');
    expect(find.textContaining('Подтвердите email'), findsOneWidget);
    expect(find.byType(BmiScreen), findsNothing);
  });

  test('Authenticated profile uses Supabase user ID and metadata', () async {
    final session = standardTestSession();
    final result = await session.register(
      name: 'Анна',
      surname: 'Иванова',
      email: 'anna@example.com',
      password: 'secret123',
    );
    expect(result.requiresEmailConfirmation, isFalse);
    await session.signIn('anna@example.com', 'secret123');
    expect(session.user.id, '22222222-2222-4222-8222-222222222222');
    expect(session.user.fullName, 'Анна Иванова');
  });

  test('Network and password errors have safe Russian messages', () {
    expect(
      authErrorMessage(AuthRetryableFetchException(message: 'network down')),
      contains('Проверьте интернет'),
    );
    expect(
      authErrorMessage(const AuthException('weak', code: 'weak_password')),
      contains('Пароль слишком простой'),
    );
    expect(
      authErrorMessage(const AuthException('internal details')),
      isNot(contains('internal details')),
    );
  });
}
