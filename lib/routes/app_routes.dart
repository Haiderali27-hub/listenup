import 'package:get/get.dart';
import 'package:sound_app/screens/splash/splash_screen.dart';
import 'package:sound_app/screens/onboarding/onboarding_screen.dart';
import 'package:sound_app/screens/auth/login_screen.dart';
import 'package:sound_app/screens/auth/signup_screen.dart';
import 'package:sound_app/screens/auth/reset_password_screen.dart';
import 'package:sound_app/screens/home/home_screen.dart';
import 'package:sound_app/screens/menu/profile/user_profile_screen.dart';
// Add other imports as needed

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String resetPassword = '/reset-password';
  // Add others as needed

  static final routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: onboarding, page: () => const OnboardingScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: signup, page: () => const SignupScreen()),
    GetPage(name: resetPassword, page: () => const ResetPasswordScreen()),
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(name: profile, page: () => const UserProfileScreen()),
    // Add other GetPage routes here as needed
  ];
}
