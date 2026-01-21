from app.domain.models import MarketCandidate
from app.llm import nli_gate
import logging

logger = logging.getLogger(__name__)

class MarketGate:
    """
    Semantic choke-point.
    Decides if a MarketCandidate matches the user's intent using NLI.
    """
    
    def __init__(self, threshold: float = 0.7):
        self.threshold = threshold

    def validate(self, query: str, candidate: MarketCandidate) -> bool:
        """
        Uses NLI to check if the candidate title entails the query intent.
        """
        # Premise: The product title found by the scraper
        # Hypothesis: This item is a [query]
        premise = candidate.title
        hypothesis = f"This item is a {query}"
        
        try:
            scores = nli_gate.score(premise, hypothesis)
            entailment_prob = scores.get("entailment", 0.0)
            contradiction_prob = scores.get("contradiction", 0.0)
            
            logger.info(f"NLI Validation | Query: '{query}' | Title: '{premise}' | E: {entailment_prob:.4f} | C: {contradiction_prob:.4f}")
            
            # We accept if entailment is high AND higher than contradiction
            is_valid = entailment_prob >= self.threshold and entailment_prob > contradiction_prob
            
            if not is_valid:
                logger.warning(f"REJECTED: '{premise}' does not seem to be a '{query}'")
                
            return is_valid
            
        except Exception as e:
            logger.error(f"NLI Validation failed: {e}")
            # Fallback: If ML fails, we might want to be conservative or permissive.
            # For now, let's be permissive to avoid total service failure, 
            # but log the error.
            return True 
