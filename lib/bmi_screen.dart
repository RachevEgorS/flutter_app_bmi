import 'package:flutter/material.dart';

import 'app_session.dart';
import 'app_ui.dart';
import 'calculation_error_message.dart';
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
  bool _isSaving = false;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (_height.text.trim().isEmpty || _weight.text.trim().isEmpty) {
      setState(() {
        _error = 'Заполните все поля';
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
    if (!isDatabaseMeasurement(height) || !isDatabaseMeasurement(weight)) {
      setState(() {
        _error = 'Введите рост и вес целыми числами без дробной части и слишком больших значений';
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
    setState(() {
      _error = null;
      _result = null;
      _isSaving = true;
    });
    try {
      final savedRecord = await widget.session.saveCalculation(record);
      if (!mounted) return;
      setState(() => _result = savedRecord);
    } catch (error) {
      if (mounted) {
        setState(() => _error = calculationErrorMessage(error, saving: true));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        if (_isSaving) return;
        FocusScope.of(context).unfocus();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProfileScreen(session: widget.session),
          ),
        );
      },
    ),
    body: ScreenBody(
      child: Column(
        key: const ValueKey('calculator-content'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeading('Индекс массы тела'),
          const SizedBox(height: 22),
          AppCard(
            key: const ValueKey('bmi-input-card'),
            child: AbsorbPointer(
              absorbing: _isSaving,
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
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('calculate-button'),
            onPressed: _isSaving ? null : _calculate,
            child: Text(_isSaving ? 'СОХРАНЯЕМ…' : 'РАССЧИТАТЬ'),
          ),
          if (_error != null) ErrorMessage(_error),
          if (_result != null) ...[
            const SizedBox(height: 20),
            AppCard(
              key: const ValueKey('bmi-result-card'),
              color: resultBackground,
              padding: const EdgeInsets.all(20),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ваш индекс массы тела:',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: appGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result!.formattedBmi,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: appGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _result!.recommendation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: recommendationColor,
                        fontSize: 14,
                      ),
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
