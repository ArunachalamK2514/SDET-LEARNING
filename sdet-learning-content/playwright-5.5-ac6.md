# Mock API Responses for Testing Edge Cases in Playwright

## Overview
Mocking API responses is a crucial technique in test automation, especially when dealing with external services, flaky APIs, or specific edge cases that are hard to reproduce in a live environment. Playwright provides powerful capabilities to intercept network requests and fulfill them with custom data. This allows SDETs to isolate the UI behavior from backend dependencies, ensuring tests are fast, reliable, and deterministic. By controlling the data returned from API calls, we can simulate various scenarios like empty states, error conditions, or specific data configurations without actual backend changes.

## Detailed Explanation
Playwright's `page.route()` method is the cornerstone for network interception. It allows you to listen for specific network requests based on a URL pattern and then decide how to handle them. When a request matches a defined route, you can either continue the request, abort it, or, most powerfully for mocking, fulfill it with your own custom response.

The `route.fulfill()` method is used to provide a custom response. You can specify the `status` code (e.g., 200, 404, 500), `contentType` (e.g., 'application/json'), and the `body` of the response. The `body` can be a string, or you can provide a JSON object which Playwright will automatically serialize to a string and set the `contentType` to `application/json`.

This mechanism enables you to:
1.  **Simulate different data states**: Test how your UI behaves with an empty list, a single item, or a large dataset.
2.  **Isolate frontend from backend**: Run frontend tests even when the backend is still under development or unavailable.
3.  **Test error handling**: Verify that your application correctly displays error messages for various HTTP status codes (e.g., 401 Unauthorized, 404 Not Found, 500 Internal Server Error).
4.  **Control test data**: Ensure consistent test results by providing predictable data, avoiding flakiness due to changing backend data.
5.  **Accelerate test execution**: Mocking often eliminates the need for database setups or complex backend seeding, leading to faster test runs.

## Code Implementation
Here's a comprehensive example demonstrating how to mock API responses for various scenarios using Playwright with TypeScript.

```typescript
import { test, expect } from '@playwright/test';

// Define a base URL for our dummy API
const BASE_API_URL = 'https://api.example.com';

test.describe('API Response Mocking Scenarios', () => {

    test('should display a list of products when API returns data', async ({ page }) => {
        // 1. Intercept the API call for products
        await page.route(`${BASE_API_URL}/products`, async route => {
            const mockProducts = [
                { id: 1, name: 'Laptop', price: 1200 },
                { id: 2, name: 'Mouse', price: 25 }
            ];
            // 2. Fulfill the request with mock JSON data
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify(mockProducts)
            });
        });

        // Navigate to the page that makes this API call
        await page.goto('https://example.com/products'); // Assuming this page fetches products

        // 3. Test UI behavior with the mocked data
        await expect(page.locator('text=Laptop')).toBeVisible();
        await expect(page.locator('text=Mouse')).toBeVisible();
        await expect(page.locator('text=$1200')).toBeVisible();
        await expect(page.locator('text=$25')).toBeVisible();
        console.log('Test Passed: Products displayed correctly with mocked data.');
    });

    test('should display "No Products Found" when API returns an empty array', async ({ page }) => {
        await page.route(`${BASE_API_URL}/products`, async route => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([]) // Empty array
            });
        });

        await page.goto('https://example.com/products');

        await expect(page.locator('text=No Products Found')).toBeVisible();
        await expect(page.locator('text=Laptop')).not.toBeVisible(); // Ensure old data isn't visible
        console.log('Test Passed: "No Products Found" message displayed for empty data.');
    });

    test('should display an error message when API returns a 500 Internal Server Error', async ({ page }) => {
        await page.route(`${BASE_API_URL}/products`, async route => {
            await route.fulfill({
                status: 500,
                contentType: 'application/json',
                body: JSON.stringify({ message: 'Internal Server Error' })
            });
        });

        await page.goto('https://example.com/products');

        await expect(page.locator('text=Failed to load products. Please try again later.')).toBeVisible(); // Assuming UI handles 500 error
        await expect(page.locator('text=Internal Server Error')).not.toBeVisible(); // Raw error message shouldn't be visible to user
        console.log('Test Passed: Error message displayed for 500 status.');
    });

    test('should display a loading spinner while data is being fetched (simulated delay)', async ({ page }) => {
        await page.route(`${BASE_API_URL}/products`, async route => {
            // Simulate a network delay of 2 seconds
            await page.waitForTimeout(2000);
            const mockProducts = [{ id: 1, name: 'Delayed Product', price: 99 }];
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify(mockProducts)
            });
        });

        await page.goto('https://example.com/products');

        // Assuming a loading spinner has a specific data-testid or class
        await expect(page.locator('[data-testid="loading-spinner"]')).toBeVisible();
        await expect(page.locator('text=Delayed Product')).not.toBeVisible(); // Product not visible yet

        // Wait for the mock response to complete and UI to update
        await page.waitForSelector('text=Delayed Product');
        await expect(page.locator('text=Delayed Product')).toBeVisible();
        await expect(page.locator('[data-testid="loading-spinner"]')).not.toBeVisible(); // Spinner should be gone
        console.log('Test Passed: Loading spinner handled correctly with simulated delay.');
    });

    test('should handle multiple API mocks on the same page', async ({ page }) => {
        await page.route(`${BASE_API_URL}/users`, async route => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([{ id: 1, name: 'Alice' }])
            });
        });

        await page.route(`${BASE_API_URL}/posts`, async route => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify([{ id: 101, title: 'Playwright Mastery' }])
            });
        });

        await page.goto('https://example.com/dashboard'); // Page making calls to /users and /posts

        await expect(page.locator('text=Alice')).toBeVisible();
        await expect(page.locator('text=Playwright Mastery')).toBeVisible();
        console.log('Test Passed: Multiple API mocks handled on the same page.');
    });
});
```

## Best Practices
-   **Granular Mocking**: Mock only the responses you need to control for a specific test. Allow other requests to go through if they don't impact your test scenario (e.g., analytics calls).
-   **Clear Naming**: Name your mock data and test descriptions clearly to reflect the scenario being tested (e.g., `mockEmptyProducts`, `mockErrorResponse`).
-   **Realism vs. Simplicity**: Strive for mock data that is realistic enough to properly test your UI, but simple enough to be easily understood and maintained. Avoid overly complex mock data unless absolutely necessary.
-   **Isolate Mocks**: Define mocks within the scope of individual tests or test `describe` blocks. This prevents mocks from leaking into other tests and causing unexpected behavior. Use `test.beforeEach` or `test.afterEach` for setup/teardown if mocks are shared within a `describe` block.
-   **Error Handling**: Always consider how your application handles various HTTP status codes and malformed responses. Mock these scenarios to ensure robust error handling.
-   **Assertions**: Assert not just that the mocked data is displayed, but also that UI elements are correctly rendered or hidden based on the mocked response (e.g., loading indicators, empty state messages).

## Common Pitfalls
-   **Over-Mocking**: Mocking too many requests can make tests brittle and hard to maintain. If a request doesn't affect the UI under test, let it go through.
-   **Stale Mocks**: If API contracts change, mocks can become outdated, leading to false positives where tests pass but the application fails with real data. Regularly review and update mocks.
-   **Incorrect URL Matching**: Using overly broad or incorrect URL patterns in `page.route()` can lead to unintended requests being mocked or, conversely, requests not being mocked when they should be. Use specific patterns or regular expressions.
-   **Missing `await route.fulfill()`**: Forgetting to call `route.fulfill()` or `route.continue()` will leave the request pending indefinitely, causing tests to time out.
-   **Ordering of Routes**: If multiple routes match the same URL, the order in which they are defined can matter. Playwright processes routes in the order they are registered.
-   **No Network Activity**: Sometimes a page might not make the expected API call if the UI logic has issues. Use Playwright's tracing or `page.on('request')` to debug if requests are actually being made and intercepted.

## Interview Questions & Answers
1.  **Q: Why is API mocking important in UI test automation?**
    A: API mocking is crucial because it allows us to isolate the frontend from the backend, making UI tests faster, more stable, and deterministic. It enables testing of edge cases (like empty states, error responses, slow network) that are difficult to reliably reproduce with a live backend. This isolation reduces flakiness, accelerates development cycles, and ensures comprehensive test coverage of the UI's reaction to various data scenarios.

2.  **Q: How do you handle different HTTP status codes (e.g., 200, 404, 500) when mocking API responses in Playwright?**
    A: In Playwright, we use `page.route()` to intercept the request and `route.fulfill()` to provide a custom response. To simulate different HTTP status codes, we set the `status` property in `route.fulfill()`. For example, `await route.fulfill({ status: 500, contentType: 'application/json', body: '{"message": "Server Error"}' });` would mock a 500 Internal Server Error, allowing us to test the UI's error handling.

3.  **Q: Describe a scenario where you would use API mocking for an edge case.**
    A: A common edge case is an "empty state" for a list or table. Suppose we have a product listing page. Without mocking, we'd need to ensure the database has no products to test the "No products found" message. With API mocking, we can intercept the `/products` API call and fulfill it with an empty JSON array (`body: JSON.stringify([])`), directly asserting that the "No products found" message is displayed, regardless of the actual database state. Another case is simulating a very slow API to test loading indicators.

4.  **Q: What are the potential drawbacks or challenges of using API mocking in tests?**
    A: Challenges include:
    *   **Maintenance Overhead**: Mocks need to be updated if the actual API contract changes, leading to potential staleness.
    *   **Inaccuracy**: Mocks might not perfectly replicate complex backend logic or subtle data transformations, potentially leading to false positives.
    *   **Over-Mocking**: Mocking too much can obscure actual integration issues and make tests brittle.
    *   **Debugging Complexity**: Debugging network issues can be harder when some requests are mocked and others are live.

## Hands-on Exercise
**Objective**: Test a "User Profile" page for various states: loading, successful data display, and error.

**Instructions**:
1.  Assume you have a web application with a `/profile` page that fetches user data from `https://api.example.com/user/123`.
2.  **Create a Playwright test file.**
3.  **Implement three separate tests:**
    *   **Test 1: Successful Profile Display**: Mock the API to return a specific user object (e.g., `{ id: 123, name: 'John Doe', email: 'john.doe@example.com' }`). Assert that 'John Doe' and 'john.doe@example.com' are visible on the page.
    *   **Test 2: User Not Found**: Mock the API to return a `404` status with an error message. Assert that a "User not found" or similar error message is displayed on the page.
    *   **Test 3: Loading State**: Mock the API to introduce a 3-second delay before fulfilling with successful data. Assert that a loading spinner (or "Loading..." text) is visible initially, and then the user data appears after the delay, with the loading indicator disappearing.
4.  **(Self-reflection)**: Consider how you would verify that the UI correctly handles a `500` error or an empty profile data scenario.

## Additional Resources
-   **Playwright Network Documentation**: [https://playwright.dev/docs/network](https://playwright.dev/docs/network) - Official documentation on network interception and mocking.
-   **Playwright `page.route()` API Reference**: [https://playwright.dev/docs/api/class-page#page-route](https://playwright.dev/docs/api/class-page#page-route) - Detailed API for the routing method.
-   **Blog Post on Playwright API Mocking**: Search for "Playwright API Mocking Tutorial" on Google or YouTube for various community-contributed guides and examples.
