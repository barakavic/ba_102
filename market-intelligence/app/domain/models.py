from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Optional, List

"""Core enums"""

class ConfidenceLevel (str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"

class PriceTrend(str, Enum):
    UP = "UP"
    DOWN = "DOWN"
    STABLE = "STABLE"

class WaitRisk (str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"

"""core  domain objects"""
@dataclass(frozen=True)
class Product :
    """ 
     -What the user wants
      -No pricing logic """
    product_id: str
    name: str
    category: str
    imported: bool = True

@dataclass(frozen=True)
class MarketCandidate:
    """
    Raw scraped data before semantic validation.
    """
    source: str
    title: str
    url: str
    price: float
    currency: str
    is_international: bool = False
    original_price: Optional[float] = None
    snippet: Optional[str] = None

@dataclass(frozen=True)
class PriceSignal:
    """ 
    -Obserevd price from any source
    -Not definitive truth """
    product_id: str
    price: float
    currency: str
    source: str
    is_international: bool
    confidence: float
    observed_at: datetime
    ttl_hours: int
    original_price: Optional[float] = None # The "was" price, if available

    @classmethod
    def from_candidate(cls, candidate: MarketCandidate, confidence: float = 0.8):
        return cls(
            product_id=candidate.url,
            price=candidate.price,
            currency=candidate.currency,
            source=candidate.source,
            is_international=candidate.is_international,
            confidence=confidence,
            observed_at=datetime.now(),
            ttl_hours=24,
            original_price=candidate.original_price
        )

@dataclass(frozen=True)
class PriceBand:
    """ Believable range for a product price.
    """

    low: float
    medium: float
    high: float
    
@dataclass(frozen=True)
class PriceConsensus:
    """ 
    -System belief derived from many price signals
    """
    product_id: str
    band: PriceBand
    confidence: ConfidenceLevel
    trend: PriceTrend
    signals_used: int
    last_updated: datetime
    best_offer_source: str = "Unknown"
    best_offer_url: str = ""


from pydantic import BaseModel

class UserFinancialContext(BaseModel):
    """ 
    -User constraints only with no advice
    """
    liquid_balance: float
    safe_to_spend_monthly: float
    existing_commitments: float = 0.0

@dataclass(frozen=True)
class AffordabilityResult:
    """ 
    -Deterministic affordabilty output
    """
    can_buy_now: bool
    months_to_afford: Optional[int]
    monthly_saving_required: Optional[float] 

@dataclass(frozen=True)
class DecisionInsight:
    """
    Final output before narration.
    """
    product_id: str
    consensus_price: float
    affordability: AffordabilityResult
    wait_risk: WaitRisk
    confidence: ConfidenceLevel
    rationale: List[str]

