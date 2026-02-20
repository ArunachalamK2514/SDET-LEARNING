# playwright-5.6-ac1.md

# playwright-5.6-ac1: Playwright API Testing - Request Context

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
---
# playwright-5.6-ac2.md

# Playwright API Testing: Performing CRUD Requests

## Overview
Playwright's `APIRequest` context is a powerful tool for testing backend APIs directly within your E2E test framework or for dedicated API testing. It allows you to send HTTP requests (GET, POST, PUT, DELETE) and assert on the responses, status codes, and headers, providing a robust way to ensure your API behaves as expected, independent of the UI. This capability is crucial for SDETs as it enables faster feedback cycles, more stable tests, and comprehensive coverage of application logic residing in the backend.

## Detailed Explanation
Playwright provides the `request` fixture, which is an instance of `APIRequestContext`. This fixture can be used in your tests to make various HTTP calls. It automatically handles things like base URLs, authentication, and headers if configured globally in `playwright.config.ts`.

### Key Concepts:
- **`request.get(url, options)`**: Sends a GET request to retrieve data.
- **`request.post(url, options)`**: Sends a POST request to create new data, typically sending a request body.
- **`request.put(url, options)`**: Sends a PUT request to update existing data, also typically sending a request body.
- **`request.delete(url, options)`**: Sends a DELETE request to remove data.
- **`APIResponse` object**: The returned object from each request, containing methods to access status, headers, and body.
  - `response.ok()`: Returns `true` if the status code is 2xx.
  - `response.status()`: Returns the HTTP status code.
  - `response.statusText()`: Returns the HTTP status text.
  - `response.json()`: Parses the response body as JSON.
  - `response.text()`: Returns the response body as plain text.
  - `response.headers()`: Returns an object with all response headers.

### Configuration (`playwright.config.ts`)
It's common practice to configure `baseURL` and `extraHTTPHeaders` for API requests globally. This simplifies your tests by avoiding repetitive URL and header definitions.

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // ... other configurations ...
  use: {
    // Base URL to use in actions like `await page.goto('/')`.
    baseURL: 'https://api.example.com', // Replace with your actual API base URL
    
    // API request context options
    // All requests will be sent with this context.
    // Recommended for API testing.
    apiRequestContext: {
      baseURL: 'https://api.example.com', // Replace with your actual API base URL
      extraHTTPHeaders: {
        'Accept': 'application/json',
        // 'Authorization': `Bearer ${process.env.API_TOKEN}`, // Example for authentication
      },
      // You can also add `ignoreHTTPSErrors: true` for development environments
      // or `timeout: 10000` for API request timeouts.
    },
  },
  projects: [
    {
      name: 'api',
      testMatch: /.*\.api\.spec\.ts/, // API tests typically have a distinct naming convention
      use: {
        ...devices['Desktop Chrome'],
        // You can override or add specific API context options for this project
      },
    },
    // ... other projects for UI tests ...
  ],
});
```

## Code Implementation

Let's assume we are testing a simple "posts" API that allows creating, reading, updating, and deleting posts.

```typescript
// tests/api/posts.api.spec.ts
import { test, expect, APIRequestContext } from '@playwright/test';

// Define a type for our Post object for better type safety
interface Post {
  id?: number; // ID is usually generated by the server
  title: string;
  body: string;
  userId: number;
}

test.describe('Posts API CRUD Operations', () => {
  const BASE_API_URL = 'https://jsonplaceholder.typicode.com'; // A public fake API for demonstration
  let apiContext: APIRequestContext;
  let createdPostId: number; // To store the ID of a post created for subsequent tests

  // Set up API context before all tests in this describe block
  test.beforeAll(async ({ playwright }) => {
    // Create an API request context.
    // Note: If configured globally in playwright.config.ts, you can just use the `request` fixture.
    // This explicit creation is useful for overriding global config or for dedicated API tests
    // where you want more control.
    apiContext = await playwright.request.newContext({
      baseURL: BASE_API_URL,
      extraHTTPHeaders: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    });
  });

  // Dispose of the API context after all tests in this describe block
  test.afterAll(async () => {
    await apiContext.dispose();
  });

  test('should create a new post via POST request', async () => {
    const newPost: Post = {
      title: 'Playwright API Test Post',
      body: 'This is a test post created using Playwright API.',
      userId: 1,
    };

    const response = await apiContext.post('/posts', { data: newPost });

    // Verify status code
    expect(response.status()).toBe(201); // 201 Created for successful POST

    // Verify response body
    const responseBody: Post = await response.json();
    expect(responseBody).toMatchObject(newPost); // Check if the created post matches our input
    expect(responseBody.id).toBeDefined(); // Ensure an ID was assigned by the server

    createdPostId = responseBody.id!; // Store the ID for later tests
    console.log(`Created Post ID: ${createdPostId}`);
  });

  test('should retrieve a specific post via GET request', async () => {
    test.skip(!createdPostId, 'Skipping GET test as POST failed to create a post.');

    const response = await apiContext.get(`/posts/${createdPostId}`);

    // Verify status code
    expect(response.status()).toBe(200); // 200 OK for successful GET

    // Verify response body
    const post: Post = await response.json();
    expect(post.id).toBe(createdPostId);
    expect(post.title).toBe('Playwright API Test Post');
    console.log(`Retrieved Post: ${JSON.stringify(post)}`);
  });

  test('should update an existing post via PUT request', async () => {
    test.skip(!createdPostId, 'Skipping PUT test as POST failed to create a post.');

    const updatedTitle = 'Playwright API Test Post - Updated';
    const updatedPost: Post = {
      id: createdPostId, // Include ID for PUT request
      title: updatedTitle,
      body: 'This post has been updated by Playwright API.',
      userId: 1,
    };

    const response = await apiContext.put(`/posts/${createdPostId}`, { data: updatedPost });

    // Verify status code
    expect(response.status()).toBe(200); // 200 OK for successful PUT

    // Verify response body
    const responseBody: Post = await response.json();
    expect(responseBody.id).toBe(createdPostId);
    expect(responseBody.title).toBe(updatedTitle);
    console.log(`Updated Post: ${JSON.stringify(responseBody)}`);
  });

  test('should delete a specific post via DELETE request', async () => {
    test.skip(!createdPostId, 'Skipping DELETE test as POST failed to create a post.');

    const response = await apiContext.delete(`/posts/${createdPostId}`);

    // Verify status code
    expect(response.status()).toBe(200); // 200 OK for successful DELETE (jsonplaceholder always returns 200 for DELETE)

    // Verify that the post is actually deleted (optional, depends on API behavior)
    // For jsonplaceholder, a GET after DELETE might still return the item but it's not truly deleted.
    // In a real API, you'd expect a 404 or empty response.
    const getResponseAfterDelete = await apiContext.get(`/posts/${createdPostId}`);
    expect(getResponseAfterDelete.status()).toBe(200); // jsonplaceholder returns 200 even after delete, but with empty object.
    expect(await getResponseAfterDelete.json()).toEqual({}); // Verifies empty object for jsonplaceholder

    console.log(`Deleted Post ID: ${createdPostId}`);
  });

  test('should handle a non-existent post for GET request', async () => {
    const nonExistentId = 999999;
    const response = await apiContext.get(`/posts/${nonExistentId}`);
    expect(response.status()).toBe(404); // Not Found
    expect(response.statusText()).toBe('Not Found');
  });

  test('should retrieve all posts via GET request', async () => {
    const response = await apiContext.get('/posts');
    expect(response.status()).toBe(200);
    const posts: Post[] = await response.json();
    expect(posts.length).toBeGreaterThan(0);
    expect(posts[0].userId).toBeDefined();
    expect(posts[0].title).toBeDefined();
  });
});
```

## Best Practices
- **Centralize API Configuration**: Define `baseURL`, `extraHTTPHeaders` (like `Authorization`, `Content-Type`), and potentially `timeout` in `playwright.config.ts` under `apiRequestContext` to keep your tests DRY (Don't Repeat Yourself).
- **Use `test.beforeAll` and `test.afterAll`**: For setting up and tearing down `APIRequestContext` or any prerequisite data (e.g., creating a user before all API tests). Remember to `await apiContext.dispose()` in `afterAll`.
- **Data Driven Testing**: Use data factories or test data generators to create dynamic test data, especially for POST and PUT requests, to avoid hardcoding values.
- **Assertions on Status Codes and Body**: Always assert on the HTTP status code (`expect(response.status()).toBe(200)`) and the response body content (`expect(await response.json()).toEqual(...)`).
- **Schema Validation**: For robust API testing, consider adding schema validation (e.g., using a library like `json-schema-validator`) to ensure the response body conforms to expected data structures.
- **Error Handling**: Test negative scenarios, such as invalid input, unauthorized access, or requests to non-existent endpoints, and assert on the expected error responses and status codes (e.g., 400 Bad Request, 401 Unauthorized, 404 Not Found).
- **Idempotency**: Ensure that PUT and DELETE operations can be called multiple times without side effects beyond the initial change, if your API design supports it.
- **Environment Variables**: Use environment variables for sensitive information like API keys or different base URLs for various environments (dev, staging, production).

## Common Pitfalls
- **Hardcoding URLs**: Directly embedding full URLs in every test makes tests brittle and difficult to maintain when environments changes. Use `baseURL` in configuration.
- **Ignoring Response Verification**: Just checking if a request succeeded (`response.ok()`) isn't enough. You must verify the actual data returned and the precise status code for specific scenarios.
- **Not Disposing of `APIRequestContext`**: For explicitly created contexts, failing to call `apiContext.dispose()` can lead to resource leaks.
- **Over-reliance on Global State**: While `apiRequestContext` is great for defaults, be mindful of tests unintentionally affecting each other if they modify shared resources without proper cleanup.
- **Authentication Issues**: Incorrect or expired tokens, or missing authentication headers, are common causes of API test failures. Ensure your authentication mechanism is correctly integrated and refreshed if needed.
- **Asynchronous Operations**: Forgetting `await` before API calls or `response.json()` can lead to race conditions or incorrect assertions on pending promises.

## Interview Questions & Answers
1.  **Q: How do you perform API testing using Playwright?**
    **A:** Playwright provides the `request` fixture, which is an instance of `APIRequestContext`. We can use methods like `request.get()`, `request.post()`, `request.put()`, and `request.delete()` to send HTTP requests. It's best practice to configure a `baseURL` and common headers in `playwright.config.ts` under `apiRequestContext` to centralize settings. After sending a request, I assert on the `response.status()` and `response.json()` (or `response.text()`) to verify the API's behavior.

2.  **Q: What are the advantages of using Playwright for API testing alongside UI testing?**
    **A:** The main advantage is having a unified testing framework. It allows for seamless integration of UI and API tests in the same codebase and CI/CD pipeline, reducing context switching and setup overhead. We can use API calls to set up test data quickly for UI tests (e.g., create a user via API before testing login via UI) or to clean up data after UI tests, making UI tests faster and more reliable. It also allows for end-to-end testing scenarios that involve both UI interactions and direct API validations.

3.  **Q: How do you handle authentication in Playwright API tests?**
    **A:** Authentication tokens (e.g., Bearer tokens, API keys) can be passed in `extraHTTPHeaders` within the `apiRequestContext` configuration in `playwright.config.ts`. For dynamic tokens, I might fetch the token in a `test.beforeAll` hook using a login API call, store it in a variable, and then use it to set the `Authorization` header for subsequent API requests. Environment variables should be used to store sensitive credentials.

4.  **Q: Describe a scenario where you would use an API call to set up test data for a UI test.**
    **A:** Imagine testing an e-commerce checkout flow. Instead of navigating through the UI to add multiple items to a cart, which can be slow and flaky, I would use Playwright's `APIRequestContext` to make direct API calls to add items to the user's cart before launching the browser and starting the UI checkout process. This significantly speeds up the test execution and makes the UI test more focused on the checkout UI itself, rather than the preceding steps.

## Hands-on Exercise
**Objective**: Test a public API that allows creating and managing tasks.
**API Endpoint**: You can use a mock API service like `https://gorest.co.in/public/v2/users` and then simulate a task management system on top of it, or use a tool like [JSONPlaceholder](https://jsonplaceholder.typicode.com/) for generic data. For this exercise, let's stick with JSONPlaceholder for simplicity.

**Tasks:**
1.  **Setup**: Create a new test file `tests/api/todos.api.spec.ts`.
2.  **Create (POST)**: Write a test to create a new "todo" item. Assert that the status code is 201 and the response body contains the new todo's data, including an ID.
3.  **Read (GET)**: Write a test to retrieve a specific todo item by its ID (use the ID from the previous POST test). Assert status 200 and verify the content.
4.  **Update (PUT)**: Write a test to update the title or completion status of the todo item using its ID. Assert status 200 and verify the updated data.
5.  **Delete (DELETE)**: Write a test to delete the todo item. Assert status 200. Optionally, attempt a GET request for the deleted ID to verify it's no longer accessible (expecting 404 or an empty response depending on the API).
6.  **Negative Test**: Write a test to attempt to retrieve a non-existent todo item and assert a 404 status code.

## Additional Resources
- **Playwright API Testing Documentation**: [https://playwright.dev/docs/api-testing](https://playwright.dev/docs/api-testing)
- **Playwright `APIRequestContext`**: [https://playwright.dev/docs/class-apirequestcontext](https://playwright.dev/docs/class-apirequestcontext)
- **Playwright `APIResponse`**: [https://playwright.dev/docs/class-apiresponse](https://playwright.dev/docs/class-apiresponse)
- **JSONPlaceholder (Fake API for Testing)**: [https://jsonplaceholder.typicode.com/](https://jsonplaceholder.typicode.com/)
---
# playwright-5.6-ac3.md

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
---
# playwright-5.6-ac4.md

# Playwright API Testing: Parse and Validate JSON Responses

## Overview
In modern software development, APIs (Application Programming Interfaces) are the backbone of communication between different services and applications. When testing APIs, merely checking the HTTP status code is often insufficient. A critical aspect of robust API testing involves thoroughly parsing and validating the JSON (JavaScript Object Notation) responses returned by these APIs. JSON is a lightweight data-interchange format, easy for humans to read and write, and easy for machines to parse and generate.

This document will guide you through the process of parsing JSON responses in Playwright API tests, validating their structure and content, and effectively handling potential parsing errors. Mastering these techniques is crucial for any SDET to ensure the data integrity and correctness of API endpoints.

## Detailed Explanation

Playwright's API testing capabilities provide a straightforward way to interact with HTTP endpoints and process their responses. When an API returns data in JSON format, Playwright's `response` object offers a convenient method to parse this data.

### 1. Using `await response.json()`
After making an API request, the `response` object holds the server's reply. To extract the JSON body, you use the `json()` method, which asynchronously parses the response body as JSON.

```typescript
import { test, expect } from '@playwright/test';

test('should fetch and parse JSON data', async ({ request }) => {
  const response = await request.get('https://api.example.com/users/1');
  expect(response.ok()).toBeTruthy(); // Ensure the request was successful

  const jsonResponse = await response.json();
  console.log(jsonResponse);
  // jsonResponse will be a JavaScript object that you can work with
});
```
The `json()` method returns a JavaScript object or array, allowing you to access its properties directly.

### 2. Validating Properties of the JSON Object
Once you have the parsed JSON object, validation is key. This involves checking:
*   **Presence of Expected Properties**: Ensure all required fields exist.
*   **Data Types**: Verify that properties have the correct data types (e.g., number, string, boolean).
*   **Values**: Assert that property values meet specific criteria (e.g., a specific string, a number within a range, a non-empty array).
*   **Schema Validation**: For complex JSON structures, using a JSON Schema validator can provide comprehensive structural validation.

Here's how you can perform basic property validation using Playwright's `expect` assertions:

```typescript
import { test, expect } from '@playwright/test';

test('should validate user data properties', async ({ request }) => {
  const response = await request.get('https://api.example.com/users/1');
  expect(response.ok()).toBeTruthy();

  const user = await response.json();

  // Validate presence and type of properties
  expect(user).toHaveProperty('id');
  expect(typeof user.id).toBe('number');
  expect(user.id).toBe(1); // Specific value validation

  expect(user).toHaveProperty('name');
  expect(typeof user.name).toBe('string');
  expect(user.name).not.toBe(''); // Value not empty

  expect(user).toHaveProperty('email');
  expect(typeof user.email).toBe('string');
  expect(user.email).toMatch(/@example.com$/); // Regex validation

  expect(user).toHaveProperty('address');
  expect(typeof user.address).toBe('object');
  expect(user.address).toHaveProperty('city');
  expect(typeof user.address.city).toBe('string');
});
```

For more advanced validation, especially with nested objects and arrays, you might consider external libraries like `ajv` (Another JSON Schema Validator) for schema-based validation.

### 3. Handling Potential Parsing Errors
API responses are not always perfect. A common scenario is receiving a non-JSON response when JSON was expected, or malformed JSON. The `response.json()` method will throw an error if the response body is not valid JSON. It's good practice to wrap this operation in a `try...catch` block or to check the `Content-Type` header before attempting to parse.

```typescript
import { test, expect } from '@playwright/test';

test('should handle invalid JSON response', async ({ request }) => {
  // Assume this endpoint sometimes returns plain text or malformed JSON
  const response = await request.get('https://api.example.com/malformed-json-endpoint');

  // Option 1: Check Content-Type header
  const contentType = response.headers()['content-type'];
  if (!contentType || !contentType.includes('application/json')) {
    console.warn('Expected JSON, but received:', contentType);
    // You might assert that it's not JSON if that's the expected error behavior
    expect(contentType).not.toContain('application/json');
    return; // Exit test or handle accordingly
  }

  // Option 2: Use try...catch for parsing errors
  try {
    const jsonResponse = await response.json();
    // Proceed with validation if parsing was successful
    expect(jsonResponse).toHaveProperty('status', 'error'); // Example validation
  } catch (e) {
    console.error('Failed to parse JSON response:', e.message);
    expect(e).toBeInstanceOf(Error);
    expect(e.message).toContain('Text content could not be parsed as JSON');
    // Assert specific error message or type if expected
  }
});

test('should handle API errors returning JSON', async ({ request }) => {
  // Assume this endpoint returns a JSON error object on failure
  const response = await request.get('https://api.example.com/non-existent-resource');
  expect(response.ok()).toBeFalsy(); // Expect a non-2xx status

  // Still parse JSON for error details
  try {
    const errorJson = await response.json();
    expect(errorJson).toHaveProperty('code');
    expect(errorJson).toHaveProperty('message');
    expect(typeof errorJson.code).toBe('string');
    expect(typeof errorJson.message).toBe('string');
    expect(errorJson.message).toContain('not found');
  } catch (e) {
    console.error('Failed to parse error JSON:', e.message);
    // This catch block would only be hit if the *error* response itself was malformed JSON
    throw new Error('Expected JSON error response but parsing failed.');
  }
});
```

## Code Implementation

Below is a comprehensive Playwright test file demonstrating how to parse and validate JSON responses for both successful and error scenarios.

```typescript
// playwright.config.ts (Example of how to configure API testing)
// import { defineConfig } from '@playwright/test';
// export default defineConfig({
//   use: {
//     baseURL: 'https://jsonplaceholder.typicode.com', // A public API for testing
//     extraHTTPHeaders: {
//       'Accept': 'application/json',
//     },
//   },
// });

import { test, expect, APIResponse } from '@playwright/test';

test.describe('API JSON Response Parsing and Validation', () => {

  // Test case for successful JSON response parsing and basic property validation
  test('should successfully fetch, parse, and validate a single user JSON response', async ({ request }) => {
    // 1. Send GET request to a user endpoint
    const response: APIResponse = await request.get('/users/1');

    // 2. Assert HTTP status code is 200 OK
    expect(response.status()).toBe(200);
    expect(response.ok()).toBeTruthy(); // Alternative for checking 2xx status

    // 3. Parse the JSON response body
    const user = await response.json();

    // 4. Validate the structure and data types of the JSON object
    expect(user).toBeDefined(); // Ensure the object is not null/undefined
    expect(typeof user).toBe('object'); // Ensure it's an object

    // Validate top-level properties
    expect(user).toHaveProperty('id', 1);
    expect(typeof user.id).toBe('number');
    expect(user).toHaveProperty('name', 'Leanne Graham');
    expect(typeof user.name).toBe('string');
    expect(user).toHaveProperty('username', 'Bret');
    expect(typeof user.username).toBe('string');
    expect(user).toHaveProperty('email');
    expect(typeof user.email).toBe('string');
    expect(user.email).toMatch(/^[^\s@]+@[^\s@]+\.[^\s@]+$/); // Basic email format validation

    // Validate nested 'address' object properties
    expect(user).toHaveProperty('address');
    expect(typeof user.address).toBe('object');
    expect(user.address).toHaveProperty('street');
    expect(typeof user.address.street).toBe('string');
    expect(user.address).toHaveProperty('suite');
    expect(typeof user.address.suite).toBe('string');
    expect(user.address).toHaveProperty('city', 'Gwenborough');
    expect(typeof user.address.city).toBe('string');
    expect(user.address).toHaveProperty('zipcode');
    expect(typeof user.address.zipcode).toBe('string'); // Zipcode can be string with hyphen
    expect(user.address).toHaveProperty('geo');
    expect(typeof user.address.geo).toBe('object');
    expect(user.address.geo).toHaveProperty('lat');
    expect(typeof user.address.geo.lat).toBe('string'); // Lat/Lng often strings
    expect(user.address.geo).toHaveProperty('lng');
    expect(typeof user.address.geo.lng).toBe('string');

    // Validate 'company' object properties
    expect(user).toHaveProperty('company');
    expect(typeof user.company).toBe('object');
    expect(user.company).toHaveProperty('name');
    expect(typeof user.company.name).toBe('string');
    expect(user.company).toHaveProperty('catchPhrase');
    expect(typeof user.company.catchPhrase).toBe('string');
    expect(user.company).toHaveProperty('bs');
    expect(typeof user.company.bs).toBe('string');

    console.log('Successfully validated user JSON response.');
  });

  // Test case for an array of JSON objects
  test('should fetch, parse, and validate an array of users', async ({ request }) => {
    const response: APIResponse = await request.get('/users');
    expect(response.ok()).toBeTruthy();

    const users = await response.json();
    expect(Array.isArray(users)).toBeTruthy(); // Ensure it's an array
    expect(users.length).toBeGreaterThan(0); // Ensure it's not empty

    // Validate the first user in the array as an example
    const firstUser = users[0];
    expect(firstUser).toHaveProperty('id');
    expect(typeof firstUser.id).toBe('number');
    expect(firstUser).toHaveProperty('name');
    expect(typeof firstUser.name).toBe('string');
    // ... extensive validation for firstUser similar to the single user test case
    console.log(`Validated ${users.length} users in the array.`);
  });

  // Test case for handling a 404 Not Found response that returns JSON error details
  test('should handle a 404 response with JSON error message', async ({ request }) => {
    // Attempt to get a non-existent user
    const response: APIResponse = await request.get('/users/9999');

    // Expect a 404 status code
    expect(response.status()).toBe(404);
    expect(response.ok()).toBeFalsy(); // Should not be a 2xx status

    // Attempt to parse the response body as JSON for error details
    let errorResponse: any;
    try {
      errorResponse = await response.json();
    } catch (e) {
      // This catch block would be hit if the 404 response body itself was not valid JSON
      throw new Error(`Failed to parse 404 error response as JSON: ${e.message}`);
    }

    // Validate the error JSON structure
    expect(errorResponse).toBeDefined();
    expect(typeof errorResponse).toBe('object');
    // The JSONPlaceholder API returns an empty object {} for 404 on /users/:id,
    // so we'll adapt our expectation for this specific API.
    // For other APIs, you would expect properties like 'code' or 'message'.
    expect(Object.keys(errorResponse).length).toBe(0); // Expect an empty object from jsonplaceholder for 404

    console.log('Successfully handled 404 JSON error response (empty object as per API).');
  });

  // Test case for an endpoint that returns non-JSON or malformed JSON unexpectedly
  // This is a hypothetical scenario as jsonplaceholder.typicode.com consistently returns JSON.
  // For a real-world scenario, you'd point to an API known to misbehave.
  test('should gracefully handle non-JSON or malformed JSON response', async ({ request }) => {
    // Hypothetical endpoint that might return plain text or bad JSON
    // For demonstration, we'll simulate this by manually checking content-type
    const response: APIResponse = await request.get('/posts/1'); // Using a valid endpoint to get a response

    const contentType = response.headers()['content-type'];
    console.log(`Content-Type received: ${contentType}`);

    // Simulate an incorrect content type for demonstration purposes
    const isActuallyJson = contentType && contentType.includes('application/json');

    if (!isActuallyJson) {
      console.warn('Simulating non-JSON response: Content-Type was not application/json.');
      // If we genuinely received non-JSON, we'd process the text directly
      const textResponse = await response.text();
      expect(textResponse).toBeDefined();
      expect(typeof textResponse).toBe('string');
      // Potentially assert specific text content or absence of JSON.
    } else {
      let parsedJson: any;
      try {
        parsedJson = await response.json();
        expect(parsedJson).toHaveProperty('userId');
        expect(parsedJson).toHaveProperty('id');
        expect(parsedJson).toHaveProperty('title');
        console.log('Successfully parsed and validated a valid JSON response (simulated non-JSON not triggered).');
      } catch (e) {
        console.error('Caught expected JSON parsing error:', e.message);
        expect(e).toBeInstanceOf(Error);
        expect(e.message).toContain('Text content could not be parsed as JSON');
        // If this were a real endpoint returning malformed JSON, this block would execute.
        console.log('Successfully caught JSON parsing error for simulated malformed JSON.');
      }
    }
  });
});
```

## Best Practices
- **Early Content-Type Check**: Before calling `response.json()`, consider checking the `Content-Type` header. If it's not `application/json`, you might want to handle it as a different type of response (e.g., `response.text()`) or assert an error.
- **Granular Assertions**: Break down complex JSON validation into smaller, focused `expect` assertions for individual properties or nested objects. This makes tests easier to read, debug, and maintain.
- **Use JSON Schema for Complex Structures**: For very complex or frequently changing JSON structures, integrate a JSON Schema validation library (like `ajv`). This allows you to define your expected JSON structure in a separate schema file and validate the response against it, providing powerful and flexible validation.
- **Reusable Validation Functions**: Create helper functions for validating common JSON patterns or structures to avoid code duplication and improve maintainability.
- **Handle Edge Cases**: Always test for scenarios like empty arrays, null values, missing optional fields, and unexpected data types.
- **Log Responses**: In debugging, it's invaluable to log the full JSON response (or parts of it) to the console to understand what the API is actually returning.

## Common Pitfalls
- **Assuming JSON Content**: Not all API responses are JSON, even if you expect them to be. A server might return HTML for an error page, or plain text. Always verify the `Content-Type` or use `try...catch` when parsing.
- **Ignoring HTTP Status Codes**: Even if the response is valid JSON, a non-2xx HTTP status code usually indicates an error. Always assert the status code (e.g., `expect(response.ok()).toBeTruthy()`) before diving into JSON validation for success scenarios.
- **Brittle Assertions**: Overly strict assertions that expect exact values for dynamic data (like timestamps, generated IDs, or user-specific data) can lead to flaky tests. Use more flexible assertions like `typeof`, `toMatch`, `toBeGreaterThan`, or `toContain`.
- **Deep Nesting Without Helper Functions**: Manually traversing deeply nested JSON objects with many `expect(obj.prop.subProp.value).toBe(...)` can become unreadable and hard to maintain. Use helper functions or JSON schema for such cases.
- **Not Testing Error Responses**: Many developers focus only on successful responses. It's equally important to test that error responses (e.g., 400 Bad Request, 401 Unauthorized, 404 Not Found, 500 Internal Server Error) return meaningful JSON error bodies with appropriate status codes.

## Interview Questions & Answers

1.  **Q: How do you handle JSON response validation in your API automation framework?**
    **A:** I typically start by using the framework's built-in methods to parse the JSON body (e.g., Playwright's `response.json()`). Then, I use assertion libraries (like Playwright's `expect` or Chai/Jasmine for other frameworks) to validate key properties: checking for existence (`toHaveProperty`), data types (`typeof`), and expected values. For complex schemas, I integrate JSON Schema validation libraries like `ajv` to ensure the overall structure and data integrity. I also ensure robust error handling around JSON parsing.

2.  **Q: What are the common challenges you face when validating JSON responses, and how do you overcome them?**
    **A:** Common challenges include dynamic data (timestamps, IDs), varying schemas between environments, and unexpected non-JSON responses. I overcome these by:
    *   **Dynamic Data**: Using flexible assertions (e.g., `toBeDefined`, `typeof`, regex `toMatch`) instead of strict equality for dynamic fields.
    *   **Varying Schemas**: Implementing JSON Schema validation, which provides a flexible way to define and validate schema variations. I might have different schema files for different API versions or environments.
    *   **Non-JSON Responses**: Always checking the `Content-Type` header or wrapping `response.json()` calls in `try...catch` blocks to gracefully handle and assert non-JSON or malformed responses.

3.  **Q: Explain the difference between validating JSON structure and validating JSON content.**
    **A:**
    *   **JSON Structure Validation**: This focuses on ensuring the JSON response adheres to an expected format. It checks for the presence of specific keys, their data types (e.g., string, number, boolean, object, array), and the nesting hierarchy of objects and arrays. It ensures the "shape" of the data is correct. JSON Schema is an excellent tool for structural validation.
    *   **JSON Content Validation**: This goes deeper, verifying the actual *values* within the JSON response. It involves asserting that a specific field has an expected string, a number falls within a certain range, an array contains specific elements, or a boolean is true/false. This ensures the "meaning" of the data is correct.

## Hands-on Exercise

**Scenario:** You are testing a public API endpoint `https://jsonplaceholder.typicode.com/posts/1/comments`. This endpoint returns an array of comments associated with a specific post.

**Task:**
1.  Write a Playwright API test that sends a GET request to this endpoint.
2.  Assert that the HTTP status code is 200.
3.  Parse the JSON response into an array of JavaScript objects.
4.  Validate that the response is indeed an array and contains at least one comment.
5.  For the first comment in the array, validate the following properties:
    *   `postId` (should be a number and equal to 1)
    *   `id` (should be a number and defined)
    *   `name` (should be a string and not empty)
    *   `email` (should be a string and match a basic email regex pattern like `^[^\s@]+@[^\s@]+\.[^\s@]+$`)
    *   `body` (should be a string and not empty)
6.  Add a `try...catch` block around the `response.json()` call to handle potential parsing errors gracefully.

## Additional Resources
-   **Playwright API Testing Documentation**: [https://playwright.dev/docs/api-testing](https://playwright.dev/docs/api-testing)
-   **JSONPlaceholder (for practice APIs)**: [https://jsonplaceholder.typicode.com/](https://jsonplaceholder.typicode.com/)
-   **AJV (Another JSON Schema Validator)**: [https://ajv.js.org/](https://ajv.js.org/)
-   **MDN Web Docs - JSON**: [https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON)
---
# playwright-5.6-ac5.md

# Chaining API Calls and Integrating with UI Tests in Playwright

## Overview
This feature explores a crucial aspect of robust test automation: integrating API calls directly into UI test flows. By chaining API calls and using their responses within subsequent UI interactions, we can achieve more efficient, reliable, and faster tests. This approach is particularly valuable for setting up test preconditions (e.g., creating test data), interacting with backend services independently of the UI, and cleaning up resources after tests.

## Detailed Explanation
In many real-world scenarios, UI tests depend on specific data or system states that are complex to set up purely through the UI. For instance, testing a user's dashboard might require a pre-existing user account with specific permissions or data. Instead of navigating through multiple UI screens to create this setup data, we can leverage Playwright's API testing capabilities to create, modify, or delete data directly via API calls.

The process typically involves:
1.  **Making an initial API request**: For example, to register a new user, create a product, or fetch some configuration.
2.  **Extracting relevant data**: From the API response (e.g., user ID, authentication token, session cookies), which is then used to parameterize subsequent steps.
3.  **Using extracted data in UI tests**: Passing the data (e.g., user credentials, item IDs) to fill forms, construct URLs, or assert UI elements.
4.  **Chaining further API requests**: Potentially using data from the UI interaction to perform cleanup actions or further verification via API.

This approach significantly reduces test execution time, makes tests less flaky (as API calls are generally faster and more stable than UI interactions for setup), and improves test data management.

## Code Implementation
```typescript
// playwright.config.ts (example setup for API testing)
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Look for test files in the "tests" directory, relative to this configuration file.
  testDir: './tests',
  // Run all tests in parallel.
  fullyParallel: true,
  // Fail the build on CI if you accidentally left test.only in the source code.
  forbidOnly: !!process.env.CI,
  // Retry on CI only.
  retries: process.env.CI ? 2 : 0,
  // Opt out of parallel tests on CI.
  workers: process.env.CI ? 1 : undefined,
  // Reporter to use. See https://playwright.dev/docs/test-reporters
  reporter: 'html',
  // Shared settings for all projects. See https://playwright.dev/docs/api/class-testoptions
  use: {
    // Base URL to use in actions like `await page.goto('/')`.
    baseURL: 'http://localhost:3000', // Replace with your application's base URL
    // Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer
    trace: 'on-first-retry',
    // APIRequestContext for making API calls
    // https://playwright.dev/docs/api/class-apirequestcontext
    // This allows API calls to respect baseURL, extraHTTPHeaders etc. defined here
    // and also handles cookies/auth if context is shared with browser.
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    // Add an API-only project if you have extensive API tests separate from UI
    {
      name: 'API',
      use: {
        baseURL: 'http://localhost:3001/api', // Replace with your API's base URL
        extraHTTPHeaders: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      },
    },
  ],
});
```

```typescript
// tests/api-ui-chaining.spec.ts
import { test, expect } from '@playwright/test';

// Define a test user
const testUser = {
  email: `testuser-${Date.now()}@example.com`,
  password: 'Password123!',
  username: `testuser${Date.now()}`
};

test.describe('API and UI Chaining Test', () => {
  let userId: string; // To store the user ID created via API

  test.beforeAll(async ({ request }) => {
    // 1. Create user via API
    // Ensure your API endpoint for user creation is correct
    const createUserResponse = await request.post('/users', {
      data: testUser,
    });
    expect(createUserResponse.ok()).toBeTruthy();
    const newUser = await createUserResponse.json();
    userId = newUser.id; // Assuming the API returns the created user's ID
    console.log(`Created user with ID: ${userId}`);
  });

  test('should create user via API, login via UI, and verify welcome message', async ({ page, baseURL }) => {
    // Navigate to the login page of your UI application
    await page.goto(`${baseURL}/login`); // Replace with your login path

    // Fill login form using the API-created user's credentials
    await page.fill('input[name="email"]', testUser.email); // Adjust selectors as per your UI
    await page.fill('input[name="password"]', testUser.password);
    await page.click('button[type="submit"]'); // Adjust selector as per your UI

    // Verify successful login by checking a UI element, e.g., a welcome message
    await expect(page.locator('.welcome-message')).toContainText(`Welcome, ${testUser.username}!`);
    console.log('Successfully logged in via UI with API-created user.');

    // Optionally, perform further UI interactions or assertions
    // await page.locator('nav a[href="/dashboard"]').click();
    // await expect(page.locator('.dashboard-title')).toContainText('Dashboard');
  });

  test.afterAll(async ({ request }) => {
    // 3. Delete user via API in teardown
    // Ensure your API endpoint for user deletion is correct and requires the user ID
    if (userId) {
      const deleteUserResponse = await request.delete(`/users/${userId}`);
      expect(deleteUserResponse.ok()).toBeTruthy();
      console.log(`Deleted user with ID: ${userId}`);
    } else {
      console.warn('User ID not found, skipping user deletion.');
    }
  });
});
```

## Best Practices
-   **Isolate Test Data**: Always create and clean up test data within your tests (e.g., `beforeAll`/`afterAll` or `beforeEach`/`afterEach` hooks). Avoid relying on pre-existing data that might change.
-   **Use Playwright's `request` Fixture**: For API calls, leverage Playwright's built-in `request` fixture, which provides `APIRequestContext` and respects settings from `playwright.config.ts` (like `baseURL`, `extraHTTPHeaders`).
-   **Error Handling and Assertions**: Always assert API response statuses (`.ok()`) and handle potential errors. Validate the structure and content of API responses using `expect`.
-   **Meaningful Data Extraction**: Extract only the necessary data from API responses. Over-extracting can make your tests brittle.
-   **Type Safety (TypeScript)**: Define interfaces for your API request/response bodies to ensure type safety and better autocompletion.
-   **Configuration for APIs**: Centralize API base URLs and headers in `playwright.config.ts` for easier management across multiple API calls.
-   **Performance Considerations**: While API calls are fast, avoid unnecessary calls. Only use them when UI setup is cumbersome or flaky.

## Common Pitfalls
-   **Not Cleaning Up Test Data**: Failing to delete created users or data can lead to test pollution, unexpected test failures, and database bloat, especially in shared test environments.
-   **Hardcoding Values**: Avoid hardcoding IDs, tokens, or other dynamic data from API responses. Always extract and pass them programmatically.
-   **Ignoring API Response Status**: Not checking if an API call was successful (`response.ok()`) can mask issues and lead to subsequent failures that are hard to debug.
-   **Security Credentials in Code**: Never hardcode sensitive API keys or credentials directly in your test files. Use environment variables or secure configuration management.
-   **Over-reliance on APIs for UI Testing**: While API calls are great for setup, the core logic of a UI test should still exercise the UI. Don't replace critical UI interactions with API calls if the goal is to test the UI flow.

## Interview Questions & Answers
1.  **Q**: Why is chaining API calls with UI tests beneficial in test automation?
    **A**: It significantly improves test efficiency and reliability. API calls are generally faster and less flaky for setting up test preconditions (e.g., creating users, configuring data) compared to complex UI navigations. This allows UI tests to focus purely on UI interactions and validations, making them more stable and quicker to execute. It also helps manage test data effectively.
2.  **Q**: How would you handle authentication tokens when chaining API calls with UI tests in Playwright?
    **A**: After an API call authenticates a user (e.g., login API), the response often contains an authentication token (JWT) or sets session cookies. This token/cookie can be extracted from the API response and then injected into the Playwright `page` or `context` for subsequent UI interactions. Playwright's `request` fixture handles cookies automatically if `baseURL` is shared with the UI `page` context, or you can manually add headers (`extraHTTPHeaders` or `page.setExtraHTTPHeaders`). For tokens, you might set them in local storage via `page.evaluate()` or as an `Authorization` header for subsequent API calls.
3.  **Q**: What are some best practices for managing test data when integrating API and UI tests?
    **A**: Key practices include:
    *   **Data Isolation**: Each test should ideally create its own unique test data to prevent interference between tests.
    *   **Setup/Teardown**: Use `beforeAll`/`afterAll` or `beforeEach`/`afterEach` hooks to create data before tests and clean it up afterward using API calls.
    *   **Data Factories**: Implement data factory patterns or helper functions to easily generate different types of test data.
    *   **Parameterized Tests**: Use test parameters to run the same test logic with various data sets.
    *   **Assertions on Data**: Verify that API calls successfully created/modified the expected data.

## Hands-on Exercise
Modify the provided `api-ui-chaining.spec.ts` example. Assume a more complex scenario where after logging in, the user creates a "To-Do" item via the UI. Your task is to:
1.  Add a UI interaction to create a To-Do item after successful login.
2.  Before `afterAll`, add an API call to verify that the To-Do item was successfully created (e.g., fetch all To-Do items for the user via API and assert the presence of the new item).
3.  In `afterAll`, ensure that not only the user is deleted, but also any To-Do items associated with that user are cleaned up via API calls.

## Additional Resources
-   **Playwright API Testing Documentation**: [https://playwright.dev/docs/api-testing](https://playwright.dev/docs/api-testing)
-   **Playwright Test Fixtures**: [https://playwright.dev/docs/test-fixtures](https://playwright.dev/docs/test-fixtures)
-   **Real-world Playwright Example (GitHub)**: [https://github.com/microsoft/playwright/tree/main/examples/todomvc](https://github.com/microsoft/playwright/tree/main/examples/todomvc) (While not direct API chaining, it shows robust UI testing)
---
# playwright-5.6-ac6.md

# Playwright API Testing: Implement API-based Test Data Setup

## Overview
In modern web applications, UI tests often depend on specific data being present in the system. Manually setting up this data through the UI before each test can be slow and brittle. API-based test data setup offers a more efficient, reliable, and faster alternative. This approach leverages the application's backend APIs to create, modify, or delete test data programmatically, ensuring that UI tests run against a known and consistent state. This improves test execution speed, reduces flakiness, and isolates UI tests from data creation complexities.

## Detailed Explanation
API-based test data setup involves making direct HTTP requests to your application's API endpoints to manipulate data. Playwright provides excellent capabilities for this through its `APIRequestContext` object, which allows you to send various HTTP methods (GET, POST, PUT, DELETE, PATCH) and handle responses within your test suite.

The typical workflow is:
1.  **Before UI Test Execution**: Use `APIRequestContext` to make API calls to create the necessary test data.
2.  **UI Test Execution**: Run the UI test, which now operates on the pre-configured data.
3.  **After UI Test Execution (Optional but Recommended)**: Use `APIRequestContext` to clean up the test data, ensuring test isolation and a clean state for subsequent tests.

A `TestDataManager` class encapsulates this logic, making it reusable and maintaining a clear separation of concerns between data setup and UI test steps.

**Why use API for Test Data Setup?**
*   **Speed**: API calls are significantly faster than navigating through UI elements.
*   **Reliability**: Less prone to UI changes or rendering issues.
*   **Isolation**: Each test can have its own dedicated data, preventing interference between tests.
*   **Maintainability**: Centralizing data setup logic in a `TestDataManager` makes it easier to update and manage.

## Code Implementation

Let's create a `TestDataManager` using TypeScript and Playwright's `APIRequestContext`.

First, ensure you have Playwright configured for API testing. You might add an `api` project to your `playwright.config.ts`:

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
    trace: 'on-first-retry',
    // Base URL for UI tests
    baseURL: 'http://localhost:3000',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    // Project for API testing (optional, but good for separate API-only tests)
    // However, APIRequestContext can be used directly in UI tests for setup.
    {
      name: 'api',
      use: {
        // Important: Base URL for API calls
        baseURL: 'http://localhost:8080/api', // Adjust to your API's base URL
        extraHTTPHeaders: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      },
    },
  ],
});
```

Now, let's implement the `TestDataManager` and an example UI test.

```typescript
// utils/TestDataManager.ts
import { APIRequestContext, expect } from '@playwright/test';

/**
 * Manages the creation and cleanup of test data via API calls.
 */
export class TestDataManager {
  private apiContext: APIRequestContext;
  private createdDataIds: string[] = []; // To keep track of created data for cleanup

  constructor(apiContext: APIRequestContext) {
    this.apiContext = apiContext;
  }

  /**
   * Creates a new product using the API.
   * @param productName The name of the product to create.
   * @param price The price of the product.
   * @returns The ID of the created product.
   */
  async createProduct(productName: string, price: number): Promise<string> {
    console.log(`Creating product: ${productName} with price ${price}`);
    const response = await this.apiContext.post('/products', {
      data: { name: productName, price: price, description: 'Test product' },
    });
    
    // Ensure the API call was successful
    expect(response.status()).toBe(201); // Assuming 201 Created for successful creation

    const product = await response.json();
    this.createdDataIds.push(product.id); // Store ID for cleanup
    console.log(`Product created with ID: ${product.id}`);
    return product.id;
  }

  /**
   * Cleans up all data created by this manager instance.
   */
  async cleanupCreatedData(): Promise<void> {
    console.log(`Cleaning up ${this.createdDataIds.length} items...`);
    for (const id of this.createdDataIds) {
      console.log(`Deleting product with ID: ${id}`);
      const response = await this.apiContext.delete(`/products/${id}`);
      expect(response.status()).toBe(204); // Assuming 204 No Content for successful deletion
    }
    this.createdDataIds = []; // Clear the list after cleanup
    console.log('Test data cleanup complete.');
  }

  // You can add more data creation/manipulation methods here, e.g., createUser, createOrder, etc.
  // async createUser(username: string, email: string): Promise<string> { ... }
}
```

Now, an example UI test that uses this `TestDataManager`:

```typescript
// tests/product.spec.ts
import { test, expect } from '@playwright/test';
import { TestDataManager } from '../utils/TestDataManager';

let testDataManager: TestDataManager;
let productId: string;
const testProductName = 'API Created Product';
const testProductPrice = 99.99;

test.beforeAll(async ({ playwright }) => {
  // Create an API context specifically for data setup/cleanup
  // Use the 'api' project defined in playwright.config.ts for its baseURL and headers
  const apiContext = await playwright.request.newContext({
    baseURL: 'http://localhost:8080/api', // Must match your API base URL
    extraHTTPHeaders: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  });
  testDataManager = new TestDataManager(apiContext);

  // --- Call createData() before UI test ---
  productId = await testDataManager.createProduct(testProductName, testProductPrice);
});

test.afterAll(async () => {
  // Clean up data after all tests in this file are done
  await testDataManager.cleanupCreatedData();
});

test('should display API created product on the products page', async ({ page }) => {
  await page.goto('/products'); // Navigate to the UI page where products are displayed

  // --- Verify UI shows the created data ---
  await expect(page.locator(`.product-card:has-text("${testProductName}")`)).toBeVisible();
  await expect(page.locator(`.product-card:has-text("${testProductName}") .product-price`)).toHaveText(`$${testProductPrice.toFixed(2)}`);

  // Optionally, navigate to the product detail page and verify
  await page.locator(`.product-card:has-text("${testProductName}") a`).click();
  await expect(page.url()).toContain(`/products/${productId}`);
  await expect(page.locator('h1')).toHaveText(testProductName);
  await expect(page.locator('.product-detail-price')).toHaveText(`Price: $${testProductPrice.toFixed(2)}`);
});
```

**Note**: For this code to run, you would need a running backend API (e.g., on `http://localhost:8080/api`) that exposes `/products` and `/products/:id` endpoints, and a frontend application (e.g., on `http://localhost:3000`) that displays these products.

## Best Practices
-   **Isolate Test Data**: Each test (or test suite) should ideally operate on its own unique dataset to prevent test interdependencies and flakiness.
-   **Cleanup**: Always clean up created test data using `afterEach` or `afterAll` hooks to maintain a clean test environment.
-   **Centralize Data Management**: Encapsulate data creation and cleanup logic within a dedicated class (e.g., `TestDataManager`) for reusability and maintainability.
-   **Error Handling**: Implement robust error handling for API calls to catch issues during data setup.
-   **Avoid Over-reliance**: While powerful, don't use API setup to entirely bypass UI interactions that are critical to the user journey. Balance API and UI interactions.
-   **Authentication**: If your API requires authentication, ensure `APIRequestContext` is configured with necessary tokens or cookies.

## Common Pitfalls
-   **Hardcoding Data**: Avoid hardcoding test data directly in tests. Use dynamic data generation or parameterized tests.
-   **Missing Cleanup**: Forgetting to clean up data can lead to data pollution and affect subsequent tests.
-   **Incorrect API Endpoints/Payloads**: Mismatches between test API calls and actual API specifications can cause setup failures. Use API documentation or tools like Postman/Insomnia to verify.
-   **Security**: Be mindful of exposing sensitive credentials when setting up API contexts, especially in CI/CD environments. Use environment variables.
-   **Network Issues**: API calls can fail due to network instability. Implement retries or robust error handling.

## Interview Questions & Answers
1.  **Q: Why is API-based test data setup preferred over UI-based setup for automation?**
    **A:** API-based setup is significantly faster, more reliable, and less susceptible to UI changes. It helps isolate tests by providing a clean, known data state for each test, reducing flakiness and improving test suite execution time. UI-based setup is slow, resource-intensive, and prone to breaking with minor UI modifications.

2.  **Q: How do you handle authentication when performing API calls for test data setup in Playwright?**
    **A:** Playwright's `APIRequestContext` can be configured with `extraHTTPHeaders` to include authentication tokens (e.g., Bearer tokens for JWT) or `storageState` to reuse authenticated sessions obtained from a previous UI login. For basic authentication, credentials can be included directly in the `baseURL` or headers.

3.  **Q: Describe a scenario where you would still use some UI interaction for data setup, even with API capabilities.**
    **A:** If the data creation process itself involves complex UI flows that are critical to the application's core functionality and need to be end-to-end tested, then a hybrid approach might be taken. For instance, testing a user onboarding process might start with API to create a base user, but then use UI to complete a profile setup form that involves specific visual validations or complex drag-and-drop interactions.

4.  **Q: What strategies do you employ to ensure test data is cleaned up effectively after tests using API setup?**
    **A:** I use `afterEach` or `afterAll` hooks in Playwright. A common pattern is to collect IDs of created resources in a `TestDataManager` class and then iterate through them in the cleanup hook, making API DELETE requests to remove them. This ensures the environment is reset for subsequent tests or runs.

## Hands-on Exercise
**Scenario**: You are testing an e-commerce application. Before testing the "add to cart" functionality on the UI, you need to ensure a specific product with sufficient stock is available.

**Task**:
1.  Extend the `TestDataManager` to include a method `createProductWithStock(productName: string, price: number, stock: number): Promise<string>`. Assume your API has a `/products` endpoint that accepts `stock` as a field.
2.  Create a new Playwright test file (`cart.spec.ts`).
3.  In `beforeAll`, use your extended `TestDataManager` to create a product (e.g., "Exclusive Gadget", $150.00, 10 units in stock).
4.  In the UI test, navigate to the product page for this newly created product.
5.  Verify that the product name, price, and available stock are displayed correctly.
6.  Click the "Add to Cart" button and verify a success message or that the cart icon updates.
7.  Ensure proper cleanup in `afterAll`.

**Expected Output (Conceptual):**
-   API call to create product successful (status 201).
-   UI displays "Exclusive Gadget", "$150.00", "Stock: 10".
-   "Add to Cart" button is enabled and clicking it adds to cart.
-   API call(s) to delete product successful (status 204).

## Additional Resources
-   **Playwright API Testing Documentation**: [https://playwright.dev/docs/api-testing](https://playwright.dev/docs/api-testing)
-   **Playwright Test Fixtures (Advanced)**: [https://playwright.dev/docs/test-fixtures](https://playwright.dev/docs/test-fixtures) (For more complex shared setup/teardown)
-   **RESTful API Design Best Practices**: [https://restfulapi.net/rest-api-design-rules/](https://restfulapi.net/rest-api-design-rules/)
---
# playwright-5.6-ac7.md

# Playwright - Hybrid UI and API Testing

## Overview
Hybrid UI and API testing in Playwright involves orchestrating interactions between the user interface and direct API calls within a single test scenario. This approach is highly effective for validating end-to-end flows where UI actions trigger backend changes, and those changes need immediate verification or further UI manipulation. It allows for more efficient, stable, and comprehensive tests by bypassing slow UI interactions for backend state validation or setup.

## Detailed Explanation
Traditional UI tests can be slow and brittle, especially when verifying complex backend states. API tests, while fast, don't cover the user experience. Hybrid tests bridge this gap.

Consider a scenario where a user submits an order via a web form.
1.  **Trigger action in UI**: The test interacts with the UI to fill out the form and click "Submit Order".
2.  **Verify backend state via API call immediately**: Instead of navigating to an "Order History" page and parsing UI elements (which can be slow and susceptible to UI changes), the test makes a direct API call to the backend's order endpoint to fetch the newly created order. This is faster and more reliable.
3.  **Assert consistency between UI message and API data**: The test then asserts that the success message displayed on the UI (e.g., "Order #123 placed successfully") matches the order ID retrieved from the API. This ensures both the UI feedback and the backend processing are correct.

This approach provides high confidence in the application's functionality, ensuring that UI actions correctly interact with the backend services and that the user receives accurate feedback. It also speeds up test execution by minimizing reliance on slow UI traversals for verification steps that can be done more efficiently via API.

## Code Implementation
This example demonstrates a hybrid test where a user submits a form, and the backend state is immediately verified via an API call.

```typescript
import { test, expect, APIResponse } from '@playwright/test';

// Assume a base URL for the UI and an API endpoint
const UI_BASE_URL = 'http://localhost:3000';
const API_BASE_URL = 'http://localhost:8080/api';

test.describe('Hybrid UI and API Testing for Order Placement', () => {

  // Before each test, potentially clear some state or log in via API
  test.beforeEach(async ({ page, request }) => {
    // Example: Log in via API to set up authenticated session for UI tests
    const loginResponse = await request.post(`${API_BASE_URL}/auth/login`, {
      data: { username: 'testuser', password: 'password123' },
    });
    expect(loginResponse.status()).toBe(200);
    // You might set a cookie or local storage item from the API response
    // if needed for the UI session, e.g.:
    // const authCookie = loginResponse.headers()['set-cookie'];
    // await page.context().addCookies([{ name: 'authToken', value: '...', url: UI_BASE_URL }]);
    await page.goto(UI_BASE_URL + '/order-form');
  });

  test('should allow user to place an order and verify via API', async ({ page, request }) => {
    const productName = 'Playwright Test Widget';
    const quantity = 5;

    // 1. Trigger action in UI (e.g., 'Submit Order')
    await page.fill('input[name="productName"]', productName);
    await page.fill('input[name="quantity"]', quantity.toString());
    await page.click('button[type="submit"]');

    // Wait for a success message or navigation
    await expect(page.locator('.success-message')).toContainText('Order placed successfully!');

    // Extract order ID from UI message (e.g., "Order placed successfully! Your ID: ORD-123")
    const successMessageText = await page.locator('.success-message').innerText();
    const orderIdMatch = successMessageText.match(/Your ID: (ORD-\d+)/);
    expect(orderIdMatch).not.toBeNull();
    const uiOrderId = orderIdMatch![1]; // Use '!' for non-null assertion as we've checked it

    // 2. Verify backend state via API call immediately
    // Make an API call to fetch the order details using the ID obtained from UI
    const orderDetailsResponse: APIResponse = await request.get(`${API_BASE_URL}/orders/${uiOrderId}`);
    expect(orderDetailsResponse.status()).toBe(200);

    const orderDetails = await orderDetailsResponse.json();

    // 3. Assert consistency between UI message and API data
    expect(orderDetails.id).toBe(uiOrderId);
    expect(orderDetails.productName).toBe(productName);
    expect(orderDetails.quantity).toBe(quantity);
    expect(orderDetails.status).toBe('PENDING'); // Assuming initial status

    console.log(`Successfully verified order ${uiOrderId} through both UI and API.`);
  });

  test('should handle invalid order submission gracefully in UI and not create order in API', async ({ page, request }) => {
    // Attempt to submit an order with invalid data (e.g., negative quantity)
    await page.fill('input[name="productName"]', 'Invalid Product');
    await page.fill('input[name="quantity"]', '-1');
    await page.click('button[type="submit"]');

    // Expect an error message in the UI
    await expect(page.locator('.error-message')).toContainText('Quantity must be positive');

    // Verify via API that no new order was created with this invalid data
    // This might involve fetching all orders and asserting the count hasn't increased
    // Or attempting to fetch by a known bad ID, expecting a 404
    const allOrdersResponse = await request.get(`${API_BASE_URL}/orders`);
    expect(allOrdersResponse.status()).toBe(200);
    const allOrders = await allOrdersResponse.json();
    
    // Assert that 'Invalid Product' is not found in the list of orders
    const invalidOrderFound = allOrders.some((order: any) => order.productName === 'Invalid Product');
    expect(invalidOrderFound).toBe(false);
  });
});
```

## Best Practices
-   **Identify API opportunities**: Look for scenarios where verifying backend state (e.g., database changes, new entity creation) can be done more reliably and faster via API than through the UI.
-   **Use API for setup**: Instead of navigating through multiple UI pages to reach a test state, use API calls to set up prerequisites (e.g., create users, populate data, log in).
-   **Clear separation of concerns**: While hybrid, try to keep UI interactions focused on user-facing workflows and API calls focused on data verification or setup.
-   **Error handling**: Ensure your API calls within tests have proper error handling and assertions for expected API responses (e.g., status codes, error messages).
-   **Parameterization**: Make API endpoints and test data configurable to easily switch between environments or test different scenarios.

## Common Pitfalls
-   **Over-reliance on UI**: Performing UI interactions for every verification step, even when an API call would be more efficient, leads to slow and flaky tests.
-   **Neglecting UI feedback**: Focusing too much on API verification and forgetting to assert that the user receives correct visual feedback or error messages in the UI.
-   **Session management issues**: Not correctly managing authentication tokens or session cookies between API calls and UI interactions, leading to unauthorized requests. Playwright's `request` context automatically handles cookies from `page` context, but explicit management might be needed for complex scenarios.
-   **Brittle selectors for UI data extraction**: Relying on unstable UI selectors to extract data (like an order ID) that is then used in API calls. Ensure these selectors are robust.

## Interview Questions & Answers
1.  **Q: What is hybrid UI and API testing, and when would you use it?**
    A: Hybrid UI and API testing combines interactions with the user interface and direct calls to backend APIs within a single test. You'd use it when you need to validate end-to-end user flows that involve UI actions triggering backend logic, but where direct API verification is faster or more reliable than solely relying on UI observations. It's particularly useful for setting up test data, verifying complex backend states, or asserting data consistency between UI and API.

2.  **Q: How does Playwright facilitate hybrid testing?**
    A: Playwright provides two main contexts: `page` for UI interactions and `request` for making direct HTTP API calls. The `request` fixture allows sending authenticated HTTP requests, often reusing the browser's cookies and authentication state, making it seamless to transition between UI actions and API verifications within the same test.

3.  **Q: Can you give an example of a scenario where hybrid testing would significantly improve test efficiency?**
    A: Consider an e-commerce application. Instead of:
    *   Navigating through UI to create a user.
    *   Navigating through UI to add items to a cart.
    *   Navigating through UI to place an order.
    *   Navigating through UI to check order status.
    You could:
    *   Use an **API call** to create a test user.
    *   Use an **API call** to add items to the cart.
    *   Interact with the **UI** to place the order.
    *   Use an **API call** to immediately verify the order status and details without navigating to an order history page in the UI.
    This significantly reduces test execution time and flakiness by reducing UI interaction.

## Hands-on Exercise
**Scenario**: Imagine a simple "To-Do List" application.
1.  Navigate to the To-Do List UI.
2.  Add a new To-Do item via the UI (e.g., "Learn Hybrid Testing").
3.  Immediately after adding, use a Playwright API call to fetch all To-Do items from the backend API endpoint (e.g., `/api/todos`).
4.  Assert that the newly added item exists in the API response and that its status is "pending".
5.  (Optional) Use another API call to mark the To-Do item as "completed" and then verify in the UI that its status has updated.

## Additional Resources
-   **Playwright API testing documentation**: [https://playwright.dev/docs/api-testing](https://playwright.dev/docs/api-testing)
-   **Playwright Test Runner**: [https://playwright.dev/docs/test-runner](https://playwright.dev/docs/test-runner)
-   **Blog: Playwright API Testing – The Ultimate Guide**: [https://www.ultimateqa.com/playwright-api-testing/](https://www.ultimateqa.com/playwright-api-testing/) (Note: May need to search for an updated link if this one is broken, as blog links can change)
