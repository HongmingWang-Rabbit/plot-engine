import 'package:flutter/material.dart';

/// Responsive breakpoints for different device sizes
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;

  Breakpoints._();
}

/// Enum representing the current viewport size category
enum ViewportSize {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Extension to get viewport properties
extension ViewportSizeExtension on ViewportSize {
  bool get isMobile => this == ViewportSize.mobile;
  bool get isTablet => this == ViewportSize.tablet;
  bool get isDesktop => this == ViewportSize.desktop || this == ViewportSize.largeDesktop;
  bool get isLargeDesktop => this == ViewportSize.largeDesktop;

  /// Whether sidebars should auto-collapse
  bool get shouldCollapseSidebars => this == ViewportSize.mobile || this == ViewportSize.tablet;

  /// Whether to use drawer navigation instead of inline panels
  bool get useDrawerNavigation => this == ViewportSize.mobile;

  /// Maximum number of panels to show side by side
  int get maxPanels {
    switch (this) {
      case ViewportSize.mobile:
        return 1;
      case ViewportSize.tablet:
        return 2;
      case ViewportSize.desktop:
      case ViewportSize.largeDesktop:
        return 3;
    }
  }
}

/// Utility class for responsive design
class Responsive {
  Responsive._();

  /// Get the current viewport size based on screen width
  static ViewportSize getViewportSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return getViewportSizeFromWidth(width);
  }

  /// Get viewport size from a width value
  static ViewportSize getViewportSizeFromWidth(double width) {
    if (width < Breakpoints.mobile) {
      return ViewportSize.mobile;
    } else if (width < Breakpoints.tablet) {
      return ViewportSize.tablet;
    } else if (width < Breakpoints.desktop) {
      return ViewportSize.desktop;
    } else {
      return ViewportSize.largeDesktop;
    }
  }

  /// Check if current viewport is mobile
  static bool isMobile(BuildContext context) {
    return getViewportSize(context).isMobile;
  }

  /// Check if current viewport is tablet
  static bool isTablet(BuildContext context) {
    return getViewportSize(context).isTablet;
  }

  /// Check if current viewport is desktop or larger
  static bool isDesktop(BuildContext context) {
    return getViewportSize(context).isDesktop;
  }

  /// Get responsive value based on viewport
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final viewport = getViewportSize(context);
    switch (viewport) {
      case ViewportSize.mobile:
        return mobile;
      case ViewportSize.tablet:
        return tablet ?? mobile;
      case ViewportSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ViewportSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context) {
    return value(
      context,
      mobile: const EdgeInsets.all(8),
      tablet: const EdgeInsets.all(12),
      desktop: const EdgeInsets.all(16),
    );
  }

  /// Get responsive horizontal padding
  static double horizontalPadding(BuildContext context) {
    return value(
      context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
      largeDesktop: 24.0,
    );
  }

  /// Get flex values for the main panels
  static ({int editor, int sidebar, int knowledge}) panelFlex(BuildContext context) {
    final viewport = getViewportSize(context);
    switch (viewport) {
      case ViewportSize.mobile:
        return (editor: 1, sidebar: 0, knowledge: 0);
      case ViewportSize.tablet:
        return (editor: 7, sidebar: 3, knowledge: 0);
      case ViewportSize.desktop:
        return (editor: 6, sidebar: 2, knowledge: 2);
      case ViewportSize.largeDesktop:
        return (editor: 7, sidebar: 2, knowledge: 2);
    }
  }
}

/// A widget that rebuilds when the viewport size changes
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ViewportSize viewport) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Responsive.getViewportSizeFromWidth(constraints.maxWidth);
        return builder(context, viewport);
      },
    );
  }
}

/// A widget that shows different children based on viewport
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, viewport) {
        switch (viewport) {
          case ViewportSize.mobile:
            return mobile;
          case ViewportSize.tablet:
            return tablet ?? mobile;
          case ViewportSize.desktop:
            return desktop ?? tablet ?? mobile;
          case ViewportSize.largeDesktop:
            return largeDesktop ?? desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}
