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
      profile: UserProfile(name: 'Пользователь', surname: '', email: demoEmail),
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

  // Категории для взрослых 20+: https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html
  String get category {
    if (bmi < 18.5) return 'Недостаточная масса тела';
    if (bmi < 25) return 'Нормальная масса тела';
    if (bmi < 30) return 'Избыточная масса тела';
    return 'Ожирение';
  }
}

double? parsePositiveNumber(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value.isFinite && value > 0 ? value : null;
}
