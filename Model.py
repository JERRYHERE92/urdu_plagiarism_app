import os
import joblib
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import classification_report

# from urduhack import download, initialize
from urduhack.normalization import normalize
from urduhack.tokenization import word_tokenizer
from urduhack.stop_words import STOP_WORDS

# # Download & initialize UrduHack models
# download()
# initialize()

# --- Preprocessing function ---
def preprocess_urdu(text):
    normalized = normalize(text)
    tokens = normalized.split()
    # tokens = word_tokenizer(normalized)
    filtered = [token for token in tokens if token not in STOP_WORDS]
    return " ".join(filtered)

# --- Dataset loading function ---
def load_dataset(folder_path, label):
    data = []
    for filename in os.listdir(folder_path):
        if filename.endswith(".txt"):
            file_path = os.path.join(folder_path, filename)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    text = f.read()
                    data.append((text, label))
            except Exception as e:
                print(f"Error reading {filename}: {e}")
    return data

# --- Load dataset ---
plagiarism_folder = r"D:\NOMAN BACKUP\Python\Dataset_in_urdu_language\Para_level\Plagiarized"
non_plagiarism_folder = r"D:\NOMAN BACKUP\Python\Dataset_in_urdu_language\Para_level\Non_plagiarized"


print("🔄 Loading data...")
plagiarized_data = load_dataset(plagiarism_folder, 1)
non_plagiarized_data = load_dataset(non_plagiarism_folder, 0)

all_data = plagiarized_data + non_plagiarized_data
print(f"✅ Loaded {len(all_data)} documents")

# --- Preprocess all text ---
print("🧹 Preprocessing text...")
texts = [preprocess_urdu(text) for text, label in all_data]
labels = [label for text, label in all_data]

# --- Vectorize using TF-IDF ---
print("🔠 Vectorizing text...")
vectorizer = TfidfVectorizer(max_features=5000)
X = vectorizer.fit_transform(texts)

# --- Train/Test split ---
X_train, X_test, y_train, y_test = train_test_split(X, labels, test_size=0.2, random_state=42)

# --- Train model ---
print("🧠 Training model...")
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# --- Evaluate ---
print("📊 Evaluation:")
y_pred = model.predict(X_test)
print(classification_report(y_test, y_pred))

# --- Save model & vectorizer ---
print("💾 Saving model and vectorizer...")
joblib.dump(model, "plagiarism_model.pkl")
joblib.dump(vectorizer, "tfidf_vectorizer.pkl")

print("✅ Model training complete and saved!")
