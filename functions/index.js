const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

exports.aiAgent = functions.https.onRequest(async (req, res) => {
  const {question, studentEmail} = req.body;

  if (!question) {
    return res.status(400).json({error: "Question is required"});
  }

  // STEP 1: Search internal knowledge_base
  const snapshot = await db
      .collection("knowledge_base")
      .where("verified", "==", true)
      .get();

  let matchedAnswer = null;

  snapshot.forEach((doc) => {
    const data = doc.data();
    if (question.toLowerCase().includes(data.question_intent.toLowerCase())) {
      matchedAnswer = data.answer;
    }
  });

  // STEP 2: If found → return answer
  if (matchedAnswer) {
    return res.json({
      source: "INTERNAL_DB",
      answer: matchedAnswer,
    });
  }

  // STEP 3: If not found → ESCALATE
  await db.collection("queries").add({
    question_text: question,
    studentEmail: studentEmail || "unknown",
    status: "ESC_ADMIN",
    escalation_reason: "No verified data found",
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return res.json({
    source: "ESCALATED",
    message: "Your query has been forwarded to administration.",
  });
});
