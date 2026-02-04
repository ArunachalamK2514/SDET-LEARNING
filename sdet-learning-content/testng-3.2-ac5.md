# TestNG: Soft Assertions vs. Hard Assertions

## Overview
In automated testing, assertions are crucial for validating the expected behavior of an application. TestNG, a powerful testing framework for Java, provides robust assertion mechanisms. This section delves into two primary types of assertions: Hard Assertions and Soft Assertions. Understanding when and how to use each is vital for writing effective, resilient, and comprehensive test suites. Hard assertions stop test execution immediately upon failure, while soft assertions allow a test to continue running even after a failure, aggregating all failures before reporting them.

## Detailed Explanation

### Hard Assertions
Hard assertions, provided by TestNG's `org.testng.Assert` class, are the default and most commonly used type of assertion. When a hard assertion fails, TestNG immediately marks the test method as failed and stops its execution. This means any subsequent code or assertions within that test method will not be executed.

**Use Cases for Hard Assertions:**
- **Critical Preconditions:** When a fundamental condition must be met for the rest of the test to be meaningful. For example, if a user login fails, there's no point in proceeding with tests that require an authenticated session.
- **Single Point of Failure:** In unit tests where each test method typically focuses on a single, isolated piece of functionality and a single assertion.
- **Fast Feedback:** When you want to fail fast and get immediate feedback on critical failures without wasting time on subsequent steps that are guaranteed to fail anyway.

**Example Scenario:**
Consider a login test. If the login itself fails, any further steps like navigating to a dashboard or verifying user-specific content are irrelevant. A hard assertion for the login success is appropriate here.

### Soft Assertions
Soft assertions, provided by the `org.testng.asserts.SoftAssert` class, are designed to collect all assertion failures within a test method without stopping its execution. The test method continues to run until its completion, and only then are all accumulated failures reported by calling `softAssert.assertAll()`. If `assertAll()` is not called, the test will appear to pass even if soft assertions failed.

**Use Cases for Soft Assertions:**
- **Multiple Independent Validations:** When a test method needs to perform several checks that are not strictly dependent on each other, and you want to know about all failures in a single run. For example, validating multiple fields on a form or different elements on a single page.
- **End-to-End Flow Validation:** In integration or end-to-end tests where a failure in one step doesn't necessarily invalidate the outcome of subsequent, independent validations within the same test flow.
- **Comprehensive Error Reporting:** When you want to gather as much information as possible about all issues in a single test run, especially in UI tests where multiple elements might be incorrectly displayed.

**Why `softAssert.assertAll()` is Necessary:**
The `softAssert.assertAll()` method is crucial because it's responsible for actually evaluating all the soft assertions made and throwing an `AssertionError` if any of them failed. Without this call, even if soft assertions (`softAssert.assertEquals`, `softAssert.assertTrue`, etc.) fail, TestNG will not mark the test method as failed, leading to a false positive (test appears to pass when it should have failed). This method should always be called at the very end of the test method where `SoftAssert` instances are used.

## Code Implementation

First, ensure you have TestNG added to your project's `pom.xml` (for Maven) or `build.gradle` (for Gradle).

```xml
<!-- Maven dependency for TestNG -->
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>7.8.0</version> <!-- Use the latest stable version -->
    <scope>test</scope>
</dependency>
```

```java
import org.testng.Assert;
import org.testng.annotations.Test;
import org.testng.asserts.SoftAssert;

public class AssertionExamples {

    // --- Hard Assertions ---

    @Test(description = "Demonstrates immediate failure with Hard Assertion")
    public void testHardAssertionFailure() {
        System.out.println("--- Starting testHardAssertionFailure ---");
        String actualTitle = "Welcome Page";
        String expectedTitle = "Login Page"; // Intentionally incorrect

        System.out.println("Performing first hard assertion: Check Page Title");
        Assert.assertEquals(actualTitle, expectedTitle, "Page title mismatch"); // This will fail

        System.out.println("This line will NOT be executed due to previous hard assertion failure.");
        Assert.assertTrue(false, "This assertion will never be reached."); // This assertion is never hit
        System.out.println("--- Ending testHardAssertionFailure ---"); // This line is also not reached
    }

    @Test(description = "Demonstrates successful Hard Assertion")
    public void testHardAssertionSuccess() {
        System.out.println("--- Starting testHardAssertionSuccess ---");
        int actualSum = 5 + 5;
        int expectedSum = 10;

        System.out.println("Performing first hard assertion: Check Sum");
        Assert.assertEquals(actualSum, expectedSum, "Sum calculation is incorrect"); // This will pass

        System.out.println("Performing second hard assertion: Check Boolean");
        Assert.assertTrue(true, "Boolean condition is false"); // This will pass
        System.out.println("All hard assertions passed in testHardAssertionSuccess.");
        System.out.println("--- Ending testHardAssertionSuccess ---");
    }


    // --- Soft Assertions ---

    @Test(description = "Demonstrates collecting multiple failures with Soft Assertion")
    public void testSoftAssertionMultipleFailures() {
        System.out.println("
--- Starting testSoftAssertionMultipleFailures ---");
        SoftAssert softAssert = new SoftAssert();

        String actualProductName = "Laptop Pro";
        String expectedProductName = "Laptop Pro Max"; // Intentionally incorrect
        double actualPrice = 1200.50;
        double expectedPrice = 1200.50;
        boolean isInStock = false; // Intentionally incorrect state

        System.out.println("Performing first soft assertion: Check Product Name");
        softAssert.assertEquals(actualProductName, expectedProductName, "Product name mismatch!"); // Will fail

        System.out.println("Performing second soft assertion: Check Product Price");
        softAssert.assertEquals(actualPrice, expectedPrice, "Product price mismatch!"); // Will pass

        System.out.println("Performing third soft assertion: Check In Stock Status");
        softAssert.assertTrue(isInStock, "Product is out of stock!"); // Will fail

        System.out.println("All soft assertions have been evaluated. Now calling assertAll()...");

        // This line is CRITICAL. It will throw an AssertionError if any soft assertion failed.
        softAssert.assertAll();
        System.out.println("--- Ending testSoftAssertionMultipleFailures (This line reached only if all soft asserts pass) ---");
    }

    @Test(description = "Demonstrates successful Soft Assertion")
    public void testSoftAssertionSuccess() {
        System.out.println("
--- Starting testSoftAssertionSuccess ---");
        SoftAssert softAssert = new SoftAssert();

        String actualStatus = "ACTIVE";
        String expectedStatus = "ACTIVE";
        int actualCount = 100;
        int expectedCount = 100;

        System.out.println("Performing first soft assertion: Check Status");
        softAssert.assertEquals(actualStatus, expectedStatus, "Status mismatch!"); // Will pass

        System.out.println("Performing second soft assertion: Check Count");
        softAssert.assertTrue(actualCount == expectedCount, "Count mismatch!"); // Will pass

        System.out.println("All soft assertions have been evaluated. Now calling assertAll()...");
        softAssert.assertAll(); // All will pass, so no exception thrown
        System.out.println("All soft assertions passed in testSoftAssertionSuccess.");
        System.out.println("--- Ending testSoftAssertionSuccess ---");
    }
}
