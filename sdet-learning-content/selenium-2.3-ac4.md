# selenium-2.3-ac4: Implement Fluent Wait with custom polling intervals and ignored exceptions

## Overview
**Fluent Wait** is an advanced and highly flexible synchronization mechanism in Selenium WebDriver. While `WebDriverWait` (Explicit Wait) waits for a specific condition to become true within a given timeout, Fluent Wait extends this control by allowing you to define not only the maximum waiting time but also the frequency with which the WebDriver checks the condition (polling interval) and which exceptions to ignore during the polling process. This makes Fluent Wait exceptionally powerful for handling elements that might appear or disappear intermittently or take an unpredictable amount of time to load.

## Detailed Explanation
Fluent Wait is implemented using the `FluentWait` class, which takes a `WebDriver` instance as an argument. You then configure several parameters to precisely control its behavior:

1.  **`withTimeout(Duration timeout)`**: Specifies the maximum amount of time to wait for a condition to be met. If the condition is not met within this duration, a `TimeoutException` is thrown.
2.  **`pollingEvery(Duration interval)`**: Defines how frequently the condition will be evaluated. For example, if you set `pollingEvery(Duration.ofSeconds(1))`, the condition will be checked every second.
3.  **`ignoring(Class<? extends Throwable>... types)`**: Allows you to specify exceptions that should be ignored during the polling process. This is particularly useful for `NoSuchElementException`, which might occur while the element is not yet present but is expected to appear. Instead of failing immediately, the Fluent Wait will simply continue polling.

**How it works:**
Fluent Wait works by continuously applying the condition to the WebDriver instance. If the condition evaluates to `null` or `false` (depending on the type of `ExpectedCondition` used), and if the exception thrown is one of the ignored exceptions, Fluent Wait will pause for the specified polling interval and then re-evaluate the condition. This process continues until the condition returns a non-null/true value, or the timeout is reached (resulting in a `TimeoutException`).

**Advantages of Fluent Wait:**
-   **Fine-grained Control:** Offers the highest level of control over waiting strategy.
-   **Handles Intermittent Elements:** Ideal for elements that load slowly, appear and disappear, or have unpredictable loading times.
-   **Reduces Flakiness:** By ignoring expected transient exceptions, tests become more stable against temporary DOM changes.
-   **Efficiency:** Waits only as long as necessary, similar to explicit waits, but with more configurable polling.

## Code Implementation
For this example, we'll use `https://the-internet.herokuapp.com/dynamic_loading/1` again, but this time, we'll configure Fluent Wait to ignore `NoSuchElementException` while polling for the dynamically appearing "Hello World!" message.

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
import org.openqa.selenium.By;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.FluentWait;
import org.openqa.selenium.support.ui.Wait;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import io.github.bonigarcia.wdm.WebDriverManager;

import java.time.Duration;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;
import static org.testng.Assert.assertTrue;
import static org.testng.Assert.fail;

public class FluentWaitDemo {

    private WebDriver driver;
    private Wait<WebDriver> fluentWait; // Use the generic Wait interface

    @BeforeMethod
    public void setup() {
        WebDriverManager.chromedriver().setup();
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--start-maximized");
        driver = new ChromeDriver(options);

        // --- Configure Fluent Wait ---
        fluentWait = new FluentWait<>(driver)
                .withTimeout(Duration.ofSeconds(15))          // Maximum wait time
                .pollingEvery(Duration.ofMillis(500))         // Check condition every 500 milliseconds
                .ignoring(NoSuchElementException.class);      // Ignore NoSuchElementException during polling

        // We will use a dynamic loading page where an element appears after a delay
        driver.get("https://the-internet.herokuapp.com/dynamic_loading/1"); // Element hidden but eventually appears
    }

    @Test(description = "Demonstrates Fluent Wait successfully finding an element after a delay")
    public void testFluentWaitSuccess() {
        System.out.println("Starting testFluentWaitSuccess...");

        // Click the start button to initiate element loading
        driver.findElement(By.cssSelector("#start button")).click();

        By finishMessageLocator = By.cssSelector("#finish h4");

        try {
            // Use Fluent Wait to wait for the visibility of the element
            WebElement finishMessage = fluentWait.until(ExpectedConditions.visibilityOfElementLocated(finishMessageLocator));

            assertNotNull(finishMessage, "Finish message element should not be null.");
            assertTrue(finishMessage.isDisplayed(), "Finish message should be displayed.");
            assertEquals(finishMessage.getText(), "Hello World!", "Finish message text mismatch.");

            System.out.println("Fluent Wait successful: Found element with text '" + finishMessage.getText() + "'");

        } catch (org.openqa.selenium.TimeoutException e) {
            fail("Fluent Wait timed out waiting for the element: " + e.getMessage());
        } catch (Exception e) {
            fail("An unexpected error occurred: " + e.getMessage());
        }
    }

    @Test(description = "Demonstrates Fluent Wait timing out for a non-existent element")
    public void testFluentWaitFailure() {
        System.out.println("Starting testFluentWaitFailure (expecting TimeoutException)...");

        // We don't click anything, so the expected element will never appear
        By nonExistentElementLocator = By.id("thisElementDoesNotExist");

        long startTime = System.currentTimeMillis();
        try {
            // Fluent Wait will poll for 15 seconds, ignoring NoSuchElementException,
            // but will eventually throw TimeoutException as the element is never found.
            fluentWait.until(ExpectedConditions.presenceOfElementLocated(nonExistentElementLocator));
            fail("Fluent Wait should have thrown TimeoutException for non-existent element.");
        } catch (org.openqa.selenium.TimeoutException e) {
            long endTime = System.currentTimeMillis();
            long duration = (endTime - startTime) / 1000; // in seconds
            System.out.println("Caught expected TimeoutException after approx " + duration + " seconds.");
            // Verify that it waited for almost the full timeout duration
            assertTrue(duration >= 14, "Fluent Wait did not wait for expected duration before timing out.");
            assertTrue(e.getMessage().contains("Expected condition failed"), "TimeoutException message incorrect.");
        } catch (Exception e) {
            fail("Caught unexpected exception: " + e.getMessage());
        }
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
-   **Specific Use Cases:** Reserve Fluent Wait for elements that have highly unpredictable loading times or are prone to appearing and disappearing temporarily in the DOM (e.g., dynamic content, loading spinners that replace content).
-   **Sensible Polling Interval:** A polling interval of 250ms to 500ms is usually a good starting point. Too frequent polling can increase CPU usage; too infrequent can delay test execution.
-   **Ignored Exceptions:** Always use `ignoring(NoSuchElementException.class)` when waiting for an element to appear, as this exception is expected when the element isn't immediately found. You can ignore multiple exception types if needed (e.g., `ignoring(NoSuchElementException.class, StaleElementReferenceException.class)`).
-   **Avoid Mixing:** As with `WebDriverWait`, do not mix Fluent Wait with Implicit Waits. It will lead to unnecessary delays and confusing behavior.
-   **Clarity in Conditions:** Pair Fluent Wait with clear and concise `ExpectedConditions` (either built-in or custom) to ensure you are waiting for the correct state.

## Common Pitfalls
-   **Too Short Polling Interval:** If the polling interval is too short, and your application is very slow, Fluent Wait might spam the DOM with checks, potentially impacting performance or causing other issues.
-   **Not Ignoring `NoSuchElementException`:** If you don't ignore `NoSuchElementException` when waiting for an element that might not be immediately present, the Fluent Wait will fail prematurely the first time `findElement()` is called and the element is not there, defeating its purpose.
-   **Long Timeout for Simple Waits:** Using Fluent Wait with a very long timeout and frequent polling for elements that typically appear quickly is inefficient. Standard `WebDriverWait` might be sufficient.
-   **Over-complicating Conditions:** While flexible, avoid overly complex logic within your `ExpectedCondition` used with Fluent Wait. Keep the condition check lean and focused.
-   **Misunderstanding `Wait<T>`:** Remember that `FluentWait` implements the `Wait<T>` interface. When declaring your variable, `Wait<WebDriver> fluentWait;` is good practice, or simply `FluentWait<WebDriver> fluentWait;`.

## Interview Questions & Answers
1.  **Q: What is Fluent Wait in Selenium WebDriver, and how does it differ from Explicit Wait (`WebDriverWait`)?**
    **A:** Fluent Wait is an advanced type of explicit wait in Selenium that provides more granular control over the waiting mechanism. While both Fluent Wait and `WebDriverWait` allow waiting for a condition to be met within a maximum timeout, Fluent Wait adds the ability to specify a `pollingEvery` interval (how often to check the condition) and to `ignoring` specific exceptions during the polling. This is useful for elements that might appear and disappear frequently or have highly unpredictable loading times.

2.  **Q: Explain the key configurable parameters of Fluent Wait and provide a scenario where each is essential.**
    **A:**
    -   **`withTimeout(Duration timeout)`**: The maximum time the wait will endure before throwing a `TimeoutException`. Essential for preventing infinite loops in tests.
    -   **`pollingEvery(Duration interval)`**: The frequency at which the condition is checked. Essential for optimizing performance – too frequent can be CPU-intensive, too infrequent can delay detection.
    -   **`ignoring(Class<? extends Throwable>... types)`**: A list of exceptions to ignore during the polling process. Essential when waiting for an element that might not be immediately present, so `NoSuchElementException` can be ignored until the element finally appears.

3.  **Q: Why would you choose Fluent Wait over standard `WebDriverWait` for a particular scenario?**
    **A:** I would choose Fluent Wait when dealing with elements that exhibit highly dynamic or asynchronous behavior, making their appearance or state transition unpredictable. Specifically:
    -   When elements might momentarily disappear from the DOM and reappear (e.g., complex animations, loading spinners).
    -   When the default polling interval of `WebDriverWait` (which is usually 500ms but not directly configurable without `FluentWait`) is either too slow or too fast for the application's responsiveness.
    -   When specific transient exceptions (like `NoSuchElementException` or `StaleElementReferenceException`) are expected during the intermediate polling attempts, and I want to gracefully handle them without failing the wait immediately.

4.  **Q: What happens if you forget to use `ignoring(NoSuchElementException.class)` with Fluent Wait when waiting for a dynamically appearing element?**
    **A:** If `ignoring(NoSuchElementException.class)` is not used, and the element is not immediately present in the DOM when Fluent Wait first attempts to `findElement()` it, a `NoSuchElementException` will be immediately thrown, and the Fluent Wait will fail. It won't continue polling as intended because it doesn't know to suppress that specific exception. This effectively negates one of the primary benefits of Fluent Wait for dynamic element handling.

## Hands-on Exercise
1.  **Modify Polling Interval:**
    -   Take the provided `FluentWaitDemo` example.
    -   Change the `pollingEvery` duration to `Duration.ofSeconds(1)`.
    -   Run the test and observe if there's any noticeable difference in execution speed or behavior (e.g., console output frequency).
    -   Then change it to `Duration.ofMillis(100)` and observe again.
2.  **Ignore `StaleElementReferenceException`:**
    -   Create a new test case.
    -   Navigate to a page with dynamic content that frequently refreshes a specific element (e.g., a live update feed or a constantly re-rendered component).
    -   Try to interact with this element repeatedly within a loop, without any waits, and observe `StaleElementReferenceException`.
    -   Now, use Fluent Wait with `ignoring(StaleElementReferenceException.class)` and an `ExpectedCondition` (e.g., `ExpectedConditions.elementToBeClickable`) to interact with this flaky element. Verify if the test becomes more stable. (Note: Simulating `StaleElementReferenceException` requires a complex enough HTML/JS setup or a known flaky website).
3.  **Combine Ignored Exceptions:**
    -   Configure a Fluent Wait instance that ignores both `NoSuchElementException` and `StaleElementReferenceException`.
    -   Think of a hypothetical scenario where an element might initially not be present, and then, once found, might become stale due to a partial page refresh before you can interact with it.

## Additional Resources
-   **Selenium Docs - Waits:** [https://www.selenium.dev/documentation/webdriver/waits/](https://www.selenium.dev/documentation/webdriver/waits/)
-   **FluentWait Javadoc:** [https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/support/ui/FluentWait.html](https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/support/ui/FluentWait.html)
-   **The Internet Herokuapp (dynamic loading examples):** [https://the-internet.herokuapp.com/dynamic_loading](https://the-internet.herokuapp.com/dynamic_loading)
