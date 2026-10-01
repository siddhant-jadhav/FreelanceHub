const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Trigger: When a notification document is written, dispatch an FCM push notification.
 */
exports.sendPushNotificationOnNewNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const userId = data.userId;

    if (!userId) return null;

    try {
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) return null;

      const fcmTokens = userDoc.data().fcmTokens || [];
      if (fcmTokens.length === 0) return null;

      const payload = {
        notification: {
          title: data.title || "FreelanceHub Update",
          body: data.message || "",
        },
        data: {
          type: data.type || "general",
          referenceId: data.referenceId || "",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      const response = await admin.messaging().sendEachForMulticast({
        tokens: fcmTokens,
        notification: payload.notification,
        data: payload.data,
      });

      // Cleanup stale/invalid FCM tokens
      const tokensToRemove = [];
      response.responses.forEach((res, index) => {
        if (!res.success) {
          const errorCode = res.error ? res.error.code : "";
          if (
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/registration-token-not-registered"
          ) {
            tokensToRemove.push(fcmTokens[index]);
          }
        }
      });

      if (tokensToRemove.length > 0) {
        await db.collection("users").doc(userId).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
        });
      }

      return null;
    } catch (error) {
      console.error("Error sending push notification:", error);
      return null;
    }
  });

/**
 * Trigger: When a proposal is created, automatically notify the client and increment offer count.
 */
exports.onProposalCreated = functions.firestore
  .document("proposals/{proposalId}")
  .onCreate(async (snap, context) => {
    const proposal = snap.data();
    const taskId = proposal.taskId;
    const clientId = proposal.clientId;

    if (!clientId) return null;

    // Create in-app notification for client
    await db.collection("notifications").add({
      userId: clientId,
      type: "new_proposal",
      title: "New Custom Offer Received",
      message: `${proposal.freelancerName || "A freelancer"} submitted a proposal for "${proposal.taskTitle || "your task"}".`,
      referenceId: taskId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Increment task offer count atomically
    if (taskId) {
      await db.collection("tasks").doc(taskId).update({
        offersCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return null;
  });

/**
 * Trigger: When a review is posted, compute verified aggregate rating for the freelancer.
 */
exports.updateFreelancerStatsOnReview = functions.firestore
  .document("reviews/{reviewId}")
  .onCreate(async (snap, context) => {
    const review = snap.data();
    const freelancerId = review.freelancerId;

    if (!freelancerId) return null;

    const freelancerRef = db.collection("freelancers").doc(freelancerId);

    return db.runTransaction(async (transaction) => {
      const doc = await transaction.get(freelancerRef);
      if (!doc.exists) return;

      const data = doc.data();
      const currentReviews = data.reviewsCount || 0;
      const currentRating = data.rating || 5.0;

      const newReviews = currentReviews + 1;
      const newRating = Number(
        (((currentRating * currentReviews) + review.rating) / newReviews).toFixed(2)
      );

      transaction.update(freelancerRef, {
        reviewsCount: newReviews,
        rating: newRating,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  });

/**
 * Callable: Trusted server-side milestone release and escrow payout.
 */
exports.releaseMilestoneEscrow = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication required."
    );
  }

  const { milestoneId, projectId } = data;
  if (!milestoneId || !projectId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing milestoneId or projectId."
    );
  }

  const projectDoc = await db.collection("projects").doc(projectId).get();
  if (!projectDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Project not found.");
  }

  const project = projectDoc.data();
  // Only the project client can authorize escrow release
  if (project.clientId !== context.auth.uid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only the hiring client can release escrow funds."
    );
  }

  const milestoneRef = db.collection("milestones").doc(milestoneId);
  const milestoneDoc = await milestoneRef.get();
  if (!milestoneDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Milestone not found.");
  }

  const milestone = milestoneDoc.data();

  // Atomically update milestone, payment record, and client spend
  const batch = db.batch();

  batch.update(milestoneRef, {
    status: "released",
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Query and update matching escrow payment record
  const paymentQuery = await db.collection("payments")
    .where("projectId", "==", projectId)
    .where("milestoneId", "==", milestoneId)
    .limit(1)
    .get();

  if (!paymentQuery.empty) {
    const paymentDoc = paymentQuery.docs[0];
    batch.update(paymentDoc.ref, {
      status: "released",
      releasedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  // Record client spend
  batch.update(db.collection("clients").doc(project.clientId), {
    totalSpent: admin.firestore.FieldValue.increment(milestone.amount || 0),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Create notification for freelancer
  const notifRef = db.collection("notifications").doc();
  batch.set(notifRef, {
    userId: project.freelancerId,
    type: "payment_released",
    title: "Escrow Funds Released! 💸",
    message: `$${(milestone.amount || 0).toFixed(2)} has been released for milestone "${milestone.title}".`,
    referenceId: projectId,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  return { success: true, releasedAmount: milestone.amount };
});
