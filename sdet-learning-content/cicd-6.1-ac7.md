# Test Categorization Strategies (Smoke, Sanity, Regression)

## Overview
Effective test categorization is crucial for optimizing the software development lifecycle, ensuring quality, and managing release risks. It allows teams to execute the right tests at the right time, providing rapid feedback while maintaining comprehensive coverage. This document discusses three primary test categories: Smoke, Sanity, and Regression tests, detailing their purpose, scope, and optimal execution frequencies within a CI/CD pipeline.

## Detailed Explanation

### 1. Smoke Tests (Critical Path)
**Definition**: Smoke tests are a subset of test cases that cover the most important and critical functionalities of an application. Their primary purpose is to ascertain if the most essential functions of the software work, or if the build is "broken" at a fundamental level, preventing further testing. They are like a "smoke detector" – if there's smoke, there's likely fire, and deeper investigation is needed.

**Characteristics**:
*   **Minimalistic**: Focus on core, end-to-end user journeys.
*   **Quick to Execute**: Designed to run very fast to provide immediate feedback.
*   **High Priority**: Cover functionalities without which the application is unusable (e.g., login, main search, core transaction).
*   **Build Verification**: Often run after every new build or deployment.

**Example**: For an e-commerce application, a smoke test might involve:
1.  Launching the application.
2.  Logging in with valid credentials.
3.  Navigating to the product page.
4.  Adding an item to the cart.
5.  Proceeding to checkout (without completing the payment).

### 2. Sanity Tests (Feature Verification)
**Definition**: Sanity tests are performed to ensure that new functionalities or bug fixes work as expected and that no major issues have been introduced by the recent changes. They are a narrow and deep form of testing focused on specific areas of recent code changes.

**Characteristics**:
*   **Focused**: Target newly added features, bug fixes, or changed modules.
*   **Quick to Execute**: Shorter than regression tests, focusing only on affected areas.
*   **Pre-Regression**: Often run before a full regression suite to ensure the system is stable enough for deeper testing.
*   **After Specific Changes**: Typically executed after a new feature is developed or a bug is fixed.

**Example**: If a new payment gateway is integrated into the e-commerce application, a sanity test would focus specifically on:
1.  Adding an item to the cart.
2.  Proceeding to checkout.
3.  Selecting the new payment gateway.
4.  Completing a test transaction via the new gateway.
5.  Verifying transaction success and order confirmation.

### 3. Regression Tests (Full Suite)
**Definition**: Regression testing is the process of re-running functional and non-functional tests to ensure that previously developed and tested software still performs after a change. These changes can include bug fixes, new features, or configuration changes. The goal is to ensure that new code doesn't break existing functionality.

**Characteristics**:
*   **Comprehensive**: Cover a broad range of functionalities, often including smoke and sanity tests.
*   **Time-Consuming**: Can take significant time to execute due to their breadth.
*   **Stability Assurance**: Crucial for guaranteeing the overall stability and reliability of the application.
*   **Scheduled Execution**: Typically run before major releases, during nightly builds, or after significant code merges.

**Example**: For the e-commerce application, a regression suite would include:
*   All smoke test cases.
*   All sanity test cases for recent features.
*   Tests for user management (registration, profile updates).
*   Tests for product catalog browsing, filtering, and search.
*   Tests for order history, returns, and customer support features.
*   Performance and security tests (if automated and integrated).

### Execution Frequency
Assigning the correct execution frequency is vital for efficient CI/CD.

*   **Smoke Tests**:
    *   **Frequency**: **Every commit/push to `main` branch**, **every successful build**, **before every deployment to any environment (dev, staging, production)**.
    *   **Rationale**: Provide immediate feedback on the core stability of the application, failing fast if critical issues exist.

*   **Sanity Tests**:
    *   **Frequency**: **After each major feature integration**, **before merging feature branches into integration branches**, **daily on integration branches**.
    *   **Rationale**: Verify the stability of newly developed or fixed modules before proceeding with broader testing.

*   **Regression Tests**:
    *   **Frequency**: **Nightly builds on integration branches**, **weekly on release branches**, **before every major release candidate deployment**.
    *   **Rationale**: Ensure overall system stability and prevent unintended side effects from cumulative changes.

## Code Implementation

While test categorization is a strategic concept, its implementation relies on how you organize your automated tests within a framework (e.g., TestNG, JUnit, Playwright, Pytest). Here's a conceptual example using a Java/TestNG structure, demonstrating how you might tag or group tests.

```java
// Example using TestNG for test categorization

import org.testng.annotations.Test;

public class EcommerceTests {

    // --- Smoke Tests ---
    // These tests verify the absolute critical path of the application.
    // They should run frequently and quickly.
    @Test(groups = {"smoke", "critical"})
    public void testUserLogin() {
        System.out.println("Executing Smoke: User login functionality.");
        // Simulate login logic
        assert true; // Placeholder for actual assertion
    }

    @Test(groups = {"smoke", "critical"})
    public void testAddItemToCart() {
        System.out.println("Executing Smoke: Add item to cart functionality.");
        // Simulate adding item to cart
        assert true;
    }

    @Test(groups = {"smoke", "critical"})
    public void testNavigateToCheckout() {
        System.out.println("Executing Smoke: Navigate to checkout page.");
        // Simulate navigation
        assert true;
    }

    // --- Sanity Tests ---
    // These tests focus on new features or bug fixes.
    // Let's assume 'NewPaymentGateway' was recently added.
    @Test(groups = {"sanity", "newPaymentGateway"})
    public void testNewPaymentGatewayTransaction() {
        System.out.println("Executing Sanity: New payment gateway transaction.");
        // Simulate transaction with new gateway
        assert true;
    }

    @Test(groups = {"sanity", "bugfix"})
    public void testFixedSearchFilterBug() {
        System.out.println("Executing Sanity: Verify search filter bug fix.");
        // Simulate testing the bug fix
        assert true;
    }

    // --- Regression Tests ---
    // These tests cover broader functionality, including all smoke and sanity tests.
    // In TestNG, you can define suites to include groups.
    // For individual tests, they might belong to 'regression' by default or explicitly.
    @Test(groups = {"regression"})
    public void testUserProfileUpdate() {
        System.out.println("Executing Regression: User profile update.");
        // Simulate profile update
        assert true;
    }

    @Test(groups = {"regression"})
    public void testProductReviewSubmission() {
        System.out.println("Executing Regression: Product review submission.");
        // Simulate review submission
        assert true;
    }

    @Test(groups = {"regression"})
    public void testOrderHistoryView() {
        System.out.println("Executing Regression: View order history.");
        // Simulate viewing order history
        assert true;
    }

    // Example of how to run these groups from a TestNG XML file:
    /*
    <!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd" >
    <suite name="TestCategorizationSuite">

        <test name="SmokeTests">
            <groups>
                <run>
                    <include name="smoke"/>
                </run>
            </groups>
            <classes>
                <class name="EcommerceTests"/>
            </classes>
        </test>

        <test name="SanityTests">
            <groups>
                <run>
                    <include name="sanity"/>
                </run>
            </groups>
            <classes>
                <class name="EcommerceTests"/>
            </classes>
        </test>

        <test name="FullRegressionTests">
            <groups>
                <run>
                    <include name="smoke"/>
                    <include name="sanity"/>
                    <include name="regression"/>
                    <!-- Or simply define all classes/packages to run -->
                </run>
            </groups>
            <classes>
                <class name="EcommerceTests"/>
            </classes>
        </test>

    </suite>
    */
}
```

## Best Practices
-   **Automate Everything Possible**: Manual smoke, sanity, or regression tests are bottlenecks. Automate them to run quickly and consistently.
-   **Maintain Clear Tagging/Grouping**: Use robust test framework features (e.g., TestNG groups, JUnit categories, Playwright tags) to clearly categorize tests.
-   **Isolate Test Data**: Ensure tests are independent and use isolated test data to avoid flaky results.
-   **Continuous Refinement**: Regularly review and update test categories as the application evolves, ensuring tests remain relevant and efficient.
-   **Integrate with CI/CD**: Configure CI/CD pipelines to trigger specific test categories based on events (e.g., commit, merge, deployment) and publish reports.
-   **Prioritize Failures**: Ensure that failures in higher-priority tests (smoke, critical sanity) halt the pipeline and notify relevant teams immediately.

## Common Pitfalls
-   **Overlapping Scope without Purpose**: Having too many tests in smoke or sanity that belong in regression can slow down critical feedback loops.
    *   **Avoidance**: Clearly define the scope for each category and review periodically.
-   **Lack of Automation**: Relying on manual execution for any of these categories, especially smoke and sanity, defeats the purpose of rapid feedback.
    *   **Avoidance**: Prioritize automation for all critical test paths.
-   **Poor Test Maintenance**: Stale, flaky, or irrelevant tests across categories dilute their value and lead to distrust in the test results.
    *   **Avoidance**: Implement regular test review and maintenance cycles.
-   **Ignoring Failures**: Allowing pipelines to pass with known smoke or sanity failures can lead to significant issues downstream.
    *   **Avoidance**: Implement strict quality gates; a single smoke or critical sanity failure should break the build.
-   **Lack of Reporting**: Without clear reporting, it's hard to understand the status of different test categories and overall quality.
    *   **Avoidance**: Integrate with reporting tools that show test results by category and provide actionable insights.

## Interview Questions & Answers
1.  **Q**: Differentiate between Smoke, Sanity, and Regression testing in the context of a CI/CD pipeline.
    **A**:
    *   **Smoke Testing**: Performed on every new build to ensure critical functionalities are working. It's a quick, high-level check to determine if the build is stable enough for further testing. In CI/CD, it runs first and often.
    *   **Sanity Testing**: A subset of regression testing focused on newly implemented functionalities or bug fixes. It's a narrow and deep check to ensure the new changes work as intended without introducing major issues. In CI/CD, it runs after specific feature development or bug fixes, often before merging to a main branch.
    *   **Regression Testing**: Re-executing existing test cases to ensure that recent code changes (new features, bug fixes, configuration changes) haven't negatively impacted existing functionalities. It's comprehensive and generally runs less frequently but thoroughly, e.g., nightly or before major releases in CI/CD.

2.  **Q**: How would you decide which tests belong to the "smoke" category?
    **A**: Smoke tests should cover the absolute core, critical functionalities without which the application is fundamentally broken or unusable. I would identify key user journeys that must work for any user to derive value (e.g., login, basic search, add to cart for e-commerce, creating a new record for a CRM). These are the "showstoppers" – if they fail, further testing is pointless.

3.  **Q**: What mechanisms would you use in an automation framework (e.g., TestNG/JUnit) to implement test categorization?
    **A**: Most modern automation frameworks offer mechanisms for grouping or tagging tests.
    *   **TestNG**: Uses the `@Test(groups = {"groupName"})` annotation. You can then specify which groups to include or exclude in your `testng.xml` file or via command line.
    *   **JUnit 5**: Uses `@Tag("tagName")` annotation. Tests can be run by specifying tags through build tools like Maven or Gradle.
    *   **Playwright**: Supports `test.describe.configure({ mode: 'only-runs-this-type' })` or using `test.skip` based on conditions, and custom logic to filter tests by file path or test name patterns.
    *   **Pytest**: Uses `@pytest.mark.markerName` to tag tests, and you can run specific markers using `pytest -m "markerName"`.

4.  **Q**: A critical smoke test failed in your CI pipeline. What is your immediate course of action?
    **A**: My immediate actions would be:
    1.  **Halt the Pipeline**: The CI pipeline should be configured to fail immediately upon a critical smoke test failure, preventing further steps like deployment.
    2.  **Alert Stakeholders**: Notify the development team, QA, and relevant stakeholders (e.g., via Slack, email, JIRA integration) about the build breakage, providing details on the failing test(s).
    3.  **Analyze Failure**: Quickly investigate the failure logs and artifacts (screenshots, videos) to understand the root cause. This typically involves reviewing recent code changes that could have introduced the issue.
    4.  **Prioritize Fix**: Work with the development team to prioritize a fix for the regression, as a failed smoke test indicates a severe block.

### Hands-on Exercise
**Scenario**: You are working on a banking application. Design a set of automated test cases and categorize them into Smoke, Sanity, and Regression using a pseudo-code or your preferred automation framework's syntax (e.g., TestNG/Java, Playwright/TypeScript).

**Tasks**:
1.  **Identify Smoke Tests**: What are the 3-5 most critical functionalities that must always work?
2.  **Identify Sanity Tests**: If a new "Multi-currency Transfer" feature was just implemented, what 2-3 tests would you write for sanity?
3.  **Identify Regression Tests**: List 5-7 general banking functionalities that should be part of the full regression suite.
4.  **Define Execution Frequency**: Assign a realistic execution frequency for each category within a CI/CD context.

### Additional Resources
-   **Test Automation University**: [https://testautomationu.com/](https://testautomationu.com/) (Search for courses on CI/CD, TestNG, Playwright)
-   **Martin Fowler - Test Pyramid**: [https://martinfowler.com/bliki/TestPyramid.html](https://martinfowler.com/bliki/TestPyramid.html)
-   **TestNG Documentation**: [https://testng.org/doc/index.html](https://testng.org/doc/index.html)
-   **Playwright Testing Concepts**: [https://playwright.dev/docs/intro](https://playwright.dev/docs/intro)