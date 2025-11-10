/**
 * Firebase Cloud Functions for Video Call System
 * 
 * Functions:
 * 1. sendCallNotification - Gửi FCM khi có cuộc gọi mới
 * 2. cleanupOldCalls - Dọn dẹp cuộc gọi cũ (chạy mỗi ngày)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Cloud Function: Gửi FCM notification khi có cuộc gọi mới
 * Trigger: Realtime Database onCreate /calls/{callId}
 * 
 * Flow:
 * 1. Phát hiện cuộc gọi mới trong /calls
 * 2. Lấy FCM token của người nhận từ Firestore
 * 3. Gửi high-priority notification
 * 4. Log kết quả
 */
export const sendCallNotification = functions.database
  .ref("/calls/{callId}")
  .onCreate(async (snapshot: functions.database.DataSnapshot, context: functions.EventContext) => {
    try {
      const callData = snapshot.val();
      const callId = context.params.callId;

      console.log(`📞 New call detected: ${callId}`);
      console.log("Call data:", callData);

      // Validate call data
      if (!callData || callData.status !== "calling") {
        console.log("⚠️  Skipping notification - invalid status:", callData?.status);
        return null;
      }

      const receiverId = callData.receiverId;
      const callerName = callData.callerName || "Someone";
      const callerAvatar = callData.callerAvatar || "";
      const callerId = callData.callerId;

      if (!receiverId) {
        console.error("❌ No receiver ID found");
        return null;
      }

      console.log(`📞 Processing call from ${callerName} (${callerId}) to ${receiverId}`);

      // Get receiver's FCM token from Firestore
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(receiverId)
        .get();

      if (!userDoc.exists) {
        console.error(`❌ User not found: ${receiverId}`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        console.error(`❌ No FCM token for user: ${receiverId}`);
        console.log("User data:", userData);
        return null;
      }

      console.log(`✅ Found FCM token for ${receiverId}: ${fcmToken.substring(0, 20)}...`);

      // Create notification message payload
      const message = {
        token: fcmToken,
        notification: {
          title: `📞 Cuộc gọi đến từ ${callerName}`,
          body: "Nhấn để trả lời hoặc từ chối",
        },
        data: {
          type: "incoming_call",
          callId: callId,
          callerId: callerId,
          callerName: callerName,
          callerAvatar: callerAvatar,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        // Android specific options
        android: {
          priority: "high" as const,
          notification: {
            channelId: "video_call_channel",
            priority: "high" as const,
            sound: "default",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            tag: callId, // Group notifications by callId
          },
        },
        // iOS specific options
        apns: {
          headers: {
            "apns-priority": "10", // High priority
          },
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              contentAvailable: true,
              category: "CALL_CATEGORY",
            },
          },
        },
      };

      // Send FCM notification
      console.log("📤 Sending FCM notification...");
      const response = await admin.messaging().send(message);
      console.log("✅ FCM notification sent successfully:", response);

      // Optional: Log to Firestore for debugging
      await admin.firestore().collection("call_notifications").add({
        callId: callId,
        receiverId: receiverId,
        callerName: callerName,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
        messageId: response,
      });

      return response;
    } catch (error) {
      console.error("❌ Error sending FCM notification:", error);

      // Log error to Firestore
      try {
        await admin.firestore().collection("call_notifications").add({
          callId: context.params.callId,
          error: String(error),
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          success: false,
        });
      } catch (logError) {
        console.error("Failed to log error:", logError);
      }

      return null;
    }
  });

/**
 * Cloud Function: Dọn dẹp cuộc gọi cũ
 * Trigger: Scheduled function - chạy mỗi ngày lúc 2 giờ sáng
 * 
 * Purpose: Xóa các cuộc gọi cũ hơn 24 giờ để giữ database sạch
 */
export const cleanupOldCalls = functions.pubsub
  .schedule("0 2 * * *") // Chạy lúc 2:00 AM mỗi ngày
  .timeZone("Asia/Ho_Chi_Minh") // Vietnam timezone
  .onRun(async (context: functions.EventContext) => {
    console.log("🧹 Starting cleanup of old calls...");

    const db = admin.database();
    const now = Date.now();
    const oneDayAgo = now - 24 * 60 * 60 * 1000; // 24 hours ago

    try {
      const snapshot = await db.ref("/calls").once("value");
      const calls = snapshot.val();

      if (!calls) {
        console.log("ℹ️  No calls to clean up");
        return null;
      }

      const updates: { [key: string]: null } = {};
      let count = 0;

      // Find old calls
      Object.keys(calls).forEach((callId) => {
        const call = calls[callId];
        const createAt = call.createAt || 0;

        // Delete calls older than 24 hours
        if (createAt < oneDayAgo) {
          updates[`/calls/${callId}`] = null;
          count++;
          console.log(`🗑️  Marking call ${callId} for deletion (created: ${new Date(createAt).toISOString()})`);
        }
      });

      // Apply deletions
      if (count > 0) {
        await db.ref().update(updates);
        console.log(`✅ Cleaned up ${count} old calls`);

        // Log cleanup to Firestore
        await admin.firestore().collection("cleanup_logs").add({
          type: "calls",
          deletedCount: count,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        console.log("ℹ️  No old calls found to clean up");
      }

      return null;
    } catch (error) {
      console.error("❌ Error cleaning up calls:", error);
      return null;
    }
  });

/**
 * Optional: Cloud Function để update call status khi timeout
 * Trigger: Realtime Database onChange /calls/{callId}
 * 
 * Purpose: Tự động đánh dấu cuộc gọi là "timeout" nếu không được trả lời sau 30 giây
 */
export const handleCallTimeout = functions.database
  .ref("/calls/{callId}")
  .onCreate(async (snapshot: functions.database.DataSnapshot, context: functions.EventContext) => {
    const callId = context.params.callId;
    const callData = snapshot.val();

    if (callData.status !== "calling") {
      return null;
    }

    console.log(`⏰ Setting timeout for call: ${callId}`);

    // Wait 30 seconds
    await new Promise((resolve) => setTimeout(resolve, 30000));

    // Check if call is still in "calling" state
    const updatedSnapshot = await snapshot.ref.once("value");
    const updatedData = updatedSnapshot.val();

    if (updatedData && updatedData.status === "calling") {
      console.log(`⏰ Call ${callId} timed out`);
      await snapshot.ref.update({
        status: "timeout",
        endAt: admin.database.ServerValue.TIMESTAMP,
      });
    }

    return null;
  });

/**
 * Optional: HTTP Callable Function để test FCM
 * Usage: Call từ Flutter app hoặc REST API
 */
export const testFCMNotification = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const {receiverId, title, body} = data;

  if (!receiverId || !title || !body) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required fields"
    );
  }

  try {
    // Get FCM token
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(receiverId)
      .get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "User not found"
      );
    }

    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "User has no FCM token"
      );
    }

    // Send test notification
    const response = await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      android: {
        priority: "high",
      },
    });

    return {
      success: true,
      messageId: response,
    };
  } catch (error) {
    console.error("Error sending test notification:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to send notification"
    );
  }
});
