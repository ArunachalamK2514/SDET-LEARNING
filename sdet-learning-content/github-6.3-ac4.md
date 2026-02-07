# GitHub Actions: Test Execution Matrix for Multiple Browsers/Environments

## Overview
In modern software development, ensuring an application works correctly across various browsers and environments is crucial for quality assurance. Manually testing every combination is time-consuming and prone to human error. GitHub Actions provides a powerful feature called `strategy.matrix` that allows you to define a set of different configurations (e.g., operating systems, Node.js versions, browser types) and run your jobs against each combination in parallel. This significantly speeds up testing cycles and increases test coverage, making your CI/CD pipeline more robust and efficient. For SDETs, mastering the test matrix is essential for building scalable and comprehensive test automation frameworks.

## Detailed Explanation
The `strategy.matrix` feature in GitHub Actions enables you to run the same job multiple times with different variables. This is particularly useful for test automation where you might want to execute your tests against:
*   Different browser versions (Chrome, Firefox, Edge, Safari).
*   Various operating systems (Ubuntu, Windows, macOS).
*   Multiple Node.js or Python versions.
*   Different environment configurations (staging, production-like).

When you define a matrix, GitHub Actions creates a separate job for each possible combination of the variables you specify. These jobs then run in parallel, dramatically reducing the overall execution time compared to running them sequentially.

### How to Define and Use `strategy.matrix`

1.  **Define `strategy.matrix`**: Within a job, you define `strategy` and then `matrix`. Inside `matrix`, you specify variables as key-value pairs. Each value can be a list, and GitHub Actions will iterate through all possible combinations.

    ```yaml
    jobs:
      build-and-test:
        runs-on: ubuntu-latest
        strategy:
          matrix:
            browser: [chrome, firefox] # Define browser types
            os: [ubuntu-latest, windows-latest] # Define operating systems
    ```

2.  **Access Matrix Variables**: You can access these matrix variables within your job steps using the `${{ matrix.<variable_name> }}` syntax.

    ```yaml
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        run: npm ci

      - name: Run Playwright tests on ${{ matrix.browser }} on ${{ matrix.os }}
        run: npx playwright test --project=${{ matrix.browser }}
        env:
          BROWSER: ${{ matrix.browser }} # Example: pass browser to test script via environment variable
    ```

    In this example, for each combination of `browser` and `os`, a separate job will be created. The `Run Playwright tests` step will use the `browser` variable to specify which browser Playwright should run tests on.

### Practical Example with Playwright

Let's assume you have Playwright tests configured to run on different browsers based on the `--project` flag or an environment variable.

**Playwright Configuration (playwright.config.ts):**

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

**GitHub Actions Workflow (.github/workflows/playwright.yml):**

```yaml
name: Playwright Tests Matrix

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  test:
    timeout-minutes: 60
    runs-on: ${{ matrix.os }} # Use OS from matrix
    strategy:
      fail-fast: false # Allows other matrix jobs to complete even if one fails
      matrix:
        os: [ubuntu-latest, windows-latest] # Test on Ubuntu and Windows
        browser: [chromium, firefox, webkit] # Test on Chrome, Firefox, Webkit

    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: 20
    - name: Install dependencies
      run: npm ci
    - name: Install Playwright Browsers
      run: npx playwright install --with-deps
    - name: Run Playwright tests on ${{ matrix.browser }} on ${{ matrix.os }}
      run: npx playwright test --project=${{ matrix.browser }} # Use matrix variable
    - uses: actions/upload-artifact@v4
      if: always()
      with:
        name: playwright-report-${{ matrix.browser }}-${{ matrix.os }}
        path: playwright-report/
        retention-days: 30
```

This workflow will generate `2 (OS) * 3 (Browsers) = 6` parallel jobs, each running Playwright tests on a specific browser and operating system combination.

## Best Practices
*   **Keep Matrix Variables Focused**: Only include variables that genuinely impact the test execution or environment. Avoid over-complicating your matrix with unnecessary combinations.
*   **Use `fail-fast: false`**: For test matrices, `fail-fast: false` is often preferable. This ensures that even if one combination fails, other combinations continue to run, providing a more complete picture of what passed and what failed across your matrix.
*   **Combine with `include` and `exclude`**: For more complex scenarios, you can use `matrix.include` to add specific combinations not covered by the main matrix, or `matrix.exclude` to skip specific combinations that are known to be incompatible or unnecessary.
*   **Optimize for Parallelism**: Ensure your test suite can run efficiently in parallel. Large, interdependent tests can lead to bottlenecks.
*   **Artifact Uploads**: Configure artifact uploads to differentiate reports based on matrix variables (e.g., `playwright-report-${{ matrix.browser }}-${{ matrix.os }}`). This makes it easier to analyze results for specific combinations.

## Common Pitfalls
*   **Too Many Combinations**: A matrix with too many variables can quickly lead to an explosion in the number of jobs, consuming excessive CI/CD resources and time. Be mindful of the number of combinations you create.
*   **Incompatible Combinations**: Sometimes, certain matrix combinations might be invalid or not supported (e.g., a specific browser version on an old OS). Use `matrix.exclude` to prevent these from running.
*   **Hardcoded Values**: Avoid hardcoding browser names or environment details in your test scripts. Instead, pass them via environment variables or CLI arguments and use the matrix variables in your workflow to configure them.
*   **Shared Resources**: If matrix jobs rely on shared external resources, ensure these resources can handle concurrent access without issues.
*   **Debugging Matrix Failures**: Debugging failures in a matrix can be challenging. Ensure your logging is comprehensive and artifact uploads (e.g., screenshots, videos, detailed reports) are configured to help pinpoint issues for specific combinations.

## Interview Questions & Answers
1.  **Q: What is a test execution matrix in CI/CD, and why is it important for SDETs?**
    A: A test execution matrix in CI/CD (like GitHub Actions `strategy.matrix`) allows you to define multiple configurations (e.g., different browsers, operating systems, environment variables) and run your tests against all possible combinations in parallel. It's crucial for SDETs because it ensures broader test coverage across diverse environments, significantly reduces overall test execution time, and helps identify environment-specific bugs earlier in the development cycle, leading to more robust and reliable software.

2.  **Q: How would you set up a GitHub Actions workflow to run Playwright tests across Chrome, Firefox, and Webkit on both Ubuntu and Windows?**
    A: I would define a `strategy.matrix` within my test job. The matrix would have two variables: `os: [ubuntu-latest, windows-latest]` and `browser: [chromium, firefox, webkit]`. In the step that executes Playwright tests, I would use `${{ matrix.browser }}` to pass the browser type to Playwright's CLI (e.g., `npx playwright test --project=${{ matrix.browser }}`). This setup would generate 6 parallel jobs, covering all specified browser and OS combinations.

3.  **Q: What are some considerations or best practices when designing a test matrix to avoid common pitfalls?**
    A: Key considerations include:
    *   **Limiting Combinations**: Avoid an excessive number of combinations to prevent high resource consumption and long run times. Prioritize the most critical environments.
    *   **Using `fail-fast: false`**: This ensures that a failure in one matrix job doesn't stop others, allowing for a more complete overview of test results.
    *   **Excluding Incompatible Combinations**: Use `matrix.exclude` for combinations that are known to be problematic or unnecessary.
    *   **Parameterized Tests**: Ensure test scripts are parameterized to accept browser/environment details dynamically, often through environment variables or CLI arguments, rather than hardcoding values.
    *   **Effective Reporting**: Configure artifact uploads with matrix variables in their names to easily distinguish and analyze reports from different combinations.

## Hands-on Exercise
**Objective**: Create a GitHub Actions workflow that executes a simple test script across two different Node.js versions and two different operating systems.

**Instructions**:
1.  **Create a test script**: Create a file named `test.js` in your repository root with the following content:
    ```javascript
    // test.js
    console.log(`Running test on Node.js version: ${process.version}`);
    console.log(`Running test on OS: ${process.platform}`);
    if (Math.random() < 0.1) { // Simulate occasional failure
      console.error("Simulated test failure!");
      process.exit(1);
    }
    console.log("Test passed!");
    ```
2.  **Create a GitHub Actions workflow**: Create a file named `.github/workflows/matrix-exercise.yml` with a job that uses `strategy.matrix` to run `test.js` on:
    *   `node-version: [18, 20]`
    *   `os: [ubuntu-latest, windows-latest]`
3.  **Verify**: Push the workflow to GitHub and observe the separate jobs spawned for each combination. Check the logs to ensure the correct Node.js version and OS are reported.

## Additional Resources
*   **GitHub Actions Workflow Syntax**: [https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstrategymatrix](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstrategymatrix)
*   **Using a matrix for your jobs**: [https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstrategymatrix](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstrategymatrix)
*   **Playwright Test Documentation**: [https://playwright.dev/docs/intro](https://playwright.dev/docs/intro)