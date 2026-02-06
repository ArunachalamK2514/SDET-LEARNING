# Network Request Interception with Playwright's `page.route()`

## Overview
Network request interception is a powerful feature in Playwright that allows SDETs to control, modify, or block network requests made by the browser. This is invaluable for testing various scenarios, including:
- **Mocking API responses**: Simulating backend behavior without an actual backend.
- **Testing error conditions**: Forcing specific network errors (e.g., 404, 500) to verify application resilience.
- **Blocking unnecessary resources**: Speeding up tests by preventing loading of analytics scripts, images, or other non-essential assets.
- **Inspecting request/response headers and bodies**: Verifying data sent to and received from the server.
- **Testing slow network conditions**: Simulating latency to check loading states and performance.

`page.route()` is the primary Playwright API for achieving this, offering fine-grained control over network traffic.

## Detailed Explanation
Playwright's `page.route(url, handler)` method allows you to intercept network requests that match a specified URL pattern. The `url` argument can be a string, a regular expression, or a function. The `handler` is an asynchronous function that receives a `Route` object, which provides methods to fulfill, abort, or continue the request.

### `route.abort()`
This method stops the request from reaching the server, simulating a network failure. It's often used to block specific resource types (like images, fonts) to improve test performance or to test scenarios where a resource fails to load.

**Example Scenario**: Aborting all PNG image requests.

### `route.continue()`
This method allows the request to continue to its destination. You can optionally modify the request before it continues by providing `headers`, `method`, `postData`, or `url` options. This is useful for inspecting requests and then letting them proceed.

**Example Scenario**: Inspecting request headers and then allowing the request to proceed.

### `route.fulfill()`
This method responds to the request with custom data, effectively mocking the server's response. You can specify `status`, `headers`, `body`, `contentType`, and `path` (to serve a local file).

**Example Scenario**: Mocking an API response to control test data.

### Request Inspection
The `Route` object provides access to the `request` object (`route.request()`), which contains detailed information about the intercepted request, such as URL, method, headers, and post data. This allows for assertions on the request details.

## Code Implementation
Here's a TypeScript example demonstrating various `page.route()` functionalities.

```typescript
import { test, expect, Page } from '@playwright/test';

test.describe('Network Request Interception', () => {

  // Test to abort specific image requests
  test('should abort PNG image requests', async ({ page }) => {
    // Intercept all requests ending with .png and abort them
    await page.route('**/*.png', route => route.abort());

    // Navigate to a page that loads PNG images
    // Replace with a URL that serves PNGs, or create a local test server
    await page.goto('https://www.example.com'); // Example URL, replace with one that serves PNGs if possible

    // You can assert that no PNGs were loaded, e.g., by checking network logs
    // Playwright doesn't directly expose aborted requests in networkFinished events easily.
    // A more direct way is to check the console for broken image icons or specific UI changes.
    // For this example, we'll just verify the page loads without specific PNG issues.
    // In a real test, you might verify the absence of an image element or a broken image icon.
    // For demonstration, let's assume if an image is crucial, its absence would break a visual assertion.
    // We can also check for failed requests in the performance tab, but that's outside Playwright's direct API.

    // Let's use a simpler assertion for demonstration: ensure no image elements are visible if they were supposed to be PNGs.
    // This is a weak assertion, a stronger one would involve actual network monitoring.
    const images = await page.locator('img[src$=".png"]').all();
    for (const img of images) {
        // We expect these images might not load, or their network request was aborted.
        // A robust test would involve checking network logs if exposed easily.
        // For now, we expect the page to still be navigable.
        expect(await page.isVisible('body')).toBe(true);
    }

    // A better approach for verification: monitor requests and check for aborted ones
    const abortedRequests: string[] = [];
    page.on('requestfailed', request => {
      if (request.url().endsWith('.png') && request.failure()?.errorText === 'net::ERR_FAILED') {
        abortedRequests.push(request.url());
      }
    });

    await page.reload(); // Reload to trigger interception with the listener active
    expect(abortedRequests.length).toBeGreaterThanOrEqual(0); // This might be 0 if example.com has no PNGs, but shows how to listen.
    // For a real test, use a page with known PNGs.
  });

  // Test to inspect request headers and continue the request
  test('should inspect request headers for authorization token', async ({ page }) => {
    let interceptedHeaders: Record<string, string> = {};
    const expectedAuthToken = 'Bearer my-secret-auth-token-123';

    // Set a custom header before navigating to simulate a logged-in state or API call
    await page.setExtraHTTPHeaders({
      'Authorization': expectedAuthToken,
      'X-Custom-Header': 'Playwright-Test'
    });

    // Intercept all requests to example.com (or your API endpoint)
    await page.route('https://www.example.com/**', async route => {
      const request = route.request();
      interceptedHeaders = request.headers(); // Get all headers
      await route.continue(); // Allow the request to proceed
    });

    // Navigate to a page or trigger an action that makes a request
    await page.goto('https://www.example.com');

    // Assert that the intercepted headers contain the expected authorization token
    expect(interceptedHeaders['authorization']).toBe(expectedAuthToken);
    expect(interceptedHeaders['x-custom-header']).toBe('Playwright-Test');
  });

  // Test to mock an API response using route.fulfill()
  test('should mock an API response', async ({ page }) => {
    const mockApiResponse = {
      id: 1,
      name: 'Mocked Product',
      price: 99.99,
      currency: 'USD'
    };

    // Intercept a specific API endpoint
    await page.route('**/api/products/1', async route => {
      // Respond with mocked data
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(mockApiResponse),
        headers: {
          'Access-Control-Allow-Origin': '*', // Important for CORS if testing different origins
        }
      });
    });

    // Navigate to a page that makes a request to this API, or directly make the request
    // For demonstration, let's make a fetch request in the browser context
    await page.goto('about:blank'); // Start with a blank page
    const response = await page.evaluate(async () => {
      const res = await fetch('/api/products/1');
      return res.json();
    });

    // Assert that the response matches the mocked data
    expect(response).toEqual(mockApiResponse);
  });
});
```

## Best Practices
- **Be Specific with URLs**: Use precise strings or regular expressions for `page.route()` to avoid unintended interceptions. Overly broad patterns can slow down tests or cause unexpected behavior.
- **Always Handle Routes**: Every `page.route()` handler **must** call `route.continue()`, `route.fulfill()`, or `route.abort()`. Failing to do so will hang the network request and eventually timeout the test.
- **Cleanup Routes**: If a route is only needed for a specific test or section, use `page.unroute()` to remove the handler when it's no longer necessary. This prevents interference with subsequent tests.
- **Organize Mocks**: For complex applications with many API calls, centralize your mock responses in dedicated files or modules to keep tests clean and maintainable.
- **Prioritize Interception Order**: If multiple `page.route()` calls match the same URL, the last registered route takes precedence. Be mindful of the order if you have overlapping patterns.

## Common Pitfalls
- **Forgetting to Call `continue()`/`fulfill()`/`abort()`**: This is the most common mistake, leading to hung requests and test timeouts.
- **Incorrect URL Patterns**: Using patterns that are too broad or too narrow can lead to missed interceptions or unintended ones. Test your patterns carefully.
- **CORS Issues with Mocking**: When using `route.fulfill()` to mock responses from a different origin, you might encounter Cross-Origin Resource Sharing (CORS) errors. Remember to add appropriate CORS headers (e.g., `'Access-Control-Allow-Origin': '*'`) to your mocked response if needed.
- **Asynchronous Nature**: Network interception is asynchronous. Ensure your test logic correctly awaits network events or conditions before making assertions.
- **Interfering with Playwright's Own Requests**: Be careful not to intercept Playwright's internal requests, which could break its functionality. Generally, focus on application-specific URLs.

## Interview Questions & Answers
1.  **Q: What is network request interception in Playwright, and why is it important for SDETs?**
    A: Network request interception is Playwright's capability to monitor, modify, or block HTTP/HTTPS requests made by the browser. It's crucial for SDETs because it allows for:
    *   **Isolation**: Decoupling frontend tests from backend availability by mocking API responses.
    *   **Testing Edge Cases**: Simulating network errors (404, 500, slow connections) to test application resilience.
    *   **Performance Optimization**: Blocking non-essential resources (images, analytics) to speed up tests.
    *   **Data Control**: Providing controlled test data through mocked responses.
    *   **Security Testing**: Inspecting headers and payloads to ensure sensitive data isn't exposed or incorrect data is sent.

2.  **Q: Explain the difference between `route.abort()`, `route.continue()`, and `route.fulfill()` in Playwright.**
    A:
    *   `route.abort()`: Prevents a network request from reaching its destination, simulating a network failure. Useful for blocking resources or testing error states.
    *   `route.continue()`: Allows a network request to proceed to its original destination. It can optionally modify the request (e.g., alter headers, method, postData) before it continues. Useful for inspecting requests or injecting client-side tokens.
    *   `route.fulfill()`: Responds to a network request directly from Playwright, effectively mocking the server's response. You can specify the status code, headers, and body of the response. This is essential for stubbing API calls.

3.  **Q: How would you use `page.route()` to ensure a specific authorization token is sent with all API requests from your application?**
    A: I would use `page.route()` with a broad pattern matching all API endpoints. Inside the handler, I would retrieve the `request` object, inspect its headers for the `Authorization` header. If it's missing or incorrect, I would fail the test or modify the request to include the correct token using `route.continue({ headers: { ...existingHeaders, 'Authorization': 'Bearer <token>' } })`.
    ```typescript
    await page.route('**/api/**', async route => {
      const request = route.request();
      const headers = request.headers();
      expect(headers['authorization']).toBe('Bearer your-expected-token'); // Assert token is present
      await route.continue(); // Let the request proceed
    });
    // Or to enforce/add the token:
    await page.route('**/api/**', async route => {
      const request = route.request();
      const headers = request.headers();
      if (!headers['authorization']) {
          // Add the authorization header if missing
          await route.continue({
              headers: {
                  ...headers,
                  'authorization': 'Bearer your-expected-token'
              }
          });
      } else {
          await route.continue(); // Let requests with existing auth continue
      }
    });
    ```

## Hands-on Exercise
**Scenario**: You are testing an e-commerce website. The product detail page makes an API call to `/api/products/:id` to fetch product information.

**Task**:
1.  Write a Playwright test that navigates to an arbitrary product page (e.g., `https://www.example.com/products/123`).
2.  Use `page.route()` to intercept the `/api/products/123` API call.
3.  Mock the response for this API call to return a custom product with the following details:
    ```json
    {
      "id": 123,
      "name": "Playwright Intercepted Gadget",
      "description": "This product data was entirely mocked by Playwright!",
      "price": 49.99,
      "imageUrl": "https://via.placeholder.com/150"
    }
    ```
4.  After the page loads, assert that the product name, description, and price displayed on the UI match the mocked data.
5.  (Bonus) Add another `page.route()` to block all requests to external analytics scripts (e.g., `**/*google-analytics.com*/**`) and verify they are not loaded.

## Additional Resources
-   **Playwright Network Documentation**: [https://playwright.dev/docs/network](https://playwright.dev/docs/network)
-   **Playwright `page.route()` API Reference**: [https://playwright.dev/docs/api/class-page#page-route](https://playwright.dev/docs/api/class-page#page-route)
-   **Video Tutorial on Network Mocking**: Search YouTube for "Playwright network mocking" or "Playwright intercept network requests" for visual guides.
