# TestNG Assertions: Common Assertions (10+)

## Overview
Assertions are fundamental to any test automation framework. They are statements that verify whether the actual result of a test matches the expected result. In TestNG, assertions play a crucial role in determining the pass or fail status of a test method. This module delves into over 10 common assertion types provided by TestNG, explaining their usage with practical examples, best practices, common pitfalls, and interview preparation tips. Understanding and effectively using TestNG assertions is vital for writing robust and reliable automated tests.

## Detailed Explanation
TestNG provides a powerful `Assert` class that contains a variety of static methods for performing assertions. When an assertion fails, TestNG marks the test method as failed and typically stops its execution (hard assertion). If all assertions within a test method pass, the test method is marked as passed.

Here's a breakdown of common TestNG assertions:

### 1. `assertEquals(actual, expected, message)`
Checks if two objects or primitive values are equal. This is one of the most frequently used assertions.

### 2. `assertNotEquals(actual, unexpected, message)`
Checks if two objects or primitive values are *not* equal.

### 3. `assertTrue(condition, message)`
Checks if a condition is true. Essential for verifying boolean outcomes.

### 4. `assertFalse(condition, message)`
Checks if a condition is false. Useful when expecting a negative outcome.

### 5. `assertNull(object, message)`
Checks if an object is null.

### 6. `assertNotNull(object, message)`
Checks if an object is not null.

### 7. `assertSame(actual, expected, message)`
Checks if two object references point to the same object in memory (reference equality).

### 8. `assertNotSame(actual, unexpected, message)`
Checks if two object references do *not* point to the same object in memory.

### 9. `assertThat(actual, matcher)` (with Hamcrest matchers)
TestNG integrates well with Hamcrest matchers, providing a more readable and flexible way to express assertions. This is particularly powerful for complex comparisons.
To use `assertThat`, you typically need to add Hamcrest as a dependency.

### 10. `fail(message)`
Forces a test to fail immediately. Useful in `catch` blocks or conditional logic where a specific failure state needs to be indicated.

### 11. `assertEquals(actual, expected, delta, message)` (for doubles/floats)
Compares two double or float values within a specified delta (tolerance) to account for floating-point inaccuracies.

### 12. `assertThrows(class, runnable)` / `assertThrows(class, message, runnable)`
Verifies that a specific type of exception is thrown when a piece of code is executed. This is crucial for testing error handling.

## Code Implementation

To run this code, you'll need TestNG and Hamcrest (optional, for `assertThat`) dependencies in your `pom.xml` (Maven) or `build.gradle` (Gradle).

**Maven `pom.xml` dependencies:**
```xml
<dependencies>
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.10.2</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
    <!-- Optional: For assertThat with Hamcrest matchers -->
    <dependency>
        <groupId>org.hamcrest</groupId>
        <artifactId>hamcrest</artifactId>
        <version>2.2</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
</dependencies>
```

**`TestNGAssertionsDemo.java`**
```java
import org.testng.Assert;
import org.testng.annotations.Test;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*; // For various Hamcrest matchers

public class TestNGAssertionsDemo {

    @Test
    public void testStringEquals() {
        String actual = "Hello TestNG";
        String expected = "Hello TestNG";
        // Assert that two strings are equal
        Assert.assertEquals(actual, expected, "Strings should be equal");
        System.out.println("testStringEquals Passed: Strings are equal.");
    }

    @Test
    public void testIntegerNotEquals() {
        int actual = 10;
        int unexpected = 20;
        // Assert that two integers are not equal
        Assert.assertNotEquals(actual, unexpected, "Integers should not be equal");
        System.out.println("testIntegerNotEquals Passed: Integers are not equal.");
    }

    @Test
    public void testBooleanTrue() {
        boolean condition = (5 > 3);
        // Assert that a condition is true
        Assert.assertTrue(condition, "5 should be greater than 3");
        System.out.println("testBooleanTrue Passed: Condition is true.");
    }

    @Test
    public void testBooleanFalse() {
        boolean condition = (10 < 5);
        // Assert that a condition is false
        Assert.assertFalse(condition, "10 should not be less than 5");
        System.out.println("testBooleanFalse Passed: Condition is false.");
    }

    @Test
    public void testObjectNull() {
        String obj = null;
        // Assert that an object is null
        Assert.assertNull(obj, "Object should be null");
        System.out.println("testObjectNull Passed: Object is null.");
    }

    @Test
    public void testObjectNotNull() {
        Object obj = new Object();
        // Assert that an object is not null
        Assert.assertNotNull(obj, "Object should not be null");
        System.out.println("testObjectNotNull Passed: Object is not null.");
    }

    @Test
    public void testSameReference() {
        String s1 = new String("Test");
        String s2 = new String("Test");
        String s3 = s1;
        
        // Assert that s1 and s3 refer to the same object
        Assert.assertSame(s1, s3, "s1 and s3 should be the same object reference");
        System.out.println("testSameReference Passed: s1 and s3 are same reference.");

        // This would fail: Assert.assertSame(s1, s2, "s1 and s2 should be different object references");
    }

    @Test
    public void testNotSameReference() {
        String s1 = new String("Test");
        String s2 = new String("Test");
        
        // Assert that s1 and s2 do not refer to the same object
        Assert.assertNotSame(s1, s2, "s1 and s2 should not be the same object reference");
        System.out.println("testNotSameReference Passed: s1 and s2 are different references.");
    }

    @Test
    public void testDoubleEqualsWithDelta() {
        double actual = 10.0000000001;
        double expected = 10.0;
        double delta = 0.0000001;
        // Assert that two doubles are equal within a delta
        Assert.assertEquals(actual, expected, delta, "Doubles should be equal within delta");
        System.out.println("testDoubleEqualsWithDelta Passed: Doubles are equal within delta.");
    }

    @Test
    public void testHamcrestAssertThat() {
        String text = "TestNG is awesome!";
        // Using Hamcrest matchers for more expressive assertions
        assertThat("String should contain 'awesome'", text, containsString("awesome"));
        assertThat("String should end with '!'", text, endsWith("!"));
        assertThat("String length should be greater than 10", text.length(), greaterThan(10));
        System.out.println("testHamcrestAssertThat Passed: Hamcrest assertions passed.");
    }

    @Test
    public void testExceptionHandling() {
        // Assert that an ArithmeticException is thrown
        Assert.assertThrows(ArithmeticException.class, () -> {
            int result = 10 / 0; // This will throw ArithmeticException
        }, "Should throw ArithmeticException for division by zero");
        System.out.println("testExceptionHandling Passed: ArithmeticException was thrown as expected.");
    }
    
    // Example of a failing test using fail()
    @Test
    public void testFailAssertion() {
        try {
            // Simulate an error condition
            int[] numbers = {};
            if (numbers.length == 0) {
                Assert.fail("Array should not be empty, this test case demonstrates forced failure.");
            }
            // Further test logic if array was not empty
        } catch (Exception e) {
            // Log the exception, then re-fail or handle
            System.err.println("Caught unexpected exception: " + e.getMessage());
            // Optionally re-fail with a different message or just let the Assert.fail above handle it
            // Assert.fail("Test failed due to unexpected exception: " + e.getMessage());
        }
        System.out.println("This line will not be printed if fail() is executed.");
    }
}
```

## Best Practices
- **Use Meaningful Messages**: Always provide a descriptive message in your assertion. This message is displayed if the assertion fails, making it much easier to diagnose the problem.
- **One Assertion Per Test (Guideline, not Rule)**: While not a strict rule, striving for one logical assertion per test method can make tests more focused and easier to understand. For UI tests, or complex integration tests, multiple assertions might be acceptable if they verify aspects of a single logical outcome.
- **Use Specific Assertions**: Choose the most specific assertion method for your verification (e.g., `assertEquals` for value comparison rather than `assertTrue` with a custom comparison).
- **Prioritize Readability**: Especially with Hamcrest, write assertions that clearly communicate intent.
- **Handle Floating Point Comparisons Carefully**: Always use the `assertEquals` overload with a `delta` when comparing `double` or `float` values to avoid issues due to precision.
- **Combine with Soft Assertions for Comprehensive Reporting**: For scenarios where you want to continue test execution even after an assertion failure (e.g., verifying multiple UI elements on a page), combine hard assertions with TestNG's Soft Assertions (covered in `testng-3.2-ac5`).

## Common Pitfalls
- **Ignoring Assertion Messages**: Forgetting to add descriptive messages makes failed test reports difficult to interpret quickly.
- **Using `==` for Object Comparison**: Using `==` instead of `assertEquals()` for non-primitive types (except for `assertSame()`) will compare references, not content, leading to misleading test results. Always use `.equals()` or `assertEquals()` for content comparison.
- **Hardcoding Values without Context**: Asserting against magic numbers or strings without explaining their origin or purpose makes tests less maintainable and understandable.
- **Over-asserting**: Too many assertions in a single test can make it hard to pinpoint the exact cause of a failure and can indicate that the test is trying to do too much.
- **Not Testing Exception Flows**: Overlooking the testing of expected exception scenarios leaves a gap in error handling validation.

## Interview Questions & Answers
1.  **Q: What is the primary purpose of assertions in TestNG, and why are they important?**
    **A: ** The primary purpose of assertions in TestNG is to verify the expected behavior of the code under test against its actual behavior. They are crucial because they determine the pass/fail status of a test, provide immediate feedback on code correctness, and help in identifying regressions during development cycles. Without assertions, a test would merely execute code without validating any outcomes, making it ineffective.

2.  **Q: Explain the difference between `assertEquals` and `assertSame` in TestNG.**
    **A: ** `assertEquals(actual, expected)` checks for *value equality*. For primitive types, it compares their values. For objects, it typically uses the object's `equals()` method to compare their content. `assertSame(actual, expected)` checks for *reference equality*. It verifies if `actual` and `expected` refer to the exact same object instance in memory. Use `assertEquals` when you care if objects *have the same content*, and `assertSame` when you care if they *are the same object*.

3.  **Q: When would you use `assertThrows`? Provide a real-world example.**
    **A: ** `assertThrows` is used to verify that a specific type of exception is thrown when a certain piece of code is executed. This is essential for testing error handling and validating that your application behaves correctly under erroneous conditions.
    **Example**: When testing a `divide` function, you'd use `assertThrows(ArithmeticException.class, () -> calculator.divide(10, 0))` to ensure that dividing by zero correctly throws an `ArithmeticException`.

4.  **Q: How do you handle assertions for floating-point numbers in TestNG, and why is it important?**
    **A: ** For floating-point numbers (`double` or `float`), you should use the `assertEquals(actual, expected, delta)` overload. It's important because floating-point arithmetic can lead to tiny precision errors, meaning `1.0 / 3.0 * 3.0` might not be *exactly* `1.0`. The `delta` parameter specifies an acceptable margin of error, allowing the assertion to pass if the difference between `actual` and `expected` is within that `delta`.

5.  **Q: What are Hamcrest matchers, and how do they enhance TestNG assertions?**
    **A: ** Hamcrest provides a library of "matcher" objects that allow for more flexible and readable assertion syntax, especially with the `assertThat(actual, matcher)` method. Instead of just `assertEquals(actual, expected)`, you can write `assertThat(myList, hasSize(5))` or `assertThat(myString, containsString("substring"))`. This makes assertions more expressive, self-descriptive, and easier to understand, particularly for complex conditions or collections.

## Hands-on Exercise
**Objective**: Create a TestNG test class that thoroughly tests a simple `ShoppingCart` class using at least 10 different TestNG assertions, including at least one `assertThat` with Hamcrest.

**Instructions**:
1.  **Create a `ShoppingCart` Class**:
    ```java
    import java.util.ArrayList;
    import java.util.List;

    public class ShoppingCart {
        private List<String> items;
        private double totalAmount;

        public ShoppingCart() {
            this.items = new ArrayList<>();
            this.totalAmount = 0.0;
        }

        public void addItem(String item, double price) {
            if (item == null || item.trim().isEmpty()) {
                throw new IllegalArgumentException("Item name cannot be null or empty.");
            }
            items.add(item);
            totalAmount += price;
        }

        public void removeItem(String item) {
            if (!items.contains(item)) {
                throw new IllegalArgumentException("Item not found in cart: " + item);
            }
            // For simplicity, we won't adjust totalAmount on remove here, 
            // as prices aren't stored with items. Focus on assertion types.
            items.remove(item);
        }

        public List<String> getItems() {
            return new ArrayList<>(items); // Return a copy to prevent external modification
        }

        public int getItemCount() {
            return items.size();
        }

        public double getTotalAmount() {
            return totalAmount;
        }

        public void clearCart() {
            items.clear();
            totalAmount = 0.0;
        }
    }
    ```
2.  **Create a TestNG Test Class (`ShoppingCartTest`)**:
    -   Write several `@Test` methods.
    -   In these methods, add items to the cart, remove items, clear the cart, and then use at least 10 different `Assert` methods (including `assertThat` and `assertThrows`) to verify the cart's state (e.g., item count, total amount, presence/absence of items, null checks, exception handling).
    -   Ensure each assertion has a meaningful message.

## Additional Resources
-   **TestNG Official Assertions Documentation**: [https://testng.org/doc/documentation-main.html#assertions](https://testng.org/doc/documentation-main.html#assertions)
-   **Hamcrest Tutorial**: [http://hamcrest.org/JavaHamcrest/tutorial](http://hamcrest.org/JavaHamcrest/tutorial/)
-   **Baeldung: TestNG Assertions**: [https://www.baeldung.com/testng-assertions](https://www.baeldung.com/testng-assertions)
