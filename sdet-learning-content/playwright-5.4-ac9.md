# Playwright Test Annotations and Attachments with `test.info()`

## Overview
In Playwright, `test.info()` provides a powerful mechanism to enrich your test reports with custom metadata, annotations, and attached files. This is crucial for improving the traceability, debuggability, and overall understanding of test execution, especially in complex test suites or CI/CD pipelines. By adding context-specific information, you can make your HTML reports more informative, helping teams quickly grasp what happened during a test run, why a test might have failed, or to categorize tests more effectively.

Annotations allow you to tag tests with arbitrary key-value pairs (e.g., `severity`, `jira`, `owner`), while attachments enable you to link files (screenshots, videos, logs, network data) directly to test results.

## Detailed Explanation
`test.info()` returns an object that provides access to various test run properties and methods for adding supplementary data. The two primary methods for this feature are:

1.  **`test.info().annotations.push({ type: '...', description?: '...' })`**: This method allows you to add custom annotations to a test. An annotation is a simple object with a `type` (required string) and an optional `description` (string). These annotations can be used for various purposes such as:
    *   **Categorization**: Mark tests as `smoke`, `regression`, `e2e`, `performance`.
    *   **Metadata**: Add `jira` ticket IDs, `owner` names, or `severity` levels.
    *   **Conditional Logic**: In custom reporters, you could potentially use these annotations to filter or process tests differently.

2.  **`test.info().attach(name: string, options: { path?: string, body?: string | Buffer, contentType?: string })`**: This method is used to attach files or data directly to the test report. When a test fails, attaching relevant artifacts like screenshots, videos, or network logs is invaluable for debugging. Playwright automatically attaches screenshots and videos on failure by default, but `test.info().attach()` gives you explicit control to attach custom data at any point in your test.
    *   `name`: A unique name for the attachment. This will appear in the report.
    *   `path`: (Optional) Path to a file on the file system to attach. Playwright will copy this file to the report directory.
    *   `body`: (Optional) The content of the attachment as a string or Buffer. Useful for attaching small text logs or JSON data directly without creating a file.
    *   `contentType`: (Optional) The MIME type of the attachment (e.g., `'image/png'`, `'text/plain'`, `'application/json'`). This helps the report viewer render the content appropriately.

These annotations and attachments are then visible in the Playwright HTML report, providing a comprehensive view of each test's execution context and outcomes.

## Code Implementation
Here's a complete Playwright test file demonstrating how to use `test.info().annotations.push()` and `test.info().attach()`.

```typescript
// tests/example.spec.ts
import { test, expect } from '@playwright/test';
import { writeFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';

// Define a directory for test artifacts
const ARTIFACTS_DIR = './test-artifacts';
if (!existsSync(ARTIFACTS_DIR)) {
  mkdirSync(ARTIFACTS_DIR);
}

test.describe('User Profile Management', () => {

  test('should allow user to update their profile information with high severity', async ({ page }, testInfo) => {
    // Add custom annotations
    testInfo.annotations.push({ type: 'feature', description: 'User Profile' });
    testInfo.annotations.push({ type: 'severity', description: 'High' });
    testInfo.annotations.push({ type: 'jira', description: 'PROJ-1234' });

    // Simulate navigating to a profile page
    await page.goto('https://example.com/profile'); // Replace with a real URL for a runnable test

    // Attach a simulated log file
    const logContent = `[${new Date().toISOString()}] Navigated to profile page.
`;
    const logFilePath = join(ARTIFACTS_DIR, `profile-update-${testInfo.testId}.log`);
    writeFileSync(logFilePath, logContent);
    testInfo.attach('profile-log', { path: logFilePath, contentType: 'text/plain' });

    // Simulate filling out a form
    await page.fill('#username', 'new_username');
    await page.fill('#email', 'new_email@example.com');

    // Attach form data as JSON directly
    const formData = {
      username: 'new_username',
      email: 'new_email@example.com',
      timestamp: new Date().toISOString()
    };
    testInfo.attach('form-data', { body: JSON.stringify(formData, null, 2), contentType: 'application/json' });

    // Simulate saving changes
    await page.click('#saveButton');

    // Add another log entry after interaction
    const postActionLogContent = `[${new Date().toISOString()}] Profile update initiated.
`;
    writeFileSync(logFilePath, postActionLogContent, { flag: 'a' }); // Append to the log
    testInfo.attach('profile-update-after-action-log', { path: logFilePath, contentType: 'text/plain' }); // Re-attach with updated content if necessary, or a new name

    // Take a screenshot of the updated profile (Playwright usually does this on failure)
    // You can explicitly take and attach it for specific test steps or success cases
    const screenshotPath = join(ARTIFACTS_DIR, `profile-updated-${testInfo.testId}.png`);
    await page.screenshot({ path: screenshotPath });
    testInfo.attach('profile-updated-screenshot', { path: screenshotPath, contentType: 'image/png' });

    // Assertions
    await expect(page.locator('.success-message')).toHaveText('Profile updated successfully!');
    // If the test fails, these attachments will be available in the report.
  });

  test('should handle invalid email format during profile update', async ({ page }, testInfo) => {
    testInfo.annotations.push({ type: 'negative-test', description: 'Email validation' });
    testInfo.annotations.push({ type: 'severity', description: 'Medium' });

    await page.goto('https://example.com/profile');
    await page.fill('#username', 'testuser');
    await page.fill('#email', 'invalid-email'); // Invalid email format
    await page.click('#saveButton');

    // Attach the current page content for debugging invalid input scenarios
    testInfo.attach('page-content-on-error', { body: await page.content(), contentType: 'text/html' });

    await expect(page.locator('.error-message')).toHaveText('Invalid email format');
  });

});
```

To run this test and view the report:
1.  Save the code as `example.spec.ts` in your Playwright `tests` directory.
2.  Run Playwright tests: `npx playwright test`
3.  Open the HTML report: `npx playwright show-report`

You will see the annotations and attachments under each test in the generated HTML report.

## Best Practices
-   **Strategic Annotation**: Use annotations to categorize tests (e.g., `smoke`, `e2e`, `critical`), link to external systems (e.g., Jira tickets), or denote test ownership. This helps in filtering reports and understanding test coverage.
-   **Contextual Attachments**: Attach relevant artifacts that aid debugging. For UI tests, screenshots and videos on failure are standard. For API tests, consider attaching request/response payloads. For performance tests, attach metrics.
-   **Clear Naming**: Give meaningful names to your attachments (`login-form-data.json`, `network-logs.har`, `checkout-screenshot.png`) so they are easily identifiable in the report.
-   **Automate Attachments**: While `test.info().attach()` gives manual control, leverage Playwright's automatic attachment capabilities (e.g., `screenshot: 'only-on-failure'`, `video: 'on'`) in your `playwright.config.ts` for common scenarios.
-   **Cleanup Artifacts**: If you manually create files for attachment (like in the example), ensure your test environment or CI/CD pipeline cleans up these temporary files after the test run to prevent disk space issues.

## Common Pitfalls
-   **Over-attaching**: Attaching too many large files (e.g., full DOM snapshots for every step of every test) can bloat your test reports, making them slow to load and difficult to navigate. Be selective and attach only what's truly necessary.
-   **Sensitive Data in Attachments**: Be cautious not to attach sensitive information (passwords, API keys) directly into reports. If necessary, sanitize data before attaching.
-   **Missing `testInfo` Parameter**: For `test.info()` to be available, the `testInfo` fixture must be passed to your test function, typically as the second argument (e.g., `async ({ page }, testInfo)`). For `test.describe` hooks (e.g., `beforeEach`, `afterEach`), `testInfo` is not directly available, but you can access `test.info()` within the test functions themselves or through `test.afterEach(async ({ }, testInfo) => {})` style hooks.
-   **Incorrect Content Type**: Attaching a file with the wrong `contentType` might prevent the HTML report from displaying it correctly (e.g., a `.json` file attached as `text/plain` might not be syntax-highlighted).

## Interview Questions & Answers
1.  **Q: How can you add custom metadata to a Playwright test run for better reporting?**
    **A:** You can use `test.info().annotations.push()` to add custom annotations. These are key-value pairs (`type`, `description`) that appear in the HTML report and can be used for categorization (e.g., `severity: 'High'`, `feature: 'Authentication'`) or linking to external systems (e.g., `jira: 'BUG-456'`).

2.  **Q: Describe a scenario where you would manually use `test.info().attach()` instead of relying on Playwright's automatic screenshot/video capture.**
    **A:** While Playwright automatically captures screenshots/videos on failure, `test.info().attach()` is useful for:
    *   **Capturing specific states on success**: For example, taking a screenshot of a generated report or a complex dashboard after a successful data submission.
    *   **Attaching non-visual data**: Such as API request/response bodies, network HAR files for specific interactions, console logs, or application state (e.g., Redux store snapshot) at a particular point in the test.
    *   **Custom error diagnostics**: Attaching specific debug information *before* an expected failure or a point of interest, even if the test eventually passes or fails for other reasons.

3.  **Q: What are the benefits of using `test.info().annotations` in a large test suite?**
    **A:** In a large test suite, annotations provide several benefits:
    *   **Improved Report Filtering**: Custom reporters can filter or group tests based on annotations (e.g., "show me all smoke tests" or "show me tests for Jira PROJ-123").
    *   **Better Test Insights**: They offer immediate context in reports, helping engineers understand the purpose, scope, or impact of a test without digging into the code.
    *   **Prioritization**: Annotations like `severity` or `priority` can help teams quickly identify and address failures in critical tests.
    *   **Test Maintenance**: Identifying test ownership or related feature areas helps in delegating maintenance tasks.

## Hands-on Exercise
**Exercise: Extend the Profile Update Test**

Modify the provided `example.spec.ts` test to include the following:

1.  **Add a new annotation**: Mark the `should allow user to update their profile information` test with an `owner` annotation, assigning it to your name or team.
2.  **Conditional Attachment**: In the `should handle invalid email format` test, if an error message is *not* found (meaning the validation failed to trigger), attach a screenshot and the full page HTML to the report specifically for this unexpected scenario.
3.  **Attach Network Logs (Mock/Simulated)**: Before the `page.goto()` in the first test, simulate writing a small JSON file containing mock network requests/responses and attach it with `contentType: 'application/json'`. This demonstrates how you might attach network activity logs.

**Hint for Conditional Attachment**: You'll need an `if (!expect(locator).toBeVisible())` or similar logic to trigger the conditional attachment. Remember `await page.screenshot()` and `await page.content()`.

## Additional Resources
-   **Playwright Test Info API**: [https://playwright.dev/docs/api/class-testinfo](https://playwright.dev/docs/api/class-testinfo)
-   **Playwright Test Annotations**: [https://playwright.dev/docs/api/class-testinfo#test-info-annotations](https://playwright.dev/docs/api/class-testinfo#test-info-annotations)
-   **Playwright Test Attachments**: [https://playwright.dev/docs/api/class-testinfo#test-info-attach](https://playwright.dev/docs/api/class-testinfo#test-info-attach)
-   **Playwright Configuration (for automatic attachments)**: [https://playwright.dev/docs/test-configuration#default-values](https://playwright.dev/docs/test-configuration#default-values)
