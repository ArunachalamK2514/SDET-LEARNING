# Playwright: Reusing Authentication State Across Tests

## Overview
In end-to-end test automation, repeatedly logging into an application for every test scenario can be a significant bottleneck, leading to slower test execution times and increased test flakiness. Playwright provides a robust mechanism to capture and reuse authentication states, allowing tests to start directly from a logged-in state. This dramatically improves test efficiency and focuses tests on the specific feature under validation rather than the login process itself. This feature is crucial for SDETs working on complex applications with authentication-gated features.

## Detailed Explanation
Playwright's `storageState` option is the core of reusing authentication. When a browser context is created, you can specify a file path for `storageState`. Playwright will then either load the authentication state from this file (if it exists) or save the current authentication state to it (if a state is successfully established during a test run).

The authentication state typically includes cookies, local storage, and session storage. By capturing this state after a successful login and reusing it, subsequent test runs can bypass the login flow.

There are two primary ways to manage `storageState`:

1.  **Via `browserContext.storageState()` and `browser.newContext()`**: You can explicitly capture the state after a login and save it to a JSON file. Then, for subsequent tests, you can load this JSON file when creating a new browser context. This approach offers fine-grained control and is often used for global setup.
2.  **Via `playwright.config.ts`**: For a more integrated approach, Playwright allows configuring `storageState` directly in `playwright.config.ts` within the `use` option of your project. You can define a global setup file that performs the login and saves the state, and then all tests in that project will automatically use this state.

### How it works (Conceptual Flow):
1.  **Login Test (Global Setup)**: A dedicated test or setup script navigates to the login page, enters credentials, and successfully logs in.
2.  **Capture State**: After successful login, `browserContext.storageState({ path: 'auth.json' })` is called to save the current authentication state to `auth.json`.
3.  **Reuse State**: For all subsequent tests, a new `browserContext` is launched with `storageState: 'auth.json'`. This context will automatically have the cookies, local storage, and session storage from the `auth.json` file, effectively starting the tests in a logged-in state.

## Code Implementation

First, let's create a global setup file (`global-setup.ts`) to perform the login and save the authentication state.

```typescript
// global-setup.ts
import { chromium, FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  const { baseURL, storageState } = config.projects[0].use; // Assuming baseURL and storageState are defined in playwright.config.ts
  if (!baseURL) {
    throw new Error('baseURL is not defined in playwright.config.ts');
  }
  if (!storageState) {
    throw new Error('storageState path is not defined in playwright.config.ts');
  }

  const browser = await chromium.launch();
  const page = await browser.newPage();

  console.log(`Navigating to login page: ${baseURL}/login`);
  await page.goto(`${baseURL}/login`); // Replace with your actual login URL

  // Perform login
  console.log('Performing login...');
  await page.fill('input#username', 'your_username'); // Replace with your username input selector
  await page.fill('input#password', 'your_password'); // Replace with your password input selector
  await page.click('button#login-button'); // Replace with your login button selector

  // Wait for successful login (e.g., redirect to dashboard or an element appears)
  await page.waitForURL(`${baseURL}/dashboard`); // Replace with your dashboard URL or a better indicator
  console.log('Login successful. Saving storage state...');

  // Save authentication state
  await page.context().storageState({ path: storageState as string });
  console.log(`Authentication state saved to: ${storageState}`);

  await browser.close();
}

export default globalSetup;
```

Next, configure `playwright.config.ts` to use this global setup and reuse the `storageState`.

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',

  // Define baseURL and storageState path
  use: {
    baseURL: 'http://localhost:3000', // Replace with your application's base URL
    trace: 'on-first-retry',
    storageState: 'playwright-auth-state.json', // Path to save/load auth state
  },

  // Configure global setup
  globalSetup: require.resolve('./global-setup'),

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    // Add other projects for different browsers if needed
  ],
});
```

Finally, a test file that leverages the saved authentication state.

```typescript
// tests/dashboard.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Dashboard access', () => {
  test('should display user dashboard after login without explicit login steps', async ({ page, baseURL }) => {
    // Because storageState is configured, this page context starts already logged in.
    await page.goto(`${baseURL}/dashboard`); // Navigate to a protected route

    // Verify a logged-in element (e.g., user profile name, logout button)
    await expect(page.locator('h1#dashboard-title')).toHaveText('Welcome to your Dashboard');
    await expect(page.locator('button#logout-button')).toBeVisible();

    console.log('Dashboard test passed, user was automatically logged in.');
  });

  test('should display user profile without re-logging in', async ({ page, baseURL }) => {
    await page.goto(`${baseURL}/profile`); // Navigate to another protected route

    await expect(page.locator('h2#profile-header')).toHaveText('User Profile');
    await expect(page.locator('span#username-display')).toHaveText('your_username'); // Verify username display
  });
});
```

To run these tests:
1.  Ensure you have an application running at `http://localhost:3000` (or your configured `baseURL`) with a login page and protected routes.
2.  Install Playwright: `npm init playwright@latest`
3.  Place `global-setup.ts`, `playwright.config.ts`, and `tests/dashboard.spec.ts` in your project.
4.  Run `npx playwright test`.

The `global-setup.ts` will run once before all tests, create `playwright-auth-state.json`, and then subsequent tests will use this file.

## Best Practices
-   **Isolate Login Logic**: Keep the login flow in a dedicated setup file (e.g., `global-setup.ts`) or a fixture.
-   **Parameterize Credentials**: Avoid hardcoding credentials. Use environment variables or a secure configuration management system.
-   **Invalidate State on Change**: If your application's authentication mechanism changes (e.g., token refresh logic), you might need to manually delete the `storageState` file to force a fresh login during the next test run.
-   **Consider Different Roles**: For testing different user roles, create separate `storageState` files for each role (e.g., `admin-auth.json`, `user-auth.json`) and configure projects to use them.
-   **Use `test.use()` for granular control**: For specific test files or blocks that need a different `storageState`, you can override it using `test.use({ storageState: 'path/to/another-auth.json' })`.
-   **Error Handling**: Ensure robust error handling in your `global-setup.ts` to catch failed logins or unexpected UI changes.

## Common Pitfalls
-   **Stale Authentication State**: If the `auth.json` file becomes outdated (e.g., password change, session expiry), tests will fail unexpectedly. The `global-setup` should ideally re-run and refresh the state if needed, or you might need a mechanism to periodically clear the state file.
-   **Incorrect Selectors**: Changes to the login page's HTML structure can break the `global-setup.ts` script, leading to failed logins and subsequently failing tests.
-   **Environment Differences**: Authentication flows might differ between local, staging, and production environments. Ensure your `baseURL` and login selectors are adaptable.
-   **Security Concerns**: Storing authentication states (especially with sensitive data like tokens) directly in your repository (if not ignored) can be a security risk. Ensure `storageState` files are properly handled and ideally not committed to version control. They are usually generated during CI runs or locally.
-   **No Wait After Login**: Forgetting to add appropriate `await page.waitForURL()` or `await page.waitForSelector()` after login can cause tests to proceed before the authentication state is fully established.

## Interview Questions & Answers
1.  **Q: Why is reusing authentication state important in Playwright tests?**
    **A**: Reusing authentication state significantly speeds up test execution by avoiding repetitive login flows for every test case. It also makes tests more focused, as they only test the specific feature under validation, not the login process, reducing flakiness associated with login UI interactions.

2.  **Q: How do you implement authentication reuse in Playwright?**
    **A**: The primary method involves using Playwright's `storageState` option. A `global-setup.ts` script is typically used to perform a login once, capture the `browserContext.storageState()` into a JSON file (e.g., `playwright-auth-state.json`), and then `playwright.config.ts` is configured to use this `storageState` file for all tests within a project.

3.  **Q: What exactly does Playwright's `storageState` capture?**
    **A**: `storageState` captures the current browser context's state, which includes cookies, local storage, and session storage. These are the primary mechanisms web applications use to maintain a user's logged-in session.

4.  **Q: What are the security implications of `storageState`?**
    **A**: The `storageState` file contains sensitive information (like session tokens or cookies). It should never be committed to version control (add it to `.gitignore`). In CI/CD pipelines, ensure the state file is generated securely and not exposed. For local development, it should be treated with care, similar to other sensitive configuration files.

5.  **Q: How would you handle testing with multiple user roles (e.g., admin, regular user) using `storageState`?**
    **A**: You would create separate `storageState` files for each role (e.g., `admin-auth.json`, `user-auth.json`). In `playwright.config.ts`, you can define multiple projects, each configured to use a specific `storageState` file, or create separate global setup files that generate these role-specific states. Alternatively, you can use `test.use()` within specific test files to switch the `storageState` for a particular set of tests.

## Hands-on Exercise
1.  **Setup a basic web application with a login page**: If you don't have one, you can use a simple Node.js/Express app or even a static HTML page with client-side login simulation. Ensure it sets some cookies or local storage items upon successful login.
2.  **Implement `global-setup.ts`**: Write the script to navigate to your login page, fill in credentials, and save the `storageState` to `auth.json`.
3.  **Configure `playwright.config.ts`**: Update your Playwright configuration to use the `global-setup.ts` and set the `storageState` path.
4.  **Create a protected test**: Write a test that attempts to access a page that requires authentication without performing explicit login steps. Assert that the page loads correctly and displays elements indicative of a logged-in user.
5.  **Verify**: Run your tests. Observe that the login flow is only executed once (by `global-setup.ts`) and all subsequent tests start already authenticated.
6.  **Experiment**: Try invalidating the `auth.json` file (e.g., by changing credentials in the setup or manually deleting the file) and observe the test failures.

## Additional Resources
-   **Playwright Documentation on Authentication**: [https://playwright.dev/docs/auth](https://playwright.dev/docs/auth)
-   **Playwright Global Setup/Teardown**: [https://playwright.dev/docs/test-global-setup-teardown](https://playwright.dev/docs/test-global-setup-teardown)
-   **Testing with different user roles**: [https://playwright.dev/docs/test-auth#reuse-authentication-in-tests-with-different-users](https://playwright.dev/docs/test-auth#reuse-authentication-in-tests-with-different-users)