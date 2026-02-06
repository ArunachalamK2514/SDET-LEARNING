# Playwright: Multiple Browser Contexts for Test Isolation

## Overview
In Playwright, a browser context is an isolated environment within a browser instance. It's akin to an "incognito" or "private" browsing session. Each context operates independently, meaning cookies, local storage, sessions, and other browser states are not shared between them. This isolation is crucial for robust test automation, especially when dealing with scenarios requiring different user roles, separate login states, or parallel execution where test data must not leak.

This feature focuses on demonstrating how to leverage multiple browser contexts to achieve complete test isolation, ensuring that tests remain reliable and free from side effects caused by previous or concurrently running tests.

## Detailed Explanation
Playwright's `Browser` object can create multiple `BrowserContext` instances. Each `BrowserContext` can then launch multiple `Page` objects. The key takeaway is that data (like cookies, local storage, and user sessions) is isolated at the `BrowserContext` level.

When you launch a browser using `playwright.chromium.launch()`, a default browser context is created implicitly if you directly create pages (e.g., `browser.newPage()`). However, for true isolation, it's best practice to explicitly create `browser.newContext()`.

**Key use cases for multiple contexts:**
*   **User Roles Testing**: Simulating multiple users (e.g., admin and regular user) interacting with an application simultaneously or sequentially without their sessions interfering.
*   **Parallel Test Execution**: Running tests in parallel where each test requires a clean slate without shared state.
*   **Authentication Testing**: Testing login/logout flows and ensuring session management works correctly without contamination from other tests.
*   **Cookie/Local Storage Testing**: Verifying that specific data is stored or cleared correctly without affecting other parts of the application under test.

**How isolation works:**
*   **Cookies**: Each context maintains its own set of cookies.
*   **Local Storage/Session Storage**: These are unique to each context.
*   **Cache**: Contexts have separate caches.
*   **Plugins/Extensions**: Not shared between contexts.

By using `await browser.newContext()` to create distinct contexts, you guarantee that each test scenario starts with a clean browser state, which significantly improves test reliability and debugging.

## Code Implementation
This example demonstrates creating two separate browser contexts, `adminContext` and `userContext`, opening a page in each, navigating to a URL, and setting a cookie in one context to prove it doesn't affect the other.

```typescript
import { chromium, Browser, BrowserContext, Page } from 'playwright';

describe('Multiple Browser Contexts for Test Isolation', () => {
  let browser: Browser;
  let adminContext: BrowserContext;
  let userContext: BrowserContext;
  let adminPage: Page;
  let userPage: Page;

  // Before all tests, launch a single browser instance
  beforeAll(async () => {
    browser = await chromium.launch();
  });

  // After all tests, close the browser instance
  afterAll(async () => {
    await browser.close();
  });

  // Before each test, create new contexts and pages
  beforeEach(async () => {
    // Create an isolated context for the admin user
    adminContext = await browser.newContext();
    adminPage = await adminContext.newPage();

    // Create another isolated context for the regular user
    userContext = await browser.newContext();
    userPage = await userContext.newPage();
  });

  // After each test, close the contexts
  afterEach(async () => {
    await adminContext.close();
    await userContext.close();
  });

  test('should ensure cookies do not leak between contexts', async () => {
    const testUrl = 'https://www.example.com'; // Use a real URL for cookie setting to work reliably

    // 1. Admin context sets a cookie
    await adminPage.goto(testUrl);
    await adminContext.addCookies([
      {
        name: 'admin_session_id',
        value: 'admin123',
        url: testUrl,
        expires: Date.now() / 1000 + 3600, // Expires in 1 hour
      },
    ]);
    console.log('Admin context cookies:', await adminContext.cookies(testUrl));

    // 2. User context navigates to the same URL
    await userPage.goto(testUrl);

    // 3. Verify admin cookie is NOT present in user context
    const userCookies = await userContext.cookies(testUrl);
    const adminCookieInUserContext = userCookies.find(
      (cookie) => cookie.name === 'admin_session_id'
    );

    expect(adminCookieInUserContext).toBeUndefined(); // Expect the admin cookie NOT to be found

    // Optionally, set a user cookie and verify isolation
    await userContext.addCookies([
      {
        name: 'user_session_id',
        value: 'user456',
        url: testUrl,
        expires: Date.now() / 1000 + 3600,
      },
    ]);
    console.log('User context cookies:', await userContext.cookies(testUrl));

    const adminContextAfterUserCookie = await adminContext.cookies(testUrl);
    const userCookieInAdminContext = adminContextAfterUserCookie.find(
      (cookie) => cookie.name === 'user_session_id'
    );
    expect(userCookieInAdminContext).toBeUndefined(); // Expect the user cookie NOT to be found in admin context

    console.log('Isolation verified: Cookies do not leak between contexts.');
  });

  test('should allow independent navigation and interaction', async () => {
    // Admin context navigates and interacts
    await adminPage.goto('https://www.google.com');
    await adminPage.fill('[name="q"]', 'Playwright admin search');
    await adminPage.press('[name="q"]', 'Enter');
    await adminPage.waitForURL(/search/);
    expect(await adminPage.title()).toContain('Playwright admin search');

    // User context navigates and interacts independently
    await userPage.goto('https://www.bing.com');
    await userPage.fill('[name="q"]', 'Playwright user search');
    await userPage.press('[name="q"]', 'Enter');
    await userPage.waitForURL(/search/);
    expect(await userPage.title()).toContain('Playwright user search');

    // Verify independent states (e.g., adminPage still on Google, userPage on Bing)
    expect(adminPage.url()).toContain('google.com');
    expect(userPage.url()).toContain('bing.com');

    console.log('Independent navigation and interaction verified.');
  });
});
```

## Best Practices
-   **Always use `browser.newContext()` for tests**: Even for single-page tests, creating a new context ensures a clean slate, preventing unexpected failures due to leftover state from previous tests.
-   **Close contexts after tests**: Use `context.close()` in `afterEach` or `afterAll` blocks to release resources and ensure no lingering states affect subsequent test runs.
-   **Parameterize context creation**: For complex scenarios, pass options to `newContext()` (e.g., `locale`, `viewport`, `geolocation`, `permissions`) to simulate specific user environments.
-   **Use `storageState` for authentication**: For authenticated tests, capture and reuse `storageState` from an authenticated context to avoid repeated login steps, while still maintaining isolation for the rest of the test.
-   **Prefer `test.use()` for fixtures**: Playwright's test runner has built-in fixtures like `context` and `page` which automatically manage isolation per test, simplifying your test code. When defining custom fixtures, ensure they correctly handle context creation and teardown.

## Common Pitfalls
-   **Forgetting to close contexts**: Not closing contexts can lead to memory leaks and resource exhaustion, especially in large test suites, and can cause unpredictable test behavior.
-   **Sharing a single context across multiple tests without resetting state**: If you reuse a context without clearing its state (e.g., cookies, local storage) between tests, subsequent tests might be affected by previous ones, leading to flaky results.
-   **Incorrectly assuming page isolation implies context isolation**: Pages within the *same* context share cookies, local storage, etc. Only pages in *different* contexts are truly isolated.
-   **Overlooking `baseURL`**: While not directly related to contexts, if `baseURL` is configured, ensure your `goto` calls are correct when switching between contexts, especially if contexts are meant to target different origins.

## Interview Questions & Answers
1.  **Q: What is a browser context in Playwright, and why is it important for test automation?**
    **A:** A browser context in Playwright is an isolated environment within a browser instance, similar to an incognito window. It's crucial for test automation because it ensures complete isolation of browser state (cookies, local storage, sessions, cache) between different contexts. This prevents test interference, allows for testing scenarios with multiple user roles, and guarantees that each test starts with a clean and predictable environment, leading to more reliable and maintainable tests.

2.  **Q: How would you test a scenario involving an administrator and a regular user interacting with an application simultaneously using Playwright?**
    **A:** I would achieve this by creating two separate browser contexts: one for the administrator and one for the regular user.
    ```typescript
    const adminContext = await browser.newContext();
    const adminPage = await adminContext.newPage();
    // Perform admin actions on adminPage (e.g., login as admin)

    const userContext = await browser.newContext();
    const userPage = await userContext.newPage();
    // Perform regular user actions on userPage (e.g., login as regular user)

    // Then, simulate interactions on both pages, verifying their isolation and respective outcomes.
    // Finally, ensure both contexts are closed after the test.
    await adminContext.close();
    await userContext.close();
    ```
    This setup ensures that their sessions, cookies, and local storage are completely independent, preventing any state leakage or interference between the two user roles during the test.

3.  **Q: Explain the difference between `browser.newPage()` and `context.newPage()` in terms of isolation.**
    **A:**
    *   `browser.newPage()`: When called directly on the `Browser` object, it implicitly creates a default `BrowserContext` if one doesn't already exist for that browser instance, and then creates a new page within *that* default context. Subsequent calls to `browser.newPage()` will create new pages within the *same* default context, meaning they will share cookies, local storage, and other browser states. This does *not* provide isolation between those pages.
    *   `context.newPage()`: This creates a new page within a *specific*, explicitly created `BrowserContext`. Since each `BrowserContext` is isolated from others, pages created within different contexts are also isolated from each other. This is the preferred method for ensuring test isolation.

## Hands-on Exercise
**Objective**: Create a Playwright test that simulates two different users logging into two different parts of an application (or the same application if you only have one), and verify that their login states remain isolated.

**Steps**:
1.  Set up a basic Playwright project (if you don't have one).
2.  Write a test file named `multi-user.spec.ts`.
3.  Inside the test, launch a browser.
4.  Create two distinct browser contexts: `user1Context` and `user2Context`.
5.  For each context, create a new page: `user1Page` and `user2Page`.
6.  Navigate both pages to a simple login form (you can use `https://www.example.com/login` if you don't have a real one, and simulate login by setting a cookie or local storage item).
7.  In `user1Page`, "log in" by setting a specific cookie (e.g., `session_id: 'user1_token'`).
8.  In `user2Page`, "log in" by setting a different specific cookie (e.g., `session_id: 'user2_token'`).
9.  Verify that `user1Page` has `user1_token` and `user2Page` has `user2_token`.
10. Crucially, verify that `user1Page` *does not* have `user2_token` and `user2Page` *does not* have `user1_token`.
11. Ensure both contexts are closed after the test.

## Additional Resources
-   **Playwright BrowserContext documentation**: [https://playwright.dev/docs/api/class-browsercontext](https://playwright.dev/docs/api/class-browsercontext)
-   **Playwright Authentication**: [https://playwright.dev/docs/auth](https://playwright.dev/docs/auth)
-   **Playwright Test with Multiple Users**: [https://playwright.dev/docs/next/test-multiple-users](https://playwright.dev/docs/next/test-multiple-users)