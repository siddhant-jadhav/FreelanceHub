import 'package:flutter_test/flutter_test.dart';
import 'package:freelancehub/main.dart';
import 'package:freelancehub/screens/buyer_requests_screen.dart';
import 'package:freelancehub/screens/client_home_screen.dart';
import 'package:freelancehub/screens/freelancer_dashboard_screen.dart';
import 'package:freelancehub/screens/freelancer_onboarding_screen.dart';
import 'package:freelancehub/screens/freelancer_onboarding_step2_screen.dart';
import 'package:freelancehub/screens/login_screen.dart';
import 'package:freelancehub/screens/signup_screen.dart';
import 'package:freelancehub/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('FreelanceHubApp launches SplashScreen by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FreelanceHubApp());

    // Verify Splash screen shows up at app launch
    expect(find.text('FreelanceHub'), findsOneWidget);
    expect(find.text('Work without limits'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Freelancer onboarding screen smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FreelancerOnboardingScreen(),
      ),
    );

    // Verify Onboarding brand elements and inputs are present
    expect(find.text('Tell us about yourself'), findsOneWidget);
    expect(find.text('STEP 1 OF 2'), findsOneWidget);
    expect(find.text('50% Completed'), findsOneWidget);
    expect(find.text('Continue to Step 2'), findsOneWidget);
    // Verify Instant Match Guarantee is NOT present
    expect(find.text('Instant Match Guarantee'), findsNothing);
    // Verify profile icon in top right is NOT present
    expect(find.byIcon(LucideIcons.user), findsNothing);
  });

  testWidgets('Freelancer onboarding Step 2 smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FreelancerOnboardingStep2Screen(),
      ),
    );

    // Verify Step 2 elements are present
    expect(find.text('Skills & Services'), findsOneWidget);
    expect(find.text('STEP 2 OF 2'), findsOneWidget);
    expect(find.text('100% Completed'), findsOneWidget);
    expect(find.text('What can you help clients with?'), findsOneWidget);
    expect(find.text('Complete Profile'), findsOneWidget);

    // Verify initial inputs start empty (not pre-filled from design)
    expect(find.text('0 selected (max 15)'), findsOneWidget);

    // Verify profile icon in top right is NOT present
    expect(find.byIcon(LucideIcons.user), findsNothing);
  });

  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Verify FreelanceHub brand elements and inputs are present
    expect(find.text('Log in to your account'), findsOneWidget);
    expect(find.text('Client'), findsOneWidget);
    expect(find.text('Freelancer'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Signup screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignupScreen(),
      ),
    );

    // Verify FreelanceHub brand elements and inputs are present
    expect(find.text('Join FreelanceHub'), findsOneWidget);
    expect(find.text("I'm a Client"), findsOneWidget);
    expect(find.text("I'm a Freelancer"), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    expect(find.text('FreelanceHub'), findsOneWidget);
    expect(find.text('Work without limits'), findsOneWidget);

    // Unmount to cleanly dispose controllers and timers
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Client home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClientHomeScreen(),
      ),
    );

    expect(find.text('FreelanceHub'), findsOneWidget);
    expect(find.text('CLIENT'), findsOneWidget);
    expect(find.text('Explore Talent'), findsOneWidget);
    expect(find.text('Top Rated Freelancers'), findsOneWidget);
  });

  testWidgets('Freelancer dashboard smoke test and contract rendering',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FreelancerDashboardScreen(),
      ),
    );

    // Verify Dashboard brand & role
    expect(find.text('FreelanceHub'), findsOneWidget);
    expect(find.text('SELLER HUB'), findsOneWidget);

    // Verify Performance KPIs
    expect(find.text('Seller Performance'), findsOneWidget);
    expect(find.text('Response Rate'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Order Completion'), findsOneWidget);
    expect(find.text('98%'), findsOneWidget);

    // Verify Earnings Snapshot
    expect(find.text('Earnings Snapshot'), findsOneWidget);
    expect(find.text('Withdraw'), findsOneWidget);

    // Verify Contract rendering
    expect(find.text('Active Orders'), findsOneWidget);
    expect(find.text('TechCorp SaaS Brand Identity'), findsOneWidget);
    expect(find.text('Mobile UI Kit Components'), findsOneWidget);
    expect(find.text('Deliver Work'), findsOneWidget);
    expect(find.text('Respond to Revision'), findsOneWidget);

    // Verify Growth & Funnel
    expect(find.text('Growth & Toolkit'), findsOneWidget);
    expect(find.text('30-Day Gig Funnel'), findsOneWidget);
  });

  testWidgets('Buyer requests screen smoke and filter test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerRequestsScreen(),
      ),
    );

    // Verify header and brand pill
    expect(find.text('Buyer Requests'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);

    // Verify stream banner
    expect(find.text('Live Opportunity Stream'), findsOneWidget);
    expect(find.text('High Match'), findsOneWidget);

    // Verify search and category chips
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All (4)'), findsOneWidget);
    expect(find.text('Mobile Design (2)'), findsOneWidget);
    expect(find.text('Web Dev (1)'), findsOneWidget);
    expect(find.text('Branding (1)'), findsOneWidget);

    // Verify initial buyer requests loaded
    expect(
      find.text(
        'Need complete Flutter mobile app UI design for FinTech wallet with 8 screens',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(find.text('Send Offer', skipOffstage: false), findsWidgets);

    // Test search filter
    await tester.enterText(find.byType(TextField), 'FinTech');
    await tester.pump();
    expect(
      find.text(
        'Need complete Flutter mobile app UI design for FinTech wallet with 8 screens',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Landing page redesign & Tailwind CSS conversion for SaaS startup',
        skipOffstage: false,
      ),
      findsNothing,
    );

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(
      find.text(
        'Landing page redesign & Tailwind CSS conversion for SaaS startup',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('Buyer requests Send Offer modal opens correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BuyerRequestsScreen(),
      ),
    );

    // Find and tap the first "Send Offer" button
    final sendOfferBtn = find.text('Send Offer').first;
    await tester.ensureVisible(sendOfferBtn);
    await tester.tap(sendOfferBtn);
    await tester.pumpAndSettle();

    // Verify modal elements are visible
    expect(find.text('Send Custom Offer'), findsOneWidget);
    expect(find.text('Select Matching Gig / Service'), findsOneWidget);
    expect(find.text('Offer Price (\$)'), findsOneWidget);
    expect(find.text('Delivery (Days)'), findsOneWidget);
    expect(find.text('Submit Proposal (Uses 1 Offer)'), findsOneWidget);
  });
}

