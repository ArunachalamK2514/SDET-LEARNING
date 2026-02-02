# selenium-2.3-ac2: Demonstrate Explicit Wait with 10 different ExpectedConditions

## Overview
While Implicit Waits provide a global, minimal wait time for element presence, **Explicit Waits** offer a more powerful and flexible synchronization mechanism in Selenium. Explicit waits allow you to pause the test execution until a specific condition has been met or the maximum timeout has elapsed. This is crucial for handling dynamic web elements that appear, disappear, or change state unpredictably, leading to more robust and less flaky tests.

## Detailed Explanation
Explicit Waits are implemented using the `WebDriverWait` class in conjunction with `ExpectedConditions`. `WebDriverWait` allows you to define the maximum amount of time to wait, and `ExpectedConditions` define the specific criteria that must be met before proceeding. This approach is highly recommended because it waits only as long as necessary for a condition to be true, making tests more efficient and reliable.

**Key characteristics of Explicit Wait:**
- **Targeted:** Explicit waits apply to specific elements or conditions, unlike implicit waits which apply globally.
- **Condition-Based:** They wait for a particular `ExpectedCondition` to become true. This could be element visibility, clickability, text presence, alert presence, etc.
- **Flexible Polling:** You can configure the polling interval (how often Selenium checks for the condition) and ignore specific exceptions during polling.
- **Exceptions:** If the condition is not met within the specified timeout, a `TimeoutException` is thrown.
- **Recommended over Implicit Wait:** For complex, dynamic web applications, explicit waits are generally preferred as they provide granular control and better stability. It is best practice *not* to mix explicit and implicit waits, as this can lead to unpredictable behavior and longer-than-necessary waits.

**`WebDriverWait` Class:**
```java
WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10)); // Selenium 4+
// or for older versions: WebDriverWait wait = new WebDriverWait(driver, 10);
```
The constructor takes the `WebDriver` instance and the maximum wait time.

**`ExpectedConditions` Class:**
This class provides a set of predefined conditions that are commonly used. Here, we will demonstrate 10 of them.

## Code Implementation
For this example, we'll continue to use `https://the-internet.herokuapp.com/`. It offers several dynamic pages suitable for demonstrating different `ExpectedConditions`.

```xml
<!-- In your pom.xml, ensure you have Selenium 4+ and TestNG -->
<dependencies>
    <!-- Selenium Java -->
    <dependency>
        <groupId>org.seleniumhq.selenium</groupId>
        <artifactId>selenium-java</artifactId>
        <version>4.20.0</version> <!-- Use the latest stable version -->
    </dependency>
    <!-- WebDriver Manager (optional, but highly recommended for driver management) -->
    <dependency>
        <groupId>io.github.bonigarcia</groupId>
        <artifactId>webdrivermanager</artifactId>
        <version>5.8.0</version> <!-- Use the latest stable version -->
    </dependency>
    <!-- TestNG -->
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.10.2</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

```java
import org.openqa.selenium.Alert;
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

import io.github.bonigarcia.wdm.WebDriverManager;

import java.time.Duration;
import java.util.List;
import java.util.Set;

import static org.testng.Assert.*;

public class ExplicitWaitExpectedConditionsDemo {

    private WebDriver driver;
    private WebDriverWait wait;
    private final Duration TIMEOUT = Duration.ofSeconds(10); // Max wait time

    @BeforeMethod
    public void setup() {
        WebDriverManager.chromedriver().setup();
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--start-maximized");
        driver = new ChromeDriver(options);
        wait = new WebDriverWait(driver, TIMEOUT);
        // Do NOT set implicit wait here to avoid mixing waits.
    }

    @Test(description = "1. Waits for an element to be present in the DOM (not necessarily visible)")
    public void testPresenceOfElementLocated() {
        driver.get("https://the-internet.herokuapp.com/dynamic_loading/1"); // Element hidden but present
        driver.findElement(By.cssSelector("#start button")).click();

        By elementToLocate = By.cssSelector("#finish h4");
        WebElement finishMessage = wait.until(ExpectedConditions.presenceOfElementLocated(elementToLocate));
        assertNotNull(finishMessage);
        assertEquals(finishMessage.getText(), "Hello World!");
        System.out.println("presenceOfElementLocated: Found text - " + finishMessage.getText());
    }

    @Test(description = "2. Waits for an element to be visible on the page (present and has height/width > 0)")
    public void testVisibilityOfElementLocated() {
        driver.get("https://the-internet.herokuapp.com/dynamic_loading/2"); // Element appears after delay
        driver.findElement(By.cssSelector("#start button")).click();

        By elementToLocate = By.cssSelector("#finish h4");
        WebElement finishMessage = wait.until(ExpectedConditions.visibilityOfElementLocated(elementToLocate));
        assertNotNull(finishMessage);
        assertEquals(finishMessage.getText(), "Hello World!");
        System.out.println("visibilityOfElementLocated: Found text - " + finishMessage.getText());
    }

    @Test(description = "3. Waits for an element to be visible on the page (using WebElement reference)")
    public void testVisibilityOf() {
        driver.get("https://the-internet.herokuapp.com/dynamic_loading/2");
        WebElement startButton = driver.findElement(By.cssSelector("#start button"));
        startButton.click();

        WebElement hiddenElement = driver.findElement(By.cssSelector("#finish h4")); // Element is present, but not visible yet
        WebElement finishMessage = wait.until(ExpectedConditions.visibilityOf(hiddenElement));
        assertNotNull(finishMessage);
        assertEquals(finishMessage.getText(), "Hello World!");
        System.out.println("visibilityOf: Found text - " + finishMessage.getText());
    }

    @Test(description = "4. Waits for an element to be clickable (visible and enabled)")
    public void testElementToBeClickable() {
        driver.get("https://the-internet.herokuapp.com/dynamic_controls");
        WebElement enableButton = driver.findElement(By.cssSelector("#input-example button"));
        enableButton.click(); // Click to enable the input field

        By inputFieldLocator = By.cssSelector("#input-example input[type='text']");
        WebElement inputField = wait.until(ExpectedConditions.elementToBeClickable(inputFieldLocator));
        inputField.sendKeys("Hello, Selenium!");
        assertEquals(inputField.getAttribute("value"), "Hello, Selenium!");
        System.out.println("elementToBeClickable: Typed into input field - " + inputField.getAttribute("value"));
    }

    @Test(description = "5. Waits for an element to be selected (e.g., checkbox, radio button)")
    public void testElementToBeSelected() {
        driver.get("https://the-internet.herokuapp.com/checkboxes");
        WebElement checkbox1 = driver.findElement(By.xpath("//form[@id='checkboxes']/input[1]"));
        assertFalse(checkbox1.isSelected());

        checkbox1.click();
        wait.until(ExpectedConditions.elementToBeSelected(checkbox1));
        assertTrue(checkbox1.isSelected());
        System.out.println("elementToBeSelected: Checkbox 1 is selected.");
    }

    @Test(description = "6. Waits for a text to be present in the specified element")
    public void testTextToBePresentInElement() {
        driver.get("https://the-internet.herokuapp.com/dynamic_controls");
        WebElement messageDiv = driver.findElement(By.id("message"));
        WebElement removeButton = driver.findElement(By.cssSelector("#checkbox-example button"));
        removeButton.click(); // Click to remove the checkbox

        wait.until(ExpectedConditions.textToBePresentInElement(messageDiv, "It's gone!"));
        assertEquals(messageDiv.getText(), "It's gone!");
        System.out.println("textToBePresentInElement: Message is - " + messageDiv.getText());
    }

    @Test(description = "7. Waits for a text to be present in the value attribute of the specified element")
    public void testTextToBePresentInElementValue() {
        driver.get("https://the-internet.herokuapp.com/dynamic_controls");
        WebElement enableButton = driver.findElement(By.cssSelector("#input-example button"));
        enableButton.click(); // Click to enable input

        By inputFieldLocator = By.cssSelector("#input-example input[type='text']");
        WebElement inputField = wait.until(ExpectedConditions.elementToBeClickable(inputFieldLocator)); // Wait till enabled
        inputField.sendKeys("My Value");

        wait.until(ExpectedConditions.textToBePresentInElementValue(inputField, "My Value"));
        assertEquals(inputField.getAttribute("value"), "My Value");
        System.out.println("textToBePresentInElementValue: Input field value is - " + inputField.getAttribute("value"));
    }

    @Test(description = "8. Waits for an alert to be displayed and switches to it")
    public void testAlertIsPresent() {
        driver.get("https://the-internet.herokuapp.com/javascript_alerts");
        driver.findElement(By.cssSelector("button[onclick='jsAlert()']")).click();

        Alert alert = wait.until(ExpectedConditions.alertIsPresent());
        assertNotNull(alert);
        assertEquals(alert.getText(), "I am a JS Alert");
        alert.accept();
        System.out.println("alertIsPresent: Alert text - " + alert.getText());
    }

    @Test(description = "9. Waits for the title of the page to contain a specific string")
    public void testTitleContains() {
        driver.get("https://the-internet.herokuapp.com/");
        wait.until(ExpectedConditions.titleContains("The Internet"));
        assertTrue(driver.getTitle().contains("The Internet"));
        System.out.println("titleContains: Page title - " + driver.getTitle());
    }

    @Test(description = "10. Waits for the URL of the current page to contain a specific string")
    public void testUrlContains() {
        driver.get("https://the-internet.herokuapp.com/");
        driver.findElement(By.linkText("Dynamic Loading")).click();
        wait.until(ExpectedConditions.urlContains("/dynamic_loading"));
        assertTrue(driver.getCurrentUrl().contains("/dynamic_loading"));
        System.out.println("urlContains: Current URL - " + driver.getCurrentUrl());
    }

    // Example of not-so-common but useful conditions:

    @Test(description = "11. Waits for a specific number of elements to be present")
    public void testNumberOfElementsToBe() {
        driver.get("https://the-internet.herokuapp.com/checkboxes");
        List<WebElement> checkboxes = wait.until(ExpectedConditions.numberOfElementsToBe(By.xpath("//input[@type='checkbox']"), 2));
        assertEquals(checkboxes.size(), 2);
        System.out.println("numberOfElementsToBe: Found " + checkboxes.size() + " checkboxes.");
    }

    @Test(description = "12. Waits for new window to be opened and switch to it")
    public void testNumberOfWindowsToBe() {
        driver.get("https://the-internet.herokuapp.com/windows");
        String originalWindow = driver.getWindowHandle();
        driver.findElement(By.linkText("Click Here")).click();

        // Wait for a new window to open
        wait.until(ExpectedConditions.numberOfWindowsToBe(2));
        Set<String> allWindows = driver.getWindowHandles();
        String newWindow = null;
        for (String windowHandle : allWindows) {
            if (!windowHandle.equals(originalWindow)) {
                newWindow = windowHandle;
                break;
            }
        }
        assertNotNull(newWindow, "New window handle should not be null.");
        driver.switchTo().window(newWindow);
        assertTrue(driver.getCurrentUrl().contains("new"));
        assertEquals(driver.getTitle(), "New Window");
        System.out.println("numberOfWindowsToBe: Switched to new window with title - " + driver.getTitle());

        driver.close(); // Close the new window
        driver.switchTo().window(originalWindow); // Switch back
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
- **Never mix with Implicit Waits:** As mentioned, this leads to unpredictable and longer waits. Prioritize explicit waits.
- **Use granular conditions:** Choose the most specific `ExpectedCondition` for your scenario (e.g., `elementToBeClickable` instead of just `presenceOfElementLocated` if you intend to click it).
- **Keep timeouts reasonable:** Set a timeout that is long enough for the element to appear under normal conditions but not excessively long. Too short causes flakiness; too long wastes time.
- **Catch `TimeoutException`:** When using `WebDriverWait`, be prepared to catch `TimeoutException` if the condition is not met within the specified time. This allows for graceful error handling or custom logging.
- **Reusable Wait Utility:** Encapsulate common explicit wait patterns in reusable utility methods to avoid code duplication and improve maintainability.

## Common Pitfalls
- **Using `Thread.sleep()`:** Avoid `Thread.sleep()` as it's a static wait that pauses execution for a fixed duration, regardless of whether the element is ready sooner or takes longer, making tests slow and flaky.
- **Incorrect `ExpectedCondition`:** Using `presenceOfElementLocated` when you need `elementToBeClickable` can lead to `ElementNotInteractableException` because the element might be in the DOM but not yet ready for interaction.
- **Locating element before waiting:** If you try to locate an element (`driver.findElement(By...)`) *before* applying `wait.until(ExpectedConditions...)`, you might still get a `NoSuchElementException` if the element isn't immediately present. The `ExpectedConditions` methods usually take `By` locators themselves.
- **Ignoring the return value:** `wait.until()` returns the `WebElement` (or other type, like `Alert`) that satisfies the condition. Don't re-find the element after waiting, use the returned element.

## Interview Questions & Answers
1. **Q: Explain Explicit Wait in Selenium and contrast it with Implicit Wait.**
   **A:** Explicit Wait is a type of smart wait that allows WebDriver to pause test execution until a specific condition (defined by `ExpectedConditions`) is met or a maximum timeout occurs. Unlike Implicit Wait, which is a global setting for element presence, Explicit Wait is applied to specific elements or actions and waits for specific states like visibility, clickability, or text changes. Explicit waits offer more control and make tests more stable and efficient by waiting only when necessary and for precise conditions.

2. **Q: What is `WebDriverWait` and `ExpectedConditions` used for? Can you give examples of when to use them?**
   **A:** `WebDriverWait` is a class in Selenium used to implement explicit waits. It allows you to set a maximum timeout. `ExpectedConditions` is a class that provides a set of common conditions to wait for.
   - Example `ExpectedConditions`:
     - `visibilityOfElementLocated(By locator)`: Use when an element appears after some dynamic action (e.g., a success message appearing).
     - `elementToBeClickable(By locator)`: Use before clicking a button or link that might be initially disabled or overlaid.
     - `alertIsPresent()`: Use before trying to interact with a JavaScript alert that might pop up after a certain action.
     - `textToBePresentInElement(WebElement element, String text)`: Use when verifying that dynamic content (like a counter or status message) has updated.

3. **Q: Why is it bad practice to mix Implicit Waits and Explicit Waits?**
   **A:** Mixing Implicit and Explicit Waits can lead to unpredictable and excessively long test execution times. If both are active, WebDriver might apply the Implicit Wait duration multiple times within the polling mechanism of the Explicit Wait. For instance, if an element is not immediately present, the Implicit Wait could repeatedly check for its presence during each polling interval of the Explicit Wait, effectively adding up the waiting times and making the total wait much longer than intended. This makes debugging difficult and obscures the actual wait behavior.

4. **Q: How do you handle a scenario where an element is present in the DOM but not yet interactable (e.g., hidden or disabled)? Which `ExpectedCondition` would you use?**
   **A:** In such a scenario, `presenceOfElementLocated` would not be sufficient because it only waits for the element to be in the DOM, not for it to be interactable. I would use `ExpectedConditions.elementToBeClickable(By locator)` if I need to click the element, or `ExpectedConditions.visibilityOfElementLocated(By locator)` if I only need to see its content, or `ExpectedConditions.elementToBeSelected(WebElement element)` for checkboxes/radio buttons. These conditions ensure the element is not only present but also in a state where it can be interacted with as intended.

## Hands-on Exercise
1. **Explore More `ExpectedConditions`:**
    - Go to `https://the-internet.herokuapp.com/dynamic_controls`.
    - Write a test that:
        - Clicks the "Remove" button.
        - Uses `ExpectedConditions.invisibilityOfElementLocated()` to wait for the checkbox to disappear.
        - Asserts that the checkbox is no longer present.
        - Clicks the "Add" button.
        - Uses `ExpectedConditions.visibilityOfElementLocated()` to wait for the checkbox to reappear.
        - Asserts that the checkbox is present.
2. **Handle Multiple Windows:**
    - Go to `https://the-internet.herokuapp.com/windows`.
    - Click on the "Click Here" link.
    - Use `ExpectedConditions.numberOfWindowsToBe(int count)` to wait for the new window to appear.
    - Switch to the new window and assert its title.
    - Close the new window and switch back to the original.
3. **Verify Text Changes in a Dynamic Element:**
    - Go to `https://www.selenium.dev/documentation/webdriver/elements_interact/`.
    - Find a section where text changes dynamically (you might need to mock this with a local HTML page if a live site doesn't have a clear example).
    - Use `ExpectedConditions.textToBePresentInElement()` to verify the text change.

## Additional Resources
- **Selenium Docs - Waits:** [https://www.selenium.dev/documentation/webdriver/waits/](https://www.selenium.dev/documentation/webdriver/waits/)
- **ExpectedConditions Source Code (for full list and details):** You can often find this in your IDE by navigating to the definition of `ExpectedConditions`.
- **The Internet Herokuapp (various dynamic content examples):** [https://the-internet.herokuapp.com/](https://the-internet.herokuapp.com/)
