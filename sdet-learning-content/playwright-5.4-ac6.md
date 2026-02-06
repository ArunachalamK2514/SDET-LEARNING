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
