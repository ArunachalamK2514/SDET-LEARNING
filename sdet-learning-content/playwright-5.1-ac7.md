# Playwright Project Setup & Configuration: Environment-Specific Configuration Files

## Overview
In any robust test automation framework, managing environment-specific configurations is crucial. Whether you're running tests against local development, staging, or production environments, each often requires different URLs, API keys, user credentials, or other settings. This feature focuses on demonstrating how to effectively set up and manage these configurations in a Playwright project using `dotenv` and command-line arguments, ensuring your tests are flexible, maintainable, and secure across various environments.

## Detailed Explanation
Playwright tests often interact with different application environments. Hardcoding environment-specific values in your test code is a bad practice as it leads to brittle tests and security vulnerabilities. A better approach is to externalize these configurations.

The `dotenv` library is a popular solution for loading environment variables from `.env` files. We can leverage `dotenv` in conjunction with Playwright's configuration (`playwright.config.ts`) and command-line arguments to dynamically load the appropriate configuration based on the target environment.

Here's the general strategy:
1.  **Install `dotenv`**: This package helps load variables from `.env` files into `process.env`.
2.  **Create `.env` file for local development**: A `.env` file will hold default or local development environment variables (e.g., `BASE_URL=http://localhost:3000`).
3.  **Create `env` directory for stage/prod configs**: To handle multiple environments, we can create an `env` directory containing files like `.env.staging`, `.env.production`, etc., each holding specific configurations for their respective environments.
4.  **Modify Playwright config**: Update `playwright.config.ts` to read environment variables. We'll add logic to parse a command-line argument (e.g., `--env=staging`) to determine which `.env` file to load. If no argument is provided, it defaults to a local `.env` or a sensible fallback.

This approach keeps sensitive information out of version control (if `.env` files are properly ignored) and allows for easy switching between environments without modifying code.

## Code Implementation

First, install `dotenv`:
```bash
npm install --save-dev dotenv
```

Next, create the `.env` files and directory structure:

`./.env` (for local development/defaults)
```
BASE_URL=http://localhost:3000
API_KEY=local_dev_api_key_123
USER_EMAIL=dev_user@example.com
USER_PASSWORD=dev_password
```

`./env/.env.staging`
```
BASE_URL=https://staging.example.com
API_KEY=staging_api_key_456
USER_EMAIL=stage_user@example.com
USER_PASSWORD=stage_password
```

`./env/.env.production` (Example, typically loaded securely in CI/CD)
```
BASE_URL=https://www.example.com
API_KEY=prod_api_key_789
USER_EMAIL=prod_user@example.com
USER_PASSWORD=prod_password
```

Now, modify `playwright.config.ts`:

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';
import * as dotenv from 'dotenv';
import path from 'path';

// Determine the environment from command line arguments
// e.g., `npx playwright test --project=chromium --env=staging`
const environment = process.argv.find(arg => arg.startsWith('--env='))?.split('=')[1] || 'local';

// Load environment variables based on the detected environment
let envPath = '.env'; // Default to local .env
if (environment !== 'local') {
  envPath = path.resolve(__dirname, `env/.env.${environment}`);
}
dotenv.config({ path: envPath });

/**
 * Read environment variables from .env file.
 * https://github.com/motdotla/dotenv
 */
// require('dotenv').config(); // This line is replaced by the dynamic loading above

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: './tests',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: 'html',
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    // baseURL: 'http://127.0.0.1:3000',
    baseURL: process.env.BASE_URL, // Use BASE_URL from .env files

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',

    // Pass environment variables to tests if needed (e.g., API_KEY)
    launchOptions: {
      args: [`--api-key=${process.env.API_KEY}`],
    },
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },

    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },

    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },

    /* Test against mobile viewports. */
    // {
    //   name: 'Mobile Chrome',
    //   use: { ...devices['Pixel 5'] },
    // },
    // {
    //   name: 'Mobile Safari',
    //   use: { ...devices['iPhone 12'] },
    // },

    /* Test against branded browsers. */
    // {
    //   name: 'Microsoft Edge',
    //   use: { ...devices['Desktop Edge'], channel: 'msedge' },
    // },
    // {
    //   name: 'Google Chrome',
    //   use: { ...devices['Desktop Chrome'], channel: 'chrome' },
    // },
  ],

  /* Run your local dev server before starting the tests */
  // webServer: {
  //   command: 'npm run start',
  //   url: 'http://127.0.0.1:3000',
  //   reuseExistingServer: !process.env.CI,
  // },
});
```

Example test (`./tests/example.spec.ts`):
```typescript
import { test, expect } from '@playwright/test';

test.describe('Environment-specific tests', () => {
  test('should navigate to the correct base URL', async ({ page }) => {
    // The baseURL is loaded from process.env.BASE_URL in playwright.config.ts
    // No need to explicitly specify it here if your tests use page.goto('/')
    await page.goto('/');
    console.log(`Navigated to: ${page.url()}`);
    // You can assert the URL or other environment-specific behaviors
    expect(page.url()).toContain(process.env.BASE_URL);
  });

  test('should use the correct API key for an operation', async ({ page }) => {
    // For demonstration, let's say a test needs to use the API_KEY
    // In a real scenario, you might have an API utility that reads this.
    const apiKey = process.env.API_KEY;
    console.log(`Using API Key: ${apiKey}`);
    expect(apiKey).toBeDefined();
    // Perform actions that use the API key (e.g., making an API call)
    // await page.goto(`/api/data?key=${apiKey}`);
    // expect(await page.textContent('body')).toContain('Data loaded successfully');
  });

  test('should log in with environment-specific credentials', async ({ page }) => {
    const userEmail = process.env.USER_EMAIL;
    const userPassword = process.env.USER_PASSWORD;

    await page.goto('/login');
    await page.fill('#email', userEmail!);
    await page.fill('#password', userPassword!);
    await page.click('#submit');
    await expect(page).toHaveURL(/dashboard/);
    console.log(`Logged in as: ${userEmail}`);
  });
});
```

To run tests for different environments:
```bash
# Run tests with local environment (default)
npx playwright test

# Run tests with staging environment
npx playwright test --project=chromium --env=staging

# Run tests with production environment (use with caution!)
npx playwright test --project=chromium --env=production
```

## Best Practices
- **Never commit `.env` files containing sensitive data to version control.** Add `.env*` to your `.gitignore` file.
- **Use separate `.env` files for each environment.** This makes it clear which configuration applies to which deployment target.
- **Define a clear fallback mechanism.** If an `--env` argument is not provided, default to a safe local development configuration.
- **Prefix environment variables.** Use prefixes like `PW_` or `APP_` to avoid conflicts with system environment variables.
- **Validate loaded variables.** In your Playwright config or utility functions, add checks to ensure critical environment variables are loaded, failing early if they are missing.
- **Prefer `process.env` for accessing variables.** `dotenv` automatically populates `process.env`.
- **Consider CI/CD integration.** In CI/CD pipelines, environment variables are often injected directly by the pipeline secrets manager rather than relying on `.env` files, especially for production.

## Common Pitfalls
- **Committing `.env` files:** Accidentally pushing `.env` files with sensitive data to public repositories. Always double-check `.gitignore`.
- **Forgetting to install `dotenv`:** Tests will fail because `process.env` variables won't be populated from `.env` files.
- **Incorrect path for `.env` files:** If `dotenv.config({ path: ... })` is not correctly pointing to your environment files, variables won't load.
- **Overwriting environment variables:** If you set a system environment variable, it will take precedence over variables in a `.env` file. Be aware of the order of precedence.
- **Not handling missing variables:** Accessing `process.env.UNDEFINED_VAR` will result in `undefined`, which can lead to runtime errors if not properly handled (e.g., with default values or checks).
- **Security risks for production:** Storing production secrets directly in `.env.production` that is present on the server is not ideal. Use secure secret management services (e.g., AWS Secrets Manager, Azure Key Vault, HashiCorp Vault) in production CI/CD.

## Interview Questions & Answers
1.  **Q: How do you handle environment-specific configurations in your Playwright tests? Why is this important?**
    A: I use `dotenv` to load configurations from `.env` files, typically separating them into `.env.local`, `.env.staging`, `.env.production`. I then modify `playwright.config.ts` to dynamically load the correct file based on a command-line argument (e.g., `--env=staging`). This is critical because it prevents hardcoding sensitive data, makes tests reusable across environments, improves security, and simplifies maintenance. It also allows developers to easily switch contexts without code changes.

2.  **Q: What are the security considerations when managing environment variables in a test automation framework?**
    A: The primary consideration is preventing sensitive data (API keys, credentials) from being exposed. This involves:
    *   **`.gitignore`**: Ensuring all `.env` files are in `.gitignore`.
    *   **CI/CD Secrets**: In CI/CD pipelines, injecting secrets directly as environment variables from a secure secrets manager rather than committing `.env` files.
    *   **Access Control**: Limiting who has access to modify environment files or inject secrets.
    *   **No logging of secrets**: Ensuring logs do not accidentally print sensitive environment variables.

3.  **Q: Describe a scenario where improper environment configuration led to a bug or issue in your testing. How did you resolve it?**
    A: (Example Answer) In a previous project, we accidentally hardcoded a staging API endpoint in a test suite. When the staging environment was updated, the tests started failing intermittently because the hardcoded URL became stale. The resolution involved refactoring the tests to use `dotenv` and externalize the base URL and API endpoints into environment-specific `.env` files, loaded dynamically via a `playwright.config.ts` modification. This ensured the tests always targeted the correct environment and eliminated the need for code changes when environment URLs changed.

## Hands-on Exercise
1.  Set up a new Playwright project or use an existing one.
2.  Install `dotenv`.
3.  Create an `env` directory and add `.env.qa` and `.env.dev` files.
4.  Define `BASE_URL`, `ADMIN_USER`, and `ADMIN_PASSWORD` in each `.env` file, with distinct values for 'dev' and 'qa'.
5.  Modify `playwright.config.ts` to load these files based on a `--env` command-line argument (defaulting to `dev` if none specified).
6.  Create a test (`login.spec.ts`) that attempts to log in using the `ADMIN_USER` and `ADMIN_PASSWORD` and navigates to the `BASE_URL`.
7.  Run your tests with `npx playwright test --env=dev` and `npx playwright test --env=qa` and verify that the tests correctly pick up the environment-specific credentials and base URLs.

## Additional Resources
-   **dotenv GitHub**: [https://github.com/motdotla/dotenv](https://github.com/motdotla/dotenv)
-   **Playwright Configuration**: [https://playwright.dev/docs/test-configuration](https://playwright.dev/docs/test-configuration)
-   **Playwright Command Line**: [https://playwright.dev/docs/test-cli](https://playwright.dev/docs/test-cli)
