import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app_session.dart';
import 'package:flutter_application_1/auth_screen.dart';
import 'package:flutter_application_1/bmi_screen.dart';
import 'package:flutter_application_1/profile_screen.dart';
import 'package:flutter_application_1/registration_screen.dart';
import 'package:flutter_application_1/app_ui.dart';

import 'auth_test_support.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Login rejects wrong credentials and accepts the specified account',
    (tester) async {
      await pumpTestApp(tester);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        demoEmail,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        demoPassword,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue,
      );
      expect(find.text('Неверный email или пароль'), findsNothing);
      await tester.enterText(find.byType(TextFormField).last, 'wrong');
      await tapText(tester, 'ВОЙТИ');
      expect(find.text('Неверный email или пароль'), findsOneWidget);
      expect(find.byType(BmiScreen), findsNothing);
      await tester.enterText(find.byType(TextFormField).last, demoPassword);
      await tapText(tester, 'ВОЙТИ');
      expect(find.byType(BmiScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Registration validates, rejects duplicate email, and creates a Supabase account',
    (tester) async {
      await pumpTestApp(tester);
      await tapText(tester, 'Зарегистрироваться');
      expect(find.byType(RegistrationScreen), findsOneWidget);
      await tapText(tester, 'СОЗДАТЬ АККАУНТ');
      expect(find.text('Заполните это поле'), findsNWidgets(2));
      expect(find.text('Введите корректный email'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Анна');
      await tester.enterText(fields.at(1), 'Иванова');
      await tester.enterText(fields.at(2), demoEmail);
      await tester.enterText(fields.at(3), 'secret123');
      await tapText(tester, 'СОЗДАТЬ АККАУНТ');
      expect(find.text('Этот email уже зарегистрирован'), findsOneWidget);
      await tester.enterText(fields.at(2), 'anna@example.com');
      await tapText(tester, 'СОЗДАТЬ АККАУНТ');
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'anna@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'secret123');
      await tapText(tester, 'ВОЙТИ');
      await tapText(tester, 'Профиль');
      expect(find.text('Анна Иванова'), findsOneWidget);
      expect(find.text('anna@example.com'), findsOneWidget);
    },
  );

  testWidgets('Registration back link returns to login', (tester) async {
    await pumpTestApp(tester);
    await tapText(tester, 'Зарегистрироваться');
    await tapText(tester, 'Вернуться к странице входа');
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets(
    'Calculator validates inputs and profile preserves real history',
    (tester) async {
      await pumpTestApp(tester);
      await tapText(tester, 'ВОЙТИ');
      expect(find.text('Ваш индекс массы тела:'), findsNothing);
      await tapText(tester, 'Профиль');
      expect(find.textContaining('Расчётов пока нет'), findsOneWidget);
      await tapText(tester, 'Калькулятор');
      await tester.enterText(find.byType(TextFormField).first, '');
      await tapText(tester, 'РАССЧИТАТЬ');
      expect(find.text('Заполните все поля'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '0');
      await tapText(tester, 'РАССЧИТАТЬ');
      expect(
        find.text('Введите рост и вес числами больше нуля'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField).first, '185');
      await tester.enterText(find.byType(TextFormField).last, '77,0');
      await tapText(tester, 'РАССЧИТАТЬ');
      expect(find.text('Ваш индекс массы тела:'), findsOneWidget);
      await tapText(tester, 'Профиль');
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('22.5'), findsOneWidget);
      expect(find.text('Рекомендация'), findsOneWidget);
      expect(
        find.text('Норма. Ваш вес в здоровом диапазоне — поддерживайте его!'),
        findsOneWidget,
      );
      expect(find.text('185 см'), findsOneWidget);
      expect(find.textContaining('Сегодня,'), findsOneWidget);
      await tapText(tester, 'Калькулятор');
      expect(find.text('Ваш индекс массы тела:'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).last, '80');
      await tester.pump();
      expect(find.text('Ваш индекс массы тела:'), findsNothing);
    },
  );

  testWidgets(
    'Small display with keyboard and enlarged text supports all screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpTestApp(tester);
      await tapText(tester, 'Зарегистрироваться');
      await tapText(tester, 'СОЗДАТЬ АККАУНТ');
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Вернуться к странице входа');
      await tapText(tester, 'ВОЙТИ');
      await tapText(tester, 'РАССЧИТАТЬ');
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Профиль');
      expect(tester.takeException(), isNull);
    },
  );

  test('BMI formula, category boundaries, and number parsing', () {
    BmiRecord record(double weight) =>
        BmiRecord(height: 100, weight: weight, date: DateTime(2026));
    expect(
      BmiRecord(height: 185, weight: 77, date: DateTime(2026)).bmi,
      closeTo(22.498, 0.001),
    );
    expect(record(18.49).category, 'Недостаточная масса тела');
    expect(record(18.5).category, 'Норма');
    expect(record(24.99).category, 'Норма');
    expect(record(25).category, 'Избыточная масса тела или предожирение');
    expect(record(30).category, 'Ожирение');
    for (final entry in <double, String>{
      15.99: 'Выраженный дефицит массы тела',
      16: 'Выраженный дефицит массы тела',
      16.01: 'Недостаточная масса тела',
      24.999: 'Норма',
      29.999: 'Избыточная масса тела или предожирение',
      34.999: 'Ожирение',
      35: 'Ожирение резкое',
      39.999: 'Ожирение резкое',
      40: 'Очень резкое ожирение',
      45: 'Очень резкое ожирение',
    }.entries) {
      expect(record(entry.key).category, entry.value);
      expect(record(entry.key).recommendation, startsWith('${entry.value}.'));
    }
    expect(record(22.5).formattedBmi, '22.5');
    expect(record(25.25).formattedBmi, '25.25');
    expect(parsePositiveNumber('77,5'), 77.5);
    for (final invalid in ['', '0', '-1', 'NaN', 'Infinity', 'abc']) {
      expect(parsePositiveNumber(invalid), isNull);
    }
  });

  testWidgets(
    'Calculator stays centered, result matches design and both footers are 60 high',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpTestApp(tester);
      final authTitleStyle = tester
          .widget<Text>(find.text('Вход в приложение'))
          .style;
      await tapText(tester, 'ВОЙТИ');
      expect(
        tester.widget<Text>(find.text('Индекс массы тела')).style,
        authTitleStyle,
      );

      void checkGeometry() {
        final footer = tester.getRect(
          find.byKey(const ValueKey('footer-content')),
        );
        final content = tester.getRect(
          find.byKey(const ValueKey('calculator-content')),
        );
        expect(footer.height, 60);
        expect(content.center.dx, closeTo(195, 0.1));
        expect(content.center.dy, closeTo(footer.top / 2, 0.1));
        final input = tester.getRect(
          find.byKey(const ValueKey('bmi-input-card')),
        );
        final button = tester.getRect(
          find.byKey(const ValueKey('calculate-button')),
        );
        expect(button.left, input.left);
        expect(button.width, input.width);
      }

      checkGeometry();
      expect(find.byKey(const ValueKey('bmi-result-card')), findsNothing);
      await tapText(tester, 'РАССЧИТАТЬ');
      checkGeometry();
      final result = tester.widget<AppCard>(
        find.byKey(const ValueKey('bmi-result-card')),
      );
      expect(result.color, const Color(0xFFE8F5E9));
      expect(
        tester.widget<Text>(find.text('Ваш индекс массы тела:')).textAlign,
        TextAlign.left,
      );
      expect(
        tester.widget<Text>(find.text('22.5')).textAlign,
        TextAlign.center,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('bmi-result-card'))).width,
        tester.getSize(find.byKey(const ValueKey('bmi-input-card'))).width,
      );
      await tapText(tester, 'Профиль');
      expect(
        tester.getSize(find.byKey(const ValueKey('footer-content'))).height,
        60,
      );
      await tapText(tester, 'Калькулятор');
      expect(find.text('22.5'), findsOneWidget);
    },
  );
}
