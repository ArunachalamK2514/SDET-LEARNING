# Playwright CI/CD: Uploading Screenshots and Videos as CI Artifacts

## Overview
When running Playwright tests in a Continuous Integration (CI) environment, visual evidence like screenshots and videos are invaluable for debugging failing tests and understanding test execution flows. This feature focuses on configuring Playwright to automatically capture these media files and then ensuring they are uploaded as CI artifacts, making them easily accessible directly from your CI pipeline's build reports. This practice significantly speeds up troubleshooting and provides transparency into test outcomes.

## Detailed Explanation
Playwright has built-in capabilities to capture screenshots and videos automatically on test failures or for entire test runs. The key to making these useful in CI is to:
1.  **Configure Playwright**: Specify where these media files should be saved locally during test execution.
2.  **CI Configuration**: Instruct your CI system (e.g., GitHub Actions, GitLab CI, Azure DevOps, Jenkins) to recognize and upload these generated files as "artifacts."

### Playwright Configuration
Playwright allows you to configure video and screenshot capturing in your `playwright.config.ts` (or `.js`) file.

-   **Videos**:
    -   `video: 'on'`: Always record video for all tests.
    -   `video: 'on-first-retry'`: Record video only when a test is retried.
    -   `video: 'retain-on-failure'`: Record video and retain it only if the test fails.
    -   `video: 'off'`: Disable video recording.
    -   `outputDir`: Specifies the directory where videos and screenshots will be saved.

-   **Screenshots**:
    -   `screenshot: 'on'`: Always take a screenshot on test failure.
    -   `screenshot: 'only-on-failure'`: Take a screenshot only on test failure.
    -   `screenshot: 'off'`: Disable screenshot capturing.
    -   You can also manually take screenshots within your tests using `await page.screenshot({ path: 'path/to/screenshot.png' });`.

For CI, `video: 'retain-on-failure'` and `screenshot: 'only-on-failure'` are often the most practical as they minimize artifact storage while providing critical evidence.

### CI Artifact Upload
Most CI platforms provide a mechanism to upload build artifacts. These artifacts are files or directories generated during a build that you want to preserve for later analysis, downloading, or deployment.

**General Steps:**
1.  **Run Tests**: Execute your Playwright tests, ensuring they generate videos/screenshots to a designated directory (e.g., `test-results/`).
2.  **Identify Artifacts**: Point your CI configuration to the directory containing these media files.
3.  **Upload Command**: Use the CI platform's specific command or action to upload the identified files as artifacts.

## Code Implementation

### `playwright.config.ts` example
```typescript
import { defineConfig, devices } from '@playwright/test';
import path from 'path';

/**
 * Read environment variables from file.
 * https://github.com/motdotla/dotenv
 */
// require('dotenv').config();

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: './tests',
  // Output directory for test results, videos, and screenshots
  outputDir: './test-results', 
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

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
    
    // Configure video recording
    video: 'retain-on-failure', // Only keep video for failed tests
    
    // Configure screenshot capturing
    screenshot: 'only-on-failure', // Only take screenshot for failed tests
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

### `test-example.spec.ts` (Example Test)
```typescript
import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  await expect(page).toHaveTitle(/Playwright/);
});

test('get started link', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  await page.getByRole('link', { name: 'Get started' }).click();
  await expect(page.getByRole('heading', { name: 'Installation' })).toBeVisible();
});

test('failing test to demonstrate artifacts', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  // This expectation will intentionally fail to trigger screenshot/video capture
  await expect(page.getByRole('button', { name: 'NonExistentButton' })).toBeVisible();
});
```

### GitHub Actions Workflow (`.github/workflows/playwright.yml`)
```yaml
name: Playwright Tests

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  test:
    timeout-minutes: 60
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: 20
    - name: Install dependencies
      run: npm ci
    - name: Install Playwright browsers
      run: npx playwright install --with-deps
    - name: Run Playwright tests
      run: npx playwright test
    - name: Upload Playwright test results, videos, and screenshots
      uses: actions/upload-artifact@v4
      if: always() # Upload artifacts even if the previous step fails
      with:
        name: playwright-results-and-media
        path: test-results/ # This should match the outputDir in playwright.config.ts
        retention-days: 7 # Optional: Set retention policy for artifacts
```

## Best Practices
-   **Consistent `outputDir`**: Ensure your Playwright `outputDir` in `playwright.config.ts` matches the path used by your CI system's artifact upload step.
-   **`if: always()` for Artifact Upload**: In CI workflows (like GitHub Actions), always include `if: always()` in the artifact upload step. This ensures that media files are uploaded even if some tests fail, which is precisely when you need them most for debugging.
-   **Retention Policy**: Configure a retention policy for your artifacts in your CI system to manage storage and avoid excessive costs. Only keep artifacts for a reasonable period (e.g., 7-30 days).
-   **Selective Recording**: Use `video: 'retain-on-failure'` and `screenshot: 'only-on-failure'` to minimize the size of artifacts, especially for large test suites.
-   **Separate Job for Artifacts (Optional)**: For very large test suites, consider having a separate CI job specifically for collecting and uploading artifacts, allowing the main test job to finish faster.

## Common Pitfalls
-   **Incorrect Paths**: Mismatch between Playwright's `outputDir` and the CI's artifact path. Always double-check these configurations.
-   **Missing `if: always()`**: If not specified, artifact upload steps might be skipped if previous test steps fail, leaving you without crucial debugging information.
-   **Excessive Artifacts**: Recording videos and screenshots for every passing test can quickly consume storage and slow down CI builds. Optimize by only retaining artifacts on failure.
-   **Lack of Retention Policy**: Forgetting to set a retention policy can lead to a build-up of old artifacts, increasing storage costs and making it harder to find relevant information.

## Interview Questions & Answers
1.  **Q: Why is it important to upload screenshots and videos as CI artifacts in Playwright testing?**
    A: It's crucial for efficient debugging. Screenshots and videos provide visual evidence of test failures, showing the state of the UI at the point of failure. This helps pinpoint root causes much faster than relying solely on logs, especially for UI-related bugs or intermittent issues. It also offers transparency for stakeholders to see exactly what happened during a test run.

2.  **Q: How do you configure Playwright to capture videos and screenshots, and what are the best practices for CI?**
    A: In `playwright.config.ts`, you configure `video` (e.g., `retain-on-failure`) and `screenshot` (e.g., `only-on-failure`) options under the `use` object. The `outputDir` also needs to be set to define where these media files are saved. For CI, best practices include setting `video: 'retain-on-failure'` and `screenshot: 'only-on-failure'` to manage artifact size, using `if: always()` in the CI pipeline's upload step to ensure artifacts are collected even on failure, and defining an artifact retention policy to control storage.

3.  **Q: Describe a scenario where CI artifacts (screenshots/videos) saved you significant debugging time.**
    A: (Example Answer) "We had an intermittent test failure on a complex checkout flow that only occurred on CI. The test logs indicated a button wasn't found, but locally it always passed. By enabling video recording on failure and uploading it as a CI artifact, we could see a subtle timing issue: a modal dialog sometimes appeared briefly and covered the button, causing Playwright to fail before the element became interactable. Without the video, we would have spent hours trying to reproduce it locally."

## Hands-on Exercise
1.  **Setup a New Project**: Create a new Playwright project (`npm init playwright@latest`).
2.  **Configure Playwright**: Modify `playwright.config.ts` to set `outputDir: './my-artifacts'`, `video: 'retain-on-failure'`, and `screenshot: 'only-on-failure'`.
3.  **Create a Failing Test**: Write a simple Playwright test that is designed to fail (e.g., assert for an element that doesn't exist).
4.  **Run Tests Locally**: Execute `npx playwright test`. Verify that a video and screenshot are generated in the `my-artifacts` directory for the failing test.
5.  **Setup GitHub Actions**: Create a `.github/workflows/playwright.yml` file similar to the example above, ensuring the `actions/upload-artifact` step points to your `my-artifacts` directory and uses `retention-days`.
6.  **Push to GitHub**: Commit your changes and push them to a GitHub repository.
7.  **Verify Artifacts**: Check the GitHub Actions run for your push. After the workflow completes (even if it fails), look for the "Artifacts" section to download the `playwright-results-and-media` archive and verify that the video and screenshot of your failing test are included.

## Additional Resources
-   **Playwright Test Configuration**: [https://playwright.dev/docs/test-configuration#videos](https://playwright.dev/docs/test-configuration#videos)
-   **GitHub Actions Artifacts**: [https://docs.github.com/en/actions/managing-workflow-runs/storing-workflow-data-as-artifacts](https://docs.github.com/en/actions/managing-workflow-runs/storing-workflow-data-as-artifacts)
-   **GitLab CI/CD Job artifacts**: [https://docs.gitlab.com/ee/ci/pipelines/job_artifacts.html](https://docs.gitlab.com/ee/ci/pipelines/job_artifacts.html)
-   **Azure DevOps Publish Build Artifacts task**: [https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/utility/publish-build-artifacts](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/utility/publish-build-artifacts)