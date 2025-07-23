import 'package:flutter/material.dart';

class PageTransition extends PageRouteBuilder {
  final Widget page;
  final RouteSettings settings;

  PageTransition({
    required this.page,
    required this.settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

// Enhanced navigation function with better error handling
void navigateWithAnimation(BuildContext context, String routeName, {Object? arguments}) {
  try {
    final route = _createRouteByName(routeName, arguments);
    if (route != null) {
      Navigator.pushReplacement(context, route);
    } else {
      // Fallback to regular navigation if route creation fails
      Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
    }
  } catch (e) {
    // Fallback navigation
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }
}

// Alternative approach: Create routes directly instead of trying to access onGenerateRoute
PageRoute<dynamic>? _createRouteByName(String routeName, Object? arguments) {
  Widget? page;
  
  switch (routeName) {
    case '/home':
      page = _createHomePage(arguments);
      break;
    case '/izin':
      page = _createIzinPage(arguments);
      break;
    case '/cuti':
      page = _createCutiPage(arguments);
      break;
    case '/lembur':
      page = _createLemburPage(arguments);
      break;
    case '/profile':
      page = _createProfilePage(arguments);
      break;
    default:
      page = _createHomePage(arguments);
  }
  
  if (page != null) {
    return PageTransition(
      page: page,
      settings: RouteSettings(name: routeName, arguments: arguments),
    );
  }
  
  return null;
}

// Fixed version of your original approach with proper null handling
Widget _getPageByRouteNameFixed(String routeName, BuildContext context) {
  final navigator = Navigator.of(context);
  final route = navigator.widget.onGenerateRoute?.call(RouteSettings(name: routeName));
  
  if (route != null) {
    try {
      return (route as PageRoute).buildPage(
        context,
        route.animation!,
        route.secondaryAnimation!,
      );
    } catch (e) {
      // If buildPage fails, return a fallback page
      return _getFallbackPage(routeName, context); // Fixed: Pass context here
    }
  }
  
  // If route is null, return fallback page
  return _getFallbackPage(routeName, context); // Fixed: Pass context here
}

// Fixed: Added BuildContext parameter
Widget _getFallbackPage(String routeName, BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Route "$routeName" not found'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    ),
  );
}

// Placeholder functions - replace these with your actual page constructors
Widget? _createHomePage(Object? arguments) {
  // Replace with your actual HomePage constructor
  // Example: return HomePage(arguments: arguments);
  return null; // Return null to trigger fallback navigation
}

Widget? _createIzinPage(Object? arguments) {
  // Replace with your actual IzinPage constructor
  // Example: return IzinPage(arguments: arguments);
  return null;
}

Widget? _createCutiPage(Object? arguments) {
  // Replace with your actual CutiPage constructor
  // Example: return CutiPage(arguments: arguments);
  return null;
}

Widget? _createLemburPage(Object? arguments) {
  // Replace with your actual LemburPage constructor
  // Example: return LemburPage(arguments: arguments);
  return null;
}

Widget? _createProfilePage(Object? arguments) {
  // Replace with your actual ProfilePage constructor
  // Example: return LemburPage(arguments: arguments);
  return null;
}

// Alternative implementation using a route generator function
class AnimatedRouteGenerator {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    Widget? page;
    
    switch (settings.name) {
      case '/home':
        page = _createHomePage(settings.arguments);
        break;
      case '/izin':
        page = _createIzinPage(settings.arguments);
        break;
      case '/cuti':
        page = _createCutiPage(settings.arguments);
        break;
      case '/lembur':
        page = _createLemburPage(settings.arguments);
        break;
      case '/profile':
        page = _createProfilePage(settings.arguments);
        break;
      default:
        page = _createHomePage(settings.arguments);
    }
    
    if (page != null) {
      return PageTransition(
        page: page,
        settings: settings,
      );
    }
    
    return null;
  }
}

// Usage example with MaterialApp:
/*
MaterialApp(
  onGenerateRoute: AnimatedRouteGenerator.generateRoute,
  initialRoute: '/home',
  // ... other properties
)
*/

// Enhanced navigation function that works with the route generator
void navigateWithAnimationV2(BuildContext context, String routeName, {Object? arguments}) {
  Navigator.pushReplacementNamed(
    context,
    routeName,
    arguments: arguments,
  );
}