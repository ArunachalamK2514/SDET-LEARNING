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
