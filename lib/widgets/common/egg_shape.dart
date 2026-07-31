import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hình trứng dọc: đỉnh hẹp (60%), đáy tròn rộng (40%).
BoxDecoration eggDecoration({
  required double width,
  required double height,
  Color color = Colors.white,
  Color? borderColor,
  double borderWidth = 0,
}) {
  final rx = width / 2;
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.only(
      topLeft: Radius.elliptical(rx, height * 0.60),
      topRight: Radius.elliptical(rx, height * 0.60),
      bottomLeft: Radius.elliptical(rx, height * 0.40),
      bottomRight: Radius.elliptical(rx, height * 0.40),
    ),
    border: borderColor != null && borderWidth > 0
        ? Border.all(color: borderColor, width: borderWidth)
        : null,
  );
}

/// Ô nhập OTP một chữ số, nền trắng hình trứng.
class EggOtpField extends StatefulWidget {
  const EggOtpField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.primary,
    this.textStyle,
    required this.onChanged,
    required this.onBackspace, // Callback xử lý khi bấm xóa ô trống
    this.onSubmitted,
    this.width = 54,
    this.height = 80,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color primary;
  final TextStyle? textStyle;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;
  final VoidCallback? onSubmitted;
  final double width;
  final double height;

  @override
  State<EggOtpField> createState() => _EggOtpFieldState();
}

class _EggOtpFieldState extends State<EggOtpField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: DecoratedBox(
        decoration: eggDecoration(
          width: widget.width,
          height: widget.height,
          color: Colors.white,
          borderColor: widget.primary,
          borderWidth: focused ? 2.2 : 1.4,
        ),
        child: Center(
          // Bọc KeyboardListener để bắt phím Backspace từ bàn phím hệ thống
          child: KeyboardListener(
            focusNode:
                FocusNode(), // FocusNode nội bộ để lắng nghe sự kiện phím độc lập
            onKeyEvent: (KeyEvent event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.backspace) {
                  // Nếu ô hiện tại trống và bấm nút xóa -> kích hoạt quay lại ô trước
                  if (widget.controller.text.isEmpty) {
                    widget.onBackspace();
                  }
                }
              }
            },
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: widget.textStyle,
              maxLength: 1,
              showCursor: false,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: widget.onChanged,
              onSubmitted: (_) => widget.onSubmitted?.call(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ),
      ),
    );
  }
}
