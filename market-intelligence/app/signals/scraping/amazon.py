from datetime import datetime
import re
from typing import Optional, Tuple
from app.signals.base import SignalProducer
from app.signals.web_scraper import WebScraper
from app.domain.models import MarketCandidate
from playwright.async_api import Page

import logging

logger = logging.getLogger(__name__)

class AmazonScraper(SignalProducer):
    def __init__(self, scraper: WebScraper):
        self.scraper = scraper
        self.source_name = "Amazon"

    async def fetch_candidate(self, product_url: str) -> MarketCandidate:
        """
        Scrapes an Amazon product page and returns a MarketCandidate.
        """
        
        async def extract_amazon_data(page: Page) -> Tuple[str, str, Optional[str]]:
            # Get Title
            title = ""
            try:
                title_selector = "#productTitle"
                title = await page.inner_text(title_selector)
            except Exception:
                pass

            # Price selectors
            price_text = ""
            try:
                price_selector = ".a-price .a-offscreen"
                try:
                    await page.wait_for_selector(price_selector, timeout=5000)
                    price_text = await page.locator(price_selector).first.inner_text()
                except Exception:
                    if await page.query_selector("#priceblock_ourprice"):
                        price_text = await page.inner_text("#priceblock_ourprice")
                    elif await page.query_selector("#priceblock_dealprice"):
                        price_text = await page.inner_text("#priceblock_dealprice")
                    elif await page.query_selector(".apexPriceToPay .a-offscreen"):
                        price_text = await page.inner_text(".apexPriceToPay .a-offscreen")
            except Exception:
                pass

            # Original Price
            original_price_text = None
            try:
                old_price_selector = "span.a-price.a-text-price span.a-offscreen"
                if await page.query_selector(old_price_selector):
                    original_price_text = await page.locator(old_price_selector).first.inner_text()
            except Exception:
                pass
            
            return title.strip(), price_text, original_price_text

        try:
            title, raw_price, raw_old_price = await self.scraper.scrape_page(product_url, extract_amazon_data)
            
            price_float = self._clean_price(raw_price)
            original_price_float = None
            if raw_old_price:
                original_price_float = self._clean_price(raw_old_price)
            
            # Detect currency
            currency = "USD" # Default
            if "KSh" in raw_price or "KES" in raw_price:
                currency = "KES"
            elif "€" in raw_price:
                currency = "EUR"
            elif "£" in raw_price:
                currency = "GBP"
            
            return MarketCandidate(
                source=self.source_name,
                title=title,
                url=product_url,
                price=price_float,
                currency=currency,
                original_price=original_price_float
            )
        except Exception as e:
            logger.error(f"Failed to scrape Amazon: {e}")
            raise e

    async def search_product(self, query: str) -> Optional[MarketCandidate]:
        """
        Searches Amazon for a product and returns the top result's candidate.
        """
        search_url = f"https://www.amazon.com/s?k={query.replace(' ', '+')}"
        
        async def get_first_result_url(page: Page):
            title = await page.title()
            logger.info(f"Amazon Search Page Title: {title}")
            
            try:
                await page.wait_for_selector("div.s-main-slot", timeout=5000)
            except:
                pass

            try:
                links = await page.locator("div.s-main-slot a").all()
                for link in links:
                    href = await link.get_attribute("href")
                    if href and "/dp/" in href and "slredirect" not in href:
                        return href
            except Exception as e:
                logger.error(f"Error finding link on Amazon: {e}")
                return None
            
            return None

        try:
            relative_url = await self.scraper.scrape_page(search_url, get_first_result_url)
            
            if relative_url:
                if not relative_url.startswith("http"):
                    full_url = f"https://www.amazon.com{relative_url}"
                else:
                    full_url = relative_url
                    
                logger.info(f"Found product on Amazon: {full_url}")
                return await self.fetch_candidate(full_url)
            else:
                logger.warning(f"No results found on Amazon for query: {query}")
                return None
                
        except Exception as e:
            logger.error(f"Amazon Search failed: {e}")
            return None

    def _clean_price(self, price_str: str) -> float:
        if not price_str:
            return 0.0
        clean_str = re.sub(r"[^\d.]", "", price_str)
        try:
            return float(clean_str)
        except ValueError:
            return 0.0
