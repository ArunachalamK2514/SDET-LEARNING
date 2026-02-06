# Playwright Core Features: Handling Multiple Pages Within a Single Context

## Overview
In web automation, it's common to encounter scenarios where interacting with a single web application requires managing multiple browser tabs or pop-up windows. Playwright provides robust capabilities to handle these multi-page interactions efficiently within the same browser context. This feature is crucial for testing workflows that involve opening new links in a new tab, handling authentication pop-ups, or navigating through various parts of an application that spawn new windows. Understanding how to switch between pages, wait for new pages to appear, and interact with elements across different pages is fundamental for comprehensive test automation.

## Detailed Explanation
Playwright's `BrowserContext` acts as an isolated browsing session, and within this context, you can open multiple `Page` instances. Each `Page` object represents a single tab or window. When a new tab or pop-up is opened by an action on the current page, Playwright does not automatically switch focus to it. You need to explicitly wait for the new page event and then switch your interaction to the new `Page` object.

The key methods and concepts involved are:

*   **`browser.newPage()` or `context.newPage()`**: Creates a new blank page within the browser or browser context. This is useful for starting new, independent flows.
*   **`page.click()` with `target='_blank'` links**: When clicking a link that opens in a new tab (e.g., `<a href="..." target="_blank">`), Playwright allows you to wait for this new page to emerge.
*   **`context.waitForEvent('page')`**: This is the primary mechanism to listen for new page openings within a specific browser context. It returns the new `Page` object as soon as it's created. This method is asynchronous and should be awaited.
*   **`page.bringToFront()`**: If you need to make a specific page the active one in the browser window (useful for visual debugging or certain interaction patterns), this method brings it into focus.
*   **`page.close()`**: Closes a specific page.
*   **`context.pages()`**: Returns an array of all active `Page` objects within the browser context, allowing you to iterate or find specific pages.

The general workflow for handling a new page/popup is:
1.  Initiate an action on the current page that is expected to open a new tab/window.
2.  Concurrently, set up a listener to wait for the `'page'` event on the `browserContext` *before* the action that triggers the new page. This is crucial to avoid race conditions.
3.  Once the new page is detected, get a reference to its `Page` object.
4.  Perform interactions on the new page.
5.  Optionally, switch back to the original page or close the new page.

## Code Implementation

This TypeScript example demonstrates handling a click that opens a new tab and interacting with both the original and the new page.

```typescript
import { test, expect, Browser, BrowserContext, Page } from '@playwright/test';

test.describe('Multi-page handling within a single context', () => {
    let browser: Browser;
    let context: BrowserContext;
    let originalPage: Page;

    test.beforeAll(async ({ playwright }) => {
        // Launch a new browser instance
        browser = await playwright.chromium.launch();
    });

    test.beforeEach(async () => {
        // Create a new browser context for each test for isolation
        context = await browser.newContext();
        originalPage = await context.newPage();
        await originalPage.goto('https://www.google.com'); // Navigate to a base URL
    });

    test.afterEach(async () => {
        // Close the context after each test
        await context.close();
    });

    test.afterAll(async () => {
        // Close the browser after all tests are done
        await browser.close();
    });

    test('should handle a new tab opened by a click event', async () => {
        // Step 1: Create an action that opens a new tab.
        // For demonstration, let's create a temporary link that opens a new tab.
        // In a real scenario, this would be an existing element on the page.
        await originalPage.evaluate(() => {
            const link = document.createElement('a');
            link.href = 'https://playwright.dev/';
            link.target = '_blank';
            link.textContent = 'Open Playwright in new tab';
            link.id = 'new-tab-link';
            document.body.appendChild(link);
        });

        // Step 2 & 3: Concurrently wait for the new page and click the link.
        // It's crucial to set up the 'waitForEvent' BEFORE triggering the event.
        const [newPage] = await Promise.all([
            context.waitForEvent('page'), // This waits for a new page to be created in the context
            originalPage.click('#new-tab-link') // This action opens the new tab
        ]);

        await newPage.waitForLoadState(); // Wait for the new page to fully load

        // Step 4: Interact with elements on the new page.
        expect(newPage.url()).toContain('playwright.dev');
        await newPage.locator('text=Docs').first().click(); // Click on 'Docs' link
        expect(newPage.url()).toContain('/docs/');
        console.log(`Navigated to: ${newPage.url()}`);

        // Step 5: Bring original page to front and interact with it again (optional).
        await originalPage.bringToFront();
        await originalPage.fill('textarea[name="q"]', 'Playwright new tab');
        await originalPage.press('textarea[name="q"]', 'Enter');
        await originalPage.waitForLoadState();
        expect(originalPage.url()).toContain('search?q=Playwright');
        console.log(`Original page URL after interaction: ${originalPage.url()}`);

        // Ensure both pages are still open and accessible
        const allPages = context.pages();
        expect(allPages.length).toBe(2);
        expect(allPages).toContain(originalPage);
        expect(allPages).toContain(newPage);

        await newPage.close(); // Close the new tab
        expect(context.pages().length).toBe(1); // Verify only original page is left
    });

    test('should handle a new popup window', async () => {
        await originalPage.goto('https://www.w3schools.com/jsref/tryit.asp?filename=tryjsref_win_open');
        await originalPage.frameLocator('#iframeResult').getByRole('button', { name: 'Try it' }).click();

        // Wait for the popup page
        const [popupPage] = await Promise.all([
            context.waitForEvent('page'),
            originalPage.frameLocator('#iframeResult').getByRole('button', { name: 'Try it' }).click() // Re-click for popup
        ]);
        await popupPage.waitForLoadState();

        expect(popupPage.url()).not.toBeNull(); // The popup opens about:blank initially, then navigates
        console.log(`Popup page URL: ${popupPage.url()}`);
        await expect(popupPage.locator('body')).toContainText('Hello World!'); // Interact with the popup content
        await popupPage.close();
    });
});
```

## Best Practices
-   **Always `await context.waitForEvent('page')` concurrently**: To prevent race conditions, always use `Promise.all([context.waitForEvent('page'), page.click(...)])` or similar patterns. This ensures Playwright is listening for the new page *before* the action that triggers it.
-   **Use meaningful selectors**: Ensure your selectors are robust and target the correct elements on both the original and new pages.
-   **Wait for load state**: After opening a new page, always await `newPage.waitForLoadState()` (e.g., `'domcontentloaded'`, `'load'`, `'networkidle'`) to ensure the page content is fully loaded before attempting to interact with it.
-   **Manage contexts for isolation**: For test suites, create a new `BrowserContext` for each test or a group of related tests to ensure complete isolation and prevent test interference.
-   **Close pages/contexts**: Explicitly close pages (`page.close()`) and contexts (`context.close()`) when they are no longer needed to free up resources, especially in large test suites.

## Common Pitfalls
-   **Race conditions**: Not awaiting `context.waitForEvent('page')` *before* the action that triggers the new page. The event might fire and be missed if the listener isn't active in time.
-   **Incorrect context**: Accidentally trying to find a new page in the wrong `BrowserContext` if multiple contexts are open. Ensure you are calling `waitForEvent('page')` on the correct `context` object where the new page is expected to open.
-   **Assuming new page focus**: Playwright does not automatically switch your `Page` object reference. You must capture the new `Page` object from `waitForEvent` and use it for subsequent interactions on that new tab/window.
-   **Slow loading pages**: Not waiting for the new page's `loadState` can lead to tests failing because elements are not yet present or interactive.

## Interview Questions & Answers
1.  **Q: How do you handle a scenario where clicking a button opens a new tab in Playwright?**
    A: The most robust way is to use `Promise.all` to concurrently wait for the `'page'` event on the `BrowserContext` while performing the click action. For example: `const [newPage] = await Promise.all([context.waitForEvent('page'), originalPage.click('selector')]);`. After getting the `newPage` object, I would then use `newPage.waitForLoadState()` to ensure the content is loaded before interacting with it.
2.  **Q: What is the significance of `BrowserContext` when dealing with multiple pages?**
    A: `BrowserContext` provides an isolated browsing session. All pages created within a single context share cookies, local storage, and session storage. When handling multiple pages, using `context.waitForEvent('page')` ensures you are listening for new pages specifically within that isolated session, preventing interference from other contexts and maintaining a clear scope for your automation.
3.  **Q: How do you switch focus between the original page and a newly opened page in Playwright?**
    A: Playwright doesn't have an explicit "switch to tab" command like some other frameworks. Instead, you directly interact with the `Page` object references you hold. Once you obtain the `newPage` object (e.g., from `context.waitForEvent('page')`), you use `newPage` for interactions on the new tab. To interact with the original page again, you simply use its `originalPage` object reference. You can optionally use `newPage.bringToFront()` or `originalPage.bringToFront()` to visually bring a specific tab into focus if needed for debugging or specific UI testing.
4.  **Q: Describe a common pitfall when handling new pages and how to avoid it.**
    A: A common pitfall is a race condition where the action that opens a new page happens before Playwright starts listening for the new page event. This leads to the test failing because the event is missed. This can be avoided by always using `Promise.all` to ensure the `context.waitForEvent('page')` listener is active *before* the UI action that triggers the new page.

## Hands-on Exercise
**Scenario**: You need to test a search result page where clicking on a search result opens the corresponding website in a new tab.

1.  Navigate to `https://www.bing.com`.
2.  Search for "Playwright multiple tabs".
3.  Identify a search result link that is likely to open in a new tab (e.g., by inspecting its `target="_blank"` attribute, or just pick the first relevant link).
4.  Write a Playwright test that:
    *   Navigates to Bing.
    *   Enters the search query.
    *   Clicks on a search result link that opens in a new tab.
    *   Verifies the URL of the new tab contains expected content (e.g., "playwright").
    *   Interacts with an element on the new tab.
    *   Closes the new tab.
    *   Verifies that the original Bing search results page is still accessible.

## Additional Resources
-   **Playwright Documentation - Pages**: [https://playwright.dev/docs/pages](https://playwright.dev/docs/pages)
-   **Playwright Documentation - BrowserContexts**: [https://playwright.dev/docs/api/class-browsercontext#browser-context-wait-for-event](https://playwright.dev/docs/api/class-browsercontext#browser-context-wait-for-event)
-   **Playwright Docs - Handling popups**: [https://playwright.dev/docs/events#handling-popups](https://playwright.dev/docs/events#handling-popups)