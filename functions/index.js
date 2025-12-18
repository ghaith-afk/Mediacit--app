const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// ✅ Add user (Auth + Firestore)
exports.adminAddUser = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in.",
    );
  }

  // Only allow admins (custom claim 'admin' = true)
  if (!context.auth.token || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can perform this action.",
    );
  }

  const {email, password, displayName, role, suspended} = data;

  if (!email || !password || !displayName) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields",
    );
  }

  // Create user in Firebase Auth
  const userRecord = await admin.auth().createUser({
    email,
    password,
    displayName,
  });

  // Save in Firestore
  const userData = {
    uid: userRecord.uid,
    email,
    displayName,
    role: role || "user",
    suspended: suspended || false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection("users").doc(userRecord.uid).set(userData);

  return {message: "User created", uid: userRecord.uid};
});

// ✅ Update user (Auth + Firestore)
exports.adminUpdateUser = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can perform this action.",
    );
  }

  const {uid, email, password, displayName, role, suspended} = data;
  if (!uid) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing UID",
    );
  }

  // Update Auth
  const updateAuth = {};
  if (email) updateAuth.email = email;
  if (password) updateAuth.password = password;
  if (displayName) updateAuth.displayName = displayName;

  if (Object.keys(updateAuth).length > 0) {
    await admin.auth().updateUser(uid, updateAuth);
  }

  // Update Firestore
  const updateFirestore = {};
  if (displayName) updateFirestore.displayName = displayName;
  if (email) updateFirestore.email = email;
  if (role) updateFirestore.role = role;
  if (typeof suspended === "boolean") updateFirestore.suspended = suspended;

  if (Object.keys(updateFirestore).length > 0) {
    await db.collection("users").doc(uid).update(updateFirestore);
  }

  return {message: "User updated", uid};
});

// ✅ Delete user (Auth + Firestore)
exports.adminDeleteUser = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can perform this action.",
    );
  }

  const {uid} = data;
  if (!uid) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing UID",
    );
  }

  // Delete from Auth and Firestore
  await admin.auth().deleteUser(uid);
  await db.collection("users").doc(uid).delete();

  return {message: "User deleted", uid};
});
