# Configure `playwright.config.ts` File

## Overview
The `playwright.config.ts` file is the central configuration hub for Playwright projects. It allows you to define various settings that control how your tests run, including browser environments, timeouts, parallel execution, retries, and reporting. Understanding and properly configuring this file is crucial for efficient, reliable, and scalable test automation.

## Detailed Explanation

The `playwright.config.ts` file exports a configuration object. This object contains properties to customize Playwright's behavior.

### Key Configuration Options:

1.  **`testDir` - Set Test Directory Location:**
    This property specifies the directory where your Playwright tests are located. By default, Playwright looks for tests in the `test` directory or `tests` directory relative to the config file.

    ```typescript
    // playwright.config.ts
    import { defineConfig } from '@playwright/test';

    export default defineConfig({
      testDir: './tests', // Specifies that tests are in the 'tests' folder
    });
    ```
    Or, if your tests are in the root of your project:
    ```typescript
    testDir: './',
    ```

2.  **`fullyParallel` - Configure Parallel Execution Settings:**
    This boolean flag determines whether tests should run in parallel. When set to `true`, Playwright will execute tests in multiple worker processes, significantly speeding up test execution, especially for large test suites.

    ```typescript
    // playwright.config.ts
    import { defineConfig } from '@playwright/test';

    export default defineConfig({
      fullyParallel: true, // Run tests in parallel workers
      // ... other configurations
    });
    ```
    You can also control the number of workers using `workers`. By default, it uses 1/2 of the number of CPU cores.
    ```typescript
    workers: process.env.CI ? 1 : undefined, // On CI, run 1 worker; locally, use default
    ```

3.  **`retries` - Set Number of Retries:**
    This property defines how many times Playwright should retry a failed test. Retries are useful for handling flaky tests caused by transient issues (e.g., network delays, unstable UI elements).

    ```typescript
    // playwright.config.ts
    import { defineConfig } from '@playwright/test';

    export default defineConfig({
      retries: 2, // Retry failed tests up to 2 times
      // ... other configurations
    });
    ```
    It's important not to over-rely on retries, as they can mask underlying stability issues.

4.  **`timeout` - Configure Global Timeout Settings:**
    This sets the maximum time (in milliseconds) a test is allowed to run. If a test exceeds this timeout, Playwright will terminate it and mark it as failed. This prevents tests from hanging indefinitely.

    ```typescript
    // playwright.config.ts
    import { defineConfig } from '@playwright/test';

    export default defineConfig({
      timeout: 30 * 1000, // Global test timeout of 30 seconds
      // ... other configurations
    });
    ```
    You can also set timeouts for individual actions (e.g., `page.click({ timeout: 5000 })`) or for `expect` assertions (`expect(...).toPass({ timeout: 10000 })`).

### Example `playwright.config.ts` File:

```typescript
// @ts-check
import { defineConfig, devices } from '@playwright/test';

/**
 * Read environment variables from .env file.
 * Not recommended for production, but useful for local development.
 * import dotenv from 'dotenv';
 * dotenv.config({ path: '.env' });
 */

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: './tests', // Specifies the directory where test files are located
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0, // Retry failed tests 2 times on CI, no retries locally
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: 'html', // Generates an HTML report after test execution
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    // baseURL: 'http://127.0.0.1:3000',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry', // Record a trace for the first retry of a failed test
  },
  timeout: 60 * 1000, // Global timeout for each test to run (60 seconds)

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

## Best Practices
- **Environment-Specific Configuration**: Use environment variables (`process.env.CI`) to adjust settings (like `retries` or `workers`) for CI/CD pipelines versus local development.
- **Sensible Timeouts**: Set timeouts judiciously. Too short, and tests become flaky; too long, and tests waste valuable execution time.
- **Parallelism for Speed**: Leverage `fullyParallel: true` and `workers` to maximize test execution speed, especially in CI environments.
- **Avoid Over-Retrying**: While retries help with flakiness, they shouldn't replace fixing the root cause of unstable tests. Use them as a last resort for genuinely transient issues.
- **Modular Configuration**: For very large projects, consider importing parts of the configuration from other files to keep `playwright.config.ts` clean and readable.

## Common Pitfalls
- **Ignoring `testDir`**: Not explicitly setting `testDir` can lead to Playwright not finding your tests, or finding unintended files if your project structure is complex.
- **Excessive Timeouts**: Setting a very high global `timeout` can hide performance issues in your application or lead to long-running, blocked CI jobs.
- **Over-reliance on Retries**: Using many retries (e.g., `retries: 5`) can mask fundamental issues in your tests or application, leading to a false sense of security regarding test stability.
- **No Parallel Execution**: Running tests serially when they could be run in parallel wastes time and resources, especially in CI.
- **Hardcoded URLs/Credentials**: Avoid hardcoding sensitive information or environment-specific URLs directly in `playwright.config.ts`. Use `.env` files or CI secrets management.

## Interview Questions & Answers
1.  **Q: Explain the purpose of `playwright.config.ts` and some key configurations you'd typically set.**
    **A:** The `playwright.config.ts` file is the central configuration file for Playwright test runner. It allows defining how tests are executed. Key configurations include `testDir` (where tests are located), `fullyParallel` (for parallel execution), `retries` (for re-running failed tests), `timeout` (global test timeout), and `projects` (to run tests across different browsers/devices).

2.  **Q: How do you handle flaky tests in Playwright, specifically using `playwright.config.ts`? What are the pros and cons of this approach?**
    **A:** Flaky tests can be handled using the `retries` option in `playwright.config.ts`. By setting `retries: N`, Playwright will re-run a failed test `N` times.
    **Pros:** Improves test stability in CI by mitigating transient failures, allows for faster feedback cycles by passing tests that fail due to non-deterministic issues.
    **Cons:** Can mask underlying issues in the test or application, increases overall test execution time if many tests are flaky, and can lead to a false sense of test suite health. It should be used judiciously and in conjunction with efforts to identify and fix the root causes of flakiness.

3.  **Q: You have a large suite of Playwright tests, and they are taking too long to run. What configuration changes in `playwright.config.ts` would you consider to speed them up?**
    **A:** To speed up a large test suite, I would enable parallel execution by setting `fullyParallel: true`. I would also consider adjusting the `workers` option to leverage more CPU cores if available, or setting it dynamically based on the CI environment. Additionally, optimizing `timeout` values to be as short as possible without causing flakiness can help prevent tests from hanging.

## Hands-on Exercise
1.  **Objective**: Configure a new Playwright project to run tests in parallel, retry failed tests, and set a custom global timeout.
2.  **Steps**:
    *   Initialize a new Playwright project: `npm init playwright@latest` (choose TypeScript, `tests` folder for tests).
    *   Open `playwright.config.ts`.
    *   Set `testDir` to `./playwright-tests` (you'll need to create this folder and move `example.spec.ts` into it).
    *   Change `fullyParallel` to `true`.
    *   Set `retries` to `1`.
    *   Set `timeout` to `45 * 1000` (45 seconds).
    *   Modify `example.spec.ts` to intentionally fail once (e.g., assert for an element that doesn't exist) and then pass on retry to observe the retry mechanism.
    *   Run tests: `npx playwright test`. Observe the parallel execution and retry in the console output or HTML report.

## Additional Resources
-   **Playwright Test Configuration**: [https://playwright.dev/docs/test-configuration](https://playwright.dev/docs/test-configuration)
-   **Playwright Test Options**: [https://playwright.dev/docs/api/class-testoptions](https://playwright.dev/docs/api/class-testoptions)
-   **Playwright CLI**: [https://playwright.dev/docs/test-cli](https://playwright.dev/docs/test-cli)
