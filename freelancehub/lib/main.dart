import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_colors.dart';
import 'firebase_options.dart';
import 'screens/buyer_requests_screen.dart';
import 'screens/client_home_screen.dart';
import 'screens/freelancer_dashboard_screen.dart';
import 'screens/freelancer_onboarding_screen.dart';
import 'screens/freelancer_onboarding_step2_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // Set system UI overlay style for seamless edge-to-edge experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const FreelanceHubApp());
}

class FreelanceHubApp extends StatelessWidget {
  const FreelanceHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreelanceHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.background,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final role = FirebaseService.instance.currentRole;
        // Role-based route guard: prevent cross-role screen access
        if (role == 'freelancer' && settings.name == '/client-home') {
          return MaterialPageRoute(
            builder: (context) => const FreelancerDashboardScreen(),
            settings: settings,
          );
        }
        if (role == 'client' &&
            (settings.name == '/freelancer-onboarding' ||
                settings.name == '/freelancer-onboarding-step2' ||
                settings.name == '/freelancer-dashboard' ||
                settings.name == '/buyer-requests')) {
          return MaterialPageRoute(
            builder: (context) => const ClientHomeScreen(),
            settings: settings,
          );
        }
        return null;
      },
      routes: {
        '/': (context) => const SplashScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/freelancer-onboarding': (context) =>
            const FreelancerOnboardingScreen(),
        '/freelancer-onboarding-step2': (context) =>
            const FreelancerOnboardingStep2Screen(),
        '/freelancer-dashboard': (context) =>
            const FreelancerDashboardScreen(),
        '/buyer-requests': (context) => const BuyerRequestsScreen(),
        '/client-home': (context) => const ClientHomeScreen(),
      },
    );
  }
}
