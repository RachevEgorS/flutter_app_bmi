import 'package:flutter/material.dart';

const appGreen = Color(0xFF4CAF50);
const appBackground = Color(0xFFF5F5F5);
const appGray = Color(0xFF808080);
const appRed = Color(0xFFFF5252);
const resultBackground = Color(0xFFE8F5E9);
const recommendationColor = Color(0xFF757575);
const cardShadows = [
  BoxShadow(
    color: Color(0x26A18B8B),
    blurRadius: 12,
    spreadRadius: 3,
    offset: Offset(0, 2),
  ),
];

ThemeData buildAppTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: appGreen),
  scaffoldBackgroundColor: appBackground,
  inputDecorationTheme: const InputDecorationTheme(
    hintStyle: TextStyle(color: appGray, fontSize: 16),
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFAAAAAA)),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: appGreen, width: 2),
    ),
    errorMaxLines: 3,
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: appGreen,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: appGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(50),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);

/// Центрирует содержимое и позволяет прокручивать его при появлении клавиатуры.
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.child, this.centered = true});
  final Widget child;
  final bool centered;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: (constraints.maxWidth / 12).clamp(20.0, 40.0),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: centered ? Alignment.center : Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: appGreen,
      fontSize: 26,
      fontWeight: FontWeight.bold,
    ),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      boxShadow: cardShadows,
    ),
    child: child,
  );
}

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.password = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.autofillHint,
    this.capitalization = TextCapitalization.none,
  });
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool password;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final String? autofillHint;
  final TextCapitalization capitalization;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: appGray, fontSize: 16)),
      const SizedBox(height: 4),
      TextFormField(
        controller: controller,
        validator: validator,
        obscureText: password,
        autocorrect: !password && keyboardType == TextInputType.text,
        enableSuggestions: !password,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        autofillHints: autofillHint == null ? null : [autofillHint!],
        textInputAction: onSubmitted != null
            ? TextInputAction.done
            : TextInputAction.next,
        onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
        onChanged: onChanged,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: const TextStyle(fontSize: 16, color: appGray),
        decoration: InputDecoration(hintText: hint),
      ),
    ],
  );
}

class ErrorMessage extends StatelessWidget {
  const ErrorMessage(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message ?? '',
        textAlign: TextAlign.center,
        style: const TextStyle(color: appRed, fontSize: 13),
      ),
    ),
  );
}

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.profileSelected,
    required this.onCalculator,
    required this.onProfile,
  });
  final bool profileSelected;
  final VoidCallback onCalculator;
  final VoidCallback onProfile;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x26A18B8B),
          blurRadius: 12,
          offset: Offset(0, -3),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        key: const ValueKey('footer-content'),
        height: 60,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tab('Калькулятор', !profileSelected, onCalculator),
            _tab('Профиль', profileSelected, onProfile),
          ],
        ),
      ),
    ),
  );
  Widget _tab(String label, bool selected, VoidCallback onPressed) => Expanded(
    child: Semantics(
      selected: selected,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: selected ? const Color(0xFF252525) : appGray,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, textAlign: TextAlign.center, maxLines: 1),
        ),
      ),
    ),
  );
}
