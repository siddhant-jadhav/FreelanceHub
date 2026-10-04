import 'package:flutter_test/flutter_test.dart';
import 'package:freelancehub/main.dart';
import 'package:freelancehub/screens/buyer_requests_screen.dart';
import 'package:freelancehub/screens/client_home_screen.dart';
import 'package:freelancehub/screens/escrow_payments_screen.dart';
import 'package:freelancehub/screens/freelancer_dashboard_screen.dart';
import 'package:freelancehub/screens/freelancer_onboarding_screen.dart';
import 'package:freelancehub/screens/freelancer_onboarding_step2_screen.dart';
import 'package:freelancehub/screens/freelancer_orders_screen.dart';
import 'package:freelancehub/screens/individual_chat_screen.dart';
import 'package:freelancehub/screens/login_screen.dart';
import 'package:freelancehub/screens/messages_inbox_screen.dart';
import 'package:freelancehub/screens/order_delivery_screen.dart';
import 'package:freelancehub/screens/post_task_screen.dart';
import 'package:freelancehub/screens/project_workspace_screen.dart';
import 'package:freelancehub/screens/send_offer_screen.dart';
import 'package:freelancehub/screens/signup_screen.dart';
import 'package:freelancehub/screens/splash_screen.dart';
import 'package:freelancehub/screens/task_details_proposals_screen.dart';
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

  testWidgets('TaskDetailsProposalsScreen smoke and task summary metrics test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TaskDetailsProposalsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('Task Details'), findsOneWidget);

    // Verify Status & Title
    expect(find.text('Active • Receiving Proposals'), findsOneWidget);
    expect(
      find.text('Flutter Mobile App UI Implementation for Freelance Marketplace'),
      findsOneWidget,
    );

    // Verify Metrics Matrix
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('\$1200'), findsWidgets);
    expect(find.text('Fixed Price'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Turnaround'), findsOneWidget);
    expect(find.text('Candidates'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);

    // Verify Skills Cloud
    expect(find.text('Flutter'), findsWidgets);
    expect(find.text('Dart'), findsWidgets);
    expect(find.text('Firebase'), findsWidgets);
    expect(find.text('UI Kit'), findsOneWidget);
    expect(find.text('Figma to Code'), findsOneWidget);

    // Verify Proposals
    expect(find.text('Elena Rostova'), findsOneWidget);
    expect(find.text('100% JSS'), findsOneWidget);
    expect(find.text('\$1150'), findsOneWidget);
    expect(find.text('10 Days'), findsOneWidget);
    expect(find.text('3 Revisions'), findsOneWidget);

    expect(find.text('Marcus Vance'), findsOneWidget);
    expect(find.text('96% JSS'), findsOneWidget);

    // Verify 100% Escrow Protection card
    expect(find.text('100% Escrow Protection'), findsOneWidget);
  });

  testWidgets('TaskDetailsProposalsScreen interactive filters, message and accept offer test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TaskDetailsProposalsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Read more toggle
    expect(find.text('Read more'), findsOneWidget);
    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);

    // Tap Message button on Elena Rostova's proposal
    final messageBtns = find.widgetWithText(OutlinedButton, 'Message');
    expect(messageBtns, findsWidgets);
    await tester.ensureVisible(messageBtns.first);
    await tester.pumpAndSettle();
    await tester.tap(messageBtns.first);
    await tester.pumpAndSettle();

    // Verify Message Modal opened
    expect(find.text('Message Elena Rostova'), findsOneWidget);
    expect(find.text('Send Message'), findsOneWidget);

    // Send Message
    await tester.tap(find.text('Send Message'));
    await tester.pumpAndSettle();
    expect(find.text('Message sent to Elena Rostova!'), findsOneWidget);

    // Tap Accept ($1150) button on Elena's proposal
    final acceptBtn = find.widgetWithText(ElevatedButton, 'Accept (\$1150)');
    expect(acceptBtn, findsOneWidget);
    await tester.ensureVisible(acceptBtn);
    await tester.pumpAndSettle();
    await tester.tap(acceptBtn);
    await tester.pumpAndSettle();

    // Verify Escrow Modal opened
    expect(find.text('Accept & Fund Escrow'), findsOneWidget);
    expect(find.text('Total Escrow Deposit'), findsOneWidget);
    expect(find.text('Fund Escrow & Accept Offer (\$1150)'), findsOneWidget);

    // Confirm escrow funding
    await tester.tap(find.text('Fund Escrow & Accept Offer (\$1150)'));
    await tester.pumpAndSettle();

    // Verify accepted state
    expect(find.text('OFFER ACCEPTED & CONTRACT ACTIVE'), findsOneWidget);
  });

  testWidgets('PostTaskScreen smoke, sections, and fields test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PostTaskScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('Post Task'), findsOneWidget);

    // Verify Quick Hint Banner
    expect(find.text('Post in 2 minutes'), findsOneWidget);
    expect(
      find.text('Receive tailored proposals from verified pros today.'),
      findsOneWidget,
    );

    // Verify Section 1: Task Overview
    expect(find.text('1. Task Overview'), findsOneWidget);
    expect(find.text('Task Title'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Detailed Description'), findsOneWidget);

    // Verify Section 2: Required Skills
    expect(find.text('2. Required Skills'), findsOneWidget);
    expect(find.text('3 added'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('Firebase'), findsOneWidget);
    expect(find.text('Figma'), findsOneWidget);
    expect(find.text('SUGGESTED FOR THIS ROLE'), findsOneWidget);
    expect(find.text('React'), findsOneWidget);
    expect(find.text('Node.js'), findsOneWidget);

    // Verify Section 3: Budget & Payment Type
    expect(find.text('3. Budget & Payment Type'), findsOneWidget);
    expect(find.text('Fixed Price'), findsOneWidget);
    expect(find.text('Hourly Rate'), findsOneWidget);
    expect(find.text('Budget Amount (USD)'), findsOneWidget);

    // Scroll to see remaining sections
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    // Verify Section 4: Timeline & Attachments
    expect(find.text('4. Timeline & Attachments'), findsOneWidget);
    expect(find.text('Within 2 weeks'), findsOneWidget);
    expect(find.text('Project Brief & Documents'), findsOneWidget);
    expect(find.text('marketplace_app_spec_v2.pdf (1.8 MB)'), findsOneWidget);

    // Verify Section 5: Experience & Protection
    expect(find.text('5. Experience & Protection'), findsOneWidget);
    expect(find.text('Junior (1-2 yrs)'), findsOneWidget);
    expect(find.text('Mid (3-5 yrs)'), findsOneWidget);
    expect(find.text('Expert (5+ yrs)'), findsOneWidget);
    expect(find.text('100% Escrow Protection'), findsOneWidget);

    // Verify Sticky Bottom Action Bar
    expect(find.text('Post Task Now'), findsOneWidget);
    expect(find.text('Free to post • Get proposals in minutes'), findsOneWidget);
  });

  testWidgets('PostTaskScreen interactions, skill addition, toggle, and submission test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/task-details': (context) => const Scaffold(body: Text('Task Details Route')),
        },
        home: const PostTaskScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Add suggested skill: React
    final reactBtn = find.text('React');
    expect(reactBtn, findsOneWidget);
    await tester.ensureVisible(reactBtn);
    await tester.tap(reactBtn);
    await tester.pumpAndSettle();
    expect(find.text('4 added'), findsOneWidget);

    // Toggle Hourly Rate
    final hourlyBtn = find.text('Hourly Rate');
    expect(hourlyBtn, findsOneWidget);
    await tester.ensureVisible(hourlyBtn);
    await tester.tap(hourlyBtn);
    await tester.pumpAndSettle();
    expect(find.text('Hourly Rate (USD/hr)'), findsOneWidget);

    // Tap Post Task Now
    final postBtn = find.widgetWithText(ElevatedButton, 'Post Task Now');
    expect(postBtn, findsOneWidget);
    await tester.tap(postBtn);
    await tester.pump();

    // Verify Success indicator appeared
    expect(find.text('Task Published!'), findsOneWidget);

    // Settle all timers including navigation delay and snackbar
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('ProjectWorkspaceScreen smoke and section verification test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProjectWorkspaceScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Header & Contract Meta
    expect(find.text('CONTRACT #FH-88492'), findsOneWidget);
    expect(find.text('In Progress • Milestone 2'), findsOneWidget);
    expect(find.text('FreelanceHub Mobile Flutter App'), findsOneWidget);
    expect(find.text('Due Nov 24 (6 days left)'), findsOneWidget);
    expect(find.text('Escrow Protected'), findsOneWidget);

    // Verify Action Required Banner
    expect(find.text('Action Required: Milestone 2'), findsOneWidget);
    expect(find.text('Review Ready'), findsOneWidget);

    // Verify Freelancer Spotlight Card
    expect(find.text('Elena Rostova'), findsOneWidget);
    expect(find.text('Senior Flutter Developer'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Direct Chat'), findsOneWidget);
    expect(find.text('Contract'), findsOneWidget);

    // Verify Project Completion & Budget Bento
    expect(find.text('Project Completion'), findsOneWidget);
    expect(find.text('Total Value'), findsOneWidget);
    expect(find.text('In Escrow'), findsWidgets);
    expect(find.text('Released'), findsOneWidget);

    // Verify Milestones & Deliverables
    expect(find.text('Milestones & Deliverables'), findsOneWidget);
    expect(find.text('1. UI Architecture & Auth Screens'), findsOneWidget);
    expect(find.text('2. Explore & Task Details Screens'), findsOneWidget);
    expect(find.text('3. Payment & Escrow Flow'), findsOneWidget);
    expect(find.text('freelancehub_screens_v2.apk'), findsOneWidget);
    expect(find.text('github.com/org/repo/pull/42'), findsOneWidget);

    // Verify Activity & Note Dock
    expect(find.text('Workspace Activity'), findsOneWidget);
    expect(find.text('Send project note or instructions...'), findsOneWidget);
  });

  testWidgets(
      'ProjectWorkspaceScreen interactive inspect, revision, approval, and note test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProjectWorkspaceScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Inspect Pull Request
    final inspectBtn = find.text('Inspect');
    expect(inspectBtn, findsOneWidget);
    await tester.ensureVisible(inspectBtn);
    await tester.tap(inspectBtn);
    await tester.pumpAndSettle();
    expect(find.text('Pull Request #42'), findsOneWidget);
    expect(find.text('Inspection Complete'), findsOneWidget);
    await tester.tap(find.text('Inspection Complete'));
    await tester.pumpAndSettle();

    // 2. Send Collaboration Note
    final noteField = find.byType(TextField);
    expect(noteField, findsOneWidget);
    await tester.ensureVisible(noteField);
    await tester.enterText(noteField, 'Please verify iOS 17 keyboard insets.');
    final sendBtn = find.byIcon(LucideIcons.send);
    await tester.tap(sendBtn);
    await tester.pumpAndSettle();
    expect(find.text('Client (You): Please verify iOS 17 keyboard insets.'), findsOneWidget);

    // 3. Request Revision
    final revisionBtn = find.text('Revision');
    expect(revisionBtn, findsOneWidget);
    await tester.ensureVisible(revisionBtn);
    await tester.tap(revisionBtn);
    await tester.pumpAndSettle();
    expect(find.text('Request Revision'), findsOneWidget);

    // Enter revision feedback
    final revisionInput = find.byType(TextField).last;
    await tester.enterText(revisionInput, 'Needs darker border on cards.');
    await tester.tap(find.text('Send Revision'));
    await tester.pumpAndSettle();
    expect(find.text('In Revision'), findsWidgets);

    // 4. Approve & Release Escrow Funds
    final approveBtn = find.widgetWithText(ElevatedButton, 'Approve & Release (\$400)');
    expect(approveBtn, findsOneWidget);
    await tester.ensureVisible(approveBtn);
    await tester.tap(approveBtn);
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Release Escrow Funds'), findsOneWidget);
    await tester.tap(find.text('Confirm & Release (\$400)'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Verify milestone 2 approved and released
    expect(find.text('Approved'), findsWidgets);
    expect(find.text('Milestone 2 approved and \$400.00 released to Elena Rostova'), findsOneWidget);
    expect(find.text('2 of 3 Milestones Delivered'), findsOneWidget);
  });

  testWidgets('EscrowPaymentsScreen smoke, bento, and milestone verification test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EscrowPaymentsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Trust Banner
    expect(find.text('Escrow Payments'), findsOneWidget);
    expect(find.text('FreelanceHub Escrow Protection'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('256-bit Encrypted'), findsOneWidget);
    expect(find.text('Dispute Mediation'), findsOneWidget);
    expect(find.text('Money-Back Guarantee'), findsOneWidget);

    // Verify 2x2 Bento Summary Grid
    expect(find.text('IN ESCROW'), findsOneWidget);
    expect(find.text('\$800.00'), findsOneWidget);
    expect(find.text('Protected & Safe'), findsOneWidget);
    expect(find.text('TOTAL FUNDED'), findsOneWidget);
    expect(find.text('\$2,400.00'), findsOneWidget);
    expect(find.text('RELEASED'), findsOneWidget);
    expect(find.text('\$1,600.00'), findsOneWidget);
    expect(find.text('IN REVIEW'), findsOneWidget);
    expect(find.text('\$0.00'), findsOneWidget);

    // Verify Active Milestones
    expect(find.text('Active Milestones'), findsOneWidget);
    expect(find.text('2 Active'), findsOneWidget);
    expect(find.text('Elena Rostova'), findsOneWidget);
    expect(find.text('Mobile App MVP — Milestone 2'), findsOneWidget);
    expect(find.text('David Chen'), findsOneWidget);
    expect(find.text('Landing Page Redesign — Final Delivery'), findsOneWidget);

    // Verify Payment Methods & FDIC Card
    expect(find.text('Payment Methods'), findsOneWidget);
    expect(find.text('Visa ending in •••• 4291'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('FDIC-Insured Partner Trust Accounts'), findsOneWidget);

    // Verify Recent Transactions & Guarantee
    expect(find.text('Recent Transactions'), findsOneWidget);
    expect(find.text('Milestone 1 Payment Released'), findsOneWidget);
    expect(find.text('Escrow Deposit — Task #4829'), findsOneWidget);
    expect(find.text('Refund Processed — Task #4120'), findsOneWidget);
    expect(find.text('Download Tax Invoices & Statements'), findsOneWidget);
    expect(find.text('Protected by FreelanceHub Guarantee · 100% Secure Checkout'), findsOneWidget);
  });

  testWidgets(
      'EscrowPaymentsScreen interactive release, deposit funding, dispute, and statement test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EscrowPaymentsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Test Dispute Modal
    final disputeBtn = find.text('Dispute / Request Revision');
    expect(disputeBtn, findsOneWidget);
    await tester.ensureVisible(disputeBtn);
    await tester.tap(disputeBtn);
    await tester.pumpAndSettle();
    expect(find.text('Mediation & Dispute Request'), findsOneWidget);
    await tester.tap(find.text('Submit Dispute for Mediation'));
    await tester.pumpAndSettle();
    expect(find.text('1 claim pending'), findsOneWidget);

    // 2. Test Release Payment
    final releaseBtn = find.widgetWithText(ElevatedButton, 'Release Payment');
    expect(releaseBtn, findsOneWidget);
    await tester.ensureVisible(releaseBtn);
    await tester.tap(releaseBtn);
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Release Escrow Payment'), findsOneWidget);
    await tester.tap(find.text('Confirm & Release (\$400)'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Payment of \$400.00 released successfully to Elena Rostova!'), findsOneWidget);

    // 3. Test Deposit & Fund Milestone for David Chen
    final fundBtn = find.widgetWithText(ElevatedButton, 'Deposit & Fund Milestone');
    expect(fundBtn, findsOneWidget);
    await tester.ensureVisible(fundBtn);
    await tester.tap(fundBtn);
    await tester.pumpAndSettle();

    // Confirm deposit dialog
    expect(find.text('Deposit & Fund Milestone'), findsWidgets);
    await tester.tap(find.text('Deposit \$400.00'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Milestone Funded ✓'), findsOneWidget);

    // 4. Test Download Statements Modal
    final statementsCard = find.text('Download Tax Invoices & Statements');
    expect(statementsCard, findsOneWidget);
    await tester.ensureVisible(statementsCard);
    await tester.tap(statementsCard);
    await tester.pumpAndSettle();
    expect(find.text('Financial Statements'), findsOneWidget);
    await tester.tap(find.text('Download PDF'));
    await tester.pumpAndSettle();

    // Settle snackbar timers
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets(
      'MessagesInboxScreen smoke, active contacts, search, and filter test',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      const MaterialApp(
        home: MessagesInboxScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Brand Header in AppBar
    expect(
        find.descendant(
            of: find.byType(AppBar),
            matching: find.textContaining('FreelanceHub', findRichText: true)),
        findsOneWidget);

    // Verify Search Bar and Filter Pills
    expect(find.text('Search conversations or messages...'), findsOneWidget);
    expect(find.text('All (12)'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Starred'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);

    // Verify Active Contacts Tray
    expect(find.text('ACTIVE CONTACTS'), findsOneWidget);
    expect(find.text('5 online now'), findsOneWidget);
    expect(find.text('Sarah'), findsOneWidget);
    expect(find.text('Michael'), findsOneWidget);
    expect(find.text('Emma'), findsOneWidget);
    expect(find.text('David'), findsOneWidget);
    expect(find.text('Elena'), findsOneWidget);

    // Verify Conversation Rows
    expect(find.text('Sarah Johnson'), findsOneWidget);
    expect(find.text('Michael Chen'), findsOneWidget);
    expect(find.text('Emma Williams'), findsOneWidget);
    expect(find.text('David Chen'), findsOneWidget);
    expect(find.text('Alex Rivera'), findsOneWidget);

    // Verify Escrow Protection Footer
    expect(find.text('END-TO-END ESCROW PROTECTED'), findsOneWidget);

    // Test Search Filtering
    await tester.enterText(
        find.widgetWithText(TextField, 'Search conversations or messages...'),
        'Michael');
    await tester.pumpAndSettle();

    expect(find.text('Michael Chen'), findsOneWidget);
    expect(find.text('Sarah Johnson'), findsNothing);

    // Clear Search
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();
    expect(find.text('Sarah Johnson'), findsOneWidget);

    // Test Filter Pills: Unread
    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();
    expect(find.text('Sarah Johnson'), findsOneWidget);
    expect(find.text('Michael Chen'), findsOneWidget);
    expect(find.text('Emma Williams'), findsNothing);

    // Reset Filter to All
    await tester.tap(find.text('All (12)'));
    await tester.pumpAndSettle();
    expect(find.text('Emma Williams'), findsOneWidget);
  });

  testWidgets(
      'IndividualChatScreen smoke, pinned project context, messages, and interactive sending test',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      const MaterialApp(
        home: IndividualChatScreen(
          contactName: 'Sarah Johnson',
          contactRole: 'Client',
          projectTitle: 'E-commerce Mobile App MVP',
          projectBudget: 1200.0,
          projectInEscrow: 800.0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Header
    expect(find.text('Sarah Johnson'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);

    // Verify Pinned Project Context Bar
    expect(find.text('E-commerce Mobile App MVP'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('Workspace'), findsOneWidget);

    // Verify Escrow Protection Security Banner
    expect(
        find.textContaining('Payments and conversations are secured by',
            findRichText: true),
        findsOneWidget);

    // Verify Messages Stream
    expect(
        find.text(
            "Hi! I've reviewed your proposal and I'd like to discuss the project timeline."),
        findsOneWidget);
    expect(find.text('Sure. I can start working on it from Monday.'),
        findsOneWidget);
    expect(find.text("Perfect. I'll share the final requirements today."),
        findsOneWidget);

    // Verify File Attachment Card
    expect(find.text('ecommerce_requirements_v3.pdf'), findsOneWidget);
    expect(find.text('Download / Preview'), findsOneWidget);

    // Verify Deliverable Preview Card
    expect(find.text('Design_System_Components_v1.fig'), findsOneWidget);
    expect(find.text('Design Draft'), findsOneWidget);

    // Verify Quick Action Offer Prompt
    expect(find.text('Propose Milestone / Scope Change'), findsOneWidget);
    expect(find.text('View Milestones'), findsOneWidget);
    expect(find.text('Create Custom Offer'), findsOneWidget);

    // Verify Escrow Footnote
    expect(find.text('100% Escrow Protection active on this contract'),
        findsOneWidget);

    // 1. Test Sending a new message
    final inputFinder = find.widgetWithText(TextField, 'Type a message...');
    expect(inputFinder, findsOneWidget);
    await tester.enterText(inputFinder, "Let's review the mockups now.");
    await tester.pumpAndSettle();

    final sendBtnFinder = find.byTooltip('Send Message');
    expect(sendBtnFinder, findsOneWidget);
    await tester.tap(sendBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text("Let's review the mockups now."), findsOneWidget);

    // 2. Test Attachment Sheet
    final attachBtn = find.byTooltip('Attach file or preview');
    expect(attachBtn, findsOneWidget);
    await tester.tap(attachBtn);
    await tester.pumpAndSettle();

    expect(find.text('Share Attachment'), findsOneWidget);
    expect(find.text('Document / Specifications (PDF)'), findsOneWidget);

    // Tap Document Attachment
    await tester.tap(find.text('Document / Specifications (PDF)'));
    await tester.pumpAndSettle();
    expect(find.text('client_brand_guidelines_2026.pdf'), findsOneWidget);

    // 3. Test Audio Call Dialog
    final callBtn = find.byIcon(LucideIcons.phone);
    expect(callBtn, findsOneWidget);
    await tester.tap(callBtn);
    await tester.pumpAndSettle();

    expect(find.text('Call Sarah Johnson'), findsOneWidget);
    expect(find.text('Start Call'), findsOneWidget);
    await tester.tap(find.text('Start Call'));
    await tester.pumpAndSettle();

    // Settle snackbar timers
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}


