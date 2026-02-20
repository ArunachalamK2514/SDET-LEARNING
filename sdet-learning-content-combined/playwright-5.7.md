# playwright-5.7-ac1.md

# Playwright CI/CD Integration: Configuring for CI Environments

## Overview
Integrating Playwright tests into Continuous Integration (CI) and Continuous Delivery (CD) pipelines is crucial for maintaining code quality, ensuring rapid feedback, and enabling fast releases. This guide focuses on configuring Playwright specifically for CI environments, addressing common setup requirements such as headless mode, worker allocation, and leveraging Playwright's `ci` property for optimal performance and reliability in automated pipelines. Understanding these configurations is vital for any SDET looking to build robust and efficient testing frameworks.

## Detailed Explanation

When running Playwright tests in a CI environment, several factors need careful consideration to ensure stability, performance, and accurate results. CI environments often have limited resources, no graphical interface, and a need for speed. Playwright offers specific configurations to address these challenges.

### 1. The `ci` Property in Playwright Configuration

Playwright's `playwright.config.ts` (or `.js`) provides a `ci` property within the `use` object. While not a direct configuration option that you set to `true` or `false`, it's common practice to detect CI environments and apply specific configurations conditionally. This property is typically used to apply specific settings when a CI environment variable (e.g., `CI=true`) is detected. This allows you to differentiate between local development runs and CI pipeline runs.

**Example Usage of `ci` Property:**
Though `ci` isn't a direct config *key*, the practice involves checking `process.env.CI`.

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

// Check if running in a CI environment
const isCI = !!process.env.CI;

export default defineConfig({
  testDir: './tests',
  /* Maximum time one test can run for. */
  timeout: 30 * 1000,
  /* Expect timeout per assertion. */
  expect: {
    timeout: 5000
  },
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: isCI,
  /* Retry on CI only */
  retries: isCI ? 2 : 0,
  /* Workers in parallel on CI only */
  workers: isCI ? '50%' : undefined, // Use 50% of available CPU cores in CI
  
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: 'http://127.0.0.1:3000',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',

    // Configure headless mode conditionally
    headless: isCI, // Run headless in CI, optionally headful locally
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
  ],

  /* Output directory for test results. */
  outputDir: './test-results',

  /* Web server for Playwright Test */
  webServer: {
    command: 'npm run start',
    url: 'http://127.0.0.1:3000',
    reuseExistingServer: !isCI,
  },
});
```

### 2. Configure Headless Mode for CI

CI environments typically lack a graphical user interface. Running browsers in "headless" mode means they operate without a visible UI, which is essential for CI. Playwright browsers run headless by default, but it's good practice to explicitly define this behavior, especially when you might want to run tests with a visible browser locally.

In `playwright.config.ts`, you control this with the `headless` option within the `use` object:

```typescript
// playwright.config.ts (excerpt)
use: {
  // ... other configurations
  headless: !!process.env.CI, // true for CI, false otherwise
},
```
This ensures that when the `CI` environment variable is set (which is standard in most CI systems), Playwright runs tests in headless mode. If `CI` is not set (e.g., during local development), tests can run in headful mode, aiding debugging.

### 3. Adjust Workers for CI Resource Limits

The `workers` property in `playwright.config.ts` controls how many parallel worker processes Playwright can spawn to execute tests. In CI environments, resource limits (CPU, memory) are common. Setting an appropriate number of workers is crucial to prevent the CI server from being overloaded, leading to unstable tests or pipeline failures.

You can specify `workers` as a number (e.g., `4`) or as a percentage of the available CPU cores (e.g., `'50%'`).

```typescript
// playwright.config.ts (excerpt)
export default defineConfig({
  // ...
  workers: process.env.CI ? '50%' : undefined, // Use half of the CPU cores in CI, or default behavior locally
  // ...
});
```

Using `'50%'` is often a good starting point for CI, as it utilizes resources efficiently without completely starving the CI runner of CPU for other tasks. For very resource-constrained environments, you might opt for a fixed low number like `2` or `4`. `undefined` lets Playwright determine the optimal number of workers based on the available CPU cores, which is typically `(number of CPU cores / 2)`.

## Code Implementation

Below is a complete `playwright.config.ts` example incorporating these CI best practices.

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';
import dotenv from 'dotenv'; // Assuming dotenv is installed for local .env files

// Load environment variables from .env file for local development
dotenv.config();

// Determine if running in a CI environment
const isCI = !!process.env.CI;

/**
 * See https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './tests', // Directory where your test files are located
  /* Maximum time one test can run for. */
  timeout: 60 * 1000, // 60 seconds timeout per test
  /* Expect timeout per assertion. */
  expect: {
    timeout: 10 * 1000 // 10 seconds timeout for assertions
  },
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: isCI,
  /* Retry on CI only to handle flaky tests */
  retries: isCI ? 2 : 0,
  /* Opt out of parallel tests on CI.
     Set workers based on CI environment resource availability.
     '50%' uses half of the available CPU cores. Adjust as needed.
  */
  workers: isCI ? '50%' : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: isCI ? 'github' : 'html', // Use GitHub Actions reporter in CI, HTML locally
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: process.env.BASE_URL || 'http://localhost:3000', // Use an environment variable or default

    /* Configure headless mode: true for CI, false for local debugging */
    headless: isCI,

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',

    /* Screenshot capturing: 'only-on-failure' is good for CI to save space */
    screenshot: 'only-on-failure',

    /* Video recording: 'on-first-retry' can help debug CI failures */
    video: 'on-first-retry',
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
    // Example for mobile devices
    // {
    //   name: 'Mobile Chrome',
    //   use: { ...devices['Pixel 5'] },
    // },
    // {
    //   name: 'Mobile Safari',
    //   use: { ...devices['iPhone 12'] },
    // },
  ],

  /* Folder for test artifacts such as screenshots, videos, trace files, etc. */
  outputDir: 'test-results/',

  /* Run your local dev server before starting the tests */
  webServer: {
    command: 'npm run start', // Command to start your application
    url: 'http://localhost:3000', // URL where your application serves
    reuseExistingServer: !isCI, // Reuse server locally, start a new one in CI
    timeout: 120 * 1000, // Give server 120 seconds to start
  },
});
```

## Best Practices

- **Conditional Configuration:** Always use `process.env.CI` to apply CI-specific settings (e.g., `headless`, `retries`, `workers`, `forbidOnly`) so that local development remains convenient.
- **Resource Management:** Carefully adjust `workers` to match your CI environment's available CPU and memory. Over-allocating can lead to build failures due to resource exhaustion.
- **Headless by Default:** Ensure browsers run in headless mode in CI. It's the standard for server-side execution where no display is available.
- **Error Reporting:** Configure reporters suitable for CI (e.g., `github` for GitHub Actions, `json` for custom parsing, or `list` for quick feedback) in addition to `html` for local detailed reports.
- **Retry Mechanism:** Enable `retries` only in CI. This helps mitigate flaky tests that might fail intermittently due to environmental factors, providing more stable builds without masking real bugs during local development.
- **Base URL:** Define `baseURL` in `playwright.config.ts` and ideally drive it from an environment variable (e.g., `process.env.BASE_URL`) that can be easily overridden in CI for different environments (dev, staging, production).
- **Web Server Management:** Use `webServer` configuration to automatically start your application before tests and ensure `reuseExistingServer: !isCI` to prevent multiple server instances in CI.
- **Artifact Collection:** Configure `trace`, `screenshot`, and `video` to collect artifacts only on failure or first retry in CI. This aids in debugging pipeline failures without consuming excessive storage.

## Common Pitfalls

- **Resource Starvation:** Setting `workers` too high in a resource-constrained CI environment can lead to tests failing due to out-of-memory errors or CPU contention, causing the pipeline to become unstable.
- **Non-Headless Runs in CI:** Forgetting to set `headless: true` (or conditionally `isCI`) will cause tests to fail in CI environments that lack a display server.
- **Hardcoding URLs:** Hardcoding `baseURL` can make it difficult to run tests against different environments (development, staging, production) in various CI stages. Always use environment variables for this.
- **Excessive Artifacts:** Collecting screenshots, videos, and traces for every test run (even successful ones) in CI can quickly consume disk space and slow down pipelines, especially for large test suites.
- **Ignoring Flakiness:** Not using `retries` in CI can lead to legitimate failures being masked by intermittent issues, while over-reliance on retries can hide truly flaky tests that need fixing.
- **Unmanaged Web Servers:** If your application isn't started correctly (e.g., using `webServer` config or a separate CI step), Playwright tests will fail due to connection errors.

## Interview Questions & Answers

1.  **Q: How do you ensure Playwright tests run efficiently and reliably in a CI/CD pipeline?**
    **A:** I primarily focus on optimizing the Playwright configuration for the CI environment. This includes:
    *   **Headless Mode:** Ensuring browsers run in `headless` mode, which is essential for server environments.
    *   **Worker Allocation:** Adjusting the `workers` count based on CI resource availability (e.g., `'50%'` of CPU cores or a fixed number) to prevent resource contention.
    *   **Conditional Retries:** Enabling `retries` only for CI runs to mitigate flaky tests without hiding issues locally.
    *   **Base URL Management:** Using environment variables for `baseURL` to easily target different deployment environments.
    *   **Artifact Strategy:** Configuring `trace`, `screenshot`, and `video` to capture artifacts only on failure or retry to optimize storage and pipeline speed.
    *   **Web Server Integration:** Using Playwright's `webServer` configuration to reliably start and stop the application under test within the pipeline.

2.  **Q: What is the purpose of running Playwright tests in headless mode in a CI environment?**
    **A:** The primary purpose of running Playwright tests in headless mode in a CI environment is that CI servers typically do not have a graphical user interface (GUI) or a display server installed. Headless mode allows the browser to operate without a visible UI, making it possible to execute UI tests on these server-side machines. It's also generally faster and consumes fewer resources than running tests in headful mode, which is beneficial in resource-constrained CI environments.

3.  **Q: How do you prevent your CI pipeline from being overloaded when running a large Playwright test suite?**
    **A:** To prevent CI pipeline overload, I focus on optimizing resource consumption and parallelism:
    *   **Worker Configuration:** Adjusting the `workers` property in `playwright.config.ts` is key. I'd typically set it to a percentage of available CPU cores (e.g., `'50%'`) or a specific number that doesn't overwhelm the CI runner.
    *   **Test Sharding/Distribution:** For very large suites, I would explore test sharding capabilities of the CI system or Playwright itself (`--shard` option) to distribute tests across multiple CI agents, if available.
    *   **Efficient Artifact Collection:** Only collecting screenshots, videos, and traces on failure helps reduce I/O and storage, contributing to faster pipeline execution.
    *   **Optimized Test Code:** Ensuring tests are efficient, avoid unnecessary waits, and clean up after themselves also contributes to overall performance.

## Hands-on Exercise

**Objective:** Configure an existing Playwright project to run optimally within a simulated CI environment.

1.  **Setup:**
    *   Create a new directory for this exercise.
    *   Initialize a new Playwright project: `npm init playwright@latest` (choose TypeScript, specify a small example test).
    *   Install `dotenv`: `npm install dotenv`
    *   Create a simple test file (e.g., `tests/example.spec.ts`) that navigates to a local server or a public website like `https://www.google.com`.

2.  **Configuration (`playwright.config.ts`):**
    *   Modify `playwright.config.ts` to include the conditional logic for CI:
        *   Import and configure `dotenv`.
        *   Detect if `process.env.CI` is set.
        *   Set `headless: isCI`.
        *   Set `retries: isCI ? 2 : 0`.
        *   Set `workers: isCI ? '50%' : undefined`.
        *   Set `forbidOnly: isCI`.
        *   Set `reporter: isCI ? 'list' : 'html'`.
        *   Ensure `screenshot` and `video` are set to `only-on-failure` or `on-first-retry`.

3.  **Simulate CI:**
    *   **Local Run (non-CI):** Run your tests normally: `npx playwright test`. Observe the behavior (e.g., headful, HTML report).
    *   **Simulate CI Run:** Run your tests with the `CI` environment variable set:
        *   **Windows (PowerShell):** `$env:CI='true'; npx playwright test`
        *   **Linux/macOS:** `CI=true npx playwright test`
    *   Observe the differences:
        *   Are the browsers running headless?
        *   Are retries happening if a test is made to fail intermittently (you might need to introduce artificial flakiness for this)?
        *   Is the reporter output different?

4.  **Verification:**
    *   Confirm that tests run without a visible browser when `CI=true`.
    *   Confirm that the `forbidOnly` rule works by temporarily adding `test.only` and running with `CI=true`.
    *   Confirm the reporter changes based on `CI` flag.

## Additional Resources

-   **Playwright Test Configuration:** [https://playwright.dev/docs/test-configuration](https://playwright.dev/docs/test-configuration)
-   **Playwright CLI Options:** [https://playwright.dev/docs/test-cli](https://playwright.dev/docs/test-cli)
-   **GitHub Actions with Playwright:** [https://playwright.dev/docs/ci/github-actions](https://playwright.dev/docs/ci/github-actions)
-   **Azure DevOps with Playwright:** [https://playwright.dev/docs/ci/azure-pipelines](https://playwright.dev/docs/ci/azure-pipelines)
---
# playwright-5.7-ac2.md

# Playwright CI/CD Integration: Setting Up GitHub Actions Workflow

## Overview
Continuous Integration/Continuous Delivery (CI/CD) pipelines are crucial for modern software development, enabling automated testing and deployment. Integrating Playwright tests into a CI/CD pipeline, specifically using GitHub Actions, ensures that every code change is validated against UI and API tests early and consistently. This proactive approach helps catch regressions quickly, maintains code quality, and accelerates the delivery of reliable software. This guide focuses on setting up a robust GitHub Actions workflow for Playwright.

## Detailed Explanation

GitHub Actions provides a flexible and powerful way to automate workflows directly within your GitHub repository. For Playwright tests, a typical workflow involves setting up the environment, installing dependencies, installing necessary browser binaries, and then executing the tests.

The official Playwright GitHub Action template provides a solid starting point, handling most of the environment setup for you.

### Key Components of a GitHub Actions Workflow for Playwright:

1.  **Trigger Events**: Define when the workflow should run. Common triggers for testing include `push` (on code commits) and `pull_request` (when a PR is opened, synchronized, or reopened).
2.  **Jobs**: Workflows are composed of one or more jobs. Each job runs in a virtual environment (e.g., `ubuntu-latest`).
3.  **Steps**: Within a job, steps define the sequence of tasks to execute.
    *   **Checkout Repository**: The `actions/checkout@v4` action is used to check out your repository's code.
    *   **Setup Node.js**: If your Playwright project uses Node.js, `actions/setup-node@v4` is used to install a specific Node.js version.
    *   **Install Dependencies**: Install project dependencies (e.g., `npm install` or `yarn install`).
    *   **Install Playwright Browsers**: The `@playwright/test` package includes a command to install browser binaries required by Playwright (Chromium, Firefox, WebKit). This is a critical step for CI environments.
    *   **Run Tests**: Execute your Playwright tests using `npx playwright test` or your custom test command.

### Example Workflow Breakdown:

The following example demonstrates a basic GitHub Actions workflow (`.github/workflows/playwright.yml`) for running Playwright tests.

*   **`on: [push, pull_request]`**: The workflow runs on every push to any branch and every pull request.
*   **`runs-on: ubuntu-latest`**: The job will execute on an Ubuntu Linux runner.
*   **`actions/checkout@v4`**: Fetches your code.
*   **`actions/setup-node@v4`**: Sets up Node.js.
*   **`npm ci`**: Installs dependencies. `npm ci` is preferred over `npm install` in CI environments for faster and more reliable installs, as it uses `package-lock.json` or `npm-shrinkwrap.json`.
*   **`npx playwright install --with-deps`**: Installs Playwright browser binaries and their operating system dependencies. `--with-deps` is crucial for CI environments to ensure all necessary system libraries are present.
*   **`npx playwright test`**: Runs all Playwright tests.

## Code Implementation

Create a file named `playwright.yml` inside the `.github/workflows/` directory in your project root.

```yaml
# .github/workflows/playwright.yml
name: Playwright Tests

on:
  push:
    branches: [ main, master, develop ] # Trigger on push to these branches
  pull_request:
    branches: [ main, master, develop ] # Trigger on pull requests targeting these branches
  workflow_dispatch: # Allows manual triggering of the workflow from GitHub UI

jobs:
  test:
    timeout-minutes: 60 # Set a timeout for the entire job
    runs-on: ubuntu-latest # Or windows-latest, macos-latest for different environments

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: 20 # Specify the Node.js version your project uses

    - name: Install dependencies
      run: npm ci # Use npm ci for clean and fast installations in CI

    - name: Install Playwright browsers
      # Install Playwright's browsers and their system dependencies.
      # The --with-deps flag ensures that all necessary OS dependencies are installed.
      run: npx playwright install --with-deps

    - name: Run Playwright tests
      run: npx playwright test # Command to execute all Playwright tests
      env:
        # Example of setting an environment variable for tests
        # This can be useful for configuring test environments (e.g., base URL)
        BASE_URL: ${{ secrets.PLAYWRIGHT_BASE_URL || 'http://localhost:3000' }}
        CI: 'true' # Often used by test runners to detect CI environment
      
    - name: Upload Playwright test results
      # This step uploads the test-results folder as an artifact,
      # which can be downloaded and inspected after the workflow completes.
      if: always() # Run this step even if previous steps fail
      uses: actions/upload-artifact@v4
      with:
        name: playwright-test-results
        path: test-results/
        retention-days: 5 # How long to retain the artifact
```

## Best Practices
- **Use `npm ci`**: For CI environments, `npm ci` is more reliable and faster than `npm install` as it performs a clean install based on `package-lock.json`.
- **Install Browsers with `--with-deps`**: Always use `npx playwright install --with-deps` in CI to ensure all necessary system dependencies for the browsers are installed.
- **Isolate Test Environments**: Use environment variables (e.g., `BASE_URL`) to configure your tests for different environments (dev, staging, production) within your CI workflow. Use GitHub Secrets for sensitive information.
- **Upload Test Artifacts**: Always upload test reports, screenshots, and videos as workflow artifacts. This is invaluable for debugging failed tests directly from GitHub.
- **Parallelize Tests**: For large test suites, consider sharding your Playwright tests across multiple jobs or runners to reduce execution time. Playwright has built-in capabilities for this (`--shard` flag).
- **Add `timeout-minutes`**: Prevent jobs from running indefinitely by setting a `timeout-minutes` for the job.
- **Use `workflow_dispatch`**: Enable manual triggering of your workflow for debugging or specific deployments.

## Common Pitfalls
- **Missing Browser Dependencies**: Forgetting `--with-deps` during `playwright install` can lead to cryptic browser launch errors in CI, as system-level dependencies for browsers (like font libraries, audio drivers) might be missing.
- **Incorrect Node.js Version**: Mismatch between the Node.js version specified in `actions/setup-node` and the one used locally can lead to build or test failures.
- **Flaky Tests**: Tests that pass inconsistently can undermine confidence in the pipeline. Implement proper waits, retries, and clear assertions to minimize flakiness.
- **Not Handling Environment Variables**: Hardcoding URLs or credentials instead of using environment variables or GitHub Secrets makes the workflow less flexible and less secure.
- **Large Artifacts**: Uploading too many or too large artifacts can slow down the workflow and consume significant storage. Be selective and set appropriate `retention-days`.

## Interview Questions & Answers

1.  **Q: Why is it important to integrate Playwright tests into a CI/CD pipeline?**
    A: Integrating Playwright tests into CI/CD ensures that UI and E2E tests run automatically with every code change. This helps to:
    *   **Catch bugs early**: Identifies regressions and issues soon after they are introduced.
    *   **Maintain code quality**: Enforces quality gates before merging code.
    *   **Accelerate feedback loop**: Provides developers with quick feedback on the impact of their changes.
    *   **Automate regression testing**: Reduces manual testing effort and increases test coverage consistency.
    *   **Improve release confidence**: Ensures that the application functions as expected before deployment.

2.  **Q: Explain the purpose of `npx playwright install --with-deps` in a CI environment.**
    A: `npx playwright install --with-deps` is crucial in a CI environment because it not only installs the browser binaries (Chromium, Firefox, WebKit) required by Playwright but also installs their necessary operating system-level dependencies. In a fresh CI runner environment, these system dependencies (e.g., libraries for rendering fonts, handling graphics, or audio) are often missing. Without `--with-deps`, Playwright might fail to launch browsers, leading to test failures.

3.  **Q: How would you handle sensitive information (like API keys or passwords) when running Playwright tests in GitHub Actions?**
    A: Sensitive information should *never* be hardcoded in the workflow file or committed to the repository. In GitHub Actions, this is handled using **GitHub Secrets**.
    *   Define secrets in your repository settings (`Settings > Secrets and variables > Actions`).
    *   Access them in your workflow file using the `secrets` context, for example, `env: API_KEY: ${{ secrets.MY_API_KEY }}`.
    *   This ensures sensitive data is encrypted and only exposed to the runner during execution, not visible in logs.

4.  **Q: What strategies would you use to optimize Playwright test execution time in a CI pipeline for a large project?**
    A: To optimize execution time:
    *   **Parallelization/Sharding**: Use Playwright's built-in `--shard` flag (`npx playwright test --shard=1/3`) to distribute tests across multiple CI jobs or runners. GitHub Actions' matrix strategy can be used for this.
    *   **Headless Mode**: Ensure tests run in headless mode (default in CI) to avoid GUI overhead.
    *   **Optimized Selectors**: Use robust and performant selectors (e.g., `getByTestId`, `getByRole`) to minimize DOM traversal time.
    *   **Caching Dependencies**: Cache `node_modules` and potentially Playwright browser binaries between workflow runs using `actions/cache@v3` to speed up installation times.
    *   **Minimize Retries**: Configure a reasonable number of retries for flaky tests, but focus on fixing flakiness rather than excessive retries.
    *   **Fast Feedback Tests First**: Prioritize running critical or faster tests earlier in the pipeline.

## Hands-on Exercise

**Objective**: Set up a GitHub Actions workflow for a minimal Playwright project.

**Instructions**:

1.  **Initialize a Node.js Project**:
    *   Create a new directory: `mkdir playwright-ci-demo && cd playwright-ci-demo`
    *   Initialize npm: `npm init -y`
2.  **Install Playwright**:
    *   `npm install @playwright/test`
    *   `npx playwright install`
3.  **Create a Simple Test**:
    *   Create `tests/example.spec.ts` (or `example.spec.js`) with the following content:
        ```typescript
        // tests/example.spec.ts
        import { test, expect } from '@playwright/test';

        test('has title', async ({ page }) => {
          await page.goto('https://playwright.dev/');
          await expect(page).toHaveTitle(/Playwright/);
        });

        test('get started link', async ({ page }) => {
          await page.goto('https://playwright.dev/');
          await page.getByRole('link', { name: 'Get started' }).click();
          await expect(page).toHaveURL(/.*intro/);
        });
        ```
4.  **Set up Git and GitHub**:
    *   Initialize a git repository: `git init`
    *   Create a `.gitignore` file:
        ```
        node_modules/
        test-results/
        .cache/
        ```
    *   Make an initial commit: `git add . && git commit -m "Initial commit"`
    *   Create a new public GitHub repository and push your local repository to it.
5.  **Create GitHub Actions Workflow**:
    *   Create the directory: `mkdir -p .github/workflows`
    *   Create the workflow file `.github/workflows/playwright.yml` and paste the "Code Implementation" YAML provided above.
6.  **Push to GitHub**:
    *   `git add .github/workflows/playwright.yml`
    *   `git commit -m "Add Playwright CI workflow"`
    *   `git push origin main` (or your default branch)

**Verification**:
Go to your GitHub repository, navigate to the "Actions" tab, and observe the workflow execution. It should trigger on your push and successfully run the Playwright tests. You should also be able to download the `playwright-test-results` artifact.

## Additional Resources
-   **Playwright Documentation - Continuous Integration**: [https://playwright.dev/docs/ci](https://playwright.dev/docs/ci)
-   **GitHub Actions Documentation**: [https://docs.github.com/en/actions](https://docs.github.com/en/actions)
-   **Playwright GitHub Action**: [https://github.com/microsoft/playwright-github-action](https://github.com/microsoft/playwright-github-action)
-   **Official Playwright CI Examples**: [https://github.com/microsoft/playwright/tree/main/examples/ci-github-actions](https://github.com/microsoft/playwright/tree/main/examples/ci-github-actions)
---
# playwright-5.7-ac3.md

# Playwright CI/CD Integration: Jenkins Pipeline Configuration

## Overview
Continuous Integration/Continuous Delivery (CI/CD) is crucial for modern software development, enabling automated testing and deployment. Integrating Playwright tests into a Jenkins pipeline ensures that UI tests are run automatically with every code change, catching regressions early and maintaining a high quality bar. This document outlines how to configure a Jenkins pipeline to execute Playwright tests, covering dependency installation, test execution, and workspace management.

## Detailed Explanation
A Jenkins pipeline is a suite of plugins that supports implementing and integrating continuous delivery pipelines into Jenkins. It's defined using a `Jenkinsfile` (a Groovy script) which lives in your project's source code repository.

For Playwright, the pipeline typically involves:
1.  **Checkout SCM**: Retrieving the latest code from your version control system (e.g., Git).
2.  **Install Dependencies**: Installing Node.js, npm, and all project dependencies, including Playwright itself and its browsers.
3.  **Run Tests**: Executing Playwright tests using the configured test runner (e.g., `npx playwright test`).
4.  **Publish Test Results**: Archiving test reports (e.g., JUnit, HTML reports) so they can be viewed directly in Jenkins.
5.  **Workspace Cleanup**: Ensuring the build environment is clean for subsequent runs.

### Jenkinsfile Structure
A `Jenkinsfile` can be either Declarative or Scripted. We will focus on a Declarative Pipeline, which is more structured and easier to understand for most CI/CD use cases.

The key stages for Playwright integration are:
*   **Agent**: Specifies where the pipeline will run (e.g., a Docker agent with Node.js pre-installed or a generic agent where Node.js is installed on the host).
*   **Stages**: Contains the sequence of steps to be executed.
    *   **Install Dependencies**: Uses `npm install` or `yarn install` to get project dependencies. It's also crucial to install Playwright browsers (`npx playwright install --with-deps`).
    *   **Run Tests**: Executes tests, often passing arguments for CI mode, headless execution, or specific browser targeting.
    *   **Post-build Actions**: Handles reporting and cleanup.

## Code Implementation

Here's a `Jenkinsfile` example for a typical Playwright project. This assumes your project uses `npm` and has a `package.json` with a `test` script, and you want to generate an HTML report.

```groovy
// Jenkinsfile for Playwright CI/CD
pipeline {
    // Agent definition: Use a Docker image with Node.js pre-installed.
    // This provides a consistent environment for builds.
    agent {
        docker {
            image 'mcr.microsoft.com/playwright/node:lts' // Official Playwright Docker image with Node.js
            args '-v /tmp:/tmp' // Mount /tmp for potential browser downloads if needed (less common with official image)
        }
    }

    // Environment variables that can be used across stages
    environment {
        // Force Playwright to run in headless mode, suitable for CI environments
        PLAYWRIGHT_HEADLESS = 'true'
        // Disable Playwright telemetry during CI runs
        PWDEBUG = '0'
    }

    stages {
        // Stage 1: Install Dependencies
        stage('Install Dependencies') {
            steps {
                script {
                    echo 'Installing project dependencies...'
                    // Check if package-lock.json exists, if not, use npm install
                    // Using npm ci is generally better for CI as it uses package-lock.json
                    // for deterministic installs.
                    if (fileExists('package-lock.json')) {
                        sh 'npm ci'
                    } else {
                        sh 'npm install'
                    }

                    echo 'Installing Playwright browsers...'
                    // Install Playwright's browsers. The --with-deps flag ensures
                    // all necessary OS dependencies are also installed.
                    sh 'npx playwright install --with-deps'
                }
            }
        }

        // Stage 2: Run Tests
        stage('Run Tests') {
            steps {
                script {
                    echo 'Running Playwright tests...'
                    // Execute Playwright tests.
                    // --workers=1 can be used to avoid concurrency issues on smaller agents,
                    // or if tests are not designed for parallel execution.
                    // The --reporter=junit argument generates a JUnit XML report, which Jenkins can parse.
                    // The --output results/ option specifies where test artifacts (like traces, screenshots)
                    // are stored.
                    sh 'npx playwright test --reporter=junit,html --output=test-results'
                }
            }
            // Ensure this stage always runs, even if previous stages fail, if cleanup is crucial
            // post {
            //     always {
            //         echo 'Test stage completed.'
            //     }
            // }
        }
    }

    // Post-build actions: These steps run after all stages have completed, regardless of their success or failure.
    post {
        // Always run these steps
        always {
            echo 'Archiving test results...'
            // Archive the JUnit XML report for Jenkins' test result trend graphs
            junit 'junit-results.xml' // Assuming the JUnit reporter outputs to junit-results.xml

            // Archive the Playwright HTML report and other artifacts
            archiveArtifacts artifacts: 'test-results/**/*', fingerprint: true

            // Clean up the workspace after the build to free up disk space and prevent interference
            // with subsequent builds.
            echo 'Cleaning up workspace...'
            deleteDir() // Deletes the entire workspace directory
        }
        // Specific action for successful builds
        success {
            echo 'Pipeline finished successfully.'
        }
        // Specific action for failed builds
        failure {
            echo 'Pipeline failed. Check test reports for details.'
        }
    }
}
```

## Best Practices
-   **Use `npm ci` for CI**: Prefer `npm ci` over `npm install` in CI environments. It's faster and ensures deterministic installs by relying on `package-lock.json`.
-   **Isolate Environments with Docker**: Use Docker agents or containers to ensure a consistent and isolated environment for your tests, preventing "it works on my machine" issues.
-   **Headless Mode for CI**: Always run Playwright tests in headless mode in CI to save resources and avoid GUI rendering issues.
-   **Leverage Playwright Reporters**: Configure Playwright to output JUnit XML reports for Jenkins integration and HTML reports for detailed debugging.
-   **Workspace Cleanup**: Implement `deleteDir()` or similar cleanup steps in `post` actions to keep your Jenkins agent's workspace tidy.
-   **Environment Variables**: Use Jenkins environment variables for sensitive data or configuration that varies between environments (e.g., `BASE_URL`, `API_KEY`).
-   **Parallel Execution**: For large test suites, explore Playwright's parallel test execution (`--workers`) and Jenkins' parallel stage capabilities to speed up feedback.
-   **Artifact Archiving**: Archive useful artifacts like screenshots, videos, and Playwright traces for failed tests to aid in debugging.

## Common Pitfalls
-   **Browser Installation Issues**: Forgetting `npx playwright install --with-deps` or running it without necessary system dependencies can lead to tests failing to launch browsers.
-   **Resource Exhaustion**: Running too many tests in parallel or not cleaning up the workspace can lead to Jenkins agent resource issues (memory, disk space).
-   **Flaky Tests**: Tests that pass inconsistently can undermine confidence in the CI pipeline. Invest in making tests robust and reliable.
-   **Incorrect Paths**: Mismatched paths for reports or artifacts between your Playwright configuration and `Jenkinsfile` can cause reports not to be published.
-   **Timeouts**: Playwright tests can time out if the application under test is slow or if CI agents are under-resourced. Adjust Playwright's `timeout` settings and Jenkins' step timeouts as needed.

## Interview Questions & Answers
1.  **Q: How do you integrate Playwright tests into a CI/CD pipeline like Jenkins?**
    A: I would define a `Jenkinsfile` in the project's root. This file would specify stages for checking out the code, installing Node.js dependencies (`npm ci`), installing Playwright browsers (`npx playwright install --with-deps`), running the tests (`npx playwright test --reporter=junit,html`), and then archiving the generated JUnit and HTML reports. I'd typically use a Docker agent with a pre-installed Node.js environment for consistency.

2.  **Q: What are the benefits of running Playwright tests in CI?**
    A: The main benefits are early bug detection, faster feedback on code changes, improved code quality, and automation of the testing process. It ensures that every code commit is validated against UI tests, reducing the risk of regressions reaching production and allowing developers to fix issues quickly.

3.  **Q: What considerations do you make when setting up a Playwright CI pipeline for performance and reliability?**
    A: For performance, I focus on using `npm ci` for faster dependency installation, running tests in headless mode, and potentially leveraging Playwright's parallel test execution with appropriate `--workers` settings. For reliability, I ensure the environment is consistent (e.g., via Docker), tests are robust and not flaky, and there's proper error handling and retry mechanisms if applicable. Also, effective workspace cleanup prevents build interference.

## Hands-on Exercise
1.  **Prerequisites**:
    *   A running Jenkins instance.
    *   A GitHub repository (or any SCM accessible by Jenkins) containing a simple Playwright test project (e.g., `npx playwright init` project).
    *   The `Jenkinsfile` provided in the "Code Implementation" section added to the root of your repository.
2.  **Steps**:
    *   Create a new "Pipeline" job in Jenkins.
    *   Configure the job to pull your `Jenkinsfile` from SCM (e.g., Git).
    *   Ensure Jenkins has access to Docker (if using the Docker agent).
    *   Run the Jenkins job.
    *   Observe the build output, console logs, and verify that test results (JUnit report) and archived HTML reports are available in the Jenkins job view.

## Additional Resources
-   **Jenkins Pipeline Documentation**: [https://www.jenkins.io/doc/book/pipeline/](https://www.jenkins.io/doc/book/pipeline/)
-   **Playwright CI Guide**: [https://playwright.dev/docs/ci](https://playwright.dev/docs/ci)
-   **Playwright Docker Images**: [https://playwright.dev/docs/docker](https://playwright.dev/docs/docker)
---
# playwright-5.7-ac4.md

# Playwright Parallel Execution with Workers

## Overview
Efficient test execution is crucial for rapid feedback in CI/CD pipelines. Playwright provides built-in capabilities for parallel test execution across multiple worker processes, significantly reducing the overall test suite run time. This feature is vital for large test suites, enabling faster release cycles and more efficient resource utilization. Understanding how to configure and leverage parallel execution is a key skill for any SDET working with Playwright.

## Detailed Explanation
Playwright's parallel test execution is configured primarily through the `playwright.config.ts` file using the `workers` option. This option specifies the number of worker processes that Playwright should use to run tests concurrently. Each worker runs a subset of the tests, isolated from other workers, ensuring that tests do not interfere with each other.

By default, Playwright uses a number of workers equal to 50% of the number of CPU cores available on the machine, but not more than 7. You can explicitly set the `workers` property to a fixed number, or to a percentage of the available CPU cores (e.g., `'50%'`).

**How it works:**
1.  **Test Sharding:** Playwright automatically shards your test files or individual tests among the available workers.
2.  **Isolated Environments:** Each worker process runs in its own isolated environment, complete with its own browser instances (if configured per worker), context, and page objects. This isolation prevents test interdependence and flakiness.
3.  **Reporter Aggregation:** Playwright aggregates results from all workers into a single report at the end of the execution.

**Benefits:**
*   **Reduced Execution Time:** The most significant benefit is the drastic reduction in total test execution time, especially for large suites.
*   **Improved Feedback Loop:** Faster feedback to developers and QAs on code changes.
*   **Better Resource Utilization:** Leverages multi-core processors effectively.

## Code Implementation

Below is an example `playwright.config.ts` demonstrating how to configure parallel execution and a sample test file.

First, the `playwright.config.ts` file:

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Look for test files in the "tests" directory, relative to this configuration file.
  testDir: './tests',
  // Folder for test artifacts such as screenshots, videos, traces, etc.
  outputDir: './test-results',

  // Run your tests in parallel on CI, or with a specified number of workers.
  // By default, it uses a percentage of CPU cores or a fixed number (e.g., 7).
  // Here we explicitly set it to 4 workers for demonstration.
  // You can also use '50%' for 50% of available CPU cores.
  workers: process.env.CI ? 2 : undefined, // Use 2 workers on CI, default locally
  
  // Example of setting a fixed number of workers.
  // workers: 4, 

  // Example of using a percentage of CPU cores.
  // workers: '75%',

  // Reporter to use. See https://playwright.dev/docs/test-reporters
  reporter: 'html',

  // Configure projects for major browsers
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
  ],

  // Global setup and teardown can also be used here.
  // For example, setting up a global database connection before all tests.
  // globalSetup: require.resolve('./global-setup'),
  // globalTeardown: require.resolve('./global-teardown'),
});
```

Next, a sample test file (`tests/example.spec.ts`) that simulates some work:

```typescript
// tests/example.spec.ts
import { test, expect } from '@playwright/test';

// Simulate a longer running test to observe parallel execution benefits
function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

test.describe('Parallel Test Suite', () => {

  test('should load Google and assert title - Test 1', async ({ page }) => {
    await page.goto('https://www.google.com');
    await sleep(1000); // Simulate some processing time
    await expect(page).toHaveTitle(/Google/);
    console.log('Test 1 finished on worker:', test.info().workerIndex);
  });

  test('should load DuckDuckGo and assert title - Test 2', async ({ page }) => {
    await page.goto('https://duckduckgo.com');
    await sleep(1500); // Simulate some processing time
    await expect(page).toHaveTitle(/DuckDuckGo/);
    console.log('Test 2 finished on worker:', test.info().workerIndex);
  });

  test('should load Bing and assert title - Test 3', async ({ page }) => {
    await page.goto('https://www.bing.com');
    await sleep(2000); // Simulate some processing time
    await expect(page).toHaveTitle(/Bing/);
    console.log('Test 3 finished on worker:', test.info().workerIndex);
  });

  test('should load Yahoo and assert title - Test 4', async ({ page }) => {
    await page.goto('https://www.yahoo.com');
    await sleep(1200); // Simulate some processing time
    await expect(page).toHaveTitle(/Yahoo/);
    console.log('Test 4 finished on worker:', test.info().workerIndex);
  });

  test('should load Wikipedia and assert title - Test 5', async ({ page }) => {
    await page.goto('https://www.wikipedia.org');
    await sleep(1800); // Simulate some processing time
    await expect(page).toHaveTitle(/Wikipedia/);
    console.log('Test 5 finished on worker:', test.info().workerIndex);
  });
});
```

To run these tests with the configured workers:
`npx playwright test`

You can also override the workers setting from the command line:
`npx playwright test --workers=2`

## Best Practices
- **Test Isolation:** Ensure all tests are fully isolated and do not depend on the state of other tests. This is critical for parallel execution, as tests can run in any order on different workers.
- **Stateless Tests:** Design tests to be stateless. Avoid shared resources or global variables that can be modified by multiple tests concurrently. If shared resources are unavoidable (e.g., a test database), ensure proper setup/teardown and data isolation for each test or worker.
- **Optimal Worker Count:** Experiment with the `workers` count to find the optimal number for your CI environment. Too few workers won't fully utilize resources; too many can lead to context switching overhead and resource exhaustion. A good starting point is usually 50-75% of CPU cores.
- **CI/CD Integration:** Configure your CI/CD pipeline to set the `workers` option appropriately, often leveraging environment variables (e.g., `process.env.CI`).
- **Resource Management:** Monitor CPU and memory usage in your CI environment during parallel runs. Adjust worker count or resource allocation if you encounter performance bottlenecks or instability.
- **Avoid Global Side Effects:** Any global setup or teardown (`globalSetup`, `globalTeardown`) should be carefully implemented to avoid side effects that could impact parallel tests. For example, setting up a database should ensure each worker gets a clean slate or unique data.

## Common Pitfalls
- **Shared State:** The most common pitfall is tests relying on shared state or resources that are not properly isolated, leading to flaky tests or failures that are difficult to debug.
- **Resource Exhaustion:** Running too many workers on a machine with limited CPU or memory can lead to slow execution, browser crashes, or out-of-memory errors.
- **Network Latency:** If tests frequently interact with external services, network latency might become a bottleneck, even with parallel execution. Optimize API calls or use mock services when appropriate.
- **Debugging Challenges:** Debugging parallel tests can be more complex due to non-deterministic execution order. Playwright's trace viewer and detailed logging become essential tools.
- **Unoptimized Test Structure:** If tests are very long or involve extensive setup/teardown within each test, the overhead might diminish the benefits of parallelization. Break down long tests into smaller, focused ones.

## Interview Questions & Answers
1.  **Q: How do you configure Playwright to run tests in parallel? What are the benefits?**
    **A:** Playwright tests are configured for parallel execution using the `workers` option in `playwright.config.ts`. You can set it to a fixed number (e.g., `workers: 4`) or a percentage of CPU cores (e.g., `workers: '50%'`). The primary benefits are significantly reduced test execution time, faster feedback loops in CI/CD, and better utilization of multi-core processing power.

2.  **Q: What are the main challenges or considerations when implementing parallel test execution in Playwright? How do you address them?**
    **A:** The main challenges include ensuring complete test isolation to prevent shared state issues, managing resource consumption (CPU/memory), and potential debugging complexity. To address these, I ensure tests are stateless, use unique data for each test, monitor CI resources to optimize the `workers` count, and leverage Playwright's debugging tools like trace viewer. For shared resources, I implement robust setup/teardown mechanisms that guarantee isolation.

3.  **Q: Describe a scenario where parallel test execution might not provide the expected performance improvement or could even cause issues.**
    **A:** Parallel execution might not improve performance significantly if tests are predominantly I/O bound (e.g., waiting for slow external API responses) rather than CPU bound. It could also cause issues if tests have implicit dependencies on each other's execution order or shared mutable state, leading to intermittent failures. Another scenario is running too many workers on a machine with insufficient resources, leading to thrashing and slower overall execution.

## Hands-on Exercise
1.  **Setup:**
    *   Create a new Playwright project: `npm init playwright@latest` (choose TypeScript, don't add a GitHub Actions workflow).
    *   Replace the content of `playwright.config.ts` with the "Code Implementation" example above.
    *   Create a `tests` directory and add the `example.spec.ts` from the "Code Implementation" section.

2.  **Run with varying workers:**
    *   Run tests with default workers (or `workers: undefined` in config): `npx playwright test`
    *   Run tests with 1 worker: `npx playwright test --workers=1`
    *   Run tests with 2 workers: `npx playwright test --workers=2`
    *   Run tests with 4 workers: `npx playwright test --workers=4`

3.  **Observe:**
    *   Compare the total execution times for each run. Note how increasing workers generally decreases the total time, up to a point.
    *   Observe the console output from `console.log('Test X finished on worker:', test.info().workerIndex);` to see which worker executed which test.

## Additional Resources
-   **Playwright Documentation - Parallelism and sharding:** [https://playwright.dev/docs/test-parallel](https://playwright.dev/docs/test-parallel)
-   **Playwright `workers` option:** [https://playwright.dev/docs/test-configuration#workers](https://playwright.dev/docs/test-configuration#workers)
-   **Video: Playwright Test Parallelism:** [https://www.youtube.com/watch?v=F_Yv2yQk140](https://www.youtube.com/watch?v=F_Yv2yQk140)
---
# playwright-5.7-ac5.md

# Playwright Test Sharding for Large Test Suites

## Overview
Test sharding in Playwright allows you to divide a large test suite into smaller, independent chunks (shards) that can be executed in parallel across multiple machines or CI/CD jobs. This significantly reduces the overall execution time for massive test suites, making your CI/CD pipeline faster and more efficient, ultimately accelerating feedback cycles for development teams. It's a critical strategy for maintaining rapid testing feedback as your application and test coverage grow.

## Detailed Explanation
Playwright provides built-in support for test sharding using the `--shard` CLI option. This option expects a string in the format `N/M`, where `N` is the current shard number (1-indexed) and `M` is the total number of shards.

When you run Playwright with sharding, it automatically distributes the tests among the specified shards. For example, if you have 100 tests and configure `--shard=1/4`, Playwright will execute approximately the first 25 tests. `--shard=2/4` would run the next 25, and so on.

The distribution is deterministic, meaning the same test files will always be assigned to the same shard given the same total number of shards. This is important for consistent reporting and debugging.

### How it works:
Playwright calculates the total number of test files and then divides them amongst the shards. It does not shard individual tests within a file but rather distributes entire test files. If you have many small test files, sharding works efficiently. If you have a few very large test files, the sharding might not be perfectly balanced in terms of execution time, as one shard might get a disproportionately long test file. For optimal sharding, it's a best practice to keep test files reasonably sized and focused.

### Example Usage:

Let's say you have a `playwright.config.ts` file and several test files.

**Running tests manually with sharding:**

To run tests in two shards:
Shard 1:
```bash
npx playwright test --shard=1/2
```

Shard 2:
```bash
npx playwright test --shard=2/2
```

You would typically run these commands on different machines or in different CI jobs concurrently.

**Configuring CI matrix to run shards in parallel:**

Most CI/CD platforms (like GitHub Actions, GitLab CI, Jenkins, Azure DevOps, CircleCI) support matrix jobs, which are ideal for parallelizing sharded tests.

Here's an example using **GitHub Actions**:

```yaml
name: Playwright Tests with Sharding

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    timeout-minutes: 60
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        shard: [1, 2, 3, 4] # Define 4 shards
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: 20
    - name: Install dependencies
      run: npm ci
    - name: Install Playwright Browsers
      run: npx playwright install --with-deps
    - name: Run Playwright tests in shard ${{ matrix.shard }}
      run: npx playwright test --shard=${{ matrix.shard }}/4
    - uses: actions/upload-artifact@v4
      if: always()
      with:
        name: playwright-report-shard-${{ matrix.shard }}
        path: playwright-report/
        retention-days: 30
```
In this GitHub Actions workflow:
- The `strategy.matrix.shard` defines a list of shard numbers (1, 2, 3, 4).
- The job `test` will run 4 times concurrently, once for each value in the `shard` matrix.
- Each job will execute `npx playwright test --shard=${{ matrix.shard }}/4`, ensuring that each shard runs a portion of the test suite.
- `fail-fast: false` ensures that all shards run even if one fails, allowing you to see the full test results across all shards.
- `upload-artifact` is used to collect individual shard reports, which can then be combined or viewed separately.

### Benefits for Massive Suites:
-   **Reduced Execution Time**: The most significant benefit. By running tests in parallel, the total time to complete the entire suite is drastically cut.
-   **Faster Feedback Loop**: Developers get faster feedback on their code changes, identifying regressions earlier in the development cycle.
-   **Improved CI/CD Efficiency**: Optimizes resource utilization in CI/CD pipelines, as multiple agents can work simultaneously.
-   **Scalability**: Allows test suites to grow very large without becoming an insurmountable bottleneck in the development process.
-   **Resource Isolation**: Each shard runs independently, reducing the chance of resource contention or interference between tests that might occur in a single large run.

## Code Implementation
Here's a minimal example showing how you might set up a `playwright.config.ts` and a simple test to demonstrate sharding.

`playwright.config.ts`:
```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true, // Recommended for parallel execution within a worker
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined, // For sharding, typically one worker per CI job
  reporter: 'html',
  use: {
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    // You can add more projects for other browsers if needed
  ],
});
```

`tests/example.spec.ts`:
```typescript
import { test, expect } from '@playwright/test';

// Simulate a few test files to see sharding in action
// In a real scenario, these would be in separate files.

test.describe('Feature A', () => {
  test('test A1', async ({ page }) => {
    await page.goto('https://www.google.com');
    await expect(page).toHaveTitle(/Google/);
    console.log('Running test A1');
  });

  test('test A2', async ({ page }) => {
    await page.goto('https://www.bing.com');
    await expect(page).toHaveTitle(/Bing/);
    console.log('Running test A2');
  });
});

test.describe('Feature B', () => {
  test('test B1', async ({ page }) => {
    await page.goto('https://www.yahoo.com');
    await expect(page).toHaveTitle(/Yahoo/);
    console.log('Running test B1');
  });

  test('test B2', async ({ page }) => {
    await page.goto('https://duckduckgo.com/');
    await expect(page).toHaveTitle(/DuckDuckGo/);
    console.log('Running test B2');
  });
});

test.describe('Feature C', () => {
  test('test C1', async ({ page }) => {
    await page.goto('https://www.wikipedia.org/');
    await expect(page).toHaveTitle(/Wikipedia/);
    console.log('Running test C1');
  });

  test('test C2', async ({ page }) => {
    await page.goto('https://www.apple.com/');
    await expect(page).toHaveTitle(/Apple/);
    console.log('Running test C2');
  });
});
```
To run these tests locally and observe sharding:

First, create a few more test files for better demonstration:
`tests/another-example.spec.ts`:
```typescript
import { test, expect } from '@playwright/test';

test.describe('Another Feature D', () => {
  test('test D1', async ({ page }) => {
    await page.goto('https://www.amazon.com');
    await expect(page).toHaveTitle(/Amazon/);
    console.log('Running test D1');
  });
});

test.describe('Another Feature E', () => {
  test('test E1', async ({ page }) => {
    await page.goto('https://www.microsoft.com');
    await expect(page).toHaveTitle(/Microsoft/);
    console.log('Running test E1');
  });
});
```

Now, run with sharding:
```bash
# Run shard 1 of 2
npx playwright test --shard=1/2

# Run shard 2 of 2
npx playwright test --shard=2/2
```
You will notice that different sets of test files are executed in each command, demonstrating the sharding. For example, `example.spec.ts` might run in shard 1, and `another-example.spec.ts` in shard 2, or Playwright might split the tests within `example.spec.ts` if it decides that's a better distribution. Note that Playwright primarily shards *files*, not individual `test()` blocks across files, unless `fullyParallel` is used, in which case it sharded at the `test()` level within a file. When sharding across CI jobs, the `shard` parameter primarily splits *files*.

## Best Practices
-   **Keep Test Files Focused**: Design your test files to be relatively small and focused on a specific feature or component. This allows Playwright to distribute them more evenly across shards.
-   **Use `fullyParallel: true` in `playwright.config.ts`**: This enables tests within a single file to run in parallel, maximizing the efficiency of each shard's execution.
-   **Optimal Shard Count**: The ideal number of shards often correlates with the number of available CI agents/runners. Start with a moderate number (e.g., 2-4) and increase as needed, monitoring your CI pipeline's performance. Too many shards can introduce overhead.
-   **Consistent Test Data**: Ensure your tests are independent and don't rely on shared state that could be modified by another shard. Use distinct test data for each test or shard if necessary.
-   **Aggregated Reporting**: After all shards complete, ensure your CI system collects and aggregates the test reports (e.g., Playwright HTML reports, JUnit XML reports) so you have a single, comprehensive view of the entire test run.
-   **Resource Allocation**: Allocate sufficient resources (CPU, memory) to each CI agent running a shard to prevent bottlenecks.

## Common Pitfalls
-   **Unbalanced Shards**: If some test files are significantly longer or more resource-intensive than others, sharding might not distribute the load evenly, leading to some shards finishing much later than others.
    *   **How to avoid**: Regularly review test execution times. Consider breaking down overly long test files. Playwright's `list` command (`npx playwright test --list`) can help in understanding test distribution.
-   **Stateful Tests**: Tests that rely on global state or modify shared resources without proper isolation can lead to flaky failures when run in parallel across shards.
    *   **How to avoid**: Emphasize test isolation. Each test should ideally be self-contained and clean up after itself. Use `test.beforeEach` and `test.afterEach` hooks effectively.
-   **Reporting Challenges**: Combining reports from multiple shards can be tricky. Some CI systems or reporting tools might not natively support merging Playwright's HTML reports.
    *   **How to avoid**: Utilize JUnit XML reporter (`reporter: 'junit'`) which is widely supported for aggregation. For HTML reports, you might need custom scripting or a dedicated tool to merge them or accept viewing them per-shard.
-   **CI Configuration Complexity**: Setting up a matrix job and artifact collection correctly can be complex depending on the CI platform.
    *   **How to avoid**: Refer to official documentation for your specific CI/CD tool. Start with a small number of shards and gradually increase.

## Interview Questions & Answers
1.  **Q: What is test sharding in Playwright, and why is it beneficial for large test suites?**
    **A:** Test sharding is the process of splitting a large test suite into smaller, independent subsets (shards) that can be executed in parallel. For large test suites, it's beneficial because it drastically reduces the overall test execution time, leading to faster feedback loops for developers, improved CI/CD efficiency, and better scalability of the testing process.

2.  **Q: How do you implement sharding in Playwright, both locally and in a CI/CD pipeline (e.g., GitHub Actions)?**
    **A:** Locally, you use the `--shard=N/M` CLI option (e.g., `npx playwright test --shard=1/2`). In a CI/CD pipeline, you leverage the platform's matrix job feature. For GitHub Actions, you'd define a `strategy.matrix` with a `shard` variable, and then run `npx playwright test --shard=${{ matrix.shard }}/M` in a parallel job, where `M` is the total number of shards.

3.  **Q: What are some best practices for effective test sharding with Playwright?**
    **A:** Best practices include keeping test files small and focused, using `fullyParallel: true` in `playwright.config.ts`, choosing an optimal number of shards (often matching CI agents), ensuring tests are independent (not relying on shared state), and having a strategy for aggregating test reports.

4.  **Q: Can you describe a common pitfall with test sharding and how you would mitigate it?**
    **A:** A common pitfall is unbalanced shards, where some shards take significantly longer to complete due to uneven distribution of test execution time. This can happen if some test files are much larger or more complex. To mitigate this, I would regularly analyze test execution times, break down large test files into smaller, more focused ones, and potentially use Playwright's `--list` command to understand test distribution.

## Hands-on Exercise
1.  **Set up a project**: Create a new Node.js project, install Playwright, and create a `playwright.config.ts` file.
2.  **Create multiple test files**: Develop at least 5-7 simple Playwright test files (e.g., `test-login.spec.ts`, `test-dashboard.spec.ts`, `test-settings.spec.ts`, etc.) each containing 2-3 tests. Ensure each test navigates to a different simple public URL (like those used in the example above) to make them distinct.
3.  **Local Sharding**: Run your test suite using `--shard=1/3`, `--shard=2/3`, and `--shard=3/3` separately. Observe which test files are executed in each shard.
4.  **CI/CD Configuration (Conceptual)**: Imagine you are using GitHub Actions. Write out the YAML configuration for a workflow that would execute your 5-7 test files across 3 parallel shards, similar to the example provided. Include steps for installing dependencies, running tests, and uploading reports.

## Additional Resources
-   **Playwright Documentation - Sharding**: [https://playwright.dev/docs/test-sharding](https://playwright.dev/docs/test-sharding)
-   **Playwright Blog - Parallel Testing**: [https://playwright.dev/blog/playwright-1-18#parallel-testing](https://playwright.dev/blog/playwright-1-18#parallel-testing)
-   **GitHub Actions - Matrix Strategy**: [https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
---
# playwright-5.7-ac6.md

# Playwright CI/CD Integration & Best Practices: Generate and Publish HTML Reports in CI

## Overview
Automated test reports are crucial for understanding test execution results, identifying failures, and maintaining a high-quality product. Playwright's built-in HTML reporter provides a rich, interactive, and user-friendly way to visualize test runs. This feature delves into how to configure Playwright to generate these HTML reports and, more importantly, how to publish them effectively within a Continuous Integration (CI) environment, enabling teams to easily access and review test outcomes without needing local execution. Integrating HTML reports into CI/CD pipelines significantly improves feedback loops and streamlines debugging.

## Detailed Explanation

Generating HTML reports with Playwright is straightforward. By default, Playwright includes an HTML reporter that creates a static HTML file (`index.html`) along with associated assets (CSS, JS) in a `playwright-report` directory. This report can be opened directly in a web browser.

The challenge in CI is making this report accessible to the entire team. This typically involves two main steps:
1.  **Configuring the HTML Reporter:** Ensuring Playwright generates the report in a predictable location.
2.  **Uploading the Report as a CI Artifact:** Storing the generated `playwright-report` directory as an artifact of the CI job.
3.  **Publishing the Report:** Making the artifact accessible, often by leveraging services like GitHub Pages, GitLab Pages, or dedicated artifact hosting solutions.

### Playwright Configuration (`playwright.config.ts`)

Playwright's configuration file (`playwright.config.ts` or `.js`) is where you specify reporters. The `html` reporter is usually enabled by default. You can explicitly configure it to ensure its behavior.

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['list'], // Console reporter
    ['html', { open: 'never', outputFolder: 'playwright-report' }] // HTML reporter
  ],
  use: {
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    // {
    //   name: 'firefox',
    //   use: { ...devices['Desktop Firefox'] },
    // },
    // {
    //   name: 'webkit',
    //   use: { ...devices['Desktop Safari'] },
    // },
  ],
});
```
-   `reporter: [['html', { open: 'never', outputFolder: 'playwright-report' }]]`: This line explicitly tells Playwright to use the HTML reporter.
    -   `open: 'never'`: Prevents the report from automatically opening in a browser after local test execution, which is desirable in a headless CI environment.
    -   `outputFolder: 'playwright-report'`: Specifies the directory where the report will be generated. This path is relative to the project root.

### CI Pipeline Integration (Example: GitHub Actions)

Once the report is generated, the next step is to upload it as a CI artifact. Most CI/CD platforms provide mechanisms for this.

```yaml
# .github/workflows/playwright.yml
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
    - name: Upload Playwright Report
      uses: actions/upload-artifact@v4
      if: always() # Upload report even if tests fail
      with:
        name: playwright-report
        path: playwright-report/
        retention-days: 30 # Keep artifact for 30 days
    - name: Deploy Playwright Report to GitHub Pages
      uses: peaceiris/actions-gh-pages@v4
      if: always() && github.ref == 'refs/heads/main' # Only deploy from main branch
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./playwright-report
        # Keep original history (useful if you have other content on gh-pages)
        # cname: example.com # Optional: if using custom domain
```
-   `actions/upload-artifact@v4`: This GitHub Action uploads the `playwright-report/` directory as an artifact named `playwright-report`. This artifact will be available on the GitHub Actions run page.
-   `peaceiris/actions-gh-pages@v4`: This action automates the deployment of content to GitHub Pages. It takes the `playwright-report` directory and publishes its contents, making the HTML report accessible via a URL (e.g., `https://<YOUR_USERNAME>.github.io/<YOUR_REPO_NAME>/`).

### CI Pipeline Integration (Example: GitLab CI)

```yaml
# .gitlab-ci.yml
stages:
  - test

playwright_tests:
  stage: test
  image: mcr.microsoft.com/playwright/python:v1.39.0-jammy # Or a node image if using JS/TS
  script:
    - npm ci # or pip install if using Python Playwright
    - npx playwright install --with-deps # if using JS/TS
    - npx playwright test
  artifacts:
    when: always # Always upload artifacts
    paths:
      - playwright-report/ # Upload the report directory
    expire_in: 30 days
  # Optional: GitLab Pages for publishing reports
  pages:
    stage: deploy # Or after test stage
    needs: ["playwright_tests"]
    script:
      - mv playwright-report/ public/ # GitLab Pages expects content in 'public' dir
    artifacts:
      paths:
        - public
      expire_in: 30 days
    only:
      - main # Only deploy from main branch
```
-   `artifacts`: This section defines which files and directories should be stored as job artifacts. `playwright-report/` is specified, making the report downloadable from the GitLab CI job page.
-   `pages`: This special job name in GitLab CI/CD is used to publish static websites to GitLab Pages. The `playwright-report` content needs to be moved to a `public` directory.

## Code Implementation
The `playwright.config.ts` example provided in the Detailed Explanation is a complete, runnable configuration. Below is a minimal example of a Playwright test and the full configuration that would generate the report.

**`playwright.config.ts`**:
```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Directory where tests are located
  testDir: './tests',
  // Run tests in files in parallel
  fullyParallel: true,
  // Fail the build on CI if you accidentally left test.only in the source code.
  forbidOnly: !!process.env.CI,
  // Retry on CI only
  retries: process.env.CI ? 2 : 0,
  // Opt out of parallel tests on CI.
  workers: process.env.CI ? 1 : undefined,
  // Configure reporters
  reporter: [
    ['list'], // Console output
    // HTML reporter configuration
    ['html', { 
      open: 'never', // Never open report automatically after tests, especially in CI
      outputFolder: 'playwright-report', // Directory for the HTML report
      // host: '0.0.0.0', // Optional: Host for the report server (local viewing)
      // port: 9223,    // Optional: Port for the report server (local viewing)
      // template: 'customTemplate.html' // Optional: Path to a custom HTML template
    }]
  ],
  // Shared settings for all projects
  use: {
    // Collect trace when retrying the first time.
    trace: 'on-first-retry',
    // Base URL to use in actions like `await page.goto('/')`.
    // baseURL: 'http://127.0.0.1:3000',
  },

  // Configure projects for different browsers/environments
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    // {
    //   name: 'firefox',
    //   use: { ...devices['Desktop Firefox'] },
    // },
    // {
    //   name: 'webkit',
    //   use: { ...devices['Desktop Safari'] },
    // },
  ],
});
```

**`./tests/example.spec.ts`**:
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

test('a failing test example', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  // This test is designed to fail to demonstrate reporting of failures
  await expect(page).toHaveTitle(/NonExistentTitle/); 
});
```

To run these locally and generate a report:
```bash
npx playwright test
npx playwright show-report # To open the generated report locally
```

## Best Practices
-   **Always Upload as Artifact:** Ensure your CI pipeline is configured to upload the `playwright-report` directory as an artifact, even if tests fail. This guarantees you always have access to the report for debugging.
-   **Automate Publishing:** Leverage CI/CD platform features (like GitHub Pages, GitLab Pages, Netlify, etc.) to automatically publish reports to a web-accessible URL. This makes sharing and reviewing results seamless for the entire team.
-   **Clean Up Old Reports:** Configure artifact retention policies to avoid accumulating excessive storage. Keep reports for a reasonable period (e.g., 30-90 days), depending on your needs.
-   **Secure Sensitive Data:** If your reports contain sensitive information (e.g., screenshots with personal data), ensure the publishing mechanism is adequately secured (e.g., private GitHub Pages, password-protected internal server).
-   **Integrate with Notifications:** Combine report publishing with CI/CD notifications (Slack, Teams, Email) to alert relevant stakeholders when new reports are available or when critical tests fail.
-   **Consider Custom Reports:** For highly specific needs, Playwright allows custom reporters. You might consider this if the default HTML report doesn't meet all your visualization requirements, but start with the default.

## Common Pitfalls
-   **Forgetting `open: 'never'`:** In CI, if `open: 'never'` is not set, Playwright might attempt to launch a browser to open the report, which will likely fail in a headless environment and cause your CI job to hang or error out.
-   **Incorrect `outputFolder` Path:** If the `outputFolder` in `playwright.config.ts` does not match the `path` specified in your CI artifact upload step, the report will not be found and uploaded.
-   **Permissions Issues:** Ensure your CI runner has the necessary write permissions to create the `playwright-report` directory and its contents, and read permissions to upload it.
-   **Missing Dependencies for Publishing:** If using GitHub Pages or similar, ensure the action or script has the necessary tokens and permissions to push content to the designated branch.
-   **Overwriting Reports:** If deploying to a single, static URL (e.g., `main` branch GitHub Pages), new reports will overwrite old ones. This is generally acceptable for "latest run" reports but might be a pitfall if you need historical reports accessible via unique URLs (consider tagging builds or using dynamic paths).

## Interview Questions & Answers
1.  **Q: Why is it important to publish test reports in a CI/CD pipeline?**
    **A:** Publishing test reports in CI/CD is crucial for several reasons:
    *   **Visibility & Transparency:** Provides immediate, centralized visibility into test results for all team members (developers, QAs, product managers).
    *   **Faster Feedback Loop:** Developers can quickly review failures, identify regressions, and address issues without needing to run tests locally.
    *   **Improved Collaboration:** Facilitates discussion around test failures and product quality.
    *   **Historical Analysis:** Allows tracking test health and stability over time, identifying flaky tests or recurring issues.
    *   **Auditability:** Provides a record of test execution for compliance and quality assurance.
2.  **Q: How would you make Playwright HTML reports accessible to non-technical stakeholders in a CI environment?**
    **A:** The best approach is to automate the deployment of these reports to a web-accessible static hosting service. This can be achieved by:
    *   Configuring Playwright to output reports to a specific folder (e.g., `playwright-report`).
    *   In the CI pipeline, after tests run, uploading this `playwright-report` folder as an artifact.
    *   Using a CI/CD integration (like GitHub Pages, GitLab Pages, or a custom script deploying to S3/Azure Blob Storage + CDN) to publish the contents of this artifact to a public or internally accessible URL. Non-technical stakeholders can then simply click a link to view the interactive HTML report in their browser.
3.  **Q: What considerations would you have for retaining test reports in CI?**
    **A:** Key considerations include:
    *   **Storage Costs:** Reports consume storage, so define a reasonable retention period (e.g., 30 days) to manage costs.
    *   **Historical Data Needs:** How long do you need to look back for trend analysis, debugging past releases, or compliance?
    *   **Performance:** A huge number of artifacts might slow down CI/CD platform interfaces.
    *   **Automation:** Ensure retention policies are automated within the CI platform rather than manual deletion.
    *   **Sensitive Data:** If reports contain sensitive data, retention policies must align with data privacy regulations.
4.  **Q: Describe how `actions/upload-artifact` and `peaceiris/actions-gh-pages` work together in GitHub Actions for publishing Playwright reports.**
    **A:**
    *   `actions/upload-artifact`: This action's primary role is to take files or directories generated during a CI job (like the `playwright-report` folder) and save them as job artifacts. These artifacts are linked to the specific workflow run and can be downloaded directly from the GitHub Actions UI. This ensures that the report files persist after the job finishes.
    *   `peaceiris/actions-gh-pages`: This action then takes the content of a specified directory (which would be the `playwright-report` in this case, often after being downloaded from a previous artifact step or if it's still present in the runner's workspace) and pushes it to a designated branch (typically `gh-pages`) of the repository. GitHub Pages automatically serves content from this branch as a static website, making the Playwright HTML report viewable via a URL. The actions typically run sequentially, ensuring the report is first generated and stored, then picked up for publishing.

## Hands-on Exercise

**Objective:** Set up a simple Playwright project, configure it to generate an HTML report, and integrate this into a GitHub Actions workflow that publishes the report to GitHub Pages.

**Steps:**
1.  **Initialize a Playwright Project:**
    *   Create a new directory: `mkdir playwright-ci-report && cd playwright-ci-report`
    *   Initialize npm: `npm init -y`
    *   Install Playwright: `npx playwright init --yes` (Choose TypeScript, add an example test)
2.  **Create a Failing Test:** Add a deliberately failing test to `tests/example.spec.ts` (as shown in the Code Implementation section) to ensure the report captures failures.
3.  **Configure Playwright:** Ensure your `playwright.config.ts` includes the HTML reporter with `open: 'never'` and `outputFolder: 'playwright-report'`.
4.  **Create GitHub Workflow:**
    *   Create the directory `.github/workflows/`.
    *   Create a file `playwright.yml` inside it.
    *   Copy the GitHub Actions workflow YAML from the "CI Pipeline Integration (Example: GitHub Actions)" section above into `playwright.yml`.
5.  **Commit and Push:**
    *   Initialize Git: `git init`
    *   Add all files: `git add .`
    *   Commit: `git commit -m "Initial Playwright project with CI reporting"`
    *   Create a new repository on GitHub and push your code to it.
6.  **Verify CI Run and Report:**
    *   Go to your GitHub repository -> Actions tab. Observe the workflow run.
    *   After the workflow completes (it should pass the test stage but potentially fail on deploy if GitHub Pages is not enabled or if using a feature branch), check the artifacts section for a `playwright-report`.
    *   Enable GitHub Pages for your repository (Settings -> Pages -> Branch `gh-pages` or `main` if directly deploying from main).
    *   Trigger another workflow run (e.g., by pushing an empty commit `git commit --allow-empty -m "Trigger CI"`).
    *   Once the `Deploy Playwright Report to GitHub Pages` step completes successfully, navigate to the URL provided by GitHub Pages (e.g., `https://<YOUR_USERNAME>.github.io/<YOUR_REPO_NAME>/`) to view your published Playwright HTML report.

## Additional Resources
-   **Playwright Reporters Documentation:** [https://playwright.dev/docs/test-reporters](https://playwright.dev/docs/test-reporters)
-   **GitHub Actions Documentation:** [https://docs.github.com/en/actions](https://docs.github.com/en/actions)
-   **GitHub Pages Documentation:** [https://docs.github.com/en/pages](https://docs.github.com/en/pages)
-   **peaceiris/actions-gh-pages:** [https://github.com/peaceiris/actions-gh-pages](https://github.com/peaceiris/actions-gh-pages)
-   **GitLab CI/CD Artifacts:** [https://docs.gitlab.com/ee/ci/pipelines/job_artifacts.html](https://docs.gitlab.com/ee/ci/pipelines/job_artifacts.html)
-   **GitLab Pages:** [https://docs.gitlab.com/ee/user/project/pages/](https://docs.gitlab.com/ee/user/project/pages/)
---
# playwright-5.7-ac7.md

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
---
# playwright-5.7-ac8.md

# Playwright 5.7: CI/CD Integration & Best Practices - Integrate with Docker for Consistent Test Environments

## Overview
Ensuring test consistency across different environments is a significant challenge in CI/CD pipelines. Docker provides a powerful solution by packaging applications and their dependencies into standardized units, called containers. This feature delves into integrating Playwright tests with Docker, enabling consistent and isolated test execution environments. By using Docker, we eliminate "it works on my machine" issues and ensure that tests run identically in development, staging, and production-like environments, thus improving reliability and reproducibility.

## Detailed Explanation
Integrating Playwright with Docker involves running your Playwright tests inside a Docker container. This container typically includes Node.js (or Python, Java, etc., depending on your test runner), Playwright dependencies, and the necessary browser binaries (Chromium, Firefox, WebKit).

The `mcr.microsoft.com/playwright` image is an official, pre-built Docker image provided by Microsoft that comes with all Playwright dependencies and browsers pre-installed. This significantly simplifies setup.

The workflow typically involves:
1.  **Choosing a Base Image**: Using `mcr.microsoft.com/playwright` as the base image.
2.  **Copying Test Code**: Adding your Playwright test project into the Docker image or mounting it as a volume. Mounting is preferred for faster iteration during development, as changes don't require rebuilding the image.
3.  **Installing Dependencies**: Installing any project-specific dependencies (e.g., `npm install` or `pnpm install`).
4.  **Running Tests**: Executing your Playwright test command within the container.
5.  **Handling Artifacts**: Ensuring test reports, screenshots, or videos generated by Playwright are accessible outside the container, usually by mounting a volume for output.

**Why is this important for SDETs?**
-   **Environment Consistency**: Guarantees that tests run in the exact same environment every time, regardless of the host machine's configuration.
-   **Isolation**: Tests run in an isolated container, preventing conflicts with other applications or system-level dependencies.
-   **Reproducibility**: Easy to reproduce test failures by running the same container locally or in CI.
-   **Scalability**: Docker containers are lightweight and can be easily scaled up in CI/CD systems to run tests in parallel.
-   **Simplified Setup**: New team members can get started quickly without complex local environment configurations.

## Code Implementation

Below is an example of a `Dockerfile`, a `package.json` for a simple Playwright project, and commands to build and run tests within a Docker container.

### `Dockerfile`
This `Dockerfile` uses the official Playwright image, copies your project, installs dependencies, and defines the command to run tests.

```dockerfile
# Use the official Playwright image as the base
# This image comes with Node.js and all Playwright browsers pre-installed
FROM mcr.microsoft.com/playwright:v1.41.2-jammy

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock, pnpm-lock.yaml) to install dependencies
# This step is cached as long as package.json doesn't change
COPY package*.json ./

# Install project dependencies
# Using --frozen-lockfile for pnpm or npm ci for npm to ensure reproducible builds
# If using npm: RUN npm ci
RUN pnpm install --frozen-lockfile

# Copy the rest of your Playwright project files into the container
COPY . .

# Command to run tests (e.g., using Playwright Test Runner)
# This will be the default command executed when the container starts
CMD ["pnpm", "playwright", "test"]

# Expose ports if your tests involve a web server inside the container, e.g., for visual regression
# EXPOSE 3000
```

### `playwright.config.ts` (Example)
A basic Playwright configuration.

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
  use: {
    baseURL: 'http://localhost:8080', // Adjust if tests hit an external URL or a server inside Docker
    trace: 'on-first-retry',
    // headless: false, // In Docker, headless is usually preferred
  },
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
  ],
});
```

### `tests/example.spec.ts` (Example Test)
A simple test to demonstrate.

```typescript
// tests/example.spec.ts
import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  await expect(page).toHaveTitle(/Playwright/);
});

test('get started link', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  await page.getByRole('link', { name: 'Get started' }).click();
  await expect(page).toHaveURL(/.*intro/);
});
```

### Build and Run Commands

1.  **Build the Docker Image**:
    Navigate to your project root (where `Dockerfile` and `package.json` are) and run:
    ```bash
    docker build -t playwright-tests:latest .
    ```
    This command builds a Docker image named `playwright-tests` with the tag `latest`.

2.  **Run Tests Inside the Container (Method 1: Using `docker run` directly)**:
    ```bash
    # For a project where tests are copied into the image
    docker run playwright-tests:latest

    # To mount your local project directory as a volume (for faster development cycles)
    # And to get test results (e.g., HTML report) out of the container
    docker run -v "$(pwd):/app" playwright-tests:latest
    ```
    -   `docker run -v "$(pwd):/app"`: This mounts your current working directory (`$(pwd)`) on the host machine to the `/app` directory inside the container. This means any changes you make to your local files are immediately reflected in the container without rebuilding the image. It also makes Playwright reports available on your host machine.

3.  **Run Specific Tests or Pass Arguments**:
    You can override the `CMD` in `Dockerfile` or append arguments:
    ```bash
    docker run -v "$(pwd):/app" playwright-tests:latest pnpm playwright test tests/specific.spec.ts --project=chromium
    ```

## Best Practices
-   **Use Official Images**: Always prefer official images like `mcr.microsoft.com/playwright` as they are maintained, secure, and optimized.
-   **Mount Volumes for Code & Reports**: For development and CI, mount your project directory as a volume (`-v $(pwd):/app`). This avoids image rebuilds on code changes and makes test reports accessible on the host.
-   **Layer Caching**: Structure your `Dockerfile` to leverage Docker's build cache. Place steps that change less frequently (e.g., `COPY package*.json`, `pnpm install`) earlier.
-   **Resource Limits**: In CI, configure resource limits (CPU, memory) for your Docker containers to prevent tests from monopolizing resources.
-   **Non-Root User**: Run containers with a non-root user for enhanced security (though `mcr.microsoft.com/playwright` often defaults to a non-root user).
-   **Handle Timezones**: Playwright tests involving dates might be affected by container timezones. Set `TZ` environment variable if needed.
-   **Clean Up**: Ensure your CI pipeline cleans up Docker containers and images after test execution to free up resources.
-   **Screenshot/Video Management**: Configure Playwright to output artifacts to a mounted volume so they can be archived or analyzed post-execution.

## Common Pitfalls
-   **Missing Dependencies**: Forgetting to `pnpm install` (or `npm install`) project-specific dependencies within the Dockerfile. The Playwright image only provides Playwright's own dependencies.
-   **Volume Mounting Issues**: Incorrectly mounting volumes, leading to tests not finding code or reports not being saved outside the container. Double-check paths.
-   **Headless Mode**: Forgetting that browsers in Docker typically run in headless mode. If you explicitly set `headless: false` in `playwright.config.ts`, it might fail without a display server (Xvfb is often used, but the Playwright Docker image usually handles this). It's generally best to let Playwright's Docker image manage headless settings.
-   **Network Issues**: If tests need to access services running on the host machine, `localhost` inside the container won't work. Use `host.docker.internal` (Docker Desktop) or configure `--network host` (Linux). For services within other Docker containers, use Docker Compose networks.
-   **Timeouts**: Tests might time out due to slower performance in a containerized environment, especially on resource-constrained CI agents. Adjust Playwright timeouts (`playwright.config.ts`).
-   **Large Image Size**: Adding unnecessary files to the image can bloat its size. Use a `.dockerignore` file similar to `.gitignore` to exclude non-essential files.

## Interview Questions & Answers
1.  **Q: Why would an SDET choose to run Playwright tests in Docker containers?**
    A: Running Playwright tests in Docker ensures environment consistency across all stages (developer machine, CI/CD, staging). It isolates tests from host system variations, making them more reliable and reproducible. This helps eliminate "works on my machine" issues, simplifies onboarding for new team members, and provides a scalable way to run tests in parallel within CI/CD pipelines.

2.  **Q: How do you ensure test reports and artifacts (screenshots, videos) generated inside a Docker container are accessible after the container stops?**
    A: By using Docker volume mounts. When running the container, we can mount a host directory to a directory inside the container (e.g., `docker run -v "$(pwd)/test-results:/app/test-results" ...`). Playwright is then configured to save its reports and artifacts to the mounted directory (`/app/test-results` in this example), making them persistent and accessible on the host machine even after the container exits.

3.  **Q: What is `mcr.microsoft.com/playwright` and why is it beneficial for Playwright Docker integration?**
    A: `mcr.microsoft.com/playwright` is the official Docker image provided by Microsoft for Playwright. It's beneficial because it comes pre-installed with Node.js, Playwright, and all necessary browser binaries (Chromium, Firefox, WebKit), as well as their system dependencies. This eliminates the need for manual installation and configuration of these components in the Dockerfile, significantly simplifying the setup process and ensuring a consistent, tested environment.

4.  **Q: Describe a common problem encountered when running Playwright tests in Docker and how you would troubleshoot it.**
    A: A common problem is tests failing due to an inability to connect to a web application under test, especially if that application is running on the *host* machine. Inside the Docker container, `localhost` refers to the container itself, not the host. To troubleshoot, I'd first check network configurations. If using Docker Desktop, I'd try `host.docker.internal` as the application's URL. On Linux, I might use `--network host` when running the Docker container. If the application is another Docker container, I'd ensure both are on the same Docker network.

## Hands-on Exercise

**Objective**: Containerize a simple Playwright test suite and execute it using Docker, ensuring that test reports are available on your local machine.

**Steps**:

1.  **Prerequisites**:
    *   Docker installed and running on your machine.
    *   Node.js and Playwright installed locally (for initial project setup, though Docker will handle execution).
    *   A directory named `my-playwright-docker-project`.

2.  **Initialize Playwright Project**:
    *   Inside `my-playwright-docker-project`, initialize a new Playwright project:
        ```bash
        npm init playwright@latest . -- --yes --typescript
        ```
    *   Accept the defaults. This will create `playwright.config.ts`, `package.json`, and an `example.spec.ts` test file.

3.  **Create `Dockerfile`**:
    *   In the root of `my-playwright-docker-project`, create a `Dockerfile` with the content provided in the "Code Implementation" section above.

4.  **Build the Docker Image**:
    *   Navigate to `my-playwright-docker-project` in your terminal.
    *   Build the image:
        ```bash
        docker build -t my-playwright-app:latest .
        ```
    *   Verify the image exists: `docker images`

5.  **Run Tests with Volume Mount**:
    *   Create a directory for test results: `mkdir test-results` (this will be mounted)
    *   Run the tests, mounting your current project directory and the `test-results` folder:
        ```bash
        docker run -v "$(pwd):/app" -v "$(pwd)/test-results:/app/test-results" my-playwright-app:latest
        ```
    *   Observe the test execution in your terminal.

6.  **Verify Reports**:
    *   After the container finishes, check the `test-results` directory on your host machine. You should find the Playwright HTML report (e.g., `index.html`) and potentially screenshots or videos.
    *   Open `test-results/index.html` in your browser to view the report.

**Expected Outcome**: Playwright tests should execute successfully within the Docker container, and an HTML test report should be generated and accessible from your local `test-results` directory.

## Additional Resources
-   **Playwright Official Docker Documentation**: [https://playwright.dev/docs/docker](https://playwright.dev/docs/docker)
-   **mcr.microsoft.com/playwright on Docker Hub**: [https://hub.docker.com/_/microsoft-playwright](https://hub.docker.com/_/microsoft-playwright)
-   **Dockerizing a Node.js web app**: [https://docs.docker.com/language/nodejs/build-images/](https://docs.docker.com/language/nodejs/build-images/)
-   **Playwright CI/CD Examples (GitHub Actions, GitLab CI, Azure Pipelines)**: [https://playwright.dev/docs/ci](https://playwright.dev/docs/ci)
---
# playwright-5.7-ac9.md

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
