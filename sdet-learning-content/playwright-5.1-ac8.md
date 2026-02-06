# Playwright Project Setup & Configuration

## Overview
Proper configuration of your Playwright project is crucial for efficient test development, stable execution, and effective debugging. This section covers essential configuration options such as `baseURL`, `timeout`, `retries`, `screenshot`, `video` recording, and `trace` viewer settings. Understanding and utilizing these configurations will streamline your test automation efforts and provide valuable insights into test failures.

## Detailed Explanation

Playwright configurations are typically managed in `playwright.config.ts` (or `.js`) at the root of your project. This file exports a configuration object that Playwright uses to run your tests.

### `baseURL`
The `baseURL` is a fundamental setting that allows you to specify the base URL for your application under test. Instead of hardcoding the full URL in every `page.goto()` call, you can use relative paths. This makes your tests more portable and easier to manage across different environments (e.g., development, staging, production).

**Example:**
If `baseURL` is `http://localhost:3000`, then `await page.goto('/users')` navigates to `http://localhost:3000/users`.

### `timeout`
This setting controls the maximum time (in milliseconds) a test, hook, or assertion can take before Playwright considers it failed. There are different levels of timeout:
- **Test timeout**: Configured globally for all tests.
- **Action timeout**: For actions like `click()`, `fill()`, `waitForSelector()`.
- **Navigation timeout**: For `page.goto()`, `page.waitForNavigation()`.

Setting an appropriate timeout prevents tests from hanging indefinitely, but too short a timeout can lead to flaky tests, especially in slower environments or during network latency.

### `retries`
Flaky tests are a common challenge in test automation. Playwright's `retries` option allows tests to be re-run a specified number of times upon failure. This can help identify genuinely failing tests versus those that fail due to transient issues (e.g., network glitches, temporary UI rendering problems). It's a useful mechanism for improving CI stability, but it should not be a substitute for fixing the root cause of flakiness.

### `screenshot`
Capturing screenshots on test failure is invaluable for debugging. Playwright offers several options:
- `'off'`: Never take screenshots.
- `'on'`: Always take screenshots at the end of each test.
- `'only-on-failure'`: Takes a screenshot only if a test fails. This is often the most practical choice.
- `'retain-on-failure'`: Takes a screenshot only if a test fails, and keeps the previous successful screenshot if available.

Screenshots are typically saved in the `test-results` directory.

### `video` Recording
Video recordings provide a chronological visual trace of test execution, which can be even more helpful than screenshots for understanding complex failures or unexpected UI behavior.
- `'off'`: Do not record videos.
- `'on'`: Record video for all tests.
- `'retain-on-failure'`: Records video for all tests, but only saves them if the test fails. This helps save disk space.
- `'on-first-retry'`: Records video for the first retry of a test.

Like screenshots, videos are usually saved in the `test-results` directory.

### `trace` Viewer
The Playwright Trace Viewer is a powerful tool for analyzing test execution. It captures a comprehensive log of Playwright operations, network requests, DOM snapshots, and screenshots for each action.
- `'off'`: Do not collect traces.
- `'on'`: Collect trace for all tests.
- `'only-on-failure'`: Collect trace only if a test fails. This is highly recommended for debugging.
- `'retain-on-failure'`: Collect trace for all tests, but only saves them if the test fails.
- `'on-first-retry'`: Collect trace for the first retry of a test.

The trace file (`.zip`) can be opened in the Playwright Trace Viewer by running `npx playwright show-report`.

## Code Implementation

Below is an example `playwright.config.ts` file demonstrating these configurations.

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';
import path from 'path';

/**
 * Read environment variables from .env file.
 * Not required but recommended for sensitive information like API keys or different base URLs.
 */
// require('dotenv').config();

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  // Path to the test files. Look for files with .spec.ts or .test.ts suffix.
  testDir: './tests',
  // Output directory for test results, screenshots, videos, and traces.
  outputDir: './test-results',
  // Global timeout for all tests. Max time in milliseconds a test can run.
  timeout: 30 * 1000, // 30 seconds
  // How many times to retry a failed test. Useful for reducing flakiness in CI.
  retries: process.env.CI ? 2 : 0, // 2 retries on CI, 0 locally
  // Limit the number of workers on CI to save resources.
  workers: process.env.CI ? 1 : undefined,

  // Global setup and teardown for the test run.
  // globalSetup: require.resolve('./global-setup'),
  // globalTeardown: require.resolve('./global-teardown'),

  // Reporter to use. See https://playwright.dev/docs/test-reporters
  reporter: 'html', // Other options: 'list', 'json', 'junit', 'dot'

  // Shared settings for all projects.
  use: {
    // Base URL to use in actions like `await page.goto('/')`.
    // This makes tests more robust across different environments.
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:8080',

    // Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer
    // 'off', 'on', 'only-on-failure', 'retain-on-failure', 'on-first-retry'
    trace: 'only-on-failure',

    // Screenshot capture on test failure.
    // 'off', 'on', 'only-on-failure'
    screenshot: 'only-on-failure',

    // Video recording settings.
    // 'off', 'on', 'retain-on-failure', 'on-first-retry'
    video: 'retain-on-failure',

    // Headless browser mode. Set to false to see the browser UI during tests.
    // Useful for debugging locally.
    headless: process.env.CI ? true : false,

    // Browser context options
    viewport: { width: 1280, height: 720 }, // Default viewport size

    // Accept downloads
    acceptDownloads: true,
  },

  // Configure projects for different browsers, devices, or environments.
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

  // Folder for test artifacts such as screenshots, videos, and traces.
  // This is set to outputDir by default, but can be overridden.
  // use: {
  //   testIdAttribute: 'data-test-id', // Custom test ID attribute
  // }
});
```

## Best Practices
- **Use `baseURL`**: Always define `baseURL` to make your tests environment-agnostic and more maintainable.
- **Conditional Retries**: Apply `retries` conditionally (e.g., only in CI environments) to avoid masking issues during local development.
- **`only-on-failure` for Artifacts**: Configure `screenshot`, `video`, and `trace` to `'only-on-failure'` or `'retain-on-failure'` to save disk space and focus on relevant debug information.
- **Environment Variables**: Utilize environment variables (e.g., `process.env.PLAYWRIGHT_BASE_URL`) for sensitive data or environment-specific configurations.
- **Modular Configuration**: For complex projects, consider breaking down configuration into multiple files or using a more sophisticated environment management strategy.

## Common Pitfalls
- **Over-reliance on Retries**: Using `retries` extensively without addressing the root cause of flakiness can hide legitimate bugs and lead to unstable test suites.
- **Short Timeouts**: Setting timeouts too aggressively can cause tests to fail prematurely on slower machines or networks, leading to false positives.
- **Not Cleaning Artifacts**: If not configured to retain-on-failure, accumulated screenshots, videos, and traces can consume significant disk space over time, especially in CI environments.
- **Hardcoding URLs**: Directly embedding full URLs in tests defeats the purpose of `baseURL` and makes switching environments cumbersome.

## Interview Questions & Answers
1.  **Q: Why is `baseURL` important in Playwright configuration?**
    A: `baseURL` is important because it allows you to define a base URL for your application. This makes your tests environment-agnostic, enabling them to run against different environments (dev, staging, prod) without code changes. It also simplifies `page.goto()` calls by allowing the use of relative paths, improving test readability and maintainability.

2.  **Q: How do you handle flaky tests in Playwright, and what are the pros and cons of using the `retries` option?**
    A: Flaky tests can be handled by investigating and fixing their root causes (e.g., race conditions, improper waits). Playwright's `retries` option can be used to re-run failed tests a specified number of times.
    *   **Pros**: Improves CI stability by passing tests that fail due to transient issues, helps differentiate between genuine failures and environmental flakiness.
    *   **Cons**: Masks underlying issues if the root cause of flakiness isn't addressed, can increase test execution time, and might give a false sense of security regarding test reliability. It should be a temporary measure while investigating flakiness.

3.  **Q: Describe the debugging benefits of `screenshot`, `video`, and `trace` options in Playwright. Which settings do you recommend for a CI/CD pipeline?**
    A:
    *   **Screenshots**: Provide a visual snapshot of the UI at the point of failure, helping to identify incorrect element states or rendering issues.
    *   **Video**: Offer a full chronological recording of the test execution, invaluable for understanding dynamic UI changes, animations, or sequences of events leading to a failure.
    *   **Trace Viewer**: The most comprehensive debugging tool, providing a detailed log of every Playwright operation, network requests, DOM snapshots, and step-by-step screenshots.
    For a CI/CD pipeline, I recommend:
    *   `screenshot: 'only-on-failure'`
    *   `video: 'retain-on-failure'`
    *   `trace: 'only-on-failure'`
    These settings ensure that artifacts are generated only when a test fails, conserving disk space and focusing on necessary debug information.

## Hands-on Exercise
1.  **Objective**: Configure a Playwright project to run against a local web server with specific settings.
2.  **Steps**:
    *   Create a new Playwright project (`npm init playwright@latest`).
    *   Modify `playwright.config.ts`:
        *   Set `baseURL` to `http://localhost:3000`.
        *   Set `timeout` to `60000` milliseconds (1 minute).
        *   Configure `retries` to `1`.
        *   Set `screenshot` to `'only-on-failure'`.
        *   Set `video` to `'retain-on-failure'`.
        *   Set `trace` to `'only-on-failure'`.
    *   Create a simple `index.html` file in a new `public` directory:
        ```html
        <!-- public/index.html -->
        <!DOCTYPE html>
        <html>
        <head>
          <title>Playwright Test Page</title>
        </head>
        <body>
          <h1>Welcome!</h1>
          <button id="myButton">Click Me</button>
          <p id="message" style="display:none;">Button clicked!</p>
          <script>
            document.getElementById('myButton').addEventListener('click', () => {
              document.getElementById('message').style.display = 'block';
            });
          </script>
        </body>
        </html>
        ```
    *   Install a simple HTTP server (e.g., `npm install http-server`).
    *   Start the server in the `public` directory: `npx http-server public -p 3000`.
    *   Create a test file `tests/example.spec.ts` that navigates to `/`, clicks the button, and asserts the message appears. Intentionally introduce a delay or a flaky assertion to see the retry, screenshot, video, and trace in action.
    *   Run your tests and observe the generated artifacts in `test-results` upon failure.

## Additional Resources
-   **Playwright Test Configuration**: [https://playwright.dev/docs/test-configuration](https://playwright.dev/docs/test-configuration)
-   **Playwright Trace Viewer**: [https://playwright.dev/docs/trace-viewer](https://playwright.dev/docs/trace-viewer)
-   **Playwright Video Recording**: [https://playwright.dev/docs/videos](https://playwright.dev/docs/videos)
-   **Playwright Screenshots**: [https://playwright.dev/docs/screenshots](https://playwright.dev/docs/screenshots)
