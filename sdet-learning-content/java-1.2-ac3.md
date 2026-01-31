# OOP Deep Dive: Method Overloading vs. Method Overriding

## Overview
Method overloading and method overriding are two forms of polymorphism in Java that are fundamental to OOP. Though their names are similar, they represent very different concepts. **Overloading** is about having multiple methods with the same name but different parameters in the same class. **Overriding** is about a subclass providing a specific implementation for a method that is already defined in its superclass. For an SDET, using these techniques correctly leads to more flexible, readable, and powerful framework design.

## Method Overloading (Compile-Time Polymorphism)

**Definition**: Method overloading allows you to define multiple methods within the same class that share the same name, as long as their **parameter lists are different**. The difference can be in the number of parameters, the type of parameters, or the order of parameters. The compiler decides which method to call at compile-time based on the arguments passed. This is also known as static polymorphism.

**Why it matters in Test Automation**: Overloading is perfect for creating flexible and convenient utility or page object methods. For example, you can create a `click()` method that can either click a default element or accept a specific element to click.

---

### Example 1: Overloading a `waitFor` Utility Method

A common utility in a test framework is a method to wait for an element. We can overload it to provide different waiting strategies.

```java
public class WaitUtils {

    // 1. Waits for a default timeout period
    public void waitFor(By locator) {
        waitFor(locator, 30); // Calls the other overloaded method
    }

    // 2. Waits for a specific timeout period (different number of parameters)
    public void waitFor(By locator, int timeoutInSeconds) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeoutInSeconds));
        wait.until(ExpectedConditions.visibilityOfElementLocated(locator));
    }
}
```

### Example 2: Overloading an `enterText` Page Object Method

We can provide convenience methods for entering text.

```java
public class SearchPage {
    private By searchBox = By.name("q");

    // 1. Enters text and presses Enter
    public void enterText(String text) {
        WebElement searchElement = driver.findElement(searchBox);
        searchElement.clear();
        searchElement.sendKeys(text);
        searchElement.submit(); // Assumes submission after entering text
    }

    // 2. Enters text but allows choosing whether to submit (different number/type of parameters)
    public void enterText(String text, boolean submitForm) {
        WebElement searchElement = driver.findElement(searchBox);
        searchElement.clear();
        searchElement.sendKeys(text);
        if (submitForm) {
            searchElement.submit();
        }
    }
}
```

### Example 3: Overloading an Assertion Wrapper

Overloading is great for creating custom assertion methods that can handle different data types.

```java
public class CustomAssert {
    
    // 1. Verifies a String value
    public static void verifyEquals(String actual, String expected, String message) {
        Assert.assertEquals(actual, expected, message);
    }
    
    // 2. Verifies an Integer value (different parameter types)
    public static void verifyEquals(int actual, int expected, String message) {
        Assert.assertEquals(actual, expected, message);
    }
}
```

---

## Method Overriding (Run-Time Polymorphism)

**Definition**: Method overriding occurs when a subclass provides a specific implementation for a method that is already defined in its superclass. The method signature (name, parameters, and return type) must be exactly the same. The `@Override` annotation is used to indicate this, and it helps the compiler verify that you are actually overriding a method correctly. The decision on which method to execute (the parent's or the child's) is made at **run-time**. This is also known as dynamic polymorphism.

**Why it matters in Test Automation**: Overriding is essential for creating specialized behavior in subclasses. A `BasePage` might have a generic `isLoaded()` method, but the `HomePage` and `ProductPage` will have very different ways of verifying that they are loaded correctly. Overriding allows each page to define its own specific check.

---

### Example 1: Overriding a Page Verification Method

Each page has a unique element or title that confirms it has loaded successfully.

```java
public abstract class BasePage {
    // ... driver setup ...
    public abstract void isLoaded(); // Force subclasses to define this
}

public class LoginPage extends BasePage {
    private By loginButton = By.id("login-button");

    @Override
    public void isLoaded() {
        // The LoginPage is loaded if the login button is visible
        Assert.assertTrue(driver.findElement(loginButton).isDisplayed());
    }
}

public class InventoryPage extends BasePage {
    private By inventoryContainer = By.id("inventory_container");

    @Override
    public void isLoaded() {
        // The InventoryPage is loaded if the inventory container is visible
        Assert.assertTrue(driver.findElement(inventoryContainer).isDisplayed());
    }
}
```

### Example 2: Overriding a `click` Method for Special Cases

Imagine a base class has a standard `click` method, but one specific type of element on a page needs a special JavaScript click.

```java
public class PageElement {
    public void click(By locator) {
        System.out.println("Performing a standard Selenium click.");
        driver.findElement(locator).click();
    }
}

public class SvgElement extends PageElement {
    // This subclass provides a specialized way to click
    @Override
    public void click(By locator) {
        System.out.println("Performing a special JavaScript click for an SVG element.");
        WebElement element = driver.findElement(locator);
        ((JavascriptExecutor) driver).executeScript("arguments[0].click();", element);
    }
}
```

### Example 3: Overriding `toString()` for Better Logging

Overriding the `toString()` method from the `Object` class is a classic example used for providing more descriptive logs for custom objects.

```java
public class TestData {
    private String username;
    private String password;
    
    // ... constructor and getters ...

    // By default, printing this object would show a useless memory address.
    // We override it to provide meaningful information for our test logs.
    @Override
    public String toString() {
        return "TestData{"
               + "username='" + username + "'" +
               ", password='***'" + // Masking sensitive data
               "}";
    }
}
```

## Comparison Summary

| Feature              | Method Overloading                             | Method Overriding                             |
| :------------------- | :--------------------------------------------- | :-------------------------------------------- |
| **Purpose**          | Use the same method name for different tasks.  | Provide a specific implementation of a parent method. |
| **Location**         | Occurs within the **same class**.              | Occurs between a **superclass and a subclass**. |
| **Parameters**       | Must have **different** parameter lists.       | Must have the **same** parameter list.        |
| **Polymorphism Type**| Compile-Time (Static)                          | Run-Time (Dynamic)                            |
| **Return Type**      | Can be different.                              | Must be the same (or a covariant type).       |
| **Relationship**     | N/A                                            | Governed by an "IS-A" (inheritance) relationship. |

## Interview Questions & Answers
1.  **Q: What is the difference between method overloading and overriding?**
    **A:** Overloading is defining multiple methods in the same class with the same name but different parameters, and it's resolved at compile-time. Overriding is a subclass providing its own implementation of a method from its superclass, with the exact same signature, and it's resolved at run-time.

2.  **Q: Can you overload a method by just changing its return type?**
    **A:** No. The parameter list must be different. The compiler would not be able to determine which method to call based only on the return type.

3.  **Q: Can you override a `private` or `final` method?**
    **A:** No. A `private` method is not visible to subclasses, so it cannot be overridden. A `final` method is explicitly designed to prevent overriding. Attempting to do either will result in a compile-time error.

## Hands-on Exercise
1.  Create a `Logger` utility class for your framework.
2.  **Overload** a `log()` method so that it can be called in three ways:
    -   `log(String message)`: Prints the message with an `[INFO]` prefix.
    -   `log(String message, String level)`: Prints the message with the given level (e.g., `[DEBUG]`, `[ERROR]`) as a prefix.
    -   `log(Exception e)`: Prints the exception's message and stack trace with an `[EXCEPTION]` prefix.
3.  Create a `BaseAnalytics` class with a method `public void trackEvent(String eventName)`.
4.  Create two subclasses, `GoogleAnalytics` and `MixpanelAnalytics`, that both extend `BaseAnalytics`.
5.  **Override** the `trackEvent` method in both subclasses to print a message specific to that analytics service (e.g., "Sending event to Google Analytics: " + eventName).
6.  In a test, create objects of both `GoogleAnalytics` and `MixpanelAnalytics` and call the `trackEvent` method on each to see the overridden behavior.

## Additional Resources
- [Baeldung: Method Overloading vs Overriding](https://www.baeldung.com/java-method-overloading-overriding)
- [GeeksforGeeks: Difference between Method Overloading and Method Overriding in Java](https://www.geeksforgeeks.org/difference-between-method-overloading-and-method-overriding-in-java/)
- [Oracle Java Tutorials: Overriding and Hiding Methods](https://docs.oracle.com/javase/tutorial/java/IandI/override.html)
