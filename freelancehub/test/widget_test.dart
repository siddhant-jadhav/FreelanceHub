import 'package:flutter_test/flutter_test.dart';
import 'package:freelancehub/main.dart';
import 'package:freelancehub/screens/buyer_requests_screen.dart';
import 'package:freelancehub/screens/client_home_screen.dart';
import 'package:freelancehub/screens/freelancer_dashboard_screen.dart';
import 'package:freelancehub/screens/freelancer_onboarding_screen.dart';
import 'package:freelancehub/screens/freelancer_onboarding_step2_screen.dart';
import 'package:freelancehub/screens/freelancer_orders_screen.dart';
import 'package:freelancehub/screens/login_screen.dart';
import 'package:freelancehub/screens/order_delivery_screen.dart';
import 'package:freelancehub/screens/send_offer_screen.dart';
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
    expect(find.text('Top Recommended For You'), findsOneWidget);
    expect(find.text('Active Deliveries'), findsOneWidget);
    expect(find.text('Find vetted experts or kickstart a project'), findsOneWidget);
    expect(find.text('+ Post a Task'), findsOneWidget);
    expect(find.text('AI Brief Writer'), findsOneWidget);
    expect(find.text('Mobile App MVP (Fintech Flow)'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('David Chen'), findsOneWidget);
    expect(find.text('Recently Saved Talent'), findsOneWidget);
    expect(find.text('Review Submission'), findsOneWidget);
  });

  testWidgets('Client home screen interactive modals and actions test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClientHomeScreen(),
      ),
    );

    // 1. Test Post a Task modal opens
    final postTaskBtn = find.text('+ Post a Task');
    await tester.tap(postTaskBtn);
    await tester.pumpAndSettle();
    expect(find.text('Post a Project Task'), findsOneWidget);
    expect(find.text('Post Task to Opportunities'), findsOneWidget);

    // Close Post Task modal
    await tester.tap(find.byIcon(LucideIcons.x).last);
    await tester.pumpAndSettle();

    // 2. Test AI Brief Writer modal opens
    final aiBriefBtn = find.text('AI Brief Writer');
    await tester.tap(aiBriefBtn);
    await tester.pumpAndSettle();
    expect(find.text('AI Project Brief Assistant'), findsOneWidget);
    expect(find.text('Generate Brief with AI'), findsOneWidget);

    // Close AI Brief modal
    await tester.tap(find.byIcon(LucideIcons.x).last);
    await tester.pumpAndSettle();

    // 3. Test Active Deliveries Workspace modal opens
    final workspaceBtn = find.text('Workspace');
    await tester.ensureVisible(workspaceBtn);
    await tester.tap(workspaceBtn);
    await tester.pumpAndSettle();
    expect(find.text('ORDER #FH-9921 • FIXED PRICE'), findsOneWidget);
    expect(find.text('Milestone Progress (3 of 4 Completed • 75%)'), findsOneWidget);

    // Close Workspace modal
    await tester.tap(find.byIcon(LucideIcons.x).last);
    await tester.pumpAndSettle();

    // 4. Test Review Submission modal opens and approves milestone
    final reviewBtn = find.text('Review Submission');
    await tester.ensureVisible(reviewBtn);
    await tester.tap(reviewBtn);
    await tester.pumpAndSettle();
    expect(find.text('SUBMISSION REVIEW • MILESTONE 2'), findsOneWidget);
    expect(find.text('Approve & Release'), findsOneWidget);

    // Tap Approve & Release
    await tester.tap(find.text('Approve & Release'));
    await tester.pumpAndSettle();

    // Banner should be removed after approval
    expect(find.text('SUBMISSION REVIEW • MILESTONE 2'), findsNothing);
    expect(find.text('Review Submission'), findsNothing);
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

  testWidgets('SendOfferScreen smoke and UI structure test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SendOfferScreen(),
      ),
    );

    // Verify App Bar
    expect(find.text('Submit Proposal'), findsOneWidget);
    expect(find.text('OFFER'), findsOneWidget);

    // Verify Context Card
    expect(find.text('BUYER REQUEST'), findsOneWidget);
    expect(find.text('Verified Client'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);

    // Verify Gig Selector
    expect(find.text('Select Associated Gig'), findsOneWidget);
    expect(find.text('Change Gig'), findsOneWidget);

    // Verify Payment Type Switcher
    expect(find.text('Payment Type'), findsOneWidget);
    expect(find.text('Single Payment'), findsOneWidget);
    expect(find.text('Milestones'), findsOneWidget);

    // Verify Proposal Pitch section
    expect(find.text('Proposal Pitch & Scope'), findsOneWidget);
    expect(find.text('Refine with AI'), findsOneWidget);
    expect(find.text('Add Portfolio Samples'), findsOneWidget);

    // Verify Pricing & Timeline
    expect(find.text('Offer Pricing & Timeline'), findsOneWidget);
    expect(find.text('Offer Price (\$)'), findsOneWidget);
    expect(find.text('Delivery Duration'), findsOneWidget);

    // Verify Revisions
    expect(find.text('Client Revisions'), findsOneWidget);
    expect(find.text('Unlimited'), findsOneWidget);

    // Verify Deliverables Grid (skipOffstage: false since scrollable)
    expect(find.text('Source Files', skipOffstage: false), findsOneWidget);
    expect(find.text('Commercial Use', skipOffstage: false), findsOneWidget);
    expect(find.text('High Res', skipOffstage: false), findsOneWidget);
    expect(find.text('Prototype', skipOffstage: false), findsOneWidget);

    // Verify Sticky Footer
    expect(find.text('Submit Custom Offer'), findsOneWidget);
    expect(find.textContaining('Client Total:'), findsOneWidget);
    expect(find.textContaining('You Earn:'), findsOneWidget);
  });

  testWidgets('SendOfferScreen milestones and submission test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SendOfferScreen(),
      ),
    );

    // Tap Milestones tab
    await tester.tap(find.text('Milestones'));
    await tester.pumpAndSettle();

    // Verify milestones section appears
    expect(find.textContaining('Project Milestones'), findsOneWidget);
    expect(find.text('+ Add Milestone'), findsOneWidget);

    // Submit Custom Offer
    final submitBtn = find.text('Submit Custom Offer');
    await tester.tap(submitBtn);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verify Success Bottom Sheet appears
    expect(find.text('Custom Offer Sent!'), findsOneWidget);
    expect(find.text('Return to Opportunities'), findsOneWidget);
  });

  testWidgets('FreelancerOrdersScreen smoke, filter and navigation test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const FreelancerOrdersScreen(),
        routes: {
          '/order-delivery': (context) => const OrderDeliveryScreen(),
        },
      ),
    );

    // Verify App Bar & Badge
    expect(find.text('Manage Orders'), findsOneWidget);
    expect(find.text('DELIVERY'), findsOneWidget);

    // Verify KPI Banner
    expect(find.text('Active Orders'), findsOneWidget);
    expect(find.text('In Escrow'), findsOneWidget);
    expect(find.text('On-Time Rate'), findsOneWidget);

    // Verify Filter Chips
    expect(find.text('All (4)'), findsOneWidget);
    expect(find.text('In Progress (2)'), findsOneWidget);
    expect(find.text('In Revision (1)'), findsOneWidget);
    expect(find.text('Completed (1)'), findsOneWidget);

    // Verify Order cards
    expect(find.text('Order #FH-9821'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('Deliver Work', skipOffstage: false), findsWidgets);

    // Test Search Filter
    await tester.enterText(find.byType(TextField), 'Marcus');
    await tester.pump();
    expect(find.text('Order #FH-9740'), findsOneWidget);
    expect(find.text('Order #FH-9821'), findsNothing);

    // Clear Search Filter
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Order #FH-9821'), findsOneWidget);

    // Tap "Deliver Work" on the first order to navigate to OrderDeliveryScreen
    final deliverWorkBtn = find.text('Deliver Work').first;
    await tester.tap(deliverWorkBtn);
    await tester.pumpAndSettle();

    // Verify navigated to OrderDeliveryScreen
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('TIME REMAINING'), findsOneWidget);
  });

  testWidgets('OrderDeliveryScreen smoke and delivery submission test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrderDeliveryScreen(),
      ),
    );

    // Verify App Bar and Header
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Order #FH-9821'), findsOneWidget);
    expect(find.text('FreelanceHub Pro'), findsOneWidget);

    // Verify Countdown Banner
    expect(find.text('TIME REMAINING'), findsOneWidget);
    expect(find.text('Due Date'), findsOneWidget);

    // Verify Client Summary
    expect(find.text('Sarah Jenkins'), findsWidgets);
    expect(find.text('Total Budget'), findsOneWidget);
    expect(find.text('\$450.00'), findsOneWidget);

    // Verify Client Brief & Assets
    expect(find.text('Client Brief & Assets'), findsOneWidget);
    expect(find.text('2 Files'), findsOneWidget);

    // Verify Deliver Completed Work Section
    expect(find.text('Deliver Completed Work'), findsWidgets);
    expect(find.text('Upload Work (ZIP, PNG, Figma Link)'), findsOneWidget);
    expect(find.text('FinTech_UI_v1.0_Final.zip'), findsOneWidget);
    expect(find.text('Delivery Note to Buyer'), findsOneWidget);
    expect(find.text('Add FreelanceHub Watermark'), findsOneWidget);

    // Verify Quick Seller Actions
    expect(find.text('Request Extension', skipOffstage: false), findsWidgets);
    expect(find.text('Contact Sarah', skipOffstage: false), findsOneWidget);

    // Submit Delivery (scroll into view and tap)
    final deliverBtn = find.widgetWithText(ElevatedButton, 'Deliver Completed Work');
    await tester.ensureVisible(deliverBtn);
    await tester.tap(deliverBtn);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verify Delivery Success Modal appears
    expect(find.text('Delivered Successfully!'), findsOneWidget);
    expect(find.text('Back to Orders List'), findsOneWidget);
  });
}


