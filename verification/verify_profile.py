from playwright.sync_api import sync_playwright

def verify_profile_page():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        # Test Case 1: Unauthenticated User visiting Profile Page (CTA)
        page.goto("http://localhost:5173/profile")
        page.wait_for_selector(".cta-card")
        page.screenshot(path="verification/profile_cta.png")
        print("Captured CTA screenshot")

        # Test Case 2: Unauthenticated User searching and visiting a profile
        page.goto("http://localhost:5173/markets")

        # Search for a user (assuming some data exists or just check UI)
        # Note: Since we are running against a live backend/dev, data might vary.
        # But we can check if the search UI exists and we can navigate.
        # Ideally, we'd mock the response, but for now we just verify the route change.

        # Let's try to simulate clicking a user link if one appears, or just direct nav to a profile URL
        # Direct nav to a potentially non-existent user to see error or structure
        page.goto("http://localhost:5173/profile?u=nonexistent_user_12345")

        # Should show "User not found"
        try:
            page.wait_for_selector(".error-container", timeout=5000)
            page.screenshot(path="verification/profile_not_found.png")
            print("Captured Not Found screenshot")
        except:
             print("Did not find error container, maybe user exists?")
             page.screenshot(path="verification/profile_check.png")

        browser.close()

if __name__ == "__main__":
    verify_profile_page()
