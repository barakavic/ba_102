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

        # 1. Normalize all prices to KES "Landed Cost"
        # This handles the Amazon vs Jumia mismatch
        # Import DutyCalculator here to avoid circular imports if any
        from app.finance.duty_calculator import DutyCalculator

        valid_prices = []
        signal_map = {} # Map price -> signal for easy lookup

        for signal in signals:
            try:
                landed_cost = DutyCalculator.calculate_landed_cost(
                    price=signal.price, 
                    currency=signal.currency, 
                    source=signal.source
                )
                valid_prices.append(landed_cost)
                signal_map[landed_cost] = signal
            except ValueError:
                continue

        if not valid_prices:
             raise ValueError("No valid signals after normalization")

        # 2. Outlier Detection (The "Accessory" Filter)
        # Calculate Median First
        median_price = statistics.median(valid_prices)
        
        # Define Sanity Bounds (0.5x to 2.5x of Median)
        # e.g., if Median is 100k, ignore < 50k (likely case) and > 250k (likely bulk)
        lower_bound = median_price * 0.5
        upper_bound = median_price * 2.5
        
        filtered_prices = [p for p in valid_prices if lower_bound <= p <= upper_bound]
        
        # If aggressive filtering killed everything, fallback to original set
        # (This happens if we only have wildly different prices)
        if not filtered_prices:
            filtered_prices = valid_prices
            
        # 3. Calculate Bands from Filtered Data
        low_price = min(filtered_prices)
        high_price = max(filtered_prices)
        med_price = statistics.median(filtered_prices)
        
        band = PriceBand(low=low_price, medium=med_price, high=high_price)

        # 4. Determine Confidence
        num_signals = len(filtered_prices)
        # Spread calculation
        spread = (high_price - low_price) / low_price if low_price > 0 else 0
        
        confidence = ConfidenceLevel.LOW
        if num_signals >= 3 and spread < 0.25: 
            confidence = ConfidenceLevel.HIGH
        elif num_signals >= 2 and spread < 0.4:
            confidence = ConfidenceLevel.MEDIUM

         # 5. Determine Trend (Placeholder)
        trend = PriceTrend.STABLE

        # 6. Identify Best Offer (Lowest Valid Price)
        # We find the signal close to our 'low_price'
        best_signal = None
        closest_diff = float('inf')
        
        for price, signal in signal_map.items():
            diff = abs(price - low_price)
            if diff < closest_diff:
                closest_diff = diff
                best_signal = signal
            
            # small optimization: exact match
            if diff < 0.01:
                break

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
