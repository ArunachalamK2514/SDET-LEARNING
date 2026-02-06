# Playwright: Reusing Authentication State Across Tests

## Overview
In end-to-end testing, logging into an application for every single test case can be a significant bottleneck, leading to slower test execution times and increased flakiness. Playwright provides a robust mechanism to capture and reuse authentication states, allowing tests to start directly from an authenticated session without repeatedly performing login actions. This significantly speeds up test suites and improves their reliability. This feature is crucial for efficient test automation in real-world applications.

## Detailed Explanation
Playwright's `storageState` option allows you to save the browser's authentication state (cookies, local storage, session storage) to a JSON file. This file can then be loaded by subsequent tests or test files, effectively restoring the user's logged-in session.

The typical workflow involves:
1.  **Login once**: Create a dedicated "login" test or a setup fixture that performs the login steps and saves the `storageState` to a file (e.g., `auth.json`).
2.  **Reuse state**: Configure your Playwright project to use this `auth.json` file for all tests that require an authenticated user. This ensures that every test context starts with the saved authentication state.

This approach is particularly beneficial for:
*   **Large test suites**: Avoids redundant login steps.
*   **Faster feedback**: Developers get quicker test results.
*   **Reduced flakiness**: Login processes can sometimes be unstable; reusing a stable state mitigates this.

### `storageState` Options:
*   **`storageState: 'path/to/auth.json'` (in `playwright.config.ts`)**: This tells Playwright to load the authentication state from the specified file for all tests running in that project.
*   **`browserContext.storageState()` (programmatic)**: Allows you to programmatically save the `storageState` from a browser context. This is used in the initial login script.
*   **`browser.newContext({ storageState: 'path/to/auth.json' })` (programmatic)**: Allows you to programmatically create a new browser context with a loaded authentication state.

## Code Implementation

First, let's create a setup file (e.g., `global.setup.ts`) to log in and save the authentication state.

```typescript
// global.setup.ts
import { test as setup, expect } from '@playwright/test';

const AUTH_FILE = 'playwright-auth.json'; // Define a constant for the auth file name

setup('authenticate', async ({ page }) => {
  // Navigate to the login page
  await page.goto('https://www.saucedemo.com/'); // Replace with your application's login URL

  // Perform login steps
  await page.fill('input[data-test="username"]', 'standard_user');
  await page.fill('input[data-test="password"]', 'secret_sauce');
  await page.click('input[data-test="login-button"]');

  // Verify successful login (e.g., check for a specific element on the dashboard)
  await expect(page.locator('.inventory_list')).toBeVisible();

  // Save authentication state
  await page.context().storageState({ path: AUTH_FILE });
  console.log(`Authentication state saved to ${AUTH_FILE}`);
});
```

Next, configure `playwright.config.ts` to run this setup and use the saved state.

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

/**
 * Read environment variables from file.
 * https://github.com/motdotla/dotenv
 */
// require('dotenv').config();

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: './tests', // Your test files directory
  /* Run your local dev server before starting the tests */
  // webServer: {
  //   command: 'npm run start',
  //   url: 'http://127.0.0.1:3000',
  //   reuseExistingServer: !process.env.CI,
  // },

  // Global setup file to run once before all tests
  globalSetup: require.resolve('./global.setup'), // Path to your setup file

  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    // baseURL: 'http://127.0.0.1:3000',

    /* Collect traces upon retrying the first time. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
    // Reuse authentication state from the saved file
    storageState: 'playwright-auth.json', // Must match the file name saved in global.setup.ts
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    // Add other browsers if needed
  ],
});
```

Finally, write your actual test files. These tests will automatically start in a logged-in state.

```typescript
// tests/dashboard.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Dashboard Functionality', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the application's base URL.
    // The browser context should already be logged in due to storageState.
    await page.goto('https://www.saucedemo.com/inventory.html'); // Assuming this is the authenticated dashboard URL
  });

  test('should display inventory items after successful authentication', async ({ page }) => {
    // Verify that inventory items are visible without explicit login steps
    await expect(page.locator('.inventory_item')).toHaveCount(6);
    await expect(page.locator('.inventory_item_name').first()).toHaveText('Sauce Labs Backpack');
  });

  test('should be able to navigate to product details page', async ({ page }) => {
    await page.locator('#item_4_title_link').click();
    await expect(page.url()).toContain('/inventory-item.html?id=4');
    await expect(page.locator('.inventory_details_name')).toHaveText('Sauce Labs Backpack');
  });
});
```

To run this:
1.  Make sure you have Playwright installed (`npm init playwright@latest`).
2.  Save the files as `global.setup.ts`, `playwright.config.ts`, and `tests/dashboard.spec.ts`.
3.  Run `npx playwright test`.

You will observe that the `authenticate` setup runs once, creates `playwright-auth.json`, and then all subsequent tests immediately start on the inventory page without performing login actions.

## Best Practices
-   **Isolate Login**: Create a single, dedicated setup script or test file responsible for logging in and saving the `storageState`. This centralizes your authentication logic.
-   **Ephemeral `storageState`**: Consider cleaning up the `auth.json` file after the test run, especially in CI/CD environments, to ensure a clean state for subsequent runs. Or, let Playwright handle it within its temporary test runner environment.
-   **Security**: Do not commit `auth.json` files to your version control system, as they might contain sensitive user tokens. Ensure they are added to `.gitignore`.
-   **Multiple Users**: For scenarios requiring different user roles, create separate `storageState` files (e.g., `admin-auth.json`, `guest-auth.json`) and configure different Playwright projects in `playwright.config.ts` to use them.
-   **Avoid Over-reliance**: While useful, don't completely abandon testing the login flow itself. Periodically run a full end-to-end test that includes the login steps to ensure that part of the application remains functional.
-   **Use `baseURL`**: Define `baseURL` in `playwright.config.ts` to make your `page.goto()` calls cleaner (e.g., `await page.goto('/inventory.html')`).

## Common Pitfalls
-   **`auth.json` not found**: If the `globalSetup` script fails to run or fails to save the `storageState` file, subsequent tests will fail because they won't find the `auth.json` file. Ensure `globalSetup` path is correct and the setup script passes.
-   **Expired Sessions**: Authentication tokens can expire. If your tests run for a very long time, or if the `auth.json` is reused across different test runs over days, the saved session might become invalid, leading to unauthorized errors. Re-running the `globalSetup` (e.g., by deleting `auth.json` or forcing it) usually fixes this.
-   **Incorrect `storageState` path**: Mismatch between the path where the `storageState` is saved and where it's loaded from in `playwright.config.ts` will cause issues. Use a constant for the filename.
-   **State Pollution**: Be mindful that `storageState` captures *all* local storage, session storage, and cookies. If your application has complex state management, this could inadvertently lead to tests being affected by previous test runs. Isolate tests as much as possible.

## Interview Questions & Answers
1.  **Q**: How can you optimize Playwright test execution time, especially for tests that require a logged-in user?
    **A**: By using Playwright's `storageState` feature. This involves creating a `globalSetup` script to log in once, save the authentication state to a JSON file (e.g., `auth.json`), and then configuring `playwright.config.ts` to load this `storageState` for all relevant test projects. This allows tests to bypass repetitive login steps, starting directly from an authenticated session, significantly speeding up the test suite.

2.  **Q**: Explain the security implications of `storageState` and how you would mitigate them.
    **A**: The `storageState` file contains sensitive information like authentication tokens and session cookies. The primary security concern is committing this file to version control, which could expose credentials. Mitigation strategies include:
    *   Adding `auth.json` (or whatever your file is named) to `.gitignore`.
    *   Ensuring `storageState` files are generated on-the-fly during CI/CD runs and never persisted in shared environments.
    *   Considering short-lived tokens or mechanisms to invalidate sessions after test runs, if applicable to the application under test.

3.  **Q**: When would you NOT use `storageState` for authentication in Playwright tests?
    **A**: You would avoid using `storageState` in scenarios where:
    *   You specifically need to test the login/logout flow itself.
    *   Each test requires a unique user account or a different authentication state (though you could generate multiple `storageState` files for this).
    *   The application's authentication state is highly dynamic or tied to specific browser sessions in a way that `storageState` capture/restore might not fully replicate.
    *   The overhead of logging in is negligible compared to the test's overall execution time.

## Hands-on Exercise
1.  **Objective**: Adapt the provided code to test a different authenticated page in the Sauce Demo application (e.g., the shopping cart page after adding an item).
2.  **Instructions**:
    *   Modify `global.setup.ts` if needed (though the login part remains the same).
    *   Create a new test file, `tests/cart.spec.ts`.
    *   In `cart.spec.ts`, navigate to the inventory page, add an item to the cart, then navigate to the cart page.
    *   Verify that the cart page shows the added item, ensuring you are still logged in.
    *   Ensure the tests run without explicit login steps in `cart.spec.ts`.

## Additional Resources
-   **Playwright Documentation - Authentication**: [https://playwright.dev/docs/auth](https://playwright.dev/docs/auth)
-   **Blog Post on Playwright Authentication**: [https://playwright.dev/docs/auth#reuse-authentication-state-between-tests](https://playwright.dev/docs/auth#reuse-authentication-state-between-tests)
-   **Sauce Demo Application (for practice)**: [https://www.saucedemo.com/](https://www.saucedemo.com/)
