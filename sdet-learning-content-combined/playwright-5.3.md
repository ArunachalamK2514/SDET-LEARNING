# playwright-5.3-ac1.md

# Playwright Browser, BrowserContext, and Page Hierarchy

## Overview
Understanding the hierarchical relationship between `Browser`, `BrowserContext`, and `Page` is fundamental to effective Playwright test automation. These three core components provide the structure for interacting with web applications, offering capabilities like isolated test environments, parallel execution, and fine-grained control over browser behavior. Grasping this hierarchy is crucial for writing robust, efficient, and maintainable automated tests.

## Detailed Explanation

In Playwright, the interaction with a web application is structured around a clear hierarchy:

1.  **`Browser`**: This is the top-level entity, representing a launched instance of a browser engine (e.g., Chromium, Firefox, WebKit). When you launch Playwright, you first create a `Browser` instance. Think of it as opening an entire browser application.
    *   **Creation**: `await playwright.chromium.launch()`, `await playwright.firefox.launch()`, `await playwright.webkit.launch()`.
    *   **Purpose**: Manages the underlying browser process, allows creation of multiple isolated browser contexts, and handles browser-level events.

2.  **`BrowserContext`**: A `BrowserContext` represents an isolated session within a `Browser` instance. Each context is completely independent of others, similar to an "Incognito" or "Private" browsing window. This isolation is a key feature of Playwright, ensuring that tests do not interfere with each other.
    *   **Creation**: `await browser.newContext()`.
    *   **Isolation**: Each `BrowserContext` has its own:
        *   **Cookies**: Session cookies, local storage, and other site data are unique to the context.
        *   **Local Storage**: `localStorage` and `sessionStorage` are isolated.
        *   **Cache**: Network cache is specific to the context.
        *   **Permissions**: Granted permissions (e.g., geolocation, camera access) are per context.
        *   **Browser State**: Everything from network requests to downloads and authentication is kept separate.
    *   **Purpose**: Ideal for scenarios where you need to simulate multiple users, run tests in parallel without state leakage, or test different user profiles (e.g., logged-in vs. logged-out).

3.  **`Page`**: A `Page` object represents a single tab or window within a `BrowserContext`. This is the primary object you'll interact with to perform actions on a web page, such as navigating to URLs, clicking elements, filling forms, and asserting content.
    *   **Creation**: `await context.newPage()`.
    *   **Purpose**: Provides methods for interacting with the DOM, handling network requests, executing JavaScript, taking screenshots, and more. All actions on a web page are performed through a `Page` instance.

### Relationship Diagram (Conceptual)

```
+---------------------+
|      Browser        |
| (Chromium/Firefox)  |
+---------+-----------+
          |
          |  (Can create multiple)
          v
+---------------------+    +---------------------+
|   BrowserContext 1  |    |   BrowserContext 2  |
| (Isolated Session)  |    | (Another Isolated   |
+---------+-----------+    +---------+-----------+
          |                          |
          | (Can create multiple)    | (Can create multiple)
          v                          v
+---------+-----------+    +---------+-----------+
|      Page 1         |    |      Page 3         |
| (Tab/Window)        |    | (Tab/Window)        |
+---------------------+    +---------------------+
+---------+-----------+
|      Page 2         |
| (Tab/Window)        |
+---------------------+
```

### Contexts Provide Isolation

The `BrowserContext` is a powerful feature for ensuring test reliability and enabling complex scenarios. Because each context is entirely isolated, actions performed in one context (like logging in, setting cookies, or modifying local storage) do not affect any other contexts, even if they are within the same `Browser` instance. This prevents cross-test contamination, making tests more deterministic and easier to debug.

## Code Implementation
Here's a TypeScript example demonstrating the creation and interaction with `Browser`, `BrowserContext`, and `Page` objects, highlighting the isolation provided by contexts.

```typescript
// filename: playwright-hierarchy.spec.ts
import { test, expect, Browser, BrowserContext, Page, chromium } from '@playwright/test';

test.describe('Playwright Browser, BrowserContext, Page Hierarchy', () => {
    let browser: Browser;

    // Launch a single browser instance for all tests in this describe block
    test.beforeAll(async () => {
        browser = await chromium.launch(); // Launch Chromium browser
    });

    // Close the browser instance after all tests are done
    test.afterAll(async () => {
        await browser.close();
    });

    test('should demonstrate isolation between two browser contexts', async () => {
        // --- Context 1: User A ---
        const context1: BrowserContext = await browser.newContext(); // Create an isolated context for User A
        const page1: Page = await context1.newPage(); // Create a new page (tab) within Context 1

        // Navigate and set a cookie in Context 1
        await page1.goto('https://www.google.com'); // Example: Navigate to a site
        await context1.addCookies([{
            name: 'user_session',
            value: 'user_A_token_123',
            url: 'https://www.google.com'
        }]);
        console.log('Context 1: User A session cookie set.');

        // Verify cookie in Context 1
        const cookies1 = await context1.cookies('https://www.google.com');
        expect(cookies1.some(cookie => cookie.name === 'user_session' && cookie.value === 'user_A_token_123')).toBeTruthy();
        console.log('Context 1: Verified User A session cookie.');

        // --- Context 2: User B ---
        const context2: BrowserContext = await browser.newContext(); // Create a separate, isolated context for User B
        const page2: Page = await context2.newPage(); // Create a new page (tab) within Context 2

        // Navigate to the same site and try to read cookies in Context 2
        await page2.goto('https://www.google.com'); // Navigate to the same site
        const cookies2 = await context2.cookies('https://www.google.com');

        // Expect User A's cookie NOT to be present in Context 2
        expect(cookies2.some(cookie => cookie.name === 'user_session')).toBeFalsy();
        console.log('Context 2: Confirmed User A session cookie is NOT present, demonstrating isolation.');

        // Set a different cookie in Context 2
        await context2.addCookies([{
            name: 'user_session',
            value: 'user_B_token_456',
            url: 'https://www.google.com'
        }]);
        console.log('Context 2: User B session cookie set.');

        // Verify cookie in Context 2
        const cookies2_after = await context2.cookies('https://www.google.com');
        expect(cookies2_after.some(cookie => cookie.name === 'user_session' && cookie.value === 'user_B_token_456')).toBeTruthy();
        console.log('Context 2: Verified User B session cookie.');


        // --- Clean up ---
        await page1.close();
        await context1.close();
        await page2.close();
        await context2.close();
    });

    test('should demonstrate multiple pages within a single browser context', async () => {
        const context: BrowserContext = await browser.newContext(); // Create a single context
        const pageA: Page = await context.newPage(); // Page A within the context
        const pageB: Page = await context.newPage(); // Page B within the same context

        // Both pages share the same context, so they can share cookies, local storage etc.
        await pageA.goto('https://www.example.com');
        await pageB.goto('https://www.google.com');

        await pageA.fill('input[type="search"]', 'Playwright');
        await pageB.fill('textarea[name="q"]', 'Playwright'); // Assuming google.com for simplicity

        // Example: Set a local storage item in Page A
        await pageA.evaluate(() => localStorage.setItem('my_data', 'shared_value_from_pageA'));

        // Navigate Page B to the same domain as Page A and verify local storage
        await pageB.goto('https://www.example.com'); // Navigate Page B to example.com
        const sharedData = await pageB.evaluate(() => localStorage.getItem('my_data'));
        expect(sharedData).toBe('shared_value_from_pageA');
        console.log('Both pages within the same context share local storage.');

        await pageA.close();
        await pageB.close();
        await context.close();
    });
});
```

## Best Practices
-   **Utilize `BrowserContext` for Isolation**: Always create a new `BrowserContext` for each independent test scenario or user flow. This guarantees test isolation and prevents state leakage between tests.
-   **Close Resources**: Ensure you close `Page` and `BrowserContext` instances after they are no longer needed (`page.close()`, `context.close()`). While `browser.close()` will close all associated contexts and pages, explicit closing of contexts and pages is good practice, especially in `beforeEach`/`afterEach` hooks, to free up resources promptly.
-   **Parallelize Tests with Contexts**: Playwright allows running tests in parallel across different `BrowserContext` instances within the same `Browser`, significantly speeding up test execution.
-   **Configure Contexts**: Use `browser.newContext()` to set specific options for a context, such as `viewport`, `locale`, `permissions`, `offline`, or `httpCredentials`, to simulate various user environments.

## Common Pitfalls
-   **Not Closing Resources**: Failing to call `context.close()` or `page.close()` can lead to memory leaks, increased resource consumption, and flaky tests, especially in long-running test suites.
-   **State Leakage**: Reusing the same `BrowserContext` for multiple unrelated tests can lead to state leakage (e.g., cookies, local storage, authentication) from one test affecting another, resulting in unpredictable test failures.
-   **Over-reliance on Global Browser**: While `test.beforeAll` for `browser` launch is fine, avoid putting `context` or `page` creation in `beforeAll` if tests need isolation. Always create new `BrowserContext` and `Page` in `beforeEach` or within the test itself for complete isolation.
-   **Confusing Browser vs. Context Settings**: Browser-level settings apply to all contexts within that browser (e.g., headless mode), while context-level settings are specific to that context (e.g., cookies, user agent string). Understand which setting applies where.

## Interview Questions & Answers

1.  **Q: Explain the hierarchy of `Browser`, `BrowserContext`, and `Page` in Playwright and how they relate to each other.**
    *   **A:** In Playwright, the `Browser` is the top-level instance of a web browser (like Chromium, Firefox, or WebKit). A `Browser` can host multiple `BrowserContext` instances. Each `BrowserContext` represents an independent, isolated browsing session—similar to an Incognito window—with its own cookies, local storage, and session data. Within each `BrowserContext`, you can open one or more `Page` objects, where each `Page` corresponds to a single browser tab or window. So, the hierarchy is `Browser` -> `BrowserContext` -> `Page`.

2.  **Q: Why is `BrowserContext` a crucial concept in Playwright, especially for test automation, and when would you use multiple contexts?**
    *   **A:** `BrowserContext` is crucial because it provides complete isolation between browsing sessions. This prevents state leakage, meaning actions or data (like login sessions, cookies, or local storage) from one test or user flow won't interfere with another. You would use multiple `BrowserContext` instances in scenarios such as:
        *   **Parallel Test Execution**: Running independent tests concurrently without worrying about shared state.
        *   **Multi-user Scenarios**: Simulating interactions between different users (e.g., a buyer and a seller on an e-commerce site) who need separate login sessions simultaneously.
        *   **Testing Different Permissions/Profiles**: Testing how a web application behaves under different user permissions or configurations.
        *   **Guest vs. Authenticated User Flows**: Quickly switching between logged-in and logged-out states without re-launching the entire browser.

## Hands-on Exercise
**Scenario**: Demonstrate simultaneous login of two different users into a hypothetical web application using separate `BrowserContext` instances.

**Task**:
1.  Set up a Playwright test.
2.  Launch a browser.
3.  Create two separate `BrowserContext` instances.
4.  Within each context, create a `Page`.
5.  For `Context 1` and `Page 1`:
    *   Navigate to a dummy login page (e.g., `http://localhost:8080/login` or `https://www.example.com`).
    *   Simulate a login for `User A` by setting a unique cookie or `localStorage` item (e.g., `user: 'UserA'`, `isLoggedIn: 'true'`).
    *   Verify `User A` is "logged in" by checking for the presence of the set cookie/local storage.
6.  For `Context 2` and `Page 2`:
    *   Navigate to the *same* dummy login page.
    *   Simulate a login for `User B` (e.g., `user: 'UserB'`, `isLoggedIn: 'true'`).
    *   Verify `User B` is "logged in" and crucially, verify that `User A`'s login state is *not* present in `Context 2`.
7.  Close all pages and contexts.

**(Hint: For the dummy login page, you can just use `https://www.example.com` and use `page.evaluate()` to manipulate `localStorage` for demonstration purposes, as direct login might require a live application.)**

## Additional Resources
-   **Playwright Official Documentation - Browsers**: [https://playwright.dev/docs/api/class-browser](https://playwright.dev/docs/api/class-browser)
-   **Playwright Official Documentation - BrowserContext**: [https://playwright.dev/docs/api/class-browsercontext](https://playwright.dev/docs/api/class-browsercontext)
-   **Playwright Official Documentation - Page**: [https://playwright.dev/docs/api/class-page](https://playwright.dev/docs/api/class-page)
-   **Playwright Docs - Authentication**: [https://playwright.dev/docs/auth](https://playwright.dev/docs/auth) (for deeper understanding of session management)
---
# playwright-5.3-ac2.md

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
---
# playwright-5.3-ac3.md

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
---
# playwright-5.3-ac4.md

# Playwright Navigation: `page.goto()`, `page.goBack()`, `page.goForward()`

## Overview
Effective navigation is fundamental to web automation. Playwright provides robust methods to control browser page navigation, allowing tests to simulate user journeys accurately. This document explores `page.goto()`, `page.goBack()`, and `page.goForward()`, essential commands for directing the browser through different URLs and its history. Understanding these methods is critical for creating reliable and comprehensive end-to-end tests.

## Detailed Explanation

### `page.goto(url, options)`
This method navigates the page to the specified URL. It's the primary way to initiate a test by directing the browser to a starting point.

*   **`url` (string)**: The URL to navigate to.
*   **`options` (object, optional)**:
    *   `waitUntil` (string): When to consider navigation succeeded. Common values:
        *   `"load"`: Considers navigation to be finished when the `load` event is fired.
        *   `"domcontentloaded"`: Considers navigation to be finished when the `DOMContentLoaded` event is fired.
        *   `"networkidle"`: Considers navigation to be finished when there have been no network connections for 500 ms. This is often the most robust for dynamic pages.
        *   `"commit"`: Considers navigation to be finished when the first response is received and the document is committed.
    *   `timeout` (number): Maximum navigation time in milliseconds, defaults to 30000 (30 seconds). Pass 0 to disable timeout.
    *   `referer` (string): Referer header value.

### `page.goBack(options)`
This method navigates the page to the previous entry in the browser's history, mimicking a user clicking the "back" button.

*   **`options` (object, optional)**: Same `waitUntil` and `timeout` options as `page.goto()`.

### `page.goForward(options)`
This method navigates the page to the next entry in the browser's history, mimicking a user clicking the "forward" button.

*   **`options` (object, optional)**: Same `waitUntil` and `timeout` options as `page.goto()`.

### Verifying Navigation with `page.url()`
After any navigation action, it's crucial to verify that the browser has landed on the expected page. The `page.url()` method returns the current URL of the page, which can then be asserted against the expected URL.

## Code Implementation

The following TypeScript example demonstrates navigating to a URL, clicking a link to navigate away, then using `goBack()` and `goForward()`, verifying the URL at each step.

```typescript
import { test, expect, Page } from '@playwright/test';

test.describe('Page Navigation Tests', () => {
  let page: Page;

  test.beforeEach(async ({ browser }) => {
    // Create a new page for each test
    page = await browser.newPage();
  });

  test.afterEach(async () => {
    // Close the page after each test
    await page.close();
  });

  test('should navigate using goto, goBack, and goForward', async () => {
    // 1. Navigate to an initial URL
    const initialUrl = 'https://www.wikipedia.org/';
    console.log(`Navigating to: ${initialUrl}`);
    await page.goto(initialUrl, { waitUntil: 'networkidle' });
    expect(page.url()).toBe(initialUrl);
    console.log(`Current URL: ${page.url()}`);

    // 2. Click a link to navigate away (e.g., to the English Wikipedia page)
    const linkSelector = 'a[data-jsl10n="lang-en"]'; // Selector for English link on Wikipedia
    console.log(`Clicking link: ${linkSelector}`);
    await page.click(linkSelector);
    // Wait for navigation to complete after clicking the link
    await page.waitForURL(/en.wikipedia.org/, { waitUntil: 'networkidle' });

    const navigatedUrl = page.url();
    expect(navigatedUrl).toMatch(/en.wikipedia.org/);
    expect(navigatedUrl).not.toBe(initialUrl); // Ensure we've moved to a different page
    console.log(`Navigated to: ${navigatedUrl}`);

    // 3. Use goBack() to return to the initial URL
    console.log('Going back...');
    await page.goBack({ waitUntil: 'networkidle' });
    expect(page.url()).toBe(initialUrl);
    console.log(`Returned to: ${page.url()}`);

    // 4. Use goForward() to advance back to the navigated URL
    console.log('Going forward...');
    await page.goForward({ waitUntil: 'networkidle' });
    expect(page.url()).toBe(navigatedUrl);
    console.log(`Advanced to: ${page.url()}`);

    // Optional: Navigate to a different page directly using goto to demonstrate its versatility
    const finalUrl = 'https://www.google.com/';
    console.log(`Navigating to: ${finalUrl}`);
    await page.goto(finalUrl, { waitUntil: 'networkidle' });
    expect(page.url()).toBe(finalUrl);
    console.log(`Final URL: ${page.url()}`);
  });
});

// To run this test:
// 1. Make sure you have Playwright installed: `npm init playwright@latest`
// 2. Save the code above as a .ts file (e.g., navigation.test.ts)
// 3. Run from your terminal: `npx playwright test navigation.test.ts`
```

## Best Practices
-   **Use `waitUntil` Appropriately**: Always specify a `waitUntil` option for `goto()`, `goBack()`, and `goForward()`. `"networkidle"` is often the most reliable for modern web applications, ensuring all network requests have settled.
-   **Verify URLs**: After every navigation action, use `expect(page.url()).toBe(expectedUrl)` to confirm that the browser has arrived at the correct destination.
-   **Handle Timeouts**: Be aware of the default 30-second timeout. For pages with very heavy assets or slow servers, you might need to increase the `timeout` option.
-   **Error Handling**: Wrap navigation calls in `try-catch` blocks if network instabilities or unexpected redirects are potential issues, especially in non-test automation scenarios (e.g., scraping).

## Common Pitfalls
-   **Not Waiting for Navigation Completion**: Forgetting `waitUntil` can lead to flaky tests where assertions are made before the page has fully loaded, resulting in `Element not found` errors or incorrect state.
-   **Ignoring Network Errors**: `page.goto()` can throw errors if navigation fails (e.g., 404, DNS error). Tests should ideally catch or allow these to fail predictably.
-   **Ambiguous URL Assertions**: Using partial URL matches (e.g., `expect(page.url()).toContain('product')`) can be too broad. Prefer exact matches or more specific regex when possible to prevent false positives.
-   **Incorrect History State**: `goBack()` and `goForward()` rely on the browser's history. If a preceding action didn't create a new history entry (e.g., a hash change on the same page, or an in-page AJAX update), these methods might not behave as expected.

## Interview Questions & Answers
1.  **Q: Describe the different `waitUntil` options in Playwright's navigation methods. When would you use each?**
    *   **A:** Playwright offers `load`, `domcontentloaded`, `networkidle`, and `commit`.
        *   `load`: Fires when the entire page (including images, stylesheets, etc.) has loaded. Useful for traditional, server-rendered pages.
        *   `domcontentloaded`: Fires when the initial HTML document has been completely loaded and parsed. Useful for pages where JavaScript execution begins early.
        *   `networkidle`: Fires when there have been no network connections for at least 500 ms. Most robust for modern single-page applications (SPAs) with dynamic content and many AJAX requests.
        *   `commit`: Fires when the first network response is received and the document is committed. Fastest, useful when you just need to ensure the navigation initiated.
    The choice depends on the specific page and what you consider a "loaded" state. `networkidle` is often a good default for reliability.

2.  **Q: How would you handle a scenario where `page.goBack()` doesn't seem to work as expected in your Playwright test? What might be the causes?**
    *   **A:** Possible causes include:
        *   **No history entry**: The previous action might not have created a new entry in the browser's history. This can happen with in-page navigations (e.g., hash changes, modals), or if the previous `goto()` was called with `history: 'none'` (though `goBack` specifically aims to respect history).
        *   **Race condition/Timing**: The `goBack()` call might be executed before the browser fully registers the previous navigation in its history stack. Adding appropriate `waitUntil` options or a brief `page.waitForTimeout()` (as a last resort) might help.
        *   **Redirections**: If the previous page was a redirect, `goBack()` might take you to an unexpected intermediate page or even further back.
        *   **JavaScript History Manipulation**: Some web applications aggressively manipulate the browser history using JavaScript, which can interfere with `goBack()`/`goForward()`.
    To debug, I would inspect `page.url()` before and after `goBack()` and use `page.evaluate(() => history.length)` to check the history stack size.

## Hands-on Exercise
1.  Navigate to `https://www.google.com/`.
2.  Search for "Playwright testing" and press Enter.
3.  Click on the first search result that leads to a different domain (e.g., Playwright's official documentation).
4.  Use `page.goBack()` to return to the search results page. Verify the URL.
5.  Use `page.goBack()` again to return to `https://www.google.com/`. Verify the URL.
6.  Use `page.goForward()` to go back to the search results page. Verify the URL.

## Additional Resources
-   **Playwright `page.goto()` documentation**: [https://playwright.dev/docs/api/class-page#page-go-to](https://playwright.dev/docs/api/class-page#page-go-to)
-   **Playwright `page.goBack()` documentation**: [https://playwright.dev/docs/api/class-page#page-go-back](https://playwright.dev/docs/api/class-page#page-go-back)
-   **Playwright `page.goForward()` documentation**: [https://playwright.dev/docs/api/class-page#page-go-forward](https://playwright.dev/docs/api/class-page#page-go-forward)
---
# playwright-5.3-ac5.md

# Playwright Actions: `click()`, `fill()`, `type()`, `selectOption()`, `check()`

## Overview
Automating user interactions is at the core of web testing and scraping. Playwright provides a powerful and intuitive API to simulate common user actions like clicking elements, filling forms, typing text, selecting dropdown options, and checking checkboxes/radio buttons. Mastering these fundamental actions is crucial for creating robust and reliable end-to-end tests. This section delves into how to effectively use Playwright's action methods, offering detailed explanations and practical examples.

## Detailed Explanation

Playwright's action methods are designed to be resilient, automatically waiting for elements to be actionable (e.g., visible, enabled, not obscured by other elements) before performing the action. This built-in auto-waiting mechanism significantly reduces the flakiness often associated with UI automation.

### 1. `fill(selector, value, options)` - Filling Form Inputs
The `fill()` method is used to populate text input fields or text areas. It first clears the existing content and then types the new value. This is generally preferred over `type()` for input fields as it's faster and more direct.

**When to use:** For standard `<input type="text">`, `<input type="password">`, `<textarea>`, etc.

### 2. `type(selector, text, options)` - Typing Text Character by Character
The `type()` method simulates keyboard input, typing characters one by one. This is useful when you need to trigger keyboard events (e.g., `keydown`, `keyup`, `input`) or observe character-by-character input behavior.

**When to use:** When you need to trigger input events, test auto-complete suggestions, or simulate human typing speed.

### 3. `click(selector, options)` - Performing Clicks
The `click()` method simulates a mouse click on an element. It can handle various click types (left, right, middle) and can be configured with modifiers (Ctrl, Alt, Shift). Playwright automatically scrolls the element into view if necessary and waits for it to become clickable.

**When to use:** For buttons, links, clickable `div`s, or any element that responds to a mouse click.

### 4. `selectOption(selector, values, options)` - Selecting Dropdown Options
The `selectOption()` method is specifically designed for `<select>` elements. It allows you to select one or more options by their value, label, or index.

**When to use:** For `<select>` dropdowns.

### 5. `check(selector, options)` / `uncheck(selector, options)` - Checking Checkboxes and Radio Buttons
The `check()` method marks a checkbox or radio button as checked. If the element is already checked, it does nothing. Similarly, `uncheck()` unchecks an element.

**When to use:** For `<input type="checkbox">` and `<input type="radio">` elements.

## Code Implementation
Here's a comprehensive TypeScript example demonstrating all these actions. Assume a simple HTML page with a form.

```typescript
// example.spec.ts
import { test, expect, Page } from '@playwright/test';

test.describe('Playwright Basic Actions', () => {
    let page: Page;

    // Before each test, navigate to a local test HTML file
    test.beforeEach(async ({ browser }) => {
        page = await browser.newPage();
        // Assuming 'test-form.html' is in the root of your project or served locally
        await page.goto('file://' + process.cwd() + '/xpath_axes_test_page.html'); // Using the provided test page
    });

    test.afterEach(async () => {
        await page.close();
    });

    test('should fill a form input', async () => {
        // Find the input field for 'First Name' on the xpath_axes_test_page.html
        // Using a more robust locator strategy as direct IDs might not always be available or unique.
        // On xpath_axes_test_page.html, there are input fields, let's target one example.
        // Assuming there's an input like <input type="text" name="username"> or similar for form filling.
        // For demonstration, let's assume there's an input by role or text association.
        // If the HTML doesn't have an obvious target, we'd need to adapt.
        // Let's create a temporary input field if not present for a clear example.
        // For the provided xpath_axes_test_page.html, let's target the 'username' input.
        // The page contains: <input type="text" id="username" name="username">
        const usernameInput = page.locator('#username');
        await usernameInput.fill('JohnDoe');
        await expect(usernameInput).toHaveValue('JohnDoe');
        console.log('Filled username input with: JohnDoe');
    });

    test('should select an option from a dropdown', async () => {
        // On xpath_axes_test_page.html, let's use the 'car-select' dropdown.
        // <select id="car-select">
        //   <option value="volvo">Volvo</option>
        //   <option value="saab">Saab</option>
        //   <option value="mercedes">Mercedes</option>
        //   <option value="audi">Audi</option>
        // </select>
        const dropdown = page.locator('#car-select');
        await dropdown.selectOption('mercedes'); // Select by value
        await expect(dropdown).toHaveValue('mercedes');
        console.log('Selected option: Mercedes');

        // You can also select by label or index
        await dropdown.selectOption({ label: 'Audi' });
        await expect(dropdown).toHaveValue('audi');
        console.log('Selected option: Audi by label');

        await dropdown.selectOption({ index: 0 }); // Selects Volvo
        await expect(dropdown).toHaveValue('volvo');
        console.log('Selected option: Volvo by index');
    });

    test('should check and uncheck a checkbox and radio button', async () => {
        // On xpath_axes_test_page.html, let's use the 'newsletter' checkbox and 'gender' radio buttons.
        // <input type="checkbox" id="newsletter" name="newsletter">
        // <input type="radio" id="male" name="gender" value="male">
        // <input type="radio" id="female" name="gender" value="female">

        const newsletterCheckbox = page.locator('#newsletter');
        await expect(newsletterCheckbox).not.toBeChecked();
        await newsletterCheckbox.check();
        await expect(newsletterCheckbox).toBeChecked();
        console.log('Checked newsletter checkbox');

        await newsletterCheckbox.uncheck();
        await expect(newsletterCheckbox).not.toBeChecked();
        console.log('Unchecked newsletter checkbox');

        const maleRadio = page.locator('#male');
        const femaleRadio = page.locator('#female');

        await expect(maleRadio).not.toBeChecked();
        await expect(femaleRadio).not.toBeChecked();

        await maleRadio.check();
        await expect(maleRadio).toBeChecked();
        await expect(femaleRadio).not.toBeChecked(); // Ensure only one is checked
        console.log('Checked male radio button');

        await femaleRadio.check();
        await expect(femaleRadio).toBeChecked();
        await expect(maleRadio).not.toBeChecked(); // Ensure only one is checked
        console.log('Checked female radio button');
    });

    test('should perform a click (left and right)', async () => {
        // On xpath_axes_test_page.html, let's find a clickable element.
        // For example, the 'Click Me' button: <button id="clickMeButton">Click Me</button>
        const clickMeButton = page.locator('#clickMeButton');
        
        // Ensure the element is present, then click
        await expect(clickMeButton).toBeVisible();

        // Left click (default)
        await clickMeButton.click();
        // Assuming a click might trigger an alert or text change,
        // we'd assert on that. For now, let's log.
        console.log('Performed a left click on "Click Me" button');

        // Right click (context menu)
        // Note: Playwright doesn't directly expose context menu interactions like
        // inspecting elements, but it can trigger the event.
        await clickMeButton.click({ button: 'right' });
        console.log('Performed a right click on "Click Me" button');
    });

    test('should type text character by character', async () => {
        // On xpath_axes_test_page.html, let's use the 'password' input field for typing
        // <input type="password" id="password" name="password">
        const passwordInput = page.locator('#password');
        await passwordInput.type('securePassword', { delay: 100 }); // Simulate typing with a delay
        await expect(passwordInput).toHaveValue('securePassword');
        console.log('Typed text character by character into password input');
    });
});
```
*Note*: The `xpath_axes_test_page.html` might not have all the elements exactly as assumed above. If the tests fail, the HTML file might need to be adjusted or more specific locators used based on its actual content. I have made reasonable assumptions based on common form elements.

## Best Practices
- **Prefer `fill()` over `type()` for basic input:** `fill()` is faster and more reliable as it clears the field and sets the value directly. Use `type()` only when character-by-character events or delays are critical.
- **Use meaningful locators:** Prioritize `getByRole`, `getByText`, `getByLabel`, `getByPlaceholder` before CSS selectors or XPath for better test resilience and readability.
- **Assertions after actions:** Always assert the expected state *after* performing an action to confirm it had the desired effect.
- **Chaining actions:** Playwright allows chaining actions for conciseness, e.g., `await page.locator('#myInput').fill('text').press('Enter');`
- **Error handling:** Wrap actions in `try...catch` blocks for more specific error logging or recovery strategies in complex scenarios.

## Common Pitfalls
- **Not waiting for element readiness:** While Playwright has auto-waiting, sometimes explicit waits (`waitForSelector`, `waitForLoadState`) might be necessary for complex transitions or dynamic content, especially before attempting an action.
- **Incorrect locators:** Using brittle locators (e.g., highly specific CSS paths generated by tools) can lead to flaky tests. Invest time in crafting robust locators.
- **Ignoring side effects of actions:** An action might trigger UI changes (e.g., a modal dialog, form submission). Always consider and assert the expected subsequent state.
- **Over-reliance on `type()` for speed:** If you just need to set the value of an input, `fill()` is almost always the better choice for performance.
- **Misunderstanding `check()` vs. `click()` for checkboxes:** `check()` and `uncheck()` explicitly set the state and handle existing state, while `click()` simply toggles it and might fail if the element is already in the desired state or has complex handlers.

## Interview Questions & Answers
1.  **Q: Explain the difference between `page.fill()` and `page.type()` in Playwright. When would you use each?**
    **A:** `page.fill(selector, value)` is a high-level action that directly sets the value of an input field. It's fast and doesn't simulate individual key presses, making it ideal for most form-filling scenarios. `page.type(selector, text)` simulates typing character by character, triggering all associated keyboard events (`keydown`, `keyup`, `keypress`, `input`). You would use `page.fill()` for performance and reliability when you just need to set text. You would use `page.type()` when testing features like auto-suggestions, input masks, character counters, or when specific keyboard event handlers are crucial for your application's logic.

2.  **Q: How does Playwright handle waiting for elements to be actionable before performing an action like `click()`?**
    **A:** Playwright has a powerful auto-waiting mechanism. Before performing an action, it automatically waits for several conditions to be met for the target element by default:
    *   **Visible:** The element is displayed on the page.
    *   **Enabled:** The element is not disabled.
    *   **Stable:** The element is not animating or moving.
    *   **Receives Events:** The element can receive mouse/keyboard events at its action point (e.g., not covered by another element).
    *   **Attached:** The element is attached to the DOM.
    If these conditions are not met within a default timeout (usually 30 seconds), the action fails with a timeout error. This significantly reduces flakiness compared to tools that require explicit, fixed waits.

3.  **Q: You need to select multiple options from a multi-select dropdown. How would you do this in Playwright?**
    **A:** You can pass an array of values to the `page.selectOption()` method. For example:
    ```typescript
    await page.selectOption('#multiSelectDropdown', ['option1_value', 'option2_value']);
    ```
    This will select options whose `value` attributes match `'option1_value'` and `'option2_value'`. You can also mix and match selecting by `value`, `label`, or `index` by providing an array of objects:
    ```typescript
    await page.selectOption('#multiSelectDropdown', [
        { value: 'option1_value' },
        { label: 'Option Two' },
        { index: 3 }
    ]);
    ```

## Hands-on Exercise

**Scenario:** Automate a simple login process and product selection.

**Instructions:**
1.  Create an `index.html` file with:
    *   An input field with `id="username"`
    *   An input field with `id="password"`
    *   A button with `id="loginButton"`
    *   A dropdown with `id="productSelect"` containing options like "Laptop", "Mouse", "Keyboard"
    *   A checkbox with `id="agreeTerms"`
    *   A button with `id="addToCartButton"`
    *   A `div` with `id="statusMessage"` to display messages.

2.  Write a Playwright test script (`login.spec.ts`) that performs the following sequence of actions:
    *   Navigate to your `index.html` file.
    *   Fill the username field with "testuser".
    *   Fill the password field with "password123".
    *   Click the "Login" button.
    *   Assert that a success message appears in `statusMessage` (you'll need to add JavaScript to `index.html` to simulate this, e.g., on login button click).
    *   Select "Keyboard" from the product dropdown.
    *   Check the "agreeTerms" checkbox.
    *   Click the "Add to Cart" button.
    *   Assert that another success message appears in `statusMessage`.

**Expected Outcome:** A passing Playwright test that simulates a user logging in, selecting a product, agreeing to terms, and adding it to a cart.

## Additional Resources
-   **Playwright Actions Documentation:** [https://playwright.dev/docs/input](https://playwright.dev/docs/input)
-   **Playwright Locators Guide:** [https://playwright.dev/docs/locators](https://playwright.dev/docs/locators)
-   **Playwright Auto-waiting:** [https://playwright.dev/docs/auto-waiting](https://playwright.dev/docs/auto-waiting)
---
# playwright-5.3-ac6.md

# Playwright File Uploads: Handling `setInputFiles()`

## Overview
Automating file uploads is a common requirement in web testing. Playwright provides a robust and straightforward method, `locator.setInputFiles()`, to handle file input elements efficiently. This feature is crucial for testing functionalities that involve users submitting documents, images, or other files through a web application. Understanding its proper usage ensures comprehensive test coverage for such scenarios.

## Detailed Explanation
Playwright's `setInputFiles()` method simplifies interacting with `<input type="file">` elements. Instead of simulating complex user interactions like drag-and-drop or clicking an "Open File" dialog, Playwright directly sets the files on the input element.

The method can accept:
1.  A single file path (string).
2.  An array of file paths (array of strings) for multiple file uploads.
3.  File payload objects (`{ name: string, mimeType: string, buffer: Buffer | string }`) for more control, especially when dealing with in-memory generated files.

When `setInputFiles()` is called:
-   Playwright locates the target file input element.
-   It injects the specified file(s) into the input.
-   This action triggers the `'change'` event on the input element, mimicking a real user interaction, which allows the application's JavaScript to react accordingly.

To clear previously selected files, `setInputFiles()` can be called with an empty array.

### Steps to Handle File Uploads:
1.  **Locate the file input element:** Use `page.locator()` to get a reference to the `<input type="file">` element.
2.  **Set the file(s):** Call `locator.setInputFiles()` with the path(s) to the file(s) you want to upload. The paths should be relative to the current working directory of your test runner or absolute paths.
3.  **Verify upload (optional but recommended):** After setting the files, check for UI indicators that confirm the upload, such as a file name appearing next to the input, a success message, or the uploaded content being displayed.
4.  **Upload multiple files:** If the input supports multiple files (e.g., `<input type="file" multiple>`), pass an array of file paths to `setInputFiles()`.
5.  **Clear selected files:** Pass an empty array `[]` to `setInputFiles()` to clear any files currently attached to the input.

## Code Implementation
Here's a TypeScript example demonstrating various file upload scenarios.

```typescript
import { test, expect, Page } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

// Create a dummy file for testing purposes
test.beforeAll(() => {
    const dummyFilePath = path.join(__dirname, 'dummy-upload.txt');
    fs.writeFileSync(dummyFilePath, 'This is a dummy file for upload testing.');

    const dummyImageFilePath = path.join(__dirname, 'dummy-image.png');
    // Create a simple 1x1 transparent PNG buffer
    const pngBuffer = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=', 'base64');
    fs.writeFileSync(dummyImageFilePath, pngBuffer);
});

// Clean up the dummy file after all tests are done
test.afterAll(() => {
    fs.unlinkSync(path.join(__dirname, 'dummy-upload.txt'));
    fs.unlinkSync(path.join(__dirname, 'dummy-image.png'));
});

test.describe('File Upload Scenarios', () => {
    let page: Page;

    test.beforeEach(async ({ browser }) => {
        page = await browser.newPage();
        // Assume a test page with a file input element
        // For demonstration, we'll navigate to a simple local HTML file
        // In a real scenario, this would be your application's URL.
        await page.setContent(`
            <!DOCTYPE html>
            <html>
            <head>
                <title>File Upload Test</title>
            </head>
            <body>
                <h1>File Upload Demo</h1>
                <input type="file" id="singleFileInput">
                <p id="singleFileName"></p>

                <h2>Multiple Files</h2>
                <input type="file" id="multipleFileInput" multiple>
                <ul id="multipleFileNames"></ul>

                <h2>File Upload via Draggable Area (simulated)</h2>
                <div id="dropArea" style="width: 200px; height: 100px; border: 2px dashed gray; text-align: center; line-height: 100px;">
                    Drop files here (simulated)
                </div>
                <p id="dropAreaFileName"></p>
                <script>
                    document.getElementById('singleFileInput').addEventListener('change', function(event) {
                        document.getElementById('singleFileName').textContent = 'Selected: ' + event.target.files[0]?.name || 'No file';
                    });
                    document.getElementById('multipleFileInput').addEventListener('change', function(event) {
                        const ul = document.getElementById('multipleFileNames');
                        ul.innerHTML = '';
                        for (const file of event.target.files) {
                            const li = document.createElement('li');
                            li.textContent = file.name;
                            ul.appendChild(li);
                        }
                    });
                    // For drop area, Playwright generally works by interacting directly with the hidden input if available
                    // or by using setInputFiles on the visible element which might have an associated input.
                    // Here, we'll simulate the drop area having an internal file input logic.
                    // In real apps, drop zones often have a hidden input they delegate to.
                    // Playwright's setInputFiles works best on the actual <input type="file">.
                    // If a drop area uses AJAX and doesn't expose a direct input, you might need to mock the XHR/fetch.
                </script>
            </body>
            </html>
        `);
    });

    test('should upload a single file using setInputFiles', async () => {
        const filePath = path.join(__dirname, 'dummy-upload.txt');
        const fileInput = page.locator('#singleFileInput');

        // Set the file
        await fileInput.setInputFiles(filePath);

        // Verify the file name is displayed
        await expect(page.locator('#singleFileName')).toHaveText('Selected: dummy-upload.txt');
    });

    test('should upload multiple files using setInputFiles', async () => {
        const filePath1 = path.join(__dirname, 'dummy-upload.txt');
        const filePath2 = path.join(__dirname, 'dummy-image.png'); // Uploading an image as a second file
        const multipleFileInput = page.locator('#multipleFileInput');

        // Set multiple files
        await multipleFileInput.setInputFiles([filePath1, filePath2]);

        // Verify all file names are displayed
        await expect(page.locator('#multipleFileNames')).toContainText('dummy-upload.txt');
        await expect(page.locator('#multipleFileNames')).toContainText('dummy-image.png');
    });

    test('should clear selected files using an empty array', async () => {
        const filePath = path.join(__dirname, 'dummy-upload.txt');
        const fileInput = page.locator('#singleFileInput');

        // First, upload a file
        await fileInput.setInputFiles(filePath);
        await expect(page.locator('#singleFileName')).toHaveText('Selected: dummy-upload.txt');

        // Then, clear the files
        await fileInput.setInputFiles([]);

        // Verify no file is selected
        await expect(page.locator('#singleFileName')).toHaveText('Selected: No file');
    });

    test('should upload file using file payload object', async () => {
        const fileInput = page.locator('#singleFileInput');
        const fileName = 'generated-report.csv';
        const fileContent = 'header1,header2
value1,value2';
        const fileMimeType = 'text/csv';

        // Set the file using a payload object
        await fileInput.setInputFiles({
            name: fileName,
            mimeType: fileMimeType,
            buffer: Buffer.from(fileContent)
        });

        // Verify the file name is displayed
        await expect(page.locator('#singleFileName')).toHaveText(`Selected: ${fileName}`);
        // In a real app, you might assert that the server received the correct content.
    });

    // Note: For elements that are not <input type="file"> but act as drop zones,
    // Playwright's setInputFiles generally won't work directly.
    // You would typically find the hidden <input type="file"> element that the drop zone delegates to
    // and then call setInputFiles on that hidden input.
    // If no such hidden input exists, and the application uses a custom drag-and-drop implementation
    // with AJAX calls, you might need to mock the network request if direct DOM manipulation isn't feasible.
});
```

## Best Practices
-   **Use `locator.setInputFiles()` on the `<input type="file">` element directly:** This is the most reliable way to handle file uploads. Avoid trying to simulate drag-and-drop events on custom drop zones unless absolutely necessary, and if so, understand that you'll likely need to target the underlying hidden input.
-   **Prepare test files:** Create dummy files programmatically (`fs.writeFileSync`) in your `test.beforeAll` or `test.beforeEach` hooks and clean them up in `test.afterAll` or `test.afterEach` to ensure tests are self-contained and don't leave artifacts.
-   **Verify upload success:** Always include assertions to confirm that the file upload was successful from the user's perspective (e.g., file name displayed, success message, preview available).
-   **Handle multiple file inputs:** If your application has multiple file input fields, ensure you locate each one correctly and apply `setInputFiles()` to the specific locator.
-   **Relative vs. Absolute Paths:** Using `path.join(__dirname, 'your-file.txt')` is a good practice to create absolute paths that work consistently across different environments, relative to your test file.

## Common Pitfalls
-   **Targeting the wrong element:** Trying to use `setInputFiles()` on a `<div>` or other non-input element that acts as a custom upload area. Playwright needs to interact with the actual `<input type="file">` element.
-   **File not found errors:** Providing incorrect or non-existent paths to `setInputFiles()`. Always verify your file paths.
-   **Not clearing files:** In tests where you perform multiple uploads, remember to clear previously uploaded files (by calling `setInputFiles([])`) if the test scenario requires a clean state for each upload attempt.
-   **Ignoring application's internal logic:** While `setInputFiles()` triggers the `change` event, some complex upload components might have additional JavaScript validation or server-side checks. Ensure your tests account for these.
-   **Asynchronous operations:** File uploads are often asynchronous. Ensure you `await` the `setInputFiles()` call and any subsequent assertions that depend on the file being processed by the application.

## Interview Questions & Answers
1.  **Q:** How do you handle file uploads in Playwright?
    **A:** In Playwright, file uploads are handled using the `locator.setInputFiles()` method. You first locate the `<input type="file">` element and then call `setInputFiles()` on its locator, passing the path(s) to the file(s) you wish to upload. This method simulates a user selecting files through the native file picker.

2.  **Q:** Can `setInputFiles()` be used for multiple file uploads? If so, how?
    **A:** Yes, `setInputFiles()` supports multiple file uploads. If the `<input type="file">` element has the `multiple` attribute, you can pass an array of file paths to `setInputFiles()`, like `await locator.setInputFiles(['path/to/file1.txt', 'path/to/file2.jpg'])`.

3.  **Q:** What if my application has a custom drag-and-drop file upload area instead of a standard input button? How would Playwright handle that?
    **A:** For custom drag-and-drop areas, `setInputFiles()` typically needs to be called on the *actual hidden `<input type="file">` element* that the custom component uses internally. If the custom component doesn't delegate to a standard file input but uses its own AJAX/fetch logic upon a drop event, direct `setInputFiles()` might not work. In such cases, you might need to inspect the network calls and potentially mock the file upload request or explore more advanced Playwright features for simulating drag-and-drop events if they trigger a hidden input. However, the first approach is to always look for and target the hidden `<input type="file">`.

4.  **Q:** How do you clear selected files from an input element using Playwright?
    **A:** You can clear selected files by calling `locator.setInputFiles([])` with an empty array. This will reset the file input element, effectively "deselecting" any previously chosen files.

## Hands-on Exercise
**Scenario:** You have a web page with an image upload form. The form has a file input for an avatar and displays a preview of the uploaded image.

**Task:**
1.  Create a new Playwright test file.
2.  Navigate to a test page (you can create a simple HTML string using `page.setContent()` as in the example or a local HTML file) that has:
    -   An `<input type="file" id="avatarUpload">` element.
    -   An `<img>` tag with `id="avatarPreview"` that updates its `src` attribute with the base64 representation or a URL of the uploaded image (simulate this if needed).
    -   A `<p id="uploadStatus">` to display a message like "Upload successful: [filename]".
3.  Create a dummy image file (e.g., `dummy-avatar.png`) in your test directory before the test runs and delete it afterwards.
4.  Write a Playwright test that:
    -   Uploads the `dummy-avatar.png` using `setInputFiles()`.
    -   Asserts that the `uploadStatus` element displays "Upload successful: dummy-avatar.png".
    -   Asserts that the `avatarPreview` image's `src` attribute is updated (e.g., checks if `src` contains 'data:image/png' or a specific filename part if it's a URL).

## Additional Resources
-   **Playwright `locator.setInputFiles()` documentation:** [https://playwright.dev/docs/api/class-locator#locator-set-input-files](https://playwright.dev/docs/api/class-locator#locator-set-input-files)
-   **Playwright File Uploads Guide:** [https://playwright.dev/docs/input#upload-files](https://playwright.dev/docs/input#upload-files)
---
# playwright-5.3-ac7.md

# Playwright: Handling File Downloads and Verification

## Overview
Automated testing of file download functionality is a crucial aspect of ensuring a robust user experience and data integrity. Users often rely on web applications to download reports, documents, images, or other files. As SDETs, we must ensure that these download processes work as expected, the correct files are downloaded, and their content is valid. Playwright provides powerful and intuitive APIs to effectively handle file downloads, allowing us to simulate user interactions and verify the outcomes seamlessly.

This section will cover how to listen for download events, trigger download actions, save downloaded files to a specified location, and perform essential verifications on the downloaded content.

## Detailed Explanation

Playwright simplifies the process of testing file downloads by providing an event-driven mechanism. When a user action triggers a download, Playwright emits a `download` event on the `page` object. We can listen for this event, retrieve the `Download` object, and then interact with the downloaded file.

Here's a breakdown of the key steps and concepts:

1.  **Setting up a Download Listener (`page.waitForEvent('download')`)**:
    Before performing the action that triggers the download (e.g., clicking a download link), you must set up an event listener to capture the `download` event. This is typically done using `page.waitForEvent('download')`. This method waits for the event to be emitted and returns a `Download` object when it occurs.

    ```typescript
    const [download] = await Promise.all([
      page.waitForEvent('download'), // Setup download listener
      page.click('a#download-link') // Action that triggers download
    ]);
    ```
    It's crucial to wrap the event listener and the trigger action in `Promise.all` to avoid race conditions. The event listener must be active *before* the download action is initiated.

2.  **Triggering the Download Action**:
    This involves simulating the user interaction that causes a file download. Common actions include:
    *   Clicking an `<a>` tag with a `download` attribute or a direct link to a file.
    *   Clicking a button that initiates a server-side file generation and download.
    *   Submitting a form that leads to a file download.

3.  **Saving the Download to a Specific Path (`download.saveAs(path)`)**:
    By default, Playwright downloads files to a temporary directory. This temporary location is available via `download.path()`. However, for verification, it's often more convenient and reliable to save the file to a known, accessible location on your local file system. The `download.saveAs(path)` method allows you to specify the destination path.

    ```typescript
    import * as fs from 'fs';
    import * as path from 'path';

    // ... inside your test
    const downloadsPath = path.join(__dirname, 'downloads');
    fs.mkdirSync(downloadsPath, { recursive: true }); // Ensure directory exists

    const filePath = path.join(downloadsPath, download.suggestedFilename());
    await download.saveAs(filePath);
    ```
    `download.suggestedFilename()` is useful as it provides the filename suggested by the browser, which often matches the original filename.

4.  **Verifying File Existence and Name**:
    After saving the file, you'll want to verify that it exists at the expected location and has the correct name. Node.js's built-in `fs` module is perfect for this.

    ```typescript
    import * as fs from 'fs';
    // ...
    expect(fs.existsSync(filePath)).toBeTruthy();
    expect(path.basename(filePath)).toBe('my_downloaded_file.pdf');
    ```

5.  **Additional Verifications (Size, Content, Type)**:
    Depending on the criticality of the download, you might need to perform more in-depth checks:
    *   **File Size**: `fs.statSync(filePath).size` can give you the file size in bytes.
    *   **File Content**: For text-based files (e.g., `.txt`, `.csv`, `.json`), you can read their content using `fs.readFileSync(filePath, 'utf-8')` and assert against expected content. For binary files, you might compare hashes or use specific libraries.
    *   **MIME Type**: While Playwright's `download.page()._actualMimeType()` or similar might give an indication, it's often more reliable to infer from the file extension or, for complex scenarios, use third-party libraries that analyze file headers.

## Code Implementation

This example demonstrates how to download a file from a hypothetical web page, save it, and perform basic verifications.

```typescript
import { test, expect, Page } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

// Define a temporary directory for downloads
const downloadsDir = path.join(__dirname, 'temp_downloads');

test.beforeAll(async () => {
  // Ensure the downloads directory exists before tests run
  fs.mkdirSync(downloadsDir, { recursive: true });
});

test.afterAll(async () => {
  // Clean up the downloads directory after all tests are done
  fs.rmSync(downloadsDir, { recursive: true, force: true });
});

test.describe('File Download Scenarios', () => {

  test('should download a text file and verify its content', async ({ page }) => {
    await page.goto('https://www.example.com/downloads'); // Replace with a real URL that offers downloads

    // Mock a download for demonstration purposes if a real one isn't available
    // In a real scenario, you'd click a link or button
    // For this example, let's assume 'https://www.example.com/downloads' has a link
    // <a id="downloadText" href="/path/to/sample.txt" download>Download Text File</a>

    // Setup an interception for the download URL to provide a mock response for testing
    // This is good for isolated unit tests, but for E2E, you'd let the real download happen.
    // For a real E2E test, ensure your page.goto() leads to a page where a download link exists.
    
    // Simulate a page with a download link (replace with your actual page logic)
    await page.setContent(`
      <a id="downloadLink" href="/files/sample.txt" download="sample_download.txt">Download Sample Text</a>
      <script>
        // Simulate a server providing the file content
        document.querySelector('#downloadLink').addEventListener('click', async (e) => {
          e.preventDefault();
          const content = "This is a sample text file content.";
          const blob = new Blob([content], { type: 'text/plain' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'sample_download.txt';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        });
      </script>
    `);


    // CRITICAL: Set up the download listener *before* triggering the download action
    const [download] = await Promise.all([
      page.waitForEvent('download'), // Wait for the download event
      page.click('#downloadLink')    // Click the element that initiates the download
    ]);

    // Verify download properties before saving
    expect(download.url()).toContain('/files/sample.txt'); // Or specific mock URL
    expect(download.suggestedFilename()).toBe('sample_download.txt');
    
    // Construct the full path where the file will be saved
    const filePath = path.join(downloadsDir, download.suggestedFilename());

    // Save the downloaded file to our designated temporary directory
    await download.saveAs(filePath);

    // Assert that the file exists and its content is as expected
    expect(fs.existsSync(filePath)).toBeTruthy();
    expect(fs.readFileSync(filePath, 'utf-8')).toBe('This is a sample text file content.');

    console.log(`Downloaded file: ${filePath}`);
  });

  test('should handle multiple downloads sequentially', async ({ page }) => {
    await page.goto('https://www.example.com/multi-downloads'); // Replace with a real URL

    await page.setContent(`
      <a id="downloadLink1" href="/files/file1.pdf" download="document_one.pdf">Download Document 1</a>
      <a id="downloadLink2" href="/files/file2.zip" download="archive_two.zip">Download Archive 2</a>
      <script>
        // Simulate server response for file1.pdf
        document.querySelector('#downloadLink1').addEventListener('click', async (e) => {
          e.preventDefault();
          const content = "PDF Content One";
          const blob = new Blob([content], { type: 'application/pdf' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'document_one.pdf';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        });

        // Simulate server response for file2.zip
        document.querySelector('#downloadLink2').addEventListener('click', async (e) => {
          e.preventDefault();
          const content = "ZIP Content Two";
          const blob = new Blob([content], { type: 'application/zip' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'archive_two.zip';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        });
      </script>
    `);


    // Download 1
    const [download1] = await Promise.all([
      page.waitForEvent('download'),
      page.click('#downloadLink1')
    ]);
    const filePath1 = path.join(downloadsDir, download1.suggestedFilename());
    await download1.saveAs(filePath1);
    expect(fs.existsSync(filePath1)).toBeTruthy();
    expect(path.basename(filePath1)).toBe('document_one.pdf');
    expect(fs.readFileSync(filePath1, 'utf-8')).toBe('PDF Content One');
    console.log(`Downloaded file 1: ${filePath1}`);

    // Download 2
    const [download2] = await Promise.all([
      page.waitForEvent('download'),
      page.click('#downloadLink2')
    ]);
    const filePath2 = path.join(downloadsDir, download2.suggestedFilename());
    await download2.saveAs(filePath2);
    expect(fs.existsSync(filePath2)).toBeTruthy();
    expect(path.basename(filePath2)).toBe('archive_two.zip');
    expect(fs.readFileSync(filePath2, 'utf-8')).toBe('ZIP Content Two');
    console.log(`Downloaded file 2: ${filePath2}`);
  });
});
```

## Best Practices
-   **Use Temporary Directories**: Always save downloaded files to a temporary, isolated directory (e.g., `temp_downloads` within your project or system temp directory) and clean it up after tests. This prevents test interference and keeps your file system tidy.
-   **Atomic Actions**: Combine `page.waitForEvent('download')` with the action triggering the download using `Promise.all` to prevent race conditions and ensure the listener is active before the download starts.
-   **Verify File Properties**: Beyond just existence, verify the filename, size (`download.size()`), and potentially the MIME type (`download.page()._actualMimeType()` or by reading file headers if critical).
-   **Content Verification**: For critical files, read and assert the content (e.g., for CSV, JSON, or text files). For binary files, consider checking file integrity via hash comparison if the expected hash is known.
-   **Handle Timeouts**: Downloads can sometimes be slow. Playwright's `waitForEvent` has a default timeout, but you might need to adjust it for very large files using the `timeout` option.
-   **Error Handling**: Consider scenarios where a download might fail (e.g., server error, file not found). Your tests should ideally cover these negative cases.

## Common Pitfalls
-   **Race Conditions**: Not setting up `page.waitForEvent('download')` *before* the action that triggers the download. This leads to the event being missed by the listener. Always use `Promise.all`.
-   **Permissions Issues**: The user running the test might not have write permissions to the directory specified in `saveAs()`, leading to test failures. Ensure the target directory is writable.
-   **Assuming Immediate Completion**: Downloads, especially large ones, take time. `download.saveAs()` is an async operation that waits for the download to complete before saving. However, always ensure your subsequent assertions properly await this.
-   **Incorrect File Path/Name**: Mismatches between `download.suggestedFilename()` and the actual file saved, or issues with path concatenation, can lead to `file not found` errors during verification.
-   **Cleanup Failure**: Not cleaning up temporary download directories can clutter your system over time and might cause unexpected behavior in subsequent test runs.

## Interview Questions & Answers

1.  **Q: How do you handle file downloads in Playwright, and what are the key steps involved?**
    **A:** In Playwright, file downloads are handled using the `page.waitForEvent('download')` method. The key steps are:
    1.  **Set up a listener**: Use `page.waitForEvent('download')` *before* initiating the download action.
    2.  **Trigger the download**: Perform the action (e.g., `page.click()`) that causes the file to download. It's crucial to wrap the listener and trigger in `Promise.all` to prevent race conditions.
    3.  **Get the Download object**: The listener returns a `Download` object, which provides access to download metadata.
    4.  **Save the file**: Use `download.saveAs(filePath)` to save the file to a specific location. By default, Playwright downloads to a temporary directory.
    5.  **Verify the file**: Use Node.js `fs` module to check for file existence, name, size, and content.
    6.  **Cleanup**: Remove the downloaded file and any temporary directories after the test.

2.  **Q: What are some common challenges or considerations when testing file downloads in an automated framework like Playwright?**
    **A:**
    *   **Race Conditions**: Ensuring the download listener is active *before* the download trigger occurs. `Promise.all` is the solution.
    *   **Download Timeouts**: Large files or slow network conditions can cause downloads to exceed default timeouts. Adjusting `waitForEvent` timeout is necessary.
    *   **Temporary File Handling**: Managing temporary directories and ensuring proper cleanup after tests to maintain a clean environment.
    *   **Content Verification**: For complex or dynamic files, verifying the actual content can be challenging, often requiring parsing libraries or robust comparison logic (e.g., comparing hashes for binary files).
    *   **Browser Prompts**: Some downloads might trigger browser prompts (e.g., "Do you want to save this file?"). Playwright handles most standard download flows automatically, but complex prompts might require specific handling or browser options to bypass.
    *   **Server-Side Generation**: Downloads often involve server-side file generation, which can introduce latency and requires robust waiting mechanisms.

3.  **Q: How would you verify the content of a downloaded CSV file in Playwright?**
    **A:** To verify the content of a downloaded CSV file:
    1.  First, ensure the file is downloaded and saved to a known path using `page.waitForEvent('download')` and `download.saveAs(filePath)`.
    2.  Then, use Node.js's `fs.readFileSync(filePath, 'utf-8')` to read the entire content of the CSV file as a string.
    3.  You can then parse this string using a CSV parsing library (e.g., `csv-parse` for Node.js) to convert it into an array of objects or arrays.
    4.  Finally, assert that the parsed data matches your expected data structure and values. This might involve checking row counts, specific cell values, or comparing the entire parsed object against a predefined expected object.

## Hands-on Exercise

**Scenario**: You need to test a web application that allows users to export a list of products as a CSV file.

**Task**:
1.  Navigate to a mock product listing page (you can create a simple `index.html` locally or use a public test site if available).
2.  Locate and click the "Export to CSV" button/link.
3.  Wait for the CSV file to download.
4.  Save the downloaded file to a `temp_downloads` directory within your project.
5.  Verify the following:
    *   The file `products.csv` exists in the `temp_downloads` directory.
    *   The file's suggested filename is `products.csv`.
    *   The content of the CSV file contains a specific header (e.g., "Product Name,Price,Quantity").
    *   The content contains at least two product entries.
6.  Clean up the `temp_downloads` directory after the test.

**Hint**: For the mock page, you can use `page.setContent()` to create a simple HTML structure with an export link that simulates a download by creating a Blob and triggering a click.

## Additional Resources
-   **Playwright Downloads Documentation**: [https://playwright.dev/docs/downloads](https://playwright.dev/docs/downloads)
-   **Node.js File System Module (fs)**: [https://nodejs.org/docs/latest/api/fs.html](https://nodejs.org/docs/latest/api/fs.html)
-   **Playwright Test Runner Documentation**: [https://playwright.dev/docs/test-intro](https://playwright.dev/docs/test-intro)
---
# playwright-5.3-ac8.md

# Handling Iframes with Playwright's `frameLocator()`

## Overview
Iframes (inline frames) are HTML documents embedded within another HTML document. They are commonly used to embed content from another source, like videos, advertisements, or even entire applications, into a web page. Interacting with elements inside an iframe can be tricky because they exist in a separate browsing context. Playwright provides the `frameLocator()` method, which simplifies locating and interacting with elements within iframes, including nested ones, making test automation more robust and readable.

## Detailed Explanation
Playwright's `frameLocator(selector)` method allows you to target an iframe based on its selector (e.g., CSS selector, XPath, or its name/URL). Once you have a `FrameLocator`, you can then chain further locators (like `locator()`, `getByText()`, etc.) to interact with elements inside that specific frame. This approach is more resilient to changes in the iframe's content or structure compared to older methods that might rely on frame indices or specific URLs.

### Locating an Iframe
You can locate an iframe using various selectors:
- **By CSS selector**: `page.frameLocator('iframe[title="Payment form"]')`
- **By XPath**: `page.frameLocator('xpath=//iframe[@id="my-iframe"]')`
- **By URL (partial match)**: `page.frameLocator('iframe[src*="example.com/payment"]')`
- **By Name**: `page.frameLocator('[name="myFrame"]')`

### Interacting with Elements Inside a Frame
Once the frame is located, you can interact with its elements as you would with any other element on the page, by chaining locators:
`page.frameLocator('iframe[name="myFrame"]').locator('input#username').fill('testuser');`

### Handling Nested Frames
Playwright's `frameLocator()` is designed to handle nested frames seamlessly. You just chain `frameLocator()` calls:
`page.frameLocator('iframe#parentFrame').frameLocator('iframe#childFrame').locator('button#submit').click();`

### Asserting State of Elements Inside a Frame
Assertions also follow the same pattern, chaining locators after `frameLocator()`:
`await expect(page.frameLocator('iframe[name="myFrame"]').locator('#welcomeMessage')).toHaveText('Welcome, Test User!');`

## Code Implementation

This example demonstrates how to interact with an iframe, specifically a payment form embedded in a simulated e-commerce page.

```typescript
import { test, expect, Page } from '@playwright/test';

test.describe('Iframe Interactions', () => {
    let page: Page;

    test.beforeEach(async ({ browser }) => {
        page = await browser.newPage();
        // Simulate a page with an iframe. In a real scenario, you would navigate to a URL.
        await page.setContent(`
            <h1>Welcome to Our Shop</h1>
            <p>Please enter your payment details below:</p>
            <iframe 
                id="payment-iframe" 
                name="paymentFrame" 
                title="Secure Payment Form" 
                srcdoc="
                    <html lang='en'>
                    <head><title>Payment Form</title></head>
                    <body>
                        <h2>Payment Details</h2>
                        <label for='card-number'>Card Number:</label>
                        <input type='text' id='card-number' name='cardNumber' placeholder='1234 5678 9012 3456'>
                        <br><br>
                        <label for='expiry-date'>Expiry Date:</label>
                        <input type='text' id='expiry-date' name='expiryDate' placeholder='MM/YY'>
                        <br><br>
                        <button id='submit-payment'>Submit Payment</button>
                        <div id='payment-status' style='margin-top: 10px; color: green;'></div>
                    </body>
                    </html>
                " 
                style="width:500px; height:300px; border: 1px solid #ccc;">
            </iframe>
            <div id="main-page-status">Order Summary</div>
        `);
    });

    test('should interact with elements inside a single iframe', async () => {
        // Locate the iframe using its ID
        const paymentFrame = page.frameLocator('#payment-iframe');

        // Interact with elements inside the iframe
        await paymentFrame.locator('#card-number').fill('1111222233334444');
        await paymentFrame.locator('#expiry-date').fill('12/25');
        await paymentFrame.locator('#submit-payment').click();

        // Assert the state of an element inside the iframe
        await expect(paymentFrame.locator('#payment-status')).toHaveText('Payment successful!'); 
        // Note: In this simulated example, the text won't change unless we add JS to the srcdoc.
        // For a real application, the iframe's content would update dynamically.
        console.log('Interacted with elements and asserted state within the iframe.');

        // Verify that we can still interact with elements outside the iframe
        await expect(page.locator('#main-page-status')).toHaveText('Order Summary');
    });

    test('should handle nested iframes', async () => {
        // Create a page with nested iframes
        await page.setContent(`
            <h1>Main Page - Nested Frames Example</h1>
            <iframe id="parent-iframe" name="parentFrame" srcdoc="
                <html lang='en'>
                <head><title>Parent Frame</title></head>
                <body>
                    <h3>Parent Frame Content</h3>
                    <iframe id='child-iframe' name='childFrame' srcdoc='
                        <html lang='en'>
                        <head><title>Child Frame</title></head>
                        <body>
                            <h4>Child Frame Content</h4>
                            <input type='text' id='child-input' placeholder='Enter text in child frame'>
                            <button id='child-button'>Click Child</button>
                            <p id='child-message'></p>
                        </body>
                        </html>
                    ' style='width:300px; height:150px; border: 1px dashed blue;'></iframe>
                    <p id='parent-message'></p>
                </body>
                </html>
            " style="width:600px; height:400px; border: 2px solid red;"></iframe>
        `);

        // Locate the parent iframe
        const parentFrame = page.frameLocator('#parent-iframe');
        // Locate the child iframe within the parent iframe
        const childFrame = parentFrame.frameLocator('#child-iframe');

        // Interact with element in child iframe
        await childFrame.locator('#child-input').fill('Hello from Playwright!');
        await childFrame.locator('#child-button').click();

        // Assert state in child iframe
        await expect(childFrame.locator('#child-message')).toBeVisible(); // Just check visibility for this example
        console.log('Interacted with elements and asserted state within nested iframes.');

        // Interact with elements in parent iframe (outside the child iframe)
        await parentFrame.locator('#parent-message').fill('Interaction in parent frame too.');
        await expect(parentFrame.locator('#parent-message')).toHaveValue('Interaction in parent frame too.');
    });
});
```

## Best Practices
- **Use `frameLocator()` for clarity and robustness**: It's the recommended modern approach in Playwright for iframe handling, providing a more readable and maintainable way to interact with frames compared to `frame()` by URL or index.
- **Prefer unique iframe attributes for location**: Use `id`, `name`, `title`, or a unique CSS selector to locate the iframe. Avoid relying on index if possible, as it can be brittle if the page structure changes.
- **Chain locators**: After locating the frame, continue to use Playwright's powerful locators (`locator()`, `getByRole()`, `getByText()`, etc.) to interact with elements inside it.
- **Be mindful of multiple iframes**: If there are multiple iframes on a page, ensure your `frameLocator()` selector is specific enough to target the correct one.
- **Wait for elements inside iframes**: Just like regular page elements, elements inside iframes might take time to load. Playwright's auto-waiting mechanism handles this implicitly with locators, but explicit waits can be used if necessary.

## Common Pitfalls
- **Incorrect iframe selector**: If the `frameLocator()` selector doesn't match the iframe element, Playwright won't be able to find the frame, leading to errors when trying to interact with elements inside it.
- **Forgetting `frameLocator()`**: A common mistake is to try to interact with iframe elements directly using `page.locator()` without first specifying the frame. This will fail because the elements are in a different DOM context.
- **Synchronization issues**: Although Playwright handles auto-waiting, complex iframe loading scenarios (e.g., dynamically loaded iframes or iframes that load their content slowly) might still require careful handling to ensure the iframe and its contents are fully ready before interaction.
- **Security restrictions (CORS)**: Be aware that cross-origin iframes may have security restrictions (e.g., same-origin policy) that prevent Playwright from accessing their content directly if the test environment security settings are strict. This is more of a browser security model consideration than a Playwright limitation.
- **Invisible iframes**: Sometimes iframes are hidden or have zero dimensions. Ensure the iframe is visible and has a layout before attempting to interact with it, especially in visual testing.

## Interview Questions & Answers
1. Q: How do you handle iframes in Playwright tests?
   A: In Playwright, the primary and most robust way to handle iframes is by using `page.frameLocator(selector)`. This method returns a `FrameLocator` which then allows you to use standard Playwright locators (like `locator()`, `getByRole()`, etc.) to interact with elements inside that specific iframe. This approach is superior because it directly targets the iframe element and handles the context switching implicitly.

2. Q: What is `frameLocator()` and why is it preferred over `page.frame()`?
   A: `frameLocator()` is a method that returns a `FrameLocator` object, representing an iframe in the DOM. It's preferred over `page.frame(options)` (which finds a frame by name/URL) because `frameLocator()` targets the `<iframe>` HTML element itself, making tests more resilient to changes in the iframe's content URL or its name if the iframe itself can be reliably located on the page. It's also more aligned with Playwright's locator-first philosophy for better test readability and stability.

3. Q: How would you interact with an element inside a nested iframe using Playwright?
   A: To interact with an element in a nested iframe, you would chain `frameLocator()` calls. First, locate the parent iframe, then from that `FrameLocator`, locate the child iframe, and finally, locate the target element within the child iframe. For example: `page.frameLocator('#parent-iframe').frameLocator('#child-iframe').locator('input#element-id').fill('text');`

## Hands-on Exercise
**Scenario:** Imagine a customer support portal where chat functionality is embedded within an iframe, and a knowledge base search is within a nested iframe inside the chat frame.

**Task:**
1. Navigate to a hypothetical page (you can use `page.setContent()` as in the example) that contains:
    - A main page title "Customer Support".
    - An iframe with `id="chat-widget"` and `title="Support Chat"`.
    - Inside the chat-widget iframe, another iframe with `id="kb-search"` and `title="Knowledge Base Search"`.
    - Inside the `kb-search` iframe, an input field with `id="search-input"` and a button with `id="search-button"`.
2. Write Playwright code to:
    - Type "troubleshooting login" into the `search-input` field within the `kb-search` iframe.
    - Click the `search-button`.
    - Assert that a specific message appears (e.g., "Searching for: troubleshooting login") within the `kb-search` iframe after clicking the button.
    - Assert that the main page title is still visible and correct.

## Additional Resources
- **Playwright Official Documentation - Frames**: [https://playwright.dev/docs/frames](https://playwright.dev/docs/frames)
- **Playwright `frameLocator()` API Reference**: [https://playwright.dev/docs/api/class-framelocator](https://playwright.dev/docs/api/class-framelocator)
- **MDN Web Docs - HTML `<iframe>` element**: [https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe)
---
# playwright-5.3-ac9.md

# Playwright: Handling Shadow DOM Elements

## Overview
Shadow DOM is a web standard that allows web component developers to encapsulate their component's internal structure, style, and behavior, isolating it from the main document's DOM. This encapsulation prevents CSS styles and JavaScript from "leaking" out of or into the component, ensuring component integrity and reusability. For test automation engineers, interacting with elements inside a Shadow DOM can be challenging if the automation tool doesn't explicitly support it. Playwright, however, offers robust, automatic handling of Shadow DOM, often "piercing" through it without requiring special commands, simplifying element selection and interaction.

Understanding how to interact with Shadow DOM is crucial for testing modern web applications built with web components, frameworks like Lit, or even some aspects of popular libraries like React (though less common for direct Shadow DOM usage). A senior SDET must be proficient in identifying and interacting with these encapsulated elements to ensure comprehensive test coverage.

## Detailed Explanation
Playwright's philosophy is to "just work" with Shadow DOM. By default, Playwright automatically pierces through open Shadow DOM roots when using standard locators like `page.locator()`. This means you can often select elements inside a Shadow DOM using their regular CSS selectors or text content as if they were part of the main document. Playwright's selector engine automatically traverses into shadow roots attached with `mode: 'open'`.

However, it's important to note that Playwright cannot pierce through "closed" Shadow DOM roots, as these are intentionally inaccessible even to JavaScript on the page, let alone automation tools. In practice, most web components use "open" Shadow DOM for better developer tooling and accessibility.

### Selecting Elements Inside Shadow Root Directly
Consider a scenario where you have a custom element `<my-component>` which internally uses a Shadow DOM to render a button.

```html
<!-- index.html -->
<!DOCTYPE html>
<html>
<head>
    <title>Shadow DOM Test Page</title>
    <style>
        body { font-family: sans-serif; }
    </style>
</head>
<body>
    <h1>Testing Shadow DOM Interactions</h1>
    <div id="app"></div>

    <script>
        class MyComponent extends HTMLElement {
            constructor() {
                super();
                const shadow = this.attachShadow({ mode: 'open' }); // Open Shadow DOM
                shadow.innerHTML = `
                    <style>
                        button {
                            background-color: #4CAF50;
                            color: white;
                            padding: 10px 20px;
                            border: none;
                            border-radius: 5px;
                            cursor: pointer;
                        }
                        button:hover {
                            background-color: #45a049;
                        }
                        div {
                            border: 1px solid blue;
                            padding: 10px;
                            margin: 10px 0;
                        }
                    </style>
                    <div>
                        <p>Content inside Shadow DOM</p>
                        <button id="shadowButton">Click Me (Shadow)</button>
                        <slot></slot> <!-- Used for light DOM content -->
                    </div>
                `;
            }
        }
        customElements.define('my-component', MyComponent);

        document.getElementById('app').innerHTML = `
            <my-component>
                <p slot="footer">This is slotted content (Light DOM within Shadow Host)</p>
            </my-component>
            <button id="regularButton">Regular Button (Light DOM)</button>
        `;
    </script>
</body>
</html>
```

In Playwright, you can directly locate the `shadowButton` without any special syntax:

```typescript
// playwright-shadow-dom.spec.ts
import { test, expect } from '@playwright/test';

test('should interact with elements inside Shadow DOM', async ({ page }) => {
    await page.goto('http://localhost:8080/index.html'); // Assuming your HTML is served locally

    // Locate and click the button inside the Shadow DOM
    const shadowButton = page.locator('my-component').locator('#shadowButton');
    await expect(shadowButton).toBeVisible();
    await shadowButton.click();
    console.log('Clicked button inside Shadow DOM');

    // You can also use a direct CSS selector if it's unique enough across Shadow DOMs
    // Playwright automatically pierces open shadow roots
    const directShadowButton = page.locator('#shadowButton');
    await expect(directShadowButton).toBeVisible(); // This will find the button if it's unique enough

    // Verify interaction (e.g., by checking a side effect or console log if applicable)
    // For this example, we'll just assert its visibility and successful click above.

    // Locate and interact with a regular button (Light DOM)
    const regularButton = page.locator('#regularButton');
    await expect(regularButton).toBeVisible();
    await regularButton.click();
    console.log('Clicked regular button');

    // Example of verifying text content inside shadow DOM
    const shadowParagraph = page.locator('my-component >> text=Content inside Shadow DOM');
    await expect(shadowParagraph).toBeVisible();
    await expect(shadowParagraph).toHaveText('Content inside Shadow DOM');
});
```

To run this example:
1.  Save the HTML content as `index.html` in your project root.
2.  Serve the `index.html` file using a simple HTTP server (e.g., `npx http-server .` or a Live Server extension in VS Code).
3.  Save the TypeScript code as `playwright-shadow-dom.spec.ts` in your `tests` folder.
4.  Run `npx playwright test playwright-shadow-dom.spec.ts`.

Playwright's auto-piercing mechanism handles the traversal, making the selector syntax clean and familiar. When `page.locator('my-component').locator('#shadowButton')` is used, Playwright first finds the custom element (`my-component`) and then, understanding that it has an open Shadow DOM, it searches for `#shadowButton` *within that Shadow DOM*.

### Verify behavior on a page with Shadow DOM
To verify the behavior, you typically interact with the elements and then assert on the visible state of the application or the effects of the interaction. Since Shadow DOM encapsulates styling and behavior, the "visible state" might be a change in the text content, the presence of a new element in the light DOM triggered by a shadow DOM interaction, or a change in an attribute.

In the example above, the verification mainly involves asserting that the buttons are visible and that clicks are performed. If clicking the shadow button triggered an alert, a text update in the light DOM, or an API call, you would assert on those effects.

For instance, if clicking `shadowButton` updated a paragraph in the light DOM:

```html
<!-- Add this to index.html within the script tag -->
document.addEventListener('DOMContentLoaded', () => {
    const myComponent = document.querySelector('my-component');
    myComponent.shadowRoot.querySelector('#shadowButton').addEventListener('click', () => {
        document.getElementById('status').textContent = 'Shadow Button Clicked!';
    });
});
```
And in `index.html` body:
```html
<p id="status">No button clicked yet.</p>
```

Then your Playwright test would verify:
```typescript
await page.locator('#shadowButton').click();
await expect(page.locator('#status')).toHaveText('Shadow Button Clicked!');
```

## Code Implementation

```typescript
// playwright-shadow-dom.spec.ts

import { test, expect } from '@playwright/test';
import * as http from 'http'; // For simple local server
import * as fs from 'fs';
import * as path from 'path';

let server: http.Server;
const PORT = 8080;
const HTML_FILE_PATH = path.join(__dirname, 'shadow-dom-test.html');

// Setup a simple HTTP server to serve the HTML file
test.beforeAll(async () => {
    const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
            <title>Shadow DOM Test Page</title>
            <style>
                body { font-family: sans-serif; margin: 20px; }
                h1 { color: #333; }
                #app { border: 1px dashed #ccc; padding: 15px; margin-top: 20px; }
                #status { margin-top: 20px; font-weight: bold; color: blue; }
            </style>
        </head>
        <body>
            <h1>Testing Shadow DOM Interactions with Playwright</h1>
            <p>This page contains a custom element using Shadow DOM.</p>
            <div id="app"></div>
            <button id="regularButton">Regular Button (Light DOM)</button>
            <p id="status">No button clicked yet.</p>

            <script>
                class MyComponent extends HTMLElement {
                    constructor() {
                        super();
                        // Attach open Shadow DOM
                        const shadow = this.attachShadow({ mode: 'open' });
                        shadow.innerHTML = `
                            <style>
                                :host { /* Styles for the custom element itself */
                                    display: block;
                                    border: 2px solid purple;
                                    padding: 15px;
                                    margin-bottom: 15px;
                                    background-color: #f0f0f0;
                                }
                                button {
                                    background-color: #2196F3; /* Blue */
                                    color: white;
                                    padding: 10px 20px;
                                    border: none;
                                    border-radius: 4px;
                                    cursor: pointer;
                                    font-size: 16px;
                                    margin-right: 10px;
                                }
                                button:hover {
                                    background-color: #0b7dda;
                                }
                                .shadow-content {
                                    padding: 10px;
                                    border: 1px solid green;
                                    margin-bottom: 10px;
                                    background-color: #e8ffe8;
                                }
                            </style>
                            <div class="shadow-content">
                                <p>This text is <strong>inside the Shadow DOM</strong>.</p>
                                <button id="shadowButton">Click Shadow Button</button>
                                <button id="anotherShadowButton">Another Shadow Button</button>
                                <slot></slot> <!-- Renders light DOM children -->
                            </div>
                        `;
                    }
                }
                customElements.define('my-component', MyComponent);

                document.addEventListener('DOMContentLoaded', () => {
                    document.getElementById('app').innerHTML = `
                        <my-component>
                            <p slot="description">This is slotted content (Light DOM, rendered within Shadow DOM)</p>
                        </my-component>
                    `;

                    // Add event listeners for interaction verification
                    const myComponent = document.querySelector('my-component');
                    if (myComponent && myComponent.shadowRoot) {
                        myComponent.shadowRoot.querySelector('#shadowButton').addEventListener('click', () => {
                            document.getElementById('status').textContent = 'Shadow Button Clicked!';
                        });
                        myComponent.shadowRoot.querySelector('#anotherShadowButton').addEventListener('click', () => {
                            document.getElementById('status').textContent = 'Another Shadow Button Clicked!';
                        });
                    }
                    document.getElementById('regularButton').addEventListener('click', () => {
                        document.getElementById('status').textContent = 'Regular Button Clicked!';
                    });
                });
            </script>
        </body>
        </html>
    `;

    // Write the HTML content to a temporary file
    fs.writeFileSync(HTML_FILE_PATH, htmlContent);

    server = http.createServer((req, res) => {
        if (req.url === '/') {
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(fs.readFileSync(HTML_FILE_PATH));
        } else {
            res.writeHead(404);
            res.end();
        }
    });

    server.listen(PORT, () => {
        console.log(`Test server running at http://localhost:${PORT}`);
    });
});

test.afterAll(async () => {
    server.close(() => {
        console.log('Test server closed.');
        // Clean up the temporary HTML file
        fs.unlinkSync(HTML_FILE_PATH);
    });
});

test.describe('Shadow DOM Interaction Tests', () => {
    test.beforeEach(async ({ page }) => {
        // Navigate to the test page before each test
        await page.goto(`http://localhost:${PORT}`);
        // Ensure the component is loaded and visible
        await expect(page.locator('my-component')).toBeVisible();
    });

    test('should click the button inside the Shadow DOM using direct CSS selector', async ({ page }) => {
        // Playwright automatically pierces open shadow roots
        const shadowButton = page.locator('#shadowButton'); // Finds it directly within the Shadow DOM
        await expect(shadowButton).toBeVisible();
        await shadowButton.click();

        // Verify the effect in the Light DOM (status paragraph updated)
        await expect(page.locator('#status')).toHaveText('Shadow Button Clicked!');
        console.log('Successfully clicked shadowButton and verified status update.');
    });

    test('should click another button inside the Shadow DOM using chained locators', async ({ page }) => {
        // Using chained locators for more specificity, though often not strictly necessary
        const anotherShadowButton = page.locator('my-component').locator('#anotherShadowButton');
        await expect(anotherShadowButton).toBeVisible();
        await anotherShadowButton.click();

        // Verify the effect
        await expect(page.locator('#status')).toHaveText('Another Shadow Button Clicked!');
        console.log('Successfully clicked anotherShadowButton and verified status update.');
    });

    test('should verify text content inside the Shadow DOM', async ({ page }) => {
        // Asserting text visibility within the shadow root
        const shadowText = page.locator('my-component >> text=inside the Shadow DOM');
        await expect(shadowText).toBeVisible();
        await expect(shadowText).toContainText('inside the Shadow DOM');
        console.log('Verified text content inside Shadow DOM.');
    });

    test('should differentiate between light DOM and shadow DOM elements with same ID', async ({ page }) => {
        // If there were an element with #shadowButton in both light and shadow DOMs,
        // Playwright's behavior can depend on context. For this test, we have unique IDs.
        // This test ensures our regular button still works as expected.
        const regularButton = page.locator('#regularButton');
        await expect(regularButton).toBeVisible();
        await regularButton.click();

        await expect(page.locator('#status')).toHaveText('Regular Button Clicked!');
        console.log('Successfully clicked regular button and verified status update.');
    });

    test('should interact with slotted content (Light DOM within Shadow Host)', async ({ page }) => {
        // Slotted content is Light DOM that is rendered *through* the Shadow DOM.
        // It's part of the Light DOM, so regular selectors work.
        const slottedContent = page.locator('my-component >> text=This is slotted content');
        await expect(slottedContent).toBeVisible();
        await expect(slottedContent).toHaveText('This is slotted content (Light DOM, rendered within Shadow DOM)');
        console.log('Verified interaction with slotted content.');
    });
});
```

## Best Practices
-   **Prefer Playwright's Auto-Piercing:** Leverage Playwright's ability to automatically traverse open Shadow DOMs. Avoid overly complex selectors when simple ones work.
-   **Use Chained Locators for Clarity:** While `page.locator('#shadowButton')` might work, `page.locator('my-component').locator('#shadowButton')` provides better readability and context, especially in complex components or when IDs might not be globally unique.
-   **Understand Open vs. Closed Shadow DOM:** Playwright only works with `mode: 'open'` Shadow DOMs. Be aware that `mode: 'closed'` Shadow DOMs are intentionally inaccessible and cannot be directly automated. (These are rare in practice for testable components).
-   **Prioritize Semantic Locators:** Even within Shadow DOM, try to use role, text, or test IDs (`data-test-id`) instead of brittle CSS selectors based on generated class names. Playwright's `getBy*` locators (e.g., `getByRole`, `getByText`, `getByTestId`) are excellent for this.
-   **Encapsulate Component Interactions:** If you frequently interact with a custom web component, consider creating a Page Object Model (POM) for that component. The POM would encapsulate the selectors and interaction methods for its internal Shadow DOM elements, making your tests cleaner and more maintainable.

## Common Pitfalls
-   **Assuming Closed Shadow DOM:** Mistaking an open Shadow DOM for a closed one and trying to use complex JavaScript executions to bypass it, when Playwright can handle it directly.
-   **Overly Specific CSS Selectors:** Relying on deeply nested CSS selectors for Shadow DOM elements can make tests brittle if the internal structure of the component changes.
-   **Timing Issues:** Shadow DOM content, like any other dynamically loaded content, might not be immediately available. Use Playwright's auto-waiting mechanisms (e.g., `expect(locator).toBeVisible()`, `await locator.click()`) to handle this.
-   **Not Running a Local Server:** When testing local HTML files with custom elements or scripts, simply opening `file://` paths might lead to security restrictions or incorrect script execution. Always serve your test HTML over `http://` for reliable testing.

## Interview Questions & Answers
1.  **Q: What is Shadow DOM, and why is it used in web development?**
    **A:** Shadow DOM is a web standard that provides component encapsulation. It allows developers to attach a separate DOM tree to an element (the "shadow host"), which is rendered separately from the main document DOM. This "shadow tree" can have its own styles and scripts that are scoped only to that tree, preventing conflicts with the main document or other components. It's used to build robust, reusable web components by isolating their internal structure, styles, and behavior, enhancing modularity and maintainability.

2.  **Q: How does Playwright interact with elements inside a Shadow DOM? Does it require any special handling?**
    **A:** Playwright automatically "pierces" open Shadow DOM roots. For `mode: 'open'` Shadow DOMs, you can use standard Playwright locators (like CSS selectors, text locators, or `getBy*` methods) directly, and Playwright's engine will traverse into the shadow tree to find the element. No special commands or custom JavaScript execution are typically required. However, Playwright cannot interact with `mode: 'closed'` Shadow DOMs, as they are intentionally inaccessible even to page-level JavaScript.

3.  **Q: Can you give an example of a Playwright locator for an element within a Shadow DOM, assuming a custom component `<my-app>` contains a button with `id="submitButton"` in its shadow root?**
    **A:** A simple and effective locator would be `page.locator('#submitButton')`. Playwright will automatically find it if `my-app` has an open Shadow DOM. For more explicit targeting, you could use `page.locator('my-app').locator('#submitButton')`. If you're using `data-test-id`, it would be `page.getByTestId('submitButton')`.

## Hands-on Exercise
**Scenario:** You have a web page with a custom `<user-profile>` component. This component has an open Shadow DOM containing:
*   A `div` with class `profile-card`.
*   Inside `profile-card`, a `span` with `id="username"` displaying "John Doe".
*   A `button` with `id="editProfileButton"`.

**Task:**
1.  Create an HTML file (`profile.html`) that defines and uses this `<user-profile>` custom element. Ensure the Shadow DOM is `mode: 'open'`.
2.  Write a Playwright test file (`user-profile.spec.ts`) that:
    *   Navigates to `profile.html` (you'll need to serve it locally, as in the example).
    *   Verifies that the "John Doe" text is visible within the `username` span inside the Shadow DOM.
    *   Clicks the "Edit Profile" button inside the Shadow DOM.
    *   (Optional but recommended) Add an event listener to the `editProfileButton` that updates a visible element in the Light DOM (e.g., a status message) and assert that this status message changes after the click.

## Additional Resources
-   **Playwright Locators:** [https://playwright.dev/docs/locators](https://playwright.dev/docs/locators) (See "Locating elements in Shadow DOM" section)
-   **MDN Web Docs: Using Shadow DOM:** [https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_shadow_DOM](https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_shadow_DOM)
-   **Web Components Standard:** [https://www.webcomponents.org/](https://www.webcomponents.org/)
---
# playwright-5.3-ac10.md

# Playwright: Taking Screenshots and Recording Videos

## Overview
In modern test automation, visual validation and debugging are crucial. Playwright provides robust capabilities to capture screenshots of web pages or specific elements, and to record videos of test executions. These features are invaluable for identifying UI regressions, understanding test failures, and providing clear evidence of application behavior.

## Detailed Explanation

### Capturing Full Page Screenshot
Playwright's `page.screenshot()` method allows capturing a screenshot of the entire viewport or the full scrollable page. This is particularly useful for visual regression testing or for documenting the state of a page at a specific point in a test.

Key options:
- `path`: (Required) The file path to save the screenshot to (e.g., `'./screenshots/full-page.png'`).
- `fullPage`: (Optional) When set to `true`, takes a screenshot of the full scrollable page, not just the viewport. Defaults to `false`.
- `omitBackground`: (Optional) Hides the default white background and allows capturing screenshots with transparency. Defaults to `false`.
- `animations`: (Optional) Whether to disable CSS animations. Defaults to `false`.
- `caret`: (Optional) Whether to hide text caret. Defaults to `true`.
- `mask`: (Optional) Specify a list of selectors that should be masked when the screenshot is taken.
- `scale`: (Optional) Scale the screenshot to a specific device pixel ratio. Defaults to the device's pixel ratio.
- `timeout`: (Optional) Maximum time in milliseconds for the operation. Defaults to `30000` (30 seconds).

### Capturing Element Screenshot
Sometimes, only a specific component or element's visual state needs to be verified. Playwright allows taking screenshots of individual elements using `elementHandle.screenshot()` or by calling `locator.screenshot()`.

### Recording Videos
Video recording is an excellent debugging aid. When a test fails, watching a video of the execution can quickly reveal the root cause, especially for flaky tests or complex user interactions. Playwright integrates video recording directly into the browser context.

To enable video recording, you need to configure it when launching the browser or creating a new browser context. The video files are typically saved in a temporary directory and can be accessed via `artifactPath` once the test run is complete or the browser context is closed.

## Code Implementation

```typescript
import { test, expect, Browser, BrowserContext, Page } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

// Define paths for screenshots and videos
const screenshotsDir = 'test-results/screenshots';
const videosDir = 'test-results/videos';

// Ensure directories exist before tests run
test.beforeAll(async () => {
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir, { recursive: true });
  }
  if (!fs.existsSync(videosDir)) {
    fs.mkdirSync(videosDir, { recursive: true });
  }
});

test.describe('Screenshot and Video Recording', () => {
  let browser: Browser;
  let context: BrowserContext;
  let page: Page;

  test.beforeEach(async ({ playwright }) => {
    browser = await playwright.chromium.launch();
    // Configure video recording for the context
    context = await browser.newContext({
      recordVideo: {
        dir: videosDir, // Directory to save videos
        size: { width: 1280, height: 720 }, // Video resolution
      },
    });
    page = await context.newPage();
  });

  test.afterEach(async () => {
    // Save video after test (Playwright automatically saves on context close)
    // You can access the video path via context.video()
    const videoPath = await page.video()?.path();
    if (videoPath) {
      console.log(`Video saved at: ${videoPath}`);
      // If you need to move/rename the video, do it here.
      // Example: fs.renameSync(videoPath, path.join(videosDir, `test-video-${Date.now()}.webm`));
    }
    await context.close();
    await browser.close();
  });

  test('should capture full page screenshot and element screenshot', async () => {
    await page.goto('https://playwright.dev/docs/screenshots');

    // 1. Capture full page screenshot
    const fullPageScreenshotPath = path.join(screenshotsDir, 'playwright-docs-full.png');
    await page.screenshot({ path: fullPageScreenshotPath, fullPage: true });
    console.log(`Full page screenshot saved: ${fullPageScreenshotPath}`);
    expect(fs.existsSync(fullPageScreenshotPath)).toBeTruthy();

    // 2. Capture element screenshot
    // Using locator for element screenshot
    const element = page.locator('nav.navbar'); // Example: screenshot the navigation bar
    const elementScreenshotPath = path.join(screenshotsDir, 'playwright-navbar.png');
    await element.screenshot({ path: elementScreenshotPath });
    console.log(`Element screenshot saved: ${elementScreenshotPath}`);
    expect(fs.existsSync(elementScreenshotPath)).toBeTruthy();

    // Demonstrate masking an element in a screenshot
    const maskedScreenshotPath = path.join(screenshotsDir, 'playwright-masked.png');
    await page.screenshot({
      path: maskedScreenshotPath,
      mask: [page.locator('.navbar__title')], // Mask the title of the navbar
      fullPage: false, // For viewport screenshot, easier to see effect
    });
    console.log(`Masked screenshot saved: ${maskedScreenshotPath}`);
    expect(fs.existsSync(maskedScreenshotPath)).toBeTruthy();

    // Additional assertion to demonstrate test flow
    await expect(page).toHaveTitle(/Screenshots/);
  });

  // To locate and play recorded video, you would typically do this outside the test framework
  // after the test run, using a video player like VLC, or integrate into a CI report.
  // The video path is logged in afterEach, which you can then use.
});
```

## Best Practices
- **Organize Screenshots and Videos**: Create dedicated directories (e.g., `test-results/screenshots`, `test-results/videos`) for storing output to keep your project clean and easily navigable.
- **Meaningful Filenames**: Use descriptive filenames for screenshots and videos, often including test name, timestamp, or an identifier.
- **Conditional Capturing**: Only capture screenshots or record videos on test failures to save disk space and speed up test execution, especially in CI environments. Playwright allows `recordVideo` only on first retry or on failure.
- **`fullPage` judiciously**: Use `fullPage: true` only when necessary, as full-page screenshots can be large and may not always be relevant for a specific failure.
- **Mask Sensitive Data**: Always mask sensitive information (e.g., personal data, credit card numbers) in screenshots and videos to comply with privacy regulations.
- **Review Video Resolution**: Choose an appropriate video resolution (`size` in `recordVideo` options) that balances clarity with file size.

## Common Pitfalls
- **Forgetting to close context/browser**: If `context.close()` or `browser.close()` are not called, video files might not be finalized or saved properly. Playwright's `test.afterEach` handles this automatically if you set up your context/page within the `test` fixture.
- **Large Video Files**: Recording videos for every test, especially long ones, can quickly consume disk space and slow down CI pipelines. Implement strategies to clean up old artifacts.
- **Incorrect Screenshot Paths**: Ensure the `path` option for `screenshot()` is correctly specified and the directory exists, otherwise the command will fail silently or throw an error.
- **Flaky Visuals due to Animations**: If animations are not disabled (`animations: 'disabled'`), screenshots might capture transitional states, leading to flaky visual comparisons.
- **Misunderstanding `fullPage`**: Confusing `fullPage: true` (entire scrollable page) with the default behavior (viewport only) can lead to missing crucial parts of the page in your screenshots.

## Interview Questions & Answers
1.  **Q: How do you use screenshots and video recordings in Playwright for debugging or regression testing?**
    A: Screenshots are used for visual regression testing by comparing current UI against a baseline, or to capture specific states of the application. Video recordings are invaluable for debugging flaky tests or complex interaction flows, as they provide a step-by-step visual replay of the test execution, helping identify unexpected behavior that logs alone might miss.

2.  **Q: What are the key considerations when implementing video recording in Playwright tests for a CI/CD pipeline?**
    A: In CI/CD, key considerations include managing disk space (videos can be large), configuring conditional recording (e.g., only on failure or first retry), ensuring video file cleanup, and integrating video artifacts with reporting tools for easy access and viewing. Also, ensuring the CI environment has necessary codecs and resources for video processing.

3.  **Q: How do you handle sensitive data when taking screenshots in automated tests?**
    A: Playwright offers a `mask` option in its `screenshot()` method. By providing selectors to elements containing sensitive data, Playwright will render these areas as solid pink blocks, preventing the actual content from being captured in the screenshot. This is crucial for privacy and security compliance.

## Hands-on Exercise
1.  **Objective**: Navigate to a complex e-commerce product page (e.g., `https://www.amazon.com/dp/B0B5P2C889`).
2.  **Task 1**: Capture a full-page screenshot of the product page.
3.  **Task 2**: Capture a screenshot of the product title element and the "Add to Cart" button element.
4.  **Task 3**: Modify the `test.beforeEach` to record a video of the entire test execution.
5.  **Task 4**: Introduce a `mask` to hide the price of the product in a screenshot.
6.  **Verification**: After running the test, confirm that the screenshots and video files are generated in the specified directories and that the masked elements are obscured.

## Additional Resources
-   **Playwright Screenshots Documentation**: [https://playwright.dev/docs/screenshots](https://playwright.dev/docs/screenshots)
-   **Playwright Videos Documentation**: [https://playwright.dev/docs/videos](https://playwright.dev/docs/videos)
-   **Playwright Test Configuration (Video Options)**: [https://playwright.dev/docs/test-configuration#videos](https://playwright.dev/docs/test-configuration#videos)
