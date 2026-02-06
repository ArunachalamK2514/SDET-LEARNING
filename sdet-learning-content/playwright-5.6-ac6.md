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