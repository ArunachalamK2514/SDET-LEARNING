# Compile-time vs Runtime Polymorphism in Java

## Overview
Polymorphism, meaning "many forms," is one of the fundamental principles of Object-Oriented Programming (OOP). In Java, it allows objects to take on different forms based on the context, enabling more flexible and extensible code. It comes in two main flavors: compile-time polymorphism (also known as static polymorphism or method overloading) and runtime polymorphism (also known as dynamic polymorphism or method overriding). Understanding these concepts is crucial for writing robust and maintainable test automation frameworks.

## Detailed Explanation

### 1. Compile-time Polymorphism (Method Overloading)
Compile-time polymorphism is achieved through method overloading. This occurs when a class has multiple methods with the same name but different parameters (number of parameters, type of parameters, or order of parameters). The Java compiler determines which overloaded method to call at compile time based on the method signature.

**Key Characteristics:**
*   **Method Name:** Same
*   **Parameters:** Different (number, type, or order)
*   **Return Type:** Can be same or different (but not the sole differentiator)
*   **Binding:** Static binding (or early binding) – decided at compile time.

**How it works in Test Automation:**
Method overloading is commonly used to provide flexible ways to interact with elements or perform actions in a test automation framework. For example, a `click()` method might accept different types of locators or coordinates.

### 2. Runtime Polymorphism (Method Overriding)
Runtime polymorphism is achieved through method overriding. This occurs when a subclass provides a specific implementation for a method that is already defined in its superclass. The method must have the same name, same parameters, and same return type (or a covariant return type) as the method in the superclass. The JVM determines which overridden method to call at runtime based on the actual type of the object, not the reference type.

**Key Characteristics:**
*   **Method Name:** Same
*   **Parameters:** Same
*   **Return Type:** Same or covariant
*   **Inheritance:** Requires inheritance (is-a relationship)
*   **Binding:** Dynamic binding (or late binding) – decided at runtime.

**How it works in Test Automation:**
Runtime polymorphism is the backbone of framework design patterns like Page Object Model (POM) and allows for extending and customizing behavior. For example, a `BasePage` class might define a generic `load()` method, and specific page objects (subclasses) can override this method to define their unique navigation logic.

### WebDriver Example (Upcasting)

A classic example of runtime polymorphism in Selenium WebDriver is the following:

```java
WebDriver driver = new ChromeDriver();
```

Here, `WebDriver` is an interface (a form of abstract class in concept) and `ChromeDriver` is a concrete class implementing that interface. The reference variable `driver` is of type `WebDriver`, but the object it points to is an instance of `ChromeDriver`. This is known as **upcasting**.

At compile time, the compiler only knows that `driver` is a `WebDriver`, so it can only see methods defined in the `WebDriver` interface. However, at runtime, the JVM knows that `driver` actually refers to a `ChromeDriver` object, and thus it invokes the `ChromeDriver`'s specific implementations of the `WebDriver` methods (e.g., `get()`, `findElement()`, `quit()` ).

**Benefits of Upcasting:**
1.  **Flexibility:** You can easily switch between different browser implementations (e.g., `FirefoxDriver`, `EdgeDriver`) by changing only the object creation part, without modifying the rest of your code that uses the `driver` object.
2.  **Extensibility:** New browser drivers can be added without affecting existing code.
3.  **Abstraction:** Test scripts interact with a high-level `WebDriver` interface, abstracting away the low-level details of specific browser interactions.
4.  **Maintainability:** Changes to a specific browser's implementation only require modifying its driver class, not all test scripts.

## Code Implementation

### Example of Compile-time Polymorphism (Method Overloading)

```java
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import io.github.bonigarcia.wdm.WebDriverManager;

public class WebElementInteraction {

    private WebDriver driver;

    public WebElementInteraction(WebDriver driver) {
        this.driver = driver;
    }

    // Overloaded method to click by By locator
    public void clickElement(By locator) {
        driver.findElement(locator).click();
        System.out.println("Clicked element by locator: " + locator.toString());
    }

    // Overloaded method to click by WebElement
    public void clickElement(WebElement element) {
        element.click();
        System.out.println("Clicked element: " + element.getTagName() + " with text: " + element.getText());
    }

    // Overloaded method to click by By locator with explicit wait
    public void clickElement(By locator, int timeoutInSeconds) {
        // In a real framework, you'd use WebDriverWait here
        System.out.println("Waiting for " + timeoutInSeconds + " seconds before clicking element by locator: " + locator.toString());
        try {
            Thread.sleep(timeoutInSeconds * 1000L); // Simulate wait
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        driver.findElement(locator).click();
        System.out.println("Clicked element by locator after wait: " + locator.toString());
    }

    public static void main(String[] args) {
        WebDriverManager.chromedriver().setup();
        WebDriver driver = new ChromeDriver();
        driver.get("https://www.google.com"); // Using a simple page for demonstration

        WebElementInteraction interaction = new WebElementInteraction(driver);

        // Usage of overloaded methods
        // Scenario 1: Click using By locator
        interaction.clickElement(By.name("btnK")); // Google Search button

        // Scenario 2: Find element first, then click using WebElement
        WebElement searchButton = driver.findElement(By.name("btnK"));
        interaction.clickElement(searchButton);

        // Scenario 3: Click using By locator with a simulated wait
        // This might fail on Google if the button is not present quickly or if there are multiple,
        // but demonstrates the concept of providing timeout
        // For a more realistic example, this would be used on a dynamically loaded element
        interaction.clickElement(By.xpath("//div[@class='FPdoLc lJ9FBc']//input[@name='btnK']"), 2);


        driver.quit();
    }
}
```

### Example of Runtime Polymorphism (Method Overriding & Upcasting)

```java
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.firefox.FirefoxDriver;
import io.github.bonigarcia.wdm.WebDriverManager;

// --- BasePage (Superclass) ---
class BasePage {
    protected WebDriver driver;
    protected String pageUrl;

    public BasePage(WebDriver driver, String pageUrl) {
        this.driver = driver;
        this.pageUrl = pageUrl;
    }

    // Generic method to navigate to the page
    public void load() {
        System.out.println("Loading generic page: " + pageUrl);
        driver.get(pageUrl);
    }

    public String getPageTitle() {
        return driver.getTitle();
    }
}

// --- LoginPage (Subclass) ---
class LoginPage extends BasePage {
    private static final String LOGIN_PAGE_URL = "https://www.saucedemo.com/";

    public LoginPage(WebDriver driver) {
        super(driver, LOGIN_PAGE_URL);
    }

    // Overriding the load method to provide specific login page behavior
    @Override
    public void load() {
        super.load(); // Call superclass method to navigate
        System.out.println("LoginPage: Navigated to " + LOGIN_PAGE_URL);
        // Additional login page specific actions/verifications can go here
    }

    public void enterUsername(String username) {
        driver.findElement(org.openqa.selenium.By.id("user-name")).sendKeys(username);
        System.out.println("LoginPage: Entered username: " + username);
    }

    public void enterPassword(String password) {
        driver.findElement(org.openqa.selenium.By.id("password")).sendKeys(password);
        System.out.println("LoginPage: Entered password: " + password);
    }

    public InventoryPage clickLoginButton() {
        driver.findElement(org.openqa.selenium.By.id("login-button")).click();
        System.out.println("LoginPage: Clicked Login button.");
        return new InventoryPage(driver); // Returns the next page object
    }
}

// --- InventoryPage (Subclass) ---
class InventoryPage extends BasePage {
    private static final String INVENTORY_PAGE_URL = "https://www.saucedemo.com/inventory.html";

    public InventoryPage(WebDriver driver) {
        super(driver, INVENTORY_PAGE_URL);
    }

    // Overriding load method, though in POM it's more common to have specific navigation
    // for each page, but demonstrating override capability
    @Override
    public void load() {
        super.load();
        System.out.println("InventoryPage: Navigated to " + INVENTORY_PAGE_URL);
        // Verify user is on inventory page, e.g., check for specific elements
        if (!driver.getCurrentUrl().equals(INVENTORY_PAGE_URL)) {
            throw new IllegalStateException("Not on the Inventory Page! Current URL: " + driver.getCurrentUrl());
        }
    }

    public boolean isInventoryPageDisplayed() {
        return driver.getCurrentUrl().equals(INVENTORY_PAGE_URL) &&
               driver.findElement(org.openqa.selenium.By.className("product_label")).isDisplayed();
    }

    public void addFirstItemToCart() {
        driver.findElement(org.openqa.selenium.By.xpath("(//button[text()='Add to cart'])[1]")).click();
        System.out.println("InventoryPage: Added first item to cart.");
    }
}

public class PolymorphismDemo {

    public static void main(String[] args) {
        // Setup WebDriver for Chrome
        WebDriverManager.chromedriver().setup();
        WebDriver chromeDriver = new ChromeDriver();
        runTest(chromeDriver, "Chrome");

        // Setup WebDriver for Firefox (optional, if Firefox is installed)
        // WebDriverManager.firefoxdriver().setup();
        // WebDriver firefoxDriver = new FirefoxDriver();
        // runTest(firefoxDriver, "Firefox");
    }

    private static void runTest(WebDriver driver, String browserName) {
        System.out.println("\n--- Running test on " + browserName + " ---");
        try {
            // Demonstrate upcasting: LoginPage and InventoryPage are treated as BasePage references
            // but their specific overridden methods are called at runtime.
            BasePage loginPage = new LoginPage(driver); // Upcasting
            loginPage.load(); // Calls LoginPage's overridden load()

            LoginPage specificLoginPage = (LoginPage) loginPage; // Downcasting to access specific methods
            specificLoginPage.enterUsername("standard_user");
            specificLoginPage.enterPassword("secret_sauce");
            InventoryPage inventoryPage = specificLoginPage.clickLoginButton(); // Returns InventoryPage

            inventoryPage.load(); // Calls InventoryPage's overridden load()
            if (inventoryPage.isInventoryPageDisplayed()) {
                System.out.println("Test Passed: Successfully logged in and navigated to Inventory Page on " + browserName);
            } else {
                System.err.println("Test Failed: Could not navigate to Inventory Page on " + browserName);
            }

        } catch (Exception e) {
            System.err.println("An error occurred during test execution on " + browserName + ": " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (driver != null) {
                driver.quit();
                System.out.println("Driver quit for " + browserName);
            }
        }
    }
}
```

## Best Practices
-   **Method Overloading:**
    *   Use it to provide convenience methods with varying input parameters for common actions (e.g., `click(By locator)`, `click(WebElement element)`, `click(By locator, int timeout)`).
    *   Ensure overloaded methods perform semantically similar operations to avoid confusion.
-   **Method Overriding:**
    *   Always use the `@Override` annotation to ensure you are indeed overriding a superclass method and to catch potential typos/signature mismatches at compile time.
    *   Use `super.methodName()` to invoke the superclass's implementation where appropriate, especially in Page Object Model `load()` methods or setup/teardown.
    *   Leverage upcasting (`WebDriver driver = new ChromeDriver();`) for maximum flexibility and adherence to the Open/Closed principle (open for extension, closed for modification).
-   **Upcasting:**
    *   Favor programming to an interface (`WebDriver`) rather than an implementation (`ChromeDriver`) for better flexibility and maintainability.
    *   This allows you to swap out underlying implementations (e.g., changing from Chrome to Firefox) with minimal code changes.

## Common Pitfalls
-   **Confusing Overloading and Overriding:** A common mistake is to think that changing the return type alone constitutes overloading (it doesn't, parameters must differ). Or to forget that overriding requires the exact same method signature (except for covariant return types in later Java versions).
-   **Forgetting `@Override`:** Not using `@Override` can lead to subtle bugs where you think you're overriding a method, but you've actually just overloaded it or made a typo, resulting in the superclass method being called unexpectedly.
-   **Downcasting Issues:** While upcasting is generally safe, carelessly downcasting (`ChromeDriver chromeDriver = (ChromeDriver) driver;`) can lead to `ClassCastException` at runtime if the object is not actually an instance of the target class. Only downcast when you are certain of the object's actual type.
-   **Misusing `final` with Polymorphism:**
    *   `final` methods cannot be overridden (compile-time error).
    *   `final` classes cannot be extended (compile-time error), effectively preventing runtime polymorphism for that class.

## Interview Questions & Answers

1.  **Q: Explain the difference between compile-time and runtime polymorphism in Java. Provide an example from a test automation context.**
    *   **A:** Compile-time polymorphism (method overloading) occurs when multiple methods in a class share the same name but have different parameters. The compiler resolves which method to call at compile time. Example: A utility method `clickElement(By locator)` and `clickElement(WebElement element)` in a `CommonActions` class.
        Runtime polymorphism (method overriding) occurs when a subclass provides a specific implementation for a method already defined in its superclass, with the same signature. The JVM resolves which method to call at runtime based on the actual object type. Example: The `WebDriver driver = new ChromeDriver();` statement, where the `WebDriver` reference calls the `ChromeDriver`'s specific implementations of methods like `get()` or `quit()`.
2.  **Q: What are the benefits of using `WebDriver driver = new ChromeDriver();` (upcasting) in Selenium?**
    *   **A:** This is an example of upcasting and runtime polymorphism. The main benefits are:
        *   **Flexibility:** Easily switch browser implementations (e.g., `FirefoxDriver`, `EdgeDriver`) by changing only the object instantiation, without altering the rest of the test code.
        *   **Abstraction:** Tests interact with the generic `WebDriver` interface, abstracting away browser-specific details.
        *   **Maintainability:** Changes to a specific browser's driver implementation don't impact existing test scripts.
        *   **Extensibility:** New browser drivers can be integrated seamlessly.
3.  **Q: When would you use method overloading versus method overriding in a test automation framework?**
    *   **A:** **Method Overloading** is used for providing multiple ways to perform the *same logical action* with different inputs. For example, a `navigateTo(String url)` and `navigateTo(String baseUrl, String path)` method to handle different navigation scenarios.
        **Method Overriding** is used to provide *specific implementations* for a generic action defined in a parent class. This is central to the Page Object Model, where a `BasePage` might have a generic `verifyPageLoaded()` method, and each specific page (subclass) overrides it to perform page-specific validations.

## Hands-on Exercise

1.  **Refactor an existing Page Object:** Take any existing Page Object class from a previous exercise or project.
    *   **Implement Method Overloading:** Create an overloaded method for a common action (e.g., `enterText(By locator, String text)`) that also accepts a `boolean clearBeforeTyping` parameter, clearing the field before typing if `true`.
    *   **Implement Method Overriding:** If you have a `BasePage` and a specific `HomePage`, create a generic `verifyPageTitle(String expectedTitle)` method in `BasePage`. Then, override this method in `HomePage` to also perform a specific assertion unique to the home page (e.g., checking for the presence of a unique header element).
    *   **Demonstrate Upcasting:** In your test class, create an instance of `HomePage` and assign it to a `BasePage` reference variable. Call the `verifyPageTitle` method using the `BasePage` reference and observe that the `HomePage`'s overridden method is executed.

## Additional Resources
-   **GeeksforGeeks - Polymorphism in Java:** [https://www.geeksforgeeks.org/polymorphism-in-java/](https://www.geeksforgeeks.org/polymorphism-in-java/)
-   **Oracle Java Tutorials - Interfaces and Inheritance:** [https://docs.oracle.com/javase/tutorial/java/IandI/](https://docs.oracle.com/javase/tutorial/java/IandI/)
-   **Selenium WebDriver Documentation:** [https://www.selenium.dev/documentation/](https://www.selenium.dev/documentation/)
