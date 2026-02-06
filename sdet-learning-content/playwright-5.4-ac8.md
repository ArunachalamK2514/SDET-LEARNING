# Playwright: Skipping and Focusing Tests (`test.skip()`, `test.only()`, `test.fixme()`)

## Overview
In Playwright, efficiently managing test execution is crucial for rapid development and effective debugging. The `test.skip()`, `test.only()`, and `test.fixme()` methods provide powerful mechanisms to control which tests run, allowing developers and SDETs to focus on specific tests, temporarily disable failing ones, or mark tests that need attention for future repairs. These features are indispensable for maintaining productivity in large test suites.

## Detailed Explanation

### `test.only()`: Focusing on Specific Tests
During development or debugging, you often need to run only a subset of your tests. `test.only()` allows you to mark a specific test or a describe block to be the *only* one executed. All other tests in your suite will be skipped. This is particularly useful when you're working on a new feature, fixing a bug, or trying to isolate a flaky test.

**When to use:**
- Debugging a failing test in isolation.
- Developing a new test and wanting to run only that test repeatedly.
- Focusing on a specific feature's tests.

### `test.skip()`: Temporarily Skipping Tests
`test.skip()` is used to temporarily disable a test or an entire test suite (`describe` block). This is common when a test is known to be failing due to a bug in the application that hasn't been fixed yet, or when a feature is temporarily disabled. Skipping tests ensures that your CI/CD pipeline doesn't break due to known, but not yet resolved, issues. You can also conditionally skip tests based on environment, browser, or operating system.

**When to use:**
- A known application bug makes a test fail, and the bug is not yet fixed.
- A feature is under development or temporarily disabled, rendering its tests irrelevant for now.
- Skipping tests on specific browsers or operating systems where they are not applicable or consistently failing.

### `test.fixme()`: Marking Tests for Repair
`test.fixme()` is a specialized skip method that explicitly marks a test as "expected to fail" or "needs repair." When a test is marked with `test.fixme()`, Playwright will execute it. If the test passes, Playwright will report it as a failure, indicating that the test no longer needs to be marked as `fixme` and should be fixed or un-skipped. If it fails, it reports as `skipped` without breaking the build. This is ideal for tests that are currently broken but are actively being worked on or are high priority to fix.

**When to use:**
- Tests that are currently failing due to issues in the test code itself or a high-priority application bug that needs immediate attention.
- Communicating to team members that a specific test is broken and needs to be fixed.

## Code Implementation

Let's demonstrate these concepts with a Playwright test file.

```typescript
// example.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Test Skipping and Focusing Features', () => {

  // This test will be the ONLY one that runs if 'test.only' is uncommented
  // test.only('should log in a user successfully', async ({ page }) => {
  test('should log in a user successfully', async ({ page }) => {
    console.log('Running: should log in a user successfully');
    await page.goto('https://www.example.com/login');
    await page.fill('#username', 'testuser');
    await page.fill('#password', 'password123');
    await page.click('#login-button');
    await expect(page).toHaveURL(/.*dashboard/);
    console.log('Completed: should log in a user successfully');
  });

  // This test will be skipped
  test.skip('should handle invalid login credentials', async ({ page }) => {
    console.log('Running: should handle invalid login credentials (this should not appear)');
    await page.goto('https://www.example.com/login');
    await page.fill('#username', 'invalid');
    await page.fill('#password', 'wrong');
    await page.click('#login-button');
    await expect(page.locator('.error-message')).toHaveText('Invalid credentials');
    console.log('Completed: should handle invalid login credentials (this should not appear)');
  });

  // This test will be marked for future repair.
  // Playwright will execute it, and if it passes, it will report it as a failure.
  test.fixme('should display product details correctly', async ({ page }) => {
    console.log('Running: should display product details correctly (fixme)');
    await page.goto('https://www.example.com/products/1');
    // Simulate a test that is expected to fail or has not been fully implemented
    await expect(page.locator('#product-title')).toHaveText('Broken Product Title', { timeout: 100 }); // This will likely fail
    console.log('Completed: should display product details correctly (fixme)');
  });

  // Conditional skipping based on environment or browser
  test('should work only on Chromium', async ({ browserName }) => {
    test.skip(browserName !== 'chromium', 'Feature is specific to Chromium');
    console.log(`Running: should work only on Chromium on ${browserName}`);
    // Test steps specific to Chromium
    expect(browserName).toBe('chromium');
    console.log(`Completed: should work only on Chromium on ${browserName}`);
  });

  test.describe('Navigation tests', () => {
    // This entire describe block will be skipped if uncommented
    // test.skip(true, 'Navigation features are unstable');

    test('should navigate to about page', async ({ page }) => {
      console.log('Running: should navigate to about page');
      await page.goto('https://www.example.com');
      await page.click('text=About');
      await expect(page).toHaveURL(/.*about/);
      console.log('Completed: should navigate to about page');
    });

    // test.only inside a describe block will only run this test, skipping others in the same describe and other describe blocks
    // test.only('should navigate to contact page', async ({ page }) => {
    test('should navigate to contact page', async ({ page }) => {
      console.log('Running: should navigate to contact page');
      await page.goto('https://www.example.com');
      await page.click('text=Contact');
      await expect(page).toHaveURL(/.*contact/);
      console.log('Completed: should navigate to contact page');
    });
  });
});

/*
To run these tests:
1. Save the code as `example.spec.ts` in your Playwright project's `tests` directory.
2. Run `npx playwright test example.spec.ts` from your terminal.

Experiment by:
- Uncommenting `test.only` on line 9 and observing that only that test runs.
- Removing `test.skip` on line 19 and seeing it fail (if example.com doesn't have that element).
- Observing the `test.fixme` behavior, especially if you make it pass.
*/
```

## Best Practices
- **Use `test.only()` sparingly and locally:** It's a debugging tool, not something to commit to version control. Always ensure `test.only()` is removed before pushing changes.
- **Provide clear reasons for `test.skip()`:** Add a comment or a message to `test.skip()` explaining *why* the test is skipped (e.g., `test.skip('Bug #1234: Login button sometimes unresponsive')`).
- **Regularly review `test.skip()` and `test.fixme()`:** These tests represent known issues or incomplete work. They should be revisited periodically to ensure they are either fixed or still relevant to be skipped/fixed.
- **Conditional skipping for environment differences:** Use `test.skip(process.env.CI === 'true', 'This test is flaky in CI')` or `test.skip(browserName === 'webkit', 'Feature not supported on WebKit')` to manage environment-specific test behavior.
- **Prioritize fixing `test.fixme()` tests:** Treat `test.fixme()` as a temporary state for tests that are broken but need immediate attention. A passing `test.fixme()` should prompt you to fix the underlying issue or the test itself.

## Common Pitfalls
- **Committing `test.only()`:** Accidentally committing `test.only()` can lead to missed test coverage in CI/CD pipelines, giving a false sense of security. Always double-check before committing.
- **Overusing `test.skip()`:** Too many skipped tests can hide regressions and indicate a poorly maintained test suite. Use it judiciously and only for well-justified reasons.
- **Ignoring `test.fixme()` warnings:** If a `test.fixme()` test starts passing, Playwright will report it as a failure. Ignoring this warning means you're missing an opportunity to re-enable a functional test and potentially uncover new issues.
- **Lack of context for skipped tests:** Without a good reason, `test.skip()` can be confusing for other team members and make it hard to determine if the skip is still valid.

## Interview Questions & Answers

1.  **Q: Explain the difference between `test.skip()` and `test.fixme()` in Playwright. When would you use each?**
    **A:** `test.skip()` is used to prevent a test from running entirely, typically when there's a known, unresolved issue (e.g., an application bug) or when a feature is temporarily unavailable. It's for tests that you *don't want* to run for now. `test.fixme()`, on the other hand, marks a test as "expected to fail" or "needs repair." Playwright *will execute* `test.fixme()` tests. If a `fixme` test fails, it's reported as skipped (without failing the build). Crucially, if a `fixme` test *passes*, Playwright will report it as a *failure*, indicating that the test's underlying issue is resolved and it should no longer be marked `fixme`. You'd use `test.skip()` for stable but currently irrelevant/failing tests due to external factors, and `test.fixme()` for tests that are broken but are actively being worked on or need immediate repair, leveraging its built-in mechanism to alert you when the test becomes healthy.

2.  **Q: How do you ensure `test.only()` doesn't get committed to your repository?**
    **A:** The primary way is through developer discipline and code review processes. Developers should always remove `test.only()` before staging and committing their changes. Automated tools like pre-commit hooks (e.g., using Husky and lint-staged) can be configured to detect `test.only()` statements in staged files and prevent the commit, or even automatically remove them. Continuous Integration (CI) pipelines can also include checks to fail builds if `test.only()` is found in any pushed code.

3.  **Q: Can you conditionally skip tests in Playwright? Provide an example scenario.**
    **A:** Yes, you can conditionally skip tests using `test.skip()` with a condition. An example scenario is when a particular feature or UI element behaves differently or is completely absent on a specific browser or operating system.
    ```typescript
    test('should only run on Windows', async ({ page, browserName, platform }) => {
      // Assuming 'platform' is accessible via a custom fixture or environment variable
      test.skip(platform !== 'win32', 'This test is specific to Windows OS');
      // Test steps for Windows-specific functionality
      await page.goto('https://example.com/windows-feature');
      await expect(page.locator('#windows-specific-element')).toBeVisible();
    });

    test('should skip on WebKit browsers', async ({ browserName }) => {
      test.skip(browserName === 'webkit', 'WebKit has known rendering issues with this component');
      // Test steps that might fail on WebKit
      await page.goto('https://example.com/complex-component');
      await expect(page.locator('.complex-animation')).toBeVisible();
    });
    ```
    This helps maintain a healthy test suite by avoiding unnecessary failures on platforms where tests are not expected to pass.

## Hands-on Exercise

**Scenario:** You are working on a new e-commerce application. A critical product search feature has a known bug (`BUG-5432`) where search results are sometimes empty when filtering by "out of stock" items. Additionally, a new "guest checkout" feature is under active development and its tests are currently unstable.

**Task:**
1.  Create a Playwright test file (e.g., `ecommerce.spec.ts`).
2.  Write a test for the "product search with 'out of stock' filter" feature. Mark this test to be skipped due to `BUG-5432`.
3.  Write a test for the "guest checkout" feature. Mark this test as `fixme` because it's unstable and needs repair.
4.  Write a test for a "user registration" feature. Temporarily use `test.only()` on this test to simulate focusing on it during development.
5.  Run your tests and observe the output. Ensure only the "user registration" test runs (initially), and then adjust to see the skipped and fixme behavior correctly reported.

**Expected Output (after removing `test.only()` and running all tests):**
- "product search with 'out of stock' filter" should be skipped.
- "guest checkout" should be reported as `skipped` (if it fails) or `failed` (if it passes unexpectedly).
- "user registration" should pass.

## Additional Resources
- **Playwright Test Configuration:** [https://playwright.dev/docs/test-configuration#test-filtering](https://playwright.dev/docs/test-configuration#test-filtering)
- **Playwright `test.only` and `test.skip`:** [https://playwright.dev/docs/api/class-test#test-only](https://playwright.dev/docs/api/class-test#test-only)
- **Playwright `test.fixme`:** [https://playwright.dev/docs/api/class-test#test-fixme](https://playwright.dev/docs/api/class-test#test-fixme)
