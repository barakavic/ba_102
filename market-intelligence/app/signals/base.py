from abc import ABC, abstractmethod
from app.domain.models import PriceSignal
from typing import Optional

class SignalProducer(ABC):
    @abstractmethod
    async def fetch_signal(self, product_id: str) -> PriceSignal:
        """
        Fetches a price signal for a given product ID (or URL).
        Returns a PriceSignal object.
        """
        pass

    @abstractmethod
    async def search_product(self, query: str) -> Optional[PriceSignal]:
        """
        Searches for a product by name and returns the best matching PriceSignal.
        Returns None if no product is found.
        """
        pass
