from abc import ABC, abstractmethod
from app.domain.models import MarketCandidate
from typing import Optional

class SignalProducer(ABC):
    @abstractmethod
    async def fetch_candidate(self, product_id: str) -> MarketCandidate:
        """
        Fetches a market candidate for a given product ID (or URL).
        Returns a MarketCandidate object.
        """
        pass

    @abstractmethod
    async def search_product(self, query: str) -> Optional[MarketCandidate]:
        """
        Searches for a product by name and returns the best matching MarketCandidate.
        Returns None if no product is found.
        """
        pass
