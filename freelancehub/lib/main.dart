import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/firebase/firebase_config.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_colors.dart';
import 'models/project_model.dart';
import 'models/task_model.dart';
import 'screens/buyer_requests_screen.dart';
import 'screens/client_home_screen.dart';
import 'screens/escrow_payments_screen.dart';
import 'screens/freelancer_dashboard_screen.dart';
import 'screens/freelancer_onboarding_screen.dart';
import 'screens/freelancer_onboarding_step2_screen.dart';
import 'screens/freelancer_orders_screen.dart';
import 'screens/individual_chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/messages_inbox_screen.dart';
import 'screens/order_delivery_screen.dart';
import 'screens/post_task_screen.dart';
import 'screens/project_workspace_screen.dart';
import 'screens/send_offer_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/task_details_proposals_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseConfig.instance.initialize();
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
        if (role == 'freelancer' &&
            (settings.name == '/client-home' || settings.name == '/post-task')) {
          return MaterialPageRoute(
            builder: (context) => const FreelancerDashboardScreen(),
            settings: settings,
          );
        }
        if (role == 'client' &&
            (settings.name == '/freelancer-onboarding' ||
                settings.name == '/freelancer-onboarding-step2' ||
                settings.name == '/freelancer-dashboard' ||
                settings.name == '/buyer-requests' ||
                settings.name == '/send-offer' ||
                settings.name == '/orders' ||
                settings.name == '/order-delivery')) {
          return MaterialPageRoute(
            builder: (context) => const ClientHomeScreen(),
            settings: settings,
          );
        }

        switch (settings.name) {
          case '/freelancer-onboarding':
            return MaterialPageRoute(
              builder: (context) => const FreelancerOnboardingScreen(),
              settings: settings,
            );
          case '/freelancer-onboarding-step2':
            return MaterialPageRoute(
              builder: (context) => const FreelancerOnboardingStep2Screen(),
              settings: settings,
            );
          case '/freelancer-dashboard':
            return MaterialPageRoute(
              builder: (context) => const FreelancerDashboardScreen(),
              settings: settings,
            );
          case '/buyer-requests':
            return MaterialPageRoute(
              builder: (context) => const BuyerRequestsScreen(),
              settings: settings,
            );
          case '/send-offer':
            return MaterialPageRoute(
              builder: (context) => settings.arguments is BuyerRequest
                  ? SendOfferScreen(initialRequest: settings.arguments as BuyerRequest)
                  : const SendOfferScreen(),
              settings: settings,
            );
          case '/orders':
            return MaterialPageRoute(
              builder: (context) => const FreelancerOrdersScreen(),
              settings: settings,
            );
          case '/order-delivery':
            return MaterialPageRoute(
              builder: (context) => const OrderDeliveryScreen(),
              settings: settings,
            );
          case '/client-home':
            return MaterialPageRoute(
              builder: (context) => const ClientHomeScreen(),
              settings: settings,
            );
          case '/task-details':
            if (settings.arguments is TaskModel) {
              return MaterialPageRoute(
                builder: (context) => TaskDetailsProposalsScreen(
                  initialTask: settings.arguments as TaskModel,
                ),
                settings: settings,
              );
            } else if (settings.arguments is String) {
              return MaterialPageRoute(
                builder: (context) => TaskDetailsProposalsScreen(
                  taskId: settings.arguments as String,
                ),
                settings: settings,
              );
            }
            return MaterialPageRoute(
              builder: (context) => const TaskDetailsProposalsScreen(),
              settings: settings,
            );
          case '/post-task':
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => PostTaskScreen(
                  initialCategory: args['category'] as String?,
                  initialTitle: args['title'] as String?,
                  initialDescription: args['description'] as String?,
                  initialBudget: (args['budget'] as num?)?.toDouble(),
                ),
                settings: settings,
              );
            }
            return MaterialPageRoute(
              builder: (context) => const PostTaskScreen(),
              settings: settings,
            );
          case '/project-workspace':
            if (settings.arguments is ProjectModel) {
              return MaterialPageRoute(
                builder: (context) => ProjectWorkspaceScreen(
                  project: settings.arguments as ProjectModel,
                ),
                settings: settings,
              );
            } else if (settings.arguments is String) {
              return MaterialPageRoute(
                builder: (context) => ProjectWorkspaceScreen(
                  projectId: settings.arguments as String,
                ),
                settings: settings,
              );
            }
            return MaterialPageRoute(
              builder: (context) => const ProjectWorkspaceScreen(),
              settings: settings,
            );
          case '/escrow-payments':
            if (settings.arguments is double) {
              return MaterialPageRoute(
                builder: (context) => EscrowPaymentsScreen(
                  initialEscrowAmount: settings.arguments as double,
                ),
                settings: settings,
              );
            } else if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => EscrowPaymentsScreen(
                  initialEscrowAmount: (args['escrowAmount'] as num?)?.toDouble(),
                  projectId: args['projectId'] as String?,
                ),
                settings: settings,
              );
            }
            return MaterialPageRoute(
              builder: (context) => const EscrowPaymentsScreen(),
              settings: settings,
            );
          case '/messages':
            return MaterialPageRoute(
              builder: (context) => const MessagesInboxScreen(),
              settings: settings,
            );
          case '/chat':
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => IndividualChatScreen(
                  conversationId: args['conversationId'] as String?,
                  contactName: (args['contactName'] as String?) ?? 'Contact',
                  contactRole: (args['contactRole'] as String?) ?? 'User',
                  contactInitials: (args['contactInitials'] as String?) ?? 'U',
                  isOnline: (args['isOnline'] as bool?) ?? true,
                  projectTitle: (args['projectTitle'] as String?) ?? 'Project Workspace',
                  projectBudget: (args['projectBudget'] as num?)?.toDouble() ?? 0.0,
                  projectInEscrow: (args['projectInEscrow'] as num?)?.toDouble() ?? 0.0,
                  projectId: args['projectId'] as String?,
                ),
                settings: settings,
              );
            }
            return MaterialPageRoute(
              builder: (context) => const IndividualChatScreen(),
              settings: settings,
            );
          default:
            return null;
        }
      },
      routes: {
        '/': (context) => const SplashScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
