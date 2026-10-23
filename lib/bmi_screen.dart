import 'package:flutter/material.dart';

import 'app_session.dart';
import 'app_ui.dart';
import 'profile_screen.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key, required this.session});
  final AppSession session;
  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final _height = TextEditingController(text: '185');
  final _weight = TextEditingController(text: '77');
  String? _error;
  BmiRecord? _result;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (_height.text.trim().isEmpty || _weight.text.trim().isEmpty) {
      setState(() {
        _error = 'Заполните все поля!';
        _result = null;
      });
      return;
    }
    final height = parsePositiveNumber(_height.text);
    final weight = parsePositiveNumber(_weight.text);
    if (height == null || weight == null) {
      setState(() {
        _error = 'Введите рост и вес числами больше нуля';
        _result = null;
      });
      return;
    }
    final record = BmiRecord(
      height: height,
      weight: weight,
      date: DateTime.now(),
    );
    if (!record.bmi.isFinite || record.bmi <= 0) {
      setState(() {
        _error = 'Проверьте значения роста и веса';
        _result = null;
      });
      return;
    }
    widget.session.user.history.insert(0, record);
    setState(() {
      _error = null;
      _result = record;
    });
  }

  void _onChanged(String _) {
    if (_error != null || _result != null) {
      setState(() {
        _error = null;
        _result = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: AppBottomBar(
      profileSelected: false,
      onCalculator: () {},
      onProfile: () {
        FocusScope.of(context).unfocus();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProfileScreen(user: widget.session.user),
          ),
        );
      },
    ),
    body: ScreenBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeading('Индекс массы тела'),
          const SizedBox(height: 22),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Персональные данные',
                  style: TextStyle(
                    color: appGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                AppField(
                  label: 'Рост (см)',
                  hint: 'Введите рост',
                  controller: _height,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: _onChanged,
                ),
                const SizedBox(height: 18),
                AppField(
                  label: 'Вес (кг)',
                  hint: 'Введите вес',
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: _onChanged,
                  onSubmitted: _calculate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _calculate, child: const Text('РАССЧИТАТЬ')),
          if (_result == null) ErrorMessage(_error),
          if (_result != null) ...[
            const SizedBox(height: 20),
            AppCard(
              child: Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    Text(
                      'Ваш ИМТ: ${_result!.bmi.toStringAsFixed(1)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: appGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result!.category,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Оценка для взрослых от 20 лет. ИМТ не является диагнозом.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: appGray, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
