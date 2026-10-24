import 'package:flutter/material.dart';

import 'app_session.dart';
import 'app_ui.dart';
import 'calculation_error_message.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.session});
  final AppSession session;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _pageSize = 50;
  final List<BmiRecord> _history = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _hasMore = false;
  int _nextOffset = 0;
  String? _error;
  UserProfile get user => widget.session.user;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool more = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final records = await widget.session.loadHistory(
        offset: more ? _nextOffset : 0,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (!more) _history.clear();
        // Avoid duplicate cards when newer records shift pages during a visit.
        final ids = _history.map((record) => record.id).toSet();
        _history.addAll(records.where((record) => ids.add(record.id)));
        _hasMore = records.length == _pageSize;
        _nextOffset = (more ? _nextOffset : 0) + records.length;
        _hasLoaded = true;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = calculationErrorMessage(error, saving: false));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: AppBottomBar(
      profileSelected: true,
      onCalculator: () => Navigator.of(context).pop(),
      onProfile: () {},
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                    child: Semantics(
                      label: 'Аватар пользователя — логотип Flutter',
                      image: true,
                      child: const Padding(
                        padding: EdgeInsets.all(18),
                        child: FlutterLogo(),
                      ),
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null) ErrorMessage(_error),
            if (!_isLoading)
              TextButton(
                onPressed: () => _loadHistory(),
                child: Text(
                  _error == null ? 'Обновить историю' : 'Повторить загрузку',
                ),
              ),
            if (_hasLoaded && !_isLoading && _error == null && _history.isEmpty)
              const AppCard(
                child: Text(
                  'Расчётов пока нет. Перейдите в калькулятор и рассчитайте свой ИМТ.',
                  style: TextStyle(color: appGray, fontSize: 16),
                ),
              ),
            for (final record in _history) ...[
              _HistoryCard(record: record),
              const SizedBox(height: 18),
            ],
            if (_hasMore && !_isLoading)
              TextButton(
                onPressed: () => _loadHistory(more: true),
                child: const Text('Показать ещё'),
              ),
          ],
        ),
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
            _detail('Индекс массы тела', record.formattedBmi),
          ],
        ),
        const SizedBox(height: 16),
        _detail('Рекомендация', record.recommendation),
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
