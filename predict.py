import joblib
from urduhack.normalization import normalize
from urduhack.stop_words import STOP_WORDS

# NOTE: We're using basic split for safe tokenization
def preprocess_urdu(text):
    normalized = normalize(text)
    tokens = normalized.split()
    filtered = [token for token in tokens if token not in STOP_WORDS]
    return " ".join(filtered)

# --- Load trained model & vectorizer ---
model = joblib.load("plagiarism_model.pkl")
vectorizer = joblib.load("tfidf_vectorizer.pkl")

# --- Get input from user ---
print("🔍 Urdu Text Prediction Mode 🔍")
user_input = input("\n✍️  Urdu text dalo check karne ke liye:\n\n")

# --- Preprocess & Vectorize ---
processed = preprocess_urdu(user_input)
vectorized_input = vectorizer.transform([processed])

# --- Predict ---
prediction = model.predict(vectorized_input)[0]
confidence = model.predict_proba(vectorized_input)[0][prediction]

# --- Show Result ---
print("\n📊 Prediction Result:")
if prediction == 1:
    if confidence > 0.85:
        print("⚠️ Highly Plagiarized")
    else:
        print("⚠️ Possibly Plagiarized, Review Advised")
else:
    if confidence > 0.85:
        print("✅ Clean Text")
    else:
        print("✅ Looks Original, but Low Confidence – Manual Review Suggested")

