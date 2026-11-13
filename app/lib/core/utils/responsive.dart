import 'package:material_ui/material_ui.dart';

enum DeviceScreenType { mobile, tablet, desktop }

class Responsive extends StatelessWidget {
  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 && MediaQuery.sizeOf(context).width < 1024;

  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= 1024;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 1024 && desktop != null) {
      return desktop!;
    }
    if (width >= 600 && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}
