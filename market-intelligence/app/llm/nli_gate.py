from typing import Dict
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification

MODEL_NAME= "typeform/distilbert-base-uncased-mnli"

_tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
_model = AutoModelForSequenceClassification.from_pretrained(MODEL_NAME)
_model.eval()

_LABELS= ["entailment", "neutral", "contradiction"]

def score(premise: str, hypothesis:str) ->Dict[str,float]:
    """
    Compute the NLI entailment Probabilities (premises, hypothesis) pair.

    Returns a Dict with keys:
    - "entailment"
    - "neutral"
    - "contradiction"

    """
    inputs = _tokenizer(
        premise, 
        hypothesis,
        return_tensors = "pt",
        truncation=True,
        max_length=512,
        )
    with torch.no_grad():
        outputs= _model(**inputs)
        logits = outputs.logits
    
    probs = torch.softmax(logits, dim=1).squeeze().tolist()

    return{
        label: float(prob)
        for label, prob in zip(_LABELS, probs)
    }