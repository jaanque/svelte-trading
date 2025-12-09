from playwright.sync_api import sync_playwright

def verify_explore_page():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        # Navigate to the Explore page (formerly Markets)
        # Note: In a SPA, initial load might be to root then nav, or direct if server supports it.
        # Vite dev server usually supports direct access or fallback to index.html.
        page.goto("http://localhost:5173/markets")

        # Wait for the search bar to be visible
        page.wait_for_selector(".search-bar")

        # Type into the search bar
        search_input = page.locator("input[placeholder='Search for users...']")
        search_input.fill("test")

        # Wait a bit for potential debounce and loading state (even if no backend results)
        page.wait_for_timeout(1000)

        # Take a screenshot
        page.screenshot(path="verification/explore_page.png")

        browser.close()

if __name__ == "__main__":
    verify_explore_page()
