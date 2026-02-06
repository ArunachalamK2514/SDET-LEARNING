# Playwright Fixtures: Sharing Data Across Tests

## Overview
Playwright's test fixtures provide a powerful mechanism to set up and tear down the environment needed for your tests. Beyond basic setup, fixtures excel at sharing complex objects or data across multiple tests or even entire test files. This is particularly useful for "heavy" operations like establishing database connections, configuring API clients, or preparing large datasets, ensuring these expensive operations run only once per worker process, significantly speeding up test execution and maintaining test isolation.

## Detailed Explanation
In Playwright, fixtures are functions that Playwright executes to set up the test environment. They can be synchronous or asynchronous and can yield a value that tests can consume. When a test requests a fixture, Playwright ensures that fixture is set up before the test runs.

There are two primary scopes for fixtures:
1.  **`test` scope (default):** The fixture is set up once per test and torn down after the test completes.
2.  **`worker` scope:** The fixture is set up once per worker process and torn down after all tests in that worker have finished. This scope is ideal for sharing resources that are expensive to create and can be safely reused across multiple tests, such as database connections, authenticated API clients, or cached data.

To share data, you define a custom `test` object using `test.extend()`, providing your worker-scoped fixture. This fixture will yield the shared data (e.g., a database client object). Any test or other fixture that depends on this custom `test` object can then access the shared data.

### Worker-Scoped Fixtures for Heavy Setup
Worker-scoped fixtures are crucial for performance optimization. Imagine you have 100 tests that all need to interact with a database. If each test establishes and closes its own database connection, the overhead would be enormous. With a worker-scoped fixture, the connection is established once when the worker starts and closed only when the worker finishes, allowing all 100 tests to reuse the same connection.

### Sharing Database Connections or Test Data Objects
A common use case is sharing a database connection. The fixture would handle:
-   Connecting to the database (e.g., PostgreSQL, MongoDB, a mock database).
-   Optionally, preparing initial test data (e.g., seeding the database).
-   Yielding the database client object.
-   Tearing down the connection (e.g., closing it, cleaning up data) after all tests in the worker complete.

This ensures all tests running in that worker process have access to the same, pre-configured database client.

### Verifying Data Availability Across Multiple Test Files
The `worker` scope means the fixture's yielded value is available to any test or test file executed by that specific worker process. This allows you to define a database connection fixture once and then use it across various test files that require database interaction, maintaining consistency and reducing boilerplate code.

## Code Implementation

Let's illustrate with a mock database connection.

First, define your custom `test` object with a worker-scoped fixture in a file like `tests/fixtures/dbFixture.ts`:

```typescript
// tests/fixtures/dbFixture.ts
import { test as baseTest } from '@playwright/test';

// Mock database client for demonstration purposes
class MockDBClient {
  private isConnected: boolean = false;
  private data: Map<string, any> = new Map();

  async connect() {
    console.log('DB: Connecting...');
    // Simulate async connection
    await new Promise(resolve => setTimeout(resolve, 500));
    this.isConnected = true;
    console.log('DB: Connected!');
    // Seed some initial data
    this.data.set('user123', { id: 'user123', name: 'Alice', email: 'alice@example.com' });
    this.data.set('product456', { id: 'product456', name: 'Laptop', price: 1200 });
  }

  async disconnect() {
    console.log('DB: Disconnecting...');
    // Simulate async disconnection
    await new Promise(resolve => setTimeout(resolve, 200));
    this.isConnected = false;
    console.log('DB: Disconnected!');
    this.data.clear();
  }

  async getUser(id: string) {
    if (!this.isConnected) throw new Error('DB not connected');
    console.log(`DB: Fetching user ${id}`);
    await new Promise(resolve => setTimeout(resolve, 50));
    return this.data.get(id);
  }

  async getProduct(id: string) {
    if (!this.isConnected) throw new Error('DB not connected');
    console.log(`DB: Fetching product ${id}`);
    await new Promise(resolve => setTimeout(resolve, 50));
    return this.data.get(id);
  }

  async insertData(key: string, value: any) {
    if (!this.isConnected) throw new Error('DB not connected');
    console.log(`DB: Inserting data for key ${key}`);
    await new Promise(resolve => setTimeout(resolve, 50));
    this.data.set(key, value);
  }

  async clearData() {
    if (!this.isConnected) throw new Error('DB not connected');
    console.log('DB: Clearing all data.');
    await new Promise(resolve => setTimeout(resolve, 100));
    this.data.clear();
  }
}

// Declare the types for your fixtures.
type MyFixtures = {
  dbClient: MockDBClient;
};

// Extend the base test object with our custom fixture.
export const test = baseTest.extend<MyFixtures>({
  dbClient: [async ({}, use) => {
    const dbClient = new MockDBClient();
    await dbClient.connect(); // Heavy setup
    await use(dbClient); // Yield the client for tests to use
    await dbClient.disconnect(); // Heavy teardown
  }, { scope: 'worker', auto: true }], // 'worker' scope ensures it runs once per worker. 'auto: true' means it runs automatically.
});

// Re-export expect for convenience if needed, or import directly from '@playwright/test' in test files.
export { expect } from '@playwright/test';
```

Next, use this `dbClient` fixture in your test files.
For example, in `tests/user.spec.ts`:

```typescript
// tests/user.spec.ts
import { test, expect } from '../tests/fixtures/dbFixture'; // Import from your custom test object

test.describe('User Management', () => {
  test('should fetch a user from the database', async ({ dbClient }) => {
    console.log('Test 1: Fetching user...');
    const user = await dbClient.getUser('user123');
    expect(user).toBeDefined();
    expect(user.name).toBe('Alice');
    expect(user.email).toBe('alice@example.com');
    await dbClient.insertData('user456', { id: 'user456', name: 'Bob', email: 'bob@example.com' });
    const newUser = await dbClient.getUser('user456');
    expect(newUser.name).toBe('Bob');
  });

  test('should not find a non-existent user', async ({ dbClient }) => {
    console.log('Test 2: Fetching non-existent user...');
    const user = await dbClient.getUser('nonExistentUser');
    expect(user).toBeUndefined();
  });
});
```

And in `tests/product.spec.ts`:

```typescript
// tests/product.spec.ts
import { test, expect } from '../tests/fixtures/dbFixture'; // Import from your custom test object

test.describe('Product Catalog', () => {
  test('should fetch a product from the database', async ({ dbClient }) => {
    console.log('Test 3: Fetching product...');
    const product = await dbClient.getProduct('product456');
    expect(product).toBeDefined();
    expect(product.name).toBe('Laptop');
    expect(product.price).toBe(1200);
  });

  test('should allow adding new product data', async ({ dbClient }) => {
    console.log('Test 4: Adding new product...');
    const newProduct = { id: 'product789', name: 'Mouse', price: 25 };
    await dbClient.insertData('product789', newProduct);
    const fetchedProduct = await dbClient.getProduct('product789');
    expect(fetchedProduct).toEqual(newProduct);
  });
});
```

When you run these tests, you will observe that `DB: Connecting...` and `DB: Disconnecting...` messages appear only once per worker process, even though multiple tests in different files utilize the `dbClient` fixture. The data seeded in `dbClient.connect()` is available to all tests within that worker.

## Best Practices
-   **Use `worker` scope for expensive, shared resources:** Database connections, API clients, browser instances (if not using `page` or `context` fixtures), and anything that takes significant time or resources to set up and tear down.
-   **Keep fixture setup and teardown clean:** Ensure fixtures clean up any resources they create to prevent resource leaks and ensure test isolation between different worker processes.
-   **Isolate test data:** While the connection is shared, ensure tests don't interfere with each other's data. If tests modify shared data, consider transaction-based approaches or mechanisms to reset data before each test or describe block. The example above uses a simple `Map` which is cleared when the worker disconnects, but real-world scenarios might require more sophisticated data management.
-   **Organize fixtures:** Place custom fixtures in a dedicated directory (e.g., `tests/fixtures/`) for better organization and reusability.
-   **Use `auto: true` sparingly:** Only set `auto: true` for worker fixtures if you are certain that every test needs it, or if it's purely for side effects that don't need to be explicitly requested by tests (e.g., logging setup). Otherwise, explicitly request the fixture in your tests (`async ({ dbClient }) => {...}`).

## Common Pitfalls
-   **Forgetting `worker` scope:** Accidentally using the default `test` scope for heavy setups will lead to significant performance degradation as the setup/teardown runs for every single test.
-   **Lack of data isolation:** If multiple tests within the same worker modify the shared state (e.g., database data) without proper cleanup or transaction management, tests can become flaky and interdependent.
-   **Over-sharing:** Not all resources should be shared. Some resources truly need to be isolated per test (e.g., a fresh browser context or page for UI tests) to prevent side effects between tests.
-   **Complex fixture dependencies:** While powerful, an overly complex chain of fixture dependencies can make it hard to understand the test setup. Keep fixtures focused and simple.

## Interview Questions & Answers
1.  **Q: Explain the difference between `test` and `worker` scoped fixtures in Playwright. When would you use each?**
    A: `test` scoped fixtures are created and destroyed for each individual test. They are suitable for resources that need to be fresh for every test, like a browser `page` or `context`. `worker` scoped fixtures are created once per worker process and shared across all tests running within that worker. They are ideal for expensive resources like database connections, API clients, or global setup that can be safely reused, improving performance.
2.  **Q: How would you share a database connection across multiple Playwright test files efficiently? Provide a high-level code example.**
    A: You would use a `worker`-scoped fixture defined using `test.extend()`. This fixture would establish the database connection, yield the connection object, and then close it in its teardown phase. All test files needing this connection would then import `test` from the custom fixture file, allowing them to access the shared connection via dependency injection. (Refer to the `Code Implementation` section for an example.)
3.  **Q: What are the potential challenges of sharing data across tests using worker-scoped fixtures, and how do you mitigate them?**
    A: The main challenge is ensuring test isolation, especially regarding data modifications. If tests modify shared data, subsequent tests might run against an altered state, leading to flakiness. Mitigation strategies include:
    *   **Transactions:** Wrap each test's database operations in a transaction and roll it back after the test.
    *   **Data Reset:** Implement a mechanism in the fixture's teardown (or a `beforeEach` hook) to reset the data to a known state.
    *   **Read-only operations:** If tests only read shared data, isolation is less of a concern.
    *   **Dedicated test data:** Each test uses its own unique set of data.

## Hands-on Exercise
1.  **Extend the `MockDBClient`:** Add a new method `deleteUser(id: string)` to the `MockDBClient` that removes a user from its internal `data` map.
2.  **Create a new test file:** Create `tests/admin.spec.ts`.
3.  **Implement an admin test:** In `tests/admin.spec.ts`, write a test that uses the `dbClient` fixture to:
    *   Insert a new admin user.
    *   Verify the admin user exists.
    *   Call `deleteUser` to remove the newly added admin user.
    *   Verify the admin user no longer exists.
4.  **Observe logging:** Run your tests (`npx playwright test`). Observe the console output to confirm that the `dbClient.connect()` and `dbClient.disconnect()` logs still only appear once per worker, even with the new test file.

## Additional Resources
-   **Playwright Test Fixtures:** [https://playwright.dev/docs/test-fixtures](https://playwright.dev/docs/test-fixtures)
-   **Playwright `test.extend`:** [https://playwright.dev/docs/api/class-test#test-extend](https://playwright.dev/docs/api/class-test#test-extend)
-   **Playwright Test Configuration (`projects` and workers):** [https://playwright.dev/docs/test-configuration#projects](https://playwright.dev/docs/test-configuration#projects)
