import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';
import '../models/milestone_model.dart';

/// Repository managing project milestones, deliverable submissions, and approvals.
class MilestoneRepository {
  final FirebaseFirestore? _injectedFirestore;

  MilestoneRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static final MilestoneRepository instance = MilestoneRepository();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _milestones =>
      _firestore.collection('milestones');

  /// Add a milestone to a project
  Future<String> createMilestone(MilestoneModel milestone) async {
    try {
      final docRef = await _milestones.add(milestone.toMap());
      try {
        await FirebaseConfig.instance.realtimeDb.ref('milestones/${docRef.id}').set({
          ...milestone.toMap(),
          'id': docRef.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
      return docRef.id;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Get all milestones for a project ordered by milestoneNumber
  Future<List<MilestoneModel>> getMilestonesForProject(String projectId) async {
    try {
      final snapshot = await _milestones
          .where('projectId', isEqualTo: projectId)
          .get();

      final list = snapshot.docs
          .map((doc) => MilestoneModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.milestoneNumber.compareTo(b.milestoneNumber));
      return list;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Real-time stream of project milestones
  Stream<List<MilestoneModel>> streamMilestonesForProject(String projectId) {
    return _milestones
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MilestoneModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.milestoneNumber.compareTo(b.milestoneNumber));
      return list;
    });
  }

  /// Submit milestone deliverable for client review
  Future<void> submitMilestoneDeliverable(
    String milestoneId, {
    required String note,
    required String fileName,
    required String fileUrl,
  }) async {
    try {
      await _milestones.doc(milestoneId).update({
        'status': 'submitted',
        'deliverableNote': note,
        'deliverableFileName': fileName,
        'deliverableFileUrl': fileUrl,
        'submittedAt': FieldValue.serverTimestamp(),
      });
      try {
        await FirebaseConfig.instance.realtimeDb.ref('milestones/$milestoneId').update({
          'status': 'submitted',
          'deliverableNote': note,
          'deliverableFileName': fileName,
          'deliverableFileUrl': fileUrl,
          'submittedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Client approves milestone and releases escrow funds
  Future<void> approveMilestone(String milestoneId) async {
    try {
      await _milestones.doc(milestoneId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      try {
        await FirebaseConfig.instance.realtimeDb.ref('milestones/$milestoneId').update({
          'status': 'approved',
          'approvedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Client requests revisions on milestone deliverable
  Future<void> requestMilestoneRevision(
    String milestoneId,
    String revisionNote,
  ) async {
    try {
      await _milestones.doc(milestoneId).update({
        'status': 'in_revision',
        'revisionNote': revisionNote,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      try {
        await FirebaseConfig.instance.realtimeDb.ref('milestones/$milestoneId').update({
          'status': 'in_revision',
          'revisionNote': revisionNote,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
