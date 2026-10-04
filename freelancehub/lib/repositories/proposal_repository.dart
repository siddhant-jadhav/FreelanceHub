import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';
import '../models/proposal_model.dart';
import 'task_repository.dart';

/// Repository managing proposal creation, submission, and status transitions.
class ProposalRepository {
  final FirebaseFirestore? _injectedFirestore;
  final TaskRepository? _injectedTaskRepository;

  ProposalRepository({
    FirebaseFirestore? firestore,
    TaskRepository? taskRepository,
  })  : _injectedFirestore = firestore,
        _injectedTaskRepository = taskRepository;

  static final ProposalRepository instance = ProposalRepository();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;
  TaskRepository get _taskRepository =>
      _injectedTaskRepository ?? TaskRepository.instance;

  CollectionReference<Map<String, dynamic>> get _proposals =>
      _firestore.collection('proposals');

  /// Submit proposal & increment task offers count atomically
  Future<String> submitProposal(ProposalModel proposal) async {
    try {
      final docRef = await _proposals.add(proposal.toMap());
      await _taskRepository.incrementOffersCount(proposal.taskId);
      return docRef.id;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Get single proposal by ID
  Future<ProposalModel?> getProposal(String proposalId) async {
    try {
      final doc = await _proposals.doc(proposalId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ProposalModel.fromFirestore(doc);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Get all proposals for a specific task
  Future<List<ProposalModel>> getProposalsForTask(String taskId) async {
    try {
      final snapshot = await _proposals
          .where('taskId', isEqualTo: taskId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProposalModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Real-time stream of proposals for a specific task
  Stream<List<ProposalModel>> streamProposalsForTask(String taskId) {
    return _proposals
        .where('taskId', isEqualTo: taskId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProposalModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream proposals submitted by a specific freelancer
  Stream<List<ProposalModel>> streamFreelancerProposals(String freelancerId) {
    return _proposals
        .where('freelancerId', isEqualTo: freelancerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProposalModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Update proposal status ('pending', 'accepted', 'rejected', 'withdrawn')
  Future<void> updateProposalStatus(String proposalId, String status) async {
    try {
      await _proposals.doc(proposalId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Toggle shortlist status of a proposal
  Future<void> toggleProposalShortlist(String proposalId, bool isShortlisted) async {
    try {
      await _proposals.doc(proposalId).update({
        'isShortlisted': isShortlisted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
