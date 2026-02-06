# Playwright CI/CD: Configure Retries on Failure

## Overview
In continuous integration and continuous delivery (CI/CD) pipelines, automated tests are a critical gatekeeper for code quality. However, end-to-end (E2E) tests, especially those interacting with browsers, can sometimes be "flaky." A flaky test is one that occasionally fails without any code changes, often due to timing issues, environment inconsistencies, or asynchronous operations. To prevent these intermittent failures from blocking deployments and to provide a more stable feedback loop, Playwright offers a robust `retries` configuration. This feature allows tests to be re-executed automatically upon failure, specifically when running in CI environments, thereby reducing false negatives while still highlighting genuine issues.

## Detailed Explanation

### Understanding Test Flakiness
Test flakiness is a common challenge in E2E testing. It can stem from:
-   **Timing issues:** Elements might not load fast enough, or animations might delay interactions.
-   **Environment instability:** Network latency, database state, or external service dependencies.
-   **Asynchronous operations:** Tests not properly awaiting all background processes.
-   **Test isolation problems:** One test impacting the state of another.

While retries don't fix the underlying flakiness, they help to filter out transient failures, allowing the CI pipeline to proceed for what are likely good code changes, while still providing data to investigate the root causes of flakiness.

### Playwright `retries` Configuration
Playwright's `retries` option in `playwright.config.ts` specifies how many times Playwright should re-run a failed test before marking it as a definitive failure.

**Key considerations:**

1.  **Setting `retries`:** The `retries` value is a number representing the count of additional attempts after the initial failure. So, `retries: 2` means a test will run a maximum of 3 times (1 initial run + 2 retries).
2.  **Conditional Retries for CI:** It's a common best practice to set `retries` to `0` for local development (to immediately catch issues and encourage developers to write stable tests) and a higher number (e.g., `2` or `3`) for CI/CD environments. This differentiation is usually achieved by checking an environment variable, suchs as `process.env.CI`.

    ```typescript
    // playwright.config.ts
    import { defineConfig, devices } from '@playwright/test';

    export default defineConfig({
      testDir: './tests',
      // Run tests in files in parallel
      fullyParallel: true,
      // Fail the build on CI if you accidentally left test.only in the source code.
      forbidOnly: !!process.env.CI,
      // Retry on CI only
      retries: process.env.CI ? 2 : 0, // 2 retries means up to 3 attempts
      // Opt out of parallel tests on CI.
      workers: process.env.CI ? 1 : undefined, // Example: fewer workers on CI for stability
      // Reporter to use. See https://playwright.dev/docs/test-reporters
      reporter: 'html',
      use: {
        // Base URL to use in actions like `await page.goto('/')`.
        baseURL: 'http://localhost:3000',
        // Collect trace when retrying the failed test.
        trace: 'on-first-retry',
        // Capture screenshot on first retry failure.
        screenshot: 'on-first-retry',
        // Record video on first retry failure.
        video: 'on-first-retry',
      },
      // Configure projects for major browsers
      projects: [
        {
          name: 'chromium',
          use: { ...devices['Desktop Chrome'] },
        },
        // ... other projects like firefox, webkit
      ],
    });
    ```
    To run this in CI, you would typically set the `CI` environment variable:
    ```bash
    CI=true npx playwright test
    ```
    Or in a GitHub Actions workflow:
    ```yaml
    - name: Run Playwright tests
      run: npx playwright test
      env:
        CI: true
    ```

### `repeatEach` vs. `retries`
It's important to distinguish `retries` from `repeatEach`.
-   `retries`: Reruns a *failed* test suite or spec *immediately* after its initial failure, up to the configured number of times. It's for handling flakiness.
-   `repeatEach`: Runs *each test* in a file multiple times *regardless of its success or failure*. This is useful for stress testing, identifying memory leaks, or ensuring test isolation by running tests repeatedly in different orders or conditions.

### Analyzing Flaky Tests Revealed by Retries
While retries provide immediate relief, they are not a long-term solution to flakiness. They buy time to investigate. Playwright offers features to help diagnose flaky tests:
-   **`trace: 'on-first-retry'`**: Captures a Playwright trace for a test when it fails for the first time, which is invaluable for debugging.
-   **`screenshot: 'on-first-retry'`**: Takes a screenshot on the first failure.
-   **`video: 'on-first-retry'`**: Records a video on the first failure.
-   **Detailed CI logs:** Examine the console output from your CI runner.
-   **Playwright UI Mode (`npx playwright test --ui`):** Locally, this allows you to step through failing tests, view traces, and understand the execution flow.

The goal is always to make tests deterministic. If a test passes on retry, it's a strong indicator of flakiness that needs investigation.

## Code Implementation

Below is a `playwright.config.ts` example demonstrating how to configure retries conditionally for a CI environment, along with other best practices for CI.

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';
import path from 'path';

/**
 * Read environment variables from .env file.
 * Not recommended for CI (use CI secrets) but useful for local development.
 */
// require('dotenv').config();

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  // Directory where tests are located.
  testDir: './tests',
  // Output directory for test results, reports, and traces.
  outputDir: './test-results',

  // Run tests in files in parallel.
  fullyParallel: true,
  // Fail the build on CI if you accidentally left test.only in the source code.
  forbidOnly: !!process.env.CI,
  // Retry on CI only. 0 retries for local development to catch issues fast.
  retries: process.env.CI ? 2 : 0, // This means up to 3 attempts in CI (initial + 2 retries)
  // Opt out of parallel tests on CI if needed for stability (e.g., resource constraints).
  // Otherwise, use undefined to let Playwright determine optimal workers.
  workers: process.env.CI ? 1 : undefined,

  // Reporter to use. See https://playwright.dev/docs/test-reporters
  // 'html' reporter is great for local analysis and can be published in CI.
  // 'github' reporter is useful for GitHub Actions to annotate pull requests.
  reporter: process.env.CI ? [['github'], ['html', { open: 'never' }]] : 'html',

  // Shared settings for all projects.
  use: {
    // Base URL to use in actions like `await page.goto('/')`.
    // Ensure this is configurable for different environments (local, staging, prod).
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000',

    // Capture trace, screenshot, and video on first retry failure.
    // This is crucial for debugging flaky tests in CI.
    trace: 'on-first-retry',
    screenshot: 'on-first-retry',
    video: 'on-first-retry',

    // Headless mode is typically true in CI.
    headless: true, // `true` for CI environments, `false` for local debugging
  },

  // Configure projects for major browsers.
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
    // Example of a project for mobile emulation (if needed)
    // {
    //   name: 'Mobile Chrome',
    //   use: { ...devices['Pixel 5'] },
    // },
  ],

  // Global setup/teardown configuration (e.g., starting a web server).
  // This runs once before all tests and once after all tests.
  globalSetup: require.resolve('./global-setup'), // Assumes you have a global-setup.ts
  globalTeardown: require.resolve('./global-teardown'), // Assumes you have a global-teardown.ts
});
```

**Explanation of `global-setup.ts` (Example - for starting a local web server):**

```typescript
// global-setup.ts
import { FullConfig } from '@playwright/test';
import { spawn } from 'child_process';

// Function to start your application or any required services.
// This runs once before all tests.
async function globalSetup(config: FullConfig) {
  // Example: Start a local development server
  // This assumes your project has a 'start' script in package.json
  if (!process.env.PLAYWRIGHT_BASE_URL) {
    console.log('Starting local web server for Playwright tests...');
    // Replace with your actual application start command
    const appProcess = spawn('npm', ['start'], {
      stdio: 'inherit',
      shell: true,
      detached: true // Detach to allow Playwright to continue
    });
    // Store the PID to kill it in globalTeardown
    process.env.APP_PID = appProcess.pid?.toString();

    // Wait for the server to be ready. You might need a more sophisticated check
    // like polling an endpoint. For simplicity, we'll just wait a bit.
    await new Promise(resolve => setTimeout(resolve, 5000));
  }
}

export default globalSetup;
```

**Explanation of `global-teardown.ts` (Example - for stopping a local web server):**

```typescript
// global-teardown.ts
import { FullConfig } from '@playwright/test';
import { execSync } from 'child_process';

// Function to stop your application or any required services.
// This runs once after all tests.
async function globalTeardown(config: FullConfig) {
  if (process.env.APP_PID) {
    console.log(`Stopping local web server with PID: ${process.env.APP_PID}`);
    // On Windows, use taskkill. On Unix-like systems, use kill.
    // Note: This is a basic example. For robust solutions, consider 'tree-kill' package.
    try {
      if (process.platform === 'win32') {
        execSync(`taskkill /pid ${process.env.APP_PID} /f /t`);
      } else {
        process.kill(-parseInt(process.env.APP_PID)); // Kill process group
      }
      console.log('Local web server stopped.');
    } catch (error) {
      console.warn(`Could not stop process with PID ${process.env.APP_PID}:`, error);
    }
  }
}

export default globalTeardown;
```

## Best Practices
-   **Strategic Retry Count:** Set a reasonable number of retries (e.g., 2-3). Too many retries can significantly slow down your CI pipeline without effectively identifying the root cause of flakiness.
-   **Immediate Flakiness Investigation:** Don't treat retries as a permanent fix. Every time a test passes on retry, it's an opportunity to improve test stability. Prioritize fixing truly flaky tests.
-   **Leverage Diagnostic Tools:** Always configure Playwright to capture traces, screenshots, and videos (`trace: 'on-first-retry'`, `screenshot: 'on-first-retry'`, `video: 'on-first-retry'`) when tests fail and are retried. These artifacts are invaluable for post-mortem analysis.
-   **Isolate Tests:** Ensure tests are independent and don't rely on the state left by previous tests. Use `beforeEach` and `afterEach` hooks effectively to set up and tear down test environments.
-   **Use `forbidOnly` in CI:** This configuration prevents developers from accidentally committing `test.only`, which can lead to incomplete test runs in CI.
-   **Robust Waits:** Avoid arbitrary `page.waitForTimeout()` calls. Instead, use Playwright's smart auto-waiting mechanisms or explicit waits like `page.waitForSelector()`, `page.waitForURL()`, `page.waitForLoadState('networkidle')`.

## Common Pitfalls
-   **Over-reliance on Retries:** Using retries to sweep flakiness under the rug instead of addressing the underlying issues. This leads to longer CI times and a false sense of security.
-   **Inconsistent Retry Policy:** Not having a clear distinction between local and CI retry configurations, leading to different test behaviors in different environments.
-   **Lack of Debugging Artifacts:** Running retries without capturing sufficient diagnostic information (traces, screenshots, videos) makes it nearly impossible to debug why a test was flaky.
-   **Ignoring Flaky Test Reports:** Failing to act on the information provided by CI systems when tests pass on retry. These tests should be prioritized for stabilization.
-   **Too Many Workers on CI:** While `workers` can speed up tests, setting too many workers on CI with limited resources can sometimes *increase* flakiness due to resource contention. Experiment to find an optimal balance.

## Interview Questions & Answers

1.  **Q: Why are test retries important in CI/CD, especially for end-to-end tests?**
    **A:** Test retries are crucial for E2E tests in CI/CD because these tests are often susceptible to flakiness due to external factors like network latency, environment inconsistencies, or asynchronous operations. Retries help prevent transient, non-reproducible failures from unnecessarily blocking the CI/CD pipeline, providing a more reliable feedback loop. They distinguish between genuine regressions and intermittent issues, allowing teams to focus on real bugs while still collecting data to investigate and fix the root causes of flakiness.

2.  **Q: How do you configure retries in Playwright, and how would you handle different retry policies for local development versus CI environments?**
    **A:** In Playwright, retries are configured using the `retries` option in `playwright.config.ts`. You set `retries: N`, where `N` is the number of additional attempts after the first failure.
    For different policies, I'd use an environment variable like `process.env.CI`. For example:
    ```typescript
    retries: process.env.CI ? 2 : 0,
    ```
    This sets `0` retries (only one attempt) for local development to ensure developers address issues immediately, and `2` retries (up to three attempts) for CI to mitigate flakiness. This balance provides quick feedback locally and stability in the pipeline.

3.  **Q: Retries can mask flaky tests. How would you identify and address the root cause of flakiness, rather than just relying on retries?**
    **A:** While retries are a valuable mitigation, it's critical to treat tests that pass on retry as "flaky" and investigate their root cause. My approach would involve:
    *   **Leveraging Playwright's Diagnostic Tools:** Configure `trace: 'on-first-retry'`, `screenshot: 'on-first-retry'`, and `video: 'on-first-retry'` to capture artifacts on the initial failure. These are invaluable for understanding the state of the application and browser at the point of failure.
    *   **Detailed CI Logs:** Thoroughly examine CI logs for any anomalies or error messages that occurred during the flaky run.
    *   **Local Reproduction:** Attempt to reproduce the flakiness locally by running the test repeatedly using `npx playwright test --retries=0 --repeat-each=10` or by using Playwright's UI mode to step through the test.
    *   **Code Review & Test Improvement:** Analyze the test code for inadequate waits (e.g., `waitForTimeout` instead of explicit waits), race conditions, or insufficient test isolation. Ensure proper use of `beforeEach` and `afterEach`.
    *   **Environment Analysis:** Investigate potential external factors like database state, network issues, or third-party service dependencies that might contribute to inconsistent test outcomes.
    *   **Reporting & Prioritization:** Log flaky tests as technical debt and prioritize their stabilization. Continuous monitoring of flaky test rates is essential.

## Hands-on Exercise

**Objective:** Create a simple flaky test and configure Playwright to retry it only when running in a simulated CI environment.

**Steps:**

1.  **Set up a Playwright Project (if you don't have one):**
    ```bash
    mkdir playwright-retry-example
    cd playwright-retry-example
    npm init playwright@latest .
    # Choose TypeScript, add a browser, and accept defaults.
    ```

2.  **Create a Flaky Test:**
    Replace the content of `tests/example.spec.ts` (or create a new file like `tests/flaky.spec.ts`) with the following:

    ```typescript
    // tests/flaky.spec.ts
    import { test, expect } from '@playwright/test';

    test('flaky test that sometimes passes', async ({ page }) => {
      await page.goto('https://www.google.com'); // Navigate to a stable page first

      // Simulate a flaky condition:
      // This test will fail ~50% of the time based on Math.random()
      const shouldFail = Math.random() < 0.5;

      if (shouldFail) {
        console.log('--- Simulating failure ---');
        // Try to assert an element that doesn't exist to force a failure
        await expect(page.locator('#nonExistentElement')).toBeVisible({ timeout: 1000 });
      } else {
        console.log('--- Simulating success ---');
        // Assert something that always passes
        await expect(page.locator('img[alt="Google"]')).toBeVisible();
      }
    });
    ```
    *Note: For a more realistic flaky test, you might interact with a local server that occasionally responds slowly or with errors.*

3.  **Configure `playwright.config.ts` for CI Retries:**
    Modify your `playwright.config.ts` to include the conditional `retries` logic as shown in the Detailed Explanation section:

    ```typescript
    // playwright.config.ts
    import { defineConfig, devices } from '@playwright/test';

    export default defineConfig({
      testDir: './tests',
      fullyParallel: true,
      forbidOnly: !!process.env.CI,
      retries: process.env.CI ? 2 : 0, // 2 retries for CI, 0 for local
      reporter: 'html',
      use: {
        baseURL: 'https://www.google.com', // Use a stable public URL
        trace: 'on-first-retry',
        screenshot: 'on-first-retry',
        video: 'on-first-retry',
      },
      projects: [
        {
          name: 'chromium',
          use: { ...devices['Desktop Chrome'] },
        },
      ],
    });
    ```

4.  **Run Locally (without CI env var):**
    ```bash
    npx playwright test tests/flaky.spec.ts
    ```
    You should see it fail immediately if `shouldFail` is true. It will not retry.

5.  **Simulate CI Run (with CI env var):**
    ```bash
    CI=true npx playwright test tests/flaky.spec.ts
    ```
    Run this command multiple times.
    -   If the test fails initially, you should observe Playwright retrying it up to 2 additional times.
    -   If a retry passes, Playwright will mark the test as passed.
    -   If all retries fail, the test will be marked as failed.
    -   Check the output for messages like `(retry #1)` to confirm retries are happening.

6.  **Analyze Reports:**
    Open the generated HTML report (`npx playwright show-report`) to see the results, including traces, screenshots, and videos captured on retry failures.

## Additional Resources
-   **Playwright Test Configuration:** [https://playwright.dev/docs/test-configuration](https://playwright.dev/docs/test-configuration)
-   **Playwright Retries Documentation:** [https://playwright.dev/docs/test-retries](https://playwright.dev/docs/test-retries)
-   **Debugging Playwright Tests:** [https://playwright.dev/docs/debug](https://playwright.dev/docs/debug)
-   **Blog Post: Dealing with Flaky Tests in Playwright:** [https://www.checklyhq.com/learn/headless/playwright-flaky-tests/](https://www.checklyhq.com/learn/headless/playwright-flaky-tests/)
