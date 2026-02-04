# TestNG Test Grouping with @Test(groups)

## Overview
TestNG's test grouping feature is a powerful mechanism that allows you to categorize your test methods into logical groups. This is incredibly useful in test automation frameworks for several reasons:
1.  **Selective Execution**: Run only a subset of your tests (e.g., "smoke" tests, "regression" tests, "sanity" tests) without modifying individual test classes.
2.  **Parallel Execution**: Combine grouping with parallel execution to run specific groups across multiple threads or machines.
3.  **Reporting**: Generate reports based on test groups, providing clear insights into the pass/fail status of different test categories.
4.  **Maintenance**: Easily manage large test suites by organizing tests based on functionality, priority, or execution type.

This feature is critical for building scalable and efficient test automation frameworks, allowing SDETs to quickly execute relevant tests for various development and deployment stages.

## Detailed Explanation
TestNG allows you to define groups for your test methods using the `groups` attribute in the `@Test` annotation. A test method can belong to one or more groups.

### Defining Groups
You can assign a test method to a single group or multiple groups:
```java
@Test(groups = {"smoke"})
public void testLogin() {
    // ...
}

@Test(groups = {"regression", "e2e"})
public void testCheckoutProcess() {
    // ...
}
```

### Configuring Groups in testng.xml
Once groups are defined in your test methods, you can control which groups to include or exclude during test execution via your `testng.xml` suite file. This is done using the `<groups>` tag within the `<test>` or `<suite>` tag.

The `<groups>` tag contains two sub-tags:
-   `<run>`: Specifies which groups to include or exclude.
    -   `<include name="groupName"/>`: Includes tests belonging to `groupName`.
    -   `<exclude name="groupName"/>`: Excludes tests belonging to `groupName`.

**Example `testng.xml` to run only "smoke" tests:**
```xml
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd">
<suite name="MyTestSuite">
    <test name="SmokeTests">
        <groups>
            <run>
                <include name="smoke"/>
            </run>
        </groups>
        <classes>
            <class name="com.example.tests.LoginTests"/>
            <class name="com.example.tests.ProductTests"/>
        </classes>
    </test>
</suite>
```

**Example `testng.xml` to run all tests EXCEPT "e2e" tests:**
```xml
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd">
<suite name="MyTestSuite">
    <test name="AllTestsExceptE2E">
        <groups>
            <run>
                <exclude name="e2e"/>
            </run>
        </groups>
        <classes>
            <class name="com.example.tests.LoginTests"/>
            <class name="com.example.tests.ProductTests"/>
            <class name="com.example.tests.CartTests"/>
        </classes>
    </test>
</suite>
```

**Groups at Suite Level:**
If `<groups>` is defined at the `<suite>` level, it applies to all `<test>` tags within that suite unless a `<test>` tag explicitly overrides it.

## Code Implementation

Let's create three test classes: `LoginTests`, `ProductTests`, and `CartTests` to demonstrate TestNG grouping.

First, the `pom.xml` should include TestNG dependency:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>TestNGGroupingDemo</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
        <testng.version>7.8.0</testng.version>
    </properties>

    <dependencies>
        <!-- TestNG Dependency -->
        <dependency>
            <groupId>org.testng</groupId>
            <artifactId>testng</artifactId>
            <version>${testng.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <!-- Maven Surefire Plugin for running TestNG tests -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.0.0-M5</version>
                <configuration>
                    <suiteXmlFiles>
                        <!-- Specify the TestNG XML suite file to run -->
                        <suiteXmlFile>testng.xml</suiteXmlFile>
                    </suiteXmlFiles>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

**`LoginTests.java`**
```java
package com.example.tests;

import org.testng.annotations.Test;

public class LoginTests {

    @Test(groups = {"smoke", "regression"})
    public void testValidLogin() {
        System.out.println("LoginTests: Executing testValidLogin - Smoke & Regression");
        // Simulate a valid login process
        // Assertions for successful login
    }

    @Test(groups = {"regression"})
    public void testInvalidLogin() {
        System.out.println("LoginTests: Executing testInvalidLogin - Regression");
        // Simulate an invalid login attempt
        // Assertions for expected error messages
    }

    @Test(groups = {"sanity"})
    public void testForgotPasswordLink() {
        System.out.println("LoginTests: Executing testForgotPasswordLink - Sanity");
        // Verify the forgot password link is present and clickable
    }
}
```

**`ProductTests.java`**
```java
package com.example.tests;

import org.testng.annotations.Test;

public class ProductTests {

    @Test(groups = {"smoke", "regression"})
    public void testViewProductDetails() {
        System.out.println("ProductTests: Executing testViewProductDetails - Smoke & Regression");
        // Simulate viewing product details
    }

    @Test(groups = {"regression"})
    public void testFilterProductsByPrice() {
        System.out.println("ProductTests: Executing testFilterProductsByPrice - Regression");
        // Simulate filtering products by price range
    }

    @Test(groups = {"e2e"})
    public void testProductReviewSubmission() {
        System.out.println("ProductTests: Executing testProductReviewSubmission - E2E");
        // Simulate submitting a product review (might involve login, product selection, form filling)
    }
}
```

**`CartTests.java`**
```java
package com.example.tests;

import org.testng.annotations.Test;

public class CartTests {

    @Test(groups = {"regression"})
    public void testAddProductToCart() {
        System.out.println("CartTests: Executing testAddProductToCart - Regression");
        // Simulate adding a product to cart
    }

    @Test(groups = {"regression", "e2e"})
    public void testRemoveProductFromCart() {
        System.out.println("CartTests: Executing testRemoveProductFromCart - Regression & E2E");
        // Simulate removing a product from cart
    }

    @Test(groups = {"smoke"})
    public void testViewCartSummary() {
        System.out.println("CartTests: Executing testViewCartSummary - Smoke");
        // Verify cart summary is visible and shows correct item count
    }
}
```

**`testng_smoke.xml`** (to run only `smoke` tests)
```xml
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd">
<suite name="SmokeTestSuite">
    <test name="ApplicationSmokeTests">
        <groups>
            <run>
                <include name="smoke"/>
            </run>
        </groups>
        <classes>
            <class name="com.example.tests.LoginTests"/>
            <class name="com.example.tests.ProductTests"/>
            <class name="com.example.tests.CartTests"/>
        </classes>
    </test>
</suite>
```

**`testng_regression.xml`** (to run `regression` tests excluding `e2e`)
```xml
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd">
<suite name="RegressionTestSuite">
    <test name="ApplicationRegressionTests">
        <groups>
            <run>
                <include name="regression"/>
                <exclude name="e2e"/> <!-- Exclude E2E tests from this regression run -->
            </run>
        </groups>
        <classes>
            <class name="com.example.tests.LoginTests"/>
            <class name="com.example.tests.ProductTests"/>
            <class name="com.example.tests.CartTests"/>
        </classes>
    </test>
</suite>
```

To run these, you would typically use Maven:
`mvn clean test -DsuiteXmlFile=testng_smoke.xml` (for smoke tests)
`mvn clean test -DsuiteXmlFile=testng_regression.xml` (for regression tests, excluding e2e)

**Expected Output for `testng_smoke.xml`:**
```
LoginTests: Executing testValidLogin - Smoke & Regression
ProductTests: Executing testViewProductDetails - Smoke & Regression
CartTests: Executing testViewCartSummary - Smoke
```
(Other tests will be skipped)

## Best Practices
-   **Meaningful Group Names**: Use clear and concise group names that reflect the purpose or scope of the tests (e.g., `smoke`, `sanity`, `regression`, `e2e`, `database`, `api`).
-   **Granularity**: Group tests at the method level. Avoid grouping entire classes if only a few methods within them belong to a specific category.
-   **Multiple Groups**: A single test method can belong to multiple groups, providing flexibility in test execution strategies.
-   **Consistency**: Maintain consistent group naming conventions across your entire test suite.
-   **XML Configuration**: Always control group execution via `testng.xml` rather than modifying annotations directly, especially for CI/CD pipelines. This allows dynamic selection of test subsets without code changes.
-   **Avoid Overlapping Exclusions/Inclusions**: Be careful when combining `<include>` and `<exclude>` tags within the same `<run>` block. TestNG processes `<include>` first and then applies `<exclude>` to the included set.

## Common Pitfalls
-   **Misunderstanding Inclusion/Exclusion Logic**: If you include a group and then try to exclude a subgroup within it, make sure the logic matches your intent. TestNG will first filter by inclusion, then by exclusion.
-   **Forgetting to Specify Classes**: If you define groups in `testng.xml` but forget to specify which test classes TestNG should look into (using `<classes>` tags), no tests might run.
-   **Mixing Group Scope**: Defining groups at the suite level and then attempting to override them entirely at the test level can lead to confusion if not done carefully.
-   **Typos in Group Names**: A simple typo in a group name in `testng.xml` will result in those tests not being found or executed.
-   **Tests Not Grouped**: If a test method is not assigned to any group, it will *always* run by default unless explicitly excluded by its class or method name. If you intend to manage all tests via groups, ensure every `@Test` method has a `groups` attribute.

## Interview Questions & Answers
1.  **Q: What is TestNG test grouping and why is it important in a test automation framework?**
    **A:** TestNG test grouping allows categorizing test methods using the `groups` attribute in the `@Test` annotation (e.g., `@Test(groups = "smoke")`). It's important because it enables selective execution of tests (e.g., running only smoke tests), simplifies managing large test suites, facilitates parallel execution strategies, and improves test reporting by category. This flexibility is crucial for efficient CI/CD pipelines, allowing different test subsets to be triggered based on deployment stage or changes made.

2.  **Q: How do you configure TestNG to run only specific groups of tests? Provide an example.**
    **A:** You configure TestNG to run specific groups using the `testng.xml` file. Within the `<test>` or `<suite>` tag, you use the `<groups>` tag with an `<run>` sub-tag and `<include>` tags.
    **Example:**
    ```xml
    <!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd">
    <suite name="SelectedGroupsSuite">
        <test name="OnlySmokeAndSanity">
            <groups>
                <run>
                    <include name="smoke"/>
                    <include name="sanity"/>
                </run>
            </groups>
            <classes>
                <class name="com.example.tests.LoginTests"/>
                <class name="com.example.tests.ProductTests"/>
            </classes>
        </test>
    </suite>
    ```
    This configuration will execute only test methods belonging to the "smoke" or "sanity" groups from the specified classes.

3.  **Q: Can a single test method belong to multiple groups? If so, how is it defined?**
    **A:** Yes, a single test method can belong to multiple groups. You define this by providing an array of group names to the `groups` attribute in the `@Test` annotation.
    **Example:**
    ```java
    @Test(groups = {"smoke", "regression", "dailyBuild"})
    public void testCriticalFeature() {
        System.out.println("Executing critical feature test.");
    }
    ```
    This test method will be executed if any of the "smoke", "regression", or "dailyBuild" groups are included in the `testng.xml` configuration.

## Hands-on Exercise
1.  **Create a New Test Class**: Add a new Java class named `OrderTests.java` to the `com.example.tests` package.
2.  **Add Test Methods**:
    *   `testPlaceOrder()`: Assign to `regression` and `e2e` groups.
    *   `testViewOrderHistory()`: Assign to `regression` group.
    *   `testCancelOrder()`: Assign to `e2e` group.
3.  **Create `testng_e2e.xml`**: Create a new `testng.xml` file named `testng_e2e.xml`.
    *   Configure this XML to *only* run tests belonging to the `e2e` group from all three test classes (`LoginTests`, `ProductTests`, `CartTests`, `OrderTests`).
4.  **Execute and Verify**: Run the `testng_e2e.xml` suite using Maven and confirm that only the tests annotated with `e2e` are executed, and others are skipped.

## Additional Resources
-   **TestNG Official Documentation - Test Groups**: [https://testng.org/doc/documentation-main.html#test-groups](https://testng.org/doc/documentation-main.html#test-groups)
-   **Maven Surefire Plugin Documentation**: [https://maven.apache.org/surefire/maven-surefire-plugin/usage.html](https://maven.apache.org/surefire/maven-surefire-plugin/usage.html)
-   **TestNG Tutorial - Test Groups (Guru99)**: [https://www.guru99.com/testng-group-tests.html](https://www.guru99.com/testng-group-tests.html)