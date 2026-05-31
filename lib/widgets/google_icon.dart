import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 20});

  final double size;

  static const _svg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M22.56 12.25C22.56 11.47 22.49 10.73 22.36 10H12V14.26H17.92C17.67 15.63 16.89 16.79 15.75 17.55V20.31H19.31C21.4 18.39 22.56 15.58 22.56 12.25Z" fill="#4285F4"/>
  <path d="M12 23C14.97 23 17.16 22.02 18.75 20.31L15.19 17.55C14.33 18.13 13.25 18.48 12 18.48C9.58 18.48 7.42 16.85 6.64 14.65H2.96V17.5C4.62 20.8 8.04 23 12 23Z" fill="#34A853"/>
  <path d="M6.64 14.65C6.44 14.06 6.33 13.43 6.33 12.78C6.33 12.13 6.44 11.5 6.64 10.91V8.06H2.96C2.26 9.45 1.86 11.07 1.86 12.78C1.86 14.49 2.26 16.11 2.96 17.5L6.64 14.65Z" fill="#FBBC05"/>
  <path d="M12 7.08C13.61 7.08 15.06 7.63 16.2 8.71L19.39 5.52C17.15 3.49 14.97 2.56 12 2.56C8.04 2.56 4.62 4.76 2.96 8.06L6.64 10.91C7.42 8.71 9.58 7.08 12 7.08Z" fill="#EA4335"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
    );
  }
}
