# Framework 3.4 AC3: Centralized Utility Packages

## Overview
In robust test automation frameworks, centralizing common functionalities into dedicated utility packages is a critical best practice. This approach promotes code reusability, improves maintainability, reduces redundancy, and ensures consistency across the test suite. Instead of scattering WebDriver calls or database connection logic throughout various test scripts, these operations are encapsulated within well-defined utility classes. This makes tests cleaner, easier to read, and more resilient to changes in underlying libraries or application UI.

## Detailed Explanation
Centralized utility packages act as an abstraction layer over raw API calls (like Selenium WebDriver or JDBC). This means that if, for instance, the way a click operation is performed changes (e.g., from `element.click()` to `Actions.moveToElement(element).click().build().perform()`), only the utility method needs to be updated, not every test case that uses a click. The same principle applies to database interactions, where connection details, query execution, and result processing can be standardized.

### Benefits:
1.  **Reusability:** Write once, use everywhere.
2.  **Maintainability:** Changes to core functionalities are managed in one place.
3.  **Readability:** Tests become more focused on business logic rather than technical implementation details.
4.  **Consistency:** Ensures that common operations are performed uniformly across the framework.
5.  **Error Handling:** Centralized error handling and logging can be implemented.

### Components for framework-3.4-ac3:

1.  **Selenium Actions Wrapper:**
    Selenium's `Actions` class provides a way to simulate complex user interactions like drag-and-drop, right-clicking, hovering, and keyboard events. Wrapping these into a utility class allows for cleaner, more descriptive test steps.

2.  **Database Utility for JDBC Connections:**
    Many applications interact with databases. A database utility class simplifies opening and closing connections, executing queries (SELECT, INSERT, UPDATE, DELETE), and processing result sets. This also centralizes database configuration (connection strings, credentials) and error handling.

## Code Implementation

### Selenium Actions Utility (`SeleniumActionsUtil.java`)

```java
package com.myframework.utilities;

import org.openqa.selenium.Alert;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

/**
 * Utility class for common Selenium WebDriver actions and waits.
 * Encapsulates complex interactions and explicit waits for better readability and maintainability.
 */
public class SeleniumActionsUtil {

    private WebDriver driver;
    private WebDriverWait wait;
    private Actions actions;

    // Constructor to initialize WebDriver, WebDriverWait, and Actions
    public SeleniumActionsUtil(WebDriver driver, Duration timeoutInSeconds) {
        this.driver = driver;
        this.wait = new WebDriverWait(driver, timeoutInSeconds);
        this.actions = new Actions(driver);
    }

    /**
     * Clicks on a web element using Selenium's Actions class.
     * Useful for elements that are not directly clickable by element.click().
     * @param element The WebElement to click.
     */
    public void clickElement(WebElement element) {
        try {
            wait.until(ExpectedConditions.elementToBeClickable(element));
            actions.moveToElement(element).click().build().perform();
            System.out.println("Clicked on element: " + element.getText());
        } catch (Exception e) {
            System.err.println("Failed to click element: " + element.getText() + " - " + e.getMessage());
            throw new RuntimeException("Error clicking element", e);
        }
    }

    /**
     * Performs a double-click action on a web element.
     * @param element The WebElement to double-click.
     */
    public void doubleClickElement(WebElement element) {
        try {
            wait.until(ExpectedConditions.elementToBeClickable(element));
            actions.doubleClick(element).build().perform();
            System.out.println("Double clicked on element: " + element.getText());
        } catch (Exception e) {
            System.err.println("Failed to double click element: " + element.getText() + " - " + e.getMessage());
            throw new RuntimeException("Error double clicking element", e);
        }
    }

    /**
     * Performs a right-click (context-click) action on a web element.
     * @param element The WebElement to right-click.
     */
    public void rightClickElement(WebElement element) {
        try {
            wait.until(ExpectedConditions.elementToBeClickable(element));
            actions.contextClick(element).build().perform();
            System.out.println("Right clicked on element: " + element.getText());
        } catch (Exception e) {
            System.err.println("Failed to right click element: " + element.getText() + " - " + e.getMessage());
            throw new RuntimeException("Error right clicking element", e);
        }
    }

    /**
     * Moves the mouse to the center of the specified web element.
     * Useful for hover effects.
     * @param element The WebElement to hover over.
     */
    public void hoverOverElement(WebElement element) {
        try {
            wait.until(ExpectedConditions.visibilityOf(element));
            actions.moveToElement(element).build().perform();
            System.out.println("Hovered over element: " + element.getText());
        } catch (Exception e) {
            System.err.println("Failed to hover over element: " + element.getText() + " - " + e.getMessage());
            throw new RuntimeException("Error hovering over element", e);
        }
    }

    /**
     * Drags an element from source to target.
     * @param source The WebElement to drag.
     * @param target The WebElement to drop on.
     */
    public void dragAndDrop(WebElement source, WebElement target) {
        try {
            wait.until(ExpectedConditions.visibilityOf(source));
            wait.until(ExpectedConditions.visibilityOf(target));
            actions.dragAndDrop(source, target).build().perform();
            System.out.println("Dragged element from " + source.getText() + " to " + target.getText());
        } catch (Exception e) {
            System.err.println("Failed to drag and drop: " + e.getMessage());
            throw new RuntimeException("Error performing drag and drop", e);
        }
    }

    /**
     * Sends a sequence of keys to the active web element.
     * @param keysToSend The character sequence to send to the element.
     */
    public void sendKeysToActiveElement(CharSequence... keysToSend) {
        try {
            actions.sendKeys(keysToSend).build().perform();
            System.out.println("Sent keys to active element.");
        } catch (Exception e) {
            System.err.println("Failed to send keys to active element: " + e.getMessage());
            throw new RuntimeException("Error sending keys", e);
        }
    }

    /**
     * Accepts a JavaScript alert.
     */
    public void acceptAlert() {
        try {
            Alert alert = wait.until(ExpectedConditions.alertIsPresent());
            alert.accept();
            System.out.println("Accepted alert.");
        } catch (Exception e) {
            System.err.println("No alert present to accept: " + e.getMessage());
            throw new RuntimeException("Error accepting alert", e);
        }
    }

    /**
     * Dismisses a JavaScript alert.
     */
    public void dismissAlert() {
        try {
            Alert alert = wait.until(ExpectedConditions.alertIsPresent());
            alert.dismiss();
            System.out.println("Dismissed alert.");
        } catch (Exception e) {
            System.err.println("No alert present to dismiss: " + e.getMessage());
            throw new RuntimeException("Error dismissing alert", e);
        }
    }

    /**
     * Gets the text from a JavaScript alert.
     * @return The text of the alert.
     */
    public String getAlertText() {
        try {
            Alert alert = wait.until(ExpectedConditions.alertIsPresent());
            String alertText = alert.getText();
            System.out.println("Alert text: " + alertText);
            return alertText;
        } catch (Exception e) {
            System.err.println("No alert present to get text from: " + e.getMessage());
            throw new RuntimeException("Error getting alert text", e);
        }
    }

    // Example of a custom wait for element to be visible
    public WebElement waitForVisibility(WebElement element) {
        return wait.until(ExpectedConditions.visibilityOf(element));
    }
}
```

### Database Utility (`DatabaseUtil.java`)

```java
package com.myframework.utilities;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

/**
 * Utility class for handling JDBC database connections and operations.
 * Centralizes database interaction logic, making tests cleaner and more robust.
 */
public class DatabaseUtil implements AutoCloseable {

    private Connection connection;
    private String dbUrl;
    private String username;
    private String password;

    // Constructor to initialize database connection parameters
    public DatabaseUtil(String dbUrl, String username, String password) {
        this.dbUrl = dbUrl;
        this.username = username;
        this.password = password;
    }

    /**
     * Establishes a connection to the database.
     * @throws SQLException If a database access error occurs.
     */
    public void connect() throws SQLException {
        if (connection == null || connection.isClosed()) {
            try {
                // For demonstration, assuming a MySQL database.
                // For other databases, the driver class name might differ (e.g., org.postgresql.Driver)
                // Class.forName("com.mysql.cj.jdbc.Driver"); // No longer strictly needed for JDBC 4.0+
                Properties props = new Properties();
                props.setProperty("user", username);
                props.setProperty("password", password);
                // Optional: Add SSL properties if needed
                // props.setProperty("ssl", "true");
                // props.setProperty("requireSSL", "true");

                connection = DriverManager.getConnection(dbUrl, props);
                System.out.println("Successfully connected to database: " + dbUrl);
            } catch (SQLException e) {
                System.err.println("Database connection failed: " + e.getMessage());
                throw e;
            }
        }
    }

    /**
     * Closes the database connection.
     */
    @Override
    public void close() {
        if (connection != null) {
            try {
                if (!connection.isClosed()) {
                    connection.close();
                    System.out.println("Database connection closed.");
                }
            } catch (SQLException e) {
                System.err.println("Error closing database connection: " + e.getMessage());
            }
            connection = null; // Mark connection as closed
        }
    }

    /**
     * Executes a SELECT query and returns the results as a List of Maps.
     * Each Map represents a row, with column names as keys and values as column data.
     * @param query The SQL SELECT query to execute.
     * @return A List of Maps, where each Map is a row of the result set.
     * @throws SQLException If a database access error occurs.
     */
    public List<Map<String, Object>> executeSelectQuery(String query) throws SQLException {
        List<Map<String, Object>> results = new ArrayList<>();
        if (connection == null || connection.isClosed()) {
            throw new SQLException("Database connection is not established or is closed.");
        }

        try (Statement statement = connection.createStatement();
             ResultSet resultSet = statement.executeQuery(query)) {

            ResultSetMetaData metaData = resultSet.getMetaData();
            int columnCount = metaData.getColumnCount();

            while (resultSet.next()) {
                Map<String, Object> row = new HashMap<>();
                for (int i = 1; i <= columnCount; i++) {
                    row.put(metaData.getColumnLabel(i), resultSet.getObject(i));
                }
                results.add(row);
            }
            System.out.println("Executed SELECT query: " + query);
        } catch (SQLException e) {
            System.err.println("Error executing SELECT query: " + query + " - " + e.getMessage());
            throw e;
        }
        return results;
    }

    /**
     * Executes an INSERT, UPDATE, or DELETE query and returns the number of affected rows.
     * @param query The SQL DML query to execute.
     * @return The number of rows affected by the query.
     * @throws SQLException If a database access error occurs.
     */
    public int executeUpdateQuery(String query) throws SQLException {
        if (connection == null || connection.isClosed()) {
            throw new SQLException("Database connection is not established or is closed.");
        }

        try (Statement statement = connection.createStatement()) {
            int affectedRows = statement.executeUpdate(query);
            System.out.println("Executed UPDATE query: " + query + ". Affected rows: " + affectedRows);
            return affectedRows;
        } catch (SQLException e) {
            System.err.println("Error executing UPDATE query: " + query + " - " + e.getMessage());
            throw e;
        }
    }

    /**
     * Example of using PreparedStatement for queries with parameters, preventing SQL injection.
     * @param query The SQL query with placeholders (e.g., "SELECT * FROM users WHERE username = ?").
     * @param params The parameters to set for the placeholders.
     * @return A List of Maps, where each Map is a row of the result set.
     * @throws SQLException If a database access error occurs.
     */
    public List<Map<String, Object>> executePreparedStatementSelect(String query, Object... params) throws SQLException {
        List<Map<String, Object>> results = new ArrayList<>();
        if (connection == null || connection.isClosed()) {
            throw new SQLException("Database connection is not established or is closed.");
        }

        try (PreparedStatement preparedStatement = connection.prepareStatement(query)) {
            for (int i = 0; i < params.length; i++) {
                preparedStatement.setObject(i + 1, params[i]);
            }

            try (ResultSet resultSet = preparedStatement.executeQuery()) {
                ResultSetMetaData metaData = resultSet.getMetaData();
                int columnCount = metaData.getColumnCount();

                while (resultSet.next()) {
                    Map<String, Object> row = new HashMap<>();
                    for (int i = 1; i <= columnCount; i++) {
                        row.put(metaData.getColumnLabel(i), resultSet.getObject(i));
                    }
                    results.add(row);
                }
            }
            System.out.println("Executed PreparedStatement SELECT query: " + query + " with params: " + java.util.Arrays.toString(params));
        } catch (SQLException e) {
            System.err.println("Error executing PreparedStatement SELECT query: " + query + " - " + e.getMessage());
            throw e;
        }
        return results;
    }

    /**
     * Executes an INSERT, UPDATE, or DELETE query using PreparedStatement.
     * @param query The SQL DML query with placeholders.
     * @param params The parameters to set for the placeholders.
     * @return The number of rows affected by the query.
     * @throws SQLException If a database access error occurs.
     */
    public int executePreparedStatementUpdate(String query, Object... params) throws SQLException {
        if (connection == null || connection.isClosed()) {
            throw new SQLException("Database connection is not established or is closed.");
        }

        try (PreparedStatement preparedStatement = connection.prepareStatement(query)) {
            for (int i = 0; i < params.length; i++) {
                preparedStatement.setObject(i + 1, params[i]);
            }
            int affectedRows = preparedStatement.executeUpdate();
            System.out.println("Executed PreparedStatement UPDATE query: " + query + " with params: " + java.util.Arrays.toString(params) + ". Affected rows: " + affectedRows);
            return affectedRows;
        } catch (SQLException e) {
            System.err.println("Error executing PreparedStatement UPDATE query: " + query + " - " + e.getMessage());
            throw e;
        }
    }
}
```

### Example Test Usage
Imagine you have a `LoginPage` class and a test that interacts with it, and also needs to verify data in a database.

```java
// Page object for a login page
package com.myframework.pages;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.PageFactory;

import com.myframework.utilities.SeleniumActionsUtil; // Import our utility

import java.time.Duration;

public class LoginPage {
    private WebDriver driver;
    private SeleniumActionsUtil actionsUtil; // Instance of our utility

    @FindBy(id = "username")
    private WebElement usernameField;

    @FindBy(id = "password")
    private WebElement passwordField;

    @FindBy(id = "loginButton")
    private WebElement loginButton;

    @FindBy(id = "alertMessage")
    private WebElement alertMessage;

    public LoginPage(WebDriver driver) {
        this.driver = driver;
        PageFactory.initElements(driver, this);
        this.actionsUtil = new SeleniumActionsUtil(driver, Duration.ofSeconds(10)); // Initialize the utility
    }

    public void enterUsername(String username) {
        usernameField.sendKeys(username);
    }

    public void enterPassword(String password) {
        passwordField.sendKeys(password);
    }

    public void clickLoginButton() {
        actionsUtil.clickElement(loginButton); // Using the utility method
    }

    public String getAlertMessageText() {
        return actionsUtil.getAlertText(); // Using the utility method for alerts
    }

    public void acceptAnyAlert() {
        actionsUtil.acceptAlert(); // Using the utility method for alerts
    }

    public String getLoginErrorMessage() {
        return actionsUtil.waitForVisibility(alertMessage).getText();
    }
}
```

```java
// TestNG Test Class
package com.myframework.tests;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.myframework.pages.LoginPage;
import com.myframework.utilities.DatabaseUtil; // Import our database utility
import com.myframework.utilities.SeleniumActionsUtil; // Import our Selenium utility

import java.sql.SQLException;
import java.time.Duration;
import java.util.List;
import java.util.Map;

public class LoginTest {

    private WebDriver driver;
    private LoginPage loginPage;
    private DatabaseUtil dbUtil;

    // Setup for WebDriver and database connection
    @BeforeMethod
    public void setup() throws SQLException {
        // Assume ChromeDriver is set up via WebDriverManager or system property
        // System.setProperty("webdriver.chrome.driver", "/path/to/chromedriver");
        driver = new ChromeDriver();
        driver.manage().window().maximize();
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(10));
        driver.get("http://localhost:8080/login"); // Replace with your application's login URL

        loginPage = new LoginPage(driver);

        // Initialize DatabaseUtil
        String dbUrl = "jdbc:mysql://localhost:3306/testdb";
        String dbUser = "root";
        String dbPass = "password";
        dbUtil = new DatabaseUtil(dbUrl, dbUser, dbPass);
        dbUtil.connect();
    }

    @Test
    public void testSuccessfulLoginAndDatabaseVerification() throws SQLException {
        // Ensure a user exists in the database for the test
        dbUtil.executeUpdateQuery("DELETE FROM users WHERE username = 'testuser'"); // Clean up previous
        dbUtil.executeUpdateQuery("INSERT INTO users (username, password, email) VALUES ('testuser', 'testpass', 'test@example.com')");

        loginPage.enterUsername("testuser");
        loginPage.enterPassword("testpass");
        loginPage.clickLoginButton();

        // Simulate a successful login redirect or check for success element
        // Assert.assertTrue(driver.getCurrentUrl().contains("/dashboard"), "Login was not successful");

        // Example: Verify user status in database after login (if applicable)
        List<Map<String, Object>> userDetails = dbUtil.executePreparedStatementSelect(
                "SELECT status FROM users WHERE username = ?", "testuser");

        Assert.assertFalse(userDetails.isEmpty(), "User details not found in DB.");
        // Assert.assertEquals(userDetails.get(0).get("status"), "active", "User status not updated in DB.");

        System.out.println("Login Test Passed: testSuccessfulLoginAndDatabaseVerification");
    }

    @Test
    public void testInvalidCredentials() {
        loginPage.enterUsername("invaliduser");
        loginPage.enterPassword("wrongpass");
        loginPage.clickLoginButton();

        // Assuming an alert or an error message on the page for invalid credentials
        // If it's an alert:
        // String alertText = loginPage.getAlertMessageText();
        // Assert.assertTrue(alertText.contains("Invalid credentials"), "Expected invalid credentials alert");
        // loginPage.acceptAnyAlert();

        // If it's an on-page error message:
        String errorMessage = loginPage.getLoginErrorMessage();
        Assert.assertTrue(errorMessage.contains("Invalid username or password"), "Expected error message for invalid credentials");
        System.out.println("Login Test Passed: testInvalidCredentials");
    }


    // Teardown to close WebDriver and database connection
    @AfterMethod
    public void tearDown() {
        if (driver != null) {
            driver.quit();
            System.out.println("WebDriver closed.");
        }
        if (dbUtil != null) {
            dbUtil.close(); // Closes the database connection
        }
    }
}
```

**Note:** For the `DatabaseUtil`, you'll need the appropriate JDBC driver in your project's classpath (e.g., `mysql-connector-java` for MySQL, `postgresql` for PostgreSQL). Add it to your `pom.xml` (Maven) or `build.gradle` (Gradle).

Example Maven dependency:
```xml
<!-- https://mvnrepository.com/artifact/mysql/mysql-connector-java -->
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <version>8.0.28</version> <!-- Use a recent version -->
</dependency>
```

## Best Practices
-   **Keep Utilities Focused:** Each utility class should have a single responsibility (e.g., `SeleniumActionsUtil` for Selenium actions, `DatabaseUtil` for database operations).
-   **Handle Exceptions Gracefully:** Implement robust error handling with meaningful logging and appropriate exception propagation.
-   **Use Explicit Waits:** Always integrate explicit waits in Selenium utilities to handle dynamic web elements reliably.
-   **Parameterize Database Connections:** Avoid hardcoding database credentials and URLs. Use configuration files (e.g., `config.properties`, `YAML`) to manage these.
-   **Use Prepared Statements:** For database operations involving user input or parameters, always use `PreparedStatement` to prevent SQL injection vulnerabilities.
-   **Implement `AutoCloseable`:** For resources like database connections, implement `AutoCloseable` to ensure they are properly closed using try-with-resources blocks.
-   **Centralize Alerts/Waits:** Create separate, focused utilities for waits and alerts, or integrate them logically within broader utility classes like `SeleniumActionsUtil`.

## Common Pitfalls
-   **Over-generalization:** Creating "god" utility classes that try to do too many things. This makes them hard to maintain. Break down functionalities into smaller, focused classes.
-   **Ignoring Error Handling:** Letting exceptions crash tests without proper logging or recovery mechanisms.
-   **Hardcoding Credentials/URLs:** Storing sensitive information or environment-specific URLs directly in code. Use external configuration.
-   **Not Using Explicit Waits:** Relying solely on `Thread.sleep()` or implicit waits, leading to flaky tests.
-   **SQL Injection Vulnerabilities:** Using simple `Statement.executeQuery()` or `Statement.executeUpdate()` with concatenated strings for dynamic queries, especially when dealing with user input. Always use `PreparedStatement`.
-   **Not Closing Resources:** Failing to close WebDriver instances, database connections, or file streams, leading to resource leaks.

## Interview Questions & Answers
1.  **Q: Why is it important to create centralized utility packages in a test automation framework?**
    **A:** Centralized utility packages promote code reusability, improve maintainability, reduce redundancy, and ensure consistency. They abstract away the technical implementation details, allowing test cases to focus purely on business logic. This makes the framework more robust, easier to scale, and more resilient to changes in the underlying application or libraries.

2.  **Q: How do you handle common Selenium actions like clicks, hovers, or drag-and-drop in a reusable way?**
    **A:** I would create a `SeleniumActionsUtil` class that wraps Selenium's `Actions` class. This utility would provide high-level methods like `clickElement(WebElement element)`, `hoverOverElement(WebElement element)`, and `dragAndDrop(WebElement source, WebElement target)`. These methods would also incorporate explicit waits (e.g., `elementToBeClickable`, `visibilityOf`) and basic error handling to make them more robust.

3.  **Q: Describe how you would implement a database utility for test automation. What considerations are important?**
    **A:** A `DatabaseUtil` class would encapsulate JDBC operations. It would have methods for `connect()`, `close()`, `executeSelectQuery(String sql)`, `executeUpdateQuery(String sql)`, and parameterized versions using `PreparedStatement` for security. Key considerations include:
    *   **Connection Management:** Opening and closing connections efficiently, potentially using connection pooling for performance.
    *   **Configuration:** Externalizing database URL, username, and password.
    *   **Error Handling:** Robust try-catch blocks for `SQLException`.
    *   **SQL Injection Prevention:** *Crucially*, using `PreparedStatement` for all queries that involve dynamic parameters to avoid security vulnerabilities.
    *   **Result Set Processing:** Converting `ResultSet` into more usable data structures like `List<Map<String, Object>>`.
    *   **Resource Management:** Ensuring `Statement`, `ResultSet`, and `Connection` objects are closed using try-with-resources.

4.  **Q: What is the role of `WebDriverWait` and `ExpectedConditions` in your Selenium utility methods?**
    **A:** `WebDriverWait` combined with `ExpectedConditions` is vital for creating robust Selenium tests that interact with dynamic web applications. They allow the driver to pause for a specified duration until a certain condition is met (e.g., an element becomes clickable, visible, or an alert is present). Integrating them into utility methods centralizes the waiting logic, prevents `NoSuchElementException` or `ElementNotInteractableException`, reduces test flakiness, and avoids the overuse of `Thread.sleep()`.

## Hands-on Exercise
**Objective:** Enhance the `SeleniumActionsUtil` and `DatabaseUtil` classes.

1.  **Add Screenshot on Failure:** Modify the `SeleniumActionsUtil` methods to take a screenshot and save it to a designated folder whenever an action fails (e.g., `clickElement` throws an exception). You'll need to pass the `driver` instance to a new `ScreenshotUtil` or directly implement the screenshot logic.
2.  **Implement Transaction Management in `DatabaseUtil`:** Add methods to `DatabaseUtil` to start a transaction (`beginTransaction()`), commit it (`commitTransaction()`), and roll it back (`rollbackTransaction()`). This is crucial for test data management where you might want to perform multiple database operations atomically and then revert them.
3.  **Create a Configuration Reader:** Develop a `ConfigReader` utility that loads database credentials and application URLs from a `config.properties` file, so they are not hardcoded in the `LoginTest` or `DatabaseUtil`.

## Additional Resources
-   **Selenium Documentation - Actions:** [https://www.selenium.dev/documentation/webdriver/actions/](https://www.selenium.dev/documentation/webdriver/actions/)
-   **Oracle JDBC Tutorial:** [https://docs.oracle.com/javase/tutorial/jdbc/index.html](https://docs.oracle.com/javase/tutorial/jdbc/index.html)
-   **Baeldung - Guide to JDBC:** [https://www.baeldung.com/java-jdbc](https://www.baeldung.com/java-jdbc)
-   **WebDriver Waits:** [https://www.selenium.dev/documentation/webdriver/waits/](https://www.selenium.dev/documentation/webdriver/waits/)
