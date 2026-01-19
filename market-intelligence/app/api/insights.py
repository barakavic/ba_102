from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional
from app.domain.models import UserFinancialContext, DecisionInsight
from app.domain.aggregation import PriceAggregator
from app.domain.decisions import DecisionEngine
from app.signals.web_scraper import WebScraper
from app.signals.scraping.jumia import JumiaScraper
from app.signals.scraping.amazon import AmazonScraper
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

# Request Models
class AnalyzeRequest(BaseModel):
    product_name: str
    user_context: UserFinancialContext

# Response Model (re-using domain model or creating a DTO if needed)
# For now, we return the DecisionInsight directly as it's a dataclass, 
# but Pydantic can handle dataclasses if configured, or we can wrap it.
# Let's create a Pydantic wrapper for clarity in docs.

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

@router.post("/analyze", response_model=DecisionResponse)
async def analyze_product(request: AnalyzeRequest):
    """
    Orchestrates the full 'Mini-CFO' flow:
    1. Scrapes market data (Jumia, Amazon)
    2. Aggregates prices
    3. Evaluates affordability against user context
    4. Returns a decision
    """
    logger.info(f"Analyzing product: {request.product_name}")
    
    # 1. Scrape Data (In parallel)
    # Note: In a real prod app, we might want to offload this to a worker queue (Celery/Redis)
    # because scraping takes time (5-10s). For now, we await it directly.
    scraper_engine = WebScraper(headless=True)
    jumia = JumiaScraper(scraper_engine)
    amazon = AmazonScraper(scraper_engine)
    
    signals = []
    try:
        # Search both sources
        # We could use asyncio.gather here for true parallelism
        import asyncio
        
        # Define tasks
        task_jumia = jumia.search_product(request.product_name)
        task_amazon = amazon.search_product(request.product_name)
        
        # Run in parallel
        results = await asyncio.gather(task_jumia, task_amazon, return_exceptions=True)
        
        for res in results:
            if isinstance(res, Exception):
                logger.error(f"Scraping error: {res}")
            elif res:
                signals.append(res)
                
    finally:
        await scraper_engine.stop()
        
    if not signals:
        raise HTTPException(status_code=404, detail="Could not find product data on any supported retailer.")

    # 2. Aggregate
    aggregator = PriceAggregator()
    try:
        consensus = aggregator.aggregate(request.product_name, signals)
    except ValueError as e:
         raise HTTPException(status_code=500, detail=f"Aggregation failed: {str(e)}")

    # 3. Decide
    engine = DecisionEngine()
    # Convert Pydantic model to Domain Dataclass
    # The request.user_context is already a Pydantic model that matches the structure, 
    # but our domain expects the dataclass. 
    # Actually, Pydantic models and Dataclasses are similar but not identical.
    # Let's map it explicitly to be safe.
    
    domain_context = UserFinancialContext(
        liquid_balance=request.user_context.liquid_balance,
        safe_to_spend_monthly=request.user_context.safe_to_spend_monthly,
        existing_commitments=request.user_context.existing_commitments
    )
    
    decision = engine.evaluate(consensus, domain_context)

    # 4. Return Response
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
        rationale=decision.rationale
    )
