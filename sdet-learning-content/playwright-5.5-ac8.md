# Playwright: Waiting for Specific Network Requests/Responses

## Overview
In modern web applications, client-side interactions often trigger asynchronous network requests to fetch or submit data. Robust test automation requires the ability to wait for and assert on these network activities to ensure that the application state is correctly updated and that data integrity is maintained. Playwright provides powerful APIs like `page.waitForRequest()` and `page.waitForResponse()` that allow testers to precisely control and synchronize their tests with network events. This is crucial for testing complex user flows, validating data submissions, and ensuring that your tests are not flaky due to timing issues.

## Detailed Explanation
Playwright's `page.waitForRequest()` and `page.waitForResponse()` methods are essential for handling asynchronous operations that involve network communication. These methods return a Promise that resolves when a network request or response matching a given predicate (condition) is observed.

### `page.waitForRequest(urlOrPredicate[, options])`
This method waits for a network request to be initiated that matches the specified URL or predicate function.

- **`urlOrPredicate`**: Can be a string, a regular expression, or a function.
    - **String**: Matches the URL exactly.
    - **Regular Expression**: Matches the URL against the regex.
    - **Function**: A predicate function that receives the `Request` object and returns `true` if it's the desired request, `false` otherwise. This offers the most flexibility for complex matching criteria (e.g., checking request method, headers, or post data).
- **`options`**:
    - **`timeout`**: Maximum time in milliseconds to wait for the event. Defaults to 30000ms.

### `page.waitForResponse(urlOrPredicate[, options])`
Similar to `waitForRequest()`, this method waits for a network *response* to be received that matches the specified URL or predicate function. This is particularly useful for asserting on response status, headers, or body content.

- **`urlOrPredicate`**: Can be a string, a regular expression, or a function.
    - **String**: Matches the URL of the response exactly.
    - **Regular Expression**: Matches the URL of the response against the regex.
    - **Function**: A predicate function that receives the `Response` object and returns `true` if it's the desired response, `false` otherwise. This allows for checking response status, headers, or even parsing the response body.
- **`options`**:
    - **`timeout`**: Maximum time in milliseconds to wait for the event. Defaults to 30000ms.

### Workflow:
1. **Define the expectation**: Determine which request or response you need to wait for (e.g., a specific API endpoint, a file download).
2. **Start waiting**: Call `page.waitForRequest()` or `page.waitForResponse()` *before* triggering the action that causes the network event. Store the returned Promise.
3. **Trigger action**: Perform the user interaction or code execution that initiates the network call.
4. **Await the promise**: Use `await` on the Promise obtained in step 2. This will pause your test until the matching network event occurs or the timeout is reached.
5. **Assert**: Once the Promise resolves, you can access the `Request` or `Response` object to perform assertions (e.g., check status codes, validate payloads, verify headers).

## Code Implementation
Here's a TypeScript example demonstrating how to wait for specific network requests and responses in Playwright.

```typescript
import { test, expect, Page, Request, Response } from '@playwright/test';

test.describe('Network Interception and Waiting', () => {

    test.beforeEach(async ({ page }) => {
        // Navigate to a test page that makes network requests
        await page.goto('https://www.example.com'); // Replace with a suitable URL for testing
    });

    test('should wait for a specific POST request and assert its payload', async ({ page }) => {
        // 1. Start waiting for the request before triggering the action
        const requestPromise = page.waitForRequest(request =>
            request.url().includes('/api/submit-data') && request.method() === 'POST'
        );

        // 2. Perform the action that triggers the network call
        // Assuming there's a button click or form submission that makes this request
        await page.evaluate(() => {
            fetch('/api/submit-data', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name: 'John Doe', email: 'john.doe@example.com' })
            });
        });

        // 3. Await the promise to get the caught request
        const request: Request = await requestPromise;

        // 4. Assertions on the request
        expect(request.postDataJSON()).toEqual({ name: 'John Doe', email: 'john.doe@example.com' });
        expect(request.headers()['content-type']).toContain('application/json');
        console.log('Caught POST Request URL:', request.url());
    });

    test('should wait for a specific GET response and assert its status and data', async ({ page }) => {
        // 1. Start waiting for the response before triggering the action
        const responsePromise = page.waitForResponse(response =>
            response.url().includes('/api/users') && response.status() === 200
        );

        // 2. Perform the action that triggers the network call
        // Assuming a click event that fetches user data
        await page.evaluate(() => {
            fetch('/api/users');
        });

        // 3. Await the promise to get the caught response
        const response: Response = await responsePromise;

        // 4. Assertions on the response
        expect(response.status()).toBe(200);
        const responseBody = await response.json();
        expect(responseBody).toHaveProperty('users');
        expect(Array.isArray(responseBody.users)).toBe(true);
        console.log('Caught GET Response URL:', response.url());
        console.log('Caught GET Response Body:', responseBody);
    });

    test('should handle network request timeout gracefully', async ({ page }) => {
        // We expect this to timeout because no action will trigger this request
        const requestPromise = page.waitForRequest('**/non-existent-api', { timeout: 1000 }); // 1 second timeout

        let error: Error | undefined;
        try {
            await requestPromise;
        } catch (e) {
            error = e as Error;
        }

        expect(error).toBeInstanceOf(Error);
        expect(error?.message).toContain('Timeout');
        console.log('Successfully handled network request timeout.');
    });
});
```

**Note**: For the code to run, you would typically need a local web server that can serve responses for `/api/submit-data` and `/api/users`. For instance, you could use a simple Express.js server:

```javascript
// server.js (Node.js with Express)
const express = require('express');
const app = express();
const port = 3000;

app.use(express.json());

app.post('/api/submit-data', (req, res) => {
    console.log('Received data:', req.body);
    res.status(200).json({ message: 'Data received successfully!', data: req.body });
});

app.get('/api/users', (req, res) => {
    res.status(200).json({ users: [{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }] });
});

app.get('/', (req, res) => {
    res.send('<h1>Welcome to the test page!</h1><script>function fetchData(){ fetch("/api/users"); } function postData(){ fetch("/api/submit-data", {method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify({name: "Test", email: "test@example.com"}) }); }</script><button onclick="fetchData()">Fetch Users</button><button onclick="postData()">Post Data</button>');
});

app.listen(port, () => {
    console.log(`Test server listening at http://localhost:${port}`);
});
```
You would then set `await page.goto('http://localhost:3000');` in your Playwright test.

## Best Practices
- **Place `waitForRequest/Response` before the action**: Always initiate the `waitFor` call *before* the action that triggers the network event to ensure you don't miss the event.
- **Use predicate functions for precision**: For complex scenarios, use predicate functions to precisely match requests/responses based on method, headers, or payload, rather than just URL strings.
- **Specify timeouts**: Use `timeout` options appropriately to prevent tests from hanging indefinitely if a network event doesn't occur.
- **Isolate network interactions**: Design your tests to focus on one network interaction at a time when using `waitForRequest/Response` to keep them clear and maintainable.
- **Combine with `Promise.all` for multiple events**: If an action triggers multiple network requests or responses you need to wait for, use `Promise.all` to await all of them concurrently.

## Common Pitfalls
- **Missing the event**: Calling `waitForRequest/Response` *after* the action that triggers the network call. The event might have already happened, leading to a timeout.
- **Overly broad predicates**: Using generic URLs or predicates that match too many requests/responses, causing the test to wait for the wrong event. Be as specific as possible.
- **Not handling timeouts**: Failing to implement error handling for network waits can lead to hanging tests or unclear failures.
- **Ignoring asynchronous nature**: Treating network calls as synchronous operations, leading to flaky tests that depend on arbitrary network timing.
- **Not checking response content**: Just waiting for a 200 status code is often not enough; always assert on the actual response data when necessary.

## Interview Questions & Answers
1. Q: Explain the difference between `page.waitForRequest()` and `page.waitForResponse()` and when you would use each.
   A: `page.waitForRequest()` waits for a network request to be initiated by the page. You'd use it to assert on the outgoing request's properties, such as its URL, method, headers, or post data *before* the server responds. `page.waitForResponse()` waits for a network response to be received by the page. You'd use it to assert on the incoming response's properties, like its status code, headers, or response body *after* the server has processed the request. Generally, if you need to validate what your application *sends*, use `waitForRequest`. If you need to validate what your application *receives* and how it reacts, use `waitForResponse`.

2. Q: How do you prevent Playwright tests from becoming flaky due to network timing issues?
   A: The primary way to prevent flakiness due to network timing is by using Playwright's network waiting mechanisms like `page.waitForRequest()`, `page.waitForResponse()`, or even more general methods like `page.waitForLoadState('networkidle')`. These methods ensure that your test execution is synchronized with the application's network activity, preventing assertions from running before necessary data has been loaded or processed. Additionally, using specific predicates (functions) with these `waitFor` methods allows for precise targeting of the desired network events, reducing the chance of waiting for an irrelevant call.

3. Q: Can you give an example of a scenario where `page.waitForResponse()` with a predicate function would be more beneficial than just waiting for a URL string?
   A: Absolutely. Consider an API endpoint `/api/status` that can return either a `200 OK` with a success message or a `400 Bad Request` with an error message depending on some application state. If you only wait for `page.waitForResponse('/api/status')`, your test will resolve upon *any* response from that URL. However, if you specifically want to test the success scenario, you would use a predicate function: `page.waitForResponse(response => response.url().includes('/api/status') && response.status() === 200 && response.json().then(data => data.message === 'Success'))`. This allows you to wait for a response that not only matches the URL and status but also contains a specific message in its body, ensuring the correct application flow is being tested.

## Hands-on Exercise
**Scenario**: You are testing a dashboard application that loads user statistics after login.
**Task**:
1. Navigate to a login page (mock one if necessary, or use a public one).
2. Log in with valid credentials.
3. After logging in, the dashboard page makes a `GET` request to `/api/dashboard-stats` which returns JSON data.
4. Your test should wait for this specific response, verify its status code is 200, and assert that the response body contains a property named `totalUsers` and `activeUsers`.

**Instructions**:
- Set up a basic Playwright test.
- Use `page.goto()` for navigation.
- Implement the login action (e.g., `page.fill()`, `page.click()`).
- Use `page.waitForResponse()` with an appropriate predicate.
- Add `expect()` assertions to validate the response status and body content.
- (Optional but recommended): If you don't have a live API, use Playwright's `page.route()` to mock the `/api/dashboard-stats` response for controlled testing.

## Additional Resources
- **Playwright `page.waitForRequest()` documentation**: [https://playwright.dev/docs/api/class-page#page-wait-for-request](https://playwright.dev/docs/api/class-page#page-wait-for-request)
- **Playwright `page.waitForResponse()` documentation**: [https://playwright.dev/docs/api/class-page#page-wait-for-response](https://playwright.dev/docs/api/class-page#page-wait-for-response)
- **Playwright Network Introduction**: [https://playwright.dev/docs/network](https://playwright.dev/docs/network)