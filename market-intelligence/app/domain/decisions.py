from typing import List
from app.domain.models import PriceConsensus, UserFinancialContext, DecisionInsight, AffordabilityResult, WaitRisk, ConfidenceLevel

class DecisionEngine:
    """
    The 'Mini-CFO' brain. 
    Combines Market Intelligence (PriceConsensus) with User Context to give advice.
    """

    def evaluate(self, consensus: PriceConsensus, user_context: UserFinancialContext) -> DecisionInsight:
        
        # 1. Affordability Check
        # Can I buy it right now without going broke?
        price_to_pay = consensus.band.medium # Assume we pay the median price
        disposable_income = user_context.liquid_balance - user_context.existing_commitments
        
        can_buy_now = disposable_income >= price_to_pay
        
        months_to_afford = 0
        monthly_saving_required = 0.0
        
        if not can_buy_now:
            shortfall = price_to_pay - disposable_income
            if user_context.safe_to_spend_monthly > 0:
                months_to_afford = int((shortfall / user_context.safe_to_spend_monthly) + 1)
                monthly_saving_required = shortfall / months_to_afford
            else:
                months_to_afford = 999 # Indefinite
        
        affordability = AffordabilityResult(
            can_buy_now=can_buy_now,
            months_to_afford=months_to_afford if not can_buy_now else 0,
            monthly_saving_required=monthly_saving_required if not can_buy_now else 0.0
        )

        # 2. Wait Risk Assessment
        # Should I wait?
        # If confidence is LOW, waiting is risky (price might be wrong).
        # If trend is UP, waiting is risky (price increasing).
        wait_risk = WaitRisk.LOW
        rationale = []

        if consensus.confidence == ConfidenceLevel.LOW:
            wait_risk = WaitRisk.HIGH
            rationale.append("Market data is sparse; prices might be volatile.")
        
        # 3. Construct Rationale
        if can_buy_now:
            rationale.append(f"You can afford this item ({price_to_pay:,.0f} KES).")
            rationale.append(f"You have {disposable_income:,.0f} KES available.")
        else:
            rationale.append(f"You cannot afford this yet. Shortfall: {price_to_pay - disposable_income:,.0f} KES.")
            if months_to_afford < 999:
                rationale.append(f"Save {monthly_saving_required:,.0f} KES for {months_to_afford} months.")

        return DecisionInsight(
            product_id=consensus.product_id,
            consensus_price=price_to_pay,
            affordability=affordability,
            wait_risk=wait_risk,
            confidence=consensus.confidence,
            rationale=rationale
        )
