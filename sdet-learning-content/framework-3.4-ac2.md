# Configuration Management using Properties Files and Config Readers

## Overview
Effective test automation frameworks require robust configuration management to handle varying environments, credentials, and settings without modifying code. Hardcoding values like URLs, browser types, or timeouts makes tests brittle and difficult to maintain. This section explores how to implement configuration management using `config.properties` files and a `ConfigReader` utility class, a common and highly effective pattern in Java-based test automation frameworks. This approach promotes flexibility, reusability, and maintainability, allowing for seamless execution across different stages (e.g., dev, staging, production) and enabling parallel execution with different browser configurations.

## Detailed Explanation
Configuration management involves externalizing parameters that are likely to change. A `.properties` file is a simple, text-based file that stores key-value pairs. It's widely used in Java applications for configuration.

Here's how we'll implement it:
1.  **`config.properties` file**: This file will store all our configuration parameters (e.g., `baseURL`, `browser`, `implicitWaitTimeout`).
2.  **`ConfigReader` utility class**: This class will be responsible for loading the `config.properties` file, reading the values, and providing methods to access them. It typically uses Java's `java.util.Properties` class.
3.  **Integration with tests**: Test scripts will call methods from the `ConfigReader` to retrieve configuration values instead of using hardcoded strings.

### Advantages:
*   **Flexibility**: Easily change configurations without recompiling code.
*   **Maintainability**: Centralized configuration makes updates straightforward.
*   **Reusability**: The same test code can run in different environments.
*   **Security (limited)**: While not for sensitive data like passwords (which should be handled by secure vault systems or environment variables), it prevents credentials from being hardcoded in version-controlled source code. For sensitive data, a layered approach is recommended (e.g., using environment variables that override properties file values).

## Code Implementation

First, let's create a `config.properties` file.

```properties
# config.properties
# Base URL for the application under test
baseURL=https://www.example.com
# Browser to use for execution (e.g., chrome, firefox, edge)
browser=chrome
# Implicit wait timeout in seconds
implicitWaitTimeout=10
# Explicit wait timeout in seconds
explicitWaitTimeout=20
# Headless mode for browser execution (true/false)
headless=false
```

Next, we'll create the `ConfigReader` utility class. This class will load the `config.properties` file once and provide static methods to access the properties.

```java
// src/main/java/utils/ConfigReader.java
package utils;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

public class ConfigReader {
    private static Properties properties;
    private static final String CONFIG_FILE_PATH = "src/main/resources/config.properties"; // Or simply "config.properties" if in root/classpath

    // Static block to load properties when the class is initialized
    static {
        try {
            FileInputStream fis = new FileInputStream(CONFIG_FILE_PATH);
            properties = new Properties();
            properties.load(fis);
            fis.close();
        } catch (IOException e) {
            // Log the exception or throw a custom runtime exception
            System.err.println("Error loading config.properties file: " + e.getMessage());
            throw new RuntimeException("Failed to load configuration properties from " + CONFIG_FILE_PATH, e);
        }
    }

    /**
     * Retrieves a property value by its key.
     * @param key The key of the property to retrieve.
     * @return The string value of the property.
     * @throws RuntimeException if the key is not found in the properties file.
     */
    public static String getProperty(String key) {
        String value = properties.getProperty(key);
        if (value == null) {
            // It's good practice to throw an exception if a critical property is missing
            throw new RuntimeException("Property '" + key + "' not found in the config.properties file.");
        }
        return value;
    }

    /**
     * Retrieves a property value by its key, providing a default value if not found.
     * @param key The key of the property to retrieve.
     * @param defaultValue The default value to return if the key is not found.
     * @return The string value of the property or the default value.
     */
    public static String getProperty(String key, String defaultValue) {
        return properties.getProperty(key, defaultValue);
    }

    /**
     * Retrieves an integer property value by its key.
     * @param key The key of the property to retrieve.
     * @return The integer value of the property.
     * @throws NumberFormatException if the property value is not a valid integer.
     * @throws RuntimeException if the key is not found.
     */
    public static int getIntProperty(String key) {
        String value = getProperty(key);
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            throw new RuntimeException("Property '" + key + "' value '" + value + "' is not a valid integer.", e);
        }
    }

    /**
     * Retrieves a boolean property value by its key.
     * @param key The key of the property to retrieve.
     * @return The boolean value of the property.
     * @throws RuntimeException if the key is not found.
     */
    public static boolean getBooleanProperty(String key) {
        String value = getProperty(key);
        // Properties.getProperty returns String, so we parse it.
        // It's robust to handle "true" (case-insensitive) as true, anything else as false.
        return Boolean.parseBoolean(value);
    }

    public static void main(String[] args) {
        // Example usage:
        System.out.println("Base URL: " + ConfigReader.getProperty("baseURL"));
        System.out.println("Browser: " + ConfigReader.getProperty("browser"));
        System.out.println("Implicit Wait Timeout: " + ConfigReader.getIntProperty("implicitWaitTimeout") + " seconds");
        System.out.println("Explicit Wait Timeout (with default): " + ConfigReader.getProperty("explicitWaitTimeout", "15") + " seconds");
        System.out.println("Headless Mode: " + ConfigReader.getBooleanProperty("headless"));

        // Example of a missing property (will throw RuntimeException)
        // System.out.println("Missing Property: " + ConfigReader.getProperty("nonExistentProperty"));
    }
}
```

Now, let's see how to replace hardcoded values in a test with calls to `ConfigReader`.

```java
// src/test/java/com/example/tests/LoginTest.java
package com.example.tests;

import io.github.bonigarcia.wdm.WebDriverManager;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.firefox.FirefoxDriver;
import org.openqa.selenium.firefox.FirefoxOptions;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;
import utils.ConfigReader;

import java.time.Duration;

public class LoginTest {
    WebDriver driver;

    @BeforeMethod
    public void setup() {
        String browser = ConfigReader.getProperty("browser", "chrome"); // Default to chrome if not specified
        boolean headless = ConfigReader.getBooleanProperty("headless");
        int implicitWaitTimeout = ConfigReader.getIntProperty("implicitWaitTimeout");

        switch (browser.toLowerCase()) {
            case "chrome":
                WebDriverManager.chromedriver().setup();
                ChromeOptions chromeOptions = new ChromeOptions();
                if (headless) {
                    chromeOptions.addArguments("--headless=new");
                }
                driver = new ChromeDriver(chromeOptions);
                break;
            case "firefox":
                WebDriverManager.firefoxdriver().setup();
                FirefoxOptions firefoxOptions = new FirefoxOptions();
                if (headless) {
                    firefoxOptions.addArguments("-headless");
                }
                driver = new FirefoxDriver(firefoxOptions);
                break;
            // Add other browsers as needed (Edge, Safari, etc.)
            default:
                throw new IllegalArgumentException("Unsupported browser: " + browser);
        }
        driver.manage().window().maximize();
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(implicitWaitTimeout));
        driver.get(ConfigReader.getProperty("baseURL")); // Use base URL from config
    }

    @Test
    public void testSuccessfulLogin() {
        // This is a placeholder test. In a real scenario, you would interact with elements
        // using Page Object Model and assertions.
        System.out.println("Navigated to: " + driver.getCurrentUrl());
        System.out.println("Page Title: " + driver.getTitle());
        // Example: Perform login actions (e.g., find elements for username, password, login button)
        // driver.findElement(By.id("username")).sendKeys("testuser");
        // driver.findElement(By.id("password")).sendKeys("password123");
        // driver.findElement(By.id("loginButton")).click();

        // Assertions would go here
        // Assert.assertTrue(driver.getCurrentUrl().contains("dashboard"), "Login failed!");
    }

    @AfterMethod
    public void teardown() {
        if (driver != null) {
            driver.quit();
        }
    }
}
```

**Note on file paths**: For `config.properties`, it's common to place it in `src/main/resources` for Maven/Gradle projects. When running tests, this directory is typically on the classpath, so you might only need `ConfigReader.CONFIG_FILE_PATH = "config.properties";` if it's directly accessible, or ensure your build system copies it correctly. For simplicity in local execution, placing it directly in `src/main/resources` and using the explicit path `src/main/resources/config.properties` works.

## Best Practices
-   **Centralize Configuration**: Keep all environment-specific or frequently changing parameters in one or a few well-defined configuration files.
-   **Environment-Specific Files**: For more complex setups, use multiple property files (e.g., `config_dev.properties`, `config_qa.properties`) and load the appropriate one based on a system property or environment variable.
-   **Prefer `FileInputStream` for flexibility**: While `ConfigReader.class.getClassLoader().getResourceAsStream()` is good for classpath resources, `FileInputStream` allows you to specify a path outside the JAR, useful for external configuration overrides.
-   **Handle Missing Properties Graciously**: Decide whether to throw an exception for missing critical properties or provide sensible default values. The `ConfigReader` above demonstrates both.
-   **Avoid Committing Sensitive Data**: Never store sensitive information like passwords, API keys, or security tokens directly in `.properties` files that are committed to version control. Use environment variables, secure vaults (like HashiCorp Vault), or encrypted files for such data.
-   **Immutable ConfigReader**: Make your `ConfigReader` class immutable (properties loaded once) and thread-safe if it's shared across threads. The static block approach ensures it's loaded only once.
-   **Clear Naming Conventions**: Use clear and consistent naming for your keys (e.g., `baseURL`, `implicitWaitTimeout`).

## Common Pitfalls
-   **Hardcoding Values**: The most common pitfall is not using configuration management at all, leading to maintenance nightmares.
-   **Incorrect File Path**: Issues with the path to the `config.properties` file (e.g., file not found, incorrect relative path). Ensure it's correctly placed and accessible at runtime.
-   **Typos in Keys**: A simple typo in a property key in the `.properties` file or in the `getProperty()` call will result in `null` or a `RuntimeException`.
-   **Not Handling Type Conversions**: Forgetting to convert string properties to their appropriate types (e.g., `Integer.parseInt` for timeouts, `Boolean.parseBoolean` for flags) can lead to runtime errors.
-   **Over-reliance on properties for sensitive data**: Storing credentials in plaintext `config.properties` is a security vulnerability.
-   **Not refreshing configuration**: If your application needs to dynamically change configuration without restarting, a simple `Properties` load won't suffice. However, for most test automation frameworks, loading once at startup is sufficient.

## Interview Questions & Answers
1.  **Q**: Why is configuration management crucial in test automation frameworks?
    **A**: Configuration management is crucial because it externalizes frequently changing parameters (like URLs, browser types, user credentials, timeouts) from the test code. This makes the framework more flexible, maintainable, and reusable. It allows testers to run the same test suite across different environments (dev, QA, staging) without code changes, facilitates parallel execution with varied settings, and helps avoid hardcoding, which is a major anti-pattern.

2.  **Q**: How would you handle different configurations for multiple environments (e.g., Dev, QA, Prod) in your framework?
    **A**: I would use environment-specific properties files, such as `config_dev.properties`, `config_qa.properties`, and `config_prod.properties`. My `ConfigReader` would then dynamically load the appropriate file based on a system property passed during test execution (e.g., `-Denv=qa`), or an environment variable. For example, `ConfigReader.loadProperties("config_" + System.getProperty("env", "qa") + ".properties");`.

3.  **Q**: What are the security considerations when using `.properties` files for configuration, especially concerning sensitive data?
    **A**: The primary security concern is that `.properties` files are typically stored in plain text and often committed to version control systems. This makes them unsuitable for sensitive data like passwords, API keys, or security tokens. For such data, I would advocate using environment variables (which can be injected securely by CI/CD pipelines), secure credential management systems (like HashiCorp Vault or AWS Secrets Manager), or encrypted configuration files. The `.properties` file can then store references or pointers to these secure sources.

4.  **Q**: Describe how you would implement a `ConfigReader` class in Java.
    **A**: I would implement a `ConfigReader` as a singleton utility class. It would have a private constructor and a static `Properties` object. In a static initializer block, it would load the `config.properties` file using `FileInputStream` or `getClassLoader().getResourceAsStream()`. It would provide static `public` methods like `getProperty(String key)`, `getIntProperty(String key)`, and `getBooleanProperty(String key)` to safely retrieve and type-cast configuration values, with error handling for missing keys or invalid formats.

## Hands-on Exercise
1.  **Enhance `config.properties`**: Add new properties to `config.properties` for:
    *   `screenshotPath` (e.g., `target/screenshots/`)
    *   `browserVersion` (e.g., `120`)
    *   `pageLoadTimeout` (e.g., `30` seconds)
2.  **Extend `ConfigReader`**: Add new `getProperty` methods to `ConfigReader` to handle `long` values, and a method to return all properties as a `Map<String, String>`.
3.  **Integrate into a new test**: Create a new test class (e.g., `RegistrationTest.java`). In its `@BeforeMethod`, initialize a WebDriver using `browserVersion` and set `pageLoadTimeout` using the new `ConfigReader` methods. Use `screenshotPath` in an `@AfterMethod` to save a screenshot on test failure.

## Additional Resources
-   [Java Properties class documentation](https://docs.oracle.com/javase/8/docs/api/java/util/Properties.html)
-   [WebDriverManager GitHub Page](https://github.com/bonigarcia/webdrivermanager)
-   [Selenium WebDriver documentation](https://www.selenium.dev/documentation/webdriver/elements/)
-   [TestNG documentation](https://testng.org/doc/index.html)
