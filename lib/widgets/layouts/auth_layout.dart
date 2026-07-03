import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // bg-transparent
      backgroundColor: Colors.transparent,
      body: Center(
        // max-w-md mx-auto (Rộng tối đa 448px và căn giữa)
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // hide-scrollbars: Ẩn thanh cuộn hiển thị bên góc
              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                // overflow-y-auto: Cho phép cuộn
                child: SingleChildScrollView(
                  // Đảm bảo nội dung luôn có chiều cao tối thiểu bằng màn hình (min-h-[100dvh])
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        // px-6 py-10 (Ngang 24px, Dọc 40px)
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // flex-1: Giúp child chiếm trọn không gian còn lại
                            Expanded(child: child),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
