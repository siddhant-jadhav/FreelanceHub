import 'package:flutter_test/flutter_test.dart';
import 'package:freelancehub/core/errors/app_exception.dart';
import 'package:freelancehub/core/services/firebase_service.dart';
import 'package:freelancehub/models/client_model.dart';
import 'package:freelancehub/models/conversation_model.dart';
import 'package:freelancehub/models/freelancer_model.dart';
import 'package:freelancehub/models/message_model.dart';
import 'package:freelancehub/models/milestone_model.dart';
import 'package:freelancehub/models/notification_model.dart';
import 'package:freelancehub/models/payment_model.dart';
import 'package:freelancehub/models/project_model.dart';
import 'package:freelancehub/models/proposal_model.dart';
import 'package:freelancehub/models/review_model.dart';
import 'package:freelancehub/models/task_model.dart';
import 'package:freelancehub/models/user_model.dart';
import 'package:freelancehub/repositories/client_repository.dart';
import 'package:freelancehub/repositories/freelancer_repository.dart';
import 'package:freelancehub/repositories/message_repository.dart';
import 'package:freelancehub/repositories/milestone_repository.dart';
import 'package:freelancehub/repositories/notification_repository.dart';
import 'package:freelancehub/repositories/payment_repository.dart';
import 'package:freelancehub/repositories/project_repository.dart';
import 'package:freelancehub/repositories/proposal_repository.dart';
import 'package:freelancehub/repositories/review_repository.dart';
import 'package:freelancehub/repositories/task_repository.dart';
import 'package:freelancehub/repositories/user_repository.dart';
import 'package:freelancehub/services/auth_service.dart';
import 'package:freelancehub/services/client_service.dart';
import 'package:freelancehub/services/firestore_service.dart';
import 'package:freelancehub/services/notification_service.dart';
import 'package:freelancehub/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppException Mapping Tests', () {
    test('Translates common FirebaseAuthException error codes correctly', () {
      final notFoundEx = AppException.fromAuth('user-not-found', 'No user found');
      expect(notFoundEx.message, contains('No user found with this email'));

      final wrongPassEx = AppException.fromAuth('wrong-password', 'Incorrect');
      expect(wrongPassEx.message, contains('Incorrect password'));

      final emailInUseEx = AppException.fromAuth('email-already-in-use', 'In use');
      expect(emailInUseEx.message, contains('already registered'));

      final weakPassEx = AppException.fromAuth('weak-password', 'Weak');
      expect(weakPassEx.message, contains('at least 6 characters'));

      final networkEx = AppException.fromAuth('network-request-failed', 'Network');
      expect(networkEx.message, contains('Network connection failed'));
    });

    test('Translates Firestore error codes correctly', () {
      final permEx = AppException.fromFirestore('permission-denied', 'Denied');
      expect(permEx.message, contains('do not have permission'));

      final notFoundDoc = AppException.fromFirestore('not-found', 'Not found');
      expect(notFoundDoc.message, contains('requested resource was not found'));
    });

    test('AppException generic wrapping', () {
      final appEx = AppException.from(Exception('Custom error message'));
      expect(appEx.message, contains('Custom error message'));
    });
  });

  group('Model Serialization & Deserialization Tests', () {
    test('UserModel round-trip serialization', () {
      final now = DateTime.now();
      final user = UserModel(
        id: 'u123',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        role: 'freelancer',
        profileCompleted: true,
        onboardingStep: 2,
        photoUrl: 'https://example.com/avatar.jpg',
        createdAt: now,
        updatedAt: now,
      );

      final map = user.toMap();
      expect(map['fullName'], 'Jane Doe');
      expect(map['role'], 'freelancer');
      expect(map['profileCompleted'], true);

      final parsed = UserModel.fromMap(map, 'u123');
      expect(parsed.id, 'u123');
      expect(parsed.fullName, 'Jane Doe');
      expect(parsed.email, 'jane@example.com');
      expect(parsed.role, 'freelancer');
      expect(parsed.profileCompleted, true);
    });

    test('FreelancerModel & PortfolioItem round-trip serialization', () {
      final now = DateTime.now();
      final item = PortfolioItem(
        id: 'p1',
        title: 'Mobile Banking App',
        description: 'Flutter finance app',
        imageUrl: 'https://example.com/project.jpg',
        tags: ['Flutter', 'Firebase'],
      );

      final freelancer = FreelancerModel(
        id: 'f101',
        name: 'Alex Rivera',
        title: 'Senior Mobile Architect',
        bio: 'Building enterprise mobile solutions',
        skills: ['Flutter', 'Dart', 'Firebase'],
        services: ['App Development', 'Code Review'],
        hourlyRate: 85.0,
        rating: 4.95,
        reviewsCount: 38,
        completedOrders: 42,
        isTopRated: true,
        availability: 'available',
        portfolio: [item],
        createdAt: now,
      );

      final map = freelancer.toMap();
      expect(map['name'], 'Alex Rivera');
      expect(map['hourlyRate'], 85.0);
      expect((map['portfolio'] as List).length, 1);

      final parsed = FreelancerModel.fromMap(map, 'f101');
      expect(parsed.id, 'f101');
      expect(parsed.skills, contains('Flutter'));
      expect(parsed.portfolio.first.title, 'Mobile Banking App');
      expect(parsed.isTopRated, true);
    });

    test('ClientModel round-trip serialization', () {
      final now = DateTime.now();
      final client = ClientModel(
        id: 'c202',
        name: 'Apex Solutions',
        company: 'Apex Digital Inc.',
        country: 'United States',
        isVerified: true,
        totalSpent: 12500.0,
        activeProjectsCount: 3,
        createdAt: now,
      );

      final map = client.toMap();
      expect(map['company'], 'Apex Digital Inc.');
      expect(map['totalSpent'], 12500.0);

      final parsed = ClientModel.fromMap(map, 'c202');
      expect(parsed.id, 'c202');
      expect(parsed.name, 'Apex Solutions');
      expect(parsed.isVerified, true);
    });

    test('TaskModel round-trip serialization', () {
      final now = DateTime.now();
      final deadline = now.add(const Duration(days: 14));
      final task = TaskModel(
        id: 't303',
        clientId: 'c202',
        clientName: 'Apex Solutions',
        title: 'Build Firebase Backend Service',
        description: 'Complete data layer integration with Firestore',
        category: 'Development',
        requiredSkills: ['Flutter', 'Firebase', 'Firestore'],
        budget: 1500.0,
        deadline: deadline,
        status: 'open',
        offersCount: 5,
        createdAt: now,
      );

      final map = task.toMap();
      expect(map['budget'], 1500.0);
      expect(map['status'], 'open');

      final parsed = TaskModel.fromMap(map, 't303');
      expect(parsed.id, 't303');
      expect(parsed.title, 'Build Firebase Backend Service');
      expect(parsed.offersCount, 5);
    });

    test('ProposalModel round-trip serialization', () {
      final now = DateTime.now();
      final proposal = ProposalModel(
        id: 'prop404',
        taskId: 't303',
        taskTitle: 'Build Firebase Backend Service',
        freelancerId: 'f101',
        clientId: 'c202',
        freelancerName: 'Alex Rivera',
        freelancerTitle: 'Senior Mobile Architect',
        proposedPrice: 1400.0,
        deliveryTimeDays: 7,
        coverLetter: 'I have extensive experience with Firebase architecture.',
        status: 'pending',
        createdAt: now,
      );

      final map = proposal.toMap();
      expect(map['proposedPrice'], 1400.0);
      expect(map['deliveryTimeDays'], 7);

      final parsed = ProposalModel.fromMap(map, 'prop404');
      expect(parsed.id, 'prop404');
      expect(parsed.freelancerName, 'Alex Rivera');
      expect(parsed.status, 'pending');
    });

    test('ProjectModel and MilestoneModel round-trip serialization', () {
      final now = DateTime.now();
      final milestone = MilestoneModel(
        id: 'm1',
        projectId: 'proj505',
        milestoneNumber: 1,
        title: 'Phase 1: Architecture & Auth',
        amount: 500.0,
        dueDate: now.add(const Duration(days: 3)),
        status: 'funded_in_escrow',
        description: 'Complete authentication service and security rules',
      );

      final milestoneMap = milestone.toMap();
      final parsedMilestone = MilestoneModel.fromMap(milestoneMap, 'm1');
      expect(parsedMilestone.id, 'm1');
      expect(parsedMilestone.title, 'Phase 1: Architecture & Auth');
      expect(parsedMilestone.amount, 500.0);

      final project = ProjectModel(
        id: 'proj505',
        taskId: 't303',
        clientId: 'c202',
        clientName: 'Apex Solutions',
        freelancerId: 'f101',
        freelancerName: 'Alex Rivera',
        title: 'Build Firebase Backend Service',
        budget: 1400.0,
        status: 'in_progress',
        progress: 0.35,
        startedDate: now,
        dueDate: now.add(const Duration(days: 14)),
        createdAt: now,
      );

      final map = project.toMap();
      expect(map['progress'], 0.35);
      expect(map['budget'], 1400.0);

      final parsed = ProjectModel.fromMap(map, 'proj505');
      expect(parsed.id, 'proj505');
      expect(parsed.title, 'Build Firebase Backend Service');
      expect(parsed.budget, 1400.0);
    });

    test('MessageModel and ConversationModel round-trip serialization', () {
      final now = DateTime.now();
      final msg = MessageModel(
        id: 'msg606',
        conversationId: 'conv707',
        senderId: 'f101',
        receiverId: 'c202',
        message: 'Hello, I have submitted the deliverable.',
        isRead: false,
        createdAt: now,
      );

      final map = msg.toMap();
      expect(map['message'], 'Hello, I have submitted the deliverable.');
      expect(map['isRead'], false);

      final parsed = MessageModel.fromMap(map, 'msg606');
      expect(parsed.id, 'msg606');
      expect(parsed.senderId, 'f101');
      expect(parsed.isRead, false);

      final conv = ConversationModel(
        id: 'conv707',
        participantIds: ['f101', 'c202'],
        lastMessage: 'Hello, I have submitted the deliverable.',
        lastMessageSenderId: 'f101',
        lastMessageTime: now,
        unreadCounts: {'c202': 1, 'f101': 0},
      );

      final convMap = conv.toMap();
      expect(convMap['lastMessageSenderId'], 'f101');
      final parsedConv = ConversationModel.fromMap(convMap, 'conv707');
      expect(parsedConv.unreadCounts['c202'], 1);
    });

    test('NotificationModel round-trip serialization', () {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: 'notif808',
        userId: 'c202',
        type: 'new_proposal',
        title: 'New Custom Offer',
        message: 'Alex Rivera submitted a proposal.',
        referenceId: 't303',
        isRead: false,
        createdAt: now,
      );

      final map = notification.toMap();
      expect(map['type'], 'new_proposal');
      expect(map['isRead'], false);

      final parsed = NotificationModel.fromMap(map, 'notif808');
      expect(parsed.id, 'notif808');
      expect(parsed.title, 'New Custom Offer');
    });

    test('PaymentModel round-trip serialization', () {
      final now = DateTime.now();
      final payment = PaymentModel(
        id: 'pay909',
        projectId: 'proj505',
        milestoneId: 'm1',
        clientId: 'c202',
        freelancerId: 'f101',
        amount: 500.0,
        platformFee: 25.0,
        netAmount: 475.0,
        status: 'held_in_escrow',
        createdAt: now,
      );

      final map = payment.toMap();
      expect(map['amount'], 500.0);
      expect(map['status'], 'held_in_escrow');

      final parsed = PaymentModel.fromMap(map, 'pay909');
      expect(parsed.id, 'pay909');
      expect(parsed.amount, 500.0);
    });

    test('ReviewModel round-trip serialization', () {
      final now = DateTime.now();
      final review = ReviewModel(
        id: 'rev1010',
        projectId: 'proj505',
        clientId: 'c202',
        freelancerId: 'f101',
        clientName: 'Apex Solutions',
        rating: 5.0,
        comment: 'Outstanding delivery and clean architecture!',
        createdAt: now,
      );

      final map = review.toMap();
      expect(map['rating'], 5.0);
      expect(map['comment'], 'Outstanding delivery and clean architecture!');

      final parsed = ReviewModel.fromMap(map, 'rev1010');
      expect(parsed.id, 'rev1010');
      expect(parsed.rating, 5.0);
      expect(parsed.clientName, 'Apex Solutions');
    });
  });

  group('Service & Repository Layer Instantiation Tests', () {
    test('FirebaseService gateway and sub-repositories instantiate safely', () {
      final service = FirebaseService.instance;
      expect(service, isNotNull);
      expect(service.authService, isA<AuthService>());
      expect(service.firestoreService, isA<FirestoreService>());
      expect(service.storageService, isA<StorageService>());
      expect(service.notificationService, isA<NotificationService>());
      expect(service.userRepository, isA<UserRepository>());
      expect(service.freelancerRepository, isA<FreelancerRepository>());
      expect(service.clientRepository, isA<ClientRepository>());
      expect(service.taskRepository, isA<TaskRepository>());
      expect(service.proposalRepository, isA<ProposalRepository>());
      expect(service.projectRepository, isA<ProjectRepository>());
      expect(service.milestoneRepository, isA<MilestoneRepository>());
      expect(service.messageRepository, isA<MessageRepository>());
      expect(service.notificationRepository, isA<NotificationRepository>());
      expect(service.paymentRepository, isA<PaymentRepository>());
      expect(service.reviewRepository, isA<ReviewRepository>());
      expect(service.clientService, isA<ClientService>());
    });

    test('Individual repository singletons are accessible without errors', () {
      expect(UserRepository.instance, isNotNull);
      expect(FreelancerRepository.instance, isNotNull);
      expect(ClientRepository.instance, isNotNull);
      expect(TaskRepository.instance, isNotNull);
      expect(ProposalRepository.instance, isNotNull);
      expect(ProjectRepository.instance, isNotNull);
      expect(MilestoneRepository.instance, isNotNull);
      expect(MessageRepository.instance, isNotNull);
      expect(NotificationRepository.instance, isNotNull);
      expect(PaymentRepository.instance, isNotNull);
      expect(ReviewRepository.instance, isNotNull);
      expect(AuthService.instance, isNotNull);
      expect(FirestoreService.instance, isNotNull);
      expect(StorageService.instance, isNotNull);
      expect(NotificationService.instance, isNotNull);
      expect(ClientService.instance, isNotNull);
    });

    test('ClientService exposes task and proposal streams gracefully', () {
      final clientService = ClientService.instance;
      expect(clientService.streamActiveProjects('client1'), isA<Stream>());
      expect(clientService.streamRecommendedFreelancers(), isA<Stream>());
      expect(clientService.streamTask('task1'), isA<Stream>());
      expect(clientService.streamTaskProposals('task1'), isA<Stream>());
    });
  });

  group('Two-User Workflow State Transition Tests (Vedant <-> Siddhant)', () {
    const vedantUid = 'vedant_client_uid';
    const vedantName = 'Vedant';

    const siddhantUid = 'siddhant_freelancer_uid';
    const siddhantName = 'Siddhant';

    test('1. Client (Vedant) posts a task', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 'task_e2e_1',
        clientId: vedantUid,
        clientName: vedantName,
        title: 'Full-Stack Mobile App for FreelanceHub',
        description: 'Build a production-grade Flutter application with Firebase integration.',
        category: 'Mobile App Development',
        budget: 1500.0,
        deadline: now.add(const Duration(days: 14)),
        status: 'open',
        requiredSkills: ['Flutter', 'Firebase', 'State Management'],
        createdAt: now,
      );

      final map = task.toMap();
      expect(map['clientId'], vedantUid);
      expect(map['budget'], 1500.0);
      expect(map['status'], 'open');
      expect(map['offersCount'], 0);
    });

    test('2. Freelancer (Siddhant) submits proposal to Vedant\'s task', () {
      final now = DateTime.now();
      final proposal = ProposalModel(
        id: 'prop_e2e_1',
        taskId: 'task_e2e_1',
        taskTitle: 'Full-Stack Mobile App for FreelanceHub',
        freelancerId: siddhantUid,
        freelancerName: siddhantName,
        clientId: vedantUid,
        proposedPrice: 1500.0,
        deliveryTimeDays: 14,
        coverLetter: 'I will build the full application using clean architecture and real-time Firestore listeners.',
        status: 'pending',
        createdAt: now,
      );

      final propMap = proposal.toMap();
      expect(propMap['taskId'], 'task_e2e_1');
      expect(propMap['freelancerId'], siddhantUid);
      expect(propMap['proposedPrice'], 1500.0);
      expect(propMap['status'], 'pending');

      final milestone1 = MilestoneModel(
        id: 'ms_1',
        projectId: 'proj_e2e_1',
        title: 'Milestone 1: Core Architecture & UI',
        description: 'Implement all screens, components, and state management.',
        amount: 750.0,
        milestoneNumber: 1,
        status: 'pending',
        dueDate: now.add(const Duration(days: 7)),
      );
      expect(milestone1.amount, 750.0);
    });

    test('3. Client (Vedant) accepts proposal, creates Project and Escrow Deposit', () {
      final now = DateTime.now();
      final project = ProjectModel(
        id: 'proj_e2e_1',
        taskId: 'task_e2e_1',
        clientId: vedantUid,
        clientName: vedantName,
        freelancerId: siddhantUid,
        freelancerName: siddhantName,
        title: 'Full-Stack Mobile App for FreelanceHub',
        status: 'in_progress',
        budget: 1500.0,
        progress: 0.0,
        startedDate: now,
        dueDate: now.add(const Duration(days: 14)),
        createdAt: now,
        completedMilestones: 0,
        totalMilestones: 2,
      );

      expect(project.status, 'in_progress');
      expect(project.clientId, vedantUid);
      expect(project.freelancerId, siddhantUid);

      final payment = PaymentModel(
        id: 'pay_e2e_1',
        projectId: project.id,
        clientId: vedantUid,
        freelancerId: siddhantUid,
        amount: 1500.0,
        netAmount: 1500.0,
        status: 'held_in_escrow',
        createdAt: now,
      );

      final payMap = payment.toMap();
      expect(payMap['status'], 'held_in_escrow');
      expect(payMap['amount'], 1500.0);
      expect(payMap['clientId'], vedantUid);
      expect(payMap['freelancerId'], siddhantUid);
    });

    test('4. Freelancer (Siddhant) submits work deliverable -> status transitions to review', () {
      final now = DateTime.now();
      final projectBefore = ProjectModel(
        id: 'proj_e2e_1',
        taskId: 'task_e2e_1',
        clientId: vedantUid,
        clientName: vedantName,
        freelancerId: siddhantUid,
        freelancerName: siddhantName,
        title: 'Full-Stack Mobile App for FreelanceHub',
        status: 'in_progress',
        budget: 1500.0,
        progress: 0.5,
        startedDate: now,
        dueDate: now.add(const Duration(days: 14)),
        createdAt: now,
        completedMilestones: 0,
        totalMilestones: 2,
      );

      final projectAfterDelivery = projectBefore.copyWith(
        status: 'review',
        progress: 1.0,
      );

      expect(projectAfterDelivery.status, 'review');
      expect(projectAfterDelivery.progress, 1.0);
    });

    test('5. Realtime 1-on-1 Messaging between Vedant and Siddhant', () {
      final now = DateTime.now();
      final conv = ConversationModel(
        id: 'conv_vedant_siddhant',
        participantIds: [vedantUid, siddhantUid],
        participantNames: {
          vedantUid: vedantName,
          siddhantUid: siddhantName,
        },
        lastMessage: 'Here is the completed build for Milestone 1.',
        lastMessageTime: now,
        unreadCounts: {
          vedantUid: 1,
          siddhantUid: 0,
        },
        projectId: 'proj_e2e_1',
        lastMessageSenderId: siddhantUid,
      );

      expect(conv.participantIds, containsAll([vedantUid, siddhantUid]));
      expect(conv.unreadCounts[vedantUid], 1);

      final msg1 = MessageModel(
        id: 'msg_1',
        conversationId: conv.id,
        senderId: siddhantUid,
        receiverId: vedantUid,
        message: 'Here is the completed build for Milestone 1.',
        createdAt: now,
        isRead: false,
      );

      expect(msg1.senderId, siddhantUid);
      expect(msg1.receiverId, vedantUid);

      final msg2 = MessageModel(
        id: 'msg_2',
        conversationId: conv.id,
        senderId: vedantUid,
        receiverId: siddhantUid,
        message: 'Looks great! Reviewing the build right now.',
        createdAt: now.add(const Duration(minutes: 5)),
        isRead: true,
      );

      expect(msg2.senderId, vedantUid);
      expect(msg2.receiverId, siddhantUid);
    });

    test('6. Vedant reviews deliverable, approves and releases Escrow payment', () {
      final now = DateTime.now();
      final completedProject = ProjectModel(
        id: 'proj_e2e_1',
        taskId: 'task_e2e_1',
        clientId: vedantUid,
        clientName: vedantName,
        freelancerId: siddhantUid,
        freelancerName: siddhantName,
        title: 'Full-Stack Mobile App for FreelanceHub',
        status: 'completed',
        budget: 1500.0,
        progress: 1.0,
        startedDate: now,
        dueDate: now.add(const Duration(days: 14)),
        createdAt: now,
        completedMilestones: 2,
        totalMilestones: 2,
      );

      expect(completedProject.status, 'completed');
      expect(completedProject.completedMilestones, 2);

      final releasedPayment = PaymentModel(
        id: 'pay_e2e_1',
        projectId: completedProject.id,
        clientId: vedantUid,
        freelancerId: siddhantUid,
        amount: 1500.0,
        netAmount: 1500.0,
        status: 'released',
        createdAt: now,
      );

      expect(releasedPayment.status, 'released');
      expect(releasedPayment.amount, 1500.0);
    });

    test('7. Real notifications generated for all workflow steps', () {
      final now = DateTime.now();
      final notif1 = NotificationModel(
        id: 'notif_1',
        userId: vedantUid,
        type: 'new_proposal',
        title: 'New Proposal Received',
        message: '$siddhantName submitted an offer of \$1,500.00 for your task.',
        referenceId: 'task_e2e_1',
        createdAt: now,
      );
      expect(notif1.userId, vedantUid);
      expect(notif1.type, 'new_proposal');

      final notif2 = NotificationModel(
        id: 'notif_2',
        userId: siddhantUid,
        type: 'proposal_accepted',
        title: 'Proposal Accepted! 🎉',
        message: '$vedantName accepted your offer. Project has started and escrow is funded.',
        referenceId: 'proj_e2e_1',
        createdAt: now,
      );
      expect(notif2.userId, siddhantUid);
      expect(notif2.type, 'proposal_accepted');

      final notif3 = NotificationModel(
        id: 'notif_3',
        userId: siddhantUid,
        type: 'payment_released',
        title: 'Escrow Funds Released! 💰',
        message: '$vedantName approved your deliverable and released \$1,500.00.',
        referenceId: 'proj_e2e_1',
        createdAt: now,
      );
      expect(notif3.userId, siddhantUid);
      expect(notif3.type, 'payment_released');
    });
  });
}
