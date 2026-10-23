import 'package:flutter/material.dart';

import 'app_session.dart';
import 'app_ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: AppBottomBar(
      profileSelected: true,
      onCalculator: () => Navigator.of(context).pop(),
      onProfile: () {},
    ),
    body: ScreenBody(
      centered: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appBackground,
                    border: Border.all(color: appGreen, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 58,
                    color: appGray,
                    semanticLabel: 'Аватар пользователя',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: appGray,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: appGray, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const AppCard(
            padding: EdgeInsets.all(18),
            child: Text(
              'Активность',
              style: TextStyle(
                color: appGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (user.history.isEmpty)
            const AppCard(
              child: Text(
                'Расчётов пока нет. Перейдите в калькулятор и рассчитайте свой ИМТ.',
                style: TextStyle(color: appGray, fontSize: 16),
              ),
            ),
          for (final record in user.history) ...[
            _HistoryCard(record: record),
            const SizedBox(height: 18),
          ],
        ],
      ),
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});
  final BmiRecord record;

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (day == today) return 'Сегодня, $time';
    if (day == yesterday) return 'Вчера, $time';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}, $time';
  }

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detail('Время расчёта', _dateLabel(record.date)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 22,
          runSpacing: 12,
          children: [
            _detail('Рост', '${_number(record.height)} см'),
            _detail('Вес', '${_number(record.weight)} кг'),
            _detail('Индекс массы тела', record.bmi.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 16),
        _detail('Оценка ИМТ', record.category),
      ],
    ),
  );

  String _number(double number) => number == number.roundToDouble()
      ? number.toStringAsFixed(0)
      : number.toString();

  Widget _detail(String label, String value) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: appGray, fontSize: 16)),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
