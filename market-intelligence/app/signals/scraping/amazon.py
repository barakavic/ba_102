from datetime import datetime
import re
from typing import Optional, Tuple
from app.signals.base import SignalProducer
from app.signals.web_scraper import WebScraper
from app.domain.models import PriceSignal
from playwright.async_api import Page

class AmazonScraper(SignalProducer):
    def __init__(self, scraper: WebScraper):
        self.scraper = scraper
        self.source_name = "Amazon"

    async def fetch_signal(self, product_url: str) -> PriceSignal:
        """
        Scrapes an Amazon product page and returns a PriceSignal.
        """
        
        async def extract_amazon_data(page: Page) -> Tuple[str, Optional[str]]:
            # Amazon often has captchas, but Playwright headless sometimes passes.
            # If we hit a captcha, we might get no price.
            
            # Price selectors
            # 1. The standard price block
            # 2. The "Apex" price (often used in search results or main detail page)
            price_text = ""
            
            # Strategy: Look for the 'offscreen' price which is cleaner
            try:
                # Wait for the main price element. 
                # .a-price .a-offscreen is usually the best bet.
                price_selector = ".a-price .a-offscreen"
                # We use a short timeout because if it's not there, it might be a different layout
                try:
                    await page.wait_for_selector(price_selector, timeout=5000)
                    # Get the first one, which is usually the main price
                    price_text = await page.locator(price_selector).first.inner_text()
                except Exception:
                    # Fallback: try #priceblock_ourprice or #priceblock_dealprice
                    if await page.query_selector("#priceblock_ourprice"):
                        price_text = await page.inner_text("#priceblock_ourprice")
                    elif await page.query_selector("#priceblock_dealprice"):
                        price_text = await page.inner_text("#priceblock_dealprice")
                    elif await page.query_selector(".apexPriceToPay .a-offscreen"):
                        price_text = await page.inner_text(".apexPriceToPay .a-offscreen")
            except Exception:
                pass

            # Original Price (for discounts)
            # Usually in span.a-price.a-text-price span.a-offscreen
            original_price_text = None
            try:
                old_price_selector = "span.a-price.a-text-price span.a-offscreen"
                if await page.query_selector(old_price_selector):
                    original_price_text = await page.locator(old_price_selector).first.inner_text()
            except Exception:
                pass
            
            return price_text, original_price_text

        try:
            raw_price, raw_old_price = await self.scraper.scrape_page(product_url, extract_amazon_data)
            
            price_float = self._clean_price(raw_price)
            
            original_price_float = None
            if raw_old_price:
                original_price_float = self._clean_price(raw_old_price)
            
            # If we failed to get a price, it might be out of stock or captcha
            if price_float == 0.0:
                print(f"Warning: Could not extract price from {product_url}")
            
            # Detect currency
            currency = "USD" # Default
            if "KSh" in raw_price or "KES" in raw_price:
                currency = "KES"
            elif "€" in raw_price:
                currency = "EUR"
            elif "£" in raw_price:
                currency = "GBP"
            
            return PriceSignal(
                product_id=product_url,
                price=price_float,
                currency=currency,
                source=self.source_name,
                confidence=0.9,
                observed_at=datetime.now(),
                ttl_hours=24,
                original_price=original_price_float
            )
        except Exception as e:
            print(f"Failed to scrape Amazon: {e}")
            raise e

    async def search_product(self, query: str) -> Optional[PriceSignal]:
        """
        Searches Amazon for a product and returns the top result's signal.
        """
        search_url = f"https://www.amazon.com/s?k={query.replace(' ', '+')}"
        
        async def get_first_result_url(page: Page):
            # Debug: Print page title to check for captcha
            title = await page.title()
            print(f"Amazon Page Title: {title}")
            
            # Wait for results to load
            try:
                await page.wait_for_selector("div.s-main-slot", timeout=5000)
            except:
                pass

            # Strategy: Find any link containing "/dp/" inside the main search results slot
            # This avoids ads (usually) and sidebars if we scope it to s-main-slot
            try:
                # Get all links in the main slot
                links = await page.locator("div.s-main-slot a").all()
                for link in links:
                    href = await link.get_attribute("href")
                    # Check if it's a product link and not a sponsored link (sometimes sponsored links have weird redirects, but usually /dp/ is safe)
                    if href and "/dp/" in href and "slredirect" not in href:
                        return href
            except Exception as e:
                print(f"Error finding link: {e}")
                return None
            
            return None

        try:
            relative_url = await self.scraper.scrape_page(search_url, get_first_result_url)
            
            if relative_url:
                if not relative_url.startswith("http"):
                    full_url = f"https://www.amazon.com{relative_url}"
                else:
                    full_url = relative_url
                    
                print(f"Found product: {full_url}")
                return await self.fetch_signal(full_url)
            else:
                print(f"No results found on Amazon for query: {query}")
                return None
                
        except Exception as e:
            print(f"Amazon Search failed: {e}")
            return None

    def _clean_price(self, price_str: str) -> float:
        if not price_str:
            return 0.0
        # Remove currency symbols ($) and commas
        # Amazon US uses dot for decimals
        clean_str = re.sub(r"[^\d.]", "", price_str)
        try:
            return float(clean_str)
        except ValueError:
            return 0.0
