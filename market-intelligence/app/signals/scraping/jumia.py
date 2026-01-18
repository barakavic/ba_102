from datetime import datetime
import re
from typing import Optional
from app.signals.base import SignalProducer
from app.signals.web_scraper import WebScraper
from app.domain.models import PriceSignal
from playwright.async_api import Page

class JumiaScraper(SignalProducer):
    def __init__(self, scraper: WebScraper):
        self.scraper = scraper
        self.source_name = "Jumia"

    async def fetch_signal(self, product_url: str) -> PriceSignal:
        """
        Scrapes a Jumia product page and returns a PriceSignal.
        """
        
        async def extract_jumia_data(page: Page):
            # Wait for network to be idle to ensure dynamic content is loaded
            try:
                await page.wait_for_load_state("networkidle", timeout=10000)
            except Exception:
                pass # Proceed anyway if timeout

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
                pass # It's okay if there's no discount
            
            return price_text, original_price_text

        try:
            raw_price, raw_old_price = await self.scraper.scrape_page(product_url, extract_jumia_data)
            
            # Clean price string: "KSh 1,299" -> 1299.0
            price_float = self._clean_price(raw_price)
            
            original_price_float = None
            if raw_old_price:
                original_price_float = self._clean_price(raw_old_price)
            
            return PriceSignal(
                product_id=product_url,
                price=price_float,
                currency="KES",
                source=self.source_name,
                confidence=0.8,
                observed_at=datetime.now(),
                ttl_hours=24,
                original_price=original_price_float
            )
        except Exception as e:
            print(f"Failed to scrape Jumia: {e}")
            raise e

    async def search_product(self, query: str) -> Optional[PriceSignal]:
        """
        Searches Jumia for a product and returns the top result's signal.
        """
        search_url = f"https://www.jumia.co.ke/catalog/?q={query.replace(' ', '+')}"
        
        async def get_first_result_url(page: Page):
            # Selector for the first product card's link in the search results
            # Jumia usually lists items in <article class="prd _fb col c-prd">
            # The link is the <a> tag inside.
            result_selector = "article.prd a.core"
            await page.wait_for_selector(result_selector, timeout=10000)
            
            # Get the href of the first result
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
                    
                print(f"Found product: {full_url}")
                return await self.fetch_signal(full_url)
            else:
                print(f"No results found for query: {query}")
                return None
                
        except Exception as e:
            print(f"Search failed: {e}")
            return None

    def _clean_price(self, price_str: str) -> float:
        if not price_str:
            return 0.0
        clean_str = re.sub(r"[^\d.]", "", price_str)
        try:
            return float(clean_str)
        except ValueError:
            return 0.0
