import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../models/client_model.dart';
import '../models/freelancer_model.dart';
import '../models/milestone_model.dart';
import '../models/payment_model.dart';
import '../models/project_model.dart';
import '../models/proposal_model.dart';
import '../models/task_model.dart';
import '../repositories/client_repository.dart';
import '../repositories/freelancer_repository.dart';
import '../repositories/milestone_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/proposal_repository.dart';
import '../repositories/task_repository.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// Dedicated client service orchestrating client home dashboard operations,
/// project deliveries, task creation, talent discovery, proposal reviews, and milestones.
class ClientService {
  final TaskRepository? _injectedTaskRepo;
  final ProjectRepository? _injectedProjectRepo;
  final MilestoneRepository? _injectedMilestoneRepo;
  final FreelancerRepository? _injectedFreelancerRepo;
  final ClientRepository? _injectedClientRepo;
  final ProposalRepository? _injectedProposalRepo;
  final PaymentRepository? _injectedPaymentRepo;
  final NotificationService? _injectedNotificationService;
  final AuthService? _injectedAuthService;

  ClientService({
    TaskRepository? taskRepo,
    ProjectRepository? projectRepo,
    MilestoneRepository? milestoneRepo,
    FreelancerRepository? freelancerRepo,
    ClientRepository? clientRepo,
    ProposalRepository? proposalRepo,
    PaymentRepository? paymentRepo,
    NotificationService? notificationService,
    AuthService? authService,
  })  : _injectedTaskRepo = taskRepo,
        _injectedProjectRepo = projectRepo,
        _injectedMilestoneRepo = milestoneRepo,
        _injectedFreelancerRepo = freelancerRepo,
        _injectedClientRepo = clientRepo,
        _injectedProposalRepo = proposalRepo,
        _injectedPaymentRepo = paymentRepo,
        _injectedNotificationService = notificationService,
        _injectedAuthService = authService;

  static final ClientService instance = ClientService();

  TaskRepository get _taskRepo =>
      _injectedTaskRepo ?? TaskRepository.instance;
  ProjectRepository get _projectRepo =>
      _injectedProjectRepo ?? ProjectRepository.instance;
  MilestoneRepository get _milestoneRepo =>
      _injectedMilestoneRepo ?? MilestoneRepository.instance;
  FreelancerRepository get _freelancerRepo =>
      _injectedFreelancerRepo ?? FreelancerRepository.instance;
  ClientRepository get _clientRepo =>
      _injectedClientRepo ?? ClientRepository.instance;
  ProposalRepository get _proposalRepo =>
      _injectedProposalRepo ?? ProposalRepository.instance;
  PaymentRepository get _paymentRepo =>
      _injectedPaymentRepo ?? PaymentRepository.instance;
  NotificationService get _notificationService =>
      _injectedNotificationService ?? NotificationService.instance;
  AuthService get _authService =>
      _injectedAuthService ?? AuthService.instance;

  String? get currentClientId => _authService.currentUid;

  /// Stream of active delivery projects for client
  Stream<List<ProjectModel>> streamActiveProjects(String clientId) {
    try {
      return _projectRepo.streamProjectsForClient(clientId);
    } catch (e) {
      debugPrint('streamActiveProjects notice: $e');
      return const Stream.empty();
    }
  }

  /// Stream of vetted and recommended freelancers from Firestore
  Stream<List<FreelancerModel>> streamRecommendedFreelancers({
    String? category,
    int limit = 10,
  }) {
    try {
      return _freelancerRepo.streamFreelancers(category: category, limit: limit);
    } catch (e) {
      debugPrint('streamRecommendedFreelancers notice: $e');
      return const Stream.empty();
    }
  }

  /// Stream task details by ID
  Stream<TaskModel?> streamTask(String taskId) {
    try {
      return _taskRepo.getTaskStream(taskId);
    } catch (e) {
      debugPrint('streamTask notice: $e');
      return const Stream.empty();
    }
  }

  /// Fetch single task by ID
  Future<TaskModel?> getTask(String taskId) async {
    try {
      return await _taskRepo.getTask(taskId);
    } catch (e) {
      debugPrint('getTask notice: $e');
      return null;
    }
  }

  /// Stream proposals submitted for a specific task
  Stream<List<ProposalModel>> streamTaskProposals(String taskId) {
    try {
      return _proposalRepo.streamProposalsForTask(taskId);
    } catch (e) {
      debugPrint('streamTaskProposals notice: $e');
      return const Stream.empty();
    }
  }

  /// Fetch all proposals for a specific task
  Future<List<ProposalModel>> getTaskProposals(String taskId) async {
    try {
      return await _proposalRepo.getProposalsForTask(taskId);
    } catch (e) {
      debugPrint('getTaskProposals notice: $e');
      return [];
    }
  }

  /// Toggle shortlist flag for a candidate proposal
  Future<void> toggleShortlistProposal({
    required String proposalId,
    required bool isShortlisted,
  }) async {
    try {
      await _proposalRepo.toggleProposalShortlist(proposalId, isShortlisted);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Decline a candidate proposal
  Future<void> declineProposal({
    required String proposalId,
  }) async {
    try {
      await _proposalRepo.updateProposalStatus(proposalId, 'rejected');
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Accept proposal, fund escrow contract, create project and milestones
  Future<String> acceptProposal({
    required TaskModel task,
    required ProposalModel proposal,
  }) async {
    try {
      // 1. Mark accepted proposal
      await _proposalRepo.updateProposalStatus(proposal.id, 'accepted');

      // 2. Update task status to in_progress
      await _taskRepo.updateTaskStatus(task.id, 'in_progress');

      // 3. Create project contract
      final newProject = ProjectModel(
        id: '',
        taskId: task.id,
        clientId: task.clientId.isNotEmpty ? task.clientId : (currentClientId ?? 'client_unknown'),
        clientName: task.clientName.isNotEmpty ? task.clientName : 'Client',
        freelancerId: proposal.freelancerId,
        freelancerName: proposal.freelancerName,
        title: task.title,
        budget: proposal.proposedPrice > 0 ? proposal.proposedPrice : task.budget,
        status: 'in_progress',
        progress: 0.0,
        completedMilestones: 0,
        totalMilestones: proposal.milestones.isNotEmpty ? proposal.milestones.length : 1,
        startedDate: DateTime.now(),
        dueDate: DateTime.now().add(Duration(days: proposal.deliveryTimeDays > 0 ? proposal.deliveryTimeDays : 14)),
        createdAt: DateTime.now(),
      );

      final projectId = await _projectRepo.createProject(newProject);

      // 4. Create milestones if provided
      if (proposal.milestones.isNotEmpty) {
        for (int i = 0; i < proposal.milestones.length; i++) {
          final m = proposal.milestones[i];
          final milestone = MilestoneModel(
            id: '',
            projectId: projectId,
            milestoneNumber: i + 1,
            title: (m['title'] as String?) ?? 'Milestone ${i + 1}',
            amount: (m['amount'] as num?)?.toDouble() ?? (newProject.budget / proposal.milestones.length),
            dueDate: DateTime.now().add(Duration(days: (i + 1) * 7)),
            status: i == 0 ? 'funded_in_escrow' : 'pending',
            description: (m['description'] as String?) ?? 'Project phase deliverable ${i + 1}',
          );
          await _milestoneRepo.createMilestone(milestone);
        }
      } else {
        // Create single milestone for entire project
        final milestone = MilestoneModel(
          id: '',
          projectId: projectId,
          milestoneNumber: 1,
          title: 'Full Project Delivery',
          amount: newProject.budget,
          dueDate: newProject.dueDate,
          status: 'funded_in_escrow',
          description: task.description,
        );
        await _milestoneRepo.createMilestone(milestone);
      }

      // 5. Create persistent Escrow Deposit record in payments collection
      final payment = PaymentModel(
        id: '',
        projectId: projectId,
        clientId: newProject.clientId,
        freelancerId: newProject.freelancerId,
        amount: newProject.budget,
        platformFee: (newProject.budget * 0.1).roundToDouble(),
        netAmount: (newProject.budget * 0.9).roundToDouble(),
        status: 'held_in_escrow',
        paymentMethod: 'card',
        createdAt: DateTime.now(),
      );
      await _paymentRepo.createEscrowDeposit(payment);

      // 6. Notify freelancer
      await _notificationService.notifyProposalAccepted(
        freelancerUserId: proposal.freelancerId,
        clientName: task.clientName.isNotEmpty ? task.clientName : 'Client',
        taskTitle: task.title,
        projectId: projectId,
      );

      return projectId;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Create and publish a new client project task to marketplace
  Future<String> postTask({
    required String title,
    required String description,
    required String category,
    required double budget,
    required DateTime deadline,
    String budgetType = 'fixed',
    List<String> requiredSkills = const [],
    String experienceLevel = 'Mid (3-5 yrs)',
    List<String> attachments = const [],
  }) async {
    try {
      final user = _authService.currentUser;
      final clientId = user?.uid ?? 'client_anonymous';
      final clientName = user?.displayName ?? 'Apex Solutions';

      final task = TaskModel(
        id: '',
        clientId: clientId,
        clientName: clientName,
        title: title.trim(),
        description: description.trim(),
        category: category,
        budget: budget,
        budgetType: budgetType,
        deadline: deadline,
        requiredSkills: requiredSkills,
        attachments: attachments,
        experienceLevel: experienceLevel,
        status: 'open',
        createdAt: DateTime.now(),
      );

      final docId = await _taskRepo.createTask(task);
      return docId;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Review a milestone deliverable submitted by freelancer
  Future<void> reviewMilestoneDeliverable({
    required String projectId,
    required String milestoneId,
    required String freelancerId,
    required String milestoneTitle,
    required double amount,
    required bool approved,
    String? feedback,
  }) async {
    try {
      if (approved) {
        await _milestoneRepo.approveMilestone(milestoneId);

        // Find and release escrow payment for this project
        try {
          final payments = await _paymentRepo.getPaymentsForProject(projectId);
          for (final p in payments) {
            if (p.status == 'held_in_escrow') {
              await _paymentRepo.releaseEscrowPayment(p.id);
              break;
            }
          }
        } catch (_) {}

        // Update project status to completed
        try {
          await _projectRepo.updateProjectStatus(projectId, 'completed');
        } catch (_) {}

        await _notificationService.notifyMilestoneApproved(
          freelancerUserId: freelancerId,
          milestoneTitle: milestoneTitle,
          amount: amount,
          projectId: projectId,
        );
      } else {
        await _milestoneRepo.requestMilestoneRevision(
          milestoneId,
          feedback ?? 'Revision requested by client.',
        );
        final user = _authService.currentUser;
        await _notificationService.notifyRevisionRequested(
          freelancerUserId: freelancerId,
          clientName: user?.displayName ?? 'Client',
          milestoneTitle: milestoneTitle,
          projectId: projectId,
        );
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Retrieve current client profile data
  Future<ClientModel?> getClientProfile([String? uid]) async {
    try {
      final targetUid = uid ?? currentClientId;
      if (targetUid == null) return null;
      return await _clientRepo.getClient(targetUid);
    } catch (e) {
      debugPrint('getClientProfile notice: $e');
      return null;
    }
  }

  /// Stream single project by ID
  Stream<ProjectModel?> streamProject(String projectId) {
    try {
      return _projectRepo.getProjectStream(projectId);
    } catch (e) {
      debugPrint('streamProject notice: $e');
      return const Stream.empty();
    }
  }

  /// Stream milestones for a project
  Stream<List<MilestoneModel>> streamProjectMilestones(String projectId) {
    try {
      return _milestoneRepo.streamMilestonesForProject(projectId);
    } catch (e) {
      debugPrint('streamProjectMilestones notice: $e');
      return const Stream.empty();
    }
  }

  /// Stream payments for the current client
  Stream<List<PaymentModel>> streamClientPayments([String? clientId]) {
    try {
      final uid = clientId ?? currentClientId;
      if (uid == null) return const Stream.empty();
      return _paymentRepo.streamUserPayments(uid, isClient: true);
    } catch (e) {
      debugPrint('streamClientPayments notice: $e');
      return const Stream.empty();
    }
  }

  /// Deposit funds into escrow for a milestone
  Future<String> fundMilestoneEscrow({
    required String projectId,
    required String milestoneId,
    required String freelancerId,
    required double amount,
  }) async {
    try {
      final clientId = currentClientId ?? 'client_anonymous';
      final payment = PaymentModel(
        id: '',
        projectId: projectId,
        milestoneId: milestoneId,
        clientId: clientId,
        freelancerId: freelancerId,
        amount: amount,
        platformFee: amount * 0.05,
        netAmount: amount * 0.95,
        status: 'held_in_escrow',
        paymentMethod: 'card',
        createdAt: DateTime.now(),
      );
      return await _paymentRepo.createEscrowDeposit(payment);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Release milestone escrow funds to freelancer
  Future<void> releaseMilestoneEscrow(String paymentId) async {
    try {
      await _paymentRepo.releaseEscrowPayment(paymentId);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}


