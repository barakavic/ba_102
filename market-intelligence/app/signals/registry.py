from typing import Dict, Type
from app.signals.base import SignalProducer
from app.signals.web_scraper import WebScraper
from app.signals.scraping.jumia import JumiaScraper
from app.signals.scraping.amazon import AmazonScraper

class ScraperRegistry:
    """
    Central registry for all supported retailer scrapers.
    """
    
    _SCRAPERS: Dict[str, Type[SignalProducer]] = {
        "jumia": JumiaScraper,
        "amazon": AmazonScraper,
        # Future retailers:
        # "kilimall": KilimallScraper,
        # "carrefour": CarrefourScraper
    }
    
    @classmethod
    def get_scraper(cls, name: str, engine: WebScraper) -> SignalProducer:
        """
        Factory method to instantiate a scraper by name.
        """
        scraper_cls = cls._SCRAPERS.get(name.lower())
        if not scraper_cls:
            raise ValueError(f"Retailer '{name}' is not supported yet.")
            
        return scraper_cls(engine)
        
    @classmethod
    def list_supported_retailers(cls):
        return list(cls._SCRAPERS.keys())
