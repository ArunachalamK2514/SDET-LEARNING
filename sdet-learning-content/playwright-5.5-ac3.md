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
