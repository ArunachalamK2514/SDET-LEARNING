# Authentication & Network Interception: Implement UI Login and Save Authentication State

## Overview
Automated testing often requires interaction with authenticated parts of an application. Manually logging in at the start of every test run is inefficient and can significantly increase test execution time. Playwright provides robust mechanisms to handle authentication by performing a UI login once and then saving the authentication state. This saved state can then be reused across multiple test files or even different test runs, drastically speeding up test execution and making tests more reliable. This feature covers performing a UI login and saving the authentication context, which includes cookies, local storage, and session storage.

## Detailed Explanation

Playwright's `browserContext.storageState()` method is central to managing authentication. This method allows you to serialize the current browser context's session state (including cookies, local storage, and session storage) into a JSON file. Subsequently, you can deserialize this state to initialize new browser contexts, effectively starting a test with a pre-authenticated session without needing to go through the login flow every time.

The process typically involves:
1.  **Performing a UI Login**: Navigate to the login page, interact with the login form (enter username and password), and submit it. Wait for navigation or a specific element to appear, confirming successful login.
2.  **Saving the Storage State**: After a successful login, use `page.context().storageState({ path: 'auth.json' })` to save the current authentication state to a file (e.g., `auth.json`).
3.  **Reusing the Storage State**: In subsequent tests, create a new `browserContext` using the saved state: `browser.newContext({ storageState: 'auth.json' })`. This new context will already be authenticated.

**What data is captured?**
When you save the storage state, Playwright captures:
*   **Cookies**: HTTP cookies set by the server, essential for maintaining session identity.
*   **Local Storage**: Data stored by web applications in the browser, often used for user preferences or caching application state.
*   **Session Storage**: Similar to local storage but data is cleared when the session ends (i.e., when the browser tab is closed).

This comprehensive capture ensures that the browser context behaves as if a user had just completed a full login flow, covering most common authentication schemes (session-based, token-based stored in local storage, etc.).

## Code Implementation

Here's a complete example demonstrating how to perform a UI login, save the authentication state, and then reuse it in a subsequent test.

**1. `setup/auth.setup.ts` (or `.js`) - Setup script to login and save state**

```typescript
// auth.setup.ts
import { test as setup, expect } from '@playwright/test';

// Define an authentication file path
const AUTH_FILE = 'playwright/.auth/user.json'; // Store auth files in a dedicated directory

setup('authenticate', async ({ page }) => {
  // 1. Navigate to the login page
  await page.goto('https://www.example.com/login'); // Replace with your application's login URL

  // 2. Enter credentials
  await page.fill('input[name="username"]', 'testuser'); // Replace with actual selectors and credentials
  await page.fill('input[name="password"]', 'testpassword'); // NEVER hardcode sensitive info in production
  await page.click('button[type="submit"]');

  // 3. Wait for successful login (e.g., navigate to dashboard or specific element appears)
  await page.waitForURL('https://www.example.com/dashboard'); // Replace with your post-login URL
  await expect(page.locator('.user-profile')).toBeVisible(); // Replace with a selector that confirms login

  // 4. Save the authentication state
  // This saves cookies, local storage, and session storage to a JSON file
  await page.context().storageState({ path: AUTH_FILE });

  console.log(`Authentication state saved to ${AUTH_FILE}`);
});
```

**2. `playwright.config.ts` - Configure Playwright to use the setup file**

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // ... other configurations ...

  // Look for test files in the "tests" directory, relative to this configuration file.
  testDir: './tests',

  // Run your global setup file. This will run once before all tests.
  globalSetup: require.resolve('./setup/auth.setup.ts'), // Path to your authentication setup script

  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        // Use the saved authentication state for this project
        storageState: AUTH_FILE, // Reference the constant defined in the setup script or directly put 'playwright/.auth/user.json'
      },
    },
    // Add other browsers as needed, also using storageState
  ],
});
```
*Note: Make sure `AUTH_FILE` is accessible or use the direct path in `playwright.config.ts` if not using a shared constant.*

**3. `tests/authenticated.spec.ts` - Example test reusing the saved state**

```typescript
// tests/authenticated.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authenticated User Tests', () => {
  test('should display user dashboard', async ({ page }) => {
    await page.goto('https://www.example.com/dashboard'); // Navigating to an authenticated page

    // Expecting an element only visible to authenticated users
    await expect(page.locator('.welcome-message')).toHaveText(/Welcome, testuser/);
    await expect(page.locator('.logout-button')).toBeVisible();
    console.log('User dashboard displayed successfully with saved authentication state.');
  });

  test('should be able to access profile page', async ({ page }) => {
    await page.goto('https://www.example.com/profile');

    await expect(page.locator('.profile-header')).toHaveText('User Profile');
    await expect(page.locator('input[name="email"]')).toHaveValue('testuser@example.com');
    console.log('User profile page accessed successfully.');
  });
});
```

To run these tests:
1.  Make sure you have Playwright installed: `npm init playwright@latest`
2.  Place the `auth.setup.ts` in a `setup` directory, `playwright.config.ts` in the root, and `authenticated.spec.ts` in a `tests` directory.
3.  Run `npx playwright test`. The `authenticate` setup will run once, save the state, and then all tests in `authenticated.spec.ts` will run using that pre-authenticated state.

## Best Practices
-   **Isolate Authentication**: Keep your authentication logic in a separate setup file (`globalSetup`) to ensure it runs only once per test run, not before every test file.
-   **Version Control Ignorance**: Add your `auth.json` file (or the directory containing it, e.g., `playwright/.auth/`) to `.gitignore` to prevent committing sensitive authentication data.
-   **Environment Variables**: Use environment variables for sensitive data like usernames and passwords instead of hardcoding them in your `auth.setup.ts`. For example: `process.env.TEST_USERNAME`, `process.env.TEST_PASSWORD`.
-   **Robust Login Flow**: Ensure your login script is resilient. Use `await page.waitForURL()` or `await expect(...).toBeVisible()` to confirm successful login before saving the state.
-   **Clear State for CI/CD**: In CI/CD environments, ensure that the `auth.json` file is generated fresh for each run to avoid stale states or security issues.
-   **Conditional Authentication**: For tests that specifically need to test the login process itself, you can create a new context *without* `storageState` to ensure a clean slate.

## Common Pitfalls
-   **Forgetting `globalSetup`**: Not configuring `globalSetup` in `playwright.config.ts` will lead to the authentication script not running, and subsequent tests will fail due to lack of authentication.
-   **Incorrect `storageState` Path**: Providing an incorrect path to `storageState` in `playwright.config.ts` will cause Playwright to fail to load the authentication, resulting in unauthenticated tests.
-   **Stale Authentication**: If the application's authentication tokens or sessions expire quickly, the saved `auth.json` might become invalid. This requires re-running the setup script more frequently or configuring shorter test runs.
-   **Over-reliance on `storageState`**: While efficient, remember that `storageState` skips the actual UI login. If you need to test the login UI itself (e.g., error messages for bad credentials), you'll need separate tests that perform a full UI login without reusing `storageState`.
-   **Security Concerns**: Committing `auth.json` to version control can be a security risk as it might contain valid session tokens. Always `.gitignore` it.

## Interview Questions & Answers

1.  **Q: Why is saving authentication state important in Playwright testing?**
    **A:** Saving authentication state significantly improves test efficiency by avoiding repeated UI login steps for every test or test suite. It reduces execution time, makes tests less flaky by removing repetitive UI interactions, and allows tests to focus directly on the features under test within an authenticated context. This is crucial for large test suites in CI/CD pipelines.

2.  **Q: What exactly does `page.context().storageState({ path: 'auth.json' })` capture, and why is each component important?**
    **A:** It captures:
    *   **Cookies**: These are critical for session management, allowing the server to identify the authenticated user across different requests.
    *   **Local Storage**: Web applications use local storage for persistent client-side data, which can include authentication tokens (like JWTs), user preferences, or cached application state.
    *   **Session Storage**: Similar to local storage but ephemeral, it's used for data relevant only to the current browsing session. While less common for long-lived authentication, it can be part of certain authentication flows.
    These components together ensure a complete restoration of the authenticated browser state.

3.  **Q: How do you handle cases where the authentication state might expire during a long test run?**
    **A:** This can be managed by:
    *   **Shorter Test Shards**: Breaking down long test runs into shorter, more focused chunks that are less likely to exceed session expiry.
    *   **Re-authentication Strategy**: Implementing logic in the `globalSetup` to detect expired states (e.g., by checking for a specific element on a "logged in" page, and if not present, re-logging in).
    *   **Token Refresh Mechanisms**: If the application uses refresh tokens, the setup script could simulate a token refresh to extend the session.
    *   **Test Environment Configuration**: Adjusting the session timeout in the test environment to be longer than the expected test run duration.

## Hands-on Exercise

**Scenario:** You are testing an e-commerce website. The website has a login page and a dashboard where authenticated users can view their order history.

**Task:**
1.  **Create a `globalSetup` script** (`setup/ecommerce.setup.ts`) that navigates to a mock login page (you can use `https://www.saucedemo.com/`), logs in with valid credentials (`standard_user`, `secret_sauce`), and saves the authentication state to `playwright/.auth/ecommerce-user.json`.
2.  **Configure `playwright.config.ts`** to use this setup script and load the saved `storageState` for the `chromium` project.
3.  **Write a test file** (`tests/ecommerce.spec.ts`) that:
    *   Navigates directly to the inventory page (`https://www.saucedemo.com/inventory.html`) after the setup.
    *   Asserts that the "Products" title is visible, confirming the user is logged in.
    *   (Bonus) Adds an item to the cart and asserts the cart icon updates.

**Expected Outcome:** Your tests should run without explicitly performing a login in `ecommerce.spec.ts`, leveraging the pre-authenticated state from `ecommerce.setup.ts`.

## Additional Resources
-   **Playwright Authentication Documentation**: [https://playwright.dev/docs/auth](https://playwright.dev/docs/auth)
-   **Playwright `storageState` API**: [https://playwright.dev/docs/api/class-browsercontext#browser-context-storage-state](https://playwright.dev/docs/api/class-browsercontext#browser-context-storage-state)
-   **Playwright `globalSetup`**: [https://playwright.dev/docs/test-configuration#global-setup-and-teardown](https://playwright.dev/docs/test-configuration#global-setup-and-teardown)
