import os
import torch
from transformers import BertTokenizer, BertForSequenceClassification, Trainer, TrainingArguments
from datasets import Dataset
from urduhack.normalization import normalize
from urduhack.stop_words import STOP_WORDS

# --- Preprocessing ---
def preprocess_urdu(text):
    normalized = normalize(text)
    tokens = normalized.split()
    filtered = [t for t in tokens if t not in STOP_WORDS]
    return " ".join(filtered)

# --- Load Dataset ---
def load_bert_dataset(base_path):
    texts, labels = [], []
    for folder_name, label in [("Non_plagiarized", 0), ("Plagiarized", 1)]:
        folder = os.path.join(base_path, folder_name)
        for fname in os.listdir(folder):
            if fname.endswith(".txt"):
                with open(os.path.join(folder, fname), encoding="utf-8") as f:
                    content = f.read()
                    texts.append(preprocess_urdu(content))
                    labels.append(label)
    return {"text": texts, "label": labels}

# --- Tokenization ---
def tokenize(batch):
    return tokenizer(batch["text"], padding=True, truncation=True, max_length=512)

# Paths
DATASET_PATH = r"D:\NOMAN BACKUP\Python\Dataset_in_urdu_language\Para_level"

# Load dataset
data = load_bert_dataset(DATASET_PATH)
dataset = Dataset.from_dict(data)

# Tokenizer & Model
tokenizer = BertTokenizer.from_pretrained("bert-base-multilingual-cased")
dataset = dataset.map(tokenize, batched=True)
dataset = dataset.train_test_split(test_size=0.2)

model = BertForSequenceClassification.from_pretrained("bert-base-multilingual-cased", num_labels=2)

# Training args
training_args = TrainingArguments(
    output_dir="./bert_plag_model",
    # evaluation_strategy="epoch",
    logging_dir='./logs',
    per_device_train_batch_size=8,
    per_device_eval_batch_size=8,
    num_train_epochs=3,
    # save_total_limit=1,
    save_strategy="steps",          # <-- NEW
    save_steps=50,                 # <-- NEW
    save_total_limit=2    
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=dataset["train"],
    eval_dataset=dataset["test"],
    tokenizer=tokenizer
)

trainer.train(resume_from_checkpoint="bert_plag_model/checkpoint-1300")

# Save model
model.save_pretrained("bert_plag_model")
tokenizer.save_pretrained("bert_plag_model")
