# Playwright Fixture Composition and Dependency Injection

## Overview
Playwright fixtures are a powerful mechanism to establish a well-defined and isolated environment for your tests. Fixture composition allows you to build complex test setups by combining smaller, reusable fixtures, while dependency injection ensures that these fixtures are provided to tests and other fixtures exactly when and where they are needed. This approach promotes code reusability, simplifies test maintenance, and guarantees a consistent and predictable test context, adhering to the DRY (Don't Repeat Yourself) principle.

## Detailed Explanation
In Playwright, a fixture can declare dependencies on other fixtures. This is achieved by listing the required fixtures as parameters in the fixture's setup function. Playwright's test runner automatically handles the resolution of these dependencies. When a test requires a fixture, Playwright first identifies all its dependent fixtures, sets them up, and then proceeds with the setup of the primary fixture.

The execution order is crucial for maintaining a stable test environment:
1.  **Dependent Fixture Setup**: Fixtures that are depended upon are set up first.
2.  **Depending Fixture Setup**: Once dependencies are met, the fixture that declares these dependencies is set up.
3.  **Test Execution**: The actual test code runs, utilizing the prepared fixtures.
4.  **Depending Fixture Teardown**: After the test completes (regardless of pass or fail), the teardown logic for the depending fixture runs.
5.  **Dependent Fixture Teardown**: Finally, the teardown logic for the dependent fixtures runs.

This ensures resources are initialized in the correct order and cleaned up gracefully, preventing resource leaks and test interference. The `use` function, provided as a parameter to a fixture's setup function, is used to pass control to the next stage (either another fixture's setup or the test itself). Anything before `await use(...)` is setup, and anything after is teardown.

## Code Implementation
Here's an example demonstrating fixture composition and the execution order. We'll define two fixtures: `userProfile` (Fixture A) which creates a mock user profile, and `loggedInPage` (Fixture B) which depends on `userProfile` to simulate a login process on a `page` object.

First, create a `fixtures.ts` file:

```typescript
// fixtures.ts
import { test as base } from '@playwright/test';

// 1. Define interfaces for our custom fixtures
// This helps with type safety and auto-completion
interface UserProfile {
  id: string;
  username: string;
  email: string;
}

interface MyFixtures {
  userProfile: UserProfile; // Fixture A: Provides a user profile object
  loggedInPage: any;        // Fixture B: Provides a Playwright Page instance after login
}

// 2. Extend the base Playwright test object with our custom fixtures
export const test = base.extend<MyFixtures>({
  // Fixture A: userProfile
  userProfile: [async ({ }, use) => {
    console.log('--- Setting up userProfile fixture (Fixture A) ---');
    const profile: UserProfile = {
      id: 'usr123',
      username: 'testuser',
      email: 'test@example.com',
    };
    // The `use` function provides the fixture's value to dependent fixtures or tests
    await use(profile);
    console.log('--- Tearing down userProfile fixture (Fixture A) ---');
  }, { scope: 'test', auto: false }], // 'scope: test' means a new instance for each test
                                     // 'auto: false' means it's not automatically used by all tests

  // Fixture B: loggedInPage, which depends on 'page' (built-in) and 'userProfile' (custom)
  loggedInPage: [async ({ page, userProfile }, use) => {
    console.log('--- Setting up loggedInPage fixture (Fixture B) ---');
    console.log(`Attempting login for user: ${userProfile.username}`);

    // Simulate navigating to a login page and performing login
    // In a real scenario, replace with your actual application's login flow
    await page.goto('https://www.google.com/search?q=playwright'); // Example: navigate to a dummy page
    // await page.fill('#username', userProfile.username);
    // await page.fill('#password', 'SecurePass123'); // Use a secure way to handle passwords in real apps
    // await page.click('#loginButton');

    // Simulate waiting for successful login (e.g., checking for a dashboard element)
    // await page.waitForURL('**/dashboard'); // Replace with your actual dashboard URL or element check
    console.log(`Successfully "logged in" as ${userProfile.username}. Current URL: ${page.url()}`);

    // Provide the configured Playwright `page` object to the test
    await use(page);
    console.log('--- Tearing down loggedInPage fixture (Fixture B) ---');
  }, { scope: 'test' }], // 'scope: test' ensures a fresh logged-in page for each test
});
```

Next, create a test file named `fixtureComposition.spec.ts` that utilizes these fixtures:

```typescript
// fixtureComposition.spec.ts
import { test } from './fixtures'; // Import our extended test object
import { expect } from '@playwright/test';

test.describe('Fixture Composition Demo', () => {
  test('should verify user information on a logged-in page', async ({ loggedInPage, userProfile }) => {
    console.log('--- Executing test: should verify user information ---');
    // The 'loggedInPage' fixture has already handled navigation and login.
    // The 'userProfile' fixture's data is directly available here.

    // In a real application, you would assert specific elements containing user info
    // For this example, we'll just log and assert something generic from the page.
    console.log(`Test sees logged-in page at: ${loggedInPage.url()}`);
    console.log(`Test has user profile: ${userProfile.username}, ${userProfile.email}`);

    // Example assertion: Check if the page title contains a common search result phrase
    await expect(loggedInPage).toHaveTitle(/.*Playwright.*/); // This assumes the dummy page navigation above
    console.log('--- Finished test: should verify user information ---');
  });

  test('should navigate to a different section from logged-in state', async ({ loggedInPage }) => {
    console.log('--- Executing test: should navigate to a different section ---');
    // Again, loggedInPage fixture provides a page that is already in a logged-in state.

    // Simulate navigation to another part of the application
    await loggedInPage.goto('https://www.bing.com'); // Example: navigate to another dummy page
    await expect(loggedInPage).toHaveTitle(/.*Bing.*/);
    console.log('--- Finished test: should navigate to a different section ---');
  });
});
```

To run this, save both files in the same directory (e.g., `tests/`) and execute `npx playwright test fixtureComposition.spec.ts`.
You will observe output similar to this, demonstrating the execution order:

```
--- Setting up userProfile fixture (Fixture A) ---
--- Setting up loggedInPage fixture (Fixture B) ---
Attempting login for user: testuser
Successfully "logged in" as testuser. Current URL: https://www.google.com/search?q=playwright
--- Executing test: should verify user information ---
Test sees logged-in page at: https://www.google.com/search?q=playwright
Test has user profile: testuser, test@example.com
--- Finished test: should verify user information ---
--- Tearing down loggedInPage fixture (Fixture B) ---
--- Tearing down userProfile fixture (Fixture A) ---
--- Setting up userProfile fixture (Fixture A) ---
--- Setting up loggedInPage fixture (Fixture B) ---
Attempting login for user: testuser
Successfully "logged in" as testuser. Current URL: https://www.google.com/search?q=playwright
--- Executing test: should navigate to a different section ---
--- Finished test: should navigate to a different section ---
--- Tearing down loggedInPage fixture (Fixture B) ---
--- Tearing down userProfile fixture (Fixture A) ---
```
*(Note: Actual console output may vary slightly based on Playwright version and specific test runner configuration, but the order of fixture setup and teardown will remain consistent.)*

## Best Practices
-   **Single Responsibility Principle**: Design each fixture to handle a single, well-defined responsibility (e.g., setting up a user, creating a database connection, providing an authenticated API client). This makes fixtures easier to understand, test, and reuse.
-   **Appropriate Scoping**: Use the `scope` option (`'test'`, `'worker'`, `'project'`) strategically.
    -   `'test'`: Default. A new instance for every test. Ensures maximum isolation but can be slower.
    -   `'worker'`: A single instance for all tests running in a particular worker process. Good for setups that can be shared between tests without interference (e.g., a database client, a browser context).
    -   `'project'`: A single instance for all tests in the entire project. Use sparingly for truly global setups (e.g., a test server that runs once).
-   **Explicit Dependencies**: Always declare all necessary dependencies for a fixture or test explicitly in its signature. Avoid relying on global state or implicit setups.
-   **Robust Teardown**: Ensure that the teardown logic (code after `await use(value)`) properly cleans up all resources allocated during setup. This is critical for preventing resource leaks and ensuring subsequent tests run in a clean state.
-   **Meaningful Names**: Give your fixtures descriptive names that clearly indicate what they provide or what setup they perform.
-   **`auto: true` for Essential Fixtures**: For fixtures that are almost always needed (e.g., `page`), consider setting `auto: true` to automatically run their setup/teardown for every test without explicitly declaring them. Be cautious with this for resource-intensive fixtures.

## Common Pitfalls
-   **Incorrect Fixture Scope**: Using `scope: 'test'` for a resource that could be shared across a worker (like a browser instance) can lead to significantly slower tests due to repeated setup/teardown. Conversely, using a broader scope when per-test isolation is necessary can lead to flaky tests due to shared, mutable state.
-   **Circular Dependencies**: A common mistake is creating a circular dependency where Fixture A depends on B, and B depends on A. Playwright will detect this and throw an error. Design your fixture graph as a Directed Acyclic Graph (DAG).
-   **Over-reliance on `auto: true`**: Making too many fixtures `auto: true` can unnecessarily increase test execution time, as their setup/teardown will run even if a specific test doesn't directly use them.
-   **Implicit State Modification**: If a fixture modifies shared state (e.g., a database) without properly isolating or cleaning up its changes, it can cause other tests to fail unpredictably. Always ensure state is reset or isolated.
-   **Synchronous Setup in Asynchronous Fixtures**: Forgetting `await` inside an `async` fixture can lead to race conditions or fixtures not being fully set up before the test runs.

## Interview Questions & Answers
1.  **Q: What are Playwright fixtures and why are they considered a best practice in test automation?**
    A: Playwright fixtures are functions that define a setup and teardown routine for tests. They provide a controlled, isolated, and reusable way to prepare the test environment. They are a best practice because they:
    *   **Promote DRY**: Centralize common setup logic, reducing code duplication.
    *   **Ensure Isolation**: Each test (or worker, or project, depending on scope) receives a fresh, predictable environment.
    *   **Improve Readability**: Tests focus on testing specific logic rather than boilerplate setup.
    *   **Manage Resources**: Guarantee proper cleanup of resources after tests, preventing leaks.
    *   **Enable Dependency Injection**: Allow complex test contexts to be built by composing simpler, interdependent fixtures.

2.  **Q: How does Playwright's dependency injection system for fixtures work, and what are its benefits?**
    A: Playwright's dependency injection works by inspecting the parameters of a fixture's or test's function signature. If a parameter matches the name of a defined fixture, Playwright automatically resolves and provides an instance of that fixture. This system ensures that all necessary prerequisites for a test or fixture are met before execution. The benefits include:
    *   **Automatic Setup Order**: Playwright handles the correct execution order of dependent fixtures.
    *   **Test Context Clarity**: Tests clearly declare what they need, making them easier to understand.
    *   **Reusability**: Fixtures become modular components that can be mixed and matched.
    *   **Reduced Boilerplate**: Testers don't need to manually set up complex environments within each test.

3.  **Q: Explain the lifecycle and execution order of composed fixtures, specifically for setup and teardown phases.**
    A: The lifecycle of composed fixtures follows a strict order:
    *   **Setup**: Playwright first identifies the entire chain of dependencies. It then sets up the *outermost* fixtures (those with no dependencies, or whose dependencies are already met) first. This proceeds *inward*, meaning a fixture's setup runs only after all its direct dependencies have been fully set up.
    *   **Test Execution**: Once all required fixtures are set up, the test function itself is executed. The values yielded by the fixtures (via `await use(value)`) are injected into the test.
    *   **Teardown**: After the test completes (successfully or with failure), the teardown phase begins. This happens in the *reverse order* of setup. The *innermost* fixtures (those directly used by the test or depending on other fixtures) are torn down first, followed by their dependencies, working *outward*. This ensures that resources are deallocated correctly and in an logical sequence.

## Hands-on Exercise
1.  **Objective**: Create a test scenario where a "shoppingCart" fixture depends on a "product" fixture.
2.  **Steps**:
    *   **Define `Product` Interface**: Create an interface for a `Product` with `id`, `name`, and `price`.
    *   **Create `productFixture`**: Define a fixture named `productFixture` that creates and yields a `Product` object.
    *   **Create `shoppingCartFixture`**: Define a fixture named `shoppingCartFixture` that depends on `page` (built-in) and `productFixture`. In its setup, it should:
        *   Navigate to a dummy shopping page (e.g., `https://example.com/shop`).
        *   Add the product provided by `productFixture` to a simulated cart (e.g., by interacting with page elements).
        *   Yield the `page` object, now with the product in the cart.
    *   **Write a Test**: Create a test that uses `shoppingCartFixture`.
        *   Verify that the product is present in the simulated cart (e.g., by checking a cart item count or product name on the page).
        *   Verify the total price displayed on the cart page is correct based on the `productFixture`'s price.
    *   **Observe Execution**: Add `console.log` statements within the setup and teardown of both custom fixtures and the test itself to observe the precise execution order.

## Additional Resources
-   [Playwright Test Fixtures - Official Documentation](https://playwright.dev/docs/test-fixtures) - The definitive guide on Playwright fixtures.
-   [Playwright Test Best Practices](https://playwright.dev/docs/best-practices) - Learn how to write robust and maintainable Playwright tests.
-   [Example of extending Test using fixtures](https://playwright.dev/docs/test-advanced#fixtures) - Advanced usage of fixtures.