# Strategy Pattern for Different Test Execution Strategies

## Overview
The Strategy pattern is a behavioral design pattern that enables selecting an algorithm at runtime. Instead of implementing a single algorithm directly, code receives run-time instructions as to which in a family of algorithms to use. In test automation, this pattern is particularly useful for handling varying test execution flows, such as different login mechanisms (e.g., social login, form-based login, API token login), distinct data setup procedures, or diverse navigation paths within an application. By encapsulating each variation into a separate strategy class, we can switch between them easily without modifying the client code, promoting flexibility, maintainability, and reusability of our test automation framework.

## Detailed Explanation
The Strategy pattern involves three key components:

1.  **Strategy Interface:** This defines a common interface for all supported algorithms. Concrete strategy classes must implement this interface. In our test automation context, this could be an interface like `LoginStrategy` or `DataSetupStrategy`.
2.  **Concrete Strategy Classes:** These implement the Strategy interface, providing the specific algorithm or behavior. For `LoginStrategy`, examples would be `SocialLoginStrategy`, `FormLoginStrategy`, or `ApiTokenLoginStrategy`.
3.  **Context Class:** This class holds a reference to a Strategy object and interacts with it. The Context doesn't know which concrete strategy it's using; it only knows about the Strategy interface. The client configures the Context with a Concrete Strategy object. In test automation, our test classes or page objects could act as the Context.

**How it applies to Test Automation:**
Consider a scenario where your application supports multiple login methods. Without the Strategy pattern, you might end up with `if-else if` statements or large switch cases in your test methods, leading to tightly coupled and hard-to-maintain code.

By using the Strategy pattern:
*   Each login method (e.g., login via Google, login via Facebook, traditional username/password) becomes a concrete strategy.
*   A `LoginContext` (or simply your test class) holds a reference to the `LoginStrategy` interface.
*   At runtime, based on test data or configuration, the appropriate concrete login strategy is injected into the `LoginContext`.
*   The test then calls a generic `login()` method on the `LoginContext`, which delegates the call to the currently set strategy.

This approach makes it easy to add new login methods without altering existing code (Open/Closed Principle) and simplifies test maintenance.

## Code Implementation
Let's illustrate with a Java example for different login strategies using Selenium WebDriver.

```java
// 1. Strategy Interface
public interface LoginStrategy {
    void login(String username, String password);
}

// 2. Concrete Strategy 1: Form-based Login
public class FormLoginStrategy implements LoginStrategy {
    private WebDriver driver;

    public FormLoginStrategy(WebDriver driver) {
        this.driver = driver;
    }

    @Override
    public void login(String username, String password) {
        System.out.println("Executing Form-based Login...");
        driver.findElement(By.id("username")).sendKeys(username);
        driver.findElement(By.id("password")).sendKeys(password);
        driver.findElement(By.id("loginButton")).click();
        System.out.println("Form login successful for user: " + username);
    }
}

// 2. Concrete Strategy 2: Social Login (e.g., Google)
public class SocialLoginStrategy implements LoginStrategy {
    private WebDriver driver;

    public SocialLoginStrategy(WebDriver driver) {
        this.driver = driver;
    }

    @Override
    public void login(String username, String password) {
        System.out.println("Executing Social Login (Google)...");
        driver.findElement(By.id("googleLoginButton")).click();
        // Assume this navigates to Google's login page
        driver.findElement(By.id("identifierId")).sendKeys(username);
        driver.findElement(By.id("identifierNext")).click();
        // Further steps for Google login might involve password and 2FA, simplified here
        // For demonstration, we'll just print.
        System.out.println("Social login initiated for user: " + username);
        // Add assertions or waits for successful social login redirect
    }
}

// 3. Context Class: Test Base or Page Object
public class LoginPage {
    private WebDriver driver;
    private LoginStrategy loginStrategy;

    public LoginPage(WebDriver driver) {
        this.driver = driver;
    }

    // Method to set the strategy dynamically
    public void setLoginStrategy(LoginStrategy loginStrategy) {
        this.loginStrategy = loginStrategy;
    }

    // Method that uses the selected strategy
    public void performLogin(String username, String password) {
        if (loginStrategy == null) {
            throw new IllegalStateException("Login strategy not set. Please call setLoginStrategy() first.");
        }
        loginStrategy.login(username, password);
    }

    // Example of navigating to the login page (common for all strategies)
    public void navigateToLoginPage(String url) {
        driver.get(url);
        System.out.println("Navigated to: " + url);
    }
}

// Client Code (Your Test Class)
public class LoginTest {
    private static WebDriver driver;
    private static LoginPage loginPage;

    @BeforeAll
    static void setup() {
        // Initialize WebDriver (e.g., ChromeDriver)
        // This is a placeholder; in a real scenario, you'd use WebDriverManager or similar
        System.setProperty("webdriver.chrome.driver", "path/to/chromedriver.exe");
        driver = new ChromeDriver();
        driver.manage().window().maximize();
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(10));
        loginPage = new LoginPage(driver);
    }

    @Test
    void testFormLogin() {
        loginPage.navigateToLoginPage("http://your-app-url/login");
        loginPage.setLoginStrategy(new FormLoginStrategy(driver));
        loginPage.performLogin("testuser", "password123");
        // Add assertions to verify successful login
        // Example: Assert.assertTrue(driver.getCurrentUrl().contains("dashboard"));
    }

    @Test
    void testSocialLogin() {
        loginPage.navigateToLoginPage("http://your-app-url/login");
        loginPage.setLoginStrategy(new SocialLoginStrategy(driver));
        loginPage.performLogin("socialuser@gmail.com", "socialpass");
        // Add assertions to verify successful social login redirection/status
    }

    @AfterAll
    static void tearDown() {
        if (driver != null) {
            driver.quit();
        }
    }
}
```

## Best Practices
-   **Keep Strategies Focused:** Each strategy should encapsulate a single algorithm or behavior. Avoid putting unrelated logic into a strategy.
-   **Inject Dependencies:** Pass any required dependencies (like `WebDriver` instance) to the strategy constructors, making them testable and reusable.
-   **Use Factories (Optional but Recommended):** For complex scenarios with many strategies, consider using a Factory pattern to create and manage strategy objects. This can centralize strategy instantiation logic.
-   **Combine with Page Object Model:** Integrate strategies within your Page Object Model. A Page Object can act as the Context, delegating actions to different strategies based on test needs.
-   **Configuration-driven Strategy Selection:** Use external configuration (e.g., properties files, environment variables, test data) to determine which strategy to use, enhancing test flexibility without code changes.

## Common Pitfalls
-   **Over-engineering:** Don't apply the Strategy pattern when a simple `if-else` statement is sufficient for a very limited number of stable variations. The overhead of creating interfaces and multiple classes might not be worth it.
-   **Exposing Internal Strategy Details:** The Context should interact with the Strategy through its interface, not directly with concrete strategy implementations. This maintains loose coupling.
-   **Stateful Strategies:** Be cautious with stateful strategies. If a strategy maintains state, ensure it's managed correctly, especially in parallel test execution, to avoid thread safety issues. Prefer stateless strategies where possible.
-   **Ignoring the Context:** Ensure the Context class provides all necessary data to the strategy to perform its operation, or that the strategy can access it (e.g., via the WebDriver instance).

## Interview Questions & Answers
1.  **Q: What is the Strategy design pattern, and when would you use it in test automation?**
    A: The Strategy pattern defines a family of algorithms, encapsulates each one, and makes them interchangeable. It lets the algorithm vary independently from clients that use it. In test automation, I'd use it when I have multiple ways to perform a specific action (e.g., different login flows, varied data setup methods, distinct ways to interact with a specific UI component) and I want to switch between these methods dynamically without altering the core test logic. It promotes flexibility, maintainability, and avoids conditional logic clutter in test cases.

2.  **Q: How does the Strategy pattern help in maintaining a scalable test automation framework?**
    A: It helps by adhering to the Open/Closed Principle – open for extension, closed for modification. When a new test execution strategy is needed (e.g., a new login method), I only need to create a new concrete strategy class implementing the existing interface, without touching the existing strategies or the Context class. This minimizes the risk of introducing regressions, makes the codebase easier to extend, and allows different team members to work on separate strategies concurrently.

3.  **Q: Can you provide a real-world example of using the Strategy pattern in a Selenium test framework?**
    A: Yes. Imagine testing an e-commerce application that allows users to pay via Credit Card, PayPal, or a Gift Card. Each payment method involves a distinct sequence of actions. I would define a `PaymentStrategy` interface with a `pay(amount)` method. Then, I'd create `CreditCardPaymentStrategy`, `PayPalPaymentStrategy`, and `GiftCardPaymentStrategy` concrete classes, each implementing the `pay` method with its specific logic. My `CheckoutPage` (Context) would have a `setPaymentStrategy()` method and a `performPayment()` method that delegates to the currently set strategy. This way, my tests can simply set the desired payment strategy and call `performPayment()`, making them clean and adaptable to new payment methods.

## Hands-on Exercise
**Scenario:** Your application has a search feature that can be performed in two ways:
1.  **Keyword Search:** Enter text into a search bar and click a search button.
2.  **Advanced Search:** Click an "Advanced Search" link, fill out multiple fields (e.g., category, price range), and click an "Apply Filters" button.

**Task:**
1.  Define a `SearchStrategy` interface with a `performSearch(String query)` method (for keyword search) or `performSearch(Map<String, String> criteria)` (for advanced search). You might need to adjust the method signature or create two distinct strategy interfaces/methods depending on how you model it.
2.  Implement `KeywordSearchStrategy` and `AdvancedSearchStrategy` classes.
3.  Create a `SearchPage` class that acts as the Context, allowing you to set and execute different search strategies.
4.  Write two simple JUnit/TestNG tests: one that performs a keyword search and another that performs an advanced search, demonstrating the use of the Strategy pattern.

## Additional Resources
-   **GeeksforGeeks - Strategy Pattern:** [https://www.geeksforgeeks.org/strategy-pattern-java-design-patterns/](https://www.geeksforgeeks.org/strategy-pattern-java-design-patterns/)
-   **Refactoring Guru - Strategy Pattern:** [https://refactoring.guru/design-patterns/strategy](https://refactoring.guru/design-patterns/strategy)
-   **Baeldung - Strategy Design Pattern in Java:** [https://www.baeldung.com/java-strategy-pattern](https://www.baeldung.com/java-strategy-pattern)
