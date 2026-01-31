# Test Data Management Utility using Java Collections

## Overview
Effective test data management is crucial for robust and maintainable test automation frameworks. It ensures that tests are reliable, repeatable, and easy to update. This section focuses on building a simple, yet powerful, test data utility using Java's `Map` and `List` collections to store and retrieve test data. This approach promotes data separation from test logic, making tests cleaner and more organized.

## Detailed Explanation
In test automation, tests often require various inputs – usernames, passwords, product IDs, expected results, etc. Hardcoding this data directly into test cases makes them rigid and difficult to manage. A test data management utility centralizes data, allowing easy modifications without touching test logic.

We will design a utility that can handle two common test data structures:
1.  **Key-Value Pairs for single data sets**: For simple scenarios where you need a set of related data points (e.g., login credentials for a single user). A `Map<String, String>` is ideal here, where the key is the data field name (e.g., "username") and the value is the data itself (e.g., "testuser").
2.  **Data Tables for multiple data sets (Data-Driven Testing)**: For scenarios like creating multiple users, testing different product configurations, or validating a feature with various inputs. A `List<Map<String, String>>` perfectly represents a table where each `Map` is a row (a set of key-value pairs) and the `List` holds all these rows.

This utility will provide methods to load data from a source (for this example, we'll simulate loading from an external source using static data) and access it efficiently.

### Example Scenario
Imagine we are testing a login page. We need different credentials for valid, invalid, and locked accounts.
*   `validUser`: username="standard_user", password="secret_sauce"
*   `lockedUser`: username="locked_out_user", password="secret_sauce"

For a product search, we might need multiple search terms and expected results:
*   `search1`: term="backpack", expectedCount="1"
*   `search2`: term="bike", expectedCount="1"
*   `search3`: term="jacket", expectedCount="1"

Our utility will allow us to store and retrieve such data programmatically.

## Code Implementation

We'll create a `TestDataManager` class.

First, ensure you have a basic Maven or Gradle project setup.
**Maven `pom.xml` dependency (for `org.json` if you were to parse JSON files, not strictly needed for this example, but good to have for future expansion):**
```xml
<dependencies>
    <!-- For demonstration, we'll use static data. 
         For real-world JSON/CSV, you'd add dependencies like GSON or Jackson, Apache POI etc. -->
    <!-- Example if reading JSON: -->
    <dependency>
        <groupId>org.json</groupId>
        <artifactId>json</artifactId>
        <version>20231013</version>
    </dependency>
    <!-- Other dependencies like TestNG or JUnit can be added here if integrating with tests -->
</dependencies>
```

**`src/main/java/com/sdetlearning/util/TestDataManager.java`**
```java
package com.sdetlearning.util;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * A utility class for managing test data using Java Collections.
 * Supports storing data as key-value maps for single data sets or
 * lists of maps for tabular data (data-driven testing).
 */
public class TestDataManager {

    // Store single data sets (e.g., login credentials for a specific user)
    // Key: data set name (e.g., "validUser"), Value: Map of data (e.g., {username: "user", password: "pwd"})
    private final Map<String, Map<String, String>> singleDataSets;

    // Store data tables (e.g., multiple search queries with expected results)
    // Key: table name (e.g., "searchQueries"), Value: List of Maps (each Map is a row)
    private final Map<String, List<Map<String, String>>> dataTables;

    public TestDataManager() {
        this.singleDataSets = new HashMap<>();
        this.dataTables = new HashMap<>();
        loadStaticTestData(); // Load initial data (in a real scenario, this would come from files)
    }

    /**
     * Simulates loading test data from an external source.
     * In a real framework, this would involve reading from JSON, CSV, Excel, DB, etc.
     */
    private void loadStaticTestData() {
        // --- Single Data Sets ---
        // Valid Login Credentials
        Map<String, String> validUser = new HashMap<>();
        validUser.put("username", "standard_user");
        validUser.put("password", "secret_sauce");
        singleDataSets.put("validUser", validUser);

        // Locked Out User Credentials
        Map<String, String> lockedUser = new HashMap<>();
        lockedUser.put("username", "locked_out_user");
        lockedUser.put("password", "secret_sauce");
        singleDataSets.put("lockedUser", lockedUser);

        // --- Data Tables ---
        // Product Search Queries
        List<Map<String, String>> searchQueries = new ArrayList<>();
        Map<String, String> query1 = new HashMap<>();
        query1.put("searchTerm", "backpack");
        query1.put("expectedCount", "1");
        searchQueries.add(query1);

        Map<String, String> query2 = new HashMap<>();
        query2.put("searchTerm", "bike light");
        query2.put("expectedCount", "1");
        searchQueries.add(query2);

        Map<String, String> query3 = new HashMap<>();
        query3.put("searchTerm", "jacket");
        query3.put("expectedCount", "1");
        searchQueries.add(query3);
        dataTables.put("productSearchQueries", searchQueries);

        // Invalid Login Attempts (for data-driven testing)
        List<Map<String, String>> invalidLogins = new ArrayList<>();
        Map<String, String> invalid1 = new HashMap<>();
        invalid1.put("username", "bad_user");
        invalid1.put("password", "wrong_password");
        invalid1.put("expectedError", "Username and password do not match any user in this service!");
        invalidLogins.add(invalid1);

        Map<String, String> invalid2 = new HashMap<>();
        invalid2.put("username", "standard_user");
        invalid2.put("password", "wrong_password");
        invalid2.put("expectedError", "Username and password do not match any user in this service!");
        invalidLogins.add(invalid2);

        Map<String, String> invalid3 = new HashMap<>();
        invalid3.put("username", "locked_out_user");
        invalid3.put("password", "secret_sauce"); // Correct password, but user is locked
        invalid3.put("expectedError", "Sorry, this user has been locked out.");
        invalidLogins.add(invalid3);
        dataTables.put("invalidLoginAttempts", invalidLogins);
    }

    /**
     * Retrieves a specific single data set by its name.
     *
     * @param dataSetName The name of the data set (e.g., "validUser").
     * @return An Optional containing the Map of key-value pairs if found, empty Optional otherwise.
     */
    public Optional<Map<String, String>> getSingleDataSet(String dataSetName) {
        return Optional.ofNullable(singleDataSets.get(dataSetName));
    }

    /**
     * Retrieves a specific value from a single data set.
     *
     * @param dataSetName The name of the data set.
     * @param key         The key for the desired value within the data set.
     * @return An Optional containing the value if found, empty Optional otherwise.
     */
    public Optional<String> getSingleDataValue(String dataSetName, String key) {
        return getSingleDataSet(dataSetName)
                .map(dataMap -> dataMap.get(key));
    }

    /**
     * Retrieves a data table (list of data sets) by its name.
     *
     * @param tableName The name of the data table (e.g., "productSearchQueries").
     * @return An Optional containing the List of Maps if found, empty Optional otherwise.
     */
    public Optional<List<Map<String, String>>> getDataTable(String tableName) {
        return Optional.ofNullable(dataTables.get(tableName));
    }

    /**
     * Retrieves a specific row from a data table by its index.
     *
     * @param tableName The name of the data table.
     * @param rowIndex  The 0-based index of the desired row.
     * @return An Optional containing the Map for the specified row if found, empty Optional otherwise.
     */
    public Optional<Map<String, String>> getTableRow(String tableName, int rowIndex) {
        return getDataTable(tableName)
                .filter(table -> rowIndex >= 0 && rowIndex < table.size())
                .map(table -> table.get(rowIndex));
    }

    /**
     * Retrieves a specific value from a specific row in a data table.
     *
     * @param tableName The name of the data table.
     * @param rowIndex  The 0-based index of the desired row.
     * @param key       The key for the desired value within the row.
     * @return An Optional containing the value if found, empty Optional otherwise.
     */
    public Optional<String> getTableValue(String tableName, int rowIndex, String key) {
        return getTableRow(tableName, rowIndex)
                .map(rowMap -> rowMap.get(key));
    }
}
```

**`src/test/java/com/sdetlearning/tests/TestDataManagerTest.java`**
```java
package com.sdetlearning.tests;

import com.sdetlearning.util.TestDataManager;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.util.List;
import java.util.Map;
import java.util.Optional;

public class TestDataManagerTest {

    private TestDataManager testDataManager;

    @BeforeClass
    public void setup() {
        testDataManager = new TestDataManager();
    }

    @Test(description = "Verify retrieval of a single data set")
    public void testGetSingleDataSet() {
        Optional<Map<String, String>> validUser = testDataManager.getSingleDataSet("validUser");
        Assert.assertTrue(validUser.isPresent(), "validUser data set should be present");
        Assert.assertEquals(validUser.get().get("username"), "standard_user");
        Assert.assertEquals(validUser.get().get("password"), "secret_sauce");

        Optional<Map<String, String>> nonExistentUser = testDataManager.getSingleDataSet("nonExistent");
        Assert.assertFalse(nonExistentUser.isPresent(), "nonExistent data set should not be present");
    }

    @Test(description = "Verify retrieval of a single data value from a data set")
    public void testGetSingleDataValue() {
        Optional<String> username = testDataManager.getSingleDataValue("lockedUser", "username");
        Assert.assertTrue(username.isPresent(), "Username should be present");
        Assert.assertEquals(username.get(), "locked_out_user");

        Optional<String> invalidKey = testDataManager.getSingleDataValue("validUser", "email");
        Assert.assertFalse(invalidKey.isPresent(), "Email key should not be present in validUser");
    }

    @Test(description = "Verify retrieval of a data table")
    public void testGetDataTable() {
        Optional<List<Map<String, String>>> searchQueries = testDataManager.getDataTable("productSearchQueries");
        Assert.assertTrue(searchQueries.isPresent(), "productSearchQueries table should be present");
        Assert.assertEquals(searchQueries.get().size(), 3, "Expected 3 search queries");

        Optional<List<Map<String, String>>> nonExistentTable = testDataManager.getDataTable("nonExistentTable");
        Assert.assertFalse(nonExistentTable.isPresent(), "nonExistentTable should not be present");
    }

    @Test(description = "Verify retrieval of a specific row from a data table")
    public void testGetTableRow() {
        Optional<Map<String, String>> firstQuery = testDataManager.getTableRow("productSearchQueries", 0);
        Assert.assertTrue(firstQuery.isPresent(), "First query row should be present");
        Assert.assertEquals(firstQuery.get().get("searchTerm"), "backpack");

        Optional<Map<String, String>> outOfBoundsRow = testDataManager.getTableRow("productSearchQueries", 99);
        Assert.assertFalse(outOfBoundsRow.isPresent(), "Out of bounds row should not be present");
    }

    @Test(description = "Verify retrieval of a specific value from a specific row in a data table")
    public void testGetTableValue() {
        Optional<String> expectedCount = testDataManager.getTableValue("productSearchQueries", 1, "expectedCount");
        Assert.assertTrue(expectedCount.isPresent(), "Expected count should be present for second query");
        Assert.assertEquals(expectedCount.get(), "1");

        Optional<String> invalidKey = testDataManager.getTableValue("productSearchQueries", 0, "nonExistentKey");
        Assert.assertFalse(invalidKey.isPresent(), "Non-existent key should not return a value");
    }

    @DataProvider(name = "invalidLoginData")
    public Object[][] getInvalidLoginData() {
        List<Map<String, String>> invalidLogins = testDataManager.getDataTable("invalidLoginAttempts")
                .orElseThrow(() -> new RuntimeException("Invalid login attempts data not found!"));
        
        Object[][] data = new Object[invalidLogins.size()][3]; // username, password, expectedError
        for (int i = 0; i < invalidLogins.size(); i++) {
            Map<String, String> row = invalidLogins.get(i);
            data[i][0] = row.get("username");
            data[i][1] = row.get("password");
            data[i][2] = row.get("expectedError");
        }
        return data;
    }

    @Test(dataProvider = "invalidLoginData", description = "Data-driven test example using TestDataManager")
    public void testInvalidLoginScenarios(String username, String password, String expectedError) {
        System.out.println(String.format("Testing login with User: %s, Pass: %s, Expected Error: %s", username, password, expectedError));
        // In a real test, you would perform UI login actions here and assert the error message
        // For demonstration, we just assert the expected error is not null or empty
        Assert.assertNotNull(expectedError, "Expected error message should not be null");
        Assert.assertFalse(expectedError.isEmpty(), "Expected error message should not be empty");
        // Example: Assert.assertEquals(loginPage.getErrorMessage(), expectedError);
    }
}
```

To run the tests, you'll need TestNG in your `pom.xml`:
```xml
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>7.8.0</version>
    <scope>test</scope>
</dependency>
```
You can run the tests using your IDE or via Maven: `mvn clean test`.

## Best Practices
-   **Separate Data from Code**: Never hardcode test data directly into your test methods. Use a data management utility.
-   **Externalize Data**: Store test data in external files (CSV, JSON, Excel, XML, database) rather than directly in code. This makes it easier for non-developers to update data and allows version control of data.
-   **Clear Naming Conventions**: Use descriptive names for your data sets and table names (e.g., "validLoginCredentials", "productSearchData").
-   **Immutable Data**: Once loaded, consider making the retrieved data immutable to prevent accidental modifications during test execution, especially in parallel testing.
-   **Error Handling**: Implement robust error handling (e.g., using `Optional` as shown, or throwing custom exceptions) for when data is not found.
-   **Lazy Loading**: For very large datasets, consider lazy loading data only when it's needed to conserve memory.
-   **Type Safety**: While `Map<String, String>` is flexible, for complex data objects, consider using POJOs (Plain Old Java Objects) and then mapping your data to these objects for better type safety and compile-time checks.

## Common Pitfalls
-   **Hardcoding Data**: The most common pitfall. Leads to unmaintainable, rigid tests.
-   **Mixing Data Loading Logic**: Directly embedding file reading logic in every test class. This makes the framework harder to maintain and less flexible.
-   **Inconsistent Data Structure**: Using different formats or structures for similar types of test data across the framework, leading to confusion and boilerplate code.
-   **Not Handling Missing Data**: Assuming data will always be present, leading to `NullPointerException`s if a key or dataset is missing. Using `Optional` helps mitigate this.
-   **Performance Overhead**: For extremely large datasets, inefficient loading or parsing can slow down test execution. Optimize data loading if performance becomes an issue.
-   **Security**: Storing sensitive data (like production credentials) directly in plain text files. Always use secure methods for managing sensitive data, such as environment variables, secure vaults, or encrypted files.

## Interview Questions & Answers
1.  **Q: Why is test data management important in test automation?**
    A: Test data management is critical because it separates test data from test logic, making tests more maintainable, reusable, and readable. It facilitates data-driven testing, allows for easy updates of data without code changes, and prevents hardcoding, which can lead to brittle tests. It also helps in managing complex scenarios and enabling parallel execution with unique data.

2.  **Q: How would you design a test data management utility using Java collections?**
    A: I would typically use `Map<String, String>` for individual data records (e.g., login credentials) and `List<Map<String, String>>` for tabular data (e.g., multiple test cases for data-driven testing). The utility would have methods to load this data from external sources (like JSON, CSV, Excel) into these collections and provide safe retrieval methods, possibly using `Optional` to handle missing data gracefully.

3.  **Q: What are the benefits of using `Optional` when retrieving data from your utility?**
    A: `Optional` helps prevent `NullPointerException`s by explicitly indicating that a value might be absent. It forces the developer to consider the case where data is not found, leading to more robust and fault-tolerant code. It improves readability by clearly stating the intent and removes the need for explicit `null` checks everywhere.

4.  **Q: What are the alternatives to using static data in `TestDataManager` for real projects?**
    A: In real projects, test data is externalized. Common alternatives include:
    *   **JSON Files**: Easy to read and write, human-readable, good for structured data.
    *   **CSV Files**: Simple, good for tabular data, easily editable in spreadsheets.
    *   **Excel Files**: Good for large, complex tabular data, accessible to non-technical users.
    *   **Databases**: For very large or dynamic datasets, allows complex queries and integration with data generation tools.
    *   **Environment Variables/Configuration Files**: For sensitive or environment-specific data.

## Hands-on Exercise
**Objective**: Extend the `TestDataManager` to load data from a JSON file.

1.  **Create a JSON file**: In your project's `src/test/resources` directory, create a file named `testdata.json` with content like this:
    ```json
    {
      "users": [
        {
          "type": "admin",
          "username": "admin_user",
          "password": "admin_password"
        },
        {
          "type": "guest",
          "username": "guest_user",
          "password": "guest_password"
        }
      ],
      "config": {
        "baseUrl": "https://www.example.com",
        "timeout": "10000"
      }
    }
    ```
2.  **Add JSON parsing library**: Add a dependency for a JSON parsing library (e.g., `com.fasterxml.jackson.core:jackson-databind` or `org.json:json`) to your `pom.xml`.
3.  **Modify `TestDataManager`**:
    *   Add a new method `loadFromJsonFile(String filePath)` that reads the `testdata.json` file.
    *   Parse the JSON content into appropriate `Map` and `List<Map>` structures.
    *   Integrate this method into the constructor or a separate initialization method.
4.  **Update `TestDataManagerTest`**: Add new test methods to verify that the data from the JSON file is loaded and accessible correctly.

## Additional Resources
*   **Java Collections Framework Tutorial**: [https://docs.oracle.com/javase/tutorial/collections/index.html](https://docs.oracle.com/javase/tutorial/collections/index.html)
*   **Jackson JSON Processor**: [https://github.com/FasterXML/jackson](https://github.com/FasterXML/jackson)
*   **org.json Library**: [https://github.com/stleary/JSON-java](https://github.com/stleary/JSON-java)
*   **Data-Driven Testing in Selenium**: [https://www.toolsqa.com/selenium-webdriver/data-driven-testing-in-selenium/](https://www.toolsqa.com/selenium-webdriver/data-driven-testing-in-selenium/)
*   **Test Data Management Best Practices**: [https://www.tricentis.com/resources/test-data-management-best-practices/](https://www.tricentis.com/resources/test-data-management-best-practices/)
