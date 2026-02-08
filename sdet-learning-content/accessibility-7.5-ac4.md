# Integrate axe-core into automation tests

## Overview
Automated accessibility testing is a critical component of a robust SDET strategy. `axe-core` is an open-source accessibility testing engine developed by Deque Systems. It is widely recognized for its accuracy and ease of integration into existing test automation frameworks. This guide focuses on integrating `axe-core` with popular browser automation tools like Selenium and Playwright to detect common accessibility violations early in the development cycle.

Integrating `axe-core` allows SDETs to programmatically check web pages against a subset of WCAG (Web Content Accessibility Guidelines) rules, providing fast feedback on issues such as missing alt text, insufficient color contrast, or incorrect ARIA attributes. This proactive approach significantly reduces the cost and effort of fixing accessibility bugs compared to discovering them manually later in the process.

## Detailed Explanation
`axe-core` works by analyzing the rendered DOM of a web page. It identifies violations based on a set of predefined rules. The typical workflow involves:
1.  **Injecting the `axe-core` script**: The `axe-core` JavaScript library needs to be executed within the context of the web page being tested. This can be done by injecting the script into the browser's current page.
2.  **Running the analysis**: Once injected, `axe-core` exposes a global `axe` object. The `axe.run()` method is called to start the accessibility scan. This method returns a promise that resolves with an object containing `violations`, `passes`, `incomplete`, and `inapplicable` results.
3.  **Asserting violations**: The most crucial part is to assert that the `violations` array is empty or contains only expected, allowed violations (e.g., for known third-party components). Any detected violations should fail the test, prompting immediate attention from the development team.

`axe-core` can be configured to run on specific elements, exclude certain elements, or include/exclude specific accessibility rules or tags (e.g., 'wcag2a', 'wcag2aa', 'best-practice'). This flexibility allows for targeted testing and managing false positives.

### Why automate accessibility with axe-core?
-   **Early detection**: Catches issues during CI/CD, preventing them from reaching production.
-   **Consistency**: Ensures consistent application of accessibility standards across the codebase.
-   **Efficiency**: Automates repetitive checks, freeing up manual testers for more complex scenarios.
-   **Developer education**: Provides concrete, actionable feedback to developers on accessibility issues.

## Code Implementation

Here are examples for integrating `axe-core` with Selenium (Java) and Playwright (TypeScript/JavaScript).

### Example 1: Selenium with Java

This example uses `selenium-java` and `axe-selenium-java` for easier integration.

#### Add Dependencies (pom.xml)
```xml
<!-- ... other dependencies ... -->
<dependency>
    <groupId>org.seleniumhq.selenium</groupId>
    <artifactId>selenium-java</artifactId>
    <version>4.17.0</version> <!-- Use your preferred Selenium version -->
</dependency>
<dependency>
    <groupId>com.dequeawesome</groupId>
    <artifactId>axe-selenium</artifactId>
    <version>4.8.0</version> <!-- Use the latest version -->
</dependency>
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>7.8.0</version> <!-- Or JUnit -->
    <scope>test</scope>
</dependency>
```

#### Accessibility Test Class (Java)
```java
import com.deque.html.axecore.selenium.AxeBuilder;
import com.deque.html.axecore.selenium.AxeReporter;
import com.deque.html.axecore.results.AxeResults;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.testng.Assert;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.Collections;
import java.util.List;

public class AccessibilityTest {

    private WebDriver driver;

    @BeforeClass
    public void setup() {
        // Set the path to your chromedriver executable
        // For example: System.setProperty("webdriver.chrome.driver", "/path/to/chromedriver");
        // WebDriverManager can be used for automatic driver management
        driver = new ChromeDriver();
        driver.manage().window().maximize();
    }

    @Test
    public void testHomePageAccessibility() {
        driver.get("https://www.google.com"); // Replace with your target URL

        // Run axe-core analysis
        AxeResults axeResults = new AxeBuilder()
                .withTags(Collections.singletonList("wcag2aa")) // Specify WCAG 2.1 Level AA rules
                .analyze(driver);

        // Report violations to console and a JSON file
        if (!axeResults.getViolations().isEmpty()) {
            AxeReporter.get ; // Placeholder for reporting (see AxeReporter methods)
            // Example: AxeReporter.writeResultsToJson("axe-report-homepage.json", axeResults);
            // AxeReporter.writeResultsToTextFile("axe-report-homepage.txt", axeResults);
        }

        // Assert that there are no accessibility violations
        Assert.assertEquals(0, axeResults.getViolations().size(),
                "Accessibility violations found on the home page. See console/report for details.");
    }

    @Test
    public void testLoginPageAccessibility() {
        driver.get("https://www.example.com/login"); // Replace with your login page URL

        // Exclude specific elements if necessary, e.g., a known third-party widget
        AxeResults axeResults = new AxeBuilder()
                .exclude("div.third-party-widget") // Exclude by CSS selector
                .withTags(List.of("wcag2a", "wcag21a")) // You can specify multiple tags
                .analyze(driver);

        AxeReporter.writeResultsToJson("axe-report-loginpage.json", axeResults);

        Assert.assertEquals(0, axeResults.getViolations().size(),
                "Accessibility violations found on the login page. Check axe-report-loginpage.json.");
    }

    @AfterClass
    public void teardown() {
        if (driver != null) {
            driver.quit();
        }
    }
}
```

### Example 2: Playwright with TypeScript

Playwright has excellent built-in support for `axe-core` via the `axe-playwright` library.

#### Install Dependencies
```bash
npm install -D playwright @playwright/test axe-core axe-playwright
```

#### Accessibility Test File (TypeScript)
```typescript
import { test, expect } from '@playwright/test';
import { AxeBuilder } from '@axe-core/playwright'; // Import AxeBuilder
import * as fs from 'fs';

test.describe('Accessibility Scans', () => {

    test('should not have any accessibility violations on the homepage', async ({ page }) => {
        await page.goto('https://www.google.com'); // Replace with your target URL

        const accessibilityScanResults = await new AxeBuilder({ page })
            .withTags(['wcag2aa', 'wcag21aa']) // Specify WCAG 2.1 Level AA rules
            .analyze();

        // Optionally, save the results to a JSON file for detailed review
        fs.writeFileSync('axe-report-homepage.json', JSON.stringify(accessibilityScanResults.violations, null, 2));

        expect(accessibilityScanResults.violations).toEqual([]);
    });

    test('should not have critical accessibility violations on the login page', async ({ page }) => {
        await page.goto('https://www.example.com/login'); // Replace with your login page URL

        const accessibilityScanResults = await new AxeBuilder({ page })
            .exclude('div.promo-banner') // Exclude specific elements if needed
            .withTags(['wcag2a']) // Focus on WCAG Level A issues
            .disableRules(['color-contrast']) // Temporarily disable a specific rule
            .analyze();

        // Filter for critical violations (if you only want to fail on these)
        const criticalViolations = accessibilityScanResults.violations.filter(
            (violation) => violation.impact === 'critical'
        );

        fs.writeFileSync('axe-report-loginpage-critical.json', JSON.stringify(criticalViolations, null, 2));

        expect(criticalViolations).toEqual([]);
    });
});
```

## Best Practices
-   **Integrate into CI/CD**: Run accessibility tests as part of your Continuous Integration pipeline to catch regressions immediately.
-   **Target critical flows**: Prioritize testing key user journeys and high-traffic pages.
-   **Educate the team**: Share axe-core reports with developers and designers to foster a culture of accessibility.
-   **Automate, don't solely rely**: Automated accessibility tests catch about 50% of WCAG issues. Supplement with manual expert review for full coverage.
-   **Regularly update `axe-core`**: Keep the library updated to benefit from new rules and improved detection.
-   **Configure rules wisely**: Use `withTags()` or `disableRules()` to focus on relevant issues and manage noise, especially for legacy systems.

## Common Pitfalls
-   **Ignoring results**: Generating reports but not acting on violations defeats the purpose. Integrate reporting into bug tracking systems.
-   **Over-reliance on automation**: Believing automated tools cover all accessibility needs. Manual testing, screen reader testing, and expert reviews are still essential.
-   **Not handling dynamic content**: `axe-core` needs to be run *after* dynamic content (e.g., modals, AJAX loaded data) has rendered. Use `page.waitForLoadState('networkidle')` in Playwright or explicit waits in Selenium.
-   **Testing against non-representative states**: Ensure tests interact with the page to reveal different states (e.g., expanded accordions, selected tabs) to uncover more issues.
-   **Failing on all violations immediately**: For existing large applications, start by focusing on critical violations and gradually expand coverage.

## Interview Questions & Answers
1.  **Q: What is `axe-core` and why is it beneficial for SDETs?**
    A: `axe-core` is an open-source accessibility testing engine that helps identify common accessibility violations in web applications. For SDETs, it's beneficial because it automates a significant portion of accessibility checks, integrates easily into existing test frameworks (like Selenium, Playwright), provides fast feedback in CI/CD, and helps enforce WCAG standards early in the development lifecycle. This leads to more accessible products and reduces rework.

2.  **Q: How do you integrate `axe-core` into an existing Selenium (Java) or Playwright (TypeScript) test suite?**
    A: **Selenium (Java)**: Add `axe-selenium` dependency, then use `AxeBuilder` to create an analysis object. Call `analyze(driver)` on a WebDriver instance, and then use `AxeReporter` to process the `AxeResults`. Assert on `axeResults.getViolations().size()`.
    **Playwright (TypeScript)**: Install `@axe-core/playwright`. Import `AxeBuilder` from `@axe-core/playwright`. After navigating to a page, create `new AxeBuilder({ page })` and call `.analyze()`. Assert on the `violations` array returned.

3.  **Q: What are some limitations of automated accessibility testing, and how do you address them?**
    A: Limitations include:
    *   Automated tools only catch about 50% of WCAG issues (e.g., cannot test for cognitive accessibility, logical tab order, or the meaningfulness of alt text).
    *   They might miss issues in dynamic content if not timed correctly.
    *   They can produce false positives if not configured properly.
    To address these, automated testing should be complemented by:
    *   Manual accessibility testing (e.g., keyboard navigation, screen reader testing).
    *   Expert accessibility audits.
    *   User testing with individuals with disabilities.
    *   Ensuring `axe-core` runs after all dynamic content is loaded.

4.  **Q: How do you handle accessibility violations found by `axe-core` in your CI/CD pipeline?**
    A: In a CI/CD pipeline, `axe-core` tests are typically set to fail the build if any violations are found. The reports (often JSON or HTML) are then published as build artifacts. Teams should:
    *   Integrate violation reporting into bug tracking systems (e.g., Jira).
    *   Prioritize critical and major violations.
    *   Use baseline reports for existing applications to track new regressions while systematically addressing old issues.
    *   Educate developers on how to interpret and fix the reported issues.

## Hands-on Exercise
1.  **Setup**:
    *   Create a new Playwright project (or use an existing one).
    *   Install `axe-core` and `@axe-core/playwright`.
    *   Create a simple `index.html` file in your project root with some intentional accessibility violations (e.g., an `<img>` tag without an `alt` attribute, a button without discernible text, low contrast text). You can serve this file locally using a simple web server (e.g., `npx http-server`).
2.  **Implement Test**:
    *   Write a Playwright test that navigates to your local `index.html`.
    *   Integrate `axe-core` to analyze the page.
    *   Assert that `violations` array is not empty (as you intentionally introduced violations).
    *   Modify your `AxeBuilder` to exclude one of the elements with a violation and observe the change in results.
    *   Fix the violations in `index.html` and re-run the test to ensure it passes.
3.  **Report Generation**:
    *   Extend your test to write the `axe-core` results to a JSON file.
    *   Inspect the JSON file to understand the structure of the violations reported by `axe-core`.

## Additional Resources
-   **`axe-core` GitHub Repository**: [https://github.com/dequelabs/axe-core](https://github.com/dequelabs/axe-core)
-   **`axe-playwright` Documentation**: [https://www.npmjs.com/package/@axe-core/playwright](https://www.npmjs.com/package/@axe-core/playwright)
-   **`axe-selenium-java` Documentation**: [https://github.com/dequelabs/axe-selenium-java](https://github.com/dequelabs/axe-selenium-java)
-   **Web Content Accessibility Guidelines (WCAG)**: [https://www.w3.org/WAI/WCAG21/](https://www.w3.org/WAI/WCAG21/)
-   **Deque University**: [https://www.deque.com/deque-university/](https://www.deque.com/deque-university/)