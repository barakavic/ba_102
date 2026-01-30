from typing import Dict, Optional
from dataclasses import dataclass
from app.finance.currency import CurrencyConverter

@dataclass
class LandedCostProfile:
    source_name: str
    is_international: bool
    import_duty_pct: float = 0.25  # 25% Duty
    vat_pct: float = 0.16          # 16% VAT
    handling_fee_flat: float = 0.0 # Flat fee in KES
    shipping_estimate_pct: float = 0.10 # 10% for shipping

class DutyCalculator:
    """
    Calculates the true 'Landed Cost' of an item in Nairobi.
    """
    
    # Registry of retailers and their import profiles
    PROFILES = {
        "amazon": LandedCostProfile("Amazon", is_international=True),
        "jumia": LandedCostProfile("Jumia", is_international=False),
        # Default fallback
        "default_local": LandedCostProfile("Local", is_international=False),
        "default_int": LandedCostProfile("International", is_international=True)
    }

    @classmethod
    def calculate_landed_cost(cls, price: float, currency: str, source: str) -> float:
        """
        Returns the final estimated price in KES, including all taxes and duties.
        """
        # 1. Convert Base Price to KES
        base_price_kes = CurrencyConverter.convert(price, currency, "KES")
        
        # 2. Get Profile
        profile = cls.PROFILES.get(source.lower(), cls.PROFILES["default_local"])
        
        # If it's local, price is price.
        if not profile.is_international:
            return base_price_kes
            
        # 3. Apply International Landed Cost Formula
        # Cost + Shipping
        cif_value = base_price_kes * (1 + profile.shipping_estimate_pct)
        
        # Duty on CIF
        with_duty = cif_value * (1 + profile.import_duty_pct)
        
        # VAT on (CIF + Duty)
        with_vat = with_duty * (1 + profile.vat_pct)
        
        # Handling
        final_price = with_vat + profile.handling_fee_flat
        
        return round(final_price, 2)
