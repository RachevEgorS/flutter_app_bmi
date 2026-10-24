import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(Object error) {
  if (error is AuthRetryableFetchException) {
    return 'Не удалось связаться с сервером. Проверьте интернет и повторите попытку.';
  }
  if (error is AuthException) {
    switch (error.code) {
      case 'user_already_exists':
      case 'email_exists':
        return 'Этот email уже зарегистрирован';
      case 'email_address_invalid':
      case 'validation_failed':
        return 'Проверьте email и пароль';
      case 'email_address_not_authorized':
        return 'Отправка писем на этот адрес пока недоступна. Обратитесь к администратору приложения.';
      case 'weak_password':
        return 'Пароль слишком простой. Используйте более длинный пароль с буквами, цифрами и символами.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Слишком много попыток. Подождите несколько минут и попробуйте снова.';
      case 'signup_disabled':
      case 'email_provider_disabled':
        return 'Регистрация по email временно недоступна';
      case 'email_not_confirmed':
        return 'Подтвердите email по ссылке в письме, затем войдите.';
      case 'invalid_credentials':
        return 'Неверный email или пароль';
    }
    if (error.statusCode == '429') {
      return 'Слишком много попыток. Подождите несколько минут и попробуйте снова.';
    }
  }
  return 'Не удалось выполнить запрос. Проверьте подключение и повторите попытку.';
}
