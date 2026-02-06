# Playwright Fixtures: `page`, `context`, and `browser`

## Overview
Playwright fixtures are a powerful mechanism for providing isolated, reusable, and configurable environments for your tests. They are at the core of Playwright's test runner, allowing you to define setup and teardown logic that runs before and after tests or groups of tests. This document focuses on the fundamental built-in fixtures: `page`, `context`, and `browser`, explaining their purpose, how to use them, and the underlying dependency injection mechanism.

Understanding and effectively utilizing these fixtures is crucial for writing robust, efficient, and maintainable Playwright tests. They streamline common testing patterns, reduce boilerplate, and ensure test isolation.

## Detailed Explanation

Playwright's test runner employs a sophisticated dependency injection system to manage test fixtures. When you declare a fixture in your test function's arguments (e.g., `test('my test', async ({ page }) => { ... })`), the test runner automatically provides an instance of that fixture. This system ensures that each test gets a fresh, isolated environment by default.

### `page` Fixture
The `page` fixture represents a single browser tab or window. It's the most commonly used fixture, providing methods to interact with web pages, such as navigating, clicking elements, filling forms, and asserting content. Each test typically receives a new `page` instance, ensuring that tests don't interfere with each other's browser state (cookies, local storage, navigated URLs, etc.).

**Key Uses:**
*   Navigating to URLs (`page.goto()`).
*   Interacting with UI elements (`page.click()`, `page.fill()`, `page.locator()`).
*   Taking screenshots (`page.screenshot()`).
*   Evaluating JavaScript in the browser context (`page.evaluate()`).

### `context` Fixture
The `context` fixture represents a browser context, which is an isolated incognito-like browsing session. A single `browser` can have multiple `context`s, and each `context` can have multiple `page`s. The `context` allows you to manage settings that apply across multiple pages within that session, such as permissions, cookies, or extra HTTP headers.

**Key Uses:**
*   Setting permissions (e.g., geolocation, camera, microphone).
*   Managing cookies and local storage for a group of pages.
*   Emulating specific device conditions or locales.
*   Opening multiple pages within the same isolated session.

### `browser` Fixture
The `browser` fixture represents an entire browser instance (e.g., Chromium, Firefox, WebKit). It's the highest level fixture provided by default. While `page` and `context` are usually sufficient for most tests, the `browser` fixture is useful for tasks that require control over the browser itself, such as inspecting its type or creating new browser contexts.

**Key Uses:**
*   Checking the type of browser being used (`browser.browserType().name()`).
*   Creating new browser contexts (`browser.newContext()`) with specific configurations that might differ from the default test `context`.

### Dependency Injection Mechanism
Playwright's test runner utilizes a dependency injection pattern. When you define a test function like `test('example', async ({ page, browser }) => { ... })`, the runner inspects the function signature. For each fixture declared in the arguments (e.g., `page`, `browser`), it resolves and provides an instance of that fixture. This means you only request the fixtures you need, and Playwright handles their creation, setup, and teardown automatically. This mechanism promotes modularity, reusability, and test isolation.

## Code Implementation

Let's illustrate the usage of these fixtures with examples.

```typescript
import { test, expect, Browser, BrowserContext, Page } from '@playwright/test';

// Use { page } fixture in test arguments
test('should navigate to Google and verify title', async ({ page }: { page: Page }) => {
  await page.goto('https://www.google.com');
  await expect(page).toHaveTitle(/Google/);
  console.log(`Test executed with page URL: ${page.url()}`);
});

// Use { browser } fixture to inspect browser type
test('should identify the browser type', async ({ browser }: { browser: Browser }) => {
  const browserName = browser.browserType().name();
  console.log(`Running test on browser: ${browserName}`);
  expect(['chromium', 'firefox', 'webkit']).toContain(browserName);

  // You can also create a new context from the browser fixture, though usually not needed in a test
  const newContext = await browser.newContext();
  const newPage = await newContext.newPage();
  await newPage.goto('https://playwright.dev/');
  console.log(`New page opened in a fresh context: ${newPage.url()}`);
  await newPage.close();
  await newContext.close();
});

// Use { context } fixture to modify permissions
test('should deny geolocation permission', async ({ context }: { context: BrowserContext }) => {
  // Set permissions for the context before navigating
  await context.grantPermissions(['geolocation'], { origins: ['https://www.google.com'] });
  await context.setGeolocation({ latitude: 34.052235, longitude: -118.243683 }); // Los Angeles coordinates

  // Navigate to a page that requests geolocation
  const page = await context.newPage();
  await page.goto('https://www.google.com/maps'); // A page that might request location

  // Playwright automatically grants the permission set on the context
  // To verify, you might need to interact with a specific element that shows location
  // For demonstration, let's just assert the page loaded without immediate errors related to permission.
  await expect(page).toHaveURL(/maps/);

  // Example of revoking permission (if needed within the same test)
  await context.clearPermissions();
  console.log('Geolocation permission granted and then cleared.');
});

// Another example using context for authentication state
test('should set authentication state via context', async ({ context, page }) => {
  // Simulate a logged-in state by setting a cookie or local storage item on the context
  await context.addCookies([{
    name: 'session_id',
    value: 'mock_session_token_123',
    domain: 'example.com',
    path: '/',
    expires: -1
  }]);

  // Now, any page created within this context (including the default `page` fixture)
  // will have this cookie.
  await page.goto('http://example.com'); // Replace with a real site that uses session_id
  const cookies = await context.cookies();
  const sessionIdCookie = cookies.find(cookie => cookie.name === 'session_id');
  expect(sessionIdCookie).toBeDefined();
  expect(sessionIdCookie?.value).toBe('mock_session_token_123');
  console.log('Authentication state (session_id cookie) set via context.');
});
```

## Best Practices
- **Prioritize `page`:** For most web interactions, the `page` fixture is all you need. Start with it and only use `context` or `browser` when their specific functionalities are required.
- **Fixture Scoping:** Playwright fixtures have scopes (`test`, `worker`, `project`). By default, `page`, `context`, and `browser` are configured with appropriate scopes by the test runner to ensure isolation and efficiency. Understand fixture scoping for custom fixtures to optimize test execution.
- **Test Isolation:** Rely on the default isolation provided by `page` and `context` fixtures. Avoid sharing state directly between tests.
- **Descriptive Tests:** Name your tests clearly, describing what each test verifies.
- **Avoid Over-reliance on `browser`:** Seldom will you directly need the `browser` fixture. Creating new contexts or pages directly from `browser` within a test might bypass some of Playwright's default test isolation mechanisms, so use it judiciously.

## Common Pitfalls
- **Forgetting `await`:** Playwright operations are asynchronous. Forgetting `await` before methods like `page.goto()` or `expect()` will lead to flaky tests or unexpected behavior.
- **Interfering Tests:** If tests fail intermittently or affect each other, it's often due to shared state. Ensure you're leveraging fixture isolation correctly. The default `page` and `context` fixtures are designed to prevent this by providing a fresh state for each test.
- **Incorrect Context Configuration:** Applying permissions or other context-level settings *after* a page has navigated will not apply retroactively. Ensure `context` configurations are done before navigating the `page`.
- **Hardcoding Delays:** Using `page.waitForTimeout()` instead of explicit waiting mechanisms (`page.waitForSelector()`, `expect().toBeVisible()`) leads to slow and brittle tests.

## Interview Questions & Answers

1.  **Q: Explain Playwright's fixture mechanism and its benefits.**
    **A:** Playwright's fixture mechanism provides a way to set up and tear down test environments. Fixtures are declared as parameters in test functions (e.g., `{ page }`). The test runner automatically detects these and provides the necessary objects.
    **Benefits:**
    *   **Test Isolation:** Each test gets a fresh, isolated instance of fixtures like `page` and `context` by default, preventing tests from affecting each other.
    *   **Reusability:** Common setup logic (e.g., launching a browser, creating a page) is encapsulated in fixtures, reducing code duplication.
    *   **Dependency Injection:** Testers only declare the dependencies they need, and Playwright handles their provision.
    *   **Configurability:** Fixtures can be configured globally or per project, allowing for flexible test environments (e.g., different screen sizes, locales, permissions).

2.  **Q: When would you use the `context` fixture instead of just the `page` fixture? Provide an example.**
    **A:** You would use the `context` fixture when you need to manage browser-level settings that apply to multiple pages within an isolated session, or when you need to control permissions, cookies, or authentication state for a group of tests or pages.
    **Example:** Setting geolocation permissions for a series of tests that verify location-based features, or setting authentication cookies once for a set of tests within the same logged-in session, rather than logging in on every `page` instance.

3.  **Q: What is the primary difference between `browser` and `context` fixtures in Playwright?**
    **A:** The `browser` fixture represents an entire browser instance (e.g., a running Chromium process). You can launch new browser contexts from it. The `context` fixture represents an isolated, incognito-like browsing session within a browser. It maintains its own cookies, local storage, and permissions, completely isolated from other contexts or pages in other contexts. A `browser` can contain multiple `context`s, and each `context` can contain multiple `page`s. Most tests operate at the `page` or `context` level.

## Hands-on Exercise

**Objective:** Write a test that performs the following actions:
1.  Navigate to `https://www.bing.com`.
2.  Use the `context` fixture to set a specific locale (e.g., `en-GB`) for the test.
3.  Assert that the page title contains "Bing" in the specified locale.
4.  Use the `page` fixture to search for "Playwright".
5.  Use the `browser` fixture to log the name of the browser currently executing the test.

```typescript
// Exercise solution structure (fill in the blanks):
import { test, expect, Browser, BrowserContext, Page } from '@playwright/test';

test('Bing search with custom locale and browser inspection', async ({ page, context, browser }) => {
  // 1. Set locale for the context
  // Hint: context.setExtraHTTPHeaders or context.addInitScript can be useful for locale emulation,
  // or you can configure `use` in playwright.config.ts for global locale.
  // For this exercise, let's assume we're setting up a more direct way if the site responds to headers.
  // More robust locale testing often involves setting it in the playwright.config.ts or by using context.setLocale().
  // For a simple demo, we can just ensure headers are set if the site would respect it.
  await context.setExtraHTTPHeaders({ 'Accept-Language': 'en-GB' });

  // 2. Navigate to Bing
  await page.goto('https://www.bing.com');

  // 3. Assert title contains "Bing"
  await expect(page).toHaveTitle(/Bing/);

  // 4. Search for "Playwright"
  await page.fill('textarea[name="q"]', 'Playwright'); // Locate the search input field
  await page.press('textarea[name="q"]', 'Enter'); // Press Enter to submit the search

  // 5. Assert search results page
  await page.waitForURL(/search\?q=Playwright/);
  await expect(page).toHaveTitle(/Playwright - Search/); // Verify title for search results

  // 6. Log browser name using browser fixture
  const browserName = browser.browserType().name();
  console.log(`Exercise completed on browser: ${browserName}`);
});
```

## Additional Resources
-   **Playwright Test Fixtures:** [https://playwright.dev/docs/test-fixtures](https://playwright.dev/docs/test-fixtures)
-   **Playwright BrowserContext:** [https://playwright.dev/docs/api/class-browsercontext](https://playwright.dev/docs/api/class-browsercontext)
-   **Playwright Page:** [https://playwright.dev/docs/api/class-page](https://playwright.dev/docs/api/class-page)
-   **Playwright `test` function:** [https://playwright.dev/docs/api/class-test#test-function](https://playwright.dev/docs/api/class-test#test-function)
