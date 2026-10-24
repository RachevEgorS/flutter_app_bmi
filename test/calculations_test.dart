import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/app_session.dart';
import 'package:flutter_application_1/app_ui.dart';
import 'package:flutter_application_1/bmi_screen.dart';
import 'package:flutter_application_1/profile_screen.dart';

import 'auth_test_support.dart';
import 'widget_test.dart' show tapText;

const userId = '11111111-1111-4111-8111-111111111111';
const savedId = '33333333-3333-4333-8333-333333333333';

Map<String, dynamic> savedRow({String id = savedId}) => {
  'id': id,
  'created_at': '2026-01-02T10:30:00+03:00',
  'height': 185,
  'weight': 77,
  'body_mass_index': 22.5,
  'recommendation': 'Рекомендация с сервера',
  'user_id': userId,
};

AppSession databaseSession(
  FutureOr<http.Response> Function(http.Request) handler,
) => testSession((request) {
  if (request.url.path == '/auth/v1/token') {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    return jsonResponse(authSession(authUser(body['email'] as String)));
  }
  expect(request.url.path, '/rest/v1/body_mass_index_calculations');
  return handler(request);
});

BmiRecord calculation({double weight = 77}) =>
    BmiRecord(height: 185, weight: weight, date: DateTime(2026));

Future<void> pumpCalculator(WidgetTester tester, AppSession session) async {
  await session.signIn(demoEmail, demoPassword);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: BmiScreen(session: session),
    ),
  );
}

void main() {
  test(
    'Insert uses current auth user and lets PostgreSQL generate ID and date',
    () async {
      final session = databaseSession((request) {
        expect(request.method, 'POST');
        expect(request.headers['authorization'], 'Bearer test-access-token');
        expect(request.headers['prefer'], contains('return=representation'));
        final row = jsonDecode(request.body) as Map<String, dynamic>;
        expect(
          row.keys,
          unorderedEquals([
            'height',
            'weight',
            'body_mass_index',
            'recommendation',
            'user_id',
          ]),
        );
        expect(row['height'], 185);
        expect(row['weight'], 77);
        expect(row['body_mass_index'], closeTo(22.4981738495, 0.0000001));
        expect(row['recommendation'], calculation().recommendation);
        expect(row['user_id'], userId);
        return jsonResponse(savedRow(), 201);
      });
      await session.signIn(demoEmail, demoPassword);
      final record = await session.saveCalculation(calculation());
      expect(record.id, savedId);
      expect(record.date.toUtc(), DateTime.utc(2026, 1, 2, 7, 30));
      expect(record.bmi, 22.5);
      expect(record.recommendation, 'Рекомендация с сервера');
    },
  );

  test(
    'A new app session reads persisted rows scoped to its authenticated user',
    () async {
      final rows = <Map<String, dynamic>>[];
      final queries = <Map<String, String>>[];
      http.Response handler(http.Request request) {
        if (request.method == 'POST') {
          final row = jsonDecode(request.body) as Map<String, dynamic>;
          row.addAll({'id': savedId, 'created_at': '2026-01-02T07:30:00Z'});
          rows.add(row);
          return jsonResponse(row, 201);
        }
        final query = request.url.queryParameters;
        queries.add(query);
        return jsonResponse(
          rows
              .where((row) => 'eq.${row['user_id']}' == query['user_id'])
              .toList(),
        );
      }

      final first = databaseSession(handler);
      await first.signIn(demoEmail, demoPassword);
      await first.saveCalculation(calculation());
      final restarted = databaseSession(handler);
      await restarted.signIn(demoEmail, demoPassword);
      final history = await restarted.loadHistory();
      expect(history.single.id, savedId);
      expect(queries.last['user_id'], 'eq.$userId');
      expect(
        queries.last['order'],
        'created_at.desc.nullslast,id.desc.nullslast',
      );
      expect(queries.last['offset'], '0');
      expect(queries.last['limit'], '50');
      await restarted.loadHistory(offset: 50);
      expect(queries.last['offset'], '50');
      await restarted.signIn('other@example.com', demoPassword);
      expect(await restarted.loadHistory(), isEmpty);
      expect(
        queries.last['user_id'],
        'eq.22222222-2222-4222-8222-222222222222',
      );
    },
  );

  test(
    'Unauthenticated writes and fractional measurements never reach database',
    () async {
      var requests = 0;
      final session = databaseSession((_) {
        requests++;
        return jsonResponse({});
      });
      await expectLater(
        session.saveCalculation(calculation()),
        throwsA(isA<AuthException>()),
      );
      await expectLater(session.loadHistory(), throwsA(isA<AuthException>()));
      await session.signIn(demoEmail, demoPassword);
      for (final weight in [77.5, 0.0, double.infinity, 1e20]) {
        await expectLater(
          session.saveCalculation(calculation(weight: weight)),
          throwsArgumentError,
        );
      }
      expect(requests, 0);
    },
  );

  testWidgets(
    'Pending save blocks duplicate submits and success shows server result',
    (tester) async {
      final response = Completer<http.Response>();
      var requests = 0;
      final session = databaseSession((_) {
        requests++;
        return response.future;
      });
      await pumpCalculator(tester, session);
      final submit = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      await tester.tap(find.byType(FilledButton));
      submit();
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.byKey(const ValueKey('bmi-result-card')), findsNothing);
      expect(find.text('СОХРАНЯЕМ…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      response.complete(jsonResponse(savedRow(), 201));
      await tester.pumpAndSettle();
      expect(find.text('22.5'), findsOneWidget);
      expect(find.text('Рекомендация с сервера'), findsOneWidget);
      expect(find.text('РАССЧИТАТЬ'), findsOneWidget);
    },
  );

  testWidgets(
    'Failed save shows error without a phantom result and can retry',
    (tester) async {
      var requests = 0;
      final session = databaseSession((_) {
        requests++;
        return requests == 1
            ? jsonResponse({'code': '42501', 'message': 'RLS denied'}, 403)
            : jsonResponse(savedRow(), 201);
      });
      await pumpCalculator(tester, session);
      await tapText(tester, 'РАССЧИТАТЬ');
      expect(find.textContaining('Нет доступа'), findsOneWidget);
      expect(find.byKey(const ValueKey('bmi-result-card')), findsNothing);
      await tapText(tester, 'РАССЧИТАТЬ');
      expect(requests, 2);
      expect(find.byKey(const ValueKey('bmi-result-card')), findsOneWidget);
    },
  );

  testWidgets('Fractional input is rejected without silently rounding', (
    tester,
  ) async {
    var requests = 0;
    final session = databaseSession((_) {
      requests++;
      return jsonResponse(savedRow(), 201);
    });
    await pumpCalculator(tester, session);
    await tester.enterText(find.byType(TextFormField).last, '77,5');
    await tapText(tester, 'РАССЧИТАТЬ');
    expect(find.textContaining('целыми числами'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets(
    'Profile distinguishes load failure from empty history and retries',
    (tester) async {
      var requests = 0;
      final session = databaseSession((_) {
        requests++;
        return requests == 1
            ? jsonResponse({'code': '42501', 'message': 'RLS denied'}, 403)
            : jsonResponse([savedRow()]);
      });
      await pumpCalculator(tester, session);
      await tapText(tester, 'Профиль');
      expect(find.textContaining('Расчётов пока нет'), findsNothing);
      expect(find.textContaining('Нет доступа'), findsOneWidget);
      await tapText(tester, 'Повторить загрузку');
      expect(find.text('Рекомендация с сервера'), findsOneWidget);
      expect(find.text('185 см'), findsOneWidget);
      expect(find.textContaining('Нет доступа'), findsNothing);
      await tapText(tester, 'Калькулятор');
      await tapText(tester, 'Профиль');
      expect(requests, 3);
    },
  );

  testWidgets('Late history response after leaving profile is safe', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    final session = databaseSession((_) => response.future);
    await pumpCalculator(tester, session);
    await tester.tap(find.text('Профиль'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    response.complete(jsonResponse([savedRow()]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
