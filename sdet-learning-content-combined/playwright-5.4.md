# playwright-5.4-ac1.md

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
---
# playwright-5.4-ac2.md

# Playwright Custom Fixtures for Reusable Setup/Teardown

## Overview
Playwright fixtures are a powerful mechanism to set up the test environment before tests run and clean it up afterwards. They allow you to define reusable setup and teardown logic, making your tests more modular, readable, and maintainable. Custom fixtures, built using `test.extend()`, enable SDETs to encapsulate complex, application-specific setup (like user authentication or database seeding) that can be easily injected into any test requiring it. This prevents code duplication, ensures consistency, and promotes a clean test architecture, ultimately leading to more robust and efficient test suites.

## Detailed Explanation
Playwright's `test.extend()` function allows you to extend the base `test` object with your own custom fixtures. These fixtures are functions that can return a value (the fixture itself) and can have setup logic before the test runs (the `async ({ parameter }, use) => { ... }` part before `await use(value)`) and teardown logic after the test finishes (the code after `await use(value)`).

A custom fixture function receives two arguments:
1.  An object containing other fixtures it depends on (e.g., `page`, `browser`, or even other custom fixtures).
2.  A `use` function, which is crucial. It yields the fixture's value to the test. Any code placed *before* `await use(value)` is setup, and any code *after* it is teardown.

### Steps to create and use a custom fixture:
1.  **Extend `test` object**: Import `test` from `@playwright/test` and use `test.extend()` to define your custom fixtures.
2.  **Define a custom fixture**: Create an asynchronous function for your fixture.
3.  **Implement setup logic**: Write code that runs before the test, such as logging in a user, setting up a database, or navigating to a specific page.
4.  **Yield the fixture value**: Use `await use(value)` to make the fixture's value available to tests.
5.  **Implement teardown logic**: Write code that runs after the test, such as logging out, cleaning up test data, or closing resources.
6.  **Use the custom fixture**: In your test files, import the extended `test` object and declare the custom fixture in your test function's arguments.

## Code Implementation

Let's create a custom `loggedInUser` fixture that logs into an application and provides the `page` object with an authenticated user context.

**`tests/fixtures/auth.ts`**
```typescript
import { test as baseTest, Page, expect } from '@playwright/test';

// Define the shape of our custom fixtures
type MyFixtures = {
  loggedInUser: Page; // The loggedInUser fixture will provide a Playwright Page object
};

// Extend the base test object with our custom fixtures
export const test = baseTest.extend<MyFixtures>({
  loggedInUser: async ({ page }, use) => {
    // --- SETUP LOGIC (before test) ---
    console.log('Setting up loggedInUser fixture: Logging in...');

    // Navigate to login page
    await page.goto('https://www.example.com/login'); // Replace with your application's login URL

    // Fill login credentials (replace with actual selectors and credentials)
    await page.fill('input[name="username"]', 'testuser');
    await page.fill('input[name="password"]', 'password123');
    await page.click('button[type="submit"]');

    // Wait for successful login (e.g., check for a dashboard element or redirect)
    await expect(page.locator('.dashboard-header')).toBeVisible();
    console.log('Login successful for loggedInUser.');

    // Yield the authenticated page object to the test
    await use(page);

    // --- TEARDOWN LOGIC (after test) ---
    console.log('Tearing down loggedInUser fixture: Logging out...');
    // Implement logout functionality
    await page.click('#user-menu'); // Example: Click on user menu to reveal logout button
    await page.click('text=Logout'); // Example: Click logout button
    await expect(page.url()).toContain('/login'); // Verify logout
    console.log('Logout successful for loggedInUser.');
  },
});

// Re-export Playwright's expect for convenience when using custom test object
export { expect } from '@playwright/test';
```

**`tests/dashboard.spec.ts`**
```typescript
// Import the extended test object from our fixtures file
import { test, expect } from './fixtures/auth';

test.describe('Dashboard functionality', () => {
  test('should display user profile information', async ({ loggedInUser }) => {
    // The 'loggedInUser' fixture has already logged us in and provided the page.
    console.log('Running test: should display user profile information');

    await loggedInUser.goto('https://www.example.com/dashboard/profile'); // Navigate to profile page
    await expect(loggedInUser.locator('.profile-name')).toHaveText('Test User');
    await expect(loggedInUser.locator('.profile-email')).toHaveText('testuser@example.com');
    console.log('User profile information verified.');
  });

  test('should allow user to navigate to settings', async ({ loggedInUser }) => {
    console.log('Running test: should allow user to navigate to settings');

    await loggedInUser.click('a[href="/dashboard/settings"]'); // Click on settings link
    await expect(loggedInUser.url()).toContain('/dashboard/settings');
    await expect(loggedInUser.locator('h1')).toHaveText('Settings');
    console.log('Navigation to settings verified.');
  });

  test('should not allow access to admin page for regular user', async ({ loggedInUser }) => {
    console.log('Running test: should not allow access to admin page for regular user');
    await loggedInUser.goto('https://www.example.com/admin');
    await expect(loggedInUser.locator('text=Access Denied')).toBeVisible();
    console.log('Access denied to admin page verified.');
  });
});
```

**To Run This Example:**
1.  Create a `tests/fixtures/auth.ts` file and paste the `auth.ts` content.
2.  Create a `tests/dashboard.spec.ts` file and paste the `dashboard.spec.ts` content.
3.  Ensure you have Playwright installed (`npm init playwright@latest`).
4.  Update `playwright.config.ts` to include your `auth.ts` in `testDir` or ensure your `testDir` covers both files.
5.  Run tests using `npx playwright test`.
    *Note: The example uses `https://www.example.com` as a placeholder. You would replace this with your actual application's URLs and selectors.*

## Best Practices
-   **Granularity**: Keep fixtures focused on a single responsibility (e.g., `loggedInUser`, `dbConnected`, `adminUser`).
-   **Reusability**: Design fixtures to be as generic and reusable as possible across different test files.
-   **Clear Naming**: Use descriptive names for your fixtures that clearly indicate their purpose.
-   **Avoid Over-Fixturing**: Don't create fixtures for every small setup step. Balance between reusability and unnecessary abstraction.
-   **Context Isolation**: Use `test.use()` in `playwright.config.ts` or within `test.describe` to set global or group-specific fixture values (e.g., `baseURL`).
-   **Error Handling**: Include robust error handling in your setup/teardown logic to ensure tests fail gracefully if a fixture fails.
-   **Fixture Scopes**: Understand and utilize `scope: 'worker' | 'test' | 'batch'` for optimal performance. `worker` scope is great for expensive operations like launching a browser, `test` for per-test setup like logging in, and `batch` for setup once per batch of tests.

## Common Pitfalls
-   **Forgetting `await use(value)`**: Tests will not run if `use` is not called, leading to hanging or timeout errors.
-   **Incorrect Teardown Logic**: Teardown logic might not run if `await use()` is not awaited properly or if an error occurs before it.
-   **Overly Complex Fixtures**: Fixtures that do too much can become hard to maintain and debug. Break them down into smaller, dependent fixtures if needed.
-   **Not Exporting `test` and `expect`**: Forgetting to export your extended `test` object and Playwright's `expect` from your fixture file means your tests won't correctly use the custom fixtures or matchers.
-   **Dependency Cycles**: Be careful not to create circular dependencies between fixtures.
-   **Performance Overhead**: Inefficient setup/teardown logic (e.g., logging in for every test when `storageState` could be used with `worker` scope) can significantly slow down your test suite.

## Interview Questions & Answers
1.  **Q: What are Playwright fixtures, and why are they beneficial for test automation?**
    **A:** Playwright fixtures are a way to set up the test environment for a test and clean it up afterward. They are functions that are automatically invoked by Playwright's test runner, providing necessary resources to tests. Benefits include:
    *   **Reusability**: Avoids duplicating setup/teardown code across multiple tests.
    *   **Readability**: Makes tests cleaner and easier to understand by abstracting setup logic.
    *   **Maintainability**: Centralizes environment setup, making changes easier to manage.
    *   **Isolation**: Ensures each test runs in a consistent, isolated environment.
    *   **Dependency Injection**: Tests declare what they need, and Playwright provides it.

2.  **Q: Explain the `test.extend()` method in Playwright. When would you use it?**
    **A:** `test.extend()` is used to create custom test objects by adding or overriding fixtures provided by Playwright. You would use it when:
    *   You need application-specific setup/teardown (e.g., logging in a specific user role, connecting to a test database).
    *   You want to create a common base test object for your project with predefined configurations or services.
    *   You need to chain fixtures, where one custom fixture depends on another or on a built-in Playwright fixture (like `page` or `browser`).

3.  **Q: How do you handle setup and teardown logic within a custom Playwright fixture?**
    **A:** Within an `async` custom fixture function, the `await use(value)` call separates setup from teardown.
    *   **Setup**: Any code executed *before* `await use(value)` is part of the setup phase. This is where you prepare the test environment (e.g., authenticate, create test data).
    *   **Teardown**: Any code executed *after* `await use(value)` is part of the teardown phase. This is where you clean up resources (e.g., log out, delete test data, close connections). Playwright ensures this teardown code runs even if the test fails.

## Hands-on Exercise
**Exercise: Create a `guestUser` fixture**

**Objective:**
Create a custom Playwright fixture called `guestUser` that navigates to a specified base URL and ensures no user is logged in.

**Steps:**
1.  Create a new file `tests/fixtures/guest.ts` (or extend your existing `auth.ts` if you prefer).
2.  Define a new custom fixture `guestUser` that returns a `Page` object.
3.  Inside the `guestUser` fixture:
    *   Use the `page` fixture (built-in).
    *   Navigate `page` to a base URL (e.g., `https://www.example.com`).
    *   Implement logic to verify that no user is logged in (e.g., check for the presence of a "Login" button and absence of a "Logout" button).
    *   Use `await use(page)` to yield the page.
    *   (Optional) Implement any teardown if necessary (e.g., clearing local storage, though navigating away usually suffices).
4.  Create a new test file (e.g., `tests/guest.spec.ts`) and use the `guestUser` fixture to write a test that verifies a public page's content.

**Expected Outcome:**
Your tests should run successfully, demonstrating that the `guestUser` fixture correctly sets up an unauthenticated page for your tests.

## Additional Resources
-   **Playwright Documentation - Test Fixtures**: [https://playwright.dev/docs/test-fixtures](https://playwright.dev/docs/test-fixtures)
-   **Playwright Documentation - `test.extend()`**: [https://playwright.dev/docs/api/class-test#test-extend](https://playwright.dev/docs/api/class-test#test-extend)
-   **Video Tutorial on Playwright Custom Fixtures**: Search YouTube for "Playwright Custom Fixtures" for various community tutorials.
---
# playwright-5.4-ac3.md

# Playwright Fixture Composition and Dependency Injection

## Overview
Playwright fixtures are a powerful mechanism to establish a well-defined and isolated environment for your tests. Fixture composition allows you to build complex test setups by combining smaller, reusable fixtures, while dependency injection ensures that these fixtures are provided to tests and other fixtures exactly when and where they are needed. This approach promotes code reusability, simplifies test maintenance, and guarantees a consistent and predictable test context, adhering to the DRY (Don't Repeat Yourself) principle.

## Detailed Explanation
In Playwright, a fixture can declare dependencies on other fixtures. This is achieved by listing the required fixtures as parameters in the fixture's setup function. Playwright's test runner automatically handles the resolution of these dependencies. When a test requires a fixture, Playwright first identifies all its dependent fixtures, sets them up, and then proceeds with the setup of the primary fixture.

The execution order is crucial for maintaining a stable test environment:
1.  **Dependent Fixture Setup**: Fixtures that are depended upon are set up first.
2.  **Depending Fixture Setup**: Once dependencies are met, the fixture that declares these dependencies is set up.
3.  **Test Execution**: The actual test code runs, utilizing the prepared fixtures.
4.  **Depending Fixture Teardown**: After the test completes (regardless of pass or fail), the teardown logic for the depending fixture runs.
5.  **Dependent Fixture Teardown**: Finally, the teardown logic for the dependent fixtures runs.

This ensures resources are initialized in the correct order and cleaned up gracefully, preventing resource leaks and test interference. The `use` function, provided as a parameter to a fixture's setup function, is used to pass control to the next stage (either another fixture's setup or the test itself). Anything before `await use(...)` is setup, and anything after is teardown.

## Code Implementation
Here's an example demonstrating fixture composition and the execution order. We'll define two fixtures: `userProfile` (Fixture A) which creates a mock user profile, and `loggedInPage` (Fixture B) which depends on `userProfile` to simulate a login process on a `page` object.

First, create a `fixtures.ts` file:

```typescript
// fixtures.ts
import { test as base } from '@playwright/test';

// 1. Define interfaces for our custom fixtures
// This helps with type safety and auto-completion
interface UserProfile {
  id: string;
  username: string;
  email: string;
}

interface MyFixtures {
  userProfile: UserProfile; // Fixture A: Provides a user profile object
  loggedInPage: any;        // Fixture B: Provides a Playwright Page instance after login
}

// 2. Extend the base Playwright test object with our custom fixtures
export const test = base.extend<MyFixtures>({
  // Fixture A: userProfile
  userProfile: [async ({ }, use) => {
    console.log('--- Setting up userProfile fixture (Fixture A) ---');
    const profile: UserProfile = {
      id: 'usr123',
      username: 'testuser',
      email: 'test@example.com',
    };
    // The `use` function provides the fixture's value to dependent fixtures or tests
    await use(profile);
    console.log('--- Tearing down userProfile fixture (Fixture A) ---');
  }, { scope: 'test', auto: false }], // 'scope: test' means a new instance for each test
                                     // 'auto: false' means it's not automatically used by all tests

  // Fixture B: loggedInPage, which depends on 'page' (built-in) and 'userProfile' (custom)
  loggedInPage: [async ({ page, userProfile }, use) => {
    console.log('--- Setting up loggedInPage fixture (Fixture B) ---');
    console.log(`Attempting login for user: ${userProfile.username}`);

    // Simulate navigating to a login page and performing login
    // In a real scenario, replace with your actual application's login flow
    await page.goto('https://www.google.com/search?q=playwright'); // Example: navigate to a dummy page
    // await page.fill('#username', userProfile.username);
    // await page.fill('#password', 'SecurePass123'); // Use a secure way to handle passwords in real apps
    // await page.click('#loginButton');

    // Simulate waiting for successful login (e.g., checking for a dashboard element)
    // await page.waitForURL('**/dashboard'); // Replace with your actual dashboard URL or element check
    console.log(`Successfully "logged in" as ${userProfile.username}. Current URL: ${page.url()}`);

    // Provide the configured Playwright `page` object to the test
    await use(page);
    console.log('--- Tearing down loggedInPage fixture (Fixture B) ---');
  }, { scope: 'test' }], // 'scope: test' ensures a fresh logged-in page for each test
});
```

Next, create a test file named `fixtureComposition.spec.ts` that utilizes these fixtures:

```typescript
// fixtureComposition.spec.ts
import { test } from './fixtures'; // Import our extended test object
import { expect } from '@playwright/test';

test.describe('Fixture Composition Demo', () => {
  test('should verify user information on a logged-in page', async ({ loggedInPage, userProfile }) => {
    console.log('--- Executing test: should verify user information ---');
    // The 'loggedInPage' fixture has already handled navigation and login.
    // The 'userProfile' fixture's data is directly available here.

    // In a real application, you would assert specific elements containing user info
    // For this example, we'll just log and assert something generic from the page.
    console.log(`Test sees logged-in page at: ${loggedInPage.url()}`);
    console.log(`Test has user profile: ${userProfile.username}, ${userProfile.email}`);

    // Example assertion: Check if the page title contains a common search result phrase
    await expect(loggedInPage).toHaveTitle(/.*Playwright.*/); // This assumes the dummy page navigation above
    console.log('--- Finished test: should verify user information ---');
  });

  test('should navigate to a different section from logged-in state', async ({ loggedInPage }) => {
    console.log('--- Executing test: should navigate to a different section ---');
    // Again, loggedInPage fixture provides a page that is already in a logged-in state.

    // Simulate navigation to another part of the application
    await loggedInPage.goto('https://www.bing.com'); // Example: navigate to another dummy page
    await expect(loggedInPage).toHaveTitle(/.*Bing.*/);
    console.log('--- Finished test: should navigate to a different section ---');
  });
});
```

To run this, save both files in the same directory (e.g., `tests/`) and execute `npx playwright test fixtureComposition.spec.ts`.
You will observe output similar to this, demonstrating the execution order:

```
--- Setting up userProfile fixture (Fixture A) ---
--- Setting up loggedInPage fixture (Fixture B) ---
Attempting login for user: testuser
Successfully "logged in" as testuser. Current URL: https://www.google.com/search?q=playwright
--- Executing test: should verify user information ---
Test sees logged-in page at: https://www.google.com/search?q=playwright
Test has user profile: testuser, test@example.com
--- Finished test: should verify user information ---
--- Tearing down loggedInPage fixture (Fixture B) ---
--- Tearing down userProfile fixture (Fixture A) ---
--- Setting up userProfile fixture (Fixture A) ---
--- Setting up loggedInPage fixture (Fixture B) ---
Attempting login for user: testuser
Successfully "logged in" as testuser. Current URL: https://www.google.com/search?q=playwright
--- Executing test: should navigate to a different section ---
--- Finished test: should navigate to a different section ---
--- Tearing down loggedInPage fixture (Fixture B) ---
--- Tearing down userProfile fixture (Fixture A) ---
```
*(Note: Actual console output may vary slightly based on Playwright version and specific test runner configuration, but the order of fixture setup and teardown will remain consistent.)*

## Best Practices
-   **Single Responsibility Principle**: Design each fixture to handle a single, well-defined responsibility (e.g., setting up a user, creating a database connection, providing an authenticated API client). This makes fixtures easier to understand, test, and reuse.
-   **Appropriate Scoping**: Use the `scope` option (`'test'`, `'worker'`, `'project'`) strategically.
    -   `'test'`: Default. A new instance for every test. Ensures maximum isolation but can be slower.
    -   `'worker'`: A single instance for all tests running in a particular worker process. Good for setups that can be shared between tests without interference (e.g., a database client, a browser context).
    -   `'project'`: A single instance for all tests in the entire project. Use sparingly for truly global setups (e.g., a test server that runs once).
-   **Explicit Dependencies**: Always declare all necessary dependencies for a fixture or test explicitly in its signature. Avoid relying on global state or implicit setups.
-   **Robust Teardown**: Ensure that the teardown logic (code after `await use(value)`) properly cleans up all resources allocated during setup. This is critical for preventing resource leaks and ensuring subsequent tests run in a clean state.
-   **Meaningful Names**: Give your fixtures descriptive names that clearly indicate what they provide or what setup they perform.
-   **`auto: true` for Essential Fixtures**: For fixtures that are almost always needed (e.g., `page`), consider setting `auto: true` to automatically run their setup/teardown for every test without explicitly declaring them. Be cautious with this for resource-intensive fixtures.

## Common Pitfalls
-   **Incorrect Fixture Scope**: Using `scope: 'test'` for a resource that could be shared across a worker (like a browser instance) can lead to significantly slower tests due to repeated setup/teardown. Conversely, using a broader scope when per-test isolation is necessary can lead to flaky tests due to shared, mutable state.
-   **Circular Dependencies**: A common mistake is creating a circular dependency where Fixture A depends on B, and B depends on A. Playwright will detect this and throw an error. Design your fixture graph as a Directed Acyclic Graph (DAG).
-   **Over-reliance on `auto: true`**: Making too many fixtures `auto: true` can unnecessarily increase test execution time, as their setup/teardown will run even if a specific test doesn't directly use them.
-   **Implicit State Modification**: If a fixture modifies shared state (e.g., a database) without properly isolating or cleaning up its changes, it can cause other tests to fail unpredictably. Always ensure state is reset or isolated.
-   **Synchronous Setup in Asynchronous Fixtures**: Forgetting `await` inside an `async` fixture can lead to race conditions or fixtures not being fully set up before the test runs.

## Interview Questions & Answers
1.  **Q: What are Playwright fixtures and why are they considered a best practice in test automation?**
    A: Playwright fixtures are functions that define a setup and teardown routine for tests. They provide a controlled, isolated, and reusable way to prepare the test environment. They are a best practice because they:
    *   **Promote DRY**: Centralize common setup logic, reducing code duplication.
    *   **Ensure Isolation**: Each test (or worker, or project, depending on scope) receives a fresh, predictable environment.
    *   **Improve Readability**: Tests focus on testing specific logic rather than boilerplate setup.
    *   **Manage Resources**: Guarantee proper cleanup of resources after tests, preventing leaks.
    *   **Enable Dependency Injection**: Allow complex test contexts to be built by composing simpler, interdependent fixtures.

2.  **Q: How does Playwright's dependency injection system for fixtures work, and what are its benefits?**
    A: Playwright's dependency injection works by inspecting the parameters of a fixture's or test's function signature. If a parameter matches the name of a defined fixture, Playwright automatically resolves and provides an instance of that fixture. This system ensures that all necessary prerequisites for a test or fixture are met before execution. The benefits include:
    *   **Automatic Setup Order**: Playwright handles the correct execution order of dependent fixtures.
    *   **Test Context Clarity**: Tests clearly declare what they need, making them easier to understand.
    *   **Reusability**: Fixtures become modular components that can be mixed and matched.
    *   **Reduced Boilerplate**: Testers don't need to manually set up complex environments within each test.

3.  **Q: Explain the lifecycle and execution order of composed fixtures, specifically for setup and teardown phases.**
    A: The lifecycle of composed fixtures follows a strict order:
    *   **Setup**: Playwright first identifies the entire chain of dependencies. It then sets up the *outermost* fixtures (those with no dependencies, or whose dependencies are already met) first. This proceeds *inward*, meaning a fixture's setup runs only after all its direct dependencies have been fully set up.
    *   **Test Execution**: Once all required fixtures are set up, the test function itself is executed. The values yielded by the fixtures (via `await use(value)`) are injected into the test.
    *   **Teardown**: After the test completes (successfully or with failure), the teardown phase begins. This happens in the *reverse order* of setup. The *innermost* fixtures (those directly used by the test or depending on other fixtures) are torn down first, followed by their dependencies, working *outward*. This ensures that resources are deallocated correctly and in an logical sequence.

## Hands-on Exercise
1.  **Objective**: Create a test scenario where a "shoppingCart" fixture depends on a "product" fixture.
2.  **Steps**:
    *   **Define `Product` Interface**: Create an interface for a `Product` with `id`, `name`, and `price`.
    *   **Create `productFixture`**: Define a fixture named `productFixture` that creates and yields a `Product` object.
    *   **Create `shoppingCartFixture`**: Define a fixture named `shoppingCartFixture` that depends on `page` (built-in) and `productFixture`. In its setup, it should:
        *   Navigate to a dummy shopping page (e.g., `https://example.com/shop`).
        *   Add the product provided by `productFixture` to a simulated cart (e.g., by interacting with page elements).
        *   Yield the `page` object, now with the product in the cart.
    *   **Write a Test**: Create a test that uses `shoppingCartFixture`.
        *   Verify that the product is present in the simulated cart (e.g., by checking a cart item count or product name on the page).
        *   Verify the total price displayed on the cart page is correct based on the `productFixture`'s price.
    *   **Observe Execution**: Add `console.log` statements within the setup and teardown of both custom fixtures and the test itself to observe the precise execution order.

## Additional Resources
-   [Playwright Test Fixtures - Official Documentation](https://playwright.dev/docs/test-fixtures) - The definitive guide on Playwright fixtures.
-   [Playwright Test Best Practices](https://playwright.dev/docs/best-practices) - Learn how to write robust and maintainable Playwright tests.
-   [Example of extending Test using fixtures](https://playwright.dev/docs/test-advanced#fixtures) - Advanced usage of fixtures.
---
# playwright-5.4-ac4.md

# Playwright Fixtures: Sharing Data Across Tests

## Overview
Playwright's test fixtures provide a powerful mechanism to set up and tear down the environment needed for your tests. Beyond basic setup, fixtures excel at sharing complex objects or data across multiple tests or even entire test files. This is particularly useful for "heavy" operations like establishing database connections, configuring API clients, or preparing large datasets, ensuring these expensive operations run only once per worker process, significantly speeding up test execution and maintaining test isolation.

## Detailed Explanation
In Playwright, fixtures are functions that Playwright executes to set up the test environment. They can be synchronous or asynchronous and can yield a value that tests can consume. When a test requests a fixture, Playwright ensures that fixture is set up before the test runs.

There are two primary scopes for fixtures:
1.  **`test` scope (default):** The fixture is set up once per test and torn down after the test completes.
2.  **`worker` scope:** The fixture is set up once per worker process and torn down after all tests in that worker have finished. This scope is ideal for sharing resources that are expensive to create and can be safely reused across multiple tests, such as database connections, authenticated API clients, or cached data.

To share data, you define a custom `test` object using `test.extend()`, providing your worker-scoped fixture. This fixture will yield the shared data (e.g., a database client object). Any test or other fixture that depends on this custom `test` object can then access the shared data.

### Worker-Scoped Fixtures for Heavy Setup
Worker-scoped fixtures are crucial for performance optimization. Imagine you have 100 tests that all need to interact with a database. If each test establishes and closes its own database connection, the overhead would be enormous. With a worker-scoped fixture, the connection is established once when the worker starts and closed only when the worker finishes, allowing all 100 tests to reuse the same connection.

### Sharing Database Connections or Test Data Objects
A common use case is sharing a database connection. The fixture would handle:
-   Connecting to the database (e.g., PostgreSQL, MongoDB, a mock database).
-   Optionally, preparing initial test data (e.g., seeding the database).
-   Yielding the database client object.
-   Tearing down the connection (e.g., closing it, cleaning up data) after all tests in the worker complete.

This ensures all tests running in that worker process have access to the same, pre-configured database client.

### Verifying Data Availability Across Multiple Test Files
The `worker` scope means the fixture's yielded value is available to any test or test file executed by that specific worker process. This allows you to define a database connection fixture once and then use it across various test files that require database interaction, maintaining consistency and reducing boilerplate code.

## Code Implementation

Let's illustrate with a mock database connection.

First, define your custom `test` object with a worker-scoped fixture in a file like `tests/fixtures/dbFixture.ts`:

```typescript
// tests/fixtures/dbFixture.ts
import { test as baseTest } from '@playwright/test';

// Mock database client for demonstration purposes
class MockDBClient {
  private isConnected: boolean = false;
  private data: Map<string, any> = new Map();

  async connect() {
    console.log('DB: Connecting...');
    // Simulate async connection
    await new Promise(resolve => setTimeout(resolve, 500));
    this.isConnected = true;
    console.log('DB: Connected!');
    // Seed some initial data
    this.data.set('user123', { id: 'user123', name: 'Alice', email: 'alice@example.com' });
    this.data.set('product456', { id: 'product456', name: 'Laptop', price: 1200 });
  }

  async disconnect() {
    console.log('DB: Disconnecting...');
    // Simulate async disconnection
    await new Promise(resolve => setTimeout(resolve, 200));
    this.isConnected = false;
    console.log('DB: Disconnected!');
    this.data.clear();
  }

  async getUser(id: string) {
    if (!this.isConnected) throw new Error('DB not connected');
    console.log(`DB: Fetching user ${id}`);
    await new Promise(resolve => setTimeout(resolve, 50));
    return this.data.get(id);
  }

  async getProduct(id: string) {
    if (!this.isConnected) throw new Error('DB not connected');
    console.log(`DB: Fetching product ${id}`);
    await new Promise(resolve => setTimeout(resolve, 50));
    return this.data.get(id);
  }

  async insertData(key: string, value: any) {
    if (!this.isConnected) throw new Error('DB not connected');
    console.log(`DB: Inserting data for key ${key}`);
    await new Promise(resolve => setTimeout(resolve, 50));
    this.data.set(key, value);
  }

  async clearData() {
    if (!this.isConnected) throw new Error('DB not connected');
    console.log('DB: Clearing all data.');
    await new Promise(resolve => setTimeout(resolve, 100));
    this.data.clear();
  }
}

// Declare the types for your fixtures.
type MyFixtures = {
  dbClient: MockDBClient;
};

// Extend the base test object with our custom fixture.
export const test = baseTest.extend<MyFixtures>({
  dbClient: [async ({}, use) => {
    const dbClient = new MockDBClient();
    await dbClient.connect(); // Heavy setup
    await use(dbClient); // Yield the client for tests to use
    await dbClient.disconnect(); // Heavy teardown
  }, { scope: 'worker', auto: true }], // 'worker' scope ensures it runs once per worker. 'auto: true' means it runs automatically.
});

// Re-export expect for convenience if needed, or import directly from '@playwright/test' in test files.
export { expect } from '@playwright/test';
```

Next, use this `dbClient` fixture in your test files.
For example, in `tests/user.spec.ts`:

```typescript
// tests/user.spec.ts
import { test, expect } from '../tests/fixtures/dbFixture'; // Import from your custom test object

test.describe('User Management', () => {
  test('should fetch a user from the database', async ({ dbClient }) => {
    console.log('Test 1: Fetching user...');
    const user = await dbClient.getUser('user123');
    expect(user).toBeDefined();
    expect(user.name).toBe('Alice');
    expect(user.email).toBe('alice@example.com');
    await dbClient.insertData('user456', { id: 'user456', name: 'Bob', email: 'bob@example.com' });
    const newUser = await dbClient.getUser('user456');
    expect(newUser.name).toBe('Bob');
  });

  test('should not find a non-existent user', async ({ dbClient }) => {
    console.log('Test 2: Fetching non-existent user...');
    const user = await dbClient.getUser('nonExistentUser');
    expect(user).toBeUndefined();
  });
});
```

And in `tests/product.spec.ts`:

```typescript
// tests/product.spec.ts
import { test, expect } from '../tests/fixtures/dbFixture'; // Import from your custom test object

test.describe('Product Catalog', () => {
  test('should fetch a product from the database', async ({ dbClient }) => {
    console.log('Test 3: Fetching product...');
    const product = await dbClient.getProduct('product456');
    expect(product).toBeDefined();
    expect(product.name).toBe('Laptop');
    expect(product.price).toBe(1200);
  });

  test('should allow adding new product data', async ({ dbClient }) => {
    console.log('Test 4: Adding new product...');
    const newProduct = { id: 'product789', name: 'Mouse', price: 25 };
    await dbClient.insertData('product789', newProduct);
    const fetchedProduct = await dbClient.getProduct('product789');
    expect(fetchedProduct).toEqual(newProduct);
  });
});
```

When you run these tests, you will observe that `DB: Connecting...` and `DB: Disconnecting...` messages appear only once per worker process, even though multiple tests in different files utilize the `dbClient` fixture. The data seeded in `dbClient.connect()` is available to all tests within that worker.

## Best Practices
-   **Use `worker` scope for expensive, shared resources:** Database connections, API clients, browser instances (if not using `page` or `context` fixtures), and anything that takes significant time or resources to set up and tear down.
-   **Keep fixture setup and teardown clean:** Ensure fixtures clean up any resources they create to prevent resource leaks and ensure test isolation between different worker processes.
-   **Isolate test data:** While the connection is shared, ensure tests don't interfere with each other's data. If tests modify shared data, consider transaction-based approaches or mechanisms to reset data before each test or describe block. The example above uses a simple `Map` which is cleared when the worker disconnects, but real-world scenarios might require more sophisticated data management.
-   **Organize fixtures:** Place custom fixtures in a dedicated directory (e.g., `tests/fixtures/`) for better organization and reusability.
-   **Use `auto: true` sparingly:** Only set `auto: true` for worker fixtures if you are certain that every test needs it, or if it's purely for side effects that don't need to be explicitly requested by tests (e.g., logging setup). Otherwise, explicitly request the fixture in your tests (`async ({ dbClient }) => {...}`).

## Common Pitfalls
-   **Forgetting `worker` scope:** Accidentally using the default `test` scope for heavy setups will lead to significant performance degradation as the setup/teardown runs for every single test.
-   **Lack of data isolation:** If multiple tests within the same worker modify the shared state (e.g., database data) without proper cleanup or transaction management, tests can become flaky and interdependent.
-   **Over-sharing:** Not all resources should be shared. Some resources truly need to be isolated per test (e.g., a fresh browser context or page for UI tests) to prevent side effects between tests.
-   **Complex fixture dependencies:** While powerful, an overly complex chain of fixture dependencies can make it hard to understand the test setup. Keep fixtures focused and simple.

## Interview Questions & Answers
1.  **Q: Explain the difference between `test` and `worker` scoped fixtures in Playwright. When would you use each?**
    A: `test` scoped fixtures are created and destroyed for each individual test. They are suitable for resources that need to be fresh for every test, like a browser `page` or `context`. `worker` scoped fixtures are created once per worker process and shared across all tests running within that worker. They are ideal for expensive resources like database connections, API clients, or global setup that can be safely reused, improving performance.
2.  **Q: How would you share a database connection across multiple Playwright test files efficiently? Provide a high-level code example.**
    A: You would use a `worker`-scoped fixture defined using `test.extend()`. This fixture would establish the database connection, yield the connection object, and then close it in its teardown phase. All test files needing this connection would then import `test` from the custom fixture file, allowing them to access the shared connection via dependency injection. (Refer to the `Code Implementation` section for an example.)
3.  **Q: What are the potential challenges of sharing data across tests using worker-scoped fixtures, and how do you mitigate them?**
    A: The main challenge is ensuring test isolation, especially regarding data modifications. If tests modify shared data, subsequent tests might run against an altered state, leading to flakiness. Mitigation strategies include:
    *   **Transactions:** Wrap each test's database operations in a transaction and roll it back after the test.
    *   **Data Reset:** Implement a mechanism in the fixture's teardown (or a `beforeEach` hook) to reset the data to a known state.
    *   **Read-only operations:** If tests only read shared data, isolation is less of a concern.
    *   **Dedicated test data:** Each test uses its own unique set of data.

## Hands-on Exercise
1.  **Extend the `MockDBClient`:** Add a new method `deleteUser(id: string)` to the `MockDBClient` that removes a user from its internal `data` map.
2.  **Create a new test file:** Create `tests/admin.spec.ts`.
3.  **Implement an admin test:** In `tests/admin.spec.ts`, write a test that uses the `dbClient` fixture to:
    *   Insert a new admin user.
    *   Verify the admin user exists.
    *   Call `deleteUser` to remove the newly added admin user.
    *   Verify the admin user no longer exists.
4.  **Observe logging:** Run your tests (`npx playwright test`). Observe the console output to confirm that the `dbClient.connect()` and `dbClient.disconnect()` logs still only appear once per worker, even with the new test file.

## Additional Resources
-   **Playwright Test Fixtures:** [https://playwright.dev/docs/test-fixtures](https://playwright.dev/docs/test-fixtures)
-   **Playwright `test.extend`:** [https://playwright.dev/docs/api/class-test#test-extend](https://playwright.dev/docs/api/class-test#test-extend)
-   **Playwright Test Configuration (`projects` and workers):** [https://playwright.dev/docs/test-configuration#projects](https://playwright.dev/docs/test-configuration#projects)
---
# playwright-5.4-ac5.md

# Playwright Fixtures & Test Organization: Create Page Object Fixtures

## Overview
This feature delves into creating custom Playwright fixtures to instantiate and provide Page Objects to tests. This approach significantly enhances test readability, maintainability, and reusability by centralizing Page Object instantiation and promoting a cleaner test body. It aligns with the Page Object Model (POM) design pattern, making tests more robust and easier to manage as your application grows.

## Detailed Explanation
Playwright's test runner allows for the creation of custom fixtures, which are functions that provide resources to tests. These resources can be anything from browser contexts to fully initialized Page Objects. By defining Page Objects as fixtures, we can leverage Playwright's dependency injection system to automatically provide these objects to our tests, eliminating boilerplate code within each test.

The key steps involve:
1.  **Defining a custom fixture:** This fixture will be responsible for creating instances of our Page Objects.
2.  **Instantiating Page Objects:** Inside the fixture, we'll create new instances of our Page Object classes, passing the `page` object (provided by Playwright's built-in fixture) to their constructors.
3.  **Passing initialized Page Objects to tests:** The fixture will then yield an object containing these initialized Page Objects, making them available to any test that declares them as a dependency.
4.  **Removing manual instantiation:** Test bodies will no longer need to manually create `new LoginPage(page)` or similar, leading to cleaner and more focused tests.

This method promotes:
*   **DRY (Don't Repeat Yourself) principle:** Page Object instantiation logic is defined once.
*   **Improved readability:** Tests focus on the *actions* performed on the page, not on how the page objects are set up.
*   **Easier refactoring:** If a Page Object's constructor changes, only the fixture needs updating, not every test using that Page Object.
*   **Better test organization:** Fixtures can be grouped logically (e.g., all authentication-related page objects in one fixture).

## Code Implementation

Let's assume we have `LoginPage` and `HomePage` Page Objects.

```typescript
// page-objects/LoginPage.ts
import { Page, Locator, expect } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly usernameInput: () => Locator;
  readonly passwordInput: () => Locator;
  readonly loginButton: () => Locator;
  readonly errorMessage: () => Locator;

  constructor(page: Page) {
    this.page = page;
    this.usernameInput = () => page.locator('#username');
    this.passwordInput = () => page.locator('#password');
    this.loginButton = () => page.locator('button[type="submit"]');
    this.errorMessage = () => page.locator('.error-message');
  }

  async navigate() {
    await this.page.goto('/login'); // Assuming base URL is configured
  }

  async login(username: string, password: string) {
    await this.usernameInput().fill(username);
    await this.passwordInput().fill(password);
    await this.loginButton().click();
  }

  async verifyErrorMessage(message: string) {
    await expect(this.errorMessage()).toHaveText(message);
  }
}

// page-objects/HomePage.ts
import { Page, Locator, expect } from '@playwright/test';

export class HomePage {
  readonly page: Page;
  readonly welcomeMessage: () => Locator;
  readonly logoutButton: () => Locator;

  constructor(page: Page) {
    this.page = page;
    this.welcomeMessage = () => page.locator('.welcome-message');
    this.logoutButton = () => page.locator('#logout');
  }

  async verifyWelcomeMessage(username: string) {
    await expect(this.welcomeMessage()).toHaveText(`Welcome, ${username}!`);
  }

  async logout() {
    await this.logoutButton().click();
  }
}

// tests/fixtures/page-fixtures.ts
import { test as baseTest } from '@playwright/test';
import { LoginPage } from '../../page-objects/LoginPage'; // Adjust path as needed
import { HomePage } from '../../page-objects/HomePage'; // Adjust path as needed

type MyPages = {
  loginPage: LoginPage;
  homePage: HomePage;
};

// Extend base test by providing our fixtures.
// This will be available to all tests that use this 'test' object.
export const test = baseTest.extend<MyPages>({
  loginPage: async ({ page }, use) => {
    // Instantiate the LoginPage with the 'page' fixture
    const loginPage = new LoginPage(page);
    // Use it in the test
    await use(loginPage);
  },
  homePage: async ({ page }, use) => {
    // Instantiate the HomePage with the 'page' fixture
    const homePage = new HomePage(page);
    // Use it in the test
    await use(homePage);
  },
});

// Export expect from the baseTest for consistency if needed, though usually not required for new expect matchers.
export { expect } from '@playwright/test';

// tests/authentication.spec.ts (example test file using the fixtures)
import { test, expect } from '../tests/fixtures/page-fixtures'; // Import custom test object

test.describe('Authentication', () => {
  test('should allow a user to log in successfully', async ({ loginPage, homePage }) => {
    await loginPage.navigate();
    await loginPage.login('testuser', 'password123');
    await homePage.verifyWelcomeMessage('testuser');
  });

  test('should display an error message for invalid credentials', async ({ loginPage }) => {
    await loginPage.navigate();
    await loginPage.login('invaliduser', 'wrongpassword');
    await loginPage.verifyErrorMessage('Invalid username or password.');
  });

  test('should allow a logged in user to log out', async ({ loginPage, homePage }) => {
    await loginPage.navigate();
    await loginPage.login('testuser', 'password123');
    await homePage.verifyWelcomeMessage('testuser');
    await homePage.logout();
    await expect(loginPage.loginButton()).toBeVisible(); // Verify logout by checking login button visibility
  });
});
```

## Best Practices
-   **Separate Fixture Files:** Organize your custom fixtures in dedicated files (e.g., `tests/fixtures/page-fixtures.ts`) to keep them separate from actual test files and Page Objects.
-   **Type Safety:** Use TypeScript to define types for your custom fixtures (e.g., `type MyPages`) to ensure type safety and better auto-completion in your tests.
-   **One Page Object per Fixture:** Generally, create one fixture per Page Object to maintain modularity. If a fixture provides multiple related Page Objects, group them logically.
-   **Leverage `use`:** The `use` function in Playwright fixtures is crucial. It passes the fixture's value to the test and ensures that any teardown logic (if present after `await use(value)`) is executed.
-   **Avoid Over-Fixturing:** While powerful, don't create fixtures for every single element interaction. Reserve fixtures for setting up significant test preconditions or providing complex objects like Page Objects.
-   **Configuration:** Ensure your `playwright.config.ts` or similar configuration points to your fixture files if they are not in the default test location.

## Common Pitfalls
-   **Circular Dependencies:** Be cautious about Page Objects or fixtures having circular dependencies, where A depends on B, and B depends on A. This can lead to difficult-to-debug issues.
-   **Over-complicating Fixtures:** Keep fixtures focused on providing a specific resource. Avoid putting too much complex test logic directly within fixtures, which can make them harder to understand and debug.
-   **Forgetting `await use()`:** If `await use()` is omitted, the test won't receive the fixture's value, and any teardown logic will not run.
-   **Not importing the custom `test` object:** Tests must import the `test` object from your custom fixture file (e.g., `import { test, expect } from './fixtures/page-fixtures';`) rather than from `@playwright/test` directly, otherwise, your custom fixtures won't be available.

## Interview Questions & Answers
1.  **Q: What are Playwright fixtures, and how do they benefit test automation?**
    A: Playwright fixtures are a powerful mechanism to set up the environment for tests, provide test data, and tear down resources. They benefit test automation by promoting code reusability, reducing boilerplate, improving test readability through dependency injection, and ensuring tests run in isolated, well-defined environments. This leads to more stable and maintainable test suites.

2.  **Q: Explain how you would integrate the Page Object Model with Playwright fixtures.**
    A: To integrate POM with Playwright fixtures, I would define custom fixtures that instantiate Page Objects. Each fixture would be responsible for creating an instance of a specific Page Object, typically passing Playwright's `page` object to its constructor. Tests would then declare these custom fixtures as dependencies, allowing Playwright to automatically inject the initialized Page Objects into the test function. This removes the need for manual Page Object instantiation in each test, making tests cleaner and more focused on interaction logic.

3.  **Q: What are the advantages of using custom fixtures for Page Objects compared to instantiating them directly in each test?**
    A: The primary advantages include:
    *   **Reduced boilerplate:** Eliminates repetitive `new PageObject(page)` calls.
    *   **Improved readability:** Tests focus on the "what" (actions) rather than the "how" (setup).
    *   **Centralized management:** Page Object instantiation logic is in one place, making updates easier.
    *   **Dependency Injection:** Leverages Playwright's framework for cleaner test function signatures.
    *   **Easier test isolation:** Fixtures can ensure each test gets a fresh, correctly initialized Page Object.

4.  **Q: How do you handle setup and teardown logic within Playwright fixtures, especially when working with Page Objects?**
    A: Playwright fixtures use the `async ({ page }, use) => { ... await use(value); ... }` pattern. Setup logic is performed before `await use(value);`, which makes the `value` available to the test. Teardown logic, if any (e.g., clearing local storage, logging out), is placed after `await use(value);` and will execute once the test finishes, even if it fails. For Page Objects, the primary setup is their instantiation. Teardown is often handled implicitly by Playwright closing the `page` or `context`, but custom teardown (like logging out) can be added within the fixture if needed.

## Hands-on Exercise
**Objective:** Refactor an existing Playwright test suite to use custom fixtures for a `DashboardPage` Page Object.

1.  **Given:** You have an application with a login page and a dashboard page.
2.  **Existing Code:** A test file `dashboard.spec.ts` that manually instantiates `DashboardPage` after logging in.
    ```typescript
    // tests/dashboard.spec.ts (before refactor)
    import { test, expect } from '@playwright/test';
    import { LoginPage } from '../page-objects/LoginPage'; // Assume LoginPage exists
    import { DashboardPage } from '../page-objects/DashboardPage'; // Assume DashboardPage exists

    test.describe('Dashboard Features', () => {
      test('should display dashboard widgets after login', async ({ page }) => {
        const loginPage = new LoginPage(page);
        await loginPage.navigate();
        await loginPage.login('admin', 'password');

        const dashboardPage = new DashboardPage(page);
        await dashboardPage.verifyDashboardLoaded();
        await expect(dashboardPage.getWidget('Analytics')).toBeVisible();
      });
    });
    ```
3.  **Task:**
    *   Create a `page-objects/DashboardPage.ts` (if not already existing) with at least one selector and method (e.g., `verifyDashboardLoaded()`, `getWidget(name)`).
    *   Create a `tests/fixtures/dashboard-fixtures.ts` file.
    *   Define a custom fixture `dashboardPage` within `dashboard-fixtures.ts` that instantiates `DashboardPage`.
    *   Modify `dashboard.spec.ts` to use the new `test` object from `dashboard-fixtures.ts` and leverage the `dashboardPage` fixture.

**Expected Outcome:** The `dashboard.spec.ts` test should pass, and the code for instantiating `DashboardPage` should be removed from the test body, relying solely on the fixture.

## Additional Resources
-   **Playwright Test Fixtures:** [https://playwright.dev/docs/test-fixtures](https://playwright.dev/docs/test-fixtures)
-   **Playwright Page Object Model:** [https://playwright.dev/docs/pom](https://playwright.dev/docs/pom)
-   **Playwright Test Type-safe fixtures:** [https://playwright.dev/docs/typescript#type-safe-fixtures](https://playwright.dev/docs/typescript#type-safe-fixtures)
-   **Extending the test runner:** [https://playwright.dev/docs/test-advanced#extending-the-test-runner](https://playwright.dev/docs/test-advanced#extending-the-test-runner)
---
# playwright-5.4-ac6.md

# Playwright Test Hooks: `beforeEach`, `afterEach`, `beforeAll`, `afterAll`

## Overview
Playwright test hooks provide a powerful mechanism to manage test setup and teardown logic, ensuring a clean and consistent state for each test run. By defining actions that execute before or after test blocks or suites, you can efficiently handle tasks like page navigation, authentication, database cleanup, or resource allocation. Understanding and utilizing these hooks is crucial for writing robust, maintainable, and efficient Playwright tests, making your test suites more reliable and easier to manage.

## Detailed Explanation
Playwright offers several built-in test hooks, similar to popular testing frameworks like Jest or Mocha. These hooks allow you to execute code at different stages of your test lifecycle.

-   `test.beforeEach(callback)`: Runs before *each* test in the current file or `describe` block. Ideal for setting up a fresh state for every test, such as navigating to a base URL or logging in.
-   `test.afterEach(callback)`: Runs after *each* test in the current file or `describe` block. Useful for cleaning up the state modified by an individual test, like taking a screenshot on failure or logging out.
-   `test.beforeAll(callback)`: Runs once before *all* tests in the current file or `describe` block start. Perfect for expensive, one-time setup operations like seeding a database, starting a server, or creating a browser instance (though Playwright usually handles browser setup efficiently with fixtures).
-   `test.afterAll(callback)`: Runs once after *all* tests in the current file or `describe` block have finished. Best for global teardown operations like cleaning up test data from a database or stopping services.

The scope of these hooks is tied to the `describe` block they are defined within. Hooks defined outside any `describe` block apply to all tests in the file. Hooks defined inside a `describe` block apply only to the tests within that specific `describe` block and its nested `describe` blocks.

**Example Scenario**:
Consider an e-commerce application.
-   `beforeAll`: Ensure the database has necessary product data.
-   `beforeEach`: Navigate to the product listing page.
-   `afterEach`: Take a screenshot if a test fails.
-   `afterAll`: Clean up any test data added to the database.

## Code Implementation
Here's a comprehensive example demonstrating the use of `beforeEach`, `afterEach`, `beforeAll`, and `afterAll`, including nested `describe` blocks and data cleanup.

```typescript
import { test, expect } from '@playwright/test';

// Global beforeAll hook for the entire test file
test.beforeAll(async () => {
  console.log('--- Global beforeAll: Setting up test environment (e.g., seeding DB) ---');
  // Simulate seeding a database with test data
  await new Promise(resolve => setTimeout(resolve, 500));
  console.log('--- Global beforeAll: Test environment ready ---');
});

// Global afterAll hook for the entire test file
test.afterAll(async () => {
  console.log('--- Global afterAll: Cleaning up global test environment (e.g., clearing DB) ---');
  // Simulate cleaning up test data from the database
  await new Promise(resolve => setTimeout(resolve, 500));
  console.log('--- Global afterAll: Global cleanup complete ---');
});

test.describe('Product Page Tests', () => {
  // beforeAll for 'Product Page Tests' describe block
  test.beforeAll(async () => {
    console.log('--- Product Page Describe beforeAll: Setting up specific product data ---');
    // Simulate setting up product-specific data
    await new Promise(resolve => setTimeout(resolve, 200));
  });

  // afterAll for 'Product Page Tests' describe block
  test.afterAll(async () => {
    console.log('--- Product Page Describe afterAll: Cleaning up specific product data ---');
    // Simulate cleaning up product-specific data
    await new Promise(resolve => setTimeout(resolve, 200));
  });

  // beforeEach for 'Product Page Tests' describe block
  // Using test.beforeEach for navigation as per requirement
  test.beforeEach(async ({ page }) => {
    console.log('--- Product Page Describe beforeEach: Navigating to product listing page ---');
    await page.goto('https://www.demoblaze.com/index.html'); // Example URL
    await expect(page).toHaveTitle('STORE');
    console.log('--- Product Page Describe beforeEach: Navigation complete ---');
  });

  // afterEach for 'Product Page Tests' describe block
  test.afterEach(async ({ page }, testInfo) => {
    console.log(`--- Product Page Describe afterEach: Test '${testInfo.title}' finished with status: ${testInfo.status} ---`);
    if (testInfo.status !== testInfo.expectedStatus) {
      // Take a screenshot on failure
      const screenshotPath = `test-results/${testInfo.title.replace(/\s/g, '_')}_failure.png`;
      await page.screenshot({ path: screenshotPath });
      console.log(`--- Screenshot taken for failed test: ${screenshotPath} ---`);
    }
  });

  test('should display product items', async ({ page }) => {
    console.log('  -> Running test: should display product items');
    await expect(page.locator('.card-title')).toHaveCount(9);
    await expect(page.locator('.card-title').first()).toBeVisible();
    console.log('  -> Test: should display product items - PASSED');
  });

  test('should allow navigating to a product detail page', async ({ page }) => {
    console.log('  -> Running test: should allow navigating to a product detail page');
    await page.locator('.card-title').filter({ hasText: 'Samsung galaxy s6' }).click();
    await expect(page).toHaveURL(/.*prod.html\?idp_=1/);
    await expect(page.locator('.name')).toHaveText('Samsung galaxy s6');
    console.log('  -> Test: should allow navigating to a product detail page - PASSED');
  });

  test.describe('Shopping Cart Functionality', () => {
    // beforeEach for 'Shopping Cart Functionality' describe block (nested)
    test.beforeEach(async ({ page }) => {
      console.log('---- Shopping Cart Describe beforeEach: Ensuring user is logged in ----');
      // Simulate login for cart tests
      await page.goto('https://www.demoblaze.com/index.html');
      await page.locator('#login2').click();
      await page.locator('#loginusername').fill('testuser');
      await page.locator('#loginpassword').fill('testpass');
      await page.locator('button:has-text("Log in")').click();
      await expect(page.locator('#nameofuser')).toBeVisible();
      console.log('---- Shopping Cart Describe beforeEach: User logged in ----');
    });

    test('should add an item to the cart', async ({ page }) => {
      console.log('    -> Running test: should add an item to the cart');
      await page.locator('.card-title').filter({ hasText: 'Samsung galaxy s6' }).click();
      await page.getByRole('link', { name: 'Add to cart' }).click();
      page.on('dialog', async dialog => {
        expect(dialog.message()).toContain('Product added.');
        await dialog.accept();
      });
      await page.locator('#cartur').click();
      await expect(page.locator('.success')).toBeVisible(); // Checks for row in cart table
      console.log('    -> Test: should add an item to the cart - PASSED');
    });

    test('should remove an item from the cart', async ({ page }) => {
      console.log('    -> Running test: should remove an item from the cart');
      // First, add an item to the cart
      await page.locator('.card-title').filter({ hasText: 'Samsung galaxy s6' }).click();
      await page.getByRole('link', { name: 'Add to cart' }).click();
      page.on('dialog', async dialog => { await dialog.accept(); }); // Accept "Product added." alert
      await page.locator('#cartur').click();
      await expect(page.locator('.success')).toBeVisible();

      // Now remove it
      await page.getByRole('link', { name: 'Delete' }).first().click();
      await expect(page.locator('.success')).not.toBeVisible(); // Verify item is gone
      console.log('    -> Test: should remove an item from the cart - PASSED');
    });
  });
});
```

## Best Practices
-   **Scope Appropriately**: Define hooks in the smallest possible `describe` block that encompasses the tests requiring that setup/teardown. This prevents unnecessary execution and keeps your tests focused.
-   **Avoid Over-reliance on Global Hooks**: While `beforeAll`/`afterAll` can be useful, overusing them globally can lead to a fragile test suite where failures in one test affect others. Prefer `beforeEach`/`afterEach` for isolating test states.
-   **Use Fixtures for Reusability**: For complex setups like authentication or custom page objects, Playwright fixtures are often a more powerful and maintainable solution than hooks, as they allow for dependency injection and explicit resource management. Hooks can complement fixtures for simpler, block-scoped actions.
-   **Error Handling**: Ensure your hook callbacks handle potential errors gracefully, especially for operations like database cleanup, to avoid disrupting subsequent tests.
-   **Logging**: Add `console.log` statements within your hooks to clearly see the order of execution, which is invaluable for debugging.
-   **Data Management**: Use `beforeAll` for idempotent data setup (e.g., ensuring a user exists) and `afterAll` for data cleanup (e.g., deleting a user created during tests). Ensure cleanup is robust.

## Common Pitfalls
-   **Incorrect Hook Scope**: Placing a `beforeEach` inside a nested `describe` when it's meant for the whole file, or vice versa. Always visualize the hierarchy of your `describe` blocks and where the hooks are defined.
-   **Leaky State**: If `afterEach` or `afterAll` fail to properly clean up resources (e.g., database entries, logged-in sessions), subsequent tests might start in an unexpected state, leading to flaky tests.
-   **Slow Hooks**: Expensive operations in `beforeEach` can significantly slow down your entire test suite, as they run for every single test. Optimize these or consider moving them to `beforeAll` if the setup can be shared.
-   **Asynchronous Issues**: Forgetting `await` in asynchronous hook callbacks can lead to tests starting before the setup is complete or teardown occurring prematurely. Playwright hooks fully support `async/await`.
-   **Misunderstanding `beforeAll` vs. `beforeEach`**: `beforeAll` runs once per describe block/file, while `beforeEach` runs before every test. Using `beforeAll` for an action that needs to reset for each test (like navigating to a fresh page) will cause issues.

## Interview Questions & Answers
1.  **Q: Explain the different Playwright test hooks and when you would use each one.**
    A: Playwright provides `test.beforeAll`, `test.afterAll`, `test.beforeEach`, and `test.afterEach`.
    -   `test.beforeAll` runs once before all tests in a `describe` block or file. Use it for expensive, one-time setups like database seeding or starting a local server.
    -   `test.afterAll` runs once after all tests in a `describe` block or file. Use it for global teardown, such as cleaning up data or stopping services.
    -   `test.beforeEach` runs before every test in a `describe` block or file. Ideal for ensuring a clean, isolated state for each test, like navigating to a base URL, logging in a user, or resetting mock data.
    -   `test.afterEach` runs after every test. Useful for individual test teardown, like taking screenshots on failure, logging out, or clearing test-specific local storage.

2.  **Q: How do Playwright hooks differ from Playwright fixtures, and when would you choose one over the other?**
    A: Hooks are primarily for executing code at specific lifecycle events (before/after tests/suites), often for setup/teardown actions. Fixtures, on the other hand, are a more powerful mechanism for dependency injection and resource management. They provide reusable setup logic and values to tests, implicitly handling setup and teardown based on test needs.
    -   **Choose Hooks**: For simple, procedural setup/teardown that doesn't need to pass data directly into tests, or when you need explicit control over execution order relative to `describe` blocks. For example, a `beforeAll` to seed a database that all tests will interact with, or `afterEach` to take a screenshot.
    -   **Choose Fixtures**: For complex, reusable test environment configurations (e.g., logged-in user, custom page objects, API clients) where you want to inject specific values or objects into your test functions. Fixtures are excellent for managing browser contexts, pages, and authenticated states more declaratively and efficiently. You can also compose fixtures.

3.  **Q: You have a `beforeEach` hook that navigates to a login page and logs in. What are the potential issues if this hook is slow, and how would you optimize it?**
    A: If a `beforeEach` hook is slow (e.g., due to repeated full login flows), it will execute before *every single test*, significantly increasing the total test execution time.
    **Optimization strategies:**
    -   **Authentication State Storage**: Instead of a full UI login on every `beforeEach`, log in once, capture the authentication state (e.g., `storageState.json`), and reuse it in `beforeEach` using `page.context().addCookies()` or `browser.newContext({ storageState: 'auth.json' })`. This is significantly faster.
    -   **API Login**: If possible, bypass the UI for login and perform it via an API call in `beforeEach` to get a session cookie or token, then inject that into the page context.
    -   **Fixture for Authentication**: Use a Playwright fixture (`authenticatedPage`) that handles the login once (or uses stored state) and provides an already-authenticated page object to tests, improving reusability and efficiency.
    -   **Scope to `beforeAll`**: If *all* tests in a `describe` block can share the same logged-in session, move the login to `beforeAll`. However, be cautious about state leakage between tests in this scenario.

## Hands-on Exercise
1.  **Objective**: Create a test file (`todo-app.spec.ts`) that tests a simple To-Do application.
2.  **Setup**:
    -   Use `test.beforeAll` to print a message "Starting ToDo App Tests".
    -   Use `test.afterAll` to print "Finished ToDo App Tests" and simulate clearing all todos from a backend (e.g., `console.log('Clearing all todos...')`).
    -   Use `test.beforeEach` to navigate to a local or online ToDo app (e.g., `https://example.com/todo`).
    -   Use `test.afterEach` to take a screenshot if a test fails (check `testInfo.status`).
3.  **Tests**:
    -   Write a test that verifies the ToDo input field is visible.
    -   Write a test that adds a new ToDo item and asserts it appears in the list.
    -   Create a nested `describe` block for "Editing and Deleting ToDos".
        -   Inside this nested block, add a `beforeEach` that first adds a "Buy milk" ToDo item to ensure it exists for the edit/delete tests.
        -   Write a test to edit the "Buy milk" ToDo to "Buy organic milk".
        -   Write a test to delete the "Buy organic milk" ToDo.
4.  **Verification**: Run the tests and observe the console output to confirm the hooks execute in the expected order and scope. Check for screenshots if any test is intentionally made to fail.

## Additional Resources
-   **Playwright Test Hooks Documentation**: [https://playwright.dev/docs/test-hooks](https://playwright.dev/docs/test-hooks)
-   **Playwright Test Fixtures**: [https://playwright.dev/docs/test-fixtures](https://playwright.dev/docs/test-fixtures)
-   **Managing Authentication States with Playwright**: [https://playwright.dev/docs/auth](https://playwright.dev/docs/auth)
---
# playwright-5.4-ac7.md

# Playwright Test Grouping with `describe` Blocks

## Overview
In Playwright, as with many testing frameworks, organizing your tests effectively is crucial for maintainability, readability, and efficient execution. The `describe` block (or `test.describe`) provides a powerful mechanism to group related tests together. This not only makes your test suite more structured but also allows for shared setup/teardown logic using hooks (`beforeEach`, `afterEach`, `beforeAll`, `afterAll`) that apply specifically to tests within that group. Grouping tests ensures logical coherence and helps in understanding the scope of various test scenarios.

## Detailed Explanation
The `test.describe()` function in Playwright is used to define a test suite or a logical group of tests. It takes two arguments:
1.  A `name` (string): A descriptive title for the test group.
2.  A `callback` function: This function contains the actual tests (`test()`) and any hooks (`beforeEach`, `afterEach`, etc.) that apply to this specific group.

### Benefits of `describe` blocks:
*   **Organization:** Clearly delineates related tests, improving test suite structure.
*   **Scoped Hooks:** Hooks defined within a `describe` block only apply to tests inside that block, preventing unintended side effects or resource consumption.
*   **Reporting Clarity:** Most test reporters will show a hierarchy, making it easier to pinpoint failures within specific functional areas.
*   **Focused Execution:** You can run tests within a specific `describe` block using `test.describe.only()` for focused debugging.
*   **Nested Grouping:** `describe` blocks can be nested to create a hierarchical structure, representing complex application flows.

### Example Structure:

```typescript
// example.spec.ts

import { test, expect } from '@playwright/test';

// Outer describe block for a major feature
test.describe('User Authentication Flow', () => {

  // Hook specific to the authentication flow
  test.beforeEach(async ({ page }) => {
    await page.goto('https://example.com/login');
    // Common login steps
  });

  // Inner describe block for login scenarios
  test.describe('Login Functionality', () => {

    test('should allow a user to log in with valid credentials', async ({ page }) => {
      // Specific test steps for valid login
      await page.fill('#username', 'validUser');
      await page.fill('#password', 'validPass');
      await page.click('button[type="submit"]');
      await expect(page).toHaveURL(/dashboard/);
      await expect(page.locator('.welcome-message')).toContainText('Welcome, validUser');
    });

    test('should prevent login with invalid password', async ({ page }) => {
      // Specific test steps for invalid password
      await page.fill('#username', 'validUser');
      await page.fill('#password', 'wrongPass');
      await page.click('button[type="submit"]');
      await expect(page.locator('.error-message')).toContainText('Invalid credentials');
      await expect(page).toHaveURL(/login/);
    });

  });

  // Inner describe block for logout scenarios
  test.describe('Logout Functionality', () => {

    test.beforeEach(async ({ page }) => {
      // Assume user is already logged in for logout tests
      // This could involve a custom fixture or a direct login call
      await page.goto('https://example.com/dashboard'); // Or specific login steps
      // For demonstration, let's assume a prior login happened
    });

    test('should allow a logged-in user to log out', async ({ page }) => {
      await page.click('#logout-button');
      await expect(page).toHaveURL(/login/);
      await expect(page.locator('.login-form')).toBeVisible();
    });

  });

  // Test outside any inner describe, but within the outer one
  test('should display registration link on login page', async ({ page }) => {
    await page.goto('https://example.com/login');
    await expect(page.locator('a[href="/register"]')).toBeVisible();
  });

});
```

## Code Implementation
Below is a complete, runnable example demonstrating `describe` blocks and scoped hooks.

To run this example:
1.  Ensure you have Node.js and Playwright installed. (`npm init playwright@latest`)
2.  Create a file named `login.spec.ts` in your `tests` directory.
3.  Paste the code below into `login.spec.ts`.
4.  Run tests using `npx playwright test`.

```typescript
// tests/login.spec.ts
import { test, expect } from '@playwright/test';

// Define a base URL for convenience
const BASE_URL = 'https://www.saucedemo.com/'; // A public demo site for testing

// Outer describe block for the entire Login/Logout feature
test.describe('SauceDemo User Management', () => {
  let loggedInUser = { username: 'standard_user', password: 'secret_sauce' };
  let invalidUser = { username: 'locked_out_user', password: 'secret_sauce' };

  // This hook runs once before all tests in this outer describe block
  test.beforeAll(async () => {
    console.log('Starting User Management Tests');
  });

  // This hook runs once after all tests in this outer describe block
  test.afterAll(async () => {
    console.log('Finished User Management Tests');
  });

  // Nested describe block for Login functionality
  test.describe('Login Feature', () => {

    // This beforeEach hook runs before each test within this 'Login Feature' describe block
    test.beforeEach(async ({ page }) => {
      await page.goto(BASE_URL);
      await expect(page.locator('.login_logo')).toBeVisible(); // Verify we are on the login page
    });

    test('should allow a standard user to log in successfully', async ({ page }) => {
      await page.fill('[data-test="username"]', loggedInUser.username);
      await page.fill('[data-test="password"]', loggedInUser.password);
      await page.click('[data-test="login-button"]');

      await expect(page).toHaveURL(`${BASE_URL}inventory.html`);
      await expect(page.locator('.title')).toContainText('Products');
    });

    test('should display error for locked out user', async ({ page }) => {
      await page.fill('[data-test="username"]', invalidUser.username);
      await page.fill('[data-test="password"]', invalidUser.password);
      await page.click('[data-test="login-button"]');

      await expect(page.locator('[data-test="error"]')).toContainText('Epic sadface: Sorry, this user has been locked out.');
      await expect(page).toHaveURL(BASE_URL); // Should remain on login page
    });

    test('should display error for invalid credentials', async ({ page }) => {
      await page.fill('[data-test="username"]', 'invalid_user');
      await page.fill('[data-test="password"]', 'wrong_password');
      await page.click('[data-test="login-button"]');

      await expect(page.locator('[data-test="error"]')).toContainText('Epic sadface: Username and password do not match any user in this service');
      await expect(page).toHaveURL(BASE_URL); // Should remain on login page
    });

  });

  // Nested describe block for Logout functionality
  test.describe('Logout Feature', () => {

    // This beforeEach hook runs before each test within this 'Logout Feature' describe block
    // It ensures the user is logged in before attempting to log out
    test.beforeEach(async ({ page }) => {
      await page.goto(BASE_URL);
      await page.fill('[data-test="username"]', loggedInUser.username);
      await page.fill('[data-test="password"]', loggedInUser.password);
      await page.click('[data-test="login-button"]');
      await expect(page).toHaveURL(`${BASE_URL}inventory.html`); // Assert successful login
    });

    test('should allow a logged-in user to log out', async ({ page }) => {
      await page.click('#react-burger-menu-btn'); // Open hamburger menu
      await page.click('#logout_sidebar_link'); // Click logout link

      await expect(page).toHaveURL(BASE_URL); // Should redirect to login page
      await expect(page.locator('.login_logo')).toBeVisible(); // Verify login elements are present
    });

  });

  // A standalone test within the outer describe block but outside any inner describe
  test('should verify the application title on the login page', async ({ page }) => {
    await page.goto(BASE_URL);
    await expect(page).toHaveTitle('Swag Labs');
  });

});
```

## Best Practices
-   **Logical Grouping:** Group tests that belong to the same feature, module, or user story. This improves readability and makes it easier to navigate the test suite.
-   **Descriptive Names:** Use clear and concise names for `describe` blocks that accurately reflect the functionality being tested (e.g., "User Registration Flow", "Product Search", "Shopping Cart Operations").
-   **Scoped Hooks:** Utilize `beforeEach`, `afterEach`, `beforeAll`, `afterAll` within `describe` blocks to manage setup and teardown for specific groups of tests, ensuring resources are isolated and tests are independent.
-   **Nesting:** Use nested `describe` blocks for complex features to create a hierarchical structure that mirrors your application's logic. Avoid excessive nesting, which can make tests hard to read.
-   **`test.describe.only()` and `test.describe.skip()`:** Use these for debugging specific test groups or temporarily disabling them. Remember to remove `.only()` before committing.
-   **Page Object Model (POM):** Combine `describe` blocks with POM for even better organization. A `describe` block can test methods within a specific Page Object.

## Common Pitfalls
-   **Over-reliance on Global Hooks:** Placing all `beforeEach`/`afterEach` hooks at the top level can lead to unnecessary setup/teardown for tests that don't require it, slowing down execution and increasing test flakiness.
-   **Poor Naming:** Vague `describe` block names make it hard to understand what feature is being tested without diving into individual `test` cases.
-   **Deep Nesting:** While nesting is good, too many levels of nested `describe` blocks can make test paths long and reports difficult to interpret. Aim for a reasonable depth (e.g., 2-3 levels).
-   **Side Effects between `describe` blocks:** Ensure that tests or hooks in one `describe` block do not inadvertently affect the state or execution of tests in another `describe` block, especially if they share resources without proper teardown.
-   **Not Using `test.describe` for Fixtures:** Custom fixtures can be defined at the `describe` level to provide specific setup for a group of tests, a powerful but sometimes overlooked feature.

## Interview Questions & Answers
1.  **Q: What is the purpose of `describe` blocks in Playwright, and why are they important for a well-structured test suite?**
    **A:** `describe` blocks (or `test.describe`) are used to logically group related tests together. They are crucial for a well-structured test suite because they improve readability, maintainability, and reporting clarity. By grouping tests, we can apply scoped setup/teardown logic using hooks (`beforeEach`, `afterAll`, etc.) that only affect tests within that group, preventing side effects and making tests more independent. This organization also helps in navigating large test suites and understanding which functional area a test belongs to.

2.  **Q: How do hooks (`beforeEach`, `afterAll`) interact with nested `describe` blocks in Playwright?**
    **A:** Hooks in Playwright are scoped to their `describe` block. A `beforeEach` hook defined within a `describe` block will run before *each* test within that specific `describe` block and any of its nested `describe` blocks. Conversely, a `beforeAll` hook will run *once* before all tests in its `describe` block and its nested blocks. Hooks in an outer `describe` block will always execute before hooks in an inner `describe` block, providing a clear execution order for setup and teardown. This hierarchical application of hooks is vital for managing test context effectively.

3.  **Q: When would you use `test.describe.only()` versus `test.only()`?**
    **A:** `test.describe.only()` is used to execute only a specific group of tests defined by a `describe` block, skipping all other `describe` blocks and standalone tests in the file. This is useful when you want to focus on a particular feature or set of related scenarios for debugging. `test.only()`, on the other hand, is used to run a single, specific test case, skipping all other tests and `describe` blocks. Both are for focused execution during development but target different granularities: `test.describe.only()` for a suite of tests, `test.only()` for an individual test.

## Hands-on Exercise
**Objective:** Refactor an existing, unorganized Playwright test file into a structured suite using `describe` blocks and appropriate hooks.

1.  **Create a new file:** `tests/unorganized-cart.spec.ts`
2.  **Paste the following unorganized tests:**

    ```typescript
    // tests/unorganized-cart.spec.ts
    import { test, expect } from '@playwright/test';

    const BASE_URL = 'https://www.saucedemo.com/';
    const loggedInUser = { username: 'standard_user', password: 'secret_sauce' };

    test('login as standard user', async ({ page }) => {
        await page.goto(BASE_URL);
        await page.fill('[data-test="username"]', loggedInUser.username);
        await page.fill('[data-test="password"]', loggedInUser.password);
        await page.click('[data-test="login-button"]');
        await expect(page).toHaveURL(`${BASE_URL}inventory.html`);
    });

    test('add backpack to cart', async ({ page }) => {
        // Assume logged in
        await page.goto(`${BASE_URL}inventory.html`);
        await page.click('[data-test="add-to-cart-sauce-labs-backpack"]');
        await expect(page.locator('.shopping_cart_badge')).toContainText('1');
    });

    test('remove backpack from cart', async ({ page }) => {
        // Assume logged in and item added
        await page.goto(`${BASE_URL}cart.html`);
        await page.click('[data-test="remove-sauce-labs-backpack"]');
        await expect(page.locator('.shopping_cart_badge')).not.toBeVisible();
    });

    test('go to checkout from cart', async ({ page }) => {
        // Assume logged in and item in cart
        await page.goto(`${BASE_URL}cart.html`);
        await page.click('[data-test="checkout"]');
        await expect(page).toHaveURL(`${BASE_URL}checkout-step-one.html`);
    });

    test('add bike light to cart', async ({ page }) => {
        // Assume logged in
        await page.goto(`${BASE_URL}inventory.html`);
        await page.click('[data-test="add-to-cart-sauce-labs-bike-light"]');
        await expect(page.locator('.shopping_cart_badge')).toContainText('1');
    });
    ```

3.  **Your Task:**
    *   Create a main `describe` block for "Shopping Cart Management".
    *   Create nested `describe` blocks for "Adding Items" and "Removing Items".
    *   Implement `beforeEach` hooks to handle the login process once for the "Shopping Cart Management" block.
    *   Implement another `beforeEach` hook for the "Removing Items" block to ensure an item is already in the cart before removal tests.
    *   Ensure each `test` block has a clear, descriptive name.
    *   Run `npx playwright test tests/unorganized-cart.spec.ts` to verify your refactoring.

## Additional Resources
-   **Playwright Test Documentation - Grouping tests:** [https://playwright.dev/docs/test-configuration#grouping-tests](https://playwright.dev/docs/test-configuration#grouping-tests)
-   **Playwright Test Documentation - Hooks:** [https://playwright.dev/docs/test-hooks](https://playwright.dev/docs/test-hooks)
-   **Sauce Labs Demo Site:** [https://www.saucedemo.com/](https://www.saucedemo.com/) (Useful for practicing web automation)
---
# playwright-5.4-ac8.md

# Playwright: Skipping and Focusing Tests (`test.skip()`, `test.only()`, `test.fixme()`)

## Overview
In Playwright, efficiently managing test execution is crucial for rapid development and effective debugging. The `test.skip()`, `test.only()`, and `test.fixme()` methods provide powerful mechanisms to control which tests run, allowing developers and SDETs to focus on specific tests, temporarily disable failing ones, or mark tests that need attention for future repairs. These features are indispensable for maintaining productivity in large test suites.

## Detailed Explanation

### `test.only()`: Focusing on Specific Tests
During development or debugging, you often need to run only a subset of your tests. `test.only()` allows you to mark a specific test or a describe block to be the *only* one executed. All other tests in your suite will be skipped. This is particularly useful when you're working on a new feature, fixing a bug, or trying to isolate a flaky test.

**When to use:**
- Debugging a failing test in isolation.
- Developing a new test and wanting to run only that test repeatedly.
- Focusing on a specific feature's tests.

### `test.skip()`: Temporarily Skipping Tests
`test.skip()` is used to temporarily disable a test or an entire test suite (`describe` block). This is common when a test is known to be failing due to a bug in the application that hasn't been fixed yet, or when a feature is temporarily disabled. Skipping tests ensures that your CI/CD pipeline doesn't break due to known, but not yet resolved, issues. You can also conditionally skip tests based on environment, browser, or operating system.

**When to use:**
- A known application bug makes a test fail, and the bug is not yet fixed.
- A feature is under development or temporarily disabled, rendering its tests irrelevant for now.
- Skipping tests on specific browsers or operating systems where they are not applicable or consistently failing.

### `test.fixme()`: Marking Tests for Repair
`test.fixme()` is a specialized skip method that explicitly marks a test as "expected to fail" or "needs repair." When a test is marked with `test.fixme()`, Playwright will execute it. If the test passes, Playwright will report it as a failure, indicating that the test no longer needs to be marked as `fixme` and should be fixed or un-skipped. If it fails, it reports as `skipped` without breaking the build. This is ideal for tests that are currently broken but are actively being worked on or are high priority to fix.

**When to use:**
- Tests that are currently failing due to issues in the test code itself or a high-priority application bug that needs immediate attention.
- Communicating to team members that a specific test is broken and needs to be fixed.

## Code Implementation

Let's demonstrate these concepts with a Playwright test file.

```typescript
// example.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Test Skipping and Focusing Features', () => {

  // This test will be the ONLY one that runs if 'test.only' is uncommented
  // test.only('should log in a user successfully', async ({ page }) => {
  test('should log in a user successfully', async ({ page }) => {
    console.log('Running: should log in a user successfully');
    await page.goto('https://www.example.com/login');
    await page.fill('#username', 'testuser');
    await page.fill('#password', 'password123');
    await page.click('#login-button');
    await expect(page).toHaveURL(/.*dashboard/);
    console.log('Completed: should log in a user successfully');
  });

  // This test will be skipped
  test.skip('should handle invalid login credentials', async ({ page }) => {
    console.log('Running: should handle invalid login credentials (this should not appear)');
    await page.goto('https://www.example.com/login');
    await page.fill('#username', 'invalid');
    await page.fill('#password', 'wrong');
    await page.click('#login-button');
    await expect(page.locator('.error-message')).toHaveText('Invalid credentials');
    console.log('Completed: should handle invalid login credentials (this should not appear)');
  });

  // This test will be marked for future repair.
  // Playwright will execute it, and if it passes, it will report it as a failure.
  test.fixme('should display product details correctly', async ({ page }) => {
    console.log('Running: should display product details correctly (fixme)');
    await page.goto('https://www.example.com/products/1');
    // Simulate a test that is expected to fail or has not been fully implemented
    await expect(page.locator('#product-title')).toHaveText('Broken Product Title', { timeout: 100 }); // This will likely fail
    console.log('Completed: should display product details correctly (fixme)');
  });

  // Conditional skipping based on environment or browser
  test('should work only on Chromium', async ({ browserName }) => {
    test.skip(browserName !== 'chromium', 'Feature is specific to Chromium');
    console.log(`Running: should work only on Chromium on ${browserName}`);
    // Test steps specific to Chromium
    expect(browserName).toBe('chromium');
    console.log(`Completed: should work only on Chromium on ${browserName}`);
  });

  test.describe('Navigation tests', () => {
    // This entire describe block will be skipped if uncommented
    // test.skip(true, 'Navigation features are unstable');

    test('should navigate to about page', async ({ page }) => {
      console.log('Running: should navigate to about page');
      await page.goto('https://www.example.com');
      await page.click('text=About');
      await expect(page).toHaveURL(/.*about/);
      console.log('Completed: should navigate to about page');
    });

    // test.only inside a describe block will only run this test, skipping others in the same describe and other describe blocks
    // test.only('should navigate to contact page', async ({ page }) => {
    test('should navigate to contact page', async ({ page }) => {
      console.log('Running: should navigate to contact page');
      await page.goto('https://www.example.com');
      await page.click('text=Contact');
      await expect(page).toHaveURL(/.*contact/);
      console.log('Completed: should navigate to contact page');
    });
  });
});

/*
To run these tests:
1. Save the code as `example.spec.ts` in your Playwright project's `tests` directory.
2. Run `npx playwright test example.spec.ts` from your terminal.

Experiment by:
- Uncommenting `test.only` on line 9 and observing that only that test runs.
- Removing `test.skip` on line 19 and seeing it fail (if example.com doesn't have that element).
- Observing the `test.fixme` behavior, especially if you make it pass.
*/
```

## Best Practices
- **Use `test.only()` sparingly and locally:** It's a debugging tool, not something to commit to version control. Always ensure `test.only()` is removed before pushing changes.
- **Provide clear reasons for `test.skip()`:** Add a comment or a message to `test.skip()` explaining *why* the test is skipped (e.g., `test.skip('Bug #1234: Login button sometimes unresponsive')`).
- **Regularly review `test.skip()` and `test.fixme()`:** These tests represent known issues or incomplete work. They should be revisited periodically to ensure they are either fixed or still relevant to be skipped/fixed.
- **Conditional skipping for environment differences:** Use `test.skip(process.env.CI === 'true', 'This test is flaky in CI')` or `test.skip(browserName === 'webkit', 'Feature not supported on WebKit')` to manage environment-specific test behavior.
- **Prioritize fixing `test.fixme()` tests:** Treat `test.fixme()` as a temporary state for tests that are broken but need immediate attention. A passing `test.fixme()` should prompt you to fix the underlying issue or the test itself.

## Common Pitfalls
- **Committing `test.only()`:** Accidentally committing `test.only()` can lead to missed test coverage in CI/CD pipelines, giving a false sense of security. Always double-check before committing.
- **Overusing `test.skip()`:** Too many skipped tests can hide regressions and indicate a poorly maintained test suite. Use it judiciously and only for well-justified reasons.
- **Ignoring `test.fixme()` warnings:** If a `test.fixme()` test starts passing, Playwright will report it as a failure. Ignoring this warning means you're missing an opportunity to re-enable a functional test and potentially uncover new issues.
- **Lack of context for skipped tests:** Without a good reason, `test.skip()` can be confusing for other team members and make it hard to determine if the skip is still valid.

## Interview Questions & Answers

1.  **Q: Explain the difference between `test.skip()` and `test.fixme()` in Playwright. When would you use each?**
    **A:** `test.skip()` is used to prevent a test from running entirely, typically when there's a known, unresolved issue (e.g., an application bug) or when a feature is temporarily unavailable. It's for tests that you *don't want* to run for now. `test.fixme()`, on the other hand, marks a test as "expected to fail" or "needs repair." Playwright *will execute* `test.fixme()` tests. If a `fixme` test fails, it's reported as skipped (without failing the build). Crucially, if a `fixme` test *passes*, Playwright will report it as a *failure*, indicating that the test's underlying issue is resolved and it should no longer be marked `fixme`. You'd use `test.skip()` for stable but currently irrelevant/failing tests due to external factors, and `test.fixme()` for tests that are broken but are actively being worked on or need immediate repair, leveraging its built-in mechanism to alert you when the test becomes healthy.

2.  **Q: How do you ensure `test.only()` doesn't get committed to your repository?**
    **A:** The primary way is through developer discipline and code review processes. Developers should always remove `test.only()` before staging and committing their changes. Automated tools like pre-commit hooks (e.g., using Husky and lint-staged) can be configured to detect `test.only()` statements in staged files and prevent the commit, or even automatically remove them. Continuous Integration (CI) pipelines can also include checks to fail builds if `test.only()` is found in any pushed code.

3.  **Q: Can you conditionally skip tests in Playwright? Provide an example scenario.**
    **A:** Yes, you can conditionally skip tests using `test.skip()` with a condition. An example scenario is when a particular feature or UI element behaves differently or is completely absent on a specific browser or operating system.
    ```typescript
    test('should only run on Windows', async ({ page, browserName, platform }) => {
      // Assuming 'platform' is accessible via a custom fixture or environment variable
      test.skip(platform !== 'win32', 'This test is specific to Windows OS');
      // Test steps for Windows-specific functionality
      await page.goto('https://example.com/windows-feature');
      await expect(page.locator('#windows-specific-element')).toBeVisible();
    });

    test('should skip on WebKit browsers', async ({ browserName }) => {
      test.skip(browserName === 'webkit', 'WebKit has known rendering issues with this component');
      // Test steps that might fail on WebKit
      await page.goto('https://example.com/complex-component');
      await expect(page.locator('.complex-animation')).toBeVisible();
    });
    ```
    This helps maintain a healthy test suite by avoiding unnecessary failures on platforms where tests are not expected to pass.

## Hands-on Exercise

**Scenario:** You are working on a new e-commerce application. A critical product search feature has a known bug (`BUG-5432`) where search results are sometimes empty when filtering by "out of stock" items. Additionally, a new "guest checkout" feature is under active development and its tests are currently unstable.

**Task:**
1.  Create a Playwright test file (e.g., `ecommerce.spec.ts`).
2.  Write a test for the "product search with 'out of stock' filter" feature. Mark this test to be skipped due to `BUG-5432`.
3.  Write a test for the "guest checkout" feature. Mark this test as `fixme` because it's unstable and needs repair.
4.  Write a test for a "user registration" feature. Temporarily use `test.only()` on this test to simulate focusing on it during development.
5.  Run your tests and observe the output. Ensure only the "user registration" test runs (initially), and then adjust to see the skipped and fixme behavior correctly reported.

**Expected Output (after removing `test.only()` and running all tests):**
- "product search with 'out of stock' filter" should be skipped.
- "guest checkout" should be reported as `skipped` (if it fails) or `failed` (if it passes unexpectedly).
- "user registration" should pass.

## Additional Resources
- **Playwright Test Configuration:** [https://playwright.dev/docs/test-configuration#test-filtering](https://playwright.dev/docs/test-configuration#test-filtering)
- **Playwright `test.only` and `test.skip`:** [https://playwright.dev/docs/api/class-test#test-only](https://playwright.dev/docs/api/class-test#test-only)
- **Playwright `test.fixme`:** [https://playwright.dev/docs/api/class-test#test-fixme](https://playwright.dev/docs/api/class-test#test-fixme)
---
# playwright-5.4-ac9.md

# Playwright Test Annotations and Attachments with `test.info()`

## Overview
In Playwright, `test.info()` provides a powerful mechanism to enrich your test reports with custom metadata, annotations, and attached files. This is crucial for improving the traceability, debuggability, and overall understanding of test execution, especially in complex test suites or CI/CD pipelines. By adding context-specific information, you can make your HTML reports more informative, helping teams quickly grasp what happened during a test run, why a test might have failed, or to categorize tests more effectively.

Annotations allow you to tag tests with arbitrary key-value pairs (e.g., `severity`, `jira`, `owner`), while attachments enable you to link files (screenshots, videos, logs, network data) directly to test results.

## Detailed Explanation
`test.info()` returns an object that provides access to various test run properties and methods for adding supplementary data. The two primary methods for this feature are:

1.  **`test.info().annotations.push({ type: '...', description?: '...' })`**: This method allows you to add custom annotations to a test. An annotation is a simple object with a `type` (required string) and an optional `description` (string). These annotations can be used for various purposes such as:
    *   **Categorization**: Mark tests as `smoke`, `regression`, `e2e`, `performance`.
    *   **Metadata**: Add `jira` ticket IDs, `owner` names, or `severity` levels.
    *   **Conditional Logic**: In custom reporters, you could potentially use these annotations to filter or process tests differently.

2.  **`test.info().attach(name: string, options: { path?: string, body?: string | Buffer, contentType?: string })`**: This method is used to attach files or data directly to the test report. When a test fails, attaching relevant artifacts like screenshots, videos, or network logs is invaluable for debugging. Playwright automatically attaches screenshots and videos on failure by default, but `test.info().attach()` gives you explicit control to attach custom data at any point in your test.
    *   `name`: A unique name for the attachment. This will appear in the report.
    *   `path`: (Optional) Path to a file on the file system to attach. Playwright will copy this file to the report directory.
    *   `body`: (Optional) The content of the attachment as a string or Buffer. Useful for attaching small text logs or JSON data directly without creating a file.
    *   `contentType`: (Optional) The MIME type of the attachment (e.g., `'image/png'`, `'text/plain'`, `'application/json'`). This helps the report viewer render the content appropriately.

These annotations and attachments are then visible in the Playwright HTML report, providing a comprehensive view of each test's execution context and outcomes.

## Code Implementation
Here's a complete Playwright test file demonstrating how to use `test.info().annotations.push()` and `test.info().attach()`.

```typescript
// tests/example.spec.ts
import { test, expect } from '@playwright/test';
import { writeFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';

// Define a directory for test artifacts
const ARTIFACTS_DIR = './test-artifacts';
if (!existsSync(ARTIFACTS_DIR)) {
  mkdirSync(ARTIFACTS_DIR);
}

test.describe('User Profile Management', () => {

  test('should allow user to update their profile information with high severity', async ({ page }, testInfo) => {
    // Add custom annotations
    testInfo.annotations.push({ type: 'feature', description: 'User Profile' });
    testInfo.annotations.push({ type: 'severity', description: 'High' });
    testInfo.annotations.push({ type: 'jira', description: 'PROJ-1234' });

    // Simulate navigating to a profile page
    await page.goto('https://example.com/profile'); // Replace with a real URL for a runnable test

    // Attach a simulated log file
    const logContent = `[${new Date().toISOString()}] Navigated to profile page.
`;
    const logFilePath = join(ARTIFACTS_DIR, `profile-update-${testInfo.testId}.log`);
    writeFileSync(logFilePath, logContent);
    testInfo.attach('profile-log', { path: logFilePath, contentType: 'text/plain' });

    // Simulate filling out a form
    await page.fill('#username', 'new_username');
    await page.fill('#email', 'new_email@example.com');

    // Attach form data as JSON directly
    const formData = {
      username: 'new_username',
      email: 'new_email@example.com',
      timestamp: new Date().toISOString()
    };
    testInfo.attach('form-data', { body: JSON.stringify(formData, null, 2), contentType: 'application/json' });

    // Simulate saving changes
    await page.click('#saveButton');

    // Add another log entry after interaction
    const postActionLogContent = `[${new Date().toISOString()}] Profile update initiated.
`;
    writeFileSync(logFilePath, postActionLogContent, { flag: 'a' }); // Append to the log
    testInfo.attach('profile-update-after-action-log', { path: logFilePath, contentType: 'text/plain' }); // Re-attach with updated content if necessary, or a new name

    // Take a screenshot of the updated profile (Playwright usually does this on failure)
    // You can explicitly take and attach it for specific test steps or success cases
    const screenshotPath = join(ARTIFACTS_DIR, `profile-updated-${testInfo.testId}.png`);
    await page.screenshot({ path: screenshotPath });
    testInfo.attach('profile-updated-screenshot', { path: screenshotPath, contentType: 'image/png' });

    // Assertions
    await expect(page.locator('.success-message')).toHaveText('Profile updated successfully!');
    // If the test fails, these attachments will be available in the report.
  });

  test('should handle invalid email format during profile update', async ({ page }, testInfo) => {
    testInfo.annotations.push({ type: 'negative-test', description: 'Email validation' });
    testInfo.annotations.push({ type: 'severity', description: 'Medium' });

    await page.goto('https://example.com/profile');
    await page.fill('#username', 'testuser');
    await page.fill('#email', 'invalid-email'); // Invalid email format
    await page.click('#saveButton');

    // Attach the current page content for debugging invalid input scenarios
    testInfo.attach('page-content-on-error', { body: await page.content(), contentType: 'text/html' });

    await expect(page.locator('.error-message')).toHaveText('Invalid email format');
  });

});
```

To run this test and view the report:
1.  Save the code as `example.spec.ts` in your Playwright `tests` directory.
2.  Run Playwright tests: `npx playwright test`
3.  Open the HTML report: `npx playwright show-report`

You will see the annotations and attachments under each test in the generated HTML report.

## Best Practices
-   **Strategic Annotation**: Use annotations to categorize tests (e.g., `smoke`, `e2e`, `critical`), link to external systems (e.g., Jira tickets), or denote test ownership. This helps in filtering reports and understanding test coverage.
-   **Contextual Attachments**: Attach relevant artifacts that aid debugging. For UI tests, screenshots and videos on failure are standard. For API tests, consider attaching request/response payloads. For performance tests, attach metrics.
-   **Clear Naming**: Give meaningful names to your attachments (`login-form-data.json`, `network-logs.har`, `checkout-screenshot.png`) so they are easily identifiable in the report.
-   **Automate Attachments**: While `test.info().attach()` gives manual control, leverage Playwright's automatic attachment capabilities (e.g., `screenshot: 'only-on-failure'`, `video: 'on'`) in your `playwright.config.ts` for common scenarios.
-   **Cleanup Artifacts**: If you manually create files for attachment (like in the example), ensure your test environment or CI/CD pipeline cleans up these temporary files after the test run to prevent disk space issues.

## Common Pitfalls
-   **Over-attaching**: Attaching too many large files (e.g., full DOM snapshots for every step of every test) can bloat your test reports, making them slow to load and difficult to navigate. Be selective and attach only what's truly necessary.
-   **Sensitive Data in Attachments**: Be cautious not to attach sensitive information (passwords, API keys) directly into reports. If necessary, sanitize data before attaching.
-   **Missing `testInfo` Parameter**: For `test.info()` to be available, the `testInfo` fixture must be passed to your test function, typically as the second argument (e.g., `async ({ page }, testInfo)`). For `test.describe` hooks (e.g., `beforeEach`, `afterEach`), `testInfo` is not directly available, but you can access `test.info()` within the test functions themselves or through `test.afterEach(async ({ }, testInfo) => {})` style hooks.
-   **Incorrect Content Type**: Attaching a file with the wrong `contentType` might prevent the HTML report from displaying it correctly (e.g., a `.json` file attached as `text/plain` might not be syntax-highlighted).

## Interview Questions & Answers
1.  **Q: How can you add custom metadata to a Playwright test run for better reporting?**
    **A:** You can use `test.info().annotations.push()` to add custom annotations. These are key-value pairs (`type`, `description`) that appear in the HTML report and can be used for categorization (e.g., `severity: 'High'`, `feature: 'Authentication'`) or linking to external systems (e.g., `jira: 'BUG-456'`).

2.  **Q: Describe a scenario where you would manually use `test.info().attach()` instead of relying on Playwright's automatic screenshot/video capture.**
    **A:** While Playwright automatically captures screenshots/videos on failure, `test.info().attach()` is useful for:
    *   **Capturing specific states on success**: For example, taking a screenshot of a generated report or a complex dashboard after a successful data submission.
    *   **Attaching non-visual data**: Such as API request/response bodies, network HAR files for specific interactions, console logs, or application state (e.g., Redux store snapshot) at a particular point in the test.
    *   **Custom error diagnostics**: Attaching specific debug information *before* an expected failure or a point of interest, even if the test eventually passes or fails for other reasons.

3.  **Q: What are the benefits of using `test.info().annotations` in a large test suite?**
    **A:** In a large test suite, annotations provide several benefits:
    *   **Improved Report Filtering**: Custom reporters can filter or group tests based on annotations (e.g., "show me all smoke tests" or "show me tests for Jira PROJ-123").
    *   **Better Test Insights**: They offer immediate context in reports, helping engineers understand the purpose, scope, or impact of a test without digging into the code.
    *   **Prioritization**: Annotations like `severity` or `priority` can help teams quickly identify and address failures in critical tests.
    *   **Test Maintenance**: Identifying test ownership or related feature areas helps in delegating maintenance tasks.

## Hands-on Exercise
**Exercise: Extend the Profile Update Test**

Modify the provided `example.spec.ts` test to include the following:

1.  **Add a new annotation**: Mark the `should allow user to update their profile information` test with an `owner` annotation, assigning it to your name or team.
2.  **Conditional Attachment**: In the `should handle invalid email format` test, if an error message is *not* found (meaning the validation failed to trigger), attach a screenshot and the full page HTML to the report specifically for this unexpected scenario.
3.  **Attach Network Logs (Mock/Simulated)**: Before the `page.goto()` in the first test, simulate writing a small JSON file containing mock network requests/responses and attach it with `contentType: 'application/json'`. This demonstrates how you might attach network activity logs.

**Hint for Conditional Attachment**: You'll need an `if (!expect(locator).toBeVisible())` or similar logic to trigger the conditional attachment. Remember `await page.screenshot()` and `await page.content()`.

## Additional Resources
-   **Playwright Test Info API**: [https://playwright.dev/docs/api/class-testinfo](https://playwright.dev/docs/api/class-testinfo)
-   **Playwright Test Annotations**: [https://playwright.dev/docs/api/class-testinfo#test-info-annotations](https://playwright.dev/docs/api/class-testinfo#test-info-annotations)
-   **Playwright Test Attachments**: [https://playwright.dev/docs/api/class-testinfo#test-info-attach](https://playwright.dev/docs/api/class-testinfo#test-info-attach)
-   **Playwright Configuration (for automatic attachments)**: [https://playwright.dev/docs/test-configuration#default-values](https://playwright.dev/docs/test-configuration#default-values)
