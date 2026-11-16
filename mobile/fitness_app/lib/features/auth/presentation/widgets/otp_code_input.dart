import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/ui/theme/app_theme.dart';

class OtpCodeInput extends StatelessWidget {
  const OtpCodeInput({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final code = value.text;
        return Semantics(
          label: label,
          textField: true,
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final isActive = enabled && code.length == index;
                  return Container(
                    width: 46,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? AppTheme.primary : AppTheme.border,
                        width: isActive ? 1.4 : 1,
                      ),
                    ),
                    child: Text(
                      index < code.length ? code[index] : '',
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ),
              Positioned.fill(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: onChanged,
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
