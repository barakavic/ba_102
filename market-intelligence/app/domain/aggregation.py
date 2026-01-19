from typing import List
from datetime import datetime
import statistics
from app.domain.models import PriceSignal, PriceConsensus, PriceBand, ConfidenceLevel, PriceTrend
from app.finance.currency import CurrencyConverter

class PriceAggregator:
    """
    Aggregates multiple PriceSignals into a single PriceConsensus.
    """

    def aggregate(self, product_id: str, signals: List[PriceSignal]) -> PriceConsensus:
        if not signals:
            raise ValueError("Cannot aggregate empty signals")

        # 1. Normalize all prices to KES
        normalized_prices = []
        for signal in signals:
            try:
                price_kes = CurrencyConverter.convert(signal.price, signal.currency, "KES")
                normalized_prices.append(price_kes)
            except ValueError:
                continue # Skip unsupported currencies

        if not normalized_prices:
             raise ValueError("No valid signals after normalization")

        # 2. Calculate Bands (Low, Medium, High)
        # Simple logic: Low = Min, High = Max, Medium = Median
        # In a real system, we'd use standard deviation to remove outliers
        low_price = min(normalized_prices)
        high_price = max(normalized_prices)
        med_price = statistics.median(normalized_prices)
        
        band = PriceBand(low=low_price, medium=med_price, high=high_price)

        # 3. Determine Confidence
        # More signals = Higher confidence
        # Tight spread = Higher confidence
        num_signals = len(signals)
        spread = (high_price - low_price) / low_price if low_price > 0 else 0
        
        confidence = ConfidenceLevel.LOW
        if num_signals >= 3 and spread < 0.2: # 3+ sources and <20% spread
            confidence = ConfidenceLevel.HIGH
        elif num_signals >= 2:
            confidence = ConfidenceLevel.MEDIUM

        # 4. Determine Trend
        # For now, we don't have historical data in this pass, so we default to STABLE
        trend = PriceTrend.STABLE

        # 5. Identify Best Offer (Lowest Price)
        # We need to find the signal that corresponds to the low_price
        best_signal = None
        for signal in signals:
            try:
                converted = CurrencyConverter.convert(signal.price, signal.currency, "KES")
                if abs(converted - low_price) < 0.01:
                    best_signal = signal
                    break
            except:
                continue

        return PriceConsensus(
            product_id=product_id,
            band=band,
            confidence=confidence,
            trend=trend,
            signals_used=num_signals,
            last_updated=datetime.now(),
            best_offer_source=best_signal.source if best_signal else "Unknown",
            best_offer_url=best_signal.product_id if best_signal else ""
        )
