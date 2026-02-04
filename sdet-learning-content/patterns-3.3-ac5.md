# Data-Driven Testing Framework

## Overview
Data-Driven Testing (DDT) is a software testing methodology where test data is stored externally (e.g., in CSV, Excel, JSON, XML files, or databases) and loaded into tests at runtime. This approach separates test logic from test data, making tests more maintainable, scalable, and reusable. Instead of writing multiple test methods for different sets of data, a single test method can be executed multiple times with varying inputs. This is crucial for verifying an application's behavior across a wide range of scenarios without duplicating test code.

## Detailed Explanation
In a Data-Driven Testing framework, the core idea is to externalize the test inputs and expected outputs. When a test runs, it fetches a row of data, injects that data into the test steps, executes the test, and then moves to the next row until all data sets are processed.

Consider a login functionality. Without DDT, you might write separate test cases for:
- Valid username, valid password
- Valid username, invalid password
- Invalid username, valid password
- Empty username, empty password

With DDT, you'd write one generic login test method and provide all these combinations as external data. The test runner (like TestNG or JUnit's parameterized tests) would then iterate through each data set.

Key components of a DDT framework typically include:
1.  **Test Data Source**: Where the test data resides (e.g., `data.xlsx`, `users.json`, `config.properties`).
2.  **Data Reader/Provider**: A utility or method responsible for reading data from the source and providing it in a structured format (e.g., `Object[][]` for TestNG).
3.  **Test Method**: A generic test method that accepts parameters for data input and uses them in its execution.
4.  **Test Runner Integration**: The mechanism by which the test framework (e.g., TestNG's `@DataProvider`) consumes the data provided by the data reader.

## Code Implementation
Here, we'll demonstrate a simple Data-Driven Test using TestNG and reading data from a CSV file.

First, let's assume we have a `login_data.csv` file:
```csv
username,password,expectedMessage
testuser1,password123,Login successful!
invaliduser,wrongpass,Invalid credentials.
,,"Username cannot be empty"
```

Now, the Java code for the Data Provider and Test Class:

```java
// src/test/java/com/example/test/data/CSVDataReader.java
package com.example.test.data;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class CSVDataReader {

    public static Iterator<Object[]> getTestData(String filePath) throws IOException {
        List<Object[]> data = new ArrayList<>();
        // Using try-with-resources to ensure BufferedReader is closed
        try (BufferedReader br = new BufferedReader(new FileReader(filePath))) {
            String line;
            boolean isFirstLine = true; // To skip header row
            while ((line = br.readLine()) != null) {
                if (isFirstLine) {
                    isFirstLine = false;
                    continue; // Skip header
                }
                String[] values = line.split(",", -1); // -1 to include trailing empty strings
                // Ensure we have enough elements, pad with empty strings if necessary
                Object[] rowData = new Object[3]; // Assuming 3 columns: username, password, expectedMessage
                for (int i = 0; i < rowData.length; i++) {
                    rowData[i] = (i < values.length) ? values[i].trim() : "";
                }
                data.add(rowData);
            }
        }
        return data.iterator();
    }
}
```

```java
// src/test/java/com/example/test/LoginTest.java
package com.example.test;

import com.example.test.data.CSVDataReader;
import org.testng.Assert;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.io.IOException;

public class LoginTest {

    // Dummy LoginService for demonstration
    static class LoginService {
        public String login(String username, String password) {
            if (username == null || username.trim().isEmpty()) {
                return "Username cannot be empty";
            }
            if (password == null || password.trim().isEmpty()) {
                return "Password cannot be empty";
            }
            if ("testuser1".equals(username) && "password123".equals(password)) {
                return "Login successful!";
            } else if ("invaliduser".equals(username)) {
                return "Invalid credentials.";
            } else {
                return "Unknown error.";
            }
        }
    }

    @DataProvider(name = "loginData")
    public Iterator<Object[]> getLoginData() throws IOException {
        // Path to your CSV file. Adjust based on your project structure.
        // For Maven/Gradle, you might place it in src/test/resources.
        String csvFilePath = "D:/AI/Gemini_CLI/SDET-Learning/login_data.csv"; // Adjust this path as needed
        return CSVDataReader.getTestData(csvFilePath);
    }

    @Test(dataProvider = "loginData")
    public void testLogin(String username, String password, String expectedMessage) {
        System.out.println("Testing login with: Username=" + username + ", Password=" + password + ", Expected=" + expectedMessage);
        LoginService loginService = new LoginService();
        String actualMessage = loginService.login(username, password);
        Assert.assertEquals(actualMessage, expectedMessage, "Login test failed for username: " + username);
    }
}
```

**Explanation:**
-   `CSVDataReader.java`: A utility class to read data from a CSV file. It skips the header and returns an `Iterator<Object[]>` which is required by TestNG's `@DataProvider`.
-   `LoginService.java` (nested class for simplicity): A mock service simulating login logic.
-   `LoginTest.java`:
    -   `@DataProvider(name = "loginData")`: This method provides the test data. It calls `CSVDataReader.getTestData()` to read the CSV file. The `name` attribute is used by the `@Test` method to link to this data provider.
    -   `@Test(dataProvider = "loginData")`: This test method will be executed once for each row of data returned by the `loginData` data provider. The parameters (`username`, `password`, `expectedMessage`) directly correspond to the elements in each `Object[]` array returned by the data provider.
    -   `Assert.assertEquals()`: Compares the actual login message with the expected message from the CSV data.

**To run this example:**
1.  Ensure you have TestNG added to your project's `pom.xml` (for Maven) or `build.gradle` (for Gradle).
    ```xml
    <!-- Maven dependency for TestNG -->
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
    ```
2.  Create the `login_data.csv` file in your project root or `src/test/resources` and adjust the `csvFilePath` in `LoginTest.java` accordingly.
3.  Place `CSVDataReader.java` and `LoginTest.java` in appropriate package structures (`src/test/java`).
4.  Run the `LoginTest` class using your IDE or TestNG runner.

## Best Practices
-   **Separate Data from Code**: Always store test data in external files or databases, not hardcoded within test methods.
-   **Choose Appropriate Data Source**: Select the data source (CSV, Excel, JSON, XML, Database) based on data complexity, volume, and team familiarity. CSV is simple for tabular data; JSON/XML for hierarchical data; databases for very large or dynamic datasets.
-   **Clear Data Structure**: Maintain a clear and consistent structure for your test data, including headers or clear keys for easy understanding.
-   **Data Validation**: Implement validation in your data reader to handle malformed data or missing values gracefully.
-   **Parameterization**: Use parameters in your test methods to accept data provided by the data source.
-   **Small, Focused Data Sets**: Avoid overly large data files for a single test. Break them down if necessary.
-   **Version Control**: Keep your test data files under version control along with your test code.

## Common Pitfalls
-   **Hardcoding File Paths**: Do not hardcode file paths. Use relative paths or dynamic resolution based on the project structure or environment variables.
-   **Ignoring Header Row**: For CSV files, forgetting to skip the header row can lead to data parsing errors or incorrect test execution.
-   **Data Type Mismatches**: Ensure the data read from the external source matches the expected data types in your test method parameters (e.g., converting strings to integers or booleans).
-   **Over-complicating Data Readers**: Start with simple data readers. Only build complex parsers if your data structure genuinely requires it.
-   **Lack of Error Handling**: Failing to handle `FileNotFoundException` or `IOException` when reading data can cause tests to crash unexpectedly.
-   **Inadequate Data Cleanup**: If tests modify data in a database, ensure proper cleanup or setup procedures (`@BeforeMethod`, `@AfterMethod`) to maintain test independence.

## Interview Questions & Answers
1.  **Q: What is Data-Driven Testing, and why is it important in test automation?**
    **A:** Data-Driven Testing (DDT) is an automation approach where test data is separated from the test logic. Tests read input values and expected results from an external source (like CSV, Excel, JSON, DB) at runtime, allowing a single test script to run with multiple data sets. It's crucial because it enhances test reusability, reduces code duplication, improves maintainability, and allows for broad test coverage with diverse data, which is especially important for regression testing and validating various user scenarios.

2.  **Q: Describe how you would implement a Data-Driven Testing framework using Selenium and TestNG.**
    **A:** I would typically:
    *   **Identify Data Source**: Choose an external data source, e.g., a CSV file for simple tabular data.
    *   **Data Provider**: Create a TestNG `@DataProvider` method that reads data from the CSV file. This method would use a utility class (e.g., `CSVDataReader` as shown above) to parse the CSV into an `Object[][]` or `Iterator<Object[]>`.
    *   **Generic Test Method**: Design a Selenium test method (e.g., `testLogin(String username, String password, String expectedMessage)`) that accepts parameters corresponding to the columns in the CSV. This method will contain the Selenium actions (e.g., finding elements, entering text, clicking buttons).
    *   **Integrate**: Annotate the test method with `@Test(dataProvider = "yourDataProviderName")` to link it to the data provider.
    *   **Assertions**: Include assertions within the test method to verify actual results against expected results from the data file.
    *   **Path Management**: Ensure the CSV file path is handled dynamically (e.g., relative path from `src/test/resources`) for portability.

3.  **Q: What are the advantages and disadvantages of using Excel files vs. JSON files as data sources for DDT?**
    **A:**
    *   **Excel (e.g., .xlsx)**:
        *   **Advantages**: User-friendly for non-technical team members to view and edit data; good for structured, tabular data; supports multiple sheets for different test cases.
        *   **Disadvantages**: Requires external libraries (e.g., Apache POI) for programmatic access in Java, which adds dependency and complexity; can be prone to manual errors; difficult to manage in version control (diffing changes is hard); less suitable for hierarchical or complex data structures.
    *   **JSON (JavaScript Object Notation)**:
        *   **Advantages**: Lightweight and human-readable; excellent for hierarchical and complex data structures; easily parsed by most programming languages; well-suited for API testing.
        *   **Disadvantages**: Less intuitive for non-technical users to edit directly compared to Excel; requires careful formatting (commas, braces, brackets); might require a dedicated JSON parsing library.
    I would generally prefer JSON for API testing and complex data, and CSV/simple databases for UI testing with tabular data, avoiding Excel unless explicitly required for business user input.

## Hands-on Exercise
1.  **Objective**: Implement a Data-Driven Test for a search functionality.
2.  **Setup**:
    *   Create a simple HTML page or use a publicly available search engine (e.g., Google).
    *   Create a `search_data.csv` file with columns like `searchTerm`, `expectedResultTitle` (e.g., `searchTerm,expectedResultTitle
Selenium,Selenium Official Site
TestNG,TestNG`).
3.  **Task**:
    *   Write a Java utility to read data from `search_data.csv`.
    *   Create a TestNG class with a `@DataProvider` that uses your utility.
    *   Write a Selenium `@Test` method that takes `searchTerm` and `expectedResultTitle` as parameters.
    *   Inside the test method, navigate to the search engine, enter the `searchTerm`, perform the search, and assert that the page title (or a specific element's text) contains the `expectedResultTitle`.
    *   Handle cases where the expected result might not be immediately visible (e.g., taking screenshots on failure).
4.  **Enhancement (Optional)**: Extend the CSV to include an `expectedURL` and verify the URL after clicking a search result.

## Additional Resources
-   **TestNG DataProviders**: [https://testng.org/doc/documentation-main.html#data-providers](https://testng.org/doc/documentation-main.html#data-providers)
-   **Apache POI (for Excel)**: [https://poi.apache.org/](https://poi.apache.org/)
-   **JSON Simple Library**: [https://code.google.com/archive/p/json-simple/](https://code.google.com/archive/p/json-simple/) (Note: Newer alternatives like Jackson or Gson are often preferred for modern projects)
-   **Gson Library (for JSON)**: [https://github.com/google/gson](https://github.com/google/gson)
-   **Jackson Databind (for JSON)**: [https://github.com/FasterXML/jackson-databind](https://github.com/FasterXML/jackson-databind)
