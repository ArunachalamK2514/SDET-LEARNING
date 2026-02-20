# selenium-2.4-ac1.md

# selenium-2.4-ac1: JavaScriptExecutor Techniques

## Overview

In Selenium WebDriver, there are limitations to what can be automated through the standard API. Some user interactions or browser manipulations, like scrolling to a specific element, clicking an element that is obscured by another, or visually highlighting an element for debugging, are not directly supported. This is where `JavaScriptExecutor` comes in. It provides a mechanism to execute JavaScript directly within the context of the currently selected frame or window, unlocking a powerful set of capabilities to handle complex scenarios.

For a Senior SDET, mastering `JavaScriptExecutor` is crucial. It demonstrates an understanding of WebDriver's limitations and the ability to find robust workarounds, moving beyond basic API calls to solve real-world automation challenges.

## Detailed Explanation

The `JavaScriptExecutor` is an interface that allows you to execute synchronous and asynchronous JavaScript code. To use it, you must cast your `WebDriver` instance to `JavaScriptExecutor`.

```java
// Casting the driver instance
JavaScriptExecutor js = (JavaScriptExecutor) driver;
```

Once cast, you have access to two primary methods:
1.  **`executeScript(String script, Object... args)`**: Executes JavaScript in the current window/frame. It's a synchronous call, meaning Selenium will wait for the script to finish before proceeding.
2.  **`executeAsyncScript(String script, Object... args)`**: Executes an asynchronous piece of JavaScript. This is less common in day-to-day testing but useful for scenarios involving `setTimeout` or AJAX calls where you need to explicitly signal completion.

The `arguments` array in your JavaScript code corresponds to the `args` you pass to the method. For example, `arguments[0]` refers to the first argument passed after the script string. This is how you can pass `WebElement` objects from your Java code into your JavaScript code.

### Core Use Cases:

1.  **Scrolling**: This is the most common use case.
    *   **Scroll to a specific element**: Brings an element into the browser's viewport. Essential for interacting with elements that are only loaded or enabled when visible.
    *   **Scroll by a specific amount**: Scrolls the page down or up by a pixel value. Useful for triggering "infinite scroll" functionalities.
    *   **Scroll to the bottom/top of the page**: Useful for verifying footers or headers.

2.  **Force Clicking**: Sometimes, an element is present in the DOM but cannot be clicked by WebDriver's `.click()` method. This can happen if it's visually covered by another element (like a sticky header or a pop-up), or if it's not considered "interactable" by the WebDriver API for other reasons. A JavaScript click often bypasses these checks.

3.  **Element Highlighting**: During debugging or in test execution recordings, it can be extremely helpful to visually highlight the element the script is currently interacting with. This is achieved by dynamically changing the element's CSS properties (e.g., its border).

4.  **Interacting with Hidden Elements**: You can use JavaScript to modify the attributes of an element, such as changing `display: none` to `display: block`, making it visible for further interaction.

## Code Implementation

Below is a complete, runnable example demonstrating the key `JavaScriptExecutor` techniques.

```java
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

public class JavaScriptExecutorDemo {

    public static void main(String[] args) throws InterruptedException {
        // Ensure you have chromedriver.exe in your PATH
        // Or set the system property: System.setProperty("webdriver.chrome.driver", "path/to/chromedriver.exe");
        WebDriver driver = new ChromeDriver();
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
        JavascriptExecutor js = (JavascriptExecutor) driver;

        try {
            // Navigate to a demo page
            driver.get("https://www.automationtesting.co.uk/contactForm.html");
            driver.manage().window().maximize();

            // --- 1. Scrolling ---
            System.out.println("--- Demonstrating Scrolling ---");

            // Scroll to the bottom of the page
            js.executeScript("window.scrollTo(0, document.body.scrollHeight)");
            System.out.println("Scrolled to the bottom of the page.");
            Thread.sleep(2000); // Pause to observe

            // Scroll back to the top
            js.executeScript("window.scrollTo(0, 0)");
            System.out.println("Scrolled back to the top.");
            Thread.sleep(2000); // Pause to observe

            // Scroll a specific element into view
            WebElement submitButton = wait.until(ExpectedConditions.presenceOfElementLocated(By.cssSelector("input[type='submit']")));
            js.executeScript("arguments[0].scrollIntoView(true);", submitButton);
            System.out.println("Scrolled the 'Submit' button into view.");
            Thread.sleep(2000); // Pause to observe

            // --- 2. Element Highlighting ---
            System.out.println("\n--- Demonstrating Element Highlighting ---");
            highlightElement(driver, submitButton);
            System.out.println("Highlighted the 'Submit' button.");
            Thread.sleep(2000); // Pause to observe

            // --- 3. Force Clicking ---
            System.out.println("\n--- Demonstrating Force Click ---");
            // In this form, a standard click works fine, but we'll use a JS click to demonstrate.
            // This is most useful when an element is covered by another.
            WebElement firstNameInput = driver.findElement(By.name("first_name"));
            highlightElement(driver, firstNameInput);
            firstNameInput.sendKeys("John (before click)"); // Standard interaction

            WebElement resetButton = driver.findElement(By.cssSelector("input[type='reset']"));
            highlightElement(driver, resetButton);
            Thread.sleep(1000);

            // Use JavaScript to click the reset button
            js.executeScript("arguments[0].click();", resetButton);
            System.out.println("Clicked the 'Reset' button using JavaScript.");
            Thread.sleep(2000); // Pause to observe

            // Verify the form was reset
            if (firstNameInput.getAttribute("value").isEmpty()) {
                System.out.println("Force click successful: Form was reset.");
            } else {
                System.out.println("Force click failed: Form was not reset.");
            }

        } finally {
            if (driver != null) {
                driver.quit();
            }
        }
    }

    /**
     * Highlights a WebElement by changing its border style.
     *
     * @param driver  The WebDriver instance.
     * @param element The WebElement to highlight.
     */
    public static void highlightElement(WebDriver driver, WebElement element) {
        if (!(driver instanceof JavascriptExecutor)) {
            throw new IllegalArgumentException("Driver does not support JavascriptExecutor.");
        }
        JavascriptExecutor js = (JavascriptExecutor) driver;
        String originalStyle = element.getAttribute("style");
        // Apply a distinct border
        js.executeScript("arguments[0].setAttribute('style', 'border: 4px solid red; background: yellow;');", element);

        // It's good practice to revert the style after a short delay,
        // but for this demo, we leave it highlighted to observe.
        // In a real framework, you might do this:
        // try { Thread.sleep(300); } catch (InterruptedException e) {}
        // js.executeScript("arguments[0].setAttribute('style', arguments[1]);", element, originalStyle);
    }
}
```

## Best Practices

-   **Use It as a Last Resort**: Always prefer native Selenium interactions (`element.click()`, `element.sendKeys()`) first. They simulate real user behavior more accurately. Use `JavaScriptExecutor` only when the native methods fail.
-   **Create a Utility Class**: Encapsulate JavaScript calls into a helper class (e.g., `JavaScriptHelper.java`). This improves readability and reusability. Methods like `scrollToElement()`, `forceClick()`, and `highlight()` are great candidates.
-   **Parameterize Scripts**: Pass WebElements and other values into your scripts using the `arguments` array. Avoid hardcoding element locators directly into the JavaScript string, as this makes maintenance very difficult.
-   **Error Handling**: Wrap `JavaScriptExecutor` calls in try-catch blocks if they are critical and could fail, though most script errors will throw a `JavascriptException`.

## Common Pitfalls

-   **Overusing Force Clicks**: Relying on JavaScript clicks can hide real bugs in the application's UI. If an element isn't clickable for a real user, it's a bug. A JS click will pass the test but miss the defect.
-   **Forgetting `arguments[0]`**: A common mistake is forgetting to reference the passed WebElement in the script. `js.executeScript("scrollIntoView(true);", element)` does nothing because the script doesn't know what to scroll to. It must be `arguments[0].scrollIntoView(true);`.
-   **Synchronization Issues**: `executeScript` is synchronous, but the *effects* of the JavaScript might not be instantaneous. For example, after scrolling an element into view, an animation might play. You still need to use an `ExplicitWait` to ensure the element is `elementToBeClickable` before interacting with it.

## Interview Questions & Answers

1.  **Q:** When would you use `JavaScriptExecutor` in your Selenium framework?
    **A:** I use `JavaScriptExecutor` as a workaround when standard WebDriver methods are insufficient. The most common scenarios are:
    1.  **Scrolling**: To bring an element into the viewport before interacting with it, especially with lazy-loading pages.
    2.  **Handling Obscured Elements**: When an element is covered by a sticky header or a banner, `element.click()` fails. `JavaScriptExecutor` can force a click that bypasses the visibility check.
    3.  **Complex Interactions**: For actions like triggering a "mouseover" event that WebDriver's `Actions` class can't handle, or interacting with disabled elements for specific test conditions.
    4.  **Debugging**: I have a helper method that uses JavaScript to draw a red border around the current element of interaction, which is invaluable when debugging failing tests on a CI server via video recordings.

2.  **Q:** What is the difference between `element.click()` and using `JavaScriptExecutor` to click?
    **A:** `element.click()` simulates a real user click. It scrolls the element into view and triggers the click event only if the element is visible and interactable. It respects the browser's security model and event simulation. A `JavaScriptExecutor` click, using `arguments[0].click()`, is a programmatic event trigger. It doesn't require the element to be visible or in the viewport. It's more powerful but less realistic. I prefer `element.click()` for its accuracy in simulating user behavior and only use the JavaScript click to bypass specific obstacles when necessary.

3.  **Q:** How would you handle a `StaleElementReferenceException` when using `JavaScriptExecutor`?
    **A:** A `StaleElementReferenceException` can still occur because the `WebElement` object passed to `executeScript` can become stale if the DOM changes. The solution is the same as with any other interaction: catch the exception, re-locate the element to get a fresh reference, and then retry the `JavaScriptExecutor` command within a loop or a framework utility.

## Hands-on Exercise

1.  **Setup**: Create a new Java class.
2.  **Target**: Go to a content-heavy news website like `https://www.bbc.com` or any e-commerce site with a long scrollable page.
3.  **Task 1 (Scroll & Highlight)**:
    *   Find the "footer" element of the page.
    *   Use `JavaScriptExecutor` to scroll this footer into view.
    *   Once in view, use `JavaScriptExecutor` to highlight the footer with a bright yellow background and a thick red border.
    *   Take a screenshot to verify the result.
4.  **Task 2 (Get Attribute)**:
    *   Find the main logo at the top of the page.
    *   Use `JavaScriptExecutor` to retrieve its `alt` text or `href` attribute using `return arguments[0].getAttribute('alt');` and print it to the console.

## Additional Resources

-   [Selenium Documentation on JavaScriptExecutor](https://www.selenium.dev/documentation/webdriver/actions_api/javascript/)
-   [Ultimate Guide to JavaScriptExecutor in Selenium (Guru99)](https://www.guru99.com/execute-javascript-selenium-webdriver.html)
-   [Baeldung: A Guide to JavaScriptExecutor](https://www.baeldung.com/selenium-javascript-executor)
---
# selenium-2.4-ac2.md

# selenium-2.4-ac2: Handle Alerts, Prompts, Confirmations Using Alert Interface

## Overview
Web applications often use JavaScript alert boxes, confirmation dialogs, and prompt boxes to interact with users. These are non-HTML pop-ups generated by the browser, and Selenium's standard `findElement()` methods cannot interact with them directly. WebDriver provides a dedicated `Alert` interface to manage these pop-up windows. Understanding how to handle them is crucial for automating real-world web scenarios, especially during negative testing or when critical information is displayed.

## Detailed Explanation
The `Alert` interface in Selenium WebDriver provides methods to interact with the three types of JavaScript pop-up boxes:
1.  **Alert Box**: Displays a message and an "OK" button. Used for notifications.
2.  **Confirmation Box**: Displays a message, an "OK" button, and a "Cancel" button. Used to get user confirmation.
3.  **Prompt Box**: Displays a message, an input field, and "OK" / "Cancel" buttons. Used to get input from the user.

To interact with any of these, you must first switch control of the WebDriver to the alert box using `driver.switchTo().alert()`. Once switched, you can use the methods provided by the `Alert` interface.

### Key `Alert` Interface Methods:
-   `accept()`: Clicks on the "OK" (or "Accept") button of the alert, confirmation, or prompt box.
-   `dismiss()`: Clicks on the "Cancel" (or "Dismiss") button of the alert, confirmation, or prompt box. If it's an alert box, it will still close it, as there's no "Cancel" option.
-   `getText()`: Retrieves the message displayed in the alert, confirmation, or prompt box.
-   `sendKeys(String keysToSend)`: Enters text into the input field of a prompt box.

**Important Note**: Once you interact with an alert (e.g., `accept()` or `dismiss()`), the alert is closed, and WebDriver control automatically returns to the main page. If you try to interact with an alert that is no longer present, it will throw a `NoAlertPresentException`.

## Code Implementation
Let's create a simple HTML file to demonstrate alert handling and then write Java Selenium code for it.

**`xpath_axes_test_page.html`** (Assuming this file is in your project root or accessible path):
(This is a generic name, you might already have this file, if not, create it. I am using the existing `xpath_axes_test_page.html` as it was listed in the folder structure, but I will assume its content for demonstration.)

```html
<!DOCTYPE html>
<html>
<head>
    <title>Alerts, Prompts, Confirmations Test Page</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        button { padding: 10px 15px; margin: 5px; cursor: pointer; }
    </style>
</head>
<body>
    <h1>JavaScript Dialog Boxes</h1>

    <button onclick="showAlert()">Show Alert</button>
    <button onclick="showConfirm()">Show Confirm</button>
    <button onclick="showPrompt()">Show Prompt</button>

    <p id="output"></p>

    <script>
        function showAlert() {
            alert("This is a simple alert box!");
        }

        function showConfirm() {
            let result = confirm("Do you want to proceed?");
            document.getElementById("output").textContent = "Confirmation Result: " + result;
        }

        function showPrompt() {
            let name = prompt("Please enter your name:", "Guest");
            if (name !== null) {
                document.getElementById("output").textContent = "Hello, " + name + "!";
            } else {
                document.getElementById("output").textContent = "Prompt cancelled.";
            }
        }
    </script>
</body>
</html>
```

**Java Selenium Code:**

```java
import org.openqa.selenium.Alert;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.time.Duration;

public class AlertHandlingTests {

    private WebDriver driver;
    private WebDriverWait wait; // For explicit waits

    @BeforeMethod
    public void setUp() {
        // Automatically manages ChromeDriver executable (Selenium 4.6+)
        // System.setProperty("webdriver.chrome.driver", "path/to/chromedriver"); // Not needed with WebDriverManager or Selenium Manager
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--start-maximized");
        driver = new ChromeDriver(options);
        wait = new WebDriverWait(driver, Duration.ofSeconds(10)); // Initialize WebDriverWait

        // Assuming the HTML file is in the project root. Adjust path as needed.
        String htmlFilePath = System.getProperty("user.dir") + "/xpath_axes_test_page.html";
        driver.get("file:///" + htmlFilePath.replace("\", "/"));
    }

    @Test
    public void testAlertBox() {
        WebElement showAlertButton = driver.findElement(By.xpath("//button[text()='Show Alert']"));
        showAlertButton.click();

        // Wait for the alert to be present
        Alert alert = wait.until(ExpectedConditions.alertIsPresent());

        // Get the text from the alert
        String alertText = alert.getText();
        System.out.println("Alert Box Text: " + alertText);
        Assert.assertEquals(alertText, "This is a simple alert box!", "Alert text mismatch!");

        // Accept the alert (clicks OK)
        alert.accept();

        // Verify the alert is no longer present (optional, but good practice)
        // If an alert is not handled, subsequent interactions with the page will fail.
        try {
            driver.switchTo().alert();
            Assert.fail("Alert was still present after accepting.");
        } catch (org.openqa.selenium.NoAlertPresentException e) {
            System.out.println("Alert successfully handled.");
        }
    }

    @Test
    public void testConfirmationBoxAccept() {
        WebElement showConfirmButton = driver.findElement(By.xpath("//button[text()='Show Confirm']"));
        showConfirmButton.click();

        Alert confirmation = wait.until(ExpectedConditions.alertIsPresent());

        String confirmationText = confirmation.getText();
        System.out.println("Confirmation Box Text: " + confirmationText);
        Assert.assertEquals(confirmationText, "Do you want to proceed?", "Confirmation text mismatch!");

        confirmation.accept(); // Clicks OK

        // Verify the result on the page
        WebElement output = driver.findElement(By.id("output"));
        wait.until(ExpectedConditions.textToBePresentInElement(output, "Confirmation Result: true"));
        Assert.assertTrue(output.getText().contains("Confirmation Result: true"), "Confirmation accept failed!");
    }

    @Test
    public void testConfirmationBoxDismiss() {
        WebElement showConfirmButton = driver.findElement(By.xpath("//button[text()='Show Confirm']"));
        showConfirmButton.click();

        Alert confirmation = wait.until(ExpectedConditions.alertIsPresent());

        String confirmationText = confirmation.getText();
        System.out.println("Confirmation Box Text: " + confirmationText);
        Assert.assertEquals(confirmationText, "Do you want to proceed?", "Confirmation text mismatch!");

        confirmation.dismiss(); // Clicks Cancel

        // Verify the result on the page
        WebElement output = driver.findElement(By.id("output"));
        wait.until(ExpectedConditions.textToBePresentInElement(output, "Confirmation Result: false"));
        Assert.assertTrue(output.getText().contains("Confirmation Result: false"), "Confirmation dismiss failed!");
    }

    @Test
    public void testPromptBox() {
        WebElement showPromptButton = driver.findElement(By.xpath("//button[text()='Show Prompt']"));
        showPromptButton.click();

        Alert prompt = wait.until(ExpectedConditions.alertIsPresent());

        String promptText = prompt.getText();
        System.out.println("Prompt Box Text: " + promptText);
        Assert.assertEquals(promptText, "Please enter your name:", "Prompt text mismatch!");

        String nameToEnter = "SDET Learner";
        prompt.sendKeys(nameToEnter); // Enters text into the prompt input field
        prompt.accept(); // Clicks OK

        // Verify the result on the page
        WebElement output = driver.findElement(By.id("output"));
        wait.until(ExpectedConditions.textToBePresentInElement(output, "Hello, SDET Learner!"));
        Assert.assertTrue(output.getText().contains("Hello, " + nameToEnter + "!"), "Prompt input and accept failed!");
    }

    @Test
    public void testPromptBoxDismiss() {
        WebElement showPromptButton = driver.findElement(By.xpath("//button[text()='Show Prompt']"));
        showPromptButton.click();

        Alert prompt = wait.until(ExpectedConditions.alertIsPresent());

        String promptText = prompt.getText();
        System.out.println("Prompt Box Text: " + promptText);
        Assert.assertEquals(promptText, "Please enter your name:", "Prompt text mismatch!");

        prompt.dismiss(); // Clicks Cancel

        // Verify the result on the page
        WebElement output = driver.findElement(By.id("output"));
        wait.until(ExpectedConditions.textToBePresentInElement(output, "Prompt cancelled."));
        Assert.assertTrue(output.getText().contains("Prompt cancelled."), "Prompt dismiss failed!");
    }

    @AfterMethod
    public void tearDown() {
        if (driver != null) {
            driver.quit();
        }
    }
}
```

## Best Practices
-   **Always use Explicit Waits**: Never rely on `Thread.sleep()` or try to interact with an alert without ensuring it's present. Use `WebDriverWait` with `ExpectedConditions.alertIsPresent()`.
-   **Handle alerts promptly**: Once an alert appears, the WebDriver's focus is on it, and you cannot interact with the main page until the alert is dismissed.
-   **Error Handling**: Wrap alert interactions in a `try-catch` block for `NoAlertPresentException` if there's a chance an alert might not appear (e.g., for optional notifications), to prevent test failures.
-   **Logging**: Log the text of the alert before accepting or dismissing it, especially in case of test failures, to understand the context.

## Common Pitfalls
-   **`NoAlertPresentException`**: This occurs if you try to switch to an alert when none is present. Often due to timing issues (alert not yet appeared) or incorrect test logic (alert already dismissed).
-   **Not switching back**: While WebDriver automatically switches focus back to the main page after an alert is handled, a common misconception is needing to explicitly switch back. The pitfall is often related to the test logic after handling the alert assuming the main page is ready immediately, potentially leading to `StaleElementReferenceException` or `NoSuchElementException` if not using proper waits for page elements.
-   **Ignoring alert text**: Failing to capture and assert the text of an alert can lead to missed issues where the alert appears, but with an unexpected message.
-   **Trying to locate elements on the main page while an alert is open**: This will always fail and result in `UnhandledAlertException`. Always handle the alert first.

## Interview Questions & Answers
1.  **Q: How do you handle JavaScript pop-ups (alerts, confirmations, prompts) in Selenium WebDriver?**
    A: I use the `driver.switchTo().alert()` method, which returns an `Alert` interface object. This object provides methods like `accept()` to click "OK", `dismiss()` to click "Cancel", `getText()` to retrieve the message, and `sendKeys()` to type into a prompt box. It's crucial to use `WebDriverWait` with `ExpectedConditions.alertIsPresent()` to ensure the alert has appeared before attempting to interact with it, to avoid `NoAlertPresentException`.

2.  **Q: What is `NoAlertPresentException` and when does it occur? How do you prevent it?**
    A: `NoAlertPresentException` occurs when WebDriver attempts to switch to an alert or interact with it, but no alert is currently displayed on the page. This typically happens due to timing issues, where the alert hasn't loaded yet, or if the alert was already dismissed by a previous action. To prevent it, I always use `WebDriverWait` with `ExpectedConditions.alertIsPresent()` before calling `driver.switchTo().alert()`.

3.  **Q: Can you interact with elements on the main web page while a JavaScript alert is open?**
    A: No, you cannot. When a JavaScript alert, confirmation, or prompt box is open, it takes control of the browser. WebDriver's focus shifts to this dialog, and any attempt to interact with elements on the underlying web page will result in an `UnhandledAlertException`. You must first handle (accept or dismiss) the alert before regaining control of the main page.

4.  **Q: What is the difference between `accept()` and `dismiss()` methods of the `Alert` interface?**
    A: The `accept()` method is used to click the "OK" or "Accept" button on an alert, confirmation, or prompt box. The `dismiss()` method is used to click the "Cancel" or "Dismiss" button on a confirmation or prompt box. For a standard alert box (which only has an "OK" button), calling `dismiss()` will also close the alert, effectively acting like `accept()`.

## Hands-on Exercise
1.  **Objective**: Navigate to a page with dynamic alerts and handle them.
2.  **Setup**:
    *   Find a public website that generates different types of JavaScript alerts (e.g., a "Try it" button for `alert()`, `confirm()`, `prompt()`). A good example can be found on W3Schools or similar tutorial sites.
    *   Ensure you have your Selenium WebDriver setup correctly with TestNG.
3.  **Task**:
    *   Write a TestNG test method for each type of alert:
        *   **Alert**: Click a button that triggers an alert. Get its text and assert it. Then accept the alert.
        *   **Confirmation**: Click a button that triggers a confirmation. Get its text, assert it, and then dismiss the confirmation. Verify the text on the page reflects the "cancel" action.
        *   **Prompt**: Click a button that triggers a prompt. Get its text, assert it, send your name into the prompt, and then accept it. Verify your name appears on the page.
    *   Include `WebDriverWait` for `ExpectedConditions.alertIsPresent()` in all your tests.
    *   Add `try-catch` blocks for `NoAlertPresentException` around your alert handling logic to make it robust.

## Additional Resources
-   **Selenium Official Documentation - Alerts**: [https://www.selenium.dev/documentation/webdriver/interactions/alerts/](https://www.selenium.dev/documentation/webdriver/interactions/alerts/)
-   **W3Schools JavaScript Popups**: [https://www.w3schools.com/js/js_popup.asp](https://www.w3schools.com/js/js_popup.asp)
-   **TutorialsPoint - Selenium Alert Handling**: [https://www.tutorialspoint.com/selenium/selenium_alert_commands.htm](https://www.tutorialspoint.com/selenium/selenium_alert_commands.htm)
---
# selenium-2.4-ac3.md

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
---
# selenium-2.4-ac4.md

# Handling IFrames in Selenium

## Overview
Web pages often use `<iframe>` (inline frame) elements to embed external content, such as maps, videos, ads, or even parts of the same application, into a parent HTML document. From Selenium's perspective, an IFrame is a separate document context. The main page and each IFrame have their own DOM tree.

To interact with elements inside an IFrame, you must explicitly switch the WebDriver's context from the main page to the desired frame. Forgetting to switch context is a common source of `NoSuchElementException`, as Selenium cannot find elements within an IFrame from the top-level document. This topic is crucial for automating modern web applications.

## Detailed Explanation
The `WebDriver.TargetLocator` interface, accessed via `driver.switchTo()`, provides the necessary methods to manage context switching. You can switch to a frame in three primary ways: by its index, by its name or ID, or by a previously located `WebElement` representing the frame. After performing actions within the frame, you must switch back to the main document context to interact with elements outside of it.

### Switching Mechanisms:
1.  **By Index (`int index`)**: IFrames on a page are indexed starting from 0, based on their order in the HTML. This is a simple but brittle method, as any change in the page structure can alter the frame's index.
2.  **By Name or ID (`String nameOrId`)**: This is the most common and recommended approach. If a frame has a `name` or `id` attribute, you can use that string to switch to it. It's more stable than switching by index because it's not dependent on the frame's position.
3.  **By WebElement (`WebElement frameElement`)**: You can first locate the `<iframe>` element using any locator strategy (e.g., `By.tagName("iframe")`, `By.cssSelector("iframe[title='...']")`) and then pass the resulting `WebElement` to the `frame()` method. This is useful for frames without a stable name or ID.

### Switching Back to the Main Content:
-   `driver.switchTo().defaultContent()`: This method always switches the context back to the top-level document, regardless of how many nested frames you have navigated.
-   `driver.switchTo().parentFrame()`: This method switches the context to the parent frame of the currently selected frame. If you are in a top-level frame, it switches back to the main document.

## Code Implementation
This example uses a local HTML file (`xpath_axes_test_page.html`) that contains two IFrames. It demonstrates switching into the frames using different methods, interacting with elements, and switching back.

**Setup:** Ensure `xpath_axes_test_page.html` is in your project's root directory.

```java
import io.github.bonigarcia.wdm.WebDriverManager;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;
import java.nio.file.Paths;
import java.time.Duration;

public class IFrameHandlingTest {

    private WebDriver driver;

    @BeforeMethod
    public void setUp() {
        WebDriverManager.chromedriver().setup();
        driver = new ChromeDriver();
        driver.manage().window().maximize();
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(10));
        
        // Get the absolute path to the HTML file
        String filePath = Paths.get("xpath_axes_test_page.html").toUri().toString();
        driver.get(filePath);
    }

    @Test(description = "Demonstrates switching to an IFrame by its name or ID.")
    public void testSwitchToFrameByNameOrId() {
        // The main page h1 is visible before switching
        Assert.assertTrue(driver.findElement(By.id("main-title")).isDisplayed());
        System.out.println("Successfully found main page title before switching.");

        // Switch to the first IFrame using its ID "frame1"
        driver.switchTo().frame("frame1");
        System.out.println("Switched to IFrame with ID 'frame1'.");

        // Interact with an element inside the IFrame
        WebElement frameInput = driver.findElement(By.id("iframe-input-1"));
        frameInput.sendKeys("Hello from the test!");
        Assert.assertEquals(frameInput.getAttribute("value"), "Hello from the test!");
        System.out.println("Successfully interacted with input inside IFrame 1.");

        // Switch back to the main document
        driver.switchTo().defaultContent();
        System.out.println("Switched back to the default content.");

        // Verify we can interact with main page elements again
        Assert.assertTrue(driver.findElement(By.id("contact-form")).isDisplayed());
        System.out.println("Successfully found contact form on the main page after switching back.");
    }

    @Test(description = "Demonstrates switching to an IFrame by its index.")
    public void testSwitchToFrameByIndex() {
        // Switch to the second IFrame using its index (1)
        // Note: The first iframe is at index 0, the second is at index 1.
        driver.switchTo().frame(1);
        System.out.println("Switched to IFrame with index 1.");

        // Verify content inside the second IFrame
        WebElement frameText = driver.findElement(By.id("text-in-iframe-2"));
        Assert.assertTrue(frameText.getText().contains("second IFrame"));
        System.out.println("Successfully verified text inside IFrame 2.");

        // Switch back to the main document
        driver.switchTo().defaultContent();
        System.out.println("Switched back to the default content.");
        Assert.assertTrue(driver.findElement(By.id("main-title")).isDisplayed());
    }
    
    @Test(description = "Demonstrates switching to an IFrame using a WebElement.")
    public void testSwitchToFrameByWebElement() {
        // Locate the iframe element first
        WebElement frameElement = driver.findElement(By.tagName("iframe")); // This gets the first iframe
        
        // Switch to the frame using the WebElement
        driver.switchTo().frame(frameElement);
        System.out.println("Switched to the first IFrame using its WebElement.");

        // Interact with an element inside the IFrame
        WebElement frameInput = driver.findElement(By.id("iframe-input-1"));
        frameInput.sendKeys("Testing WebElement switch");
        Assert.assertTrue(frameInput.getAttribute("value").contains("WebElement switch"));
        System.out.println("Successfully interacted with input inside the frame.");

        // Switch back to the parent frame/main document
        driver.switchTo().parentFrame(); // For a top-level frame, this is same as defaultContent()
        System.out.println("Switched back to the parent frame.");
        Assert.assertTrue(driver.findElement(By.id("main-title")).isDisplayed());
    }

    @AfterMethod
    public void tearDown() {
        if (driver != null) {
            driver.quit();
        }
    }
}
```

## Best Practices
-   **Use Name or ID**: Always prefer switching to frames using a stable `name` or `id`. This makes your tests more robust and readable.
-   **Avoid Index-Based Switching**: Only use `switchTo().frame(index)` as a last resort. It's brittle and can easily break if the page layout changes.
-   **Always Switch Back**: After you are done with actions inside a frame, always remember to switch back to the main context using `driver.switchTo().defaultContent()`.
-   **Explicit Waits**: Use explicit waits (`WebDriverWait`) to wait for the frame to be available and switchable before attempting to switch. This is crucial for frames that load asynchronously.
    ```java
    WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
    wait.until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.id("frame1")));
    ```
-   **Nested Frames**: For nested frames, you must switch to each frame in sequence, from parent to child. To get out of a nested frame, use `driver.switchTo().parentFrame()` to go up one level or `defaultContent()` to go all the way to the top.

## Common Pitfalls
-   **`NoSuchElementException`**: The most common issue. If you forget to switch to the IFrame, Selenium will not be able to find any elements within it.
-   **Switching to the Wrong Frame**: On pages with multiple frames, ensure you are using the correct identifier (name, ID, or index) to switch to the intended frame.
-   **Forgetting to Switch Back**: If you don't switch back to `defaultContent()`, subsequent commands intended for the main page will fail because the driver's context is still inside the IFrame.
-   **StaleElementReferenceException**: This can occur if the IFrame's content is reloaded or changed dynamically after you have switched to it. In such cases, you may need to switch out and back into the frame again.

## Interview Questions & Answers
1.  **Q:** You are getting a `NoSuchElementException` for an element that is clearly visible on the page. What is the most likely cause?
    **A:** The most likely cause is that the element is inside an IFrame. Selenium's driver can only access the DOM of the current context. To interact with the element, I need to first switch the driver's context to the correct IFrame using `driver.switchTo().frame()`.

2.  **Q:** What are the different ways to switch to a frame? Which one is the best and why?
    **A:** There are three ways: by index (integer), by name or ID (string), and by `WebElement`. The best and most reliable method is by **name or ID**, because it's not dependent on the page structure. An ID is supposed to be unique, making it a very stable locator. Switching by index is brittle because the order of frames can change. Switching by `WebElement` is a good alternative if no stable name or ID is available.

3.  **Q:** How do you handle nested IFrames?
    **A:** To handle nested IFrames, you must switch context sequentially. First, switch to the parent IFrame. From there, you can switch to the child IFrame nested within it. To exit, you can use `driver.switchTo().parentFrame()` to move up one level, or `driver.switchTo().defaultContent()` to return directly to the main page from any level of nesting.

## Hands-on Exercise
1.  Open the provided `xpath_axes_test_page.html` in a browser.
2.  Write a new test method `testInteractionBetweenFrames`.
3.  In the test, switch to the first IFrame (`frame1`) and get the placeholder text from the input field (`iframe-input-1`).
4.  Switch back to the default content.
5.  Now, switch to the second IFrame (by index `1` or by locating it as a `WebElement`).
6.  Assert that the text "Some text here for verification." is present in the `p` tag with ID `text-in-iframe-2`.
7.  Finally, switch back to the default content and assert that the main title "Demonstrating XPath Axes & IFrames" is visible.

## Additional Resources
-   [Selenium Documentation on Windows and Frames](https://www.selenium.dev/documentation/webdriver/browser/frames/)
-   [Ultimate Guide to Handling iFrames in Selenium](https://www.lambdatest.com/blog/how-to-handle-iframes-in-selenium-webdriver/)
-   [W3Schools IFrame Tag](https://www.w3schools.com/tags/tag_iframe.asp)
---
# selenium-2.4-ac5.md

# selenium-2.4-ac5: Drag-and-drop operations

## Overview
Automated testing often involves interacting with complex user interface elements, and drag-and-drop is a common interaction, especially in modern web applications. Selenium WebDriver provides the `Actions` class to simulate intricate user interactions like mouse clicks, keyboard presses, and, critically, drag-and-drop. Mastering this class is essential for SDETs to automate scenarios involving interactive elements such as kanban boards, file uploads via drag, or customizable dashboards.

## Detailed Explanation
The `Actions` class in Selenium WebDriver allows you to compose complex interactions rather than just single actions. It's particularly useful for scenarios that require holding down a mouse button, moving the mouse to a different location, and then releasing the button. The `dragAndDrop()` method is a convenient way to encapsulate this sequence of actions.

Selenium's `dragAndDrop()` method requires two `WebElement` arguments: the source element (the one to be dragged) and the target element (where the source element should be dropped). When this method is called, Selenium internally performs the following steps:
1.  Moves the mouse to the center of the source element.
2.  Presses (clicks down) the left mouse button.
3.  Moves the mouse to the center of the target element.
4.  Releases the left mouse button.

Alternatively, for more granular control or when `dragAndDrop()` doesn't work as expected (e.g., due to specific JavaScript implementations on the page), you can build the sequence manually using `clickAndHold()`, `moveToElement()`, and `release()` methods.

**When to use `Actions` for drag-and-drop:**
*   When the UI element genuinely requires a mouse-driven drag-and-drop interaction.
*   When standard `click()` or `sendKeys()` methods are insufficient.
*   For advanced interactions like hovering, double-clicking, right-clicking, or combining keyboard and mouse actions.

## Code Implementation
Let's consider a simple example where we drag a draggable element and drop it onto a droppable target. We'll use a public test site that provides such functionality.

```java
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.time.Duration;

public class DragAndDropTest {

    private WebDriver driver;
    private WebDriverWait wait;

    @BeforeMethod
    public void setup() {
        // Ensure you have chromedriver in your PATH or set System.setProperty
        // Example: System.setProperty("webdriver.chrome.driver", "/path/to/chromedriver");
        driver = new ChromeDriver();
        driver.manage().window().maximize();
        wait = new WebDriverWait(driver, Duration.ofSeconds(10));
    }

    @Test
    public void testDragAndDropUsingDirectMethod() {
        driver.get("https://jqueryui.com/droppable/");

        // Wait for the iframe to be present and switch to it
        // The draggable and droppable elements are inside an iframe
        wait.until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.className("demo-frame")));

        // Locate the source (draggable) and target (droppable) elements
        WebElement draggable = wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("draggable")));
        WebElement droppable = wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("droppable")));

        // Verify initial state
        String initialDroppableText = droppable.getText();
        Assert.assertEquals(initialDroppableText, "Drop here", "Droppable element should initially say 'Drop here'");

        // Perform drag and drop using the Actions class
        Actions actions = new Actions(driver);
        actions.dragAndDrop(draggable, droppable).build().perform();

        // Verify the result after drag and drop
        String droppableTextAfterDrop = droppable.getText();
        Assert.assertEquals(droppableTextAfterDrop, "Dropped!", "Droppable element text should change to 'Dropped!'");
        Assert.assertEquals(droppable.getCssValue("background-color"), "rgba(255, 250, 144, 1)", "Droppable background color should change");
        
        // Switch back to the main content (default content) if further actions are needed outside the iframe
        driver.switchTo().defaultContent();
    }

    @Test
    public void testDragAndDropUsingManualActions() {
        driver.get("https://jqueryui.com/droppable/");

        // Wait for the iframe and switch to it
        wait.until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(By.className("demo-frame")));

        WebElement draggable = wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("draggable")));
        WebElement droppable = wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("droppable")));

        // Verify initial state
        String initialDroppableText = droppable.getText();
        Assert.assertEquals(initialDroppableText, "Drop here", "Droppable element should initially say 'Drop here'");

        // Perform drag and drop manually using individual actions
        Actions actions = new Actions(driver);
        actions.clickAndHold(draggable) // Clicks on the draggable element and holds it
               .moveToElement(droppable)  // Moves the mouse to the droppable element
               .release()                 // Releases the mouse button
               .build()                   // Compiles all the actions into a single step
               .perform();                // Executes the compiled actions

        // Verify the result after drag and drop
        String droppableTextAfterDrop = droppable.getText();
        Assert.assertEquals(droppableTextAfterDrop, "Dropped!", "Droppable element text should change to 'Dropped!'");
        Assert.assertEquals(droppable.getCssValue("background-color"), "rgba(255, 250, 144, 1)", "Droppable background color should change");

        driver.switchTo().defaultContent();
    }

    @AfterMethod
    public void teardown() {
        if (driver != null) {
            driver.quit();
        }
    }
}
```

**Maven `pom.xml` dependencies:**
```xml
<dependencies>
    <!-- Selenium Java Client -->
    <dependency>
        <groupId>org.seleniumhq.selenium</groupId>
        <artifactId>selenium-java</artifactId>
        <version>4.17.0</version> <!-- Use the latest stable version -->
    </dependency>
    <!-- TestNG for test framework -->
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version> <!-- Use the latest stable version -->
        <scope>test</scope>
    </dependency>
    <!-- WebDriverManager (Optional, but highly recommended) -->
    <dependency>
        <groupId>io.github.bonigarcia</groupId>
        <artifactId>webdrivermanager</artifactId>
        <version>5.6.3</version> <!-- Use the latest stable version -->
        <scope>test</scope>
    </dependency>
</dependencies>
```
*Note: For `WebDriverManager` to auto-manage drivers, add `WebDriverManager.chromedriver().setup();` in your `setup()` method before `driver = new ChromeDriver();`.*

## Best Practices
- **Use Explicit Waits:** Always wait for the source and target elements to be visible and interactive before attempting drag-and-drop operations. This prevents `ElementNotInteractableException` or `NoSuchElementException`.
- **Handle Iframes:** If the elements involved in drag-and-drop are inside an iframe, remember to switch into the iframe first (`driver.switchTo().frame(...)`) and switch back to the default content afterwards (`driver.switchTo().defaultContent()`).
- **Verify Outcome:** After performing a drag-and-drop, always verify that the operation was successful. This could involve checking text changes, CSS property changes, element positions, or the presence/absence of certain elements.
- **Granular Actions for Complex Scenarios:** If `actions.dragAndDrop(source, target)` fails, try building the action sequence more manually using `clickAndHold(source)`, `moveToElement(target)`, and `release()`. This gives you more control.
- **Use `build().perform()`:** Always chain `build()` and `perform()` at the end of an `Actions` sequence. `build()` compiles the series of actions, and `perform()` executes them.

## Common Pitfalls
- **No Wait Strategy:** Attempting drag-and-drop on elements that are not yet fully loaded or interactive often leads to failures.
    *   **Solution:** Use `WebDriverWait` with `ExpectedConditions.visibilityOfElementLocated()` or `elementToBeClickable()`.
- **Iframe Issues:** Forgetting to switch to the correct iframe (or not switching back) when elements are embedded.
    *   **Solution:** Identify iframes using browser developer tools and use `driver.switchTo().frame()` appropriately. Remember `driver.switchTo().defaultContent()` to return to the main page.
- **Incorrect Locators:** Using incorrect or unstable locators for the source or target elements.
    *   **Solution:** Use reliable locators (ID, unique CSS selectors) and verify them thoroughly.
- **Dynamic Elements:** Drag-and-drop not working because the element attributes change after an initial interaction, leading to `StaleElementReferenceException`.
    *   **Solution:** Re-locate elements if necessary or use robust locators less prone to staleness.
- **JavaScript Event Handling Differences:** Some web applications implement drag-and-drop purely through JavaScript, which might not precisely mimic standard browser events.
    *   **Solution:** If `Actions` class fails, try to simulate the JavaScript events directly using `JavaScriptExecutor`, though this is usually a last resort.

## Interview Questions & Answers
1.  **Q: How do you perform drag-and-drop operations in Selenium?**
    **A:** We use the `Actions` class in Selenium WebDriver. The primary method is `actions.dragAndDrop(sourceElement, targetElement).build().perform()`. This method takes two `WebElement` arguments: the element to be dragged and the element it should be dropped onto. For more complex or failing scenarios, we can use individual actions like `clickAndHold(source)`, `moveToElement(target)`, and `release()`.

2.  **Q: What is the `Actions` class in Selenium and when would you use it?**
    **A:** The `Actions` class is a user-facing API for emulating complex user gestures, not just single events. I would use it for scenarios requiring multi-step interactions like:
    *   Drag-and-drop
    *   Mouse hovers (tooltips, dropdowns)
    *   Double-clicks and right-clicks
    *   Keyboard interactions (e.g., pressing `Shift` and clicking multiple elements)
    *   Any combination of mouse and keyboard events.

3.  **Q: You are trying to automate a drag-and-drop scenario, but it's failing. What are the common debugging steps you would take?**
    **A:**
    *   **Verify Locators:** First, confirm that the locators for both source and target elements are correct and stable.
    *   **Check for Iframes:** Use browser dev tools to see if elements are inside an iframe; if so, switch to it.
    *   **Add Waits:** Ensure explicit waits are in place for both elements to be visible and interactable before the action.
    *   **Try Manual Actions:** Instead of `dragAndDrop()`, try the granular sequence: `clickAndHold(source).moveToElement(target).release().build().perform()`. This sometimes helps if the direct method has issues.
    *   **JavaScriptExecutor:** As a last resort, investigate if the application's drag-and-drop is purely JavaScript-driven and try to emulate it using `JavaScriptExecutor`.
    *   **Browser/Driver Issues:** Test on different browsers or update WebDriver to the latest version.

## Hands-on Exercise
**Objective:** Automate a scenario involving dragging a slider.

**Task:**
1.  Navigate to: `https://jqueryui.com/slider/`
2.  Switch into the `iframe` containing the slider.
3.  Locate the slider handle element.
4.  Drag the slider handle to the right by approximately 100 pixels.
5.  Verify that the value associated with the slider (if displayed) or its position has changed.

**Hint:** You'll need `Actions.dragAndDropBy(element, xOffset, yOffset)`.

## Additional Resources
- **Selenium WebDriver Actions Class:** [https://www.selenium.dev/documentation/webdriver/actions/](https://www.selenium.dev/documentation/webdriver/actions/)
- **jQuery UI Droppable (used in example):** [https://jqueryui.com/droppable/](https://jqueryui.com/droppable/)
- **jQuery UI Slider (for exercise):** [https://jqueryui.com/slider/](https://jqueryui.com/slider/)
- **WebDriverManager GitHub:** [https://github.com/bonigarcia/webdrivermanager](https://github.com/bonigarcia/webdrivermanager)
---
# selenium-2.4-ac6.md

# Selenium Actions Class: Advanced Mouse and Keyboard Interactions

## Overview
In modern web applications, user interactions go far beyond simple clicks and text entry. Actions like hovering to reveal menus, right-clicking for context options, double-clicking, and performing complex keyboard inputs are common. Selenium's `Actions` class is the essential tool for automating these advanced user gestures, providing a powerful API to simulate complex interactions that simple `WebElement` commands cannot handle. Mastering the `Actions` class is critical for any SDET aiming to build robust and comprehensive test suites.

## Detailed Explanation
The `Actions` class works by building a chain of individual actions that are then performed in sequence. This chain-of-command pattern allows for the creation of complex and realistic user simulations. The process involves three key steps:

1.  **Instantiate the `Actions` class**: Create an instance of the `Actions` class, passing the `WebDriver` instance to its constructor. `Actions actions = new Actions(driver);`
2.  **Build the sequence of actions**: Call methods on the `actions` object to define the desired interactions. Each method (e.g., `moveToElement()`, `doubleClick()`, `keyDown()`) returns the `actions` object itself, allowing for intuitive method chaining.
3.  **Perform the actions**: Call the `.perform()` method at the end of the chain. This crucial step compiles and executes all the queued actions on the browser. Forgetting to call `.perform()` is a very common mistake.

### Key `Actions` Class Methods:
- **Mouse Hover (`moveToElement`)**: Moves the mouse to the center of a specified element. This is essential for testing dropdown menus, tooltips, or any content that appears on hover.
- **Double Click (`doubleClick`)**: Performs a double-click on an element.
- **Right Click (`contextClick`)**: Performs a right-click (context click) on an element, which often reveals a custom context menu.
- **Keyboard Actions (`keyDown`, `keyUp`, `sendKeys`)**: Allows for precise control over keyboard inputs. For example, holding down the `SHIFT` key while typing to produce uppercase text, or performing copy-paste operations (`CONTROL` + `C`, `CONTROL` + `V`).
- **Drag and Drop (`dragAndDrop`)**: Simulates dragging an element and dropping it onto another. (Covered in `selenium-2.4-ac5`).

## Code Implementation
This example demonstrates how to use the `Actions` class to interact with various elements on our test page, `xpath_axes_test_page.html`.

```java
import io.github.bonigarcia.wdm.WebDriverManager;
import org.junit.jupiter.api.*;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.nio.file.Paths;
import java.time.Duration;

public class AdvancedActionsTest {

    private static WebDriver driver;
    private WebDriverWait wait;
    private Actions actions;

    @BeforeAll
    public static void setupClass() {
        WebDriverManager.chromedriver().setup();
    }

    @BeforeEach
    public void setupTest() {
        driver = new ChromeDriver();
        driver.manage().window().maximize();
        // Get the absolute path of the HTML file
        String htmlFilePath = Paths.get("xpath_axes_test_page.html").toUri().toString();
        driver.get(htmlFilePath);
        wait = new WebDriverWait(driver, Duration.ofSeconds(10));
        actions = new Actions(driver);
    }

    @AfterEach
    public void teardown() {
        if (driver != null) {
            driver.quit();
        }
    }

    @Test
    @DisplayName("Should display menu on mouse hover")
    public void testMouseHover() {
        WebElement hoverButton = driver.findElement(By.id("hover-btn"));
        WebElement hoverMenu = driver.findElement(By.id("hover-menu"));
        WebElement hoverLink = driver.findElement(By.id("hover-link"));

        // Pre-condition check: menu should not be visible
        Assertions.assertFalse(hoverMenu.isDisplayed(), "Hover menu should not be visible initially.");

        // Build and perform the hover action
        actions.moveToElement(hoverButton).perform();

        // Wait for the menu to become visible and verify
        wait.until(ExpectedConditions.visibilityOf(hoverMenu));
        Assertions.assertTrue(hoverMenu.isDisplayed(), "Hover menu should be visible after hover.");

        // Move to the link within the menu and click it
        actions.moveToElement(hoverLink).click().perform();

        // In a real app, you would assert the navigation or action resulting from the click
        System.out.println("Successfully hovered and clicked the sub-menu link.");
    }

    @Test
    @DisplayName("Should display message on double-click")
    public void testDoubleClick() {
        WebElement doubleClickButton = driver.findElement(By.id("double-click-btn"));
        WebElement message = driver.findElement(By.id("double-click-message"));

        // Pre-condition check: message should not be visible
        Assertions.assertFalse(message.isDisplayed(), "Double-click message should be hidden initially.");

        // Build and perform the double-click action
        actions.doubleClick(doubleClickButton).perform();

        // Verify the message is now displayed
        Assertions.assertTrue(message.isDisplayed(), "Double-click message should appear after action.");
    }

    @Test
    @DisplayName("Should display context menu on right-click")
    public void testRightClick() {
        WebElement rightClickArea = driver.findElement(By.id("right-click-area"));
        WebElement rightClickMenu = driver.findElement(By.id("right-click-menu"));

        // Pre-condition check: context menu should not be visible
        Assertions.assertFalse(rightClickMenu.isDisplayed(), "Context menu should be hidden initially.");

        // Build and perform the right-click action
        actions.contextClick(rightClickArea).perform();

        // Verify the context menu is now displayed
        wait.until(ExpectedConditions.visibilityOf(rightClickMenu));
        Assertions.assertTrue(rightClickMenu.isDisplayed(), "Context menu should appear after right-click.");

        // Click an option in the context menu
        WebElement menuItem = driver.findElement(By.id("context-menu-item-1"));
        menuItem.click();

        // Assert the menu disappears after clicking an item
        wait.until(ExpectedConditions.invisibilityOf(rightClickMenu));
        Assertions.assertFalse(rightClickMenu.isDisplayed(), "Context menu should disappear after selecting an option.");
    }
    
    @Test
    @DisplayName("Should type in uppercase using SHIFT key")
    public void testKeyboardActions() {
        WebElement input = driver.findElement(By.id("key-input"));
        String textToType = "hello world";
        
        // Action to type text in uppercase by holding the SHIFT key
        actions.moveToElement(input)
                .click()
                .keyDown(Keys.SHIFT) // Press the SHIFT key down
                .sendKeys(textToType) // Type the text
                .keyUp(Keys.SHIFT) // Release the SHIFT key
                .perform();

        // Assert that the text in the input field is in uppercase
        String typedText = input.getAttribute("value");
        Assertions.assertEquals(textToType.toUpperCase(), typedText, "Text should be in uppercase.");
    }
}
```

## Best Practices
- **Always Use `.perform()`**: A chain of actions is only a blueprint. `.perform()` is what executes it. A common mistake is to call `.build()` which compiles the action but does not execute it. `.perform()` does both.
- **Chain Multiple Actions**: For complex sequences (e.g., hover, then click), chain the methods together in a single `.perform()` call for a more fluid and realistic interaction.
- **Use for Complex Scenarios Only**: Don't overuse the `Actions` class. For a simple click, `WebElement.click()` is more direct and readable. Reserve `Actions` for interactions that are impossible otherwise.
- **Include Waits**: After performing an action that triggers a UI change (like a hover menu appearing), always include an explicit wait to ensure the application has time to react before you proceed with verifications.

## Common Pitfalls
- **Forgetting `.perform()`**: The most frequent error. The actions are defined but never executed, leading to test failures with no apparent browser activity.
- **Interacting with Obscured Elements**: If another element is covering your target, the action may fail or have an unintended effect. Ensure the element is visible and unobstructed before interacting. Use `JavaScriptExecutor` to scroll if necessary.
- **Browser/Driver Inconsistencies**: The precision of mouse movements can sometimes vary slightly between different browsers or WebDriver versions. Be aware of potential flakiness and ensure your tests are resilient.
- **Actions on Wrong Element**: Always double-check that you are passing the correct `WebElement` to the `Actions` method. For example, `actions.moveToElement(menu).click(menuItem).perform()` is incorrect. It should be chained like `actions.moveToElement(menu).moveToElement(menuItem).click().perform()`.

## Interview Questions & Answers
1.  **Q:** You need to automate a scenario where a menu item only appears after hovering over a main menu. Simple `.click()` fails. How do you solve this?
    **A:** This is a classic use case for the `Actions` class. I would first instantiate the `Actions` class with the WebDriver instance. Then, I would build a chain of actions: first, use the `moveToElement()` method to hover over the main menu element. This will trigger the display of the submenu. Following that, I would chain another `moveToElement()` to the now-visible submenu item and finally append a `.click()` action. The entire sequence is executed by calling `.perform()`. It's also critical to add an explicit wait (`WebDriverWait`) for the submenu item to become visible or clickable after the initial hover.

2.  **Q:** What is the difference between `actions.build().perform()` and just `actions.perform()`?
    **A:** The `.build()` method compiles the sequence of actions into a single composite `Action` object but does not execute it. The `.perform()` method internally calls `.build()` and then immediately executes the action (`.build().perform()`). Therefore, for most use cases, calling `actions.perform()` is sufficient and more concise. Using `.build()` separately might be useful if you want to store a pre-defined composite action in a variable to be performed multiple times, but this is a rare scenario.

3.  **Q:** How would you automate typing "HELLO" in all caps into a search box without just sending the string "HELLO"?
    **A:** To simulate the user action of typing in caps, I would use the `Actions` class to control the keyboard. The sequence would be: `actions.moveToElement(searchBox).click().keyDown(Keys.SHIFT).sendKeys("hello").keyUp(Keys.SHIFT).perform()`. This chain first clicks the search box, then presses and holds the `SHIFT` key, types the string "hello", and finally releases the `SHIFT` key, resulting in "HELLO" being entered into the field. This is a more realistic simulation of user behavior than simply sending the uppercase string.

## Hands-on Exercise
1.  **Objective**: Extend the drag-and-drop test (`selenium-2.4-ac5`) with a keyboard action.
2.  **Task**:
    - Go to the jQuery UI Droppable example page: `https://jqueryui.com/droppable/`.
    - Using the `Actions` class, first drag the "Drag me to my target" box to the drop target.
    - **New Step**: After dropping it, use the `Actions` class to perform a "copy" keyboard shortcut (CTRL+C or CMD+C) while focused on the "Droppable" target box.
    - **Verification**: Although you can't verify the clipboard content directly with Selenium, add a `System.out.println()` statement confirming that the action was performed. The goal is to practice chaining drag-and-drop with keyboard actions.

## Additional Resources
- [Official Selenium Actions Class Documentation](https://www.selenium.dev/documentation/webdriver/actions_api/mouse/)
- [Ultimate Guide to Selenium Actions Class (Guru99)](https://www.guru99.com/keyboard-mouse-events-files-webdriver.html)
- [Baeldung: Selenium Actions Class](https://www.baeldung.com/selenium-actions-class)
---
# selenium-2.4-ac7.md

# Selenium 2.4-ac7: Handling File Uploads

## Overview
File uploads are a common feature in web applications, allowing users to submit documents, images, or other data. For an SDET, knowing how to automate file uploads is a crucial skill to ensure end-to-end test coverage. Selenium provides multiple strategies to handle file uploads, each with its own use case. The most common and reliable method involves using `sendKeys()` on an `<input type="file">` element. However, for more complex scenarios involving non-standard file selection dialogs, the `Robot` class can be a powerful, albeit less robust, alternative.

This guide covers both methods, providing production-grade code, best practices, and interview-focused insights to master file upload automation.

## Detailed Explanation

### Method 1: The `sendKeys()` Approach (Preferred)
This is the standard and most recommended way to handle file uploads in Selenium. It works when the file upload functionality is implemented with a standard HTML `<input>` element with `type="file"`.

**How it works:**
Selenium's `sendKeys()` method can be used on a file input element to directly provide the absolute path of the file you want to upload. You do not need to (and should not) click the "Browse" or "Choose File" button. Sending the file path to the input element programmatically populates the file selection.

**HTML Example:**
```html
<input type="file" id="file-upload" name="file-upload">
```
When you find this element and use `sendKeys("C:\\path\\to\\your\\file.txt")`, Selenium instructs the browser to set the value of this input to the provided path, simulating a user having selected that file.

### Method 2: The `Robot` Class Approach (Fallback)
This method should only be used as a fallback when the `sendKeys()` approach is not possible. This typically happens when the file upload dialog is not a standard HTML element but a native OS dialog (e.g., triggered by a Flash or a complex JavaScript component that hides the `input` element).

**How it works:**
The `java.awt.Robot` class is a low-level utility that can simulate native keyboard and mouse events on the operating system level, outside the context of the browser's DOM. The automation flow is:
1.  Click the button that opens the native file selection dialog.
2.  Use `Robot` to "type" the file path into the dialog's file name field.
3.  Use `Robot` to press the "Enter" key to confirm the selection and close the dialog.

**Why it's brittle:**
-   **Platform Dependent:** The code is not cross-platform. The file path format and dialog behavior differ between Windows, macOS, and Linux.
-   **Focus Dependent:** The script's success depends entirely on the file dialog window having the correct focus when the `Robot` class starts typing. Any interruption (like another window popping up) will cause the script to fail.
-   **Timing Issues:** You often need to add hardcoded `Thread.sleep()` calls to wait for the OS dialog to appear, which leads to flaky tests.
-   **Headless Execution:** It will not work in headless browser mode, as there is no GUI for the `Robot` to interact with.

## Code Implementation

Here is a complete, runnable TestNG example demonstrating both approaches.

### Prerequisites
1.  **Test HTML File:** Create a local HTML file named `FileUploadTestPage.html` with the following content to practice on.
    ```html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>File Upload Test Page</title>
    </head>
    <body>
        <h1>File Upload Test</h1>
        
        <h2>Standard Input Element</h2>
        <form action="#" method="post" enctype="multipart/form-data">
            <label for="file-upload">Choose a file to upload:</label>
            <input type="file" id="file-upload" name="file-upload">
            <br><br>
            <input type="submit" value="Upload File" id="submit-button">
        </form>
        <p id="file-upload-status"></p>

        <script>
            document.getElementById('submit-button').addEventListener('click', function(e) {
                e.preventDefault();
                const fileInput = document.getElementById('file-upload');
                if (fileInput.files.length > 0) {
                    document.getElementById('file-upload-status').textContent = 'File selected: ' + fileInput.files[0].name;
                } else {
                    document.getElementById('file-upload-status').textContent = 'No file selected!';
                }
            });
        </script>
    </body>
    </html>
    ```
2.  **Test File:** Create a dummy file named `test-file-to-upload.txt` in a known location (e.g., `C:\temp\test-file-to-upload.txt`).

### Java TestNG Code
```java
package com.sdetlearning.selenium;

import io.github.bonigarcia.wdm.WebDriverManager;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.awt.event.KeyEvent;
import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import java.time.Duration;

public class FileUploadTest {

    private WebDriver driver;
    private String testFilePath;
    private String testPageUrl;

    @BeforeMethod
    public void setUp() throws IOException {
        WebDriverManager.chromedriver().setup();
        driver = new ChromeDriver();
        driver.manage().window().maximize();
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(10));

        // Create a dummy file for upload
        File dummyFile = new File("test-file-to-upload.txt");
        if (!dummyFile.exists()) {
            dummyFile.createNewFile();
        }
        testFilePath = dummyFile.getAbsolutePath();

        // Path to the local HTML test page
        testPageUrl = Paths.get("FileUploadTestPage.html").toUri().toString();
    }

    @Test(description = "Handles file upload using the sendKeys method.", priority = 1)
    public void testFileUploadWithSendKeys() {
        System.out.println("Navigating to: " + testPageUrl);
        driver.get(testPageUrl);

        // Find the file input element
        WebElement fileInput = driver.findElement(By.id("file-upload"));
        
        // Use sendKeys to provide the file path
        System.out.println("Uploading file: " + testFilePath);
        fileInput.sendKeys(testFilePath);

        // Click the submit button
        driver.findElement(By.id("submit-button")).click();

        // Verify the status message
        WebElement status = driver.findElement(By.id("file-upload-status"));
        Assert.assertTrue(status.getText().contains("test-file-to-upload.txt"),
                "File upload status message is incorrect.");
        System.out.println("Successfully verified file selection with sendKeys.");
    }

    @Test(description = "Handles file upload using the Robot class.", priority = 2, enabled = false)
    public void testFileUploadWithRobotClass() throws AWTException, InterruptedException {
        // NOTE: This test is disabled by default because it's flaky and platform-dependent.
        // It's here for demonstration purposes only.
        System.out.println("Navigating to: " + testPageUrl);
        driver.get(testPageUrl);

        // In a real scenario with a non-input element, you'd click the button that opens the dialog.
        // For this demo, we'll imagine clicking a custom button that opens the dialog.
        // We'll still click the input element to trigger the dialog for this example.
        WebElement fileInputButton = driver.findElement(By.id("file-upload"));
        fileInputButton.click(); // This opens the native file dialog

        // Allow time for the dialog to appear
        Thread.sleep(2000);

        // 1. Copy file path to clipboard
        StringSelection stringSelection = new StringSelection(testFilePath);
        Toolkit.getDefaultToolkit().getSystemClipboard().setContents(stringSelection, null);

        // 2. Paste the file path using Robot class
        Robot robot = new Robot();
        
        // Use CTRL+V to paste
        robot.keyPress(KeyEvent.VK_CONTROL);
        robot.keyPress(KeyEvent.VK_V);
        robot.keyRelease(KeyEvent.VK_V);
        robot.keyRelease(KeyEvent.VK_CONTROL);

        // Add a small delay
        Thread.sleep(1000);

        // 3. Press Enter to confirm
        robot.keyPress(KeyEvent.VK_ENTER);
        robot.keyRelease(KeyEvent.VK_ENTER);

        // Allow time for the file to be "selected"
        Thread.sleep(2000);
        
        // Now submit the form
        driver.findElement(By.id("submit-button")).click();
        
        // Verify the status message
        WebElement status = driver.findElement(By.id("file-upload-status"));
        Assert.assertTrue(status.getText().contains("test-file-to-upload.txt"),
                "File upload status message is incorrect.");
        System.out.println("Successfully verified file selection with Robot class.");
    }

    @AfterMethod
    public void tearDown() {
        if (driver != null) {
            driver.quit();
        }
        // Clean up the dummy file
        File dummyFile = new File("test-file-to-upload.txt");
        if (dummyFile.exists()) {
            dummyFile.delete();
        }
    }
}
```

## Best Practices
-   **Always Prefer `sendKeys()`:** It is the most robust, reliable, and fastest method. It works cross-browser, cross-platform, and in headless mode.
-   **Use Absolute Paths:** Always provide the absolute path to the file in `sendKeys()`. Relative paths can be unreliable depending on the execution context.
-   **Avoid `Robot` Class:** Only use the `Robot` class as a last resort. If you must use it, be aware of its limitations and expect flakiness.
-   **Check for `<input type="file">`:** Before resorting to complex methods, inspect the DOM carefully. The file input element might be hidden or styled to look like a button. Even if it's hidden, you can often still use `sendKeys()` on it. You may need to use `JavaScriptExecutor` to make it visible first.
-   **Dynamic File Creation:** For CI/CD environments, don't rely on pre-existing files. Create the files you need during runtime, as shown in the example code. This makes your tests self-contained and environment-independent.

## Common Pitfalls
-   **Clicking the "Browse" Button:** A common mistake is trying to automate the clicking of the "Browse" button and then interacting with the OS dialog. This is doomed to fail because the dialog is not part of the browser's DOM and cannot be controlled by Selenium WebDriver directly.
-   **Using Relative Paths:** Using a relative path like `src/test/resources/my-file.txt` might work locally but fail in a CI environment where the working directory is different.
-   **`Robot` Class Flakiness:** Forgetting to add delays (`Thread.sleep`) or having another window steal focus can cause `Robot`-based tests to fail unpredictably.
-   **Hidden Input Fields:** Sometimes developers hide the `input` element and overlay it with a styled button. If `sendKeys()` doesn't work directly, you might need to use JavaScript to unhide the element first before sending the file path.
    ```java
    WebElement fileInput = driver.findElement(By.id("hidden-file-input"));
    ((JavascriptExecutor) driver).executeScript("arguments[0].style.display = 'block';", fileInput);
    fileInput.sendKeys(filePath);
    ```

## Interview Questions & Answers
1.  **Q: How do you automate a file upload in Selenium?**
    **A:** The most reliable method is to locate the `<input type="file">` element and use the `sendKeys()` method to pass the absolute path of the file. This directly sets the file for upload without interacting with the OS file dialog. It's fast, works in headless mode, and is platform-independent.

2.  **Q: What if the file upload is not a standard `<input type="file">` element? What's your fallback strategy?**
    **A:** If `sendKeys()` is not an option because the upload is handled by a custom widget that triggers a native OS dialog, the `Robot` class in Java can be used as a last resort. The process involves clicking the upload button, waiting for the dialog, copying the file path to the clipboard, and then using the `Robot` class to simulate `CTRL+V` (paste) and `Enter`. However, I would first raise this as a testability issue with the development team. This approach is flaky, platform-dependent, and won't work in headless CI environments.

3.  **Q: Why is using the `Robot` class for file uploads considered a bad practice?**
    **A:** It's considered a bad practice due to several reasons:
    -   **Flakiness:** It depends on window focus and timing, making tests unreliable.
    -   **Platform Dependency:** The code for handling dialogs is different for Windows, macOS, and Linux.
    -   **No Headless Support:** It requires a GUI to be present, so it cannot run in headless browsers, which is a standard practice in CI/CD pipelines.
    -   **Maintenance Overhead:** These tests are harder to maintain and debug.

## Hands-on Exercise
1.  **Setup:** Use the provided `FileUploadTestPage.html` and `FileUploadTest.java` files.
2.  **Execute the `sendKeys()` Test:** Run the `testFileUploadWithSendKeys` test and verify that it passes. Observe how quickly and reliably it executes.
3.  **Attempt the `Robot` Class Test:**
    -   Enable the `testFileUploadWithRobotClass` test by changing `enabled = false` to `enabled = true`.
    -   Run the test.
    -   While the test is running (during the `Thread.sleep`), try clicking on another window to see how it fails when the browser loses focus. This will demonstrate its flakiness.
4.  **Modify for a Hidden Element:**
    -   Add `style="display:none"` to the `<input type="file">` element in `FileUploadTestPage.html`.
    -   Re-run the `sendKeys()` test. It will likely fail with an `ElementNotInteractableException`.
    -   Implement the `JavaScriptExecutor` solution described in the "Common Pitfalls" section to make the element visible before calling `sendKeys()`.
    -   Verify that the test passes again.

## Additional Resources
-   [Selenium Documentation on File Uploads](https://www.selenium.dev/documentation/webdriver/elements/file_uploads/)
-   [Baeldung: Upload a File using Selenium](https://www.baeldung.com/java-selenium-upload-file)
-   [Java `Robot` Class Documentation](https://docs.oracle.com/javase/8/docs/api/java/awt/Robot.html)
---
# selenium-2.4-ac8.md

# Handling File Downloads and Verification in Selenium

## Overview

Automating file downloads and verifying their integrity is a critical task in end-to-end testing, especially for applications that generate reports, export data, or provide downloadable assets. While Selenium doesn't have a direct API to interact with the file system post-download, we can configure the browser to download files to a specific location and then use Java's I/O capabilities to verify the downloaded file.

This guide covers the standard approach using ChromeOptions to manage download behavior and Java to perform file verification.

## Detailed Explanation

The process involves two main stages:
1.  **Browser Configuration**: We instruct the WebDriver to automatically download files of a certain type to a predefined, temporary directory without showing a "Save As" dialog. This ensures a consistent and predictable download location for our tests.
2.  **File System Verification**: After triggering the download action in the application, the test script waits for the file to appear in the specified directory. Once the file is present, we can perform checks like verifying its name, size, or even content.

### Configuring Chrome for Downloads

We use `ChromeOptions` to set experimental preferences. The key preferences are:
-   `download.default_directory`: Specifies the absolute path where files will be saved.
-   `download.prompt_for_download`: Setting this to `false` prevents the browser from asking for download confirmation.
-   `plugins.always_open_pdf_externally`: Setting this to `true` ensures PDF files are downloaded instead of being opened in Chrome's built-in viewer.

It is a best practice to create a unique temporary directory for each test run to ensure isolation and avoid conflicts from previous runs.

## Code Implementation

Below is a complete, runnable example demonstrating how to download a file and verify its existence and size.

**Maven Dependencies:**
Ensure you have `selenium-java`, `testng`, and `webdrivermanager` in your `pom.xml`.

```xml
<dependencies>
    <dependency>
        <groupId>org.seleniumhq.selenium</groupId>
        <artifactId>selenium-java</artifactId>
        <version>4.15.0</version> <!-- Use a recent version -->
    </dependency>
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.github.bonigarcia</groupId>
        <artifactId>webdrivermanager</artifactId>
        <version>5.6.3</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

**Test Implementation:**

```java
import io.github.bonigarcia.wdm.WebDriverManager;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.testng.Assert;
import org.testng.annotations.*;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class FileDownloadTest {

    private WebDriver driver;
    private Path downloadDir;

    @BeforeClass
    public void setUp() throws IOException {
        // Create a temporary directory for downloads
        downloadDir = Files.createTempDirectory("selenium-downloads-");

        // Setup ChromeOptions to configure download behavior
        ChromeOptions options = new ChromeOptions();
        Map<String, Object> prefs = new HashMap<>();
        prefs.put("download.default_directory", downloadDir.toAbsolutePath().toString());
        prefs.put("download.prompt_for_download", false);
        prefs.put("plugins.always_open_pdf_externally", true); // For PDF downloads
        options.setExperimentalOption("prefs", prefs);

        WebDriverManager.chromedriver().setup();
        driver = new ChromeDriver(options);
        driver.manage().window().maximize();
    }

    @Test
    public void testFileDownloadAndVerify() throws InterruptedException {
        // For this example, we'll use a public site with a file to download
        driver.get("https://file-examples.com/index.php/sample-documents-download/sample-doc-download/");

        // 1. Trigger the download
        WebElement downloadLink = driver.findElement(By.xpath("//tbody/tr[1]/td[5]/a"));
        downloadLink.click();

        // 2. Wait for the file to be downloaded
        // This is a critical step. The wait time depends on file size and network speed.
        // A robust solution would involve a custom wait condition.
        String fileName = "file-sample_100kB.doc"; // The expected file name
        File downloadedFile = downloadDir.resolve(fileName).toFile();

        // Wait for a maximum of 30 seconds for the file to be downloaded
        boolean isDownloaded = waitForFileDownload(downloadedFile, 30);
        Assert.assertTrue(isDownloaded, "File was not downloaded within the specified time.");

        // 3. Verify the downloaded file
        System.out.println("File downloaded successfully to: " + downloadedFile.getAbsolutePath());
        Assert.assertTrue(downloadedFile.exists(), "Downloaded file does not exist.");

        // Verify file size (greater than 0)
        long fileSize = downloadedFile.length();
        System.out.println("Downloaded file size: " + fileSize + " bytes");
        Assert.assertTrue(fileSize > 0, "Downloaded file is empty.");
        
        // Example of a more specific size check (e.g., between 80KB and 100KB)
        Assert.assertTrue(fileSize > 80 * 1024 && fileSize < 100 * 1024, "File size is not within expected range.");
    }

    /**
     * A utility method to wait for a file to be downloaded.
     * @param file The file to wait for.
     * @param timeoutSeconds The maximum time to wait in seconds.
     * @return true if the file exists and is not empty, false otherwise.
     */
    private boolean waitForFileDownload(File file, int timeoutSeconds) throws InterruptedException {
        int counter = 0;
        while (counter < timeoutSeconds) {
            if (file.exists() && file.length() > 0) {
                return true;
            }
            TimeUnit.SECONDS.sleep(1);
            counter++;
        }
        return false;
    }

    @AfterClass
    public void tearDown() throws IOException {
        if (driver != null) {
            driver.quit();
        }
        // Clean up the download directory and its contents
        if (downloadDir != null && Files.exists(downloadDir)) {
             Files.walk(downloadDir)
                  .map(Path::toFile)
                  .forEach(File::delete);
        }
    }
}
```

## Best Practices

-   **Use Temporary, Isolated Directories**: Always create a new, unique download directory for each test session or even each test. This prevents collisions and makes cleanup easier.
-   **Implement Robust Waits**: Don't use `Thread.sleep()`. A polling mechanism that checks for file existence and size is much more reliable. The `waitForFileDownload` helper is a good start. For very large files, you might need to check if the file size has stopped changing for a certain period.
-   **Clean Up After Tests**: Always delete the downloaded files and the temporary directory in your `@After` methods to avoid cluttering the test environment.
-   **Use a `.gitignore`**: Add your root download folder (if you use a fixed one for local debugging) to `.gitignore` to avoid committing test artifacts.
-   **Verify Content when Necessary**: For critical files like financial reports, consider parsing the file (e.g., using Apache POI for Excel, or a simple text reader for CSV/TXT) and verifying a key piece of data within the content.

## Common Pitfalls

-   **Hardcoded `Thread.sleep()`**: The most common mistake. This leads to flaky tests that fail on slow networks or pass unnecessarily slowly on fast ones.
-   **Ignoring Browser-Specific Settings**: Different browsers (Firefox, Edge) have their own way of setting download preferences. The code above is for Chrome; you'll need to adapt it for other browsers using `FirefoxOptions`, etc.
-   **Not Handling the "Save As" Dialog**: If `download.prompt_for_download` is not set to `false`, a system-level dialog may appear, which Selenium cannot handle, causing the test to hang.
-   **Forgetting to Clean Up**: Leaving downloaded files on the test runner can consume significant disk space over time, especially in a CI/CD environment.

## Interview Questions & Answers

1.  **Q: How do you verify that a file has been downloaded successfully using Selenium?**
    **A:** Selenium itself cannot directly verify a file on the disk. The process is to first configure the WebDriver (e.g., using `ChromeOptions`) to save files to a known, predictable directory without user prompts. After the test clicks the download link, we use standard Java libraries (like `java.io.File` or `java.nio.file.Files`) to poll that directory until the file appears. We can then assert that the file exists, is not empty, and optionally check its name, extension, or even parse its contents.

2.  **Q: Why is using `Thread.sleep()` a bad idea when waiting for a download? What's a better approach?**
    **A:** Using `Thread.sleep()` introduces flakiness. If you set the sleep time too low, the test will fail on slower connections. If you set it too high, the test will be unnecessarily slow. A better approach is to use a dynamic wait or polling mechanism. You can write a loop that checks for the file's existence every second for a certain maximum timeout period. This makes the test wait only as long as necessary, making it both faster and more reliable.

3.  **Q: What challenges have you faced while automating file downloads?**
    **A:** Common challenges include:
    -   Handling browser-native "Save As" dialogs, which can be overcome by setting browser preferences.
    -   Dealing with dynamic file names (e.g., with timestamps). This can be handled by getting a list of files in the download directory and finding the most recently created one.
    -   Ensuring tests are reliable on different network speeds by implementing robust, dynamic waits instead of fixed sleeps.
    -   Cleaning up test artifacts (the downloaded files) to keep the test environment clean, which is crucial in CI pipelines.

## Hands-on Exercise

1.  **Modify the Test**: Take the code example above and adapt it to download a different file type, for example, a CSV or PDF from a different public website.
2.  **Handle Dynamic File Names**: Find a website that generates a file with a timestamp in the name. Modify the `waitForFileDownload` logic to find the latest file in the directory that matches a certain pattern (e.g., starts with `report-` and ends with `.csv`).
3.  **Verify Content**: Download a simple `.txt` or `.csv` file. After downloading, use Java's `Files.readAllLines()` to read the content and assert that it contains a specific, expected string.
4.  **Refactor for Firefox**: Create a new test class that performs the same download verification but using `FirefoxDriver` and `FirefoxOptions`. You will need to research the specific preferences for Firefox to control download behavior.

## Additional Resources

-   [Baeldung: How to Download a File with Selenium](https://www.baeldung.com/java-selenium-download-file)
-   [Selenium.dev Documentation](https://www.selenium.dev/documentation/webdriver/drivers/options/)
-   [Apache Commons IO](https://commons.apache.org/proper/commons-io/): A useful library for more advanced file operations and verification.
---
# selenium-2.4-ac9.md

# Handling Browser Authentication in Selenium

## Overview
Automating web applications that are protected by basic browser authentication (the native browser pop-up asking for a username and password) is a common challenge. Standard Selenium commands cannot interact with these dialogs because they are part of the browser's UI, not the web page's DOM. This guide covers the various strategies to handle this scenario effectively.

## Detailed Explanation

Browser-based authentication is a security measure implemented at the server level (e.g., via `.htaccess` on Apache). When a user tries to access a protected resource, the server sends a `401 Unauthorized` response with a `WWW-Authenticate: Basic` header. This triggers the browser to display a native login pop-up.

**Why can't Selenium's `Alert` interface handle this?**

The `driver.switchTo().alert()` method is designed to handle JavaScript-generated alerts (`alert()`, `confirm()`, `prompt()`). The browser authentication dialog is a native OS/browser-level UI component, completely outside the scope of the web page's content and the JavaScript execution context. Therefore, the Alert API cannot detect or interact with it.

### Strategy 1: Embedding Credentials in the URL (Deprecated but Simple)

The most straightforward method is to pass the username and password directly within the URL.

- **Syntax**: `https://<username>:<password>@<your-domain>.com`
- **Example**: `https://admin:admin@the-internet.herokuapp.com/basic_auth`

**How it works**: The browser intercepts the credentials from the URL and automatically uses them to respond to the server's authentication challenge.

**Limitations**:
- **Security Risk**: Credentials are in plain text in your code and potentially in server logs, which is a major security flaw.
- **Browser Support**: Modern browsers like Chrome and Firefox have deprecated or removed support for this feature due to its security risks. It often doesn't work or may require special configuration flags.
- **Not Robust**: This is not a reliable solution for modern, professional test automation frameworks.

### Strategy 2: Using the Chrome DevTools Protocol (CDP) (Recommended for Chromium)

Selenium 4 provides powerful integration with the Chrome DevTools Protocol (CDP), allowing direct communication with Chromium-based browsers (Chrome, Edge). We can use CDP to intercept network requests and provide authentication credentials before the pop-up ever appears.

**How it works**:
1. Get a handle to the DevTools session.
2. Enable the "Network" domain of CDP.
3. Register an authentication handler that will provide the credentials whenever the browser requires them.

This is the cleanest and most reliable method for modern browsers.

## Code Implementation

Here is a complete, runnable example demonstrating how to handle browser authentication using the CDP approach in Selenium 4.

```java
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.openqa.selenium.By;
import org.openqa.selenium.HasAuthentication;
import org.openqa.selenium.UsernameAndPassword;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import java.net.URI;
import java.time.Duration;
import java.util.function.Predicate;

public class BrowserAuthenticationTest {

    private WebDriver driver;
    private static final String USERNAME = "admin";
    private static final String PASSWORD = "admin";
    private static final String PROTECTED_URL = "https://the-internet.herokuapp.com/basic_auth";

    @BeforeEach
    public void setUp() {
        // Selenium Manager will handle the driver setup
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--start-maximized");
        driver = new ChromeDriver(options);
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(5));
    }

    @Test
    public void handleBrowserAuthenticationUsingCDP() {
        // Predicate to check if the URL requires authentication
        Predicate<URI> uriPredicate = uri -> uri.getHost().contains("the-internet.herokuapp.com");

        // Register the authentication handler
        // This cast is necessary to access the register() method
        ((HasAuthentication) driver).register(uriPredicate, UsernameAndPassword.of(USERNAME, PASSWORD));

        // Navigate to the page. The authentication is handled automatically.
        driver.get(PROTECTED_URL);

        // Verify that the login was successful
        WebElement successMessage = driver.findElement(By.tagName("p"));
        String expectedMessage = "Congratulations! You must have the proper credentials.";
        
        System.out.println("Page message: " + successMessage.getText());
        Assertions.assertEquals(expectedMessage, successMessage.getText().trim());
    }
    
    @Test
    public void handleAuthByEmbeddingCredentialsInURL() {
        // This method is deprecated and may not work in all modern browsers
        String urlWithCreds = "https://" + USERNAME + ":" + PASSWORD + "@the-internet.herokuapp.com/basic_auth";
        
        try {
            driver.get(urlWithCreds);
            
            // Verify that the login was successful
            WebElement successMessage = driver.findElement(By.tagName("p"));
            String expectedMessage = "Congratulations! You must have the proper credentials.";

            System.out.println("Page message: " + successMessage.getText());
            Assertions.assertEquals(expectedMessage, successMessage.getText().trim());
        } catch (Exception e) {
            System.err.println("Authentication with embedded credentials failed. This is common in modern browsers.");
            // This might fail depending on the browser version and security policies.
            // In a real test, you might want to handle this failure case.
        }
    }

    @AfterEach
    public void tearDown() {
        if (driver != null) {
            driver.quit();
        }
    }
}
```

## Best Practices
- **Prefer CDP over URL Embedding**: For Chromium browsers, the CDP approach (`HasAuthentication`) is the most secure, reliable, and professional method.
- **Use Predicates for Scoping**: When using `register`, provide a specific `Predicate<URI>` to ensure you only apply credentials to the intended domain. This prevents leaking credentials to other sites.
- **Store Credentials Securely**: Never hardcode usernames and passwords in your code. Use a secure vault (like HashiCorp Vault, AWS Secrets Manager) or environment variables to manage sensitive data.
- **Check for Browser Compatibility**: If you need to support non-Chromium browsers like Firefox or Safari, you may need a different approach, as CDP is not supported. For Firefox, you can use a similar mechanism via `HasAuthentication`. Safari support might be more limited.

## Common Pitfalls
- **Using `Alert` API**: The most common mistake is trying to use `driver.switchTo().alert()`, which will always fail with a `NoAlertPresentException`.
- **Ignoring Security**: Embedding credentials in the URL is insecure and should be avoided in production test code. It's acceptable for a quick local test but not for a shared codebase.
- **Forgetting to Register Before Navigating**: The authentication handler must be registered *before* you call `driver.get()`. The browser needs to know how to authenticate before it makes the request.
- **Casting to `HasAuthentication`**: Forgetting to cast the `driver` instance to `(HasAuthentication)` will result in a compile-time error, as the `register` method is not part of the standard `WebDriver` interface.

## Interview Questions & Answers
1. **Q:** Your team has a new test environment that is protected by basic browser authentication. How would you automate the login process using Selenium?
   **A:** For modern Chromium browsers like Chrome or Edge, the best approach is to use the Selenium 4 `HasAuthentication` interface, which leverages the Chrome DevTools Protocol (CDP). I would register an authentication handler with a URI predicate and the required username and password. This must be done before navigating to the protected page. This method is secure and reliable because it intercepts the authentication challenge at the network level. The older, less secure method of embedding credentials in the URL is unreliable in modern browsers and should be avoided.

2. **Q:** Why can't you use `driver.switchTo().alert()` to handle a browser authentication dialog?
   **A:** The `Alert` API in Selenium is designed specifically for JavaScript-based pop-ups like `alert()`, `confirm()`, and `prompt()`, which are part of the web page's DOM. A browser authentication dialog is a native UI component of the browser itself, not the web page. It operates outside the DOM and the JavaScript sandbox, so Selenium's standard interaction APIs cannot see or control it.

## Hands-on Exercise
1. **Set up**: Ensure you have a Java project with Selenium 4 and JUnit 5 configured.
2. **Implement**: Copy the `BrowserAuthenticationTest.java` code provided above into your project.
3. **Execute**: Run the `handleBrowserAuthenticationUsingCDP` test.
4. **Verify**: Observe that the test runs, the browser opens, navigates to the page, and the assertion passes without any visible pop-up.
5. **Experiment**: Change the USERNAME or PASSWORD to incorrect values and re-run the test. Observe that the page does not load correctly and the test fails, demonstrating that the authentication is indeed being checked.
6. **(Optional) Test the Deprecated Method**: Run the `handleAuthByEmbeddingCredentialsInURL` test and see if it works with your browser version. Note any warnings or failures.

## Additional Resources
- [Selenium Documentation on Authentication](https://www.selenium.dev/documentation/webdriver/http_auth/)
- [The-Internet: Basic Auth Example Page](https://the-internet.herokuapp.com/basic_auth)
- [Baeldung: Selenium 4 Authentication](https://www.baeldung.com/selenium-4-authentication)
---
# selenium-2.4-ac10.md


# Handling SSL Certificates in Selenium

## Overview
In test automation, we often encounter staging or test environments with self-signed or expired SSL (Secure Sockets Layer) certificates. By default, browsers block access to these sites, displaying a security warning (like "Your connection is not private") which halts Selenium scripts. This acceptance criterion covers how to configure WebDriver to automatically accept these insecure certificates, allowing tests to proceed seamlessly. This is a crucial skill for ensuring that tests can run reliably in non-production environments.

## Detailed Explanation
SSL certificates are digital certificates that authenticate a website's identity and enable an encrypted connection. When a browser encounters a website with an invalid (self-signed, expired, or mismatched) certificate, it interrupts the navigation to protect the user.

In Selenium, this interruption causes the `driver.get()` command to hang or fail, leading to a `WebDriverException` or similar error. To prevent this, we need to instruct the browser session managed by WebDriver to ignore these SSL errors and proceed with loading the page.

This is achieved by modifying the browser's capabilities before the WebDriver session is created. For modern browsers like Chrome and Firefox, this is done using their respective `Options` classes (`ChromeOptions`, `FirefoxOptions`). The key capability is `acceptInsecureCerts`. When this is set to `true`, the browser starts in a mode that bypasses SSL warning pages.

**Example Scenario:**
Imagine your team deploys a new build to a QA server `https://qa.my-app.com`. To save costs, the server uses a self-signed SSL certificate. Without handling this, all your UI tests would fail on the very first step—opening the URL. By enabling `acceptInsecureCerts`, your tests can navigate past the security warning and begin interacting with the application.

## Code Implementation
Here is a complete, runnable Java example demonstrating how to handle SSL certificates for both Chrome and Firefox using TestNG.

```java
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.firefox.FirefoxDriver;
import org.openqa.selenium.firefox.FirefoxOptions;
import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;
import io.github.bonigarcia.wdm.WebDriverManager;

public class SslCertificateTest {

    private WebDriver driver;

    // A popular site for testing pages with bad SSL certs
    private static final String INSECURE_URL = "https://expired.badssl.com/";

    @BeforeMethod
    public void setUp() {
        // Using WebDriverManager to handle driver binaries automatically
        WebDriverManager.chromedriver().setup();
        WebDriverManager.firefoxdriver().setup();
    }

    @Test
    public void testChromeAcceptsInsecureCert() {
        // 1. Configure setAcceptInsecureCerts in ChromeOptions
        ChromeOptions chromeOptions = new ChromeOptions();
        chromeOptions.setAcceptInsecureCerts(true);

        // Forcing headless mode for CI/CD environments
        chromeOptions.addArguments("--headless");
        
        // Instantiate the driver with the configured options
        driver = new ChromeDriver(chromeOptions);

        // 2. Navigate to site with bad cert
        System.out.println("Navigating to: " + INSECURE_URL);
        driver.get(INSECURE_URL);

        // 3. Verify page loads without blocking
        String pageTitle = driver.getTitle();
        System.out.println("Page Title: " + pageTitle);
        
        // The title of the page confirms we bypassed the SSL error
        Assert.assertEquals(pageTitle, "expired.badssl.com", "Page title should match, indicating successful navigation.");
    }

    @Test
    public void testFirefoxAcceptsInsecureCert() {
        // 1. Configure setAcceptInsecureCerts in FirefoxOptions
        FirefoxOptions firefoxOptions = new FirefoxOptions();
        firefoxOptions.setAcceptInsecureCerts(true);
        
        // Forcing headless mode for CI/CD environments
        firefoxOptions.addArguments("--headless");

        // Instantiate the driver with the configured options
        driver = new FirefoxDriver(firefoxOptions);

        // 2. Navigate to site with bad cert
        System.out.println("Navigating to: " + INSECURE_URL);
        driver.get(INSECURE_URL);

        // 3. Verify page loads without blocking
        String pageTitle = driver.getTitle();
        System.out.println("Page Title: " + pageTitle);

        // The title of the page confirms we bypassed the SSL error
        Assert.assertEquals(pageTitle, "expired.badssl.com", "Page title should match, indicating successful navigation.");
    }


    @AfterMethod
    public void tearDown() {
        if (driver != null) {
            driver.quit();
        }
    }
}
```

## Best Practices
- **Use `setAcceptInsecureCerts`:** This is the modern, standardized W3C approach for handling insecure certificates and should be your default choice. Avoid older, browser-specific profile settings.
- **Isolate Insecure Configurations:** Only apply this setting for environments that require it (like `dev`, `qa`, `staging`). Never use it for production tests, as it could mask real security issues. Use a configuration file or environment variables to enable it conditionally.
- **Combine with Other Options:** The `Options` object is the central place for all browser startup configurations. Add other settings like headless mode, window size, or disabled notifications to the same object.
- **Log a Warning:** When this capability is enabled, it's good practice to log a clear warning message (e.g., "WARNING: Running browser with insecure certificates enabled.") so that it's visible in test execution logs.

## Common Pitfalls
- **Applying to WebDriver, Not Options:** A common mistake is trying to set this capability on the `WebDriver` instance *after* it has been created. It **must** be set on the `ChromeOptions` or `FirefoxOptions` object *before* it is passed to the driver's constructor.
- **Using Deprecated Methods:** In older Selenium versions, developers used `DesiredCapabilities`. While it might still work for backward compatibility, it is deprecated. Always use the `...Options` classes.
- **Forgetting about Other Browsers:** If your test suite is cross-browser, ensure you implement this logic for all `Options` types (e.g., `EdgeOptions`, `SafariOptions`) that you support.

## Interview Questions & Answers
1. **Q:** Your Selenium script is failing with a "privacy error" or "connection not secure" message when running against the QA environment. What is the likely cause and how do you fix it?
   **A:** The likely cause is that the QA environment is using an invalid SSL certificate (e.g., self-signed or expired). The browser is blocking the navigation for security reasons. To fix this, I would use the browser's `Options` class (like `ChromeOptions` or `FirefoxOptions`) and call the `setAcceptInsecureCerts(true)` method. This capability, when passed to the WebDriver constructor, tells the browser to bypass the SSL warning page and proceed with loading the site, allowing the test to continue.

2. **Q:** Is it a good practice to always accept insecure SSL certificates in your test framework? Why or why not?
   **A:** No, it is not a good practice to *always* enable it. This setting should be used conditionally and enabled only for specific test environments (like DEV or QA) where self-signed certificates are expected. It should be disabled for production test runs. Enabling it for production could hide a serious, real issue with the site's SSL certificate, which is a critical security flaw that the test should catch. A robust framework should allow enabling or disabling this feature through an external configuration file or environment variable.

## Hands-on Exercise
1. **Setup:** Create a new Maven project and add dependencies for Selenium (`selenium-java`), TestNG (`testng`), and WebDriverManager (`webdrivermanager`).
2. **Create Test Class:** Create a new Java class named `SslPracticeTest`.
3. **Write a Failing Test:** Write a TestNG test method that attempts to navigate to `https://untrusted-root.badssl.com/` using a standard `ChromeDriver` instance (with no special options). Run the test and observe that it fails because of the SSL error.
4. **Write a Passing Test:** Create a new test method. Inside this method:
    - Instantiate `ChromeOptions`.
    - Set the `acceptInsecureCerts` capability to `true`.
    - Create a `ChromeDriver` instance, passing the options object to its constructor.
    - Navigate to `https://untrusted-root.badssl.com/`.
    - Add an assertion to verify that the page title is "untrusted-root.badssl.com".
5. **Run and Verify:** Run your test class. The first test should fail, and the second test should pass. This confirms your understanding of how to handle SSL errors.

## Additional Resources
- [badssl.com](https://badssl.com/): A great resource for testing various SSL certificate issues.
- [Selenium Documentation on Browser Options](https://www.selenium.dev/documentation/webdriver/drivers/options/): Official documentation on using Options classes.
- [ChromeOptions Documentation](https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/chrome/ChromeOptions.html): Javadoc for `ChromeOptions`.
---
# selenium-2.4-ac11.md


# Working with Advanced HTML5 Elements: Shadow DOM, SVG, and Canvas

## Overview
Modern web applications are increasingly complex, using advanced HTML5 features like Shadow DOM for encapsulation, SVG for scalable vector graphics, and Canvas for dynamic drawings. Automating interactions with these elements requires specialized techniques beyond standard locators, as they behave differently from traditional DOM elements. This guide covers the essential strategies an SDET needs to test applications that use these modern web technologies effectively.

## Detailed Explanation

### 1. Shadow DOM
The Shadow DOM allows a component's internal structure, styling, and behavior to be hidden and encapsulated from the rest of the page's DOM. This is a core concept behind Web Components.

- **Why is it tricky?** Elements within a Shadow DOM are not directly accessible via standard `driver.findElement()` calls from the main document. You must first access the **shadow host** (the element the shadow root is attached to) and then query its `shadowRoot` property to find elements within it.

- **How to automate:** Selenium provides the `getShadowRoot()` method on a `WebElement` to access its shadow DOM. Once you have the `SearchContext` of the shadow root, you can use `findElement()` and `findElements()` to locate elements within it.

### 2. SVG (Scalable Vector Graphics)
SVG is an XML-based format for defining vector graphics. Unlike standard image formats, SVGs are part of the DOM, meaning their internal shapes (`<path>`, `<circle>`, `<rect>`, etc.) are DOM elements that can be located and interacted with.

- **Why is it tricky?** SVG elements don't always have standard attributes like `id` or `class`. They also belong to a different XML namespace. Locating them requires using specific XPath functions like `local-name()` or `name()` to correctly identify the tag.

- **How to automate:** The most reliable way to locate SVG elements is with XPath. Standard CSS selectors have limited support for SVG. The key is to construct an XPath that checks the element's tag name using `local-name()` because of the XML namespace. For example: `//*[local-name()='svg']/*[local-name()='g']/*[local-name()='path']`.

### 3. Canvas
The `<canvas>` element is a container for graphics that are drawn programmatically, usually with JavaScript. It's essentially a bitmap drawing surface.

- **Why is it tricky?** The contents of a canvas are not part of the DOM. There are no "elements" inside a canvas to locate. You cannot use `findElement` to click a button drawn on a canvas because, from the DOM's perspective, that button doesn't exist. It's just pixels on a surface.

- **How to automate:** Interaction with a canvas is typically done in two ways:
    1.  **JavaScriptExecutor:** Use JavaScript to simulate drawing actions or to retrieve pixel data for visual validation.
    2.  **Actions Class:** Calculate the coordinates of the target within the canvas and use the `Actions` class to perform a click at that specific `(x, y)` offset from the top-left corner of the canvas element. This is the most common approach for UI interaction.

## Code Implementation
This runnable Java TestNG class demonstrates how to interact with all three types of elements.

### Example HTML Page (`AdvancedElements.html`)
To run the following code, create this HTML file locally:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Advanced Elements Test Page</title>
</head>
<body>

<h1>Shadow DOM Example</h1>
<div id="shadow-host"></div>

<h1>SVG Example</h1>
<svg id="svg-icon" width="100" height="100">
  <circle id="svg-circle" cx="50" cy="50" r="40" stroke="green" stroke-width="4" fill="yellow" onclick="alert('Circle clicked!')" />
</svg>

<h1>Canvas Example</h1>
<canvas id="my-canvas" width="200" height="100" style="border:1px solid #000000;"></canvas>
<p id="canvas-status">Canvas not clicked</p>

<script>
    // Shadow DOM setup
    const host = document.getElementById('shadow-host');
    const shadowRoot = host.attachShadow({ mode: 'open' });
    shadowRoot.innerHTML = `
        <style>p { color: red; }</style>
        <p id="shadow-text">This text is inside the Shadow DOM.</p>
        <button id="shadow-button" onclick="alert('Shadow button clicked!')">Click Me</button>
    `;

    // Canvas setup
    const canvas = document.getElementById('my-canvas');
    const ctx = canvas.getContext('2d');
    ctx.font = '20px Arial';
    ctx.fillText('Clickable Area', 10, 50);
    
    canvas.addEventListener('click', function(event) {
        // Simple click detection for demonstration
        if (event.offsetX > 10 && event.offsetX < 150 && event.offsetY > 30 && event.offsetY < 60) {
             document.getElementById('canvas-status').textContent = 'Canvas area was clicked!';
        }
    });
</script>

</body>
</html>
```

### Test Class (`AdvancedElementsTest.java`)

```java
import io.github.bonigarcia.wdm.WebDriverManager;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.interactions.Actions;
import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;
import java.nio.file.Paths;

public class AdvancedElementsTest {

    private WebDriver driver;

    @BeforeMethod
    public void setUp() {
        WebDriverManager.chromedriver().setup();
        driver = new ChromeDriver();
        // Load the local HTML file. Update this path to where you saved the file.
        String htmlFilePath = Paths.get("AdvancedElements.html").toUri().toString();
        driver.get(htmlFilePath);
    }

    @Test(description = "Interact with elements inside a Shadow DOM")
    public void testShadowDomInteraction() {
        // 1. Find the shadow host element
        WebElement shadowHost = driver.findElement(By.id("shadow-host"));

        // 2. Get the shadow root
        SearchContext shadowRoot = shadowHost.getShadowRoot();

        // 3. Find elements within the shadow root
        WebElement shadowText = shadowRoot.findElement(By.id("shadow-text"));
        Assert.assertEquals(shadowText.getText(), "This text is inside the Shadow DOM.");

        // You can also interact with elements
        WebElement shadowButton = shadowRoot.findElement(By.id("shadow-button"));
        shadowButton.click();
        
        // Handle the alert to confirm the click
        Alert alert = driver.switchTo().alert();
        Assert.assertEquals(alert.getText(), "Shadow button clicked!");
        alert.accept();
    }

    @Test(description = "Interact with an SVG element using XPath")
    public void testSvgInteraction() {
        // Use XPath with local-name() to correctly identify the SVG element
        // This is the most reliable way to locate SVG nodes
        WebElement svgCircle = driver.findElement(By.xpath("//*[local-name()='svg']/*[local-name()='circle']"));
        
        // SVG elements can be clicked like any other element
        svgCircle.click();

        // Handle the alert to confirm the click
        Alert alert = driver.switchTo().alert();
        Assert.assertEquals(alert.getText(), "Circle clicked!");
        alert.accept();
    }

    @Test(description = "Interact with a Canvas element using Actions class")
    public void testCanvasInteraction() {
        WebElement canvas = driver.findElement(By.id("my-canvas"));
        WebElement canvasStatus = driver.findElement(By.id("canvas-status"));
        
        // Verify initial state
        Assert.assertEquals(canvasStatus.getText(), "Canvas not clicked");
        
        // Use Actions class to click at a specific coordinate within the canvas
        Actions actions = new Actions(driver);
        
        // Move to the top-left of the canvas, then move by an offset (x=50, y=40) and click
        // This targets the "Clickable Area" text drawn on the canvas
        actions.moveToElement(canvas, 50, 40).click().build().perform();
        
        // Verify that the click was registered by checking the status text
        Assert.assertEquals(canvasStatus.getText(), "Canvas area was clicked!");
    }

    @AfterMethod
    public void tearDown() {
        if (driver != null) {
            driver.quit();
        }
    }
}

```

## Best Practices
- **Shadow DOM:** Always check the browser dev tools. If an element is inside a `#shadow-root`, you must use `getShadowRoot()`. Create a reusable utility method that takes a host element and a locator, and returns the element from within the shadow DOM.
- **SVG:** Prefer XPath with `local-name()` or `name()` for robust SVG locators. Avoid relying on CSS selectors, which can be inconsistent across browsers for SVG.
- **Canvas:** For clickable areas, use the `Actions` class with coordinate offsets. For validation, consider visual regression testing tools (like Applitools) or use JavaScript to get pixel data if the canvas state is queryable.
- **Communication:** Work with developers to add `data-testid` attributes to SVG elements and to expose methods on the `window` object to get the state of a canvas if possible. This makes testing far less brittle.

## Common Pitfalls
- **`NoSuchElementException`:** This is the most common error when trying to find an element inside a Shadow DOM or SVG without the correct technique.
- **Incorrect XPath for SVG:** Writing `//svg/circle` might fail. You must account for the XML namespace, making `//*[local-name()='svg']/*[local-name()='circle']` the correct approach.
- **Clicking the Canvas Element:** Simply calling `canvas.click()` will click the center of the canvas. This is rarely what you want. You must use `actions.moveToElement(canvas, x, y).click()` to target a specific area.

## Interview Questions & Answers
1. **Q:** You're trying to locate a button with `id="submit"` but `driver.findElement(By.id("submit"))` throws a `NoSuchElementException`. In dev tools, you can clearly see the element. What's a likely cause?
   **A:** A very likely cause is that the button is inside a Shadow DOM. Standard find methods on the `driver` object cannot pierce the shadow boundary. To solve this, I would first locate the "host" element that contains the shadow root. Then, I'd call the `.getShadowRoot()` method on that host element to get a `SearchContext`. Finally, I would use that search context to find the button by its ID, like this: `shadowRoot.findElement(By.id("submit"))`.

2. **Q:** How would you verify that a graph rendered as an SVG is displaying the correct number of bars?
   **A:** Since SVG elements are part of the DOM, I can locate them directly. I would use an XPath locator to find all the bar elements. For example, if each bar is a `<rect>` element inside the main SVG, I would use a locator like `//*[local-name()='svg']//*[local-name()='rect']` combined with `findElements()`. The size of the returned list of WebElements would give me the count of bars, which I can then assert against the expected number.

3. **Q:** Can you use Selenium to click a specific "start" button inside a game that runs in an HTML `<canvas>`? Explain your approach.
   **A:** You cannot locate the "start" button directly because it's not a DOM element; it's just pixels drawn on the canvas. The correct approach is to use the `Actions` class. First, I would need to know the coordinates of the button relative to the top-left corner of the canvas element. I might get these from developers or by manual inspection. Then, I would use `new Actions(driver).moveToElement(canvas, x, y).click().build().perform()`, where `x` and `y` are the coordinates of the button. This simulates a user clicking at that precise location on the canvas.

## Hands-on Exercise
1. **Save the HTML:** Save the example HTML code from this guide to a local file named `AdvancedElements.html`.
2. **Setup Project:** Create a Maven project with Selenium, TestNG, and WebDriverManager dependencies.
3. **Create Test Class:** Copy the `AdvancedElementsTest.java` code into your project.
4. **Update File Path:** In the `@BeforeMethod`, make sure the path to your `AdvancedElements.html` file is correct. Use the `Paths.get("...").toUri().toString()` method to ensure it works across different operating systems.
5. **Run the Tests:** Execute the tests using TestNG. All three tests should pass, demonstrating that you can successfully interact with elements in a Shadow DOM, an SVG, and a Canvas.
6. **Experiment:** Try to break the tests. For example, remove `getShadowRoot()` and see the test fail. Change the XPath for the SVG to see it fail. This will help reinforce why these specific techniques are necessary.

## Additional Resources
- [Selenium Documentation on Shadow DOM](https://www.selenium.dev/documentation/webdriver/support_features/shadow_dom/)
- [MDN Web Docs: Shadow DOM](https://developer.mozilla.org/en-US/docs/Web/API/Web_components/Using_shadow_DOM)
- [MDN Web Docs: SVG Tutorial](https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial)
- [MDN Web Docs: Canvas API](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API)
---
# selenium-2.4-ac12.md


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
