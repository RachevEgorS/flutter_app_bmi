import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Empty registration shows errors; valid form shows demo result', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('СОЗДАТЬ АККАУНТ'));
    await tester.tap(find.text('СОЗДАТЬ АККАУНТ'));
    await tester.pumpAndSettle();
    expect(find.text('Заполните это поле'), findsNWidgets(2));
    expect(find.text('Введите корректный email'), findsOneWidget);
    expect(find.text('Введите пароль'), findsWidgets);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Анна');
    await tester.enterText(fields.at(1), 'Иванова');
    await tester.enterText(fields.at(2), 'anna@example.com');
    await tester.enterText(fields.at(3), 'example123');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('СОЗДАТЬ АККАУНТ'));
    await tester.tap(find.text('СОЗДАТЬ АККАУНТ'));
    await tester.pumpAndSettle();
    expect(find.text('Данные проверены'), findsOneWidget);
  });

  testWidgets('Login link opens login form and clears password', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextFormField).last, 'example123');
    await tester.ensureVisible(find.text('Вернуться к странице входа'));
    await tester.tap(find.text('Вернуться к странице входа'));
    await tester.pumpAndSettle();
    expect(find.text('Вход'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      isEmpty,
    );
    await tester.tap(find.text('Перейти к регистрации'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('Small screen with keyboard and large text remains scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: const MyApp(),
      ),
    );
    await tester.ensureVisible(find.text('СОЗДАТЬ АККАУНТ'));
    await tester.tap(find.text('СОЗДАТЬ АККАУНТ'));
    await tester.pumpAndSettle();
    expect(find.text('Введите корректный email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
