# selenium-2.3-ac3: Build custom ExpectedConditions for specific business scenarios

## Overview
While Selenium's `ExpectedConditions` class provides a rich set of predefined conditions for explicit waits, real-world web applications often present unique synchronization challenges. There might be scenarios where an element's readiness depends on a state not covered by standard conditions – for example, an element's background color changing, its opacity reaching a certain value, a specific JavaScript variable becoming true, or a complex AJAX call completing. In such cases, creating **custom `ExpectedConditions`** is invaluable. This allows testers to define precise wait criteria tailored to their application's specific behavior, leading to more robust and less flaky tests.

## Detailed Explanation
A custom `ExpectedCondition` is implemented by creating a class that implements the `ExpectedCondition<T>` interface. This interface requires the implementation of a single method: `apply(WebDriver driver)`.

The `apply()` method is the core of your custom condition. Inside this method, you write the logic to check if your desired condition has been met.
- If the condition is met, the `apply()` method should return a non-null value (usually the `WebElement` itself, a `Boolean` `true`, or any other relevant object). `WebDriverWait` will then immediately proceed with the test.
- If the condition is *not* met, the `apply()` method should return `null` or `false` (depending on the generic type `T`). `WebDriverWait` will continue to poll (re-execute the `apply()` method) until the condition is met or the `WebDriverWait` timeout expires.

**Structure of a Custom Expected Condition:**

```java
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.support.ui.ExpectedCondition;

public class CustomExpectedConditions {

    // Example 1: Wait until an element's background color changes to a specific value
    public static ExpectedCondition<Boolean> backgroundColorChangesTo(By locator, String expectedColor) {
        return new ExpectedCondition<Boolean>() {
            @Override
            public Boolean apply(WebDriver driver) {
                try {
                    String currentColor = driver.findElement(locator).getCssValue("background-color");
                    return currentColor.equals(expectedColor);
                } catch (Exception e) {
                    // Element might not be present yet, or other exceptions during retrieval
                    return false; // Condition not met
                }
            }

            @Override
            public String toString() {
                return String.format("background color of element located by %s to change to %s", locator, expectedColor);
            }
        };
    }

    // Example 2: Wait until an element's opacity reaches 1 (fully visible after fade-in)
    public static ExpectedCondition<WebElement> elementOpacityIs(By locator, String expectedOpacity) {
        return new ExpectedCondition<WebElement>() {
            @Override
            public WebElement apply(WebDriver driver) {
                try {
                    WebElement element = driver.findElement(locator);
                    String currentOpacity = element.getCssValue("opacity");
                    if (currentOpacity.equals(expectedOpacity)) {
                        return element; // Condition met, return the element
                    }
                    return null; // Condition not met
                } catch (Exception e) {
                    return null; // Element not found or other issues
                }
            }

            @Override
            public String toString() {
                return String.format("element located by %s to have opacity %s", locator, expectedOpacity);
            }
        };
    }

    // Example 3: Wait until a specific JavaScript variable has a certain value
    public static ExpectedCondition<Boolean> javaScriptVariableValueIs(String variableName, String expectedValue) {
        return new ExpectedCondition<Boolean>() {
            @Override
            public Boolean apply(WebDriver driver) {
                Object result = ((org.openqa.selenium.JavascriptExecutor) driver)
                        .executeScript("return window." + variableName + ";");
                return result != null && result.toString().equals(expectedValue);
            }

            @Override
            public String toString() {
                return String.format("JavaScript variable '%s' to have value '%s'", variableName, expectedValue);
            }
        };
    }
}
```

## Code Implementation
For demonstrating custom `ExpectedConditions`, we'll create a simple HTML file to simulate the dynamic behavior.

First, create `custom_conditions_test_page.html` in your project root:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Custom ExpectedConditions Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        #dynamicElement {
            width: 100px;
            height: 100px;
            background-color: red;
            margin-top: 20px;
            opacity: 0.1; /* Start mostly transparent */
            transition: background-color 2s, opacity 3s; /* CSS transition for smooth changes */
            border: 1px solid black;
            text-align: center;
            line-height: 100px;
            font-size: 1.2em;
            color: white;
            font-weight: bold;
        }
        #message {
            margin-top: 15px;
            color: gray;
        }
        button {
            padding: 10px 15px;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <h1>Custom ExpectedConditions Demonstration</h1>

    <button id="startButton">Start Animation & JS Var Update</button>
    <div id="dynamicElement">Loading...</div>
    <p id="message">Initial state.</p>

    <script>
        var animationState = "not_started"; // Custom JS variable

        document.getElementById('startButton').onclick = function() {
            document.getElementById('message').textContent = "Animation started...";
            animationState = "started"; // Update JS variable

            var dynamicElement = document.getElementById('dynamicElement');
            // Change background after 3 seconds
            setTimeout(function() {
                dynamicElement.style.backgroundColor = 'blue';
            }, 3000);

            // Change opacity to 1 after 5 seconds
            setTimeout(function() {
                dynamicElement.style.opacity = '1';
                dynamicElement.textContent = 'READY!';
                animationState = "ready"; // Update JS variable
                document.getElementById('message').textContent = "Element ready!";
            }, 5000);
        };
    </script>
</body>
</html>
```

Now, the Java test class:

```java
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.ExpectedCondition;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import io.github.bonigarcia.wdm.WebDriverManager;

import java.time.Duration;

import static org.testng.Assert.*;

public class CustomExpectedConditionsDemo {

    private WebDriver driver;
    private WebDriverWait wait;
    private final Duration TIMEOUT = Duration.ofSeconds(10); // Max wait time
    private final String HTML_FILE_PATH = "file://" + System.getProperty("user.dir") + "/custom_conditions_test_page.html";


    @BeforeMethod
    public void setup() {
        WebDriverManager.chromedriver().setup();
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--start-maximized");
        driver = new ChromeDriver(options);
        wait = new WebDriverWait(driver, TIMEOUT);
        driver.get(HTML_FILE_PATH);
    }

    // Custom ExpectedCondition class (can be nested or in a separate file)
    public static class CustomExpectedConditions {

        /**
         * An expectation for checking that an element's background color has changed to a specific value.
         *
         * @param locator The locator used to find the element.
         * @param expectedColor The expected CSS background-color value (e.g., "rgba(0, 0, 255, 1)").
         * @return true once the condition is met.
         */
        public static ExpectedCondition<Boolean> backgroundColorChangesTo(By locator, String expectedColor) {
            return new ExpectedCondition<Boolean>() {
                @Override
                public Boolean apply(WebDriver driver) {
                    try {
                        String currentColor = driver.findElement(locator).getCssValue("background-color");
                        System.out.println("Current background color for " + locator + ": " + currentColor);
                        return currentColor.equals(expectedColor);
                    } catch (Exception e) {
                        // Element might not be present yet, or other exceptions during retrieval
                        return false; // Condition not met
                    }
                }

                @Override
                public String toString() {
                    return String.format("background color of element located by %s to change to %s", locator, expectedColor);
                }
            };
        }

        /**
         * An expectation for checking that an element's CSS opacity value reaches a specific value.
         * Returns the WebElement once the condition is met.
         *
         * @param locator The locator used to find the element.
         * @param expectedOpacity The expected CSS opacity value (e.g., "1").
         * @return The WebElement once its opacity is the expected value, otherwise null.
         */
        public static ExpectedCondition<WebElement> elementOpacityIs(By locator, String expectedOpacity) {
            return new ExpectedCondition<WebElement>() {
                @Override
                public WebElement apply(WebDriver driver) {
                    try {
                        WebElement element = driver.findElement(locator);
                        String currentOpacity = element.getCssValue("opacity");
                        System.out.println("Current opacity for " + locator + ": " + currentOpacity);
                        if (currentOpacity.equals(expectedOpacity)) {
                            return element; // Condition met, return the element
                        }
                        return null; // Condition not met
                    } catch (Exception e) {
                        return null; // Element not found or other issues, will retry
                    }
                }

                @Override
                public String toString() {
                    return String.format("element located by %s to have opacity %s", locator, expectedOpacity);
                }
            };
        }

        /**
         * An expectation for checking that a specific JavaScript variable in the window scope
         * has a certain string value.
         *
         * @param variableName The name of the JavaScript variable (e.g., "animationState").
         * @param expectedValue The expected string value of the JavaScript variable.
         * @return true once the condition is met.
         */
        public static ExpectedCondition<Boolean> javaScriptVariableValueIs(String variableName, String expectedValue) {
            return new ExpectedCondition<Boolean>() {
                @Override
                public Boolean apply(WebDriver driver) {
                    Object result = ((org.openqa.selenium.JavascriptExecutor) driver)
                            .executeScript("return window." + variableName + ";");
                    System.out.println("Current JS variable '" + variableName + "' value: " + result);
                    return result != null && result.toString().equals(expectedValue);
                }

                @Override
                public String toString() {
                    return String.format("JavaScript variable '%s' to have value '%s'", variableName, expectedValue);
                }
            };
        }
    }

    @Test(description = "Waits for dynamic element's background color to change")
    public void testCustomCondition_BackgroundColor() {
        System.out.println("Starting testCustomCondition_BackgroundColor...");
        driver.findElement(By.id("startButton")).click();

        // Expected color for 'blue' is usually "rgba(0, 0, 255, 1)"
        String expectedBlueColor = "rgba(0, 0, 255, 1)";
        WebElement dynamicElement = driver.findElement(By.id("dynamicElement"));
        System.out.println("Initial background color: " + dynamicElement.getCssValue("background-color"));

        // Use custom ExpectedCondition
        Boolean colorChanged = wait.until(CustomExpectedConditions.backgroundColorChangesTo(By.id("dynamicElement"), expectedBlueColor));
        assertTrue(colorChanged, "Dynamic element's background color did not change to blue.");
        System.out.println("Dynamic element's background color successfully changed to blue.");
    }

    @Test(description = "Waits for dynamic element's opacity to reach 1")
    public void testCustomCondition_ElementOpacity() {
        System.out.println("Starting testCustomCondition_ElementOpacity...");
        driver.findElement(By.id("startButton")).click();

        WebElement dynamicElement = driver.findElement(By.id("dynamicElement"));
        System.out.println("Initial opacity: " + dynamicElement.getCssValue("opacity"));

        // Use custom ExpectedCondition
        WebElement fullyVisibleElement = wait.until(CustomExpectedConditions.elementOpacityIs(By.id("dynamicElement"), "1"));
        assertNotNull(fullyVisibleElement, "Dynamic element did not become fully visible (opacity 1).");
        assertEquals(fullyVisibleElement.getText(), "READY!");
        System.out.println("Dynamic element successfully reached opacity 1 and displayed text: " + fullyVisibleElement.getText());
    }

    @Test(description = "Waits for a JavaScript variable's value to change")
    public void testCustomCondition_JavaScriptVariable() {
        System.out.println("Starting testCustomCondition_JavaScriptVariable...");
        driver.findElement(By.id("startButton")).click();

        // Use custom ExpectedCondition to wait for JS variable 'animationState' to become "ready"
        Boolean jsVarReady = wait.until(CustomExpectedConditions.javaScriptVariableValueIs("animationState", "ready"));
        assertTrue(jsVarReady, "JavaScript variable 'animationState' did not become 'ready'.");
        System.out.println("JavaScript variable 'animationState' successfully set to 'ready'.");
        // Also verify the element's text as a secondary check
        assertEquals(driver.findElement(By.id("dynamicElement")).getText(), "READY!");
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
- **Make them reusable:** Design custom conditions generically (taking `By` locators, expected values, etc.) so they can be reused across different tests and parts of your framework.
- **Provide meaningful `toString()`:** Implement the `toString()` method in your anonymous `ExpectedCondition` class. This provides useful information in `TimeoutException` messages, making debugging much easier.
- **Handle `NoSuchElementException` gracefully:** Inside `apply()`, ensure you handle cases where `driver.findElement(locator)` might initially fail (element not present yet). Returning `null` or `false` in such cases will instruct `WebDriverWait` to continue polling. Wrap the logic in a `try-catch` block.
- **Avoid complex assertions inside `apply()`:** The `apply()` method should primarily focus on checking the condition. Leave actual test assertions (like `assertEquals`, `assertTrue`) to your `@Test` methods.
- **Keep them focused:** Each custom condition should ideally check for one specific, well-defined state.

## Common Pitfalls
- **Not handling `NoSuchElementException` in `apply()`:** If `findElement()` throws `NoSuchElementException` inside your `apply()` method without being caught, it will immediately fail the `WebDriverWait` instead of continuing to poll. This makes it behave like `findElement()` without a wait.
- **Returning `true` too early:** Ensure your condition genuinely reflects the desired state. For example, if you want an element to be both visible and have specific text, just checking visibility isn't enough.
- **Over-complicating `apply()`:** Avoid putting too much complex logic or side effects inside `apply()`. It's meant for state checking, not for performing actions.
- **Ignoring return values:** Always use the return value of `wait.until()` in your assertions or subsequent actions. This is often the `WebElement` itself or a `Boolean` indicating success.
- **Not implementing `toString()`:** This doesn't cause functional errors, but it makes debugging `TimeoutException`s incredibly frustrating as you won't know what condition the wait was waiting for.

## Interview Questions & Answers
1. **Q: When would you need to create a custom `ExpectedCondition` in Selenium?**
   **A:** I would create a custom `ExpectedCondition` when none of the predefined `ExpectedConditions` in Selenium adequately cover a specific synchronization requirement of the application under test. This is common for unique UI behaviors such as:
     - Waiting for a CSS property (like background color, opacity, font size) to change to a specific value.
     - Waiting for a specific JavaScript variable or function return value to meet a condition.
     - Waiting for an element to contain a particular number of child elements.
     - Waiting for an SVG element attribute to change.
     - Complex AJAX completion indicators not tied to a simple element state.

2. **Q: How do you implement a custom `ExpectedCondition`? What method is crucial?**
   **A:** To implement a custom `ExpectedCondition`, you create a new class (often an anonymous inner class) that implements the `org.openqa.selenium.support.ui.ExpectedCondition<T>` interface, where `T` is the return type of the condition. The crucial method to implement is `public T apply(WebDriver driver)`. Inside `apply()`, you write the logic to check if the condition is met. If met, return a non-null value (e.g., `true` or the `WebElement`); otherwise, return `null` or `false`.

3. **Q: What are the benefits of using custom `ExpectedConditions` over just `Thread.sleep()` or a series of generic waits?**
   **A:** Custom `ExpectedConditions` offer several significant benefits:
     - **Increased Robustness:** They wait for a precise state to be achieved, making tests less susceptible to timing issues and flakiness due to varying network speeds or application performance.
     - **Improved Readability:** A well-named custom condition like `backgroundColorChangesTo` clearly expresses the intent of the wait, improving code understanding.
     - **Efficiency:** Unlike `Thread.sleep()`, they wait only as long as necessary, speeding up test execution.
     - **Maintainability:** Encapsulating complex wait logic into a reusable custom condition reduces code duplication and simplifies maintenance.
     - **Debugging:** With a good `toString()` implementation, `TimeoutException` messages are much more informative.

4. **Q: What should you return from the `apply()` method if your custom condition is not met, and what if it is met?**
   **A:**
     - If the custom condition is **not met**, the `apply()` method should return `null` (if the generic type `T` is an object, like `WebElement`) or `false` (if `T` is `Boolean`). This signals to `WebDriverWait` to continue polling.
     - If the custom condition **is met**, the `apply()` method should return a non-null value that signifies success. This could be `true` (if `T` is `Boolean`), the `WebElement` that satisfied the condition, or any other relevant object. `WebDriverWait` will then stop polling and return this value.

## Hands-on Exercise
1. **Implement `textChangeInElement(By locator, String initialText)`:**
    - Create a custom `ExpectedCondition` that waits for the text of an element identified by `locator` to *not* be equal to `initialText`. This is useful for dynamic updates.
    - Test it on a page where a paragraph's text changes after a button click (e.g., our `custom_conditions_test_page.html` with the `#message` paragraph).
2. **Implement `elementHasClass(By locator, String className)`:**
    - Create a custom `ExpectedCondition` that waits for an element to acquire a specific CSS class.
    - Modify the `custom_conditions_test_page.html` to add a class (e.g., `fade-in-complete`) to `#dynamicElement` when its opacity reaches 1. Then use your custom condition to wait for this class.
3. **Implement `countOfElementsToBeLessThan(By locator, int count)`:**
    - Create a custom `ExpectedCondition` that waits for the number of elements matching a locator to be less than a given count. This can be useful for waiting for elements to disappear or be filtered out.

## Additional Resources
- **Selenium Docs - Waits:** [https://www.selenium.dev/documentation/webdriver/waits/](https://www.selenium.dev/documentation/webdriver/waits/)
- **WebDriverWait Javadoc:** [https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/support/ui/WebDriverWait.html](https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/support/ui/WebDriverWait.html)
- **ExpectedCondition Javadoc:** [https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/support/ui/ExpectedCondition.html](https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/support/ui/ExpectedCondition.html)
