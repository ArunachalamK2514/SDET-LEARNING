# playwright-5.5-ac1.md

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
---
# playwright-5.5-ac2.md

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
---
# playwright-5.5-ac3.md

# API-based Authentication in Playwright using Request Context

## Overview
Automated end-to-end (E2E) tests often require logging into an application before interacting with its features. While logging in through the UI is the most realistic approach, it can significantly slow down test execution, especially when many tests depend on a logged-in state. API-based authentication in Playwright offers a powerful alternative by allowing tests to bypass the UI login flow. This involves directly interacting with the application's authentication API to obtain necessary credentials (like auth tokens or session cookies) and injecting them into the browser context. This approach drastically speeds up test execution, making your CI/CD pipeline more efficient without sacrificing the integrity of your functional tests.

## Detailed Explanation

Bypassing UI login for tests is a strategic optimization. Instead of navigating to a login page, entering credentials, and clicking a button for every test scenario, we can simulate the successful login process at a lower level. Playwright's `request` context, accessible via `playwright.request`, is ideal for this. It allows you to make HTTP requests programmatically, outside the browser context, mimicking how a client-side application or a backend service would interact with an API.

The general steps for API-based authentication are:

1.  **Hit the Login API Directly**: Use `playwright.request.post()` or `playwright.request.fetch()` to send a POST request to your application's login endpoint. This request typically includes user credentials (username, password) in the request body.
2.  **Extract Authentication Data**: The response from a successful login API call will usually contain authentication artifacts. This could be:
    *   **Auth Tokens**: JWT (JSON Web Tokens) often returned in the response body.
    *   **Session Cookies**: Set in the `Set-Cookie` header of the response.
    *   **API Keys**: Sometimes returned directly, or associated with the user for subsequent requests.
3.  **Inject Auth Data into Browser Context**: Once you have the authentication data, you need to provide it to Playwright's browser context so that subsequent browser actions (like `page.goto()`) recognize the user as authenticated. This can be done in several ways:
    *   **Cookies**: Use `context.addCookies()` to set session cookies.
    *   **Local Storage/Session Storage**: Use `context.addInitScript()` to run JavaScript code that populates `localStorage` or `sessionStorage` with tokens or other data before the page loads.
    *   **Request Headers**: For some applications, you might need to modify default request headers in the browser context (less common for full browser auth, more for API tests).
4.  **Verify Bypassing UI Login is Faster**: After setting the authentication state, navigate directly to an authenticated page. The application should treat the session as logged in without requiring a UI login, confirming the efficiency gain.

## Code Implementation

Let's assume we have a simple web application with a login API endpoint `/api/login` that returns a JWT token upon successful authentication.

```typescript
// playwright.config.ts (Example for setting up global setup)
import { defineConfig, devices } from '@playwright/test';
import * as path from 'path';

export const STORAGE_STATE_PATH = path.join(__dirname, 'playwright-auth-state.json');

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000', // Your application's base URL
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'setup',
      testMatch: /global\.setup\.ts/, // This project will run first to set up auth
    },
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'], storageState: STORAGE_STATE_PATH },
      dependencies: ['setup'], // Depends on the 'setup' project
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'], storageState: STORAGE_STATE_PATH },
      dependencies: ['setup'],
    },
    // Add other browsers as needed
  ],
});
```

```typescript
// global.setup.ts
import { test as setup, expect } from '@playwright/test';
import { STORAGE_STATE_PATH } from './playwright.config';
import * as fs from 'fs';

setup('authenticate user', async ({ request }) => {
  // 1. Use request.post() to hit login API directly
  const response = await request.post('/api/login', {
    data: {
      username: 'testuser',
      password: 'password123',
    },
  });

  expect(response.ok()).toBeTruthy();
  const { token, user } = await response.json(); // Assuming API returns { token: '...', user: { ... } }

  // 2. Extract token from response and inject auth data into browser context
  // Here, we'll store the token in localStorage and also save cookies if any
  const storageState = await request.context().storageState();
  
  // You might also need to add specific cookies if the API sets them.
  // Playwright's request context automatically handles cookies from the response for its own requests,
  // but if you need to pass them to the browser context, you'd extract them from response headers.
  // For simplicity, we assume a JWT token stored in localStorage is sufficient.

  // Let's create a dummy page to set localStorage for the token, then save its storageState
  const browser = await setup.browser.launch();
  const page = await browser.newPage();
  await page.goto('http://localhost:3000'); // Go to your app's origin
  await page.evaluate(
    ([authToken, userObj]) => {
      localStorage.setItem('authToken', authToken);
      localStorage.setItem('currentUser', JSON.stringify(userObj));
    },
    [token, user]
  );
  await page.context().storageState({ path: STORAGE_STATE_PATH });
  await browser.close();

  console.log('Authentication state saved successfully.');
});
```

```typescript
// tests/authenticated-feature.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authenticated Feature Tests', () => {
  test('should access authenticated dashboard', async ({ page }) => {
    // Because of global setup, 'page' should already be authenticated
    await page.goto('/dashboard'); 
    
    // 3. Verify bypassing UI login is faster
    // We expect not to see the login form
    const loginForm = page.locator('form[name="login"]');
    await expect(loginForm).not.toBeVisible({ timeout: 5000 }); // Short timeout as it should be fast
    
    // Verify a user-specific element
    await expect(page.locator('h1')).toHaveText('Welcome, testuser!'); 
    
    console.log('Successfully accessed authenticated dashboard without UI login.');
  });

  test('should perform an action as authenticated user', async ({ page }) => {
    await page.goto('/profile');
    await expect(page.locator('#user-email')).toHaveText('testuser@example.com');
  });
});
```

**Note**: For `global.setup.ts` to capture `localStorage`, you need to navigate to the application's domain within the setup to ensure `localStorage` is set for the correct origin. The `browser.newPage()` followed by `page.goto()` and `page.evaluate()` achieves this. The `storageState` then captures the cookies and local storage.

## Best Practices
- **Isolate Authentication Logic**: Keep your authentication setup in a dedicated global setup file (e.g., `global.setup.ts`) to ensure it runs once before all tests.
- **Handle Different Auth Types**: Adapt the extraction and injection logic based on your application's authentication mechanism (e.g., parsing cookies, JWT from response body, or API keys).
- **Security**: Never hardcode sensitive credentials directly in your tests. Use environment variables (e.g., `process.env.TEST_USERNAME`) or a secure configuration management system.
- **`storageState` for Reusability**: Leverage Playwright's `storageState` feature. By saving the authentication state to a file (`playwright-auth-state.json`) and configuring your projects to use it, you can reuse the authenticated session across multiple test files and browsers.
- **Error Handling**: Include robust error handling for API calls (e.g., checking `response.ok()`, handling non-200 status codes) to make your setup resilient.
- **Clean Up**: If your authentication process creates user accounts or modifies data, ensure you have a cleanup strategy (e.g., using a global teardown or individual test teardowns).

## Common Pitfalls
-   **Incorrectly Parsing Authentication Response**: The structure of your login API's response matters. Ensure you correctly parse the JSON body or extract headers to get the token or cookies. A common mistake is assuming a `token` field when it might be nested or named differently.
-   **Scope of Authentication**:
    *   **Browser Context vs. Page**: `context.addCookies()` and `context.addInitScript()` apply to all pages within that browser context. If you need different authentication states for different tests, consider creating separate browser contexts or using `test.use({ storageState: 'path/to/another/state.json' })`.
    *   **Origin Mismatch**: If you set cookies or local storage for `example.com` but your tests navigate to `sub.example.com`, the authentication data might not be accessible due to same-origin policy. Ensure your authentication setup operates on the correct origin.
-   **Token/Cookie Expiry**: Authentication tokens or session cookies can expire. For long test suites, you might need a mechanism to refresh them or re-authenticate if tests start failing due to expired credentials. Playwright's `global.setup` runs once, so if your tests run for a very long time, this might become an issue.
-   **CORS Issues**: If your login API is on a different domain than your web application, ensure CORS (Cross-Origin Resource Sharing) headers are correctly configured, especially if you're trying to inject cookies or other credentials from the API response directly into the browser context.

## Interview Questions & Answers

1.  **Q**: Why would you choose API-based authentication over UI-based login for your Playwright E2E tests? What are the trade-offs?
    **A**: API-based authentication significantly improves test execution speed by bypassing the time-consuming UI login flow. This is crucial for large test suites and fast CI/CD feedback. The trade-offs include:
    *   **Pros**: Faster execution, less flaky (no UI elements to interact with), better isolation for functional tests (login isn't part of the feature under test).
    *   **Cons**: Does not test the actual UI login flow itself (requires a separate, minimal test for UI login), might be more complex to set up initially, relies on the stability of the authentication API.

2.  **Q**: How do you handle different user roles (e.g., admin, regular user) when using API-based authentication in Playwright tests?
    **A**: You would typically create separate authentication states for each user role. This involves:
    *   Creating multiple `global.setup.ts` files or a single setup file that generates multiple `storageState` files (e.g., `admin-auth-state.json`, `user-auth-state.json`).
    *   Calling the login API with credentials for each specific role.
    *   Saving the resulting `storageState` for each role.
    *   In `playwright.config.ts`, define different projects or use test hooks to select the appropriate `storageState` file based on the test's requirements (e.g., `test.use({ storageState: 'admin-auth-state.json' })`).

3.  **Q**: Your API-based authenticated tests are occasionally failing, and you suspect it's related to the authentication state. What steps would you take to debug this issue?
    **A**:
    *   **Verify API Response**: First, directly test the login API endpoint (e.g., using Postman, curl, or a simple Node.js script) to ensure it's returning the expected authentication data (token, cookies).
    *   **Inspect `storageState`**: After running the global setup, inspect the generated `playwright-auth-state.json` file. Check if the cookies and `localStorage` entries contain the expected authentication information (e.g., the JWT token).
    *   **Check Browser Context**: During a failing test, add `await page.pause()` and open DevTools to inspect `document.cookie` and `localStorage` in the browser console. Confirm that the injected authentication data is present and correctly formatted.
    *   **Network Tab**: Use Playwright's trace viewer or the browser's network tab (via `page.pause()`) to check the network requests. Look for authentication headers (e.g., `Authorization: Bearer <token>`) or cookies being sent with requests to your application's protected endpoints.
    *   **Application Logs**: Check your application's backend logs to see if it's receiving the authentication credentials and why it might be rejecting them.

## Hands-on Exercise

**Scenario**: You have an application with a protected `/settings` page that only authenticated users can access. The login API is `POST /api/authenticate` and it returns an object `{ sessionId: 'abc123def456' }`. This `sessionId` needs to be stored in `sessionStorage` as `appSessionId` for the application to recognize the user.

**Task**:
1.  Create a `global.setup.ts` file that uses `request.post()` to call `/api/authenticate` with a username and password.
2.  Extract the `sessionId` from the response.
3.  Inject this `sessionId` into the browser's `sessionStorage` as `appSessionId`.
4.  Save the `storageState` to a file.
5.  Create a test (`tests/settings.spec.ts`) that directly navigates to `/settings` and asserts that a specific element only visible to authenticated users is present, without performing a UI login.

## Additional Resources
-   **Playwright Authentication Documentation**: [https://playwright.dev/docs/auth](https://playwright.dev/docs/auth)
-   **Playwright `request` context**: [https://playwright.dev/docs/api/class-apiRequestContext](https://playwright.dev/docs/api/class-apiRequestContext)
-   **Blog Post: Speed up Playwright tests with authentication via API**: (Search for recent articles, e.g., on official Playwright blog or community blogs)
---
# playwright-5.5-ac4.md

# Playwright: UI Login vs. Token-based Authentication Strategies

## Overview
In end-to-end (E2E) test automation, efficiently handling user authentication is crucial. This document explores two primary strategies for authenticating users in Playwright tests: direct UI login and token-based authentication. We will compare their trade-offs, discuss appropriate use cases, and provide code examples to illustrate their implementation. Understanding when to use each method can significantly impact test speed, reliability, and maintainability.

## Detailed Explanation

### 1. UI Login (Traditional Approach)
UI login involves automating the process of a user typing credentials into a login form and submitting it, just as a real user would.

**Process:**
1.  Navigate to the login page.
2.  Locate username and password input fields.
3.  Type credentials into the fields.
4.  Click the login button.
5.  Verify successful login (e.g., by checking for a dashboard element or absence of login form).

**When to Use:**
*   **Smoke Tests & Critical User Journeys:** Essential for verifying the core login functionality itself, including form validation, UI elements, and backend authentication flow.
*   **E2E Tests for Authentication Features:** When testing features directly related to user authentication, such as password reset, multi-factor authentication (MFA) flows, or "remember me" functionality.
*   **Realism over Speed:** Prioritize testing the exact user experience, even if it adds a few extra seconds to test execution.

### 2. Token-based Authentication (API/Bypass Approach)
Token-based authentication involves directly injecting authentication tokens (e.g., JWTs, session cookies) into the browser's context or local storage, bypassing the UI login process. This requires prior knowledge of how the application handles authentication tokens.

**Process:**
1.  Make an API call (e.g., using `request` context or a dedicated HTTP client) to the application's login endpoint with credentials to obtain authentication tokens (cookies, local storage items, bearer tokens).
2.  Inject these tokens into the Playwright `BrowserContext` or `page` before navigating to the application under test.
3.  Navigate to the desired page, which should now recognize the user as authenticated.

**When to Use:**
*   **Most E2E Feature Tests:** For the vast majority of tests where the goal is to test a feature *after* login, and the login process itself isn't the primary focus.
*   **Performance Optimization:** Significantly speeds up test execution by skipping repetitive UI interactions for login.
*   **Stable Authentication:** When the login flow is stable and thoroughly covered by separate UI login tests.
*   **CI/CD Environments:** Ideal for fast feedback cycles in continuous integration pipelines.

### Comparison Table: UI Login vs. Token-based Authentication

| Feature          | UI Login                                    | Token-based Authentication                  |
| :--------------- | :------------------------------------------ | :------------------------------------------ |
| **Speed**        | Slower (full UI interaction)                | Faster (bypasses UI login)                  |
| **Realism**      | High (mimics user experience)               | Lower (bypasses user experience)            |
| **Setup Cost**   | Low (standard Playwright commands)          | Moderate (API calls, token handling)        |
| **Maintenance**  | Higher (fragile to UI changes)              | Lower (more stable, less UI dependent)      |
| **Use Cases**    | Smoke, critical auth flows, E2E auth features | Most E2E feature tests, performance-critical |
| **Test Focus**   | Login flow, UI elements                     | Features post-login                         |
| **Dependencies** | Web UI                                      | Web UI, API endpoints, token structure      |

## Code Implementation

### Example 1: UI Login

```typescript
// playwright.config.ts or a separate setup file
import { test as setup, expect } from '@playwright/test';

const authFile = 'playwright/.auth/user.json'; // Path to store authentication state

setup('authenticate via UI login', async ({ page }) => {
  await page.goto('https://your-app.com/login');
  await page.fill('input[name="username"]', 'testuser');
  await page.fill('input[name="password"]', 'password123');
  await page.click('button[type="submit"]');

  // Wait for the navigation to complete and a specific element to appear post-login
  await page.waitForURL('https://your-app.com/dashboard');
  await expect(page.locator('.user-profile')).toBeVisible();

  // Save the authentication state
  await page.context().storageState({ path: authFile });
});

// In your actual test file (e.g., example.spec.ts)
import { test, expect } from '@playwright/test';

// Use the authenticated state by referring to the setup test
test.use({ storageState: 'playwright/.auth/user.json' });

test('should display user dashboard after UI login', async ({ page }) => {
  await page.goto('https://your-app.com/dashboard');
  // Since we used storageState, the page should already be authenticated
  await expect(page.locator('.welcome-message')).toHaveText('Welcome, testuser!');
  // Continue testing features post-login
});
```

### Example 2: Token-based Authentication (API Login)

```typescript
// playwright.config.ts or a separate setup file
import { test as setup, expect } from '@playwright/test';

const authFile = 'playwright/.auth/api-user.json'; // Path to store authentication state

setup('authenticate via API token', async ({ request }) => {
  // 1. Make an API call to get authentication tokens (e.g., JWT)
  const response = await request.post('https://your-api.com/auth/login', {
    data: {
      username: 'apiuser',
      password: 'apipassword123',
    },
  });
  expect(response.ok()).toBeTruthy();
  const { accessToken, refreshToken, userId } = await response.json();

  // 2. Prepare storage state for Playwright
  // This structure might vary based on how your app uses tokens (cookies, local storage, session storage)
  const storageState = {
    cookies: [], // If your app uses cookies, extract them from response.headers() or Set-Cookie header
    origins: [
      {
        origin: 'https://your-app.com', // Replace with your app's origin
        localStorage: [
          { name: 'accessToken', value: accessToken },
          { name: 'refreshToken', value: refreshToken },
          { name: 'userId', value: userId.toString() },
        ],
        // You can also add sessionStorage entries here if needed
        sessionStorage: [],
      },
    ],
  };

  // 3. Save the authentication state
  // Playwright will load these into the browser context for subsequent tests
  await setup.step('Save storage state', async () => {
    await request.context().storageState({ path: authFile });
  });

  // Optional: Verify authentication by hitting a protected endpoint
  const protectedResponse = await request.get('https://your-api.com/user/profile', {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  expect(protectedResponse.ok()).toBeTruthy();
  const profile = await protectedResponse.json();
  expect(profile.username).toBe('apiuser');
});

// In your actual test file (e.g., feature.spec.ts)
import { test, expect } from '@playwright/test';

// Use the authenticated state from the API setup
test.use({ storageState: 'playwright/.auth/api-user.json' });

test('should access protected feature after API login', async ({ page }) => {
  await page.goto('https://your-app.com/protected-feature');
  // The page should be authenticated due to the injected tokens
  await expect(page.locator('.feature-content')).toBeVisible();
  await expect(page.locator('.current-user-info')).toHaveText('Logged in as apiuser');
});
```

## Best Practices
-   **Separate Authentication Setup:** Use Playwright's `setup` projects (defined in `playwright.config.ts`) to handle authentication state creation. This ensures authentication runs only once and its state is reused across all tests, significantly reducing test run time.
-   **Clear Naming Conventions:** Name your authentication files (e.g., `user.json`, `api-user.json`) clearly to indicate the type of authentication used.
-   **Environment Variables for Credentials:** Never hardcode sensitive credentials. Use environment variables or a secure configuration management system.
-   **Robust Token Handling:** For token-based approaches, ensure your token acquisition logic is resilient to API changes and correctly handles token expiration and refresh if applicable.
-   **Fallback to UI Login:** Always have at least one or a small suite of UI login tests to ensure the user-facing login flow is functional.
-   **Reusability with `storageState`:** Leverage `page.context().storageState()` and `test.use({ storageState: ... })` to persist and reuse authentication sessions.

## Common Pitfalls
-   **Over-reliance on Token-based Authentication:** If you entirely skip UI login tests, you might miss regressions in the actual login form, validation, or related UI elements.
-   **Fragile Token Injection:** Incorrectly injecting tokens (e.g., wrong local storage key, incorrect cookie domain) can lead to tests failing due to unauthenticated access, even if the token acquisition itself was successful.
-   **Expired Tokens:** If tokens have a short lifespan and are not refreshed, long-running test suites or tests run against older setup states might fail due to expired tokens. Consider refreshing tokens within your setup if needed or making `setup` tests run more frequently for critical paths.
-   **Security Concerns:** Directly handling tokens in test code needs to be done securely. Avoid logging tokens or exposing them in test reports.
-   **Ignoring `storageState` persistence:** Forgetting to save and reuse `storageState` will lead to re-authenticating in every test, negating the performance benefits of a dedicated authentication setup.

## Interview Questions & Answers
1.  **Q:** Explain the difference between UI-based and API-based authentication in Playwright testing and when you would choose one over the other.
    **A:** UI-based authentication involves simulating a user's interaction with a login form. It's realistic but slower and more susceptible to UI changes. I'd use it for smoke tests, critical login flow verification, or specific tests targeting authentication features (e.g., password reset). API-based (token-based) authentication bypasses the UI by programmatically obtaining and injecting authentication tokens into the browser context. It's significantly faster and more stable, ideal for the majority of E2E tests where the focus is on features *after* login, not the login process itself. I'd choose it for performance-critical test suites and general feature validation.

2.  **Q:** How do you handle authentication in Playwright to avoid logging in repeatedly in every test file?
    **A:** Playwright provides a powerful mechanism using `setup` projects and `storageState`. I would create a dedicated setup test (e.g., `auth.setup.ts`) that performs the login (either UI or API-based) and then saves the authenticated browser context's state using `await page.context().storageState({ path: 'playwright/.auth/user.json' });`. Then, in `playwright.config.ts`, I'd configure a `project` for this setup test and have other test projects `depend` on it. Finally, all feature tests can use `test.use({ storageState: 'playwright/.auth/user.json' });` to automatically load this pre-authenticated state, ensuring they start from a logged-in session without repeated UI interactions.

3.  **Q:** What are the potential challenges or pitfalls of using token-based authentication for E2E tests, and how do you mitigate them?
    **A:** Challenges include:
    *   **Fragility to API changes:** If the authentication API or token structure changes, the test setup breaks. Mitigation: Keep the API login setup isolated and well-tested.
    *   **Token expiration:** Short-lived tokens can cause tests to fail. Mitigation: Implement token refresh logic within the setup test or ensure the setup runs frequently enough (e.g., before each test suite) if tokens expire quickly.
    *   **Security risks:** Handling tokens directly requires careful management to avoid exposure. Mitigation: Use environment variables for sensitive data, avoid logging tokens, and ensure CI/CD pipelines handle secrets securely.
    *   **Lack of UI coverage:** Bypassing UI login means the actual login form is not tested. Mitigation: Always complement token-based tests with a dedicated set of UI login tests to cover the critical user journey.

## Hands-on Exercise
**Objective:** Implement and demonstrate both UI and API-based authentication strategies for a hypothetical web application.

1.  **Setup a basic Playwright project:** If you don't have one, initialize it: `npm init playwright@latest`
2.  **Create `auth.setup.ts`:**
    *   Implement a UI login to a placeholder URL (e.g., `https://www.google.com` and pretend to log in, or use a dummy login site like `https://www.saucedemo.com`). Save the `storageState`.
    *   Implement an API login (you might need a mock API or use a public API that returns a simple token upon POST request). Manually construct `storageState` with a mock token in `localStorage`.
3.  **Configure `playwright.config.ts`:**
    *   Define two `projects`: one for UI-authenticated tests (`use: { storageState: 'playwright/.auth/ui-user.json' }`) and one for API-authenticated tests (`use: { storageState: 'playwright/.auth/api-user.json' }`).
    *   Ensure the `setup` tests run before these projects.
4.  **Create test files:**
    *   `ui-auth.spec.ts`: Contains a test that navigates to a protected page and asserts that the user is logged in, using the UI-authenticated `storageState`.
    *   `api-auth.spec.ts`: Contains a test that navigates to a protected page and asserts that the user is logged in, using the API-authenticated `storageState`.
5.  **Run tests and observe:** Compare the execution time and output.

## Additional Resources
-   **Playwright Authentication Documentation:** [https://playwright.dev/docs/auth](https://playwright.dev/docs/auth)
-   **Playwright `setup` and `teardown` projects:** [https://playwright.dev/docs/test-global-setup-teardown](https://playwright.dev/docs/test-global-setup-teardown)
-   **Authentication Best Practices in E2E Testing:** [https://docs.cypress.io/guides/references/best-practices#Authentication](https://docs.cypress.io/guides/references/best-practices#Authentication) (Cypress, but concepts are transferable)
---
# playwright-5.5-ac5.md

# Network Request Interception with Playwright's `page.route()`

## Overview
Network request interception is a powerful feature in Playwright that allows SDETs to control, modify, or block network requests made by the browser. This is invaluable for testing various scenarios, including:
- **Mocking API responses**: Simulating backend behavior without an actual backend.
- **Testing error conditions**: Forcing specific network errors (e.g., 404, 500) to verify application resilience.
- **Blocking unnecessary resources**: Speeding up tests by preventing loading of analytics scripts, images, or other non-essential assets.
- **Inspecting request/response headers and bodies**: Verifying data sent to and received from the server.
- **Testing slow network conditions**: Simulating latency to check loading states and performance.

`page.route()` is the primary Playwright API for achieving this, offering fine-grained control over network traffic.

## Detailed Explanation
Playwright's `page.route(url, handler)` method allows you to intercept network requests that match a specified URL pattern. The `url` argument can be a string, a regular expression, or a function. The `handler` is an asynchronous function that receives a `Route` object, which provides methods to fulfill, abort, or continue the request.

### `route.abort()`
This method stops the request from reaching the server, simulating a network failure. It's often used to block specific resource types (like images, fonts) to improve test performance or to test scenarios where a resource fails to load.

**Example Scenario**: Aborting all PNG image requests.

### `route.continue()`
This method allows the request to continue to its destination. You can optionally modify the request before it continues by providing `headers`, `method`, `postData`, or `url` options. This is useful for inspecting requests and then letting them proceed.

**Example Scenario**: Inspecting request headers and then allowing the request to proceed.

### `route.fulfill()`
This method responds to the request with custom data, effectively mocking the server's response. You can specify `status`, `headers`, `body`, `contentType`, and `path` (to serve a local file).

**Example Scenario**: Mocking an API response to control test data.

### Request Inspection
The `Route` object provides access to the `request` object (`route.request()`), which contains detailed information about the intercepted request, such as URL, method, headers, and post data. This allows for assertions on the request details.

## Code Implementation
Here's a TypeScript example demonstrating various `page.route()` functionalities.

```typescript
import { test, expect, Page } from '@playwright/test';

test.describe('Network Request Interception', () => {

  // Test to abort specific image requests
  test('should abort PNG image requests', async ({ page }) => {
    // Intercept all requests ending with .png and abort them
    await page.route('**/*.png', route => route.abort());

    // Navigate to a page that loads PNG images
    // Replace with a URL that serves PNGs, or create a local test server
    await page.goto('https://www.example.com'); // Example URL, replace with one that serves PNGs if possible

    // You can assert that no PNGs were loaded, e.g., by checking network logs
    // Playwright doesn't directly expose aborted requests in networkFinished events easily.
    // A more direct way is to check the console for broken image icons or specific UI changes.
    // For this example, we'll just verify the page loads without specific PNG issues.
    // In a real test, you might verify the absence of an image element or a broken image icon.
    // For demonstration, let's assume if an image is crucial, its absence would break a visual assertion.
    // We can also check for failed requests in the performance tab, but that's outside Playwright's direct API.

    // Let's use a simpler assertion for demonstration: ensure no image elements are visible if they were supposed to be PNGs.
    // This is a weak assertion, a stronger one would involve actual network monitoring.
    const images = await page.locator('img[src$=".png"]').all();
    for (const img of images) {
        // We expect these images might not load, or their network request was aborted.
        // A robust test would involve checking network logs if exposed easily.
        // For now, we expect the page to still be navigable.
        expect(await page.isVisible('body')).toBe(true);
    }

    // A better approach for verification: monitor requests and check for aborted ones
    const abortedRequests: string[] = [];
    page.on('requestfailed', request => {
      if (request.url().endsWith('.png') && request.failure()?.errorText === 'net::ERR_FAILED') {
        abortedRequests.push(request.url());
      }
    });

    await page.reload(); // Reload to trigger interception with the listener active
    expect(abortedRequests.length).toBeGreaterThanOrEqual(0); // This might be 0 if example.com has no PNGs, but shows how to listen.
    // For a real test, use a page with known PNGs.
  });

  // Test to inspect request headers and continue the request
  test('should inspect request headers for authorization token', async ({ page }) => {
    let interceptedHeaders: Record<string, string> = {};
    const expectedAuthToken = 'Bearer my-secret-auth-token-123';

    // Set a custom header before navigating to simulate a logged-in state or API call
    await page.setExtraHTTPHeaders({
      'Authorization': expectedAuthToken,
      'X-Custom-Header': 'Playwright-Test'
    });

    // Intercept all requests to example.com (or your API endpoint)
    await page.route('https://www.example.com/**', async route => {
      const request = route.request();
      interceptedHeaders = request.headers(); // Get all headers
      await route.continue(); // Allow the request to proceed
    });

    // Navigate to a page or trigger an action that makes a request
    await page.goto('https://www.example.com');

    // Assert that the intercepted headers contain the expected authorization token
    expect(interceptedHeaders['authorization']).toBe(expectedAuthToken);
    expect(interceptedHeaders['x-custom-header']).toBe('Playwright-Test');
  });

  // Test to mock an API response using route.fulfill()
  test('should mock an API response', async ({ page }) => {
    const mockApiResponse = {
      id: 1,
      name: 'Mocked Product',
      price: 99.99,
      currency: 'USD'
    };

    // Intercept a specific API endpoint
    await page.route('**/api/products/1', async route => {
      // Respond with mocked data
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(mockApiResponse),
        headers: {
          'Access-Control-Allow-Origin': '*', // Important for CORS if testing different origins
        }
      });
    });

    // Navigate to a page that makes a request to this API, or directly make the request
    // For demonstration, let's make a fetch request in the browser context
    await page.goto('about:blank'); // Start with a blank page
    const response = await page.evaluate(async () => {
      const res = await fetch('/api/products/1');
      return res.json();
    });

    // Assert that the response matches the mocked data
    expect(response).toEqual(mockApiResponse);
  });
});
```

## Best Practices
- **Be Specific with URLs**: Use precise strings or regular expressions for `page.route()` to avoid unintended interceptions. Overly broad patterns can slow down tests or cause unexpected behavior.
- **Always Handle Routes**: Every `page.route()` handler **must** call `route.continue()`, `route.fulfill()`, or `route.abort()`. Failing to do so will hang the network request and eventually timeout the test.
- **Cleanup Routes**: If a route is only needed for a specific test or section, use `page.unroute()` to remove the handler when it's no longer necessary. This prevents interference with subsequent tests.
- **Organize Mocks**: For complex applications with many API calls, centralize your mock responses in dedicated files or modules to keep tests clean and maintainable.
- **Prioritize Interception Order**: If multiple `page.route()` calls match the same URL, the last registered route takes precedence. Be mindful of the order if you have overlapping patterns.

## Common Pitfalls
- **Forgetting to Call `continue()`/`fulfill()`/`abort()`**: This is the most common mistake, leading to hung requests and test timeouts.
- **Incorrect URL Patterns**: Using patterns that are too broad or too narrow can lead to missed interceptions or unintended ones. Test your patterns carefully.
- **CORS Issues with Mocking**: When using `route.fulfill()` to mock responses from a different origin, you might encounter Cross-Origin Resource Sharing (CORS) errors. Remember to add appropriate CORS headers (e.g., `'Access-Control-Allow-Origin': '*'`) to your mocked response if needed.
- **Asynchronous Nature**: Network interception is asynchronous. Ensure your test logic correctly awaits network events or conditions before making assertions.
- **Interfering with Playwright's Own Requests**: Be careful not to intercept Playwright's internal requests, which could break its functionality. Generally, focus on application-specific URLs.

## Interview Questions & Answers
1.  **Q: What is network request interception in Playwright, and why is it important for SDETs?**
    A: Network request interception is Playwright's capability to monitor, modify, or block HTTP/HTTPS requests made by the browser. It's crucial for SDETs because it allows for:
    *   **Isolation**: Decoupling frontend tests from backend availability by mocking API responses.
    *   **Testing Edge Cases**: Simulating network errors (404, 500, slow connections) to test application resilience.
    *   **Performance Optimization**: Blocking non-essential resources (images, analytics) to speed up tests.
    *   **Data Control**: Providing controlled test data through mocked responses.
    *   **Security Testing**: Inspecting headers and payloads to ensure sensitive data isn't exposed or incorrect data is sent.

2.  **Q: Explain the difference between `route.abort()`, `route.continue()`, and `route.fulfill()` in Playwright.**
    A:
    *   `route.abort()`: Prevents a network request from reaching its destination, simulating a network failure. Useful for blocking resources or testing error states.
    *   `route.continue()`: Allows a network request to proceed to its original destination. It can optionally modify the request (e.g., alter headers, method, postData) before it continues. Useful for inspecting requests or injecting client-side tokens.
    *   `route.fulfill()`: Responds to a network request directly from Playwright, effectively mocking the server's response. You can specify the status code, headers, and body of the response. This is essential for stubbing API calls.

3.  **Q: How would you use `page.route()` to ensure a specific authorization token is sent with all API requests from your application?**
    A: I would use `page.route()` with a broad pattern matching all API endpoints. Inside the handler, I would retrieve the `request` object, inspect its headers for the `Authorization` header. If it's missing or incorrect, I would fail the test or modify the request to include the correct token using `route.continue({ headers: { ...existingHeaders, 'Authorization': 'Bearer <token>' } })`.
    ```typescript
    await page.route('**/api/**', async route => {
      const request = route.request();
      const headers = request.headers();
      expect(headers['authorization']).toBe('Bearer your-expected-token'); // Assert token is present
      await route.continue(); // Let the request proceed
    });
    // Or to enforce/add the token:
    await page.route('**/api/**', async route => {
      const request = route.request();
      const headers = request.headers();
      if (!headers['authorization']) {
          // Add the authorization header if missing
          await route.continue({
              headers: {
                  ...headers,
                  'authorization': 'Bearer your-expected-token'
              }
          });
      } else {
          await route.continue(); // Let requests with existing auth continue
      }
    });
    ```

## Hands-on Exercise
**Scenario**: You are testing an e-commerce website. The product detail page makes an API call to `/api/products/:id` to fetch product information.

**Task**:
1.  Write a Playwright test that navigates to an arbitrary product page (e.g., `https://www.example.com/products/123`).
2.  Use `page.route()` to intercept the `/api/products/123` API call.
3.  Mock the response for this API call to return a custom product with the following details:
    ```json
    {
      "id": 123,
      "name": "Playwright Intercepted Gadget",
      "description": "This product data was entirely mocked by Playwright!",
      "price": 49.99,
      "imageUrl": "https://via.placeholder.com/150"
    }
    ```
4.  After the page loads, assert that the product name, description, and price displayed on the UI match the mocked data.
5.  (Bonus) Add another `page.route()` to block all requests to external analytics scripts (e.g., `**/*google-analytics.com*/**`) and verify they are not loaded.

## Additional Resources
-   **Playwright Network Documentation**: [https://playwright.dev/docs/network](https://playwright.dev/docs/network)
-   **Playwright `page.route()` API Reference**: [https://playwright.dev/docs/api/class-page#page-route](https://playwright.dev/docs/api/class-page#page-route)
-   **Video Tutorial on Network Mocking**: Search YouTube for "Playwright network mocking" or "Playwright intercept network requests" for visual guides.
---
# playwright-5.5-ac6.md

# Mock API Responses for Testing Edge Cases in Playwright

## Overview
Mocking API responses is a crucial technique in test automation, especially when dealing with external services, flaky APIs, or specific edge cases that are hard to reproduce in a live environment. Playwright provides powerful capabilities to intercept network requests and fulfill them with custom data. This allows SDETs to isolate the UI behavior from backend dependencies, ensuring tests are fast, reliable, and deterministic. By controlling the data returned from API calls, we can simulate various scenarios like empty states, error conditions, or specific data configurations without actual backend changes.

## Detailed Explanation
Playwright's `page.route()` method is the cornerstone for network interception. It allows you to listen for specific network requests based on a URL pattern and then decide how to handle them. When a request matches a defined route, you can either continue the request, abort it, or, most powerfully for mocking, fulfill it with your own custom response.

The `route.fulfill()` method is used to provide a custom response. You can specify the `status` code (e.g., 200, 404, 500), `contentType` (e.g., 'application/json'), and the `body` of the response. The `body` can be a string, or you can provide a JSON object which Playwright will automatically serialize to a string and set the `contentType` to `application/json`.

This mechanism enables you to:
1.  **Simulate different data states**: Test how your UI behaves with an empty list, a single item, or a large dataset.
2.  **Isolate frontend from backend**: Run frontend tests even when the backend is still under development or unavailable.
3.  **Test error handling**: Verify that your application correctly displays error messages for various HTTP status codes (e.g., 401 Unauthorized, 404 Not Found, 500 Internal Server Error).
4.  **Control test data**: Ensure consistent test results by providing predictable data, avoiding flakiness due to changing backend data.
5.  **Accelerate test execution**: Mocking often eliminates the need for database setups or complex backend seeding, leading to faster test runs.

## Code Implementation
Here's a comprehensive example demonstrating how to mock API responses for various scenarios using Playwright with TypeScript.

```typescript
import { test, expect } from '@playwright/test';

// Define a base URL for our dummy API
const BASE_API_URL = 'https://api.example.com';

test.describe('API Response Mocking Scenarios', () => {

    test('should display a list of products when API returns data', async ({ page }) => {
        // 1. Intercept the API call for products
        await page.route(`${BASE_API_URL}/products`, async route => {
            const mockProducts = [
                { id: 1, name: 'Laptop', price: 1200 },
                { id: 2, name: 'Mouse', price: 25 }
            ];
            // 2. Fulfill the request with mock JSON data
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify(mockProducts)
            });
        });

        // Navigate to the page that makes this API call
        await page.goto('https://example.com/products'); // Assuming this page fetches products

        // 3. Test UI behavior with the mocked data
        await expect(page.locator('text=Laptop')).toBeVisible();
        await expect(page.locator('text=Mouse')).toBeVisible();
        await expect(page.locator('text=$1200')).toBeVisible();
        await expect(page.locator('text=$25')).toBeVisible();
        console.log('Test Passed: Products displayed correctly with mocked data.');
    });

    test('should display "No Products Found" when API returns an empty array', async ({ page }) => {
        await page.route(`${BASE_API_URL}/products`, async route => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([]) // Empty array
            });
        });

        await page.goto('https://example.com/products');

        await expect(page.locator('text=No Products Found')).toBeVisible();
        await expect(page.locator('text=Laptop')).not.toBeVisible(); // Ensure old data isn't visible
        console.log('Test Passed: "No Products Found" message displayed for empty data.');
    });

    test('should display an error message when API returns a 500 Internal Server Error', async ({ page }) => {
        await page.route(`${BASE_API_URL}/products`, async route => {
            await route.fulfill({
                status: 500,
                contentType: 'application/json',
                body: JSON.stringify({ message: 'Internal Server Error' })
            });
        });

        await page.goto('https://example.com/products');

        await expect(page.locator('text=Failed to load products. Please try again later.')).toBeVisible(); // Assuming UI handles 500 error
        await expect(page.locator('text=Internal Server Error')).not.toBeVisible(); // Raw error message shouldn't be visible to user
        console.log('Test Passed: Error message displayed for 500 status.');
    });

    test('should display a loading spinner while data is being fetched (simulated delay)', async ({ page }) => {
        await page.route(`${BASE_API_URL}/products`, async route => {
            // Simulate a network delay of 2 seconds
            await page.waitForTimeout(2000);
            const mockProducts = [{ id: 1, name: 'Delayed Product', price: 99 }];
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify(mockProducts)
            });
        });

        await page.goto('https://example.com/products');

        // Assuming a loading spinner has a specific data-testid or class
        await expect(page.locator('[data-testid="loading-spinner"]')).toBeVisible();
        await expect(page.locator('text=Delayed Product')).not.toBeVisible(); // Product not visible yet

        // Wait for the mock response to complete and UI to update
        await page.waitForSelector('text=Delayed Product');
        await expect(page.locator('text=Delayed Product')).toBeVisible();
        await expect(page.locator('[data-testid="loading-spinner"]')).not.toBeVisible(); // Spinner should be gone
        console.log('Test Passed: Loading spinner handled correctly with simulated delay.');
    });

    test('should handle multiple API mocks on the same page', async ({ page }) => {
        await page.route(`${BASE_API_URL}/users`, async route => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([{ id: 1, name: 'Alice' }])
            });
        });

        await page.route(`${BASE_API_URL}/posts`, async route => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([{ id: 101, title: 'Playwright Mastery' }])
            });
        });

        await page.goto('https://example.com/dashboard'); // Page making calls to /users and /posts

        await expect(page.locator('text=Alice')).toBeVisible();
        await expect(page.locator('text=Playwright Mastery')).toBeVisible();
        console.log('Test Passed: Multiple API mocks handled on the same page.');
    });
});
```

## Best Practices
-   **Granular Mocking**: Mock only the responses you need to control for a specific test. Allow other requests to go through if they don't impact your test scenario (e.g., analytics calls).
-   **Clear Naming**: Name your mock data and test descriptions clearly to reflect the scenario being tested (e.g., `mockEmptyProducts`, `mockErrorResponse`).
-   **Realism vs. Simplicity**: Strive for mock data that is realistic enough to properly test your UI, but simple enough to be easily understood and maintained. Avoid overly complex mock data unless absolutely necessary.
-   **Isolate Mocks**: Define mocks within the scope of individual tests or test `describe` blocks. This prevents mocks from leaking into other tests and causing unexpected behavior. Use `test.beforeEach` or `test.afterEach` for setup/teardown if mocks are shared within a `describe` block.
-   **Error Handling**: Always consider how your application handles various HTTP status codes and malformed responses. Mock these scenarios to ensure robust error handling.
-   **Assertions**: Assert not just that the mocked data is displayed, but also that UI elements are correctly rendered or hidden based on the mocked response (e.g., loading indicators, empty state messages).

## Common Pitfalls
-   **Over-Mocking**: Mocking too many requests can make tests brittle and hard to maintain. If a request doesn't affect the UI under test, let it go through.
-   **Stale Mocks**: If API contracts change, mocks can become outdated, leading to false positives where tests pass but the application fails with real data. Regularly review and update mocks.
-   **Incorrect URL Matching**: Using overly broad or incorrect URL patterns in `page.route()` can lead to unintended requests being mocked or, conversely, requests not being mocked when they should be. Use specific patterns or regular expressions.
-   **Missing `await route.fulfill()`**: Forgetting to call `route.fulfill()` or `route.continue()` will leave the request pending indefinitely, causing tests to time out.
-   **Ordering of Routes**: If multiple routes match the same URL, the order in which they are defined can matter. Playwright processes routes in the order they are registered.
-   **No Network Activity**: Sometimes a page might not make the expected API call if the UI logic has issues. Use Playwright's tracing or `page.on('request')` to debug if requests are actually being made and intercepted.

## Interview Questions & Answers
1.  **Q: Why is API mocking important in UI test automation?**
    A: API mocking is crucial because it allows us to isolate the frontend from the backend, making UI tests faster, more stable, and deterministic. It enables testing of edge cases (like empty states, error responses, slow network) that are difficult to reliably reproduce with a live backend. This isolation reduces flakiness, accelerates development cycles, and ensures comprehensive test coverage of the UI's reaction to various data scenarios.

2.  **Q: How do you handle different HTTP status codes (e.g., 200, 404, 500) when mocking API responses in Playwright?**
    A: In Playwright, we use `page.route()` to intercept the request and `route.fulfill()` to provide a custom response. To simulate different HTTP status codes, we set the `status` property in `route.fulfill()`. For example, `await route.fulfill({ status: 500, contentType: 'application/json', body: '{"message": "Server Error"}' });` would mock a 500 Internal Server Error, allowing us to test the UI's error handling.

3.  **Q: Describe a scenario where you would use API mocking for an edge case.**
    A: A common edge case is an "empty state" for a list or table. Suppose we have a product listing page. Without mocking, we'd need to ensure the database has no products to test the "No products found" message. With API mocking, we can intercept the `/products` API call and fulfill it with an empty JSON array (`body: JSON.stringify([])`), directly asserting that the "No products found" message is displayed, regardless of the actual database state. Another case is simulating a very slow API to test loading indicators.

4.  **Q: What are the potential drawbacks or challenges of using API mocking in tests?**
    A: Challenges include:
    *   **Maintenance Overhead**: Mocks need to be updated if the actual API contract changes, leading to potential staleness.
    *   **Inaccuracy**: Mocks might not perfectly replicate complex backend logic or subtle data transformations, potentially leading to false positives.
    *   **Over-Mocking**: Mocking too much can obscure actual integration issues and make tests brittle.
    *   **Debugging Complexity**: Debugging network issues can be harder when some requests are mocked and others are live.

## Hands-on Exercise
**Objective**: Test a "User Profile" page for various states: loading, successful data display, and error.

**Instructions**:
1.  Assume you have a web application with a `/profile` page that fetches user data from `https://api.example.com/user/123`.
2.  **Create a Playwright test file.**
3.  **Implement three separate tests:**
    *   **Test 1: Successful Profile Display**: Mock the API to return a specific user object (e.g., `{ id: 123, name: 'John Doe', email: 'john.doe@example.com' }`). Assert that 'John Doe' and 'john.doe@example.com' are visible on the page.
    *   **Test 2: User Not Found**: Mock the API to return a `404` status with an error message. Assert that a "User not found" or similar error message is displayed on the page.
    *   **Test 3: Loading State**: Mock the API to introduce a 3-second delay before fulfilling with successful data. Assert that a loading spinner (or "Loading..." text) is visible initially, and then the user data appears after the delay, with the loading indicator disappearing.
4.  **(Self-reflection)**: Consider how you would verify that the UI correctly handles a `500` error or an empty profile data scenario.

## Additional Resources
-   **Playwright Network Documentation**: [https://playwright.dev/docs/network](https://playwright.dev/docs/network) - Official documentation on network interception and mocking.
-   **Playwright `page.route()` API Reference**: [https://playwright.dev/docs/api/class-page#page-route](https://playwright.dev/docs/api/class-page#page-route) - Detailed API for the routing method.
-   **Blog Post on Playwright API Mocking**: Search for "Playwright API Mocking Tutorial" on Google or YouTube for various community-contributed guides and examples.
---
# playwright-5.5-ac7.md

# Playwright: Modifying Network Requests (Headers, Method, Post Data)

## Overview
Network request modification in Playwright is a powerful feature that allows testers to alter outgoing HTTP requests before they reach the server. This capability is crucial for simulating various real-world scenarios, testing authentication and authorization flows, injecting fault conditions, and verifying how an application behaves under different network conditions or data inputs. By programmatically changing headers, HTTP methods, or the request body (post data), SDETs can gain fine-grained control over their tests, enabling more robust and comprehensive test suites.

## Detailed Explanation
Playwright's `page.route()` method is the cornerstone for intercepting and modifying network requests. When a request matches a specified URL pattern, `page.route()` provides a `Route` object, allowing you to either `fulfill` the request with a custom response or `continue` it with modifications.

The `route.continue()` method is used to allow the request to proceed to its destination, but with potential changes. It accepts an optional `options` object with properties like `headers`, `method`, and `postData`.

### 1. Modifying Request Headers
Headers are key-value pairs that carry metadata about the request. You might want to modify headers to:
- Add `Authorization` tokens for authenticated requests.
- Change `User-Agent` to simulate different browsers/devices.
- Inject custom headers for A/B testing or specific backend logic.

When using `route.continue({ headers: ... })`, you provide an object where keys are header names and values are their desired content. Note that providing new headers will **merge** with the existing headers. If you want to remove an existing header, you can explicitly set its value to `undefined` or an empty string, or rebuild the headers object from scratch if you need precise control. It's often safer to get the existing headers and then modify them.

```typescript
await page.route('**/api/data', async route => {
  const headers = await route.request().headers();
  await route.continue({
    headers: {
      ...headers, // Copy existing headers
      'X-Custom-Header': 'MyValue',
      'Authorization': 'Bearer my_auth_token_123',
      'User-Agent': 'PlaywrightTestBot'
    },
  });
});
```

### 2. Modifying Request Method
Changing the HTTP method allows you to test how a server or client-side application reacts if a request originally intended as, say, a `POST`, arrives as a `PUT` or `GET`. This is less common but can be useful for security testing or verifying method-specific endpoint logic.

```typescript
await page.route('**/api/resource', async route => {
  await route.continue({
    method: 'PUT', // Change POST to PUT, or GET to POST etc.
  });
});
```
**Important**: When changing methods, ensure the new method is compatible with the `postData` (if any). For example, changing a `POST` with a body to a `GET` will typically strip the body.

### 3. Modifying Post Data Payload
`postData` refers to the body of an HTTP request, typically used with `POST`, `PUT`, and `PATCH` methods to send data to the server (e.g., JSON, form data). Modifying `postData` is essential for:
- Testing different input values without changing UI.
- Injecting invalid data to test validation.
- Simulating specific user actions or data states.

The `postData` property in `route.continue()` expects a string or a Buffer. If your original request sends JSON, you should parse the existing `postData`, modify the JavaScript object, and then `JSON.stringify()` it back into a string. Remember to also update the `Content-Type` header if the data type changes.

```typescript
await page.route('**/api/submit', async route => {
  const request = route.request();
  let postData = request.postData();

  if (postData) {
    try {
      const payload = JSON.parse(postData);
      payload.userName = 'modifiedUser';
      payload.isAdmin = true;
      postData = JSON.stringify(payload);
    } catch (e) {
      console.error('Could not parse postData as JSON:', e);
      // Handle non-JSON postData if necessary
    }
  }

  const headers = await request.headers();
  await route.continue({
    postData: postData,
    headers: {
      ...headers,
      'Content-Type': 'application/json' // Ensure content type matches
    }
  });
});
```

## Code Implementation

This example demonstrates intercepting a POST request, adding a custom header, changing the method to PUT, and modifying the JSON payload. We'll simulate a backend endpoint using `page.route().fulfill()` to inspect the incoming request.

```typescript
// example.spec.ts
import { test, expect, Page, Route } from '@playwright/test';

test.describe('Network Request Modification', () => {

  // A helper function to simulate an API endpoint that captures and responds with the received request details
  async function setupMockApi(page: Page) {
    await page.route('**/api/resource', async (route: Route) => {
      const request = route.request();
      const headers = await request.allHeaders();
      const method = request.method();
      let postData = null;
      if (request.postDataBuffer()) {
        postData = request.postData();
      }

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          receivedMethod: method,
          receivedHeaders: headers,
          receivedPostData: postData ? JSON.parse(postData) : null,
          message: 'Request successfully processed by mock server.'
        }),
      });
    });
  }

  test('should modify request headers, method, and post data', async ({ page }) => {
    // 1. Setup our mock API to capture request details
    await setupMockApi(page);

    // 2. Intercept the outgoing request to modify it
    await page.route('**/api/resource', async (route: Route) => {
      const originalRequest = route.request();

      // Get existing headers to merge new ones
      const currentHeaders = await originalRequest.allHeaders();

      // Modify headers: add new, change existing (e.g., Authorization), potentially remove
      const newHeaders = {
        ...currentHeaders,
        'X-Trace-Id': 'playwright-test-123',
        'Authorization': 'Bearer modified_token',
        'User-Agent': 'PlaywrightModifiedAgent',
        // 'Accept-Encoding': undefined // Example of how to remove a header (by setting to undefined)
      };

      // Modify post data: Assuming original is JSON
      let modifiedPostData: string | undefined;
      const originalPostData = originalRequest.postData();
      if (originalPostData) {
        try {
          const payload = JSON.parse(originalPostData);
          payload.userId = 'modifiedUser123';
          payload.status = 'updated';
          modifiedPostData = JSON.stringify(payload);
          // Ensure Content-Type is correct if you're sending JSON
          newHeaders['Content-Type'] = 'application/json';
        } catch (e) {
          console.warn('Original postData was not JSON or empty. Skipping payload modification.', e);
          modifiedPostData = originalPostData; // Keep original if parsing fails
        }
      }

      // Continue the route with modifications
      await route.continue({
        headers: newHeaders,
        method: 'PUT', // Change the HTTP method
        postData: modifiedPostData,
      });
    });

    // 3. Trigger a request from the page (e.g., a form submission, API call)
    // We'll simulate a POST request with initial data
    const response = await page.evaluate(async () => {
      const res = await fetch('/api/resource', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer original_token',
          'User-Agent': 'OriginalAgent'
        },
        body: JSON.stringify({
          userId: 'originalUser',
          data: 'someData',
          status: 'initial'
        })
      });
      return res.json();
    });

    // 4. Assertions: Verify that our mock API received the modified request
    expect(response.receivedMethod).toBe('PUT'); // Method should be modified
    expect(response.receivedHeaders['x-trace-id']).toBe('playwright-test-123'); // Custom header added
    expect(response.receivedHeaders['authorization']).toBe('Bearer modified_token'); // Authorization header modified
    expect(response.receivedHeaders['user-agent']).toBe('PlaywrightModifiedAgent'); // User-Agent header modified

    // Assert post data modifications
    expect(response.receivedPostData).toEqual({
      userId: 'modifiedUser123',
      data: 'someData',
      status: 'updated'
    });

    expect(response.message).toBe('Request successfully processed by mock server.');
  });
});
```

## Best Practices
- **Be Specific with URL Patterns**: Use precise glob patterns or regular expressions in `page.route()` to avoid unintentionally intercepting and modifying requests that shouldn't be touched.
- **Maintain Original Headers**: When modifying headers, always retrieve the existing headers first using `route.request().allHeaders()` and then merge your changes. This ensures that essential headers (like `Host`, `Content-Length`) are not accidentally removed.
- **Handle Different `postData` Types**: Be mindful of the `Content-Type` header when modifying `postData`. If you modify a JSON body, ensure the `Content-Type` header remains `application/json`. For form data, process it accordingly.
- **Use `route.continue()` for Modifications**: Reserve `route.fulfill()` for mocking entire responses. For request-level alterations, `route.continue()` is the appropriate method.
- **Clean Up Routes**: In complex test suites, ensure routes are unset after the relevant tests to prevent interference with other tests. Playwright automatically cleans up routes registered within a `test()` block, but be cautious with global or `beforeEach` routes.

## Common Pitfalls
- **Forgetting `route.continue()` or `route.fulfill()`**: If a request is intercepted but neither `route.continue()` nor `route.fulfill()` is called, the request will hang, causing tests to time out.
- **Overwriting All Headers**: Directly assigning `{ headers: { ... } }` without spreading the `currentHeaders` will overwrite all existing headers, potentially breaking the request.
- **Incorrect `postData` Format**: Modifying a JSON payload but forgetting to `JSON.stringify()` it back, or sending a malformed string, will lead to server errors. Similarly, not updating `Content-Type` after changing data format.
- **Broad Interception Patterns**: Using `**/*` or similarly broad patterns can lead to unexpected side effects, as many requests (images, CSS, fonts) might be unintentionally intercepted.
- **Race Conditions with Multiple Routes**: If multiple `page.route()` calls match the same URL, their execution order can lead to unpredictable behavior. Structure your tests to have clear interception logic.

## Interview Questions & Answers
1.  **Q: When would you typically use `page.route()` to modify an outgoing request in Playwright?**
    **A:** I'd use `page.route()` to modify outgoing requests for several key scenarios:
    *   **Authentication/Authorization Testing:** Injecting or modifying `Authorization` headers to test different user roles or invalid tokens.
    *   **Data Manipulation:** Changing form submissions or API payloads to test validation, edge cases (e.g., very long strings, special characters), or unauthorized data access.
    *   **Simulating Client-Side Logic:** Testing how the application behaves if certain data is sent or not sent, or if the HTTP method is altered.
    *   **Performance/Security Testing:** Adding custom headers for tracing or security policy enforcement.

2.  **Q: How do you add a custom header to a request, ensuring existing headers are preserved?**
    **A:** To add a custom header while preserving existing ones, I would first retrieve all current headers using `route.request().allHeaders()`. Then, I'd create a new headers object by spreading the existing headers and adding my new custom header(s). Finally, I'd pass this new headers object to `route.continue({ headers: newHeaders })`. This ensures a merge rather than an overwrite.

3.  **Q: Can you change the HTTP method of a request (e.g., from POST to PUT) using Playwright? If so, what are the considerations?**
    **A:** Yes, you can change the HTTP method using `route.continue({ method: 'PUT' })`. The main consideration is compatibility with the request body (`postData`). If you change a `POST` (which typically has a body) to a `GET` (which typically does not), the `postData` will usually be stripped by the browser/Playwright unless explicitly handled. Conversely, if you change a `GET` to a `POST` and intend to send data, you must also provide appropriate `postData` and set the `Content-Type` header.

4.  **Q: What challenges might you encounter when modifying the `postData` of a request, especially for JSON payloads?**
    **A:** The primary challenges include:
    *   **Parsing and Stringifying:** `postData` is a string or Buffer. For JSON, you must parse it (`JSON.parse()`), modify the resulting JavaScript object, and then convert it back to a string (`JSON.stringify()`) before passing it to `route.continue()`.
    *   **`Content-Type` Header:** If you modify the `postData` (e.g., changing it from JSON to form data, or vice versa), you **must** also update the `Content-Type` header accordingly to ensure the server correctly interprets the payload.
    *   **Handling Empty or Non-JSON Data:** You need robust error handling for `JSON.parse()` if the original `postData` might be empty, malformed, or not in JSON format (e.g., URL-encoded form data).

## Hands-on Exercise
**Scenario**: You are testing a web application that has a registration form. When a user submits the form, a `POST` request is sent to `/api/register` with user details (e.g., `email`, `password`, `referrer`).
**Task**: Write a Playwright test that:
1. Intercepts the `POST` request to `/api/register`.
2. Modifies the `email` in the `postData` payload to `testuser-modified@example.com` and adds a `X-Testing-Group` header with value `A`.
3. Changes the HTTP method of the request from `POST` to `PATCH`.
4. Asserts that the modified request (as received by a mock server or captured in a test utility) contains the new email, the new header, and the `PATCH` method.

You can use a similar `setupMockApi` function as in the example above to simulate the server's reception of the modified request.

## Additional Resources
-   **Playwright `page.route()` Documentation**: [https://playwright.dev/docs/network#modify-requests](https://playwright.dev/docs/network#modify-requests)
-   **Playwright Network Handling Guide**: [https://playwright.dev/docs/network](https://playwright.dev/docs/network)
-   **HTTP Methods (MDN Web Docs)**: [https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods)
---
# playwright-5.5-ac8.md

# Playwright: Waiting for Specific Network Requests/Responses

## Overview
In modern web applications, client-side interactions often trigger asynchronous network requests to fetch or submit data. Robust test automation requires the ability to wait for and assert on these network activities to ensure that the application state is correctly updated and that data integrity is maintained. Playwright provides powerful APIs like `page.waitForRequest()` and `page.waitForResponse()` that allow testers to precisely control and synchronize their tests with network events. This is crucial for testing complex user flows, validating data submissions, and ensuring that your tests are not flaky due to timing issues.

## Detailed Explanation
Playwright's `page.waitForRequest()` and `page.waitForResponse()` methods are essential for handling asynchronous operations that involve network communication. These methods return a Promise that resolves when a network request or response matching a given predicate (condition) is observed.

### `page.waitForRequest(urlOrPredicate[, options])`
This method waits for a network request to be initiated that matches the specified URL or predicate function.

- **`urlOrPredicate`**: Can be a string, a regular expression, or a function.
    - **String**: Matches the URL exactly.
    - **Regular Expression**: Matches the URL against the regex.
    - **Function**: A predicate function that receives the `Request` object and returns `true` if it's the desired request, `false` otherwise. This offers the most flexibility for complex matching criteria (e.g., checking request method, headers, or post data).
- **`options`**:
    - **`timeout`**: Maximum time in milliseconds to wait for the event. Defaults to 30000ms.

### `page.waitForResponse(urlOrPredicate[, options])`
Similar to `waitForRequest()`, this method waits for a network *response* to be received that matches the specified URL or predicate function. This is particularly useful for asserting on response status, headers, or body content.

- **`urlOrPredicate`**: Can be a string, a regular expression, or a function.
    - **String**: Matches the URL of the response exactly.
    - **Regular Expression**: Matches the URL of the response against the regex.
    - **Function**: A predicate function that receives the `Response` object and returns `true` if it's the desired response, `false` otherwise. This allows for checking response status, headers, or even parsing the response body.
- **`options`**:
    - **`timeout`**: Maximum time in milliseconds to wait for the event. Defaults to 30000ms.

### Workflow:
1. **Define the expectation**: Determine which request or response you need to wait for (e.g., a specific API endpoint, a file download).
2. **Start waiting**: Call `page.waitForRequest()` or `page.waitForResponse()` *before* triggering the action that causes the network event. Store the returned Promise.
3. **Trigger action**: Perform the user interaction or code execution that initiates the network call.
4. **Await the promise**: Use `await` on the Promise obtained in step 2. This will pause your test until the matching network event occurs or the timeout is reached.
5. **Assert**: Once the Promise resolves, you can access the `Request` or `Response` object to perform assertions (e.g., check status codes, validate payloads, verify headers).

## Code Implementation
Here's a TypeScript example demonstrating how to wait for specific network requests and responses in Playwright.

```typescript
import { test, expect, Page, Request, Response } from '@playwright/test';

test.describe('Network Interception and Waiting', () => {

    test.beforeEach(async ({ page }) => {
        // Navigate to a test page that makes network requests
        await page.goto('https://www.example.com'); // Replace with a suitable URL for testing
    });

    test('should wait for a specific POST request and assert its payload', async ({ page }) => {
        // 1. Start waiting for the request before triggering the action
        const requestPromise = page.waitForRequest(request =>
            request.url().includes('/api/submit-data') && request.method() === 'POST'
        );

        // 2. Perform the action that triggers the network call
        // Assuming there's a button click or form submission that makes this request
        await page.evaluate(() => {
            fetch('/api/submit-data', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name: 'John Doe', email: 'john.doe@example.com' })
            });
        });

        // 3. Await the promise to get the caught request
        const request: Request = await requestPromise;

        // 4. Assertions on the request
        expect(request.postDataJSON()).toEqual({ name: 'John Doe', email: 'john.doe@example.com' });
        expect(request.headers()['content-type']).toContain('application/json');
        console.log('Caught POST Request URL:', request.url());
    });

    test('should wait for a specific GET response and assert its status and data', async ({ page }) => {
        // 1. Start waiting for the response before triggering the action
        const responsePromise = page.waitForResponse(response =>
            response.url().includes('/api/users') && response.status() === 200
        );

        // 2. Perform the action that triggers the network call
        // Assuming a click event that fetches user data
        await page.evaluate(() => {
            fetch('/api/users');
        });

        // 3. Await the promise to get the caught response
        const response: Response = await responsePromise;

        // 4. Assertions on the response
        expect(response.status()).toBe(200);
        const responseBody = await response.json();
        expect(responseBody).toHaveProperty('users');
        expect(Array.isArray(responseBody.users)).toBe(true);
        console.log('Caught GET Response URL:', response.url());
        console.log('Caught GET Response Body:', responseBody);
    });

    test('should handle network request timeout gracefully', async ({ page }) => {
        // We expect this to timeout because no action will trigger this request
        const requestPromise = page.waitForRequest('**/non-existent-api', { timeout: 1000 }); // 1 second timeout

        let error: Error | undefined;
        try {
            await requestPromise;
        } catch (e) {
            error = e as Error;
        }

        expect(error).toBeInstanceOf(Error);
        expect(error?.message).toContain('Timeout');
        console.log('Successfully handled network request timeout.');
    });
});
```

**Note**: For the code to run, you would typically need a local web server that can serve responses for `/api/submit-data` and `/api/users`. For instance, you could use a simple Express.js server:

```javascript
// server.js (Node.js with Express)
const express = require('express');
const app = express();
const port = 3000;

app.use(express.json());

app.post('/api/submit-data', (req, res) => {
    console.log('Received data:', req.body);
    res.status(200).json({ message: 'Data received successfully!', data: req.body });
});

app.get('/api/users', (req, res) => {
    res.status(200).json({ users: [{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }] });
});

app.get('/', (req, res) => {
    res.send('<h1>Welcome to the test page!</h1><script>function fetchData(){ fetch("/api/users"); } function postData(){ fetch("/api/submit-data", {method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify({name: "Test", email: "test@example.com"}) }); }</script><button onclick="fetchData()">Fetch Users</button><button onclick="postData()">Post Data</button>');
});

app.listen(port, () => {
    console.log(`Test server listening at http://localhost:${port}`);
});
```
You would then set `await page.goto('http://localhost:3000');` in your Playwright test.

## Best Practices
- **Place `waitForRequest/Response` before the action**: Always initiate the `waitFor` call *before* the action that triggers the network event to ensure you don't miss the event.
- **Use predicate functions for precision**: For complex scenarios, use predicate functions to precisely match requests/responses based on method, headers, or payload, rather than just URL strings.
- **Specify timeouts**: Use `timeout` options appropriately to prevent tests from hanging indefinitely if a network event doesn't occur.
- **Isolate network interactions**: Design your tests to focus on one network interaction at a time when using `waitForRequest/Response` to keep them clear and maintainable.
- **Combine with `Promise.all` for multiple events**: If an action triggers multiple network requests or responses you need to wait for, use `Promise.all` to await all of them concurrently.

## Common Pitfalls
- **Missing the event**: Calling `waitForRequest/Response` *after* the action that triggers the network call. The event might have already happened, leading to a timeout.
- **Overly broad predicates**: Using generic URLs or predicates that match too many requests/responses, causing the test to wait for the wrong event. Be as specific as possible.
- **Not handling timeouts**: Failing to implement error handling for network waits can lead to hanging tests or unclear failures.
- **Ignoring asynchronous nature**: Treating network calls as synchronous operations, leading to flaky tests that depend on arbitrary network timing.
- **Not checking response content**: Just waiting for a 200 status code is often not enough; always assert on the actual response data when necessary.

## Interview Questions & Answers
1. Q: Explain the difference between `page.waitForRequest()` and `page.waitForResponse()` and when you would use each.
   A: `page.waitForRequest()` waits for a network request to be initiated by the page. You'd use it to assert on the outgoing request's properties, such as its URL, method, headers, or post data *before* the server responds. `page.waitForResponse()` waits for a network response to be received by the page. You'd use it to assert on the incoming response's properties, like its status code, headers, or response body *after* the server has processed the request. Generally, if you need to validate what your application *sends*, use `waitForRequest`. If you need to validate what your application *receives* and how it reacts, use `waitForResponse`.

2. Q: How do you prevent Playwright tests from becoming flaky due to network timing issues?
   A: The primary way to prevent flakiness due to network timing is by using Playwright's network waiting mechanisms like `page.waitForRequest()`, `page.waitForResponse()`, or even more general methods like `page.waitForLoadState('networkidle')`. These methods ensure that your test execution is synchronized with the application's network activity, preventing assertions from running before necessary data has been loaded or processed. Additionally, using specific predicates (functions) with these `waitFor` methods allows for precise targeting of the desired network events, reducing the chance of waiting for an irrelevant call.

3. Q: Can you give an example of a scenario where `page.waitForResponse()` with a predicate function would be more beneficial than just waiting for a URL string?
   A: Absolutely. Consider an API endpoint `/api/status` that can return either a `200 OK` with a success message or a `400 Bad Request` with an error message depending on some application state. If you only wait for `page.waitForResponse('/api/status')`, your test will resolve upon *any* response from that URL. However, if you specifically want to test the success scenario, you would use a predicate function: `page.waitForResponse(response => response.url().includes('/api/status') && response.status() === 200 && response.json().then(data => data.message === 'Success'))`. This allows you to wait for a response that not only matches the URL and status but also contains a specific message in its body, ensuring the correct application flow is being tested.

## Hands-on Exercise
**Scenario**: You are testing a dashboard application that loads user statistics after login.
**Task**:
1. Navigate to a login page (mock one if necessary, or use a public one).
2. Log in with valid credentials.
3. After logging in, the dashboard page makes a `GET` request to `/api/dashboard-stats` which returns JSON data.
4. Your test should wait for this specific response, verify its status code is 200, and assert that the response body contains a property named `totalUsers` and `activeUsers`.

**Instructions**:
- Set up a basic Playwright test.
- Use `page.goto()` for navigation.
- Implement the login action (e.g., `page.fill()`, `page.click()`).
- Use `page.waitForResponse()` with an appropriate predicate.
- Add `expect()` assertions to validate the response status and body content.
- (Optional but recommended): If you don't have a live API, use Playwright's `page.route()` to mock the `/api/dashboard-stats` response for controlled testing.

## Additional Resources
- **Playwright `page.waitForRequest()` documentation**: [https://playwright.dev/docs/api/class-page#page-wait-for-request](https://playwright.dev/docs/api/class-page#page-wait-for-request)
- **Playwright `page.waitForResponse()` documentation**: [https://playwright.dev/docs/api/class-page#page-wait-for-response](https://playwright.dev/docs/api/class-page#page-wait-for-response)
- **Playwright Network Introduction**: [https://playwright.dev/docs/network](https://playwright.dev/docs/network)
---
# playwright-5.5-ac9.md

# Playwright: Blocking Unnecessary Resources for Faster Tests

## Overview
In Playwright test automation, network interception is a powerful feature that allows you to control network requests made by the browser. One of its most effective applications is blocking unnecessary resources like images, fonts, or stylesheets during test execution. This technique can significantly speed up your tests, reduce network traffic, and ensure that your tests focus on the core functionality without being bogged down by non-essential asset loading. By strategically blocking resources, you can achieve faster feedback cycles and more efficient CI/CD pipelines.

## Detailed Explanation
Playwright provides the `page.route(url, handler)` method to intercept network requests. The `url` parameter can be a string, a regular expression, or a function to match specific requests. The `handler` is an asynchronous function that receives a `Route` object, which represents the intercepted request. Within this handler, you can either fulfill the request (`route.fulfill()`), continue it (`route.continue()`), or abort it (`route.abort()`).

To block resources, we utilize `route.abort()`. The key is to identify the type of resource being requested. The `request` object, accessible via `route.request()`, has a `resourceType()` method that returns a string indicating the type of resource (e.g., 'image', 'font', 'stylesheet', 'script').

By combining `page.route()` with a handler that checks `request.resourceType()`, we can selectively block specific types of assets. For instance, to block images and fonts, we can set up a route that intercepts all requests, inspects their type, and aborts those identified as 'image' or 'font'.

It's crucial to ensure that you only block resources that are genuinely unnecessary for the test's purpose. Over-blocking can lead to brittle tests or hide actual issues by preventing critical elements from loading.

## Code Implementation
The following Playwright test demonstrates how to block image and font resources to potentially speed up test execution.

First, create a simple HTML file named `test_page.html` in your project root to simulate a page with images and fonts:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resource Blocking Test Page</title>
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Roboto', sans-serif;
            margin: 20px;
        }
        h1 {
            color: #333;
        }
        .container {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
        }
        .image-card {
            border: 1px solid #ccc;
            padding: 10px;
            border-radius: 5px;
            text-align: center;
        }
        img {
            max-width: 150px;
            height: auto;
            display: block;
            margin: 0 auto 10px;
        }
    </style>
</head>
<body>
    <h1>Welcome to the Resource Blocking Demo</h1>
    <p>This page loads several images and uses a custom font (Roboto) from Google Fonts.</p>
    <div class="container">
        <div class="image-card">
            <img src="https://picsum.photos/id/237/200/150" alt="Dog">
            <p>A random dog image.</p>
        </div>
        <div class="image-card">
            <img src="https://picsum.photos/id/238/200/150" alt="Nature">
            <p>A nature scene.</p>
        </div>
        <div class="image-card">
            <img src="https://picsum.photos/id/239/200/150" alt="City">
            <p>A city view.</p>
        </div>
    </div>
    <p>Some additional text to show font rendering: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
</body>
</html>
```

Now, here's the Playwright test (`block-resources.spec.ts`):

```typescript
import { test, expect } from '@playwright/test';

test.describe('Resource Blocking for Performance', () => {

    test('should load page faster by blocking images and fonts', async ({ page }) => {
        let blockedRequests = 0;

        // Listen for all network requests
        await page.route('**/*', async route => {
            const resourceType = route.request().resourceType();
            // Block requests for images and fonts
            if (resourceType === 'image' || resourceType === 'font') {
                console.log(`Blocking: ${resourceType} - ${route.request().url()}`);
                route.abort(); // Abort the request
                blockedRequests++;
            } else {
                route.continue(); // Allow other requests to proceed
            }
        });

        // Capture start time
        const startTime = Date.now();

        // Navigate to a local HTML file for demonstration
        // Make sure 'test_page.html' is in your project root or specify the correct path
        await page.goto('file:///' + process.cwd() + '/test_page.html');

        // Capture end time
        const endTime = Date.now();
        const loadTime = endTime - startTime;

        console.log(`Page loaded in ${loadTime}ms with ${blockedRequests} requests blocked.`);

        // Assertions to verify that images are not visible (or at least not loaded)
        // You might check for placeholder alt text or broken image icons
        const imageElements = await page.locator('img').all();
        for (const img of imageElements) {
            // Check if the image has a naturalWidth (indicating it loaded)
            // If it's blocked, naturalWidth might be 0, but this is not foolproof for all cases.
            // A more robust check might involve visually inspecting the page or checking network logs.
            // For this example, we'll just log and assert presence of the element.
            await expect(img).toBeVisible(); // The element itself should be present in DOM
        }

        // Verify that the blocking mechanism is effective (optional, but good for confidence)
        expect(blockedRequests).toBeGreaterThan(0);

        // You can add more specific assertions here based on your application's behavior
        // e.g., expect certain text content to be present, indicating core functionality loaded.
        await expect(page.locator('h1')).toHaveText('Welcome to the Resource Blocking Demo');

        // You might want to run a baseline test without blocking resources to compare load times.
    });

    test('should load page with all resources (baseline for comparison)', async ({ page }) => {
        // No resource blocking in this test, all requests will continue by default
        const startTime = Date.now();
        await page.goto('file:///' + process.cwd() + '/test_page.html');
        const endTime = Date.now();
        const loadTime = endTime - startTime;
        console.log(`Baseline page loaded in ${loadTime}ms with all resources.`);

        // Expect images to be loaded
        const imageElements = await page.locator('img').all();
        for (const img of imageElements) {
            // This is a basic check. A more advanced check might involve checking for naturalWidth > 0
            // or waiting for the image to be "loaded".
            await expect(img).toBeVisible();
        }
    });
});
```

## Best Practices
- **Selective Blocking:** Only block resources that do not impact the core functionality or visual aspects being tested. For instance, if you are testing an API integration, blocking UI assets might be acceptable.
- **Performance-Critical Paths:** Apply resource blocking primarily to tests that cover performance-critical user flows where network load is a significant factor.
- **Environment Awareness:** Consider whether blocking should be applied universally or only in specific test environments (e.g., CI/CD pipelines where network latency might be higher).
- **Graceful Handling:** Ensure that your application under test can handle blocked resources gracefully without crashing or displaying critical errors, as this can reveal underlying issues.
- **Use `request.isNavigationRequest()`:** To prevent accidentally blocking the main document request, you can add a condition like `if (!route.request().isNavigationRequest() && (resourceType === 'image' || resourceType === 'font'))`.

## Common Pitfalls
- **Over-blocking:** The most common pitfall is blocking too many resources, leading to tests that pass but do not accurately reflect real user experience. This can result in false positives where a bug might exist with a loaded resource but goes undetected.
- **Visual Regression Testing Conflicts:** If your test suite includes visual regression tests, blocking resources will almost certainly cause these tests to fail or produce misleading results because the page's visual appearance will change significantly.
- **Hidden Dependencies:** Sometimes, what seems like an "unnecessary" resource might have a subtle dependency or trigger an important side effect. Blocking it could mask a bug.
- **Maintenance Overhead:** As your application evolves, resource types and their importance might change. Regularly review your resource blocking strategy to avoid blocking newly critical assets or unblocking non-critical ones.

## Interview Questions & Answers
1.  **Q: Why would you choose to block certain resources like images or fonts in your Playwright tests?**
    **A:** Blocking resources like images and fonts can significantly improve test execution speed by reducing network traffic and page load times. This is particularly beneficial for tests focusing on application logic, API interactions, or UI elements where the visual assets are not critical for the test's assertion. It leads to faster feedback loops in development and CI/CD pipelines.

2.  **Q: How do you implement resource blocking in Playwright, and what Playwright methods are involved?**
    **A:** Resource blocking in Playwright is primarily achieved using the `page.route()` method. Inside the route handler, you access the `Route` object, which provides the `route.request()` method to get details about the intercepted request. You then use `request.resourceType()` to identify the type of resource (e.g., 'image', 'font', 'stylesheet'). If the resource type matches the criteria for blocking, `route.abort()` is called; otherwise, `route.continue()` is used to allow the request to proceed.

3.  **Q: What are the potential trade-offs or risks associated with blocking resources in automated tests?**
    **A:** The main trade-offs include:
    *   **Visual Discrepancies:** Blocking resources alters the page's visual rendering, making it incompatible with visual regression testing.
    *   **Hidden Bugs:** It can mask bugs related to asset loading, broken images, or font rendering issues that would otherwise appear to a real user.
    *   **Test Brittleness:** If a blocked resource becomes critical for a test's functionality in the future, the test might break or provide incorrect results.
    *   **Reduced Realism:** Tests might not fully reflect the actual user experience if significant assets are omitted.

## Hands-on Exercise
**Objective:** Write a Playwright test that navigates to a sample web page and blocks all CSS stylesheets. Verify that the page loads but appears unstyled, confirming the blocking was successful.

1.  **Create an HTML file:** Create `unstyled_page.html` with some basic HTML and a linked CSS file (e.g., Google Fonts CSS or a local CSS file).
2.  **Write the Playwright test:**
    *   Use `page.route('**/*', ...)` to intercept all requests.
    *   Inside the handler, check if `request.resourceType()` is `'stylesheet'`.
    *   If it's a stylesheet, `route.abort()`; otherwise, `route.continue()`.
    *   Navigate to `unstyled_page.html`.
    *   Add an assertion to verify that the page content is present but looks unstyled (e.g., check for default font, lack of colors, etc. – this might require visual inspection or checking computed styles).

## Additional Resources
-   **Playwright `page.route()` documentation:** [https://playwright.dev/docs/network#route-requests](https://playwright.dev/docs/network#route-requests)
-   **Playwright `Request` object documentation:** [https://playwright.dev/docs/api/class-request](https://playwright.dev/docs/api/class-request)
-   **Playwright `resourceType` values:** [https://playwright.dev/docs/api/class-request#request-resource-type](https://playwright.dev/docs/api/class-request#request-resource-type)
