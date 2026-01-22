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
        Uses a combination of keyword matching and NLI to validate candidates.
        """
        premise = candidate.title.lower()
        query_lower = query.lower()
        
        # 1. Strict Keyword Guard for Electronics
        # If query has "AI" but title doesn't, it's a mismatch
        if "ai" in query_lower and "ai" not in premise:
            logger.warning(f"KEYWORD REJECTED: Query asks for 'AI' but title '{candidate.title}' does not mention it.")
            return False
            
        # If query has "Pro" but title doesn't (common for PS5/iPhone)
        if "pro" in query_lower and "pro" not in premise:
            logger.warning(f"KEYWORD REJECTED: Query asks for 'Pro' but title '{candidate.title}' does not mention it.")
            return False

        # Prevent picking up accessories when looking for the main device
        accessories = ["case", "cover", "adapter", "cable", "skin", "sticker", "mount", "stand"]
        if any(acc in premise for acc in accessories) and not any(acc in query_lower for acc in accessories):
             logger.warning(f"KEYWORD REJECTED: Title '{candidate.title}' looks like an accessory, but query '{query}' does not.")
             return False

        # 2. NLI Validation
        hypothesis = f"This item is a {query}"
        
        try:
            scores = nli_gate.score(candidate.title, hypothesis)
            entailment_prob = scores.get("entailment", 0.0)
            contradiction_prob = scores.get("contradiction", 0.0)
            
            logger.info(f"NLI Validation | Query: '{query}' | Title: '{candidate.title}' | E: {entailment_prob:.4f} | C: {contradiction_prob:.4f}")
            
            # We accept if entailment is high AND higher than contradiction
            # Increased threshold to 0.8 for better precision
            is_valid = entailment_prob >= 0.8 and entailment_prob > contradiction_prob
            
            if not is_valid:
                logger.warning(f"REJECTED: '{candidate.title}' does not seem to be a '{query}'")
                
            return is_valid
            
        except Exception as e:
            logger.error(f"NLI Validation failed: {e}")
            # Fallback: If ML fails, we might want to be conservative or permissive.
            # For now, let's be permissive to avoid total service failure, 
            # but log the error.
            return True 
