# Page Object Model (POM) in Test Automation

## Overview
The Page Object Model (POM) is a design pattern widely used in test automation, especially for web UI testing. It helps in creating an object repository for web UI elements within an application. Each web page in the application is represented as a class, and the elements on that page are defined as variables within the class. Methods are then created to interact with these elements. This approach makes tests more readable, maintainable, and reduces code duplication.

**Why POM matters:**
- **Maintainability:** If the UI changes, only the page object class needs to be updated, not every test case that uses that element.
- **Readability:** Test scripts become cleaner and easier to understand as they interact with page methods (e.g., `loginPage.login("user", "pass")`) rather than directly manipulating elements.
- **Reusability:** Page object methods can be reused across multiple test cases, reducing code duplication.
- **Separation of Concerns:** Clearly separates test logic from page-specific element interactions.

## Detailed Explanation
In the Page Object Model, each significant web page or a major component (like a header, footer, or complex form) of your application under test should have a corresponding "Page Object" class.

**Key components of a Page Object class:**

1.  **`WebElements` as private fields:** These fields represent the interactive elements on the page (buttons, text fields, links, etc.). They are typically made `private` to encapsulate the page's structure and are often initialized using annotations like `@FindBy` provided by Selenium's PageFactory.
2.  **Public methods for interaction:** These methods perform actions on the `WebElements` (e.g., `enterUsername()`, `clickLoginButton()`, `verifyErrorMessage()`). These methods should return either `void` (if the action stays on the same page or navigates to a non-page-object-represented state) or another Page Object (if the action navigates to a new page).
3.  **Constructor:** The constructor typically initializes the `WebElements` using `PageFactory.initElements(driver, this)`.

**Example Scenario:**
Consider a login page. Without POM, a test might directly find and interact with elements:
```java
driver.findElement(By.id("username")).sendKeys("testuser");
driver.findElement(By.id("password")).sendKeys("password");
driver.findElement(By.id("loginButton")).click();
```

With POM, you would have a `LoginPage` class:
```java
public class LoginPage {
    // ... elements and methods ...
}
```
And your test would look like:
```java
LoginPage loginPage = new LoginPage(driver);
loginPage.login("testuser", "password");
```
This makes the test much more concise and robust.

## Code Implementation

Let's implement a simplified POM for a hypothetical e-commerce application with 5 page classes:
1.  `LoginPage`
2.  `HomePage`
3.  `ProductPage`
4.  `CartPage`
5.  `CheckoutPage`

**Project Structure:**
```
src/main/java/
└── com/example/pom/
    ├── pages/
    │   ├── LoginPage.java
    │   ├── HomePage.java
    │   ├── ProductPage.java
    │   ├── CartPage.java
    │   └── CheckoutPage.java
    └── tests/
        └── ECommerceTests.java
```

**`pom.xml` (Maven Dependencies):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>ECommerceAutomation</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <selenium.version>4.17.0</selenium.version>
        <testng.version>7.8.0</testng.version>
    </properties>

    <dependencies>
        <!-- Selenium WebDriver -->
        <dependency>
            <groupId>org.seleniumhq.selenium</groupId>
            <artifactId>selenium-java</artifactId>
            <version>${selenium.version}</version>
        </dependency>
        <!-- TestNG -->
        <dependency>
            <groupId>org.testng</groupId>
            <artifactId>testng</artifactId>
            <version>${testng.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

</project>
```

**`src/main/java/com/example/pom/pages/LoginPage.java`**
```java
package com.example.pom.pages;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.PageFactory;

public class LoginPage {
    private WebDriver driver;

    // WebElements defined using @FindBy
    @FindBy(id = "username")
    private WebElement usernameInput;

    @FindBy(id = "password")
    private WebElement passwordInput;

    @FindBy(id = "loginButton")
    private WebElement loginButton;

    @FindBy(className = "error-message")
    private WebElement errorMessage;

    // Constructor to initialize elements using PageFactory
    public LoginPage(WebDriver driver) {
        this.driver = driver;
        PageFactory.initElements(driver, this);
    }

    // Public methods to interact with elements
    public HomePage login(String username, String password) {
        usernameInput.sendKeys(username);
        passwordInput.sendKeys(password);
        loginButton.click();
        // Assuming successful login navigates to HomePage
        return new HomePage(driver);
    }

    public void attemptLogin(String username, String password) {
        usernameInput.sendKeys(username);
        passwordInput.sendKeys(password);
        loginButton.click();
    }

    public String getErrorMessage() {
        return errorMessage.getText();
    }

    public boolean isLoginPageDisplayed() {
        return loginButton.isDisplayed();
    }
}
```

**`src/main/java/com/example/pom/pages/HomePage.java`**
```java
package com.example.pom.pages;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.PageFactory;

public class HomePage {
    private WebDriver driver;

    @FindBy(id = "welcomeMessage")
    private WebElement welcomeMessage;

    @FindBy(css = ".nav-link[href='/products']")
    private WebElement productsLink;

    @FindBy(css = ".nav-link[href='/cart']")
    private WebElement cartLink;

    public HomePage(WebDriver driver) {
        this.driver = driver;
        PageFactory.initElements(driver, this);
    }

    public String getWelcomeMessage() {
        return welcomeMessage.getText();
    }

    public ProductPage navigateToProducts() {
        productsLink.click();
        return new ProductPage(driver);
    }

    public CartPage navigateToCart() {
        cartLink.click();
        return new CartPage(driver);
    }

    public boolean isHomePageDisplayed() {
        return welcomeMessage.isDisplayed();
    }
}
```

**`src/main/java/com/example/pom/pages/ProductPage.java`**
```java
package com.example.pom.pages;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.PageFactory;

import java.util.List;

public class ProductPage {
    private WebDriver driver;

    @FindBy(css = ".product-item")
    private List<WebElement> productList;

    @FindBy(xpath = "//div[@class='product-item'][1]//button[contains(text(),'Add to Cart')]")
    private WebElement firstProductAddToCartButton; // Example for a specific product

    @FindBy(id = "searchProductInput")
    private WebElement searchProductInput;

    @FindBy(id = "searchProductButton")
    private WebElement searchProductButton;

    public ProductPage(WebDriver driver) {
        this.driver = driver;
        PageFactory.initElements(driver, this);
    }

    public int getNumberOfProducts() {
        return productList.size();
    }

    public void addFirstProductToCart() {
        firstProductAddToCartButton.click();
    }

    public CartPage searchAndAddToCart(String productName) {
        // This method would typically involve searching, finding the product, and then adding it.
        // For simplicity, let's assume it directly leads to the cart after an action.
        searchProductInput.sendKeys(productName);
        searchProductButton.click();
        // Assuming a product details page or direct add to cart confirmation
        // For this example, we'll simulate adding to cart and navigating to CartPage
        addFirstProductToCart(); // Assuming the searched product becomes the "first product"
        return new CartPage(driver);
    }

    public boolean isProductPageDisplayed() {
        return !productList.isEmpty(); // Or check for search input, etc.
    }
}
```

**`src/main/java/com/example/pom/pages/CartPage.java`**
```java
package com.example.pom.pages;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.PageFactory;

import java.util.List;

public class CartPage {
    private WebDriver driver;

    @FindBy(css = ".cart-item")
    private List<WebElement> cartItems;

    @FindBy(id = "totalPrice")
    private WebElement totalPrice;

    @FindBy(id = "checkoutButton")
    private WebElement checkoutButton;

    public CartPage(WebDriver driver) {
        this.driver = driver;
        PageFactory.initElements(driver, this);
    }

    public int getNumberOfItemsInCart() {
        return cartItems.size();
    }

    public String getTotalPrice() {
        return totalPrice.getText();
    }

    public CheckoutPage proceedToCheckout() {
        checkoutButton.click();
        return new CheckoutPage(driver);
    }

    public boolean isCartPageDisplayed() {
        return checkoutButton.isDisplayed();
    }
}
```

**`src/main/java/com/example/pom/pages/CheckoutPage.java`**
```java
package com.example.pom.pages;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.PageFactory;

public class CheckoutPage {
    private WebDriver driver;

    @FindBy(id = "shippingAddress")
    private WebElement shippingAddressInput;

    @FindBy(id = "paymentMethod")
    private WebElement paymentMethodDropdown; // Could be a Select element

    @FindBy(id = "confirmOrderButton")
    private WebElement confirmOrderButton;

    @FindBy(className = "order-confirmation-message")
    private WebElement orderConfirmationMessage;

    public CheckoutPage(WebDriver driver) {
        this.driver = driver;
        PageFactory.initElements(driver, this);
    }

    public void enterShippingAddress(String address) {
        shippingAddressInput.sendKeys(address);
    }

    public void selectPaymentMethod(String method) {
        // For simplicity, assuming a text input or direct click,
        // in a real scenario, you'd interact with a dropdown (Select class).
        paymentMethodDropdown.sendKeys(method); // Example: sends text to a faux dropdown
    }

    public void confirmOrder() {
        confirmOrderButton.click();
    }

    public String getOrderConfirmationMessage() {
        return orderConfirmationMessage.getText();
    }

    public boolean isCheckoutPageDisplayed() {
        return confirmOrderButton.isDisplayed();
    }
}
```

**`src/test/java/com/example/pom/tests/ECommerceTests.java`**
```java
package com.example.pom.tests;

import com.example.pom.pages.*;
import io.github.bonigarcia.wdm.WebDriverManager;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.time.Duration;

public class ECommerceTests {
    private WebDriver driver;

    @BeforeMethod
    public void setup() {
        WebDriverManager.chromedriver().setup();
        driver = new ChromeDriver();
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(10));
        driver.manage().window().maximize();
        driver.get("http://your-ecommerce-app.com/login"); // Replace with your actual app URL
    }

    @Test
    public void testSuccessfulPurchaseWorkflow() {
        // Test only interacts with Page Object methods, not elements directly

        LoginPage loginPage = new LoginPage(driver);
        Assert.assertTrue(loginPage.isLoginPageDisplayed(), "Login page is not displayed.");

        HomePage homePage = loginPage.login("testuser", "testpassword");
        Assert.assertTrue(homePage.isHomePageDisplayed(), "Home page is not displayed after login.");
        Assert.assertEquals(homePage.getWelcomeMessage(), "Welcome, testuser!", "Welcome message is incorrect.");

        ProductPage productPage = homePage.navigateToProducts();
        Assert.assertTrue(productPage.isProductPageDisplayed(), "Product page is not displayed.");
        productPage.addFirstProductToCart(); // Adding first product

        CartPage cartPage = new CartPage(driver); // Assuming adding to cart redirects or refreshes to cart
        Assert.assertTrue(cartPage.isCartPageDisplayed(), "Cart page is not displayed.");
        Assert.assertTrue(cartPage.getNumberOfItemsInCart() > 0, "Cart should contain items.");
        System.out.println("Total price in cart: " + cartPage.getTotalPrice());

        CheckoutPage checkoutPage = cartPage.proceedToCheckout();
        Assert.assertTrue(checkoutPage.isCheckoutPageDisplayed(), "Checkout page is not displayed.");
        checkoutPage.enterShippingAddress("123 Test St, Test City");
        checkoutPage.selectPaymentMethod("Credit Card"); // Placeholder for actual interaction
        checkoutPage.confirmOrder();

        Assert.assertTrue(checkoutPage.getOrderConfirmationMessage().contains("Order Placed Successfully"),
                "Order confirmation message is missing or incorrect.");
        System.out.println("Order Confirmation: " + checkoutPage.getOrderConfirmationMessage());
    }

    @Test
    public void testLoginFailure() {
        LoginPage loginPage = new LoginPage(driver);
        loginPage.attemptLogin("invaliduser", "wrongpass");
        Assert.assertTrue(loginPage.getErrorMessage().contains("Invalid credentials"),
                "Error message for invalid login is not displayed or incorrect.");
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
-   **One Page Object per Web Page/Major Component:** Keep page objects focused on a single logical unit of the UI.
-   **Encapsulation:** All WebElements should be `private`. Interactions should happen only through public methods.
-   **Readable Method Names:** Method names should clearly describe the action they perform (e.g., `enterUsername`, `clickLoginButton`, `verifyLoginSuccess`).
-   **Return Type of Methods:** Methods that result in navigation to a new page should return an instance of the new Page Object. Methods that stay on the same page or perform an action without navigation can return `void` or `this` (for chaining).
-   **Avoid Assertions in Page Objects:** Page Objects should represent the state and behavior of a page, not contain test-specific assertions. Assertions belong in the test classes.
-   **Use `PageFactory`:** Leverage `PageFactory.initElements()` for automatic initialization of WebElements with `@FindBy` annotations, reducing boilerplate code.
-   **Abstract Base Page (Optional but Recommended):** For common elements (like header, footer, navigation) or common functionalities (like waiting strategies) across multiple pages, create an abstract base class that other page objects can extend.

## Common Pitfalls
-   **Putting Assertions in Page Objects:** This violates the separation of concerns, making page objects less reusable and harder to maintain.
-   **Directly Exposing WebElements:** Making WebElements public defeats the purpose of encapsulation and leads to brittle tests. All interactions should be via methods.
-   **Overly Granular Page Objects:** Creating a page object for every tiny pop-up or component can lead to an explosion of classes, making the structure complex rather than simpler. Group related functionality logically.
-   **"God Object" Page Objects:** A single page object that tries to handle all interactions across the entire application. This becomes unwieldy and hard to maintain.
-   **Not Handling Dynamic Elements:** If elements appear/disappear or change dynamically, basic `@FindBy` might not be sufficient. Explicit waits (`WebDriverWait`) should be used within Page Object methods to ensure elements are interactable.

## Interview Questions & Answers
1.  **Q: What is the Page Object Model (POM) and why is it important in test automation?**
    A: POM is a design pattern where each web page (or significant part of a page) in an application is represented as a class. This class contains WebElements for that page and methods to interact with those elements. It's important because it improves test maintainability (UI changes only affect one class), readability (tests are cleaner), and reusability (methods can be shared). It promotes separation of concerns between test logic and UI interaction.

2.  **Q: What are the key components of a Page Object class?**
    A:
    *   **WebDriver instance:** Used to interact with the browser.
    *   **WebElements:** Private fields representing UI elements, often located using `@FindBy` annotations.
    *   **Constructor:** To initialize the WebDriver and WebElements (typically using `PageFactory.initElements()`).
    *   **Public methods:** To perform actions on the WebElements and encapsulate page behavior. These methods should return `void` or another Page Object.

3.  **Q: Should assertions be placed in Page Objects? Why or why not?**
    A: No, assertions should generally not be placed in Page Objects. Page Objects are meant to model the UI and its behaviors. Assertions are part of the test validation logic. Placing them in Page Objects blurs the line between "what the page can do" and "what the test expects," making page objects less flexible and reusable across different test scenarios. Assertions belong in the test classes.

4.  **Q: How do you handle navigation between pages using POM?**
    A: When an action on one page leads to another page, the method performing that action in the current Page Object should return an instance of the new Page Object. For example, a `login()` method in `LoginPage` that successfully logs in and goes to the home page would return a `HomePage` object: `public HomePage login(String user, String pass) { ... return new HomePage(driver); }`.

5.  **Q: What is `PageFactory` in Selenium and how does it relate to POM?**
    A: `PageFactory` is a class in Selenium that helps implement the Page Object Model. Its primary function is to initialize WebElements defined in a Page Object class using `@FindBy` annotations. The `PageFactory.initElements(driver, this)` method automatically populates these annotated WebElements when a Page Object is instantiated, simplifying element initialization and making the code cleaner.

## Hands-on Exercise
**Scenario:** Automate a simple search functionality on a hypothetical website.

**Task:**
1.  **Identify Pages:** Assume you have a `LandingPage` with a search bar and a `SearchResultsPage` to display results.
2.  **Create Page Objects:**
    *   `LandingPage.java`:
        *   `@FindBy` for the search input field and search button.
        *   A public method `searchFor(String query)` that enters text into the search field, clicks the button, and returns a `SearchResultsPage` object.
    *   `SearchResultsPage.java`:
        *   `@FindBy` for a list of search result items (e.g., `List<WebElement>`).
        *   A public method `getNumberOfResults()` that returns the count of results.
        *   A public method `getResultTitle(int index)` to get the title of a specific search result.
3.  **Create a Test:**
    *   Use TestNG.
    *   `@BeforeMethod` to set up the WebDriver and navigate to the landing page.
    *   `@Test` method to perform a search, navigate to the results page, and assert that the number of results is greater than zero.
    *   `@AfterMethod` to tear down the WebDriver.

## Additional Resources
-   **Selenium Official Documentation - PageFactory:** [https://www.selenium.dev/documentation/webdriver/elements_locators/page_factory/](https://www.selenium.dev/documentation/webdriver/elements_locators/page_factory/)
-   **Sauce Labs - Page Object Model:** [https://saucelabs.com/blog/page-object-model-design-pattern-selenium](https://saucelabs.com/blog/page-object-model-design-pattern-selenium)
-   **Test Automation University - Page Object Model:** [https://testautomationu.applitools.com/page-object-model-design-pattern/](https://testautomationu.applitools.com/page-object-model-design-pattern/)
-   **Guru99 - Page Object Model with Selenium WebDriver:** [https://www.guru99.com/page-object-model-pom-selenium-webdriver.html](https://www.guru99.com/page-object-model-pom-selenium-webdriver.html)