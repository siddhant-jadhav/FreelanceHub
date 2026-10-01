/// Order and Delivery data models for FreelanceHub.
enum OrderStatus {
  inProgress,
  inRevision,
  delivered,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.inRevision:
        return 'In Revision';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderRequirementFile {
  final String fileName;
  final String fileSize;
  final String fileType; // 'pdf', 'image', 'zip', 'figma'

  const OrderRequirementFile({
    required this.fileName,
    required this.fileSize,
    required this.fileType,
  });
}

class OrderTimelineEvent {
  final String title;
  final String time;
  final String? description;
  final bool isClientMessage;
  final String? senderName;

  const OrderTimelineEvent({
    required this.title,
    required this.time,
    this.description,
    this.isClientMessage = false,
    this.senderName,
  });
}

class FreelanceOrder {
  final String id; // e.g. "FH-9821"
  final String clientName;
  final String clientCompany;
  final String clientCountry;
  final bool isClientVerified;
  final double clientRating;
  final String gigTitle;
  final String gigTier;
  final double budget;
  final DateTime dueDate;
  final DateTime startedDate;
  final int totalDays;
  final double progressPercent; // 0.0 - 1.0 (e.g. 0.72)
  final String clientBrief;
  final List<OrderRequirementFile> briefFiles;
  final List<OrderTimelineEvent> timeline;
  String? deliveredFileName;
  String? deliveredFileSize;
  String? deliveryNote;
  bool hasWatermark;
  OrderStatus status;

  FreelanceOrder({
    required this.id,
    required this.clientName,
    required this.clientCompany,
    this.clientCountry = 'United States',
    this.isClientVerified = true,
    this.clientRating = 5.0,
    required this.gigTitle,
    required this.gigTier,
    required this.budget,
    required this.dueDate,
    required this.startedDate,
    this.totalDays = 5,
    this.progressPercent = 0.72,
    required this.clientBrief,
    required this.briefFiles,
    required this.timeline,
    this.deliveredFileName,
    this.deliveredFileSize,
    this.deliveryNote,
    this.hasWatermark = true,
    this.status = OrderStatus.inProgress,
  });
}
