# selenium-2.4-ac3: Window/tab switching
## Overview
In web automation, it's common for user actions to open new browser windows or tabs. Selenium WebDriver provides robust mechanisms to handle these scenarios using "window handles." A window handle is a unique identifier assigned by the browser to each open window or tab. This section will delve into how to effectively manage multiple browser windows/tabs, switch contexts between them, and perform actions, which is crucial for testing multi-window applications.

## Detailed Explanation
When Selenium WebDriver is launched, it typically starts with one primary window. Any subsequent actions that open new windows or tabs (e.g., clicking a link with `target="_blank"`, or JavaScript actions) will result in a new browsing context. To interact with elements in these new windows/tabs, Selenium WebDriver needs to explicitly "switch" its focus to them.

Each window/tab has a unique `window handle` (a string identifier). WebDriver maintains a set of all currently open window handles and knows which window it is currently focused on.

The primary methods for window handling are:
1.  `getWindowHandle()`: Returns the handle of the current window/tab.
2.  `getWindowHandles()`: Returns a `Set` of all currently open window/tab handles.
3.  `switchTo().window(windowHandle)`: Switches the WebDriver's focus to the window/tab identified by the given handle.
4.  `close()`: Closes the *current* window/tab.
5.  `quit()`: Closes *all* open windows/tabs and terminates the WebDriver session.

**Scenario**: Clicking a link opens a new tab. We need to perform an action on the new tab and then return to the original tab.

### Steps for Window/Tab Switching:
1.  **Get the handle of the parent/original window:** Store it to switch back later.
2.  **Perform an action that opens a new window/tab:** This could be a click event.
3.  **Get all window handles:** After the new window/tab opens, get the `Set<String>` of all available handles.
4.  **Iterate and switch to the new window/tab:** The new window's handle will be the one that is *not* the parent window's handle.
5.  **Perform actions on the new window/tab.**
6.  **Close the new window/tab (optional):** If it's no longer needed.
7.  **Switch back to the parent window/tab:** Use the stored parent window handle.

## Code Implementation
Here's a comprehensive Java example demonstrating window/tab switching. We'll use a local HTML file to simulate the scenario.

First, create an HTML file named `multiWindowTest.html` in your project root with the following content:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Parent Window</title>
</head>
<body>
    <h1>This is the Parent Window</h1>
    <a href="https://www.selenium.dev" target="_blank" id="newTabLink">Open Selenium Website in New Tab</a>
    <p>Current URL: <span id="currentUrl"></span></p>

    <script>
        document.getElementById('currentUrl').innerText = window.location.href;
    </script>
</body>
</html>
```

Now, the Java code:

```java
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.nio.file.Paths;
import java.time.Duration;
import java.util.Iterator;
import java.util.Set;

import static org.testng.Assert.assertTrue;
import static org.testng.Assert.fail;

public class WindowTabSwitchingTest {

    private WebDriver driver;
    private WebDriverWait wait;

    @BeforeMethod
    public void setUp() {
        // Setup ChromeDriver - Selenium Manager handles driver binaries
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--start-maximized");
        // For headless execution, uncomment the line below:
        // options.addArguments("--headless");
        driver = new ChromeDriver(options);
        wait = new WebDriverWait(driver, Duration.ofSeconds(10));
    }

    @Test
    public void testWindowAndTabSwitching() {
        // Path to your local HTML file
        String filePath = Paths.get("multiWindowTest.html").toAbsolutePath().toString();
        String parentWindowUrl = "file:///" + filePath.replace("\", "/");

        System.out.println("Navigating to parent window URL: " + parentWindowUrl);
        driver.get(parentWindowUrl);
        String parentWindowHandle = driver.getWindowHandle();
        System.out.println("Parent Window Handle: " + parentWindowHandle);
        System.out.println("Parent Window Title: " + driver.getTitle());
        assertTrue(driver.getTitle().contains("Parent Window"), "Failed to load parent window.");

        // Click the link that opens a new tab
        WebElement newTabLink = driver.findElement(By.id("newTabLink"));
        newTabLink.click();
        System.out.println("Clicked on 'Open Selenium Website in New Tab' link.");

        // Wait for the new window/tab to open
        wait.until(ExpectedConditions.numberOfWindowsToBe(2));

        Set<String> windowHandles = driver.getWindowHandles();
        System.out.println("All Window Handles: " + windowHandles);

        Iterator<String> iterator = windowHandles.iterator();
        String currentHandle;
        boolean switchedToNewTab = false;

        while (iterator.hasNext()) {
            currentHandle = iterator.next();
            if (!parentWindowHandle.equals(currentHandle)) {
                driver.switchTo().window(currentHandle);
                System.out.println("Switched to New Tab with Handle: " + currentHandle);
                wait.until(ExpectedConditions.urlContains("selenium.dev")); // Wait for new tab content to load
                System.out.println("New Tab Title: " + driver.getTitle());
                System.out.println("New Tab URL: " + driver.getCurrentUrl());
                assertTrue(driver.getTitle().contains("Selenium"), "New tab did not load Selenium website.");
                switchedToNewTab = true;
                break; // Exit loop once new tab is found and switched
            }
        }

        if (!switchedToNewTab) {
            fail("Failed to switch to the new tab.");
        }

        // Perform an action on the new tab (e.g., verify a navigation link)
        WebElement downloadsLink = driver.findElement(By.linkText("Downloads"));
        downloadsLink.click();
        wait.until(ExpectedConditions.urlContains("downloads"));
        System.out.println("Navigated to Downloads page in new tab.");
        assertTrue(driver.getCurrentUrl().contains("downloads"), "Failed to navigate to downloads page.");

        // Close the new tab
        driver.close();
        System.out.println("Closed the new tab.");

        // Switch back to the parent window
        driver.switchTo().window(parentWindowHandle);
        System.out.println("Switched back to Parent Window with Handle: " + parentWindowHandle);
        System.out.println("Parent Window Title after switch: " + driver.getTitle());
        assertTrue(driver.getTitle().contains("Parent Window"), "Failed to switch back to parent window.");

        // Verify we are indeed on the parent window by interacting with an element
        WebElement currentUrlSpan = driver.findElement(By.id("currentUrl"));
        assertTrue(currentUrlSpan.getText().contains("multiWindowTest.html"), "Parent window content is not as expected.");
        System.out.println("Successfully verified parent window content.");
    }

    @AfterMethod
    public void tearDown() {
        if (driver != null) {
            driver.quit(); // Closes all windows and ends the WebDriver session
        }
    }
}
```

## Best Practices
-   **Always store the parent window handle:** This allows you to easily switch back to the original context.
-   **Use `WebDriverWait` for `numberOfWindowsToBe`:** Do not assume the new window/tab opens instantly. Wait for the expected number of windows to appear before attempting to switch.
-   **Iterate through window handles:** The order of handles in the `Set` is not guaranteed, so always iterate to find the new handle.
-   **Close child windows/tabs:** If a new window/tab is opened for a temporary action, close it using `driver.close()` once operations are complete to save resources and prevent memory leaks.
-   **Use `driver.quit()` in `tearDown()`:** This ensures all browser windows opened during the test session are closed, not just the currently focused one.
-   **Handle `NoSuchWindowException`:** Implement error handling if a window handle becomes invalid (e.g., if the window was unexpectedly closed).

## Common Pitfalls
-   **Not waiting for the new window to open:** Trying to get window handles or switch too soon can lead to `NoSuchWindowException` or not finding the new window.
-   **Not switching back to the parent window:** After interacting with a new window/tab, forgetting to switch back will cause subsequent actions intended for the parent window to fail.
-   **Using `driver.close()` on the last window:** If you use `driver.close()` on the only remaining window, the WebDriver session becomes invalid, leading to a `NoSuchSessionException` for subsequent commands. Always use `driver.quit()` in your `tearDown` or after completing all tests to gracefully end the session.
-   **Order of window handles:** Assuming the new window handle will always be the last one in the `Set`. The order is not guaranteed.
-   **Misidentifying the new window:** Accidentally switching back to the original window or to another existing window if the logic for identifying the "new" window is flawed.

## Interview Questions & Answers
1.  **Q: How do you handle multiple browser windows or tabs in Selenium WebDriver?**
    A: We handle multiple browser windows/tabs using window handles. First, we get the handle of the parent window using `driver.getWindowHandle()`. Then, after an action opens a new window/tab, we retrieve all open window handles using `driver.getWindowHandles()`, which returns a `Set<String>`. We iterate through this set to identify the new window (the handle not matching the parent). We use `driver.switchTo().window(newWindowHandle)` to switch focus, perform actions, and then use `driver.switchTo().window(parentWindowHandle)` to return to the original window. It's good practice to close the child window if it's no longer needed.

2.  **Q: What is the difference between `driver.close()` and `driver.quit()`?**
    A: `driver.close()` closes the browser window or tab that is currently in focus by the WebDriver instance. If it's the last open window, the session remains active but unusable. `driver.quit()`, on the other hand, closes *all* windows/tabs opened by the WebDriver session and then terminates the WebDriver session itself, releasing all associated resources. `driver.quit()` should always be called in the test teardown to prevent memory leaks and ensure clean session termination.

3.  **Q: What common issues might you face when dealing with multiple windows/tabs, and how do you resolve them?**
    A: Common issues include `NoSuchWindowException` if trying to interact with a window that WebDriver isn't focused on, or if the window hasn't fully opened yet. This can be resolved by using `WebDriverWait` with `ExpectedConditions.numberOfWindowsToBe()` to ensure the new window is present before attempting to switch. Another issue is forgetting to switch back to the original window, causing subsequent tests to fail on the wrong context. Always store the parent window handle and switch back explicitly. Finally, `StaleElementReferenceException` can occur if you try to interact with an element from a window you've switched away from and then back to, especially if the page reloaded. Re-locating elements can help in such cases.

## Hands-on Exercise
1.  **Scenario:** Navigate to a website that has a "Contact Us" link that opens in a new tab/window (e.g., a sample banking site or an e-commerce site's help section).
2.  **Task:**
    *   Open the main website.
    *   Click on the "Contact Us" or equivalent link.
    *   Switch to the newly opened tab/window.
    *   Verify the title or a specific text/element on the new page.
    *   If there's a form, fill in a dummy name and email (do not submit).
    *   Close the new tab/window.
    *   Switch back to the original window.
    *   Verify you are back on the main website.

## Additional Resources
-   **Selenium Official Documentation - Window Handling:** [https://www.selenium.dev/documentation/webdriver/browser/windows/](https://www.selenium.dev/documentation/webdriver/browser/windows/)
-   **TutorialsPoint - Selenium Window Handling:** [https://www.tutorialspoint.com/selenium/selenium_window_handling.htm](https://www.tutorialspoint.com/selenium/selenium_window_handling.htm)
-   **Guru99 - Handle Multiple Windows in Selenium WebDriver:** [https://www.guru99.com/handle-multiple-windows-selenium-webdriver.html](https://www.guru99.com/handle-multiple-windows-selenium-webdriver.html)
