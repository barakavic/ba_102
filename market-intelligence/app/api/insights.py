from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional
from app.domain.models import UserFinancialContext, DecisionInsight, PriceSignal
from app.domain.aggregation import PriceAggregator
from app.domain.decisions import DecisionEngine
from app.domain.market_gate import MarketGate
from app.signals.web_scraper import WebScraper
from app.signals.scraping.jumia import JumiaScraper
from app.signals.scraping.amazon import AmazonScraper
import logging
import asyncio

router = APIRouter()
logger = logging.getLogger(__name__)

# Request Models
class AnalyzeRequest(BaseModel):
    product_name: str
    user_context: UserFinancialContext

class AffordabilityDTO(BaseModel):
    can_buy_now: bool
    months_to_afford: int
    monthly_saving_required: float

class DecisionResponse(BaseModel):
    product_id: str
    consensus_price: float
    currency: str = "KES"
    affordability: AffordabilityDTO
    wait_risk: str
    confidence: str
    rationale: List[str]
    best_offer_source: str
    best_offer_url: str

@router.post("/analyze", response_model=DecisionResponse)
async def analyze_product(request: AnalyzeRequest):
    """
    Orchestrates the full 'Mini-CFO' flow:
    1. Scrapes market data (Jumia, Amazon) -> Candidates
    2. Validates candidates through MarketGate (NLI) -> PriceSignals
    3. Aggregates prices
    4. Evaluates affordability against user context
    5. Returns a decision
    """
    logger.info(f"Analyzing product: {request.product_name}")
    
    # 1. Scrape Candidates
    scraper_engine = WebScraper(headless=True)
    jumia = JumiaScraper(scraper_engine)
    amazon = AmazonScraper(scraper_engine)
    
    candidates = []
    try:
        task_jumia = jumia.search_product(request.product_name)
        task_amazon = amazon.search_product(request.product_name)
        
        results = await asyncio.gather(task_jumia, task_amazon, return_exceptions=True)
        
        for res in results:
            if isinstance(res, Exception):
                logger.error(f"Scraping error: {res}")
            elif res:
                candidates.append(res)
                
    finally:
        await scraper_engine.stop()
        
    if not candidates:
        raise HTTPException(status_code=404, detail="Could not find product data on any supported retailer.")

    # 2. Validate through MarketGate (Semantic Choke-point)
    gate = MarketGate(threshold=0.7)
    signals = []
    
    for candidate in candidates:
        if gate.validate(request.product_name, candidate):
            # If valid, convert to PriceSignal
            signals.append(PriceSignal.from_candidate(candidate))
        else:
            logger.warning(f"MarketGate rejected candidate from {candidate.source}: {candidate.title}")

    if not signals:
        raise HTTPException(
            status_code=404, 
            detail=f"Found results for '{request.product_name}', but none matched the semantic requirements (e.g., they might be accessories)."
        )

    # 3. Aggregate
    aggregator = PriceAggregator()
    try:
        consensus = aggregator.aggregate(request.product_name, signals)
    except ValueError as e:
         raise HTTPException(status_code=500, detail=f"Aggregation failed: {str(e)}")

    # 4. Decide
    engine = DecisionEngine()
    domain_context = UserFinancialContext(
        liquid_balance=request.user_context.liquid_balance,
        safe_to_spend_monthly=request.user_context.safe_to_spend_monthly,
        existing_commitments=request.user_context.existing_commitments
    )
    
    decision = engine.evaluate(consensus, domain_context)

    # 5. Return Response
    return DecisionResponse(
        product_id=decision.product_id,
        consensus_price=decision.consensus_price,
        currency="KES",
        affordability=AffordabilityDTO(
            can_buy_now=decision.affordability.can_buy_now,
            months_to_afford=decision.affordability.months_to_afford or 0,
            monthly_saving_required=decision.affordability.monthly_saving_required or 0.0
        ),
        wait_risk=decision.wait_risk.value,
        confidence=decision.confidence.value,
        rationale=decision.rationale,
        best_offer_source=consensus.best_offer_source,
        best_offer_url=consensus.best_offer_url
    )
