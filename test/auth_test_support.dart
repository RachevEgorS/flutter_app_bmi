import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/app_session.dart';
import 'package:flutter_application_1/main.dart';

const demoEmail = 'tester@example.com';
const demoPassword = 'test-password';

Map<String, dynamic> authUser(String email, [Map<String, dynamic>? data]) => {
  'id': email == demoEmail
      ? '11111111-1111-4111-8111-111111111111'
      : '22222222-2222-4222-8222-222222222222',
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': email,
  'created_at': '2026-01-01T00:00:00Z',
  'app_metadata': {'provider': 'email'},
  'user_metadata': data ?? {'name': 'Имя', 'surname': 'Фамилия'},
};

Map<String, dynamic> authSession(Map<String, dynamic> user) => {
  'access_token': 'test-access-token',
  'refresh_token': 'test-refresh-token',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': user,
};

http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {
    'content-type': 'application/json; charset=utf-8',
    'x-supabase-api-version': '2024-01-01',
  },
);

AppSession testSession(FutureOr<http.Response> Function(http.Request) handler) {
  // Start the SDK's JSON isolate outside the widget test's fake clock.
  final client = Zone.root.run(
    () => SupabaseClient(
      'https://test.supabase.co',
      'test-publishable-key',
      httpClient: MockClient((request) async {
        final response = await handler(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    ),
  );
  addTearDown(
    () =>
        TestWidgetsFlutterBinding.ensureInitialized().runAsync(client.dispose),
  );
  return AppSession(client: client);
}

// Fake HTTP transport only: production registration/sign-in code runs unchanged.
AppSession standardTestSession({bool confirmEmail = false}) {
  final records = <Map<String, dynamic>>[];
  final accounts = <String, ({String password, Map<String, dynamic> user})>{
    demoEmail: (password: demoPassword, user: authUser(demoEmail)),
  };
  return testSession((request) {
    if (request.url.path == '/rest/v1/body_mass_index_calculations') {
      if (request.method == 'POST') {
        final row = jsonDecode(request.body) as Map<String, dynamic>;
        row['id'] =
            '33333333-3333-4333-8333-${records.length.toString().padLeft(12, '0')}';
        row['created_at'] = DateTime.now().toUtc().toIso8601String();
        records.insert(0, row);
        return jsonResponse(row, 201);
      }
      final userId = request.url.queryParameters['user_id']!.substring(3);
      return jsonResponse(
        records.where((row) => row['user_id'] == userId).toList(),
      );
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final email = body['email'] as String;
    if (request.url.path == '/auth/v1/signup') {
      if (accounts.containsKey(email)) {
        return jsonResponse({
          'code': 'user_already_exists',
          'msg': 'User already registered',
        }, 422);
      }
      final user = authUser(email, body['data'] as Map<String, dynamic>);
      accounts[email] = (password: body['password'] as String, user: user);
      return jsonResponse(confirmEmail ? user : authSession(user));
    }
    expect(request.url.path, '/auth/v1/token');
    expect(request.url.queryParameters['grant_type'], 'password');
    final account = accounts[email];
    if (account == null || account.password != body['password']) {
      return jsonResponse({
        'code': 'invalid_credentials',
        'msg': 'Invalid login credentials',
      }, 400);
    }
    return jsonResponse(authSession(account.user));
  });
}

Future<void> pumpTestApp(WidgetTester tester) async {
  await tester.pumpWidget(MyApp(session: standardTestSession()));
  await tester.enterText(find.byType(TextFormField).first, demoEmail);
  await tester.enterText(find.byType(TextFormField).last, demoPassword);
}
