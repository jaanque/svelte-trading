from playwright.sync_api import sync_playwright, expect

def verify_portfolio_graph():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        # Intercept and mock responses
        page.route("**/rest/v1/profiles*", lambda route: route.fulfill(
            status=200,
            content_type="application/json",
            body='{"id": "123", "username": "testuser", "full_name": "Test User", "avatar_url": "", "tokens": 250, "price": 100}'
        ))

        # Mock empty price history to test fallback
        page.route("**/rest/v1/price_history*", lambda route: route.fulfill(
             status=200,
             content_type="application/json",
             body='[]'
        ))

        page.goto("http://localhost:5173/portfolio")

        # Wait for chart canvas
        try:
             page.wait_for_selector(".chart-wrapper canvas", timeout=5000)
        except:
             print("Chart canvas not found")
             browser.close()
             return

        # Check if the header shows current value
        value_text = page.locator(".current-value").inner_text()
        print(f"Current Value displayed: {value_text}")

        # Take a screenshot to verify visual appearance of chart
        page.screenshot(path="verification/portfolio_chart_fallback.png")
        print("Captured Portfolio Chart Fallback screenshot")

        browser.close()

if __name__ == "__main__":
    verify_portfolio_graph()
