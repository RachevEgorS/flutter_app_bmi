import 'package:supabase_flutter/supabase_flutter.dart';

String calculationErrorMessage(Object error, {required bool saving}) {
  if (error is AuthException ||
      error is PostgrestException && error.code == 'PGRST301') {
    return 'Сессия истекла. Войдите в аккаунт заново.';
  }
  if (error is PostgrestException && error.code == '42501') {
    return 'Нет доступа к истории расчётов. Обратитесь к администратору приложения.';
  }
  return saving
      ? 'Не удалось подтвердить сохранение. Проверьте интернет и историю в профиле перед повторной попыткой.'
      : 'Не удалось загрузить историю. Проверьте интернет и повторите попытку.';
}
