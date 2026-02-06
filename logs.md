# SDET Learning Content Generation Logs
Started at: Fri Feb  6 23:13:56 IST 2026
---
## Iteration 1 - Fri Feb  6 23:13:59 IST 2026
Target Feature: playwright-5.6-ac1
### Iteration 1 Output
YOLO mode is enabled. All tool calls will be automatically approved.
Loaded cached credentials.
YOLO mode is enabled. All tool calls will be automatically approved.
Hook registry initialized with 0 hook entries
## playwright-5.6-ac1: Playwright API Testing - Request Context

### Overview
Playwright's `request` object provides powerful capabilities for API testing, allowing developers and SDETs to make HTTP requests independent of the browser. This is crucial for testing backend services, validating data, and setting up test preconditions efficiently, without the overhead of UI interactions. By creating a `request.newContext()`, you can define a dedicated context with a base URL, custom headers, authentication tokens, and other configurations that apply to all requests made within that context. This ensures consistency and simplifies API testing workflows.

### Detailed Explanation
The `playwright.request` object is a standalone API client within Playwright. It's built on top of Node.js's `fetch` API, providing a familiar interface for making HTTP requests. The key advantage of `request.newContext()` is its ability to establish a session that maintains state (like cookies or authentication headers) and common configurations across multiple API calls.

When you create a new request context, you can specify:
- **`baseURL`**: A common base URL for all requests made within this context, reducing redundancy.
- **`extraHTTPHeaders`**: Default headers (e.g., `Authorization`, `Content-Type`) to be sent with every request.
- **`ignoreHTTPSErrors`**: To bypass TLS certificate errors, useful in non-production environments.
- **`proxy`**: Proxy settings for routing requests.
- **`timeout`**: Default timeout for all requests in this context.

This context can then be used to perform various HTTP methods (`get`, `post`, `put`, `delete`, `patch`, `head`) against your API endpoints. Responses can be easily asserted for status codes, JSON body content, headers, and more.

**Example Scenario**:
Imagine testing a user management API. You need to:
1.  Register a new user (POST /users).
2.  Log in that user to get an authentication token (POST /auth/login).
3.  Use the token to fetch user details (GET /users/{id}).
4.  Update user details (PUT /users/{id}).
5.  Delete the user (DELETE /users/{id}).

Using `request.newContext()`, you can establish an authenticated session once and reuse the context for all subsequent API calls related to that user, mimicking a real user's interaction flow more accurately and efficiently than if each request were isolated.

### Code Implementation
Let's consider an example using a hypothetical user API.

```typescript
import { test, expect, APIRequestContext } from '@playwright/test';

// Define a type for the user object for better type safety
type User = {
    id?: string;
    username: string;
    email: string;
    password?: string;
};

// Declare a variable to hold the API request context
let apiContext: APIRequestContext;
let createdUserId: string;
let authToken: string;

// Before all tests, set up the API context and register/login a user
test.beforeAll(async ({ playwright }) => {
    // Create a new API request context with a base URL and default headers
    apiContext = await playwright.request.newContext({
        baseURL: 'https://api.example.com/v1', // Replace with your actual API base URL
        extraHTTPHeaders: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        },
        // ignoreHTTPSErrors: true, // Uncomment if you are dealing with self-signed certs in dev
    });

    // 1. Register a new user
    const newUser: User = {
        username: `testuser_${Date.now()}`,
        email: `testuser_${Date.now()}@example.com`,
        password: 'Password123!',
    };
    const registerResponse = await apiContext.post('/users', { data: newUser });
    expect(registerResponse.ok()).toBeTruthy();
    const registeredUser = await registerResponse.json();
    createdUserId = registeredUser.id;
    console.log(`Registered user with ID: ${createdUserId}`);

    // 2. Login the new user to get an auth token
    const loginResponse = await apiContext.post('/auth/login', {
        data: {
            email: newUser.email,
            password: newUser.password,
        },
    });
    expect(loginResponse.ok()).toBeTruthy();
    const loginData = await loginResponse.json();
    authToken = loginData.token; // Assuming the API returns a token upon successful login
    console.log(`Logged in and received auth token: ${authToken.substring(0, 10)}...`);

    // Update the context with the authentication token for subsequent requests
    apiContext = await playwright.request.newContext({
        baseURL: 'https://api.example.com/v1',
        extraHTTPHeaders: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authToken}`, // Add the auth token
        },
    });
});

// After all tests, clean up resources (e.g., delete the created user)
test.afterAll(async () => {
    if (createdUserId && authToken) {
        // Use the authenticated context to delete the user
        const deleteResponse = await apiContext.delete(`/users/${createdUserId}`);
        expect(deleteResponse.ok()).toBeTruthy();
        console.log(`Cleaned up: Deleted user with ID: ${createdUserId}`);
    }
    // Dispose the context after all tests are done
    await apiContext.dispose();
});

test('should retrieve user details using authenticated context', async () => {
    expect(createdUserId).toBeDefined();

    // 3. Fetch user details using the authenticated context
    const userDetailsResponse = await apiContext.get(`/users/${createdUserId}`);
    expect(userDetailsResponse.ok()).toBeTruthy();
    const userDetails: User = await userDetailsResponse.json();

    expect(userDetails.id).toBe(createdUserId);
    expect(userDetails.username).toMatch(/testuser_\d+/);
    expect(userDetails.email).toMatch(/testuser_\d+@example.com/);
    // Add more assertions based on expected user data
});

test('should update user details using authenticated context', async () => {
    expect(createdUserId).toBeDefined();

    const updatedEmail = `updated_testuser_${Date.now()}@example.com`;
    const updateData = { email: updatedEmail };

    // 4. Update user details using the authenticated context
    const updateResponse = await apiContext.put(`/users/${createdUserId}`, { data: updateData });
    expect(updateResponse.ok()).toBeTruthy();
    const updatedUser: User = await updateResponse.json();

    expect(updatedUser.id).toBe(createdUserId);
    expect(updatedUser.email).toBe(updatedEmail);

    // Verify the update by fetching the user again
    const verifyResponse = await apiContext.get(`/users/${createdUserId}`);
    expect(verifyResponse.ok()).toBeTruthy();
    const verifiedUser: User = await verifyResponse.json();
    expect(verifiedUser.email).toBe(updatedEmail);
});

test('should fail to retrieve user details with invalid ID', async () => {
    const invalidUserId = 'invalid-id-123';
    const response = await apiContext.get(`/users/${invalidUserId}`);
    // Expect a 404 Not Found or similar error for an invalid ID
    expect(response.status()).toBe(404);
});
```

### Best Practices
- **Isolate API Tests**: Use `request.newContext()` for API tests to keep them separate from UI-driven browser contexts. This makes tests faster and more reliable.
- **Centralize Configuration**: Define `baseURL`, headers, and authentication logic in `beforeAll` hooks for consistency and easy maintenance.
- **Clean Up Resources**: Always clean up any data created during API tests (e.g., users, items) in `afterAll` hooks to ensure test independence and prevent data pollution.
- **Use Type Definitions**: For languages like TypeScript, define interfaces or types for your API request/response bodies to leverage type checking and improve code readability.
- **Detailed Assertions**: Don't just check `response.ok()`. Perform detailed assertions on status codes, response headers, and especially the JSON response body to ensure data integrity.
- **Handle Authentication Dynamically**: Instead of hardcoding tokens, dynamically obtain them through a login API call within `beforeAll` and inject them into the `request` context.

### Common Pitfalls
- **Forgetting `await apiContext.dispose()`**: Not disposing the context can lead to resource leaks, especially in large test suites, and might cause tests to hang or consume excessive memory.
- **Mixing Browser and API Contexts**: Attempting to use a browser's page context for API calls when `request.newContext()` is more appropriate. While `page.request` exists, `playwright.request` is designed for standalone API testing.
- **Hardcoding Sensitive Data**: Embedding API keys, tokens, or credentials directly in the code. Use environment variables or secure configuration management.
- **Inadequate Error Handling**: Not asserting on negative scenarios (e.g., invalid requests, authentication failures). API tests should cover both success and failure cases.
- **Ignoring `baseURL`**: Not leveraging the `baseURL` option and repeating the full URL in every request, making code harder to read and maintain.

### Interview Questions & Answers
1.  **Q: When would you use `playwright.request.newContext()` instead of making API calls directly with `fetch` in Node.js or `page.request`?**
    **A:** `playwright.request.newContext()` is preferred for dedicated API testing because it provides a consistent and configurable environment for multiple API calls. It allows centralizing `baseURL`, `extraHTTPHeaders` (like authentication tokens), and other settings for an entire test suite or block. While `fetch` works, `playwright.request` integrates better with Playwright's test runner, reporting, and assertion library. `page.request` is tied to a specific browser page, which introduces unnecessary browser overhead and dependencies for pure API tests.

2.  **Q: How do you handle authentication for API tests using Playwright's `request` context?**
    **A:** Authentication should typically be handled in a `beforeAll` hook. First, make an initial API call (e.g., a login endpoint) to obtain an authentication token (JWT, session cookie, etc.). Then, recreate or update the `apiContext` with this token in the `extraHTTPHeaders` (e.g., `Authorization: Bearer <token>`). This ensures all subsequent requests made with that context are authenticated.

3.  **Q: Describe how you would ensure idempotency and atomicity in Playwright API tests, particularly when creating and deleting test data.**
    **A:** To ensure idempotency and atomicity, test data creation (e.g., registering a user) should be done in a `beforeAll` or `beforeEach` hook, and the corresponding cleanup (e.g., deleting that user) should be performed in an `afterAll` or `afterEach` hook, respectively. Using unique identifiers (like timestamps or UUIDs) for created resources helps prevent conflicts. The `apiContext` plays a crucial role here by allowing a single authenticated session to manage the lifecycle of the test data.

### Hands-on Exercise
**Goal**: Create a set of API tests for a mock "To-Do List" API that demonstrate creating, retrieving, updating, and deleting a to-do item using `playwright.request.newContext()`.

**Instructions**:
1.  Set up a new Playwright project.
2.  Imagine a mock API with the following endpoints:
    *   `POST /todos`: Create a new to-do item (returns the created item with an ID).
    *   `GET /todos/{id}`: Retrieve a specific to-do item.
    *   `PUT /todos/{id}`: Update an existing to-do item.
    *   `DELETE /todos/{id}`: Delete a to-do item.
3.  In a `beforeAll` hook, create a `request.newContext()` with a `baseURL` (you can use a mock API service like `JSONPlaceholder` for practice, but for full CRUD, you might need a local mock server or a service like `MockAPI.io`).
4.  Write a test that:
    *   Creates a new to-do item using `apiContext.post()`.
    *   Asserts the creation was successful and extracts the `id`.
    *   Retrieves the item using `apiContext.get()` and asserts its content.
    *   Updates the item using `apiContext.put()` and asserts the update.
    *   Deletes the item using `apiContext.delete()` and asserts successful deletion.
5.  In an `afterAll` hook, ensure any created resources are cleaned up and the `apiContext` is disposed.
6.  Add a negative test case (e.g., trying to retrieve a non-existent item or updating with invalid data).

### Additional Resources
-   **Playwright APIRequestContext Documentation**: [https://playwright.dev/docs/api/class-apirequestcontext](https://playwright.dev/docs/api/class-apirequestcontext)
-   **Playwright Network Article**: [https://playwright.dev/docs/network](https://playwright.dev/docs/network)
-   **REST API Testing with Playwright - A Comprehensive Guide**: [https://medium.com/@bharatdwarkani/rest-api-testing-with-playwright-a-comprehensive-guide-2877073238fe](https://medium.com/@bharatdwarkani/rest-api-testing-with-playwright-a-comprehensive-guide-2877073238fe)
```
C:\Users\Arunachalam\AppData\Roaming\npm\node_modules\@google\gemini-cli\node_modules\@lydell\node-pty\conpty_console_list_agent.js:11
var consoleProcessList = getConsoleProcessList(shellPid);
                         ^

Error: AttachConsole failed
    at Object.<anonymous> (C:\Users\Arunachalam\AppData\Roaming\npm\node_modules\@google\gemini-cli\node_modules\@lydell\node-pty\conpty_console_list_agent.js:11:26)
    at Module._compile (node:internal/modules/cjs/loader:1706:14)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49

Node.js v22.21.0
C:\Users\Arunachalam\AppData\Roaming\npm\node_modules\@google\gemini-cli\node_modules\@lydell\node-pty\conpty_console_list_agent.js:11
var consoleProcessList = getConsoleProcessList(shellPid);
                         ^

Error: AttachConsole failed
    at Object.<anonymous> (C:\Users\Arunachalam\AppData\Roaming\npm\node_modules\@google\gemini-cli\node_modules\@lydell\node-pty\conpty_console_list_agent.js:11:26)
    at Module._compile (node:internal/modules/cjs/loader:1706:14)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49

Node.js v22.21.0
All tasks for `playwright-5.6-ac1` have been successfully completed:

1.  Generated comprehensive content for `playwright-5.6-ac1`.
2.  Created the markdown file `./sdet-learning-content/playwright-5.6-ac1.md`.
3.  Updated `progress.md` to mark the feature as complete.
4.  Appended the new log entry to `progress.md`.
5.  Committed the changes with the message: "Content: playwright-5.6-ac1 - Playwright API Testing - Request Context".

Files created this iteration: 1
Features marked complete: 237
---
## Iteration 2 - Fri Feb  6 23:16:45 IST 2026
Target Feature: playwright-5.5-ac2
