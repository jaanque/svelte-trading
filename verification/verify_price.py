from playwright.sync_api import sync_playwright, expect

def verify_price_on_profile():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        # Intercept the Supabase request for profile
        page.route("**/rest/v1/profiles*", lambda route: route.fulfill(
            status=200,
            content_type="application/json",
            body='{"id": "123", "username": "testuser", "full_name": "Test User", "avatar_url": "", "tokens": 250, "price": 100}'
        ))

        page.goto("http://localhost:5173/profile?u=testuser")

        try:
            page.wait_for_selector(".profile-info-container", timeout=5000)
        except:
            print("Profile container did not appear.")
            browser.close()
            return

        # Check for Price label
        price_label = page.get_by_text("Price")
        expect(price_label).to_be_visible()

        # We need to target the specific link in the stats section, not the nav bar
        # The locator "a[href='/portfolio']" is finding both the sidebar nav link and our new link.
        # We added class "stat-link" to our new link.
        link = page.locator(".stat-link[href='/portfolio']")

        expect(link).to_be_visible()
        expect(link).to_contain_text("100")

        page.screenshot(path="verification/profile_price_link.png")
        print("Captured Profile Price Link screenshot")

        browser.close()

if __name__ == "__main__":
    verify_price_on_profile()
