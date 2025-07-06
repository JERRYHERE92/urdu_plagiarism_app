import os
import torch
from transformers import BertTokenizer, BertForSequenceClassification
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from urduhack.normalization import normalize
from urduhack.stop_words import STOP_WORDS
import torch.nn.functional as F

# ----------- Load Trained Model -----------
model_path = "bert_plag_model"
tokenizer = BertTokenizer.from_pretrained(model_path)
model = BertForSequenceClassification.from_pretrained(model_path)
model.eval()

# ----------- Preprocessing Function -----------
def preprocess(text):
    normalized = normalize(text)
    tokens = normalized.split()
    filtered = [t for t in tokens if t not in STOP_WORDS]
    return " ".join(filtered)

# ----------- Cosine Similarity Check -----------
def load_dataset_texts(base_folder):
    texts = []
    for folder in ["Plagiarized", "Non_plagiarized"]:
        path = os.path.join(base_folder, folder)
        for file in os.listdir(path):
            if file.endswith(".txt"):
                with open(os.path.join(path, file), encoding="utf-8") as f:
                    content = f.read()
                    texts.append(preprocess(content))
    return texts

def check_cosine_similarity(input_text, all_texts):
    vectorizer = TfidfVectorizer()
    vectors = vectorizer.fit_transform([input_text] + all_texts)
    cosine_scores = cosine_similarity(vectors[0:1], vectors[1:]).flatten()
    max_sim = cosine_scores.max()
    return max_sim * 100  # percentage

# ----------- Prediction Function -----------
def predict_with_similarity(input_text, dataset_path):
    processed = preprocess(input_text)

    # --- BERT Prediction ---
    inputs = tokenizer(processed, return_tensors="pt", truncation=True, padding=True, max_length=512)
    with torch.no_grad():
        outputs = model(**inputs)
        probs = F.softmax(outputs.logits, dim=1)
        confidence, pred_class = torch.max(probs, dim=1)

    label = "❌ Plagiarized" if pred_class.item() == 1 else "✅ Original"
    conf = confidence.item() * 100

    # --- Cosine Similarity ---
    print("🔄 Checking cosine similarity...")
    dataset_texts = load_dataset_texts(dataset_path)
    cosine_conf = check_cosine_similarity(processed, dataset_texts)

    # --- Final Result ---
    final = f"📊 BERT: {label} (Confidence: {conf:.2f}%)\n📎 Cosine Similarity: {cosine_conf:.2f}%"

    # Decision logic
    if pred_class.item() == 1 or cosine_conf > 70:
        final += "\n🔍 Final Verdict: ❌ Likely Plagiarized"
    elif cosine_conf < 30 and pred_class.item() == 0:
        final += "\n✅ Final Verdict: Original"
    else:
        final += "\n⚠️ Final Verdict: Manual Review Suggested"

    return final

# ----------- Run Script -----------
if __name__ == "__main__":
    user_input = input("📥 Enter Urdu text: ")
    dataset_path = r"D:\NOMAN BACKUP\Python\Dataset\Para_level"
    result = predict_with_similarity(user_input, dataset_path)
    print(result)
