from datetime import datetime
import re
from typing import Optional
from app.signals.base import SignalProducer
from app.signals.web_scraper import WebScraper
from app.domain.models import MarketCandidate
from playwright.async_api import Page

import logging

logger = logging.getLogger(__name__)

class JumiaScraper(SignalProducer):
    def __init__(self, scraper: WebScraper):
        self.scraper = scraper
        self.source_name = "Jumia"

    async def fetch_candidate(self, product_url: str) -> MarketCandidate:
        """
        Scrapes a Jumia product page and returns a MarketCandidate.
        """
        
        async def extract_jumia_data(page: Page):
            # Wait for network to be idle to ensure dynamic content is loaded
            try:
                await page.wait_for_load_state("networkidle", timeout=20000)
            except Exception:
                pass # Proceed anyway if timeout

            # Get Title
            title = ""
            try:
                title_selector = "h1"
                title = await page.inner_text(title_selector)
            except Exception:
                pass

            # Try multiple price selectors
            price_text = ""
            selectors = [".prc", "span.-b.-ltr.-tal.-fs24", "div.df.-i-ctr.-j-bet span"]
            
            for selector in selectors:
                try:
                    if await page.query_selector(selector):
                        price_text = await page.inner_text(selector)
                        if price_text:
                            break
                except Exception:
                    continue
            
            # Fallback: Look for text containing "KSh"
            if not price_text:
                try:
                    element = page.get_by_text("KSh").first
                    if element:
                        price_text = await element.text_content()
                except Exception:
                    pass
            
            # Original price (strikethrough) selector - often ".old"
            original_price_text = None
            try:
                old_price_selector = ".old"
                if await page.query_selector(old_price_selector):
                    original_price_text = await page.inner_text(old_price_selector)
            except Exception:
                pass 
            
            return title, price_text, original_price_text

        try:
            title, raw_price, raw_old_price = await self.scraper.scrape_page(product_url, extract_jumia_data)
            
            # Clean price string: "KSh 1,299" -> 1299.0
            price_float = self._clean_price(raw_price)
            
            original_price_float = None
            if raw_old_price:
                original_price_float = self._clean_price(raw_old_price)
            
            return MarketCandidate(
                source=self.source_name,
                title=title,
                url=product_url,
                price=price_float,
                currency="KES",
                original_price=original_price_float
            )
        except Exception as e:
            logger.error(f"Failed to scrape Jumia: {e}")
            raise e

    async def search_product(self, query: str) -> Optional[MarketCandidate]:
        """
        Searches Jumia for a product and returns the top result's candidate.
        """
        search_url = f"https://www.jumia.co.ke/catalog/?q={query.replace(' ', '+')}"
        
        async def get_first_result_url(page: Page):
            result_selector = "article.prd a.core"
            await page.wait_for_selector(result_selector, timeout=20000)
            
            first_result = await page.query_selector(result_selector)
            if first_result:
                return await first_result.get_attribute("href")
            return None

        try:
            relative_url = await self.scraper.scrape_page(search_url, get_first_result_url)
            
            if relative_url:
                if not relative_url.startswith("http"):
                    full_url = f"https://www.jumia.co.ke{relative_url}"
                else:
                    full_url = relative_url
                    
                logger.info(f"Found product on Jumia: {full_url}")
                return await self.fetch_candidate(full_url)
            else:
                logger.warning(f"No results found on Jumia for query: {query}")
                return None
                
        except Exception as e:
            logger.error(f"Jumia Search failed: {e}")
            return None

    def _clean_price(self, price_str: str) -> float:
        if not price_str:
            return 0.0
        clean_str = re.sub(r"[^\d.]", "", price_str)
        try:
            return float(clean_str)
        except ValueError:
            return 0.0
