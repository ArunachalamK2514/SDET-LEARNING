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
