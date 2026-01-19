from typing import Dict

class CurrencyConverter:
    """
    Handles currency conversion.
    Currently uses static rates, but designed to be swapped for a live API later.
    """
    
    # Static rates for now (Base: KES)
    # TODO: Connect to a live forex API
    RATES = {
        "KES": 1.0,
        "USD": 160.0,  # Example rate
        "EUR": 175.0,
        "GBP": 200.0
    }

    @classmethod
    def convert(cls, amount: float, from_currency: str, to_currency: str = "KES") -> float:
        """
        Converts an amount from one currency to another.
        """
        if from_currency == to_currency:
            return amount
            
        # Convert to Base (KES) first
        rate_to_base = cls.RATES.get(from_currency.upper())
        if not rate_to_base:
            raise ValueError(f"Unsupported currency: {from_currency}")
            
        amount_in_base = amount * rate_to_base
        
        # Convert from Base to Target
        rate_from_base = cls.RATES.get(to_currency.upper())
        if not rate_from_base:
            raise ValueError(f"Unsupported currency: {to_currency}")
            
        return amount_in_base / rate_from_base
