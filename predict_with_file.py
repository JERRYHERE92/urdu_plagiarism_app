import os
import re
import torch
import docx
import pdfplumber
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

# ----------- Preprocessing -----------
def preprocess(text):
    normalized = normalize(text)
    normalized = re.sub(r'\s+', ' ', normalized).strip()
    tokens = normalized.split()
    filtered = [t for t in tokens if t not in STOP_WORDS]
    return " ".join(filtered)

# ----------- File Reader -----------
def extract_text_from_file(file_path):
    ext = os.path.splitext(file_path)[1].lower()
    if ext == ".txt":
        return open(file_path, encoding="utf-8").read().replace('\n',' ')
    if ext == ".docx":
        return " ".join(p.text for p in docx.Document(file_path).paragraphs)
    if ext == ".pdf":
        txt=""
        with pdfplumber.open(file_path) as pdf:
            for p in pdf.pages:
                if p.extract_text(): txt+=p.extract_text()+" "
        return txt.strip()
    raise ValueError("Unsupported format")

# ----------- Cosine Similarity -----------
def load_dataset_texts(base_folder):
    texts=[]
    for fld in ["Plagiarized","Non_plagiarized"]:
        for f in os.listdir(os.path.join(base_folder,fld)):
            if f.endswith(".txt"):
                texts.append(preprocess(open(os.path.join(base_folder,fld,f),encoding="utf-8").read()))
    return texts

def cosine_score(input_text, corpus):
    vec = TfidfVectorizer().fit_transform([input_text]+corpus)
    sims = cosine_similarity(vec[0:1], vec[1:]).flatten()
    return sims.max()*100

# ----------- Chunking + BERT -----------
def chunk_text(text, max_tokens=300, stride=50):
    toks = tokenizer.tokenize(text)
    chs=[]; i=0
    while i < len(toks):
        chs.append(tokenizer.convert_tokens_to_string(toks[i:i+max_tokens]))
        i += max_tokens - stride
    return chs

def bert_chunk_probs(text):
    clean = preprocess(text)
    chs = chunk_text(clean)
    probs=[]
    print("\n========== Chunk‐wise BERT Probabilities ==========")
    for i,ch in enumerate(chs,1):
        inp = tokenizer(ch, return_tensors="pt", truncation=True, padding=True, max_length=512)
        with torch.no_grad():
            logit = model(**inp).logits
        p = F.softmax(logit,dim=1)[0,1].item()*100
        probs.append(p)
        print(f"Chunk {i:02d}: {p:.2f}% plagiarized")
    avg = sum(probs)/len(probs)
    print(f"Average BERT plagiarism probability: {avg:.2f}%")
    return avg

# ----------- Main Prediction -----------
def predict_with_similarity(text, dataset_path):
    # always show cosine
    print("\n========== Cosine Similarity ==========")
    cos = cosine_score(preprocess(text), load_dataset_texts(dataset_path))
    print(f"Max cosine similarity vs dataset: {cos:.2f}%")

    # always show chunks
    avg_bert = bert_chunk_probs(text)

    # override logic
    print("\n========== Final Decision ==========")
    if cos < 30:
        print("🔍 Final Verdict: ✅ Original (Cosine similarity < 30%)")
    else:
        if avg_bert > 70:
            print("🔍 Final Verdict: ❌ Likely Plagiarized")
        elif avg_bert < 30:
            print("🔍 Final Verdict: ✅ Original")
        else:
            print("🔍 Final Verdict: ⚠️ Manual Review Suggested")

# ----------- Run Script -----------
if __name__=="__main__":
    fp = input("📥 Enter file path (.txt/.docx/.pdf): ")
    dp = r"D:\NOMAN BACKUP\Python\Dataset\Para_level"
    try:
        txt = extract_text_from_file(fp)
        print("\n========== Extracted Text ==========\n", txt, "\n")
        print("🔄 Starting checks...")
        predict_with_similarity(txt, dp)
    except Exception as e:
        print("❌ Error:", e)

