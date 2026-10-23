// Учебная авторизация: данные живут только в памяти текущего запуска.
// Для настоящей регистрации замените этот класс обращением к серверу.
const demoEmail = 'i_g_o_r_spirin@mail.ru';
const demoPassword = '456321';

class UserProfile {
  UserProfile({required this.name, required this.surname, required this.email});
  final String name;
  final String surname;
  final String email;
  final List<BmiRecord> history = [];
  String get fullName => '$name $surname'.trim();
}

class AppSession {
  final Map<String, ({UserProfile profile, String password})> _accounts = {
    demoEmail: (
      profile: UserProfile(name: 'Имя', surname: 'Фамилия', email: demoEmail),
      password: demoPassword,
    ),
  };
  UserProfile? _currentUser;
  UserProfile get user => _currentUser!;

  bool signIn(String email, String password) {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) return false;
    _currentUser = account.profile;
    return true;
  }

  bool register({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.containsKey(normalizedEmail)) return false;
    _accounts[normalizedEmail] = (
      profile: UserProfile(
        name: name.trim(),
        surname: surname.trim(),
        email: normalizedEmail,
      ),
      password: password,
    );
    return true;
  }
}

class BmiRecord {
  BmiRecord({required this.height, required this.weight, required this.date});
  final double height;
  final double weight;
  final DateTime date;
  double get bmi => weight / ((height / 100) * (height / 100));

  String get formattedBmi =>
      bmi.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  // Интервалы задания без пересечений: <=16; (16,18.5); [18.5,25);
  // [25,30); [30,35); [35,40); >=40. Сравниваем неокруглённый ИМТ.
  String get category {
    if (bmi <= 16) return 'Выраженный дефицит массы тела';
    if (bmi < 18.5) return 'Недостаточная масса тела';
    if (bmi < 25) return 'Норма';
    if (bmi < 30) return 'Избыточная масса тела или предожирение';
    if (bmi < 35) return 'Ожирение';
    if (bmi < 40) return 'Ожирение резкое';
    return 'Очень резкое ожирение';
  }

  String get recommendation {
    if (bmi <= 16) {
      return 'Выраженный дефицит массы тела. Советуем набрать вес для здоровья.';
    }
    if (bmi < 18.5) {
      return 'Недостаточная масса тела. Рекомендуется увеличить массу тела.';
    }
    if (bmi < 25) {
      return 'Норма. Ваш вес в здоровом диапазоне — поддерживайте его!';
    }
    if (bmi < 30) {
      return 'Избыточная масса тела или предожирение. Желательно снизить вес для улучшения самочувствия.';
    }
    if (bmi < 35) {
      return 'Ожирение. Рекомендуется уменьшить вес под контролем специалиста.';
    }
    if (bmi < 40) {
      return 'Ожирение резкое. Необходимо снижение веса с медицинской поддержкой.';
    }
    return 'Очень резкое ожирение. Требуется срочная коррекция веса под наблюдением врача.';
  }
}

double? parsePositiveNumber(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value.isFinite && value > 0 ? value : null;
}
