# Playwright API Testing: Validating API Responses

## Overview
In modern software development, APIs are the backbone of most applications. Ensuring their reliability and correctness is paramount for a stable system. Playwright, while renowned for its browser automation capabilities, also provides robust features for API testing. This document focuses on how to effectively validate API responses using Playwright's `APIRequestContext`, specifically asserting status codes, headers, and the response body. This is a critical skill for SDETs, as it allows for comprehensive testing of the entire application stack, from UI interactions down to backend service integrity.

## Detailed Explanation
Playwright's `request` fixture (an instance of `APIRequestContext`) allows you to send HTTP requests and interact with API endpoints directly, without the overhead of a browser. This makes it an excellent choice for fast, reliable, and integrated API testing alongside your UI tests.

When performing API calls, validating the response is crucial. Key aspects to check include:
1.  **Status Code**: Ensures the server responded with the expected HTTP status (e.g., 200 OK, 201 Created, 404 Not Found, 500 Internal Server Error).
2.  **Response Headers**: Validates metadata about the response, such as `Content-Type`, `Cache-Control`, `Authorization`, etc. This helps ensure proper communication and security configurations.
3.  **Response Body**: Confirms that the actual data returned by the API matches expectations. This often involves parsing JSON or XML and asserting specific values or structures.

Playwright's `APIResponse` object provides convenient methods to access these details:
-   `response.ok()`: A boolean indicating if the response was successful (status code 2xx).
-   `response.status()`: Returns the numeric HTTP status code.
-   `response.statusText()`: Returns the HTTP status text (e.g., "OK", "Not Found").
-   `response.headers()`: Returns an object containing all response headers.
-   `response.json()`: Parses the response body as JSON.
-   `response.text()`: Returns the response body as a string.

## Code Implementation

Let's illustrate with an example using a hypothetical REST API endpoint `/api/users`.

```typescript
// Import Playwright's test runner and expect assertion library
import { test, expect, APIResponse } from '@playwright/test';

// Define a base URL for your API to keep tests DRY
// This can be configured in playwright.config.ts or passed via CLI
const API_BASE_URL = 'https://api.example.com'; 

test.describe('API Response Validation Tests for /api/users', () => {

    test('should validate successful user creation response (status 201)', async ({ request }) => {
        // 1. Send a POST request to create a new user
        const newUser = { 
            name: 'John Doe', 
            email: 'john.doe@example.com', 
            password: 'securePassword123' 
        };
        const response: APIResponse = await request.post(`${API_BASE_URL}/users`, {
            data: newUser,
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
        });

        // Assert response.ok() - checks for 2xx status codes
        // This is a convenient shorthand for checking success
        expect(response.ok()).toBeTruthy(); 
        console.log(`Response successful: ${response.ok()}`);

        // Assert specific status code: 201 Created
        expect(response.status()).toBe(201);
        console.log(`Response Status: ${response.status()}`);

        // Assert headers content
        const headers = response.headers();
        expect(headers['content-type']).toContain('application/json');
        expect(headers['cache-control']).toBeDefined(); // Ensure cache-control header exists
        expect(headers['x-request-id']).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/); // Example: UUID format

        // Assert response body content (assuming JSON response)
        const responseBody = await response.json();
        expect(responseBody).toBeInstanceOf(Object);
        expect(responseBody.id).toBeDefined(); // New user should have an ID
        expect(responseBody.name).toBe(newUser.name);
        expect(responseBody.email).toBe(newUser.email);
        expect(responseBody.createdAt).toBeDefined(); // Timestamp
        expect(responseBody.password).toBeUndefined(); // Passwords should not be returned in response body
        console.log('Response Body:', responseBody);
    });

    test('should validate fetching all users (status 200) and array structure', async ({ request }) => {
        const response: APIResponse = await request.get(`${API_BASE_URL}/users`, {
            headers: {
                'Accept': 'application/json'
            }
        });

        expect(response.ok()).toBeTruthy();
        expect(response.status()).toBe(200);

        const headers = response.headers();
        expect(headers['content-type']).toContain('application/json');

        const responseBody = await response.json();
        expect(Array.isArray(responseBody)).toBeTruthy(); // Expect an array of users
        expect(responseBody.length).toBeGreaterThanOrEqual(0); // Can be empty, or have users

        if (responseBody.length > 0) {
            // Assert structure of at least one user object
            const firstUser = responseBody[0];
            expect(firstUser).toHaveProperty('id');
            expect(firstUser).toHaveProperty('name');
            expect(firstUser).toHaveProperty('email');
            expect(firstUser).not.toHaveProperty('password'); // Sensitive data check
        }
        console.log('Fetched Users Body:', responseBody);
    });

    test('should validate fetching a non-existent user (status 404)', async ({ request }) => {
        const nonExistentUserId = 'nonexistent-id-123';
        const response: APIResponse = await request.get(`${API_BASE_URL}/users/${nonExistentUserId}`, {
            headers: {
                'Accept': 'application/json'
            }
        });

        expect(response.ok()).toBeFalsy(); // Should not be a successful response
        expect(response.status()).toBe(404);
        expect(response.statusText()).toBe('Not Found');

        const headers = response.headers();
        expect(headers['content-type']).toContain('application/json');

        const responseBody = await response.json();
        expect(responseBody).toHaveProperty('message');
        expect(responseBody.message).toContain('User not found');
        console.log('Not Found Response Body:', responseBody);
    });

    test('should handle server errors (status 500) gracefully', async ({ request }) => {
        // Assuming there's an endpoint that intentionally triggers a 500 for testing
        const response: APIResponse = await request.get(`${API_BASE_URL}/users/trigger-error`, {
            headers: {
                'Accept': 'application/json'
            }
        });

        expect(response.ok()).toBeFalsy();
        expect(response.status()).toBe(500);
        expect(response.statusText()).toBe('Internal Server Error');

        const headers = response.headers();
        expect(headers['content-type']).toContain('application/json');

        const responseBody = await response.json();
        expect(responseBody).toHaveProperty('error');
        expect(responseBody.error).toContain('Something went wrong on the server');
        console.log('Server Error Response Body:', responseBody);
    });
});
```

## Best Practices
-   **Use `expect(response.ok()).toBeTruthy();` for 2xx status codes:** This is a quick and effective way to assert that the request was generally successful.
-   **Assert specific status codes for clarity:** While `response.ok()` is good, explicitly asserting `expect(response.status()).toBe(200);` or `toBe(201);` provides more specific context and better error messages if the status code differs.
-   **Validate `Content-Type` header:** Always check the `Content-Type` header to ensure the API is returning data in the expected format (e.g., `application/json`).
-   **Thoroughly validate response body structure and data:** Don't just check for the presence of keys; validate their types, formats (e.g., UUIDs, dates), and actual values against your expectations. For dynamic values, use regex or partial matches.
-   **Test error scenarios:** Include tests for 4xx (client errors) and 5xx (server errors) responses to ensure the API handles invalid requests and internal failures gracefully and returns informative error messages.
-   **Isolate API tests:** Ensure your API tests are independent and don't rely on the state created by previous tests, unless specifically designed for chain-of-requests scenarios. Use `beforeAll` and `afterAll` hooks for setup/teardown if necessary.
-   **Use environment variables or Playwright config for base URLs:** Avoid hardcoding URLs directly in your tests.

## Common Pitfalls
-   **Not checking `response.ok()` or status codes:** This can lead to silently passing tests even if the API returned an error, as long as the response structure is somewhat similar.
-   **Overlooking header validation:** Headers carry important information regarding caching, security, and content negotiation. Neglecting them can miss potential issues.
-   **Shallow body assertions:** Only checking for the existence of top-level keys without validating their values or nested structures can lead to false positives.
-   **Hardcoding data:** Relying on fixed data that might change in the backend can make tests brittle. Use dynamic data generation or mock servers when appropriate.
-   **Ignoring network issues:** While Playwright's `request` handles common HTTP errors, understanding how network timeouts or connection issues manifest in Playwright's API responses is important for robust error handling.

## Interview Questions & Answers
1.  **Q: How do you perform API testing using Playwright?**
    A: Playwright provides the `request` fixture (an instance of `APIRequestContext`) which allows sending HTTP requests directly. You can use methods like `request.get()`, `request.post()`, `request.put()`, `request.delete()` and then validate the `APIResponse` object.

2.  **Q: What are the key assertions you would make when validating an API response in Playwright?**
    A: I would always start by asserting `response.ok()` to ensure a 2xx status code. Then, I'd check the specific `response.status()` (e.g., `toBe(200)` or `toBe(201)`). Header validation, especially `Content-Type`, is crucial via `response.headers()`. Finally, the `response.json()` or `response.text()` method would be used to parse and assert the structure and data within the response body.

3.  **Q: Describe how you would handle validating a JSON response body in Playwright, including nested objects and arrays.**
    A: After parsing the response body using `await response.json()`, I would use Playwright's `expect` assertions. For basic properties, `expect(body.property).toBe(expectedValue)`. For nested objects, `expect(body.nestedObject.property).toBe(expectedValue)`. For arrays, `expect(Array.isArray(body.arrayProperty)).toBeTruthy()` and then iterate or access elements to validate their structure and data using `toHaveProperty`, `toContainEqual`, or deeper individual assertions. It's also important to check for the absence of sensitive data.

## Hands-on Exercise
**Objective**: Create a Playwright API test for a public API that involves both a GET and a POST request, validating status, headers, and body for both success and a specific error case.

1.  **Choose a Public API**: Use `https://jsonplaceholder.typicode.com/` as your target API.
2.  **GET Request**:
    *   Write a test that performs a GET request to `/posts/1`.
    *   Assert that `response.ok()` is true and the status is 200.
    *   Assert that the `Content-Type` header is `application/json; charset=utf-8`.
    *   Assert that the response body is a JSON object containing `userId: 1`, `id: 1`, `title`, and `body` properties.
3.  **POST Request**:
    *   Write a test that performs a POST request to `/posts` with a new post object `{ title: 'foo', body: 'bar', userId: 1 }`.
    *   Assert that `response.ok()` is true and the status is 201.
    *   Assert the `Content-Type` header.
    *   Assert that the response body contains the submitted data plus a new `id` property.
4.  **Error Case**:
    *   Write a test that performs a GET request to a non-existent endpoint (e.g., `/nonexistent`).
    *   Assert that `response.ok()` is false and the status is 404.
    *   Assert the `Content-Type` header (it might still be JSON or plain text depending on the API's error handling).

## Additional Resources
-   **Playwright API Testing Documentation**: [https://playwright.dev/docs/api-testing](https://playwright.dev/docs/api-testing)
-   **HTTP Status Codes**: [https://developer.mozilla.org/en-US/docs/Web/HTTP/Status](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
-   **jsonplaceholder - Free Fake API for Testing**: [https://jsonplaceholder.typicode.com/](https://jsonplaceholder.typicode.com/)
