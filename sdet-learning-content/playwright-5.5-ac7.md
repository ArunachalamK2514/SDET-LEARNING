# Playwright: Modifying Network Requests (Headers, Method, Post Data)

## Overview
Network request modification in Playwright is a powerful feature that allows testers to alter outgoing HTTP requests before they reach the server. This capability is crucial for simulating various real-world scenarios, testing authentication and authorization flows, injecting fault conditions, and verifying how an application behaves under different network conditions or data inputs. By programmatically changing headers, HTTP methods, or the request body (post data), SDETs can gain fine-grained control over their tests, enabling more robust and comprehensive test suites.

## Detailed Explanation
Playwright's `page.route()` method is the cornerstone for intercepting and modifying network requests. When a request matches a specified URL pattern, `page.route()` provides a `Route` object, allowing you to either `fulfill` the request with a custom response or `continue` it with modifications.

The `route.continue()` method is used to allow the request to proceed to its destination, but with potential changes. It accepts an optional `options` object with properties like `headers`, `method`, and `postData`.

### 1. Modifying Request Headers
Headers are key-value pairs that carry metadata about the request. You might want to modify headers to:
- Add `Authorization` tokens for authenticated requests.
- Change `User-Agent` to simulate different browsers/devices.
- Inject custom headers for A/B testing or specific backend logic.

When using `route.continue({ headers: ... })`, you provide an object where keys are header names and values are their desired content. Note that providing new headers will **merge** with the existing headers. If you want to remove an existing header, you can explicitly set its value to `undefined` or an empty string, or rebuild the headers object from scratch if you need precise control. It's often safer to get the existing headers and then modify them.

```typescript
await page.route('**/api/data', async route => {
  const headers = await route.request().headers();
  await route.continue({
    headers: {
      ...headers, // Copy existing headers
      'X-Custom-Header': 'MyValue',
      'Authorization': 'Bearer my_auth_token_123',
      'User-Agent': 'PlaywrightTestBot'
    },
  });
});
```

### 2. Modifying Request Method
Changing the HTTP method allows you to test how a server or client-side application reacts if a request originally intended as, say, a `POST`, arrives as a `PUT` or `GET`. This is less common but can be useful for security testing or verifying method-specific endpoint logic.

```typescript
await page.route('**/api/resource', async route => {
  await route.continue({
    method: 'PUT', // Change POST to PUT, or GET to POST etc.
  });
});
```
**Important**: When changing methods, ensure the new method is compatible with the `postData` (if any). For example, changing a `POST` with a body to a `GET` will typically strip the body.

### 3. Modifying Post Data Payload
`postData` refers to the body of an HTTP request, typically used with `POST`, `PUT`, and `PATCH` methods to send data to the server (e.g., JSON, form data). Modifying `postData` is essential for:
- Testing different input values without changing UI.
- Injecting invalid data to test validation.
- Simulating specific user actions or data states.

The `postData` property in `route.continue()` expects a string or a Buffer. If your original request sends JSON, you should parse the existing `postData`, modify the JavaScript object, and then `JSON.stringify()` it back into a string. Remember to also update the `Content-Type` header if the data type changes.

```typescript
await page.route('**/api/submit', async route => {
  const request = route.request();
  let postData = request.postData();

  if (postData) {
    try {
      const payload = JSON.parse(postData);
      payload.userName = 'modifiedUser';
      payload.isAdmin = true;
      postData = JSON.stringify(payload);
    } catch (e) {
      console.error('Could not parse postData as JSON:', e);
      // Handle non-JSON postData if necessary
    }
  }

  const headers = await request.headers();
  await route.continue({
    postData: postData,
    headers: {
      ...headers,
      'Content-Type': 'application/json' // Ensure content type matches
    }
  });
});
```

## Code Implementation

This example demonstrates intercepting a POST request, adding a custom header, changing the method to PUT, and modifying the JSON payload. We'll simulate a backend endpoint using `page.route().fulfill()` to inspect the incoming request.

```typescript
// example.spec.ts
import { test, expect, Page, Route } from '@playwright/test';

test.describe('Network Request Modification', () => {

  // A helper function to simulate an API endpoint that captures and responds with the received request details
  async function setupMockApi(page: Page) {
    await page.route('**/api/resource', async (route: Route) => {
      const request = route.request();
      const headers = await request.allHeaders();
      const method = request.method();
      let postData = null;
      if (request.postDataBuffer()) {
        postData = request.postData();
      }

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          receivedMethod: method,
          receivedHeaders: headers,
          receivedPostData: postData ? JSON.parse(postData) : null,
          message: 'Request successfully processed by mock server.'
        }),
      });
    });
  }

  test('should modify request headers, method, and post data', async ({ page }) => {
    // 1. Setup our mock API to capture request details
    await setupMockApi(page);

    // 2. Intercept the outgoing request to modify it
    await page.route('**/api/resource', async (route: Route) => {
      const originalRequest = route.request();

      // Get existing headers to merge new ones
      const currentHeaders = await originalRequest.allHeaders();

      // Modify headers: add new, change existing (e.g., Authorization), potentially remove
      const newHeaders = {
        ...currentHeaders,
        'X-Trace-Id': 'playwright-test-123',
        'Authorization': 'Bearer modified_token',
        'User-Agent': 'PlaywrightModifiedAgent',
        // 'Accept-Encoding': undefined // Example of how to remove a header (by setting to undefined)
      };

      // Modify post data: Assuming original is JSON
      let modifiedPostData: string | undefined;
      const originalPostData = originalRequest.postData();
      if (originalPostData) {
        try {
          const payload = JSON.parse(originalPostData);
          payload.userId = 'modifiedUser123';
          payload.status = 'updated';
          modifiedPostData = JSON.stringify(payload);
          // Ensure Content-Type is correct if you're sending JSON
          newHeaders['Content-Type'] = 'application/json';
        } catch (e) {
          console.warn('Original postData was not JSON or empty. Skipping payload modification.', e);
          modifiedPostData = originalPostData; // Keep original if parsing fails
        }
      }

      // Continue the route with modifications
      await route.continue({
        headers: newHeaders,
        method: 'PUT', // Change the HTTP method
        postData: modifiedPostData,
      });
    });

    // 3. Trigger a request from the page (e.g., a form submission, API call)
    // We'll simulate a POST request with initial data
    const response = await page.evaluate(async () => {
      const res = await fetch('/api/resource', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer original_token',
          'User-Agent': 'OriginalAgent'
        },
        body: JSON.stringify({
          userId: 'originalUser',
          data: 'someData',
          status: 'initial'
        })
      });
      return res.json();
    });

    // 4. Assertions: Verify that our mock API received the modified request
    expect(response.receivedMethod).toBe('PUT'); // Method should be modified
    expect(response.receivedHeaders['x-trace-id']).toBe('playwright-test-123'); // Custom header added
    expect(response.receivedHeaders['authorization']).toBe('Bearer modified_token'); // Authorization header modified
    expect(response.receivedHeaders['user-agent']).toBe('PlaywrightModifiedAgent'); // User-Agent header modified

    // Assert post data modifications
    expect(response.receivedPostData).toEqual({
      userId: 'modifiedUser123',
      data: 'someData',
      status: 'updated'
    });

    expect(response.message).toBe('Request successfully processed by mock server.');
  });
});
```

## Best Practices
- **Be Specific with URL Patterns**: Use precise glob patterns or regular expressions in `page.route()` to avoid unintentionally intercepting and modifying requests that shouldn't be touched.
- **Maintain Original Headers**: When modifying headers, always retrieve the existing headers first using `route.request().allHeaders()` and then merge your changes. This ensures that essential headers (like `Host`, `Content-Length`) are not accidentally removed.
- **Handle Different `postData` Types**: Be mindful of the `Content-Type` header when modifying `postData`. If you modify a JSON body, ensure the `Content-Type` header remains `application/json`. For form data, process it accordingly.
- **Use `route.continue()` for Modifications**: Reserve `route.fulfill()` for mocking entire responses. For request-level alterations, `route.continue()` is the appropriate method.
- **Clean Up Routes**: In complex test suites, ensure routes are unset after the relevant tests to prevent interference with other tests. Playwright automatically cleans up routes registered within a `test()` block, but be cautious with global or `beforeEach` routes.

## Common Pitfalls
- **Forgetting `route.continue()` or `route.fulfill()`**: If a request is intercepted but neither `route.continue()` nor `route.fulfill()` is called, the request will hang, causing tests to time out.
- **Overwriting All Headers**: Directly assigning `{ headers: { ... } }` without spreading the `currentHeaders` will overwrite all existing headers, potentially breaking the request.
- **Incorrect `postData` Format**: Modifying a JSON payload but forgetting to `JSON.stringify()` it back, or sending a malformed string, will lead to server errors. Similarly, not updating `Content-Type` after changing data format.
- **Broad Interception Patterns**: Using `**/*` or similarly broad patterns can lead to unexpected side effects, as many requests (images, CSS, fonts) might be unintentionally intercepted.
- **Race Conditions with Multiple Routes**: If multiple `page.route()` calls match the same URL, their execution order can lead to unpredictable behavior. Structure your tests to have clear interception logic.

## Interview Questions & Answers
1.  **Q: When would you typically use `page.route()` to modify an outgoing request in Playwright?**
    **A:** I'd use `page.route()` to modify outgoing requests for several key scenarios:
    *   **Authentication/Authorization Testing:** Injecting or modifying `Authorization` headers to test different user roles or invalid tokens.
    *   **Data Manipulation:** Changing form submissions or API payloads to test validation, edge cases (e.g., very long strings, special characters), or unauthorized data access.
    *   **Simulating Client-Side Logic:** Testing how the application behaves if certain data is sent or not sent, or if the HTTP method is altered.
    *   **Performance/Security Testing:** Adding custom headers for tracing or security policy enforcement.

2.  **Q: How do you add a custom header to a request, ensuring existing headers are preserved?**
    **A:** To add a custom header while preserving existing ones, I would first retrieve all current headers using `route.request().allHeaders()`. Then, I'd create a new headers object by spreading the existing headers and adding my new custom header(s). Finally, I'd pass this new headers object to `route.continue({ headers: newHeaders })`. This ensures a merge rather than an overwrite.

3.  **Q: Can you change the HTTP method of a request (e.g., from POST to PUT) using Playwright? If so, what are the considerations?**
    **A:** Yes, you can change the HTTP method using `route.continue({ method: 'PUT' })`. The main consideration is compatibility with the request body (`postData`). If you change a `POST` (which typically has a body) to a `GET` (which typically does not), the `postData` will usually be stripped by the browser/Playwright unless explicitly handled. Conversely, if you change a `GET` to a `POST` and intend to send data, you must also provide appropriate `postData` and set the `Content-Type` header.

4.  **Q: What challenges might you encounter when modifying the `postData` of a request, especially for JSON payloads?**
    **A:** The primary challenges include:
    *   **Parsing and Stringifying:** `postData` is a string or Buffer. For JSON, you must parse it (`JSON.parse()`), modify the resulting JavaScript object, and then convert it back to a string (`JSON.stringify()`) before passing it to `route.continue()`.
    *   **`Content-Type` Header:** If you modify the `postData` (e.g., changing it from JSON to form data, or vice versa), you **must** also update the `Content-Type` header accordingly to ensure the server correctly interprets the payload.
    *   **Handling Empty or Non-JSON Data:** You need robust error handling for `JSON.parse()` if the original `postData` might be empty, malformed, or not in JSON format (e.g., URL-encoded form data).

## Hands-on Exercise
**Scenario**: You are testing a web application that has a registration form. When a user submits the form, a `POST` request is sent to `/api/register` with user details (e.g., `email`, `password`, `referrer`).
**Task**: Write a Playwright test that:
1. Intercepts the `POST` request to `/api/register`.
2. Modifies the `email` in the `postData` payload to `testuser-modified@example.com` and adds a `X-Testing-Group` header with value `A`.
3. Changes the HTTP method of the request from `POST` to `PATCH`.
4. Asserts that the modified request (as received by a mock server or captured in a test utility) contains the new email, the new header, and the `PATCH` method.

You can use a similar `setupMockApi` function as in the example above to simulate the server's reception of the modified request.

## Additional Resources
-   **Playwright `page.route()` Documentation**: [https://playwright.dev/docs/network#modify-requests](https://playwright.dev/docs/network#modify-requests)
-   **Playwright Network Handling Guide**: [https://playwright.dev/docs/network](https://playwright.dev/docs/network)
-   **HTTP Methods (MDN Web Docs)**: [https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods)
