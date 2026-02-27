# Encapsulation in the Page Object Model (POM)

## Topic Overview: java-1.2-ac2
Implement Page Object Model classes demonstrating encapsulation principles.

## 1. What is Encapsulation in POM?
<!-- Briefly explain how encapsulation is applied when creating Page Objects. -->
Encapsulation in the Page Object Model (POM) is the practice of bundling the data (web element locators) and the behaviors (user interactions) of a web page into a single class. By declaring locators as `private`, we hide the technical implementation details of how elements are found. We then expose `public` methods that represent high-level user actions, such as `login()` or `searchProduct()`. This ensures that test scripts interact with the page through a clean API rather than manipulating raw elements directly.

## 2. Why use Private Locators?
<!-- Explain the security and maintainability benefits of keeping 'By' or 'WebElement' fields private. -->
Keeping `By` or `WebElement` fields private prevents "leaky abstraction." It ensures that test scripts cannot directly access or modify the locators, which centralizes UI changes. From a maintainability standpoint, if a developer changes an element's ID to a Class name, you only update the locator in the Page Object class. The test scripts remain untouched because they only call the public methods, not the private fields.

## 3. The Role of Public Action Methods
<!-- Describe how public methods act as the interface for your test scripts. -->
Public methods serve as the "contract" or interface between the test logic and the application UI. Instead of a test script containing brittle Selenium commands like `driver.findElement(By.id("...")).sendKeys("...")`, it calls a descriptive method like `loginPage.enterUsername("admin")`. This makes the tests more readable (resembling manual test steps) and allows the Page Object to handle complex synchronization, such as waiting for an element to be clickable before interacting.

## 4. Practical Implementation Details
<!-- Document the key elements and methods you implemented in your LoginPage class. -->
In a standard `LoginPage` implementation, the following components are encapsulated:
- **Private Locators**: `private By usernameField`, `private By passwordField`, and `private By loginButton`. These are hidden from the test classes to prevent direct manipulation.
- **Constructor**: A public constructor that initializes the `WebDriver` instance and uses an assertion or a wait to verify that the browser is actually on the Login page.
- **Action Methods**: Methods like `enterUsername(String user)` and `enterPassword(String pass)` which wrap the Selenium `sendKeys()` command, providing a cleaner API.
- **Business Logic Methods**: A higher-level `login(String user, String pass)` method that combines multiple atomic actions into a single functional flow.
- **Fluent Interface**: Designing methods like `clickLogin()` to return a `new ProductsPage(driver)`, allowing the test script to chain actions as the user navigates through the app.

## 5. Maintenance Benefit
<!-- Explain what happens to your tests if a locator (e.g., an ID) changes in the UI. -->
The primary benefit of encapsulation is the reduction of technical debt. If a locator changes in the UI, you only have to fix it in one specific Page Object class. For example, if the `usernameField` locator changes from `By.id("username")` to `By.name("user")`, you would only update that single line in the `LoginPage` class. The test scripts that call `loginPage.enterUsername("admin")` remain unaffected because they interact with the public method, not the private locator. Without encapsulation, you would have to search through every test script in your suite to find and replace every instance of the old locator, which is time-consuming and error-prone. Encapsulation ensures that your tests are resilient to UI changes, making them easier to maintain and less likely to break due to minor updates in the application.
