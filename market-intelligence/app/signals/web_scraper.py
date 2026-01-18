from playwright.async_api import async_playwright, Page, Browser
from typing import Optional, Any, Callable
import logging

logger = logging.getLogger(__name__)

class WebScraper:
    """
    A generic Playwright-based scraper that handles browser lifecycle
    and page navigation.
    """
    def __init__(self, headless: bool = True):
        self.headless = headless
        self.playwright = None
        self.browser: Optional[Browser] = None

    async def start(self):
        """Starts the Playwright engine and browser."""
        if not self.playwright:
            self.playwright = await async_playwright().start()
        if not self.browser:
            self.browser = await self.playwright.chromium.launch(headless=self.headless)

    async def stop(self):
        """Stops the browser and Playwright engine."""
        if self.browser:
            await self.browser.close()
            self.browser = None
        if self.playwright:
            await self.playwright.stop()
            self.playwright = None

    async def scrape_page(self, url: str, extract_fn: Callable[[Page], Any]) -> Any:
        """
        Navigates to a URL and applies an extraction function to the page.
        
        Args:
            url: The URL to scrape.
            extract_fn: A generic async function that takes a Playwright Page object 
                        and returns extracted data.
        
        Returns:
            The result of extract_fn.
        """
        if not self.browser:
            await self.start()
        
        page = await self.browser.new_page()
        try:
            # Set a realistic user agent to avoid bot detection
            await page.set_extra_http_headers({
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            })
            
            logger.info(f"Navigating to {url}")
            await page.goto(url, wait_until="domcontentloaded", timeout=60000)
            
            return await extract_fn(page)
        except Exception as e:
            logger.error(f"Error scraping {url}: {e}")
            raise
        finally:
            await page.close()
