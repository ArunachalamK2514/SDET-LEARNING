# Data-Driven & Parameterized API Testing Framework

## Overview
In modern API testing, relying on a single set of test data often isn't sufficient to ensure robust and comprehensive coverage. Data-driven testing allows us to execute the same test logic with multiple sets of input data, leading to more thorough validation of API behavior across various scenarios. This feature focuses on building a scalable, data-driven framework for API testing by combining Plain Old Java Objects (POJOs), TestNG's DataProvider, and external data sources like Excel or JSON. This approach promotes reusability, maintainability, and extensibility, enabling test cases to grow effortlessly with new data.

## Detailed Explanation

Data-driven testing separates the test logic from the test data. This separation provides several benefits:
-   **Reusability**: The same test script can be used for different data sets.
-   **Maintainability**: Changes in test data do not require modifications to the test script, and vice-versa.
-   **Coverage**: Easily expand test coverage by simply adding more data rows to the external data source.
-   **Readability**: Test scripts become cleaner and more focused on logic, while data is managed separately in a more human-readable format.

Our framework will integrate the following components:
1.  **POJOs (Plain Old Java Objects)**: Used to model the request and response payloads of our API calls. This provides type safety, better readability, and easier serialization/deserialization.
2.  **TestNG DataProvider**: A powerful TestNG annotation (`@DataProvider`) that allows a test method to receive data from a specified method. This method can return `Object[][]` or `Iterator<Object[]>`, supplying multiple sets of arguments for the test method.
3.  **External Data Source (Excel/JSON)**: Storing test data externally provides flexibility.
    *   **Excel**: Ideal for structured tabular data, easily manageable by non-technical users. Libraries like Apache POI are used for reading.
    *   **JSON**: Excellent for complex, hierarchical data structures, commonly used in API requests and responses. Libraries like Jackson or GSON are used for parsing.

The scalable architecture aims to automatically create new test iterations for each new row of data added to the Excel/JSON file, without modifying the test code.

## Code Implementation

We'll demonstrate this using a `POST` request example where user data is sent to an API.

First, let's define a POJO for our `User` object (assuming a simple registration API).

```java
// src/main/java/com/example/api/payloads/User.java
package com.example.api.payloads;

public class User {
    private String username;
    private String email;
    private String password;
    private String role; // e.g., "user", "admin"

    // Default constructor for deserialization
    public User() {
    }

    public User(String username, String email, String password, String role) {
        this.username = username;
        this.email = email;
        this.password = password;
        this.role = role;
    }

    // Getters and Setters
    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    @Override
    public String toString() {
        return "User{" +
               "username='" + username + ''' +
               ", email='" + email + ''' +
               ", password='" + password + ''' +
               ", role='" + role + ''' +
               '}';
    }
}
```

Next, let's create a utility class to read data from an Excel file. We'll use Apache POI for this. Make sure to add Apache POI dependencies to your `pom.xml` (for Maven) or `build.gradle` (for Gradle).

**`pom.xml` dependencies (if using Maven):**
```xml
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi</artifactId>
    <version>5.2.5</version>
</dependency>
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi-ooxml</artifactId>
    <version>5.2.5</version>
</dependency>
```

```java
// src/main/java/com/example/api/utils/ExcelReader.java
package com.example.api.utils;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class ExcelReader {

    public static Object[][] getExcelData(String filePath, String sheetName) {
        List<Object[]> data = new ArrayList<>();
        try (FileInputStream fis = new FileInputStream(filePath);
             Workbook workbook = new XSSFWorkbook(fis)) {

            Sheet sheet = workbook.getSheet(sheetName);
            if (sheet == null) {
                throw new IllegalArgumentException("Sheet '" + sheetName + "' not found in " + filePath);
            }

            Iterator<Row> rowIterator = sheet.iterator();

            // Skip header row
            if (rowIterator.hasNext()) {
                rowIterator.next();
            }

            while (rowIterator.hasNext()) {
                Row row = rowIterator.next();
                List<String> rowData = new ArrayList<>();
                Iterator<Cell> cellIterator = row.cellIterator();

                while (cellIterator.hasNext()) {
                    Cell cell = cellIterator.next();
                    // Handle different cell types
                    switch (cell.getCellType()) {
                        case STRING:
                            rowData.add(cell.getStringCellValue());
                            break;
                        case NUMERIC:
                            // If it's a number, read as string or convert to appropriate type
                            rowData.add(String.valueOf((int) cell.getNumericCellValue()));
                            break;
                        case BOOLEAN:
                            rowData.add(String.valueOf(cell.getBooleanCellValue()));
                            break;
                        case FORMULA:
                            rowData.add(cell.getCellFormula());
                            break;
                        case BLANK:
                            rowData.add(""); // Treat blank cells as empty strings
                            break;
                        default:
                            rowData.add(cell.toString());
                    }
                }
                if (!rowData.isEmpty()) { // Only add if row has data
                    data.add(rowData.toArray(new String[0]));
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
            // In a real framework, you'd log this and potentially re-throw a custom exception
            throw new RuntimeException("Failed to read Excel file: " + filePath, e);
        }
        return data.toArray(new Object[0][0]);
    }
}
```

Now, let's integrate this with TestNG's DataProvider. We'll also use RestAssured for API calls.
Add RestAssured and TestNG dependencies:
```xml
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <version>5.3.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>7.8.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.17.0</version>
</dependency>
```

**`Users.xlsx` (Example Data File in `src/test/resources/`):**

| Username | Email               | Password   | Role   |
|----------|---------------------|------------|--------|
| user1    | user1@example.com   | pass123    | user   |
| admin1   | admin1@example.com  | adminpass  | admin  |
| guest    | guest@example.com   | guestpass  | guest  |
| user2    | user2@example.com   | password456| user   |


```java
// src/test/java/com/example/api/tests/UserRegistrationTest.java
package com.example.api.tests;

import com.example.api.payloads.User;
import com.example.api.utils.ExcelReader;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import static io.restassured.RestAssured.given;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

public class UserRegistrationTest {

    private static final String BASE_URL = "http://localhost:8080/api"; // Replace with your actual API base URL
    private static final String EXCEL_FILE_PATH = "src/test/resources/Users.xlsx";
    private static final String SHEET_NAME = "Users";

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URL;
        // Optionally, you can set common headers, authentication, etc.
        // RestAssured.authentication = basic("username", "password");
    }

    @DataProvider(name = "userData")
    public Object[][] getUserData() {
        // Read data from Excel and return it as Object[][]
        // Each inner array represents a row, and elements are column values
        Object[][] excelData = ExcelReader.getExcelData(EXCEL_FILE_PATH, SHEET_NAME);

        // Convert String[] from ExcelReader to User POJO for type-safety and easier use in test
        Object[][] userData = new Object[excelData.length][1];
        for (int i = 0; i < excelData.length; i++) {
            String[] row = (String[]) excelData[i];
            // Assuming order: username, email, password, role
            User user = new User(row[0], row[1], row[2], row[3]);
            userData[i][0] = user;
        }
        return userData;
    }

    @Test(dataProvider = "userData")
    public void testUserRegistration(User user) throws IOException {
        System.out.println("Testing registration for user: " + user.getUsername());

        // Use ObjectMapper to convert POJO to JSON string
        ObjectMapper objectMapper = new ObjectMapper();
        String requestBody = objectMapper.writeValueAsString(user);

        Response response = given()
                .contentType(ContentType.JSON)
                .body(requestBody)
                .log().all() // Log request details
            .when()
                .post("/register") // Assuming /register endpoint for user registration
            .then()
                .log().all() // Log response details
                .extract().response();

        // Assertions
        assertEquals(response.statusCode(), 201, "Expected status code 201 for successful registration");

        // Further assertions based on response body
        // For example, if the API returns the registered user's ID or a success message
        assertNotNull(response.jsonPath().getString("id"), "User ID should not be null in response");
        assertEquals(response.jsonPath().getString("username"), user.getUsername(), "Username in response should match request");
        // Add more assertions as per your API's expected successful response
    }

    // Example of a negative test case using a different data provider or specific data
    @Test
    public void testRegistrationWithInvalidEmail() {
        User invalidUser = new User("baduser", "invalid-email", "pass123", "user");
        ObjectMapper objectMapper = new ObjectMapper();
        String requestBody = null;
        try {
            requestBody = objectMapper.writeValueAsString(invalidUser);
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException("Failed to serialize invalid user object", e);
        }

        Response response = given()
                .contentType(ContentType.JSON)
                .body(requestBody)
            .when()
                .post("/register")
            .then()
                .extract().response();

        assertEquals(response.statusCode(), 400, "Expected status code 400 for invalid email");
        assertNotNull(response.jsonPath().getString("message"), "Error message should not be null");
        // Further assertions on the error message content
    }
}
```

**Note on Scalability:**
The `getUserData()` DataProvider directly uses `ExcelReader.getExcelData()`. This means that every time you add a new row of user data to `Users.xlsx` under the `Users` sheet, a new test iteration will automatically be generated for `testUserRegistration` without any code changes. This is the essence of a scalable data-driven architecture.

### Documenting the Data Format

It's crucial to document the expected data format for external data sources to ensure consistency and prevent errors.

**For `Users.xlsx` (Sheet: `Users`)**

| Column Header | Description                                    | Data Type | Constraints                                      | Example         |
|---------------|------------------------------------------------|-----------|--------------------------------------------------|-----------------|
| `Username`    | Unique identifier for the user.                | String    | Min 3, Max 20 characters, alphanumeric           | `john.doe`      |
| `Email`       | User's email address. Must be unique.          | String    | Valid email format                               | `john@example.com`|
| `Password`    | User's password.                               | String    | Min 8 characters, at least one uppercase, one digit, one special character | `P@ssw0rd1!`    |
| `Role`        | User's role/permission level.                  | String    | `user`, `admin`, `guest` (enum-like)             | `user`          |

## Best Practices
-   **Separate Data from Code**: Always keep test data in external files (Excel, JSON, CSV, DB) rather than hardcoding it in test scripts.
-   **POJO Usage**: Use POJOs for request and response bodies. This makes your code type-safe, readable, and easier to refactor, and leverages Jackson/Gson for seamless serialization/deserialization.
-   **Centralized Data Providers**: Create dedicated classes or methods for DataProviders to encapsulate data reading logic, promoting reusability across different test classes.
-   **Robust Error Handling**: Implement comprehensive error handling in your data reading utilities (e.g., for file not found, incorrect sheet name, invalid data format).
-   **Version Control Data Files**: Include your data files (e.g., `Users.xlsx`) in version control to track changes and ensure all team members use the same test data.
-   **Parameterized Tests for All Scenarios**: Use data-driven approaches not just for positive cases but also for negative, boundary, and edge cases to ensure full coverage.
-   **Meaningful Test Data**: Use realistic and diverse test data that covers various scenarios, including valid, invalid, boundary, and edge cases.

## Common Pitfalls
-   **Hardcoding File Paths**: Avoid hardcoding file paths. Use `System.getProperty("user.dir")` or `ClassLoader.getResource()` to make paths relative and environment-agnostic.
-   **Ignoring Header Row**: For structured data like Excel, remember to skip the header row when iterating through data to avoid processing it as test data.
-   **Not Handling Different Cell Types**: Excel cells can contain strings, numbers, booleans, formulas, etc. Failing to handle these gracefully in your Excel reader can lead to `IllegalStateException` or incorrect data.
-   **Large Data Sets in Memory**: For extremely large data sets, reading the entire file into `Object[][]` might consume too much memory. Consider using an `Iterator<Object[]>` with TestNG DataProvider to process data row by row, or stream data.
-   **Inconsistent Data Schema**: Changes in the external data file's schema (e.g., column reordering, name changes) can break your data reading logic if not handled flexibly (e.g., by using column names instead of indices).
-   **Lack of Documentation**: Without proper documentation of the expected data format, it becomes challenging for others (or your future self) to add or modify test data correctly.

## Interview Questions & Answers
1.  **Q: What is data-driven testing in the context of API automation, and why is it important?**
    **A:** Data-driven testing is an approach where test data is stored externally (e.g., in Excel, JSON, XML, databases) and loaded into the test scripts at runtime. The same test logic is executed multiple times with different sets of input data. It's crucial for API automation because APIs often handle diverse inputs and scenarios. It helps achieve broader test coverage, reduces code duplication, makes tests more maintainable, and allows for easy expansion of test cases by simply adding new data without altering the code.

2.  **Q: How do you implement data-driven testing using TestNG?**
    **A:** In TestNG, data-driven testing is primarily implemented using the `@DataProvider` annotation. A method annotated with `@DataProvider` returns an `Object[][]` or `Iterator<Object[]>`, where each inner array/object array represents a set of parameters for a test method. The test method then uses the `dataProvider` attribute in its `@Test` annotation to specify which data provider to use, receiving the data as method arguments.

3.  **Q: Discuss the advantages and disadvantages of using Excel vs. JSON for API test data.**
    **A:**
    *   **Excel Advantages**: User-friendly for non-technical team members, good for tabular data, easy to visualize.
    *   **Excel Disadvantages**: Requires external libraries (like Apache POI), can be cumbersome for complex nested data structures, prone to manual errors, performance overhead for very large files.
    *   **JSON Advantages**: Native format for many APIs, excellent for complex and hierarchical data, easily parsable by libraries, human-readable for developers, lightweight.
    *   **JSON Disadvantages**: Less user-friendly for non-technical users to edit directly, not ideal for simple tabular data that might be clearer in a spreadsheet.

4.  **Q: How do POJOs contribute to robust API testing, especially in a data-driven framework?**
    **A:** POJOs (Plain Old Java Objects) provide a strong, type-safe contract for API request and response payloads. In a data-driven framework, when you read data from an external source (like Excel) and need to form a request body, mapping this raw data into a POJO ensures that the data conforms to the expected structure and types. It prevents runtime errors due to type mismatches, improves code readability, and allows for easy serialization (POJO to JSON/XML) and deserialization (JSON/XML to POJO) using libraries like Jackson or GSON, which is essential for working with API payloads.

5.  **Q: What considerations are important for creating a "scalable" data-driven architecture?**
    **A:** A scalable data-driven architecture should:
    *   **Decouple data from logic**: Changes in data shouldn't require code changes.
    *   **Support multiple data sources**: Be flexible enough to switch between Excel, JSON, CSV, databases, etc., with minimal code impact.
    *   **Handle varying data sizes**: Efficiently manage small to very large datasets, potentially using iterative parsing instead of loading everything into memory.
    *   **Clear data contracts**: Have well-defined and documented data formats.
    *   **Automated test generation**: New data entries should ideally translate directly into new test iterations without manual intervention in code. Our TestNG `@DataProvider` combined with a generic data reader achieves this for new rows.
    *   **Error reporting**: Provide clear reports on which data set failed and why.

## Hands-on Exercise

**Scenario**: You are testing an e-commerce API endpoint for product creation (`POST /products`).

**Task**:
1.  **Create a `Product` POJO**: Define fields like `name`, `description`, `price`, `category`, `stock`.
2.  **Prepare an Excel file**: Create an `Products.xlsx` file with a sheet named `Products`. Populate it with at least 5 rows of diverse product data, including valid and invalid cases (e.g., negative price, empty name).
3.  **Implement `ExcelReader`**: If not already done, ensure you have an `ExcelReader` utility that can read your product data into a `Object[][]`.
4.  **Create a TestNG Test Class**:
    *   Implement a `@DataProvider` method that reads data from `Products.xlsx` and converts each row into a `Product` POJO.
    *   Create a `@Test` method that accepts a `Product` POJO.
    *   Inside the test method, use RestAssured to send a `POST` request to `/products` with the `Product` POJO serialized as JSON.
    *   Include assertions for successful product creation (e.g., status code 201, product ID returned) and appropriate error handling/assertions for invalid product data (e.g., status code 400).
5.  **Run and Verify**: Execute your TestNG tests and ensure that all data sets are processed, and assertions pass/fail as expected.

## Additional Resources
-   **TestNG DataProvider Documentation**: [https://testng.org/doc/documentation-main.html#parameters-dataproviders](https://testng.org/doc/documentation-main.html#parameters-dataproviders)
-   **Apache POI Project**: [https://poi.apache.org/](https://poi.apache.org/)
-   **RestAssured Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Jackson Databind GitHub**: [https://github.com/FasterXML/jackson-databind](https://github.com/FasterXML/jackson-databind)
-   **Tutorial: Data-Driven Testing in REST Assured with TestNG DataProvider and Excel**: [https://www.toolsqa.com/rest-assured/data-driven-testing-in-rest-assured/](https://www.toolsqa.com/rest-assured/data-driven-testing-in-rest-assured/) (Example, search for updated or similar resources if this one is outdated)