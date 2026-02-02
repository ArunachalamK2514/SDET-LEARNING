
# Capturing Screenshots in Selenium

## Overview
Capturing screenshots during test automation is a critical capability for debugging, reporting, and providing visual evidence of test outcomes. When a test fails, a screenshot of the application's state at that moment is invaluable for quickly diagnosing the issue. Selenium provides built-in mechanisms to capture both the full visible page and screenshots of specific web elements. This feature is fundamental to any robust test automation framework.

## Detailed Explanation

Selenium's screenshot capabilities are primarily accessed through the `TakesScreenshot` interface. To use it, you cast your `WebDriver` instance to this interface. The core method is `getScreenshotAs()`, which can capture a screenshot and return it in different formats, most commonly as a file (`OutputType.FILE`).

### 1. Full Page Screenshot
This is the most common type of screenshot. It captures the entire visible area of the browser's viewport. If the page is scrollable, this will only capture the currently visible portion, not the entire logical page (unless you are using a browser-specific command, like in Firefox).

- **How it works:** You cast the `WebDriver` instance to `TakesScreenshot` and call `getScreenshotAs(OutputType.FILE)`. This returns a `File` object pointing to a temporary location. You then need to copy this file to a permanent location, typically a dedicated `screenshots` directory in your project, giving it a meaningful name (e.g., including the test name and a timestamp).

### 2. Element-Level Screenshot
Since Selenium 4, WebDriver has added the ability to take a screenshot of a single, specific `WebElement`. This is extremely useful for focusing on a particular area of the UI, such as a form, a specific button, or an image, without the noise of the full page.

- **How it works:** You first locate the `WebElement` you want to capture. Then, you simply call the `getScreenshotAs(OutputType.FILE)` method directly on the `WebElement` instance. Just like with a full page screenshot, this returns a `File` object that you must save to a permanent location.

A common use case for both is to integrate screenshot capture into a `TestListener` (e.g., in TestNG). When a test fails (`onTestFailure` event), the listener automatically captures a screenshot and saves it, linking it to the test report.

## Code Implementation
This runnable Java TestNG class demonstrates how to capture both full-page and element-level screenshots.

```java
import io.github.bonigarcia.wdm.WebDriverManager;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.ChromeDriver;
import org.testng.Assert;
import org.testng.ITestResult;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.SimpleDateFormat;
import java.util.Date;

public class ScreenshotTest {

    private WebDriver driver;
    private static final String SCREENSHOTS_DIR = "target/screenshots/";

    @BeforeMethod
    public void setUp() throws IOException {
        WebDriverManager.chromedriver().setup();
        driver = new ChromeDriver();
        driver.get("https://www.google.com");
        // Create the directory for screenshots if it doesn't exist
        Files.createDirectories(Paths.get(SCREENSHOTS_DIR));
    }

    @Test(description = "Capture a full page screenshot")
    public void testCaptureFullPageScreenshot() {
        try {
            // 1. Use TakesScreenshot interface
            TakesScreenshot ts = (TakesScreenshot) driver;

            // 2. Capture full page screenshot
            File sourceFile = ts.getScreenshotAs(OutputType.FILE);
            String timestamp = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss").format(new Date());
            Path destinationPath = Paths.get(SCREENSHOTS_DIR, "FullPage_" + timestamp + ".png");

            // 4. Save file to disk
            Files.copy(sourceFile.toPath(), destinationPath);
            System.out.println("Full page screenshot saved to: " + destinationPath);
            Assert.assertTrue(Files.exists(destinationPath), "Screenshot file should be created.");

        } catch (IOException e) {
            Assert.fail("Failed to capture or save screenshot", e);
        }
    }

    @Test(description = "Capture a screenshot of a specific web element")
    public void testCaptureElementScreenshot() {
        try {
            WebElement googleLogo = driver.findElement(By.cssSelector("img.lnXdpd"));

            // 3. Capture specific WebElement screenshot
            File sourceFile = googleLogo.getScreenshotAs(OutputType.FILE);
            String timestamp = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss").format(new Date());
            Path destinationPath = Paths.get(SCREENSHOTS_DIR, "Element_GoogleLogo_" + timestamp + ".png");

            // 4. Save file to disk
            Files.copy(sourceFile.toPath(), destinationPath);
            System.out.println("Element screenshot saved to: " + destinationPath);
            Assert.assertTrue(Files.exists(destinationPath), "Element screenshot file should be created.");

        } catch (IOException e) {
            Assert.fail("Failed to capture or save element screenshot", e);
        }
    }

    // This AfterMethod acts like a simple TestNG listener to take a screenshot on failure
    @AfterMethod
    public void tearDown(ITestResult result) {
        if (ITestResult.FAILURE == result.getStatus()) {
            System.out.println("Test failed, taking a screenshot...");
            TakesScreenshot ts = (TakesScreenshot) driver;
            File sourceFile = ts.getScreenshotAs(OutputType.FILE);
            String timestamp = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss").format(new Date());
            String screenshotName = result.getMethod().getMethodName() + "_" + timestamp + ".png";
            try {
                Path destinationPath = Paths.get(SCREENSHOTS_DIR, screenshotName);
                Files.copy(sourceFile.toPath(), destinationPath);
                System.out.println("Screenshot on failure saved to: " + destinationPath);
            } catch (IOException e) {
                System.err.println("Failed to save screenshot on failure: " + e.getMessage());
            }
        }
        if (driver != null) {
            driver.quit();
        }
    }
}
```

## Best Practices
- **Unique Naming:** Always save screenshots with unique names. A common pattern is `[TestClassName]_[TestMethodName]_[Timestamp].png`. This prevents files from being overwritten and makes them easy to trace.
- **Integrate with Listeners:** The best way to handle screenshots on failure is automatically. Use TestNG's `ITestListener` or JUnit's `TestWatcher` to trigger screenshot capture in the `onTestFailure` method.
- **Organize Screenshots:** Save screenshots in a dedicated, clearly named directory (e.g., `target/screenshots`). This directory should be cleaned before each test run to avoid accumulating old files.
- **Link in Reports:** If you use an advanced reporting library like ExtentReports or Allure, embed or link the screenshots directly in the test report. This creates a single, comprehensive source for test results.

## Common Pitfalls
- **IOException:** Failing to handle `IOException` is a common mistake. File I/O operations can fail (e.g., due to permissions issues), and this must be enclosed in a try-catch block.
- **Overwriting Files:** Using a static filename (e.g., `"screenshot.png"`) in a parallel test run will cause a race condition where tests overwrite each other's screenshots. Always generate unique filenames.
- **Incorrect Casting:** Forgetting to cast the `WebDriver` instance to `TakesScreenshot` will result in a compile-time error, as the `getScreenshotAs` method is not part of the `WebDriver` interface itself.

## Interview Questions & Answers
1. **Q:** How do you take a screenshot in Selenium when a test fails?
   **A:** The best approach is to implement a listener. In TestNG, you would create a class that implements `ITestListener`. Inside the `onTestFailure()` method, you cast the WebDriver instance to the `TakesScreenshot` interface and call the `getScreenshotAs()` method. This returns a file that you then copy to a designated screenshots folder with a unique name, typically including the failed test's name and a timestamp. Finally, you configure this listener in your `testng.xml` file to have it run automatically.

2. **Q:** What is the difference between taking a screenshot of the page versus an element? When would you prefer one over the other?
   **A:** A page-level screenshot captures the entire browser viewport, which is great for understanding the overall context of the UI at the time of failure. An element-level screenshot, a feature introduced in Selenium 4, captures only the image of a specific WebElement. I would prefer an element-level screenshot when I need to validate a specific component's appearance, such as a chart, a user profile card, or a specific error message, without the distraction of the rest of the page. It's also useful in visual regression testing to compare just one component.

3. **Q:** Your code to save a screenshot works on your local machine but fails in the CI/CD pipeline with a `FileNotFoundException`. What could be a possible cause?
   **A:** A common cause is an incorrect file path or directory permissions. The CI/CD environment might not have the same directory structure as a local machine. You should avoid hardcoding absolute paths. A better approach is to use a relative path like `"target/screenshots/"`, which is created within the project's workspace. Additionally, you should programmatically create the directory before saving the file (e.g., using `Files.createDirectories()`) to ensure it exists, as the CI agent might start with a clean workspace.

## Hands-on Exercise
1. **Setup:** Use the same Maven project from the previous exercises (with Selenium, TestNG, WebDriverManager).
2. **Create Test Class:** Create a new test class `ScreenshotPracticeTest`.
3. **Full Page Test:** Write a test that navigates to a website (e.g., `https://www.amazon.com`), takes a full-page screenshot, and saves it to a `target/screenshots` directory with a unique timestamped name.
4. **Element Test:** Write another test that navigates to the same site, locates a specific element (like the main search bar), and saves a screenshot of only that element.
5. **Failure Test:** Create a third test that is designed to fail (e.g., `Assert.fail("This test is meant to fail");`).
6. **Implement Listener:** Copy the `@AfterMethod` from the code example above into your test class. This method will check if a test failed and take a screenshot if it did.
7. **Run and Verify:** Run the test class. You should see three screenshots in your `target/screenshots` folder: one for the full page, one for the search bar element, and one from the failed test.

## Additional Resources
- [Selenium Documentation on Screenshots](https://www.selenium.dev/documentation/webdriver/browser/screenshots/)
- [Baeldung - A Guide to Taking Screenshots with Selenium](https://www.baeldung.com/java-selenium-screenshot)
- [TestNG Listeners Documentation](https://testng.org/doc/documentation-main.html#testng-listeners)
