# TestNG - Setting Test Priorities

## Overview
In TestNG, the `@Test` annotation includes a `priority` attribute that allows you to control the execution order of your test methods. By default, TestNG executes test methods in alphabetical order of their names. However, in many real-world scenarios, you need to enforce a specific sequence, such as logging in before adding an item to a cart. The `priority` attribute provides a simple and effective way to manage this execution flow.

Lower priority numbers are executed first. The default priority for a test method, if not specified, is 0.

## Detailed Explanation
The `priority` attribute is an integer. TestNG will run tests with a lower priority value before those with a higher value. Priorities can be positive, negative, or zero.

- **`@Test(priority = 0)`**: This is the default. If no priority is set, the method is considered `priority=0`.
- **`@Test(priority = 1)`**: This test will run after all `priority=0` tests.
- **`@Test(priority = -1)`**: This test will run before all `priority=0` tests.

If multiple test methods share the same priority, their execution order within that priority group is again determined alphabetically.

**Use Case in Test Automation:**
Consider a typical e-commerce workflow:
1.  **Login**: Must happen first.
2.  **Search for a product**: Must happen after login.
3.  **Add product to cart**: Depends on a successful search.
4.  **Checkout**: Depends on having an item in the cart.
5.  **Logout**: Should be the final step.

Assigning priorities ensures this sequence is always respected, making tests predictable and reliable.

## Code Implementation
Here is a complete, runnable Java example demonstrating the use of the `priority` attribute.

```java
package com.sdetlearning.testng;

import org.testng.annotations.Test;

/**
 * This class demonstrates how to control the execution order of test methods
 * using the 'priority' attribute in TestNG.
 * - Lower priority numbers are executed first.
 * - The default priority is 0 if not specified.
 * - If priorities are the same, execution is alphabetical by method name.
 */
public class TestPriority {

    @Test(priority = 4)
    public void testLogout() {
        System.out.println("Executing Test: Logout (Priority 4)");
    }

    @Test(priority = 1)
    public void testLogin() {
        System.out.println("Executing Test: Login (Priority 1)");
    }

    @Test(priority = 3)
    public void testCheckout() {
        System.out.println("Executing Test: Checkout (Priority 3)");
    }

    @Test // No priority set, so it defaults to priority = 0
    public void testLaunchApplication() {
        System.out.println("Executing Test: Launch Application (Default Priority 0)");
    }

    @Test(priority = 2)
    public void testSearchAndAddToCart() {
        System.out.println("Executing Test: Search and Add to Cart (Priority 2)");
    }

    @Test(priority = 1) // Same priority as testLogin
    public void testVerifyHomePageTitle() {
        System.out.println("Executing Test: Verify Home Page Title (Priority 1)");
    }
}
```

### Execution Output
When you run the `TestPriority` class with TestNG, the console output will be:

```
Executing Test: Launch Application (Default Priority 0)
Executing Test: Login (Priority 1)
Executing Test: Verify Home Page Title (Priority 1)
Executing Test: Search and Add to Cart (Priority 2)
Executing Test: Checkout (Priority 3)
Executing Test: Logout (Priority 4)
```

**Analysis of the output:**
1.  `testLaunchApplication` runs first because its default priority is 0.
2.  `testLogin` and `testVerifyHomePageTitle` both have `priority=1`. They run next, in alphabetical order relative to each other.
3.  The remaining tests execute sequentially according to their assigned priorities (2, 3, and 4).

## Best Practices
- **Use Priorities Sparingly**: Don't assign a priority to every single test. Only use them when a specific order is functionally required. Overuse can make the test suite rigid and hard to maintain.
- **Combine with Dependencies**: For strict dependencies (e.g., a test *must* pass for another to run), `dependsOnMethods` is a better choice than `priority`. Use `priority` for ordering independent tests.
- **Group Priorities**: Leave gaps between priority numbers (e.g., 10, 20, 30) to make it easier to insert new tests later without re-numbering everything.
- **Document Your Strategy**: Clearly document why certain tests have priorities, especially in a team setting.

## Common Pitfalls
- **Relying Solely on Priority for Dependencies**: A high-priority test can still run even if a low-priority test it depends on has failed. `priority` only controls execution order, not success/failure dependency. Use `dependsOnMethods` for that.
- **Forgetting the Default Priority**: Engineers often forget that tests without a `priority` attribute default to `priority=0`, causing them to run before all tests with positive priorities.
- **Mixing with Alphabetical Order**: If two tests have the same priority, TestNG falls back to alphabetical execution. This can lead to unexpected ordering if not accounted for.

## Interview Questions & Answers
1. **Q: How do you define the execution order of test methods in TestNG?**
   **A:** The primary way to control execution order is with the `priority` attribute in the `@Test` annotation. Methods with lower priority numbers execute first. If `priority` is not set, it defaults to 0. If multiple methods have the same priority, they are executed in alphabetical order. For strict, "hard" dependencies, it's better to use the `dependsOnMethods` or `dependsOnGroups` attributes.

2. **Q: What happens if I have a test with `priority=-5` and another with `priority=5`? Which runs first?**
   **A:** The test with `priority=-5` will run first. TestNG priorities are simple integer comparisons, and -5 is less than 5. Negative priorities are perfectly valid and useful for setup-related tests that must run before all others.

3. **Q: When would you use `dependsOnMethods` instead of `priority`?**
   **A:** You should use `dependsOnMethods` when the outcome of one test directly determines whether another test should even be attempted. For example, a "Verify Dashboard" test should only run if the "Login" test passes. If the "Login" test fails, `dependsOnMethods` will cause "Verify Dashboard" to be **skipped**. `priority` only guarantees the order of execution; the "Verify Dashboard" test would still run and fail even if "Login" failed. `priority` is for ordering, while `dependsOnMethods` is for managing logical dependencies.

## Hands-on Exercise
1.  **Create a new Java class** named `PriorityExercise`.
2.  **Write five test methods**:
    - `registerUser()`
    - `loginWithNewUser()`
    - `sendEmailConfirmation()`
    - `verifyEmailReceived()`
    - `logout()`
3.  **Assign priorities** to these methods to ensure they run in a logical sequence. For example, registration must happen before login, and login must happen before sending an email.
4.  Add a test method called `openBrowser()` without any priority.
5.  **Run the test class** and verify from the console output that the execution order is exactly what you intended. Observe where `openBrowser()` runs and understand why.

## Additional Resources
- [TestNG Official Documentation - Test Priorities](https://testng.org/doc/documentation-main.html#test-priorities)
- [Baeldung - TestNG Priorities](https://www.baeldung.com/testng-test-priority)
