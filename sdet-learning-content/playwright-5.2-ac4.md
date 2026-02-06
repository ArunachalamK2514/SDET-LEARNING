# Playwright Text-Based Locators: Exact, Partial, and Regex Matching

## Overview
Playwright's auto-waiting mechanism combined with robust text-based locators simplifies writing resilient and readable tests. This document explores how to effectively use `getByText` with exact and partial matching, as well as leverage regular expressions for more dynamic text matching, ensuring elements are found reliably without explicit waits.

## Detailed Explanation
Playwright provides powerful built-in locators that are resilient to changes in the DOM structure. Among these, text-based locators are fundamental for interacting with elements visible to the user.

*   **`getByText('Exact Text', { exact: true })`**: This locator finds an element that contains the exact text specified. It's case-sensitive by default. The `{ exact: true }` option ensures that only elements whose text content precisely matches the provided string are selected, preventing unintended matches from partial strings.

    *Example*: If you have `<span>Hello World</span>` and `<span>World</span>`, `getByText('World', { exact: true })` will only match the second `<span>`.
*   **`getByText('Partial Text')`**: When the `exact` option is omitted or set to `false`, `getByText` performs a partial, case-insensitive match. This is useful when the full text content might vary slightly, or you only care about a significant portion of the text.

    *Example*: `getByText('World')` will match both `<span>Hello World</span>` and `<span>World</span>`.
*   **`getByText(/regex/i)`**: For more complex or dynamic text patterns, Playwright allows using regular expressions. This provides immense flexibility, enabling matching based on patterns, case-insensitivity (using the `i` flag), or other regex features. This is particularly powerful when text content might change (e.g., dynamic numbers, timestamps) but follows a predictable pattern.

    *Example*: `getByText(/Hello\sWorld/i)` would match `<span>hello world</span>`, `<span>Hello World</span>`, and `<span>Hello   World</span>`.

## Code Implementation
```typescript
import { test, expect, Page } from '@playwright/test';

test.describe('Playwright Text-Based Locators', () => {
  let page: Page;

  test.beforeAll(async ({ browser }) => {
    page = await browser.newPage();
    // Navigate to a simple page for demonstration
    await page.setContent(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Text Locators Test Page</title>
      </head>
      <body>
        <h1>Welcome to the Demo</h1>
        <p>This is some example text.</p>
        <div>
          <button>Submit Order</button>
          <span>Current Items: 5</span>
          <a href="/products">View Products</a>
        </div>
        <p>Your order total is: $123.45</p>
        <div id="dynamic-content">
          <span>Item count: 123</span>
        </div>
      </body>
      </html>
    `);
  });

  test.afterAll(async () => {
    await page.close();
  });

  test('should find element by exact text match', async () => {
    // Find the "Submit Order" button using exact text matching
    const submitButton = page.getByText('Submit Order', { exact: true });
    await expect(submitButton).toBeVisible();
    await expect(submitButton).toHaveText('Submit Order'); // Verify its text content
    console.log('Found "Submit Order" button by exact text.');
  });

  test('should find element by partial text match', async () => {
    // Find the paragraph containing "example text" using partial matching
    const exampleText = page.getByText('example text');
    await expect(exampleText).toBeVisible();
    await expect(exampleText).toContainText('some example text'); // Verify it contains the text
    console.log('Found element containing "example text" by partial match.');
  });

  test('should find element using regex for pattern matching', async () => {
    // Find the dynamic item count using a regex (case-insensitive, matches "Item count: " followed by digits)
    const itemCountSpan = page.getByText(/Item count: \d+/i);
    await expect(itemCountSpan).toBeVisible();
    await expect(itemCountSpan).toHaveText(/Item count: \d+/); // Verify it matches the pattern
    console.log('Found dynamic item count using regex.');

    // Find the total price using regex (matches a dollar amount)
    const orderTotal = page.getByText(/\$\d+\.\d{2}/);
    await expect(orderTotal).toBeVisible();
    await expect(orderTotal).toContainText('$123.45');
    console.log('Found order total using regex.');
  });

  test('should handle multiple matches gracefully for partial text (first one)', async () => {
    // If multiple elements match, Playwright's getByText often returns the first one in document order,
    // or requires a specific filter if ambiguity exists. For this example, 'text' appears in multiple places.
    const firstTextMatch = page.getByText('text').first();
    await expect(firstTextMatch).toBeVisible();
    await expect(firstTextMatch).toContainText('example text');
    console.log('Found the first occurrence of "text" using partial match.');
  });

  test('should verify text is on the page (not necessarily an element)', async () => {
    // You can assert that text exists on the page
    await expect(page.locator('body')).toContainText('Welcome to the Demo');
    console.log('Verified "Welcome to the Demo" text is on the page body.');
  });
});
```

## Best Practices
-   **Prefer visible text**: Use `getByText` when the text is visually clear and descriptive to users. This makes tests more readable and resilient to DOM changes.
-   **Combine with other locators**: If text alone isn't unique, combine `getByText` with parent locators (e.g., `page.locator('div').getByText('Text')`) or role locators for more precise targeting.
-   **Use `exact: true` for precision**: When you need to match the text content precisely, always use `{ exact: true }` to avoid false positives from partial matches.
-   **Leverage regex for dynamic content**: For text that changes (e.g., timestamps, counts, IDs), use regular expressions to match the pattern rather than the exact volatile string.
-   **Avoid over-specificity**: Don't include too much surrounding text in `getByText` calls. Focus on the most unique and stable part of the text.

## Common Pitfalls
-   **Case sensitivity (or lack thereof)**: `getByText` is case-insensitive by default for partial matches. If case sensitivity is required for partial matches, you'll need to use a regex with no `i` flag. For `exact: true`, it is case-sensitive.
-   **Hidden elements**: `getByText` (like most Playwright locators) primarily interacts with visible elements due to auto-waiting. If an element with matching text is hidden, Playwright might not find it or wait until it becomes visible.
-   **Multiple matches**: If `getByText` finds multiple elements matching the text, Playwright might throw an error or implicitly select the first one. Use `.first()`, `.last()`, `.nth()`, or chain with other locators to resolve ambiguity.
-   **Text across multiple elements**: If the "text" you are trying to locate is spread across multiple child elements (e.g., `<div>Hello <strong>World</strong></div>`), `getByText('Hello World')` might not work as expected because Playwright looks at the aggregated text content of a single element. In such cases, target the parent or use a different locator strategy.

## Interview Questions & Answers
1.  **Q: When would you choose `getByText` over a CSS selector or XPath, and what are its advantages?**
    A: `getByText` is preferred when the primary identifier for a user to interact with an element is its visible text content. Its advantages include:
    *   **Readability**: Tests are more human-readable as they mirror how a user perceives the page.
    *   **Resilience**: Less prone to breaking when the DOM structure changes, as long as the visible text remains the same. CSS selectors and XPaths can be brittle if element attributes or hierarchies shift.
    *   **Auto-waiting**: Playwright's auto-waiting works seamlessly with `getByText`, reducing the need for explicit waits.
2.  **Q: How do you handle scenarios where `getByText` returns multiple matching elements?**
    A: There are several ways:
    *   **Chain with other locators**: Combine `getByText` with a parent locator, a `getByRole` locator, or other attribute locators to narrow down the selection. E.g., `page.locator('#sidebar').getByText('Settings')`.
    *   **Use position filters**: `.first()`, `.last()`, `.nth(index)` can be used if the position of the desired element is stable.
    *   **Specify `exact: true`**: If the multiple matches are due to partial matching, using `{ exact: true }` might resolve the ambiguity.
    *   **Use a more specific regex**: Refine the regular expression to match only the intended element.
3.  **Q: Describe a situation where using a regular expression with `getByText` would be particularly beneficial.**
    A: A classic scenario is when dealing with dynamic text, such as a product count, a timestamp, or a confirmation message containing a dynamically generated ID. For instance, if a page displays "You have 15 items in your cart" or "Transaction ID: ABC-123-XYZ", using `getByText(/You have \d+ items in your cart/i)` or `getByText(/Transaction ID: [A-Z0-9-]+/)` allows the test to pass regardless of the exact number or ID, as long as the pattern holds.

## Hands-on Exercise
1.  **Objective**: Navigate to a given URL and assert the presence of specific text elements using different `getByText` strategies.
2.  **Setup**:
    *   Create a simple HTML file named `dynamic_page.html` with the following content:
        ```html
        <!DOCTYPE html>
        <html>
        <head>
          <title>Dynamic Content Page</title>
        </head>
        <body>
          <h2>Product List</h2>
          <p>Total products available: <span>150</span></p>
          <button>Add to Cart</button>
          <div>
            <p>Welcome, User123!</p>
            <a href="#">View Profile</a>
          </div>
          <p>Special offer ends on <span>12/31/2026</span>!</p>
          <button>See all offers</button>
        </body>
        </html>
        ```
    *   Save this HTML file in the same directory where your Playwright tests run, or configure Playwright to serve it.
3.  **Task**:
    *   Write a Playwright test that:
        *   Navigates to `dynamic_page.html`.
        *   Uses `getByText('Add to Cart', { exact: true })` to find and click the "Add to Cart" button.
        *   Uses `getByText('Total products available:', { exact: false })` or `getByText(/Total products available: \d+/)` to verify the product count paragraph is visible.
        *   Uses `getByText(/Welcome, User\d+!/i)` to assert the greeting message.
        *   Uses `getByText(/Special offer ends on \d{2}\/\d{2}\/\d{4}!/)` to verify the offer message.
        *   Asserts that the "See all offers" button is visible using `getByText('See all offers')`.
4.  **Expected Outcome**: All assertions pass, demonstrating successful use of exact, partial, and regex text locators.

## Additional Resources
-   Playwright `getByText` documentation: [https://playwright.dev/docs/locators#locate-by-text](https://playwright.dev/docs/locators#locate-by-text)
-   Playwright Locators overview: [https://playwright.dev/docs/locators](https://playwright.dev/docs/locators)
-   Regular Expressions (MDN Web Docs): [https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions)