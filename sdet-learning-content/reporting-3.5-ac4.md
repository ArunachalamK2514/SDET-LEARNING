# Add screenshots on test failure automatically

## Overview
Automating screenshot capture on test failure is a crucial aspect of robust test automation frameworks. It significantly enhances debugging capabilities by providing visual context of the application's state at the exact moment a test fails. This feature is particularly valuable in UI automation, where visual discrepancies or unexpected element states often lead to test failures. Integrating this directly into reporting, like ExtentReports, makes the reports more informative and actionable.

## Detailed Explanation
When a test fails, especially in UI automation, a simple stack trace might not be enough to pinpoint the root cause. A screenshot captured at the point of failure provides invaluable visual evidence. It can show:
- Incorrect UI rendering.
- Elements not found or not interactable.
- Unexpected pop-ups or error messages.
- Data display issues.

To implement this, we typically leverage test listener interfaces provided by testing frameworks (e.g., `ITestListener` in TestNG, `TestWatcher` in JUnit 5) or custom listeners for other frameworks. Within the `onTestFailure` (or equivalent) method of these listeners, we programmatically capture a screenshot and then attach it to the test report.

The process generally involves:
1.  **WebDriver Instance:** Accessing the `WebDriver` instance used by the failing test.
2.  **Screenshot Capture:** Using `TakesScreenshot` interface provided by Selenium WebDriver to capture the screen.
3.  **File Handling:** Saving the captured screenshot to a designated directory.
4.  **Report Integration:** Adding the screenshot to the test report (e.g., ExtentReports, Allure, ReportNG) so it's directly visible alongside the failed test details.

## Code Implementation
Here's a comprehensive example using TestNG and ExtentReports to automatically capture and attach screenshots on test failure.

First, define a base test class that initializes the WebDriver and sets up ExtentReports.

```java
// src/test/java/com/example/BaseTest.java
package com.example;

import com.aventstack.extentreports.ExtentReports;
import com.aventstack.extentreports.ExtentTest;
import com.aventstack.extentreports.Status;
import com.aventstack.extentreports.reporter.ExtentSparkReporter;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.testng.ITestResult;
import org.testng.annotations.*;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Objects;

public class BaseTest {
    protected static WebDriver driver;
    protected static ExtentReports extent;
    protected static ThreadLocal<ExtentTest> extentTest = new ThreadLocal<>();

    @BeforeSuite
    public void setupExtentReports() {
        // Ensure reports directory exists
        try {
            Files.createDirectories(Paths.get("test-output/ExtentReports"));
        } catch (IOException e) {
            System.err.println("Failed to create ExtentReports directory: " + e.getMessage());
        }

        ExtentSparkReporter sparkReporter = new ExtentSparkReporter("test-output/ExtentReports/index.html");
        sparkReporter.config().setReportName("Web Automation Results");
        sparkReporter.config().setDocumentTitle("Test Execution Report");

        extent = new ExtentReports();
        extent.attachReporter(sparkReporter);
        extent.setSystemInfo("Tester", "Your Name");
        extent.setSystemInfo("OS", System.getProperty("os.name"));
        extent.setSystemInfo("Browser", "Chrome");
    }

    @BeforeMethod
    public void setup(ITestResult result) {
        // Initialize WebDriver
        // Make sure to set the path to your ChromeDriver executable
        // System.setProperty("webdriver.chrome.driver", "path/to/chromedriver.exe");
        driver = new ChromeDriver();
        driver.manage().window().maximize();

        // Create a new test entry in ExtentReports for each test method
        ExtentTest test = extent.createTest(result.getMethod().getMethodName());
        extentTest.set(test);
    }

    @AfterMethod
    public void tearDown(ITestResult result) {
        if (result.getStatus() == ITestResult.FAILURE) {
            extentTest.get().log(Status.FAIL, "Test Failed");
            extentTest.get().fail(result.getThrowable()); // Log the exception

            try {
                // Capture screenshot on failure
                String screenshotPath = ScreenshotUtil.captureScreenshot(driver, result.getMethod().getMethodName());
                // Attach screenshot to Extent Report
                extentTest.get().addScreenCaptureFromPath(screenshotPath, "Failed Test Screenshot");
            } catch (IOException e) {
                extentTest.get().fail("Failed to attach screenshot: " + e.getMessage());
            }
        } else if (result.getStatus() == ITestResult.SUCCESS) {
            extentTest.get().log(Status.PASS, "Test Passed");
        } else if (result.getStatus() == ITestResult.SKIP) {
            extentTest.get().log(Status.SKIP, "Test Skipped");
        }

        // Close browser
        if (driver != null) {
            driver.quit();
        }
    }

    @AfterSuite
    public void flushExtentReports() {
        extent.flush(); // Write the report to the file
    }
}
```

Next, create a utility class for capturing screenshots.

```java
// src/main/java/com/example/ScreenshotUtil.java
package com.example;

import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.io.FileHandler;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.text.SimpleDateFormat;
import java.util.Date;

public class ScreenshotUtil {

    public static String captureScreenshot(WebDriver driver, String screenshotName) throws IOException {
        // Ensure screenshots directory exists
        String screenshotsDir = "test-output/ExtentReports/Screenshots";
        Files.createDirectories(Paths.get(screenshotsDir));

        // Generate a unique file name with timestamp
        String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
        String filePath = screenshotsDir + File.separator + screenshotName + "_" + timestamp + ".png";

        // Take screenshot and save to file
        File screenshotFile = ((TakesScreenshot) driver).getScreenshotAs(OutputType.FILE);
        File destinationFile = new File(filePath);
        FileHandler.copy(screenshotFile, destinationFile);

        System.out.println("Screenshot captured: " + destinationFile.getAbsolutePath());
        return filePath; // Return relative path for ExtentReports
    }
}
```

Finally, a sample test class that extends `BaseTest`.

```java
// src/test/java/com/example/SampleTest.java
package com.example;

import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import org.testng.Assert;
import org.testng.annotations.Test;

public class SampleTest extends BaseTest {

    @Test(description = "Verify Google Search functionality")
    public void testGoogleSearch() {
        extentTest.get().info("Starting testGoogleSearch");
        driver.get("https://www.google.com");
        extentTest.get().info("Navigated to Google");

        WebElement searchBox = driver.findElement(By.name("q"));
        searchBox.sendKeys("Selenium WebDriver");
        searchBox.submit();
        extentTest.get().info("Performed search for 'Selenium WebDriver'");

        Assert.assertTrue(driver.getTitle().contains("Selenium WebDriver"), "Page title does not contain 'Selenium WebDriver'");
        extentTest.get().pass("Test Passed: Title contains 'Selenium WebDriver'");
    }

    @Test(description = "Verify a deliberately failing scenario to check screenshot capture")
    public void testFailingScenario() {
        extentTest.get().info("Starting testFailingScenario");
        driver.get("https://www.google.com");
        extentTest.get().info("Navigated to Google");

        // Intentionally trying to find a non-existent element to cause a failure
        WebElement nonExistentElement = driver.findElement(By.id("thisElementDoesntExist"));
        nonExistentElement.sendKeys("some text"); // This line will not be reached
        extentTest.get().fail("This step should not be reached"); // This will also not be reached

        Assert.fail("Deliberately failing this test to trigger screenshot");
    }
}
```

To run these tests, you'll need `testng.xml`:

```xml
<!-- src/test/resources/testng.xml -->
<!DOCTYPE suite SYSTEM "http://testng.org/testng-1.0.dtd">
<suite name="Automation Suite">
    <listeners>
        <!-- The BaseTest class handles the listeners internally via @AfterMethod -->
        <!-- No explicit listener needed here if all tests extend BaseTest -->
    </listeners>
    <test name="Web Tests">
        <classes>
            <class name="com.example.SampleTest"/>
        </classes>
    </test>
</suite>
```

**Dependencies (Maven `pom.xml`):**

```xml
<dependencies>
    <!-- Selenium Java -->
    <dependency>
        <groupId>org.seleniumhq.selenium</groupId>
        <artifactId>selenium-java</artifactId>
        <version>4.17.0</version> <!-- Use the latest stable version -->
    </dependency>
    <!-- TestNG -->
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version> <!-- Use the latest stable version -->
        <scope>test</scope>
    </dependency>
    <!-- ExtentReports -->
    <dependency>
        <groupId>com.aventstack</groupId>
        <artifactId>extentreports</artifactId>
        <version>5.1.1</version> <!-- Use the latest stable version -->
    </dependency>
</dependencies>
```

## Best Practices
-   **Consistent Naming:** Use clear, consistent naming conventions for screenshot files (e.g., `TestClassName_MethodName_Timestamp.png`).
-   **Separate Directory:** Store screenshots in a dedicated directory, ideally within the test report output folder, for easy organization and access.
-   **Relative Paths:** When attaching to reports, use relative paths to ensure reports are portable.
-   **Error Handling:** Implement robust error handling around screenshot capture (e.g., `try-catch` blocks) to prevent test failures during the screenshot process itself.
-   **Conditional Capture:** Only capture screenshots on failure or specific critical steps to avoid unnecessary overhead and disk usage.
-   **Driver Management:** Ensure the WebDriver instance is properly passed to the screenshot utility and is not `null` when attempting to capture.
-   **Thread Safety:** For parallel execution, ensure that the WebDriver instance and ExtentTest logger are thread-safe (e.g., using `ThreadLocal`).

## Common Pitfalls
-   **`WebDriver` Not Initialized/Closed:** Attempting to capture a screenshot when the `WebDriver` instance is `null` or already closed, leading to `NullPointerException` or `NoSuchSessionException`.
-   **Incorrect Driver Casting:** Forgetting to cast the `WebDriver` instance to `TakesScreenshot` (e.g., `((TakesScreenshot) driver).getScreenshotAs(...)`).
-   **Path Issues:** Incorrect file paths for saving screenshots, leading to `FileNotFoundException` or screenshots not being saved where expected. Ensure directories exist.
-   **Permissions:** Lack of write permissions to the screenshot directory, causing `IOException`.
-   **Large Reports:** Capturing screenshots for every step, even successful ones, can bloat report size and slow down execution. Limit captures to failures.
-   **Synchronization Issues:** In highly asynchronous applications, the screenshot might not reflect the exact state at the moment of failure if there are delays in page rendering or script execution.

## Interview Questions & Answers
1.  **Q: Why is automated screenshot capture on test failure important in a CI/CD pipeline?**
    **A:** It's crucial for quick defect diagnosis and reduced mean time to recovery (MTTR). In a CI/CD pipeline, tests run unattended. A screenshot provides immediate visual context of the failure, allowing developers and QAs to understand the issue without rerunning the test or manually inspecting the environment, thereby streamlining the feedback loop and accelerating bug fixing.

2.  **Q: How would you implement screenshot capture in a Selenium-based framework using TestNG?**
    **A:** I would implement the `ITestListener` interface (or extend a base listener) and override the `onTestFailure` method. Inside this method, I would cast the `WebDriver` instance to `TakesScreenshot`, call `getScreenshotAs(OutputType.FILE)`, save the resulting `File` object to a predefined directory, and then attach its path to the test report (e.g., using `extentTest.addScreenCaptureFromPath()` for ExtentReports). I'd ensure proper exception handling and unique file naming.

3.  **Q: What considerations are important for managing screenshot files, especially in a large project?**
    **A:** Key considerations include:
    *   **Storage:** Storing screenshots in a structured manner (e.g., by date, test name, or build number).
    *   **Retention Policy:** Implementing a policy to clean up old screenshots to manage disk space, especially in CI/CD environments.
    *   **Accessibility:** Ensuring screenshots are easily accessible from test reports (using relative paths) or a centralized storage if reports are distributed.
    *   **Uniqueness:** Generating unique filenames (e.g., with timestamps) to prevent overwriting.
    *   **Security/Privacy:** Be mindful of sensitive data appearing in screenshots in production-like environments; consider obfuscation or redacting sensitive areas if necessary.

## Hands-on Exercise
1.  **Set up Project:** Create a new Maven project and add the necessary Selenium, TestNG, and ExtentReports dependencies.
2.  **Implement `BaseTest`:** Create the `BaseTest` class as shown above, ensuring `setupExtentReports`, `setup`, `tearDown`, and `flushExtentReports` methods are correctly implemented.
3.  **Implement `ScreenshotUtil`:** Create the `ScreenshotUtil` class with the `captureScreenshot` method.
4.  **Create a Failing Test:** Write a simple Selenium test that intentionally fails (e.g., tries to find an element with a non-existent ID or asserts a false condition).
5.  **Run and Verify:** Execute the TestNG suite. After execution, open the generated `index.html` report. Verify that the failed test entry contains an attached screenshot, and clicking on it displays the image of the browser at the time of failure.
6.  **Experiment with Success:** Modify the failing test to pass and observe that no screenshot is attached for successful tests.

## Additional Resources
-   **Selenium WebDriver Documentation (TakesScreenshot):** [https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/TakesScreenshot.html](https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/TakesScreenshot.html)
-   **TestNG Listeners:** [https://testng.org/doc/documentation-main.html#testng-listeners](https://testng.org/doc/documentation-main.html#testng-listeners)
-   **ExtentReports Documentation:** [https://www.extentreports.com/docs/versions/5/java/index.html](https://www.extentreports.com/docs/versions/5/java/index.html)
-   **Maven Official Website:** [https://maven.apache.org/](https://maven.apache.org/)