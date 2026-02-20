# api-4.4-ac1.md

# Data-Driven API Testing with REST Assured and TestNG DataProvider

## Overview
Data-driven testing is a strategy where test data is stored externally and loaded into tests at runtime. This approach significantly enhances test coverage and reusability, especially for API testing where endpoints might behave differently based on various input parameters. When combined with REST Assured, a powerful Java library for testing RESTful APIs, and TestNG's `DataProvider`, we can create robust, maintainable, and highly efficient API test suites. This document will guide you through integrating REST Assured with TestNG `DataProvider` to perform data-driven API testing, enabling you to test multiple scenarios with minimal code duplication.

## Detailed Explanation
TestNG's `DataProvider` is an annotation that marks a method as supplying data for a test method. The data provider method must return a `Object[][]` where each inner `Object[]` represents a set of parameters for a single invocation of the test method. REST Assured will then consume this data to construct dynamic API requests.

The process involves three main steps:
1.  **Create a DataProvider Method**: This method will generate the test data. It's typically placed in the same test class or a separate utility class.
2.  **Link DataProvider to a @Test Method**: The `@Test` method is linked to the `DataProvider` using the `dataProvider` attribute, and its parameters must match the data types provided by the `DataProvider`.
3.  **Use Data to Build Dynamic API Requests**: Inside the `@Test` method, the received data can be used to set request parameters, headers, or even the request body, making the API call dynamic for each data set.

### Why use DataProvider?
*   **Reduced Code Duplication**: Avoid writing separate test methods for each data set.
*   **Improved Readability**: Test methods remain clean and focused on the test logic, while data is managed separately.
*   **Enhanced Test Coverage**: Easily test various positive, negative, and edge-case scenarios by simply adding more data to the `DataProvider`.
*   **Better Maintainability**: Changes to test data don't require modifications to the test logic.

## Code Implementation

Let's consider an example where we want to test a `POST /users` endpoint that creates a new user. We'll use `DataProvider` to supply different user details.

```java
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

public class UserCreationTest {

    // Base URI for the API
    private static final String BASE_URI = "https://reqres.in/api";

    @DataProvider(name = "userData")
    public Object[][] getUserData() {
        // Each inner array represents a set of parameters for one test invocation:
        // { name, job, expectedStatusCode, expectedNameInResponse, expectedJobInResponse }
        return new Object[][] {
            // Positive test case
            {"Morpheus", "leader", 201, "Morpheus", "leader"},
            // Another positive test case
            {"Neo", "zion resident", 201, "Neo", "zion resident"},
            // Test case with missing job (assuming API handles it or returns an error)
            {"Agent Smith", "", 201, "Agent Smith", ""}, // reqres.in allows empty job
            // Test case with very long name (edge case)
            {"VeryLongNameThatExceedsStandardLengthLimits", "tester", 201, "VeryLongNameThatExceedsStandardLengthLimits", "tester"}
            // Note: reqres.in often returns 201 for POST even with invalid data, 
            // a real API might return 400 or 422 for certain invalid inputs.
            // Adjust expectedStatusCode based on actual API behavior.
        };
    }

    @Test(dataProvider = "userData")
    public void testCreateUserWithDataProvider(String name, String job, int expectedStatusCode, String expectedNameInResponse, String expectedJobInResponse) {
        RestAssured.baseURI = BASE_URI;

        // Construct request body dynamically using provided data
        String requestBody = "{"name": "" + name + "", "job": "" + job + ""}";

        System.out.println("Testing with Name: " + name + ", Job: " + job);

        given()
            .contentType(ContentType.JSON)
            .body(requestBody)
        .when()
            .post("/users")
        .then()
            .log().all() // Log all response details for debugging
            .assertThat()
            .statusCode(expectedStatusCode)
            .body("name", equalTo(expectedNameInResponse))
            .body("job", equalTo(expectedJobInResponse))
            .body("id", notNullValue()) // Assert that an ID is generated
            .body("createdAt", notNullValue()); // Assert that creation timestamp is present
    }

    @Test
    public void setup() {
        // Optional: Can be used for global setup if needed, e.g., setting filters
        // RestAssured.filters(new RequestLoggingFilter(), new ResponseLoggingFilter());
    }
}
```

### Explanation of the Code:
*   `@DataProvider(name = "userData")`: This annotation defines a data provider named "userData".
*   `getUserData()`: This method returns a `Object[][]`. Each `Object[]` contains the `name`, `job`, `expectedStatusCode`, `expectedNameInResponse`, and `expectedJobInResponse` for a single test run.
*   `@Test(dataProvider = "userData")`: This links the `testCreateUserWithDataProvider` method to the "userData" data provider. TestNG will call this test method once for each `Object[]` returned by `getUserData()`, passing the elements of the array as method arguments.
*   `given().contentType(ContentType.JSON).body(requestBody)`: The request body is constructed dynamically using the `name` and `job` parameters received from the data provider.
*   `.post("/users")`: Sends the POST request.
*   `.then().statusCode(expectedStatusCode).body(...)`: Asserts the response status code and body content based on the expected values provided by the `DataProvider`.

## Best Practices
-   **Separate Data from Tests**: Ideally, keep your test data in external files (CSV, Excel, JSON, YAML) and have the `DataProvider` method read from these files. This further separates data from code and makes data management easier.
-   **Meaningful DataProvider Names**: Use descriptive names for your data providers (e.g., `validUserCredentials`, `invalidLoginAttempts`).
-   **Diverse Test Data**: Include a variety of test data, covering positive, negative, boundary, and edge cases to maximize test coverage.
-   **Handle DataProvider Exceptions**: Implement robust error handling within your `DataProvider` method, especially when reading from external sources.
-   **Logging**: Use `log().all()` or specific logging filters in REST Assured to log request and response details. This is invaluable for debugging data-driven tests.
-   **Keep DataProviders Concise**: If a `DataProvider` becomes too complex, consider breaking it down into smaller, focused data providers or using a factory pattern.

## Common Pitfalls
-   **Mismatched Parameters**: The number and type of arguments in the `@Test` method must exactly match the elements in each `Object[]` returned by the `DataProvider`. A mismatch will lead to runtime errors.
-   **Hardcoding Data**: Avoid hardcoding test data directly within the `@Test` method when it should be coming from the `DataProvider`. This defeats the purpose of data-driven testing.
-   **Overly Complex DataProviders**: If your `DataProvider` logic becomes too convoluted (e.g., complex calculations, multiple external file reads), it might be a sign to refactor or simplify it.
-   **Ignoring Negative Scenarios**: Only testing positive scenarios with data-driven tests misses a significant portion of test coverage. Always include invalid inputs.
-   **Performance Overhead**: For a very large number of data sets, `DataProvider` can lead to many test invocations. Consider optimizing data loading or using parallel execution features of TestNG if performance becomes an issue.

## Interview Questions & Answers
1.  **Q: What is data-driven testing, and why is it important in API automation?**
    A: Data-driven testing is an automation approach where test input values and expected outputs are stored in an external source (like a spreadsheet, database, or JSON file) rather than being hardcoded into the test script. It's crucial in API automation because APIs often handle diverse inputs and produce varying outputs. Data-driven testing allows a single test script to be executed multiple times with different data sets, ensuring comprehensive coverage, reducing code duplication, and making tests more maintainable.

2.  **Q: How does TestNG's `DataProvider` facilitate data-driven testing with REST Assured?**
    A: `DataProvider` in TestNG is an annotation used to supply data to test methods. A method annotated with `@DataProvider` returns a `Object[][]`, where each inner array provides a set of parameters for a single invocation of a `@Test` method. When used with REST Assured, the `@Test` method consumes these parameters to dynamically construct API requests (e.g., setting path parameters, query parameters, or request body) and validate responses, allowing the same test logic to be applied to many different data scenarios.

3.  **Q: Can you describe a scenario where you would use an external data source (like CSV or JSON) with `DataProvider` for API testing?**
    A: Absolutely. Imagine testing an e-commerce "add item to cart" API. We might have various scenarios: adding a valid product, an out-of-stock product, a product with an invalid ID, or adding multiple quantities. Instead of hardcoding these product IDs and expected outcomes, we could store them in a CSV file. The `DataProvider` method would read this CSV file, parse each row into an `Object[]`, and the `@Test` method would then use this data to make dynamic `POST /cart/add` requests and assert the appropriate responses (e.g., 200 OK for valid, 400 Bad Request for invalid ID, 409 Conflict for out-of-stock).

## Hands-on Exercise
**Scenario**: Test a `PUT /users/{id}` endpoint to update user information.

**Task**:
1.  Create a TestNG class named `UserUpdateTest`.
2.  Implement a `DataProvider` that provides data for updating existing users. The data should include:
    *   `userId` (the ID of the user to update)
    *   `newName` (the new name for the user)
    *   `newJob` (the new job for the user)
    *   `expectedStatusCode` (e.g., 200)
    *   `expectedNameInResponse`
    *   `expectedJobInResponse`
3.  Create a `@Test` method that uses this `DataProvider`.
4.  Inside the test method, use REST Assured to send a `PUT` request to `https://reqres.in/api/users/{id}`.
5.  Dynamically set the path parameter `{id}` and the request body using the `DataProvider` values.
6.  Assert the response status code and ensure the updated `name` and `job` are present in the response body.
7.  Include at least three distinct data sets in your `DataProvider`.

**Hint**: You can obtain user IDs from the `GET /users` endpoint (e.g., `https://reqres.in/api/users?page=2`) or assume some common IDs like 2, 7, 10.

## Additional Resources
-   **TestNG DataProviders**: [https://testng.org/doc/documentation-main.html#data-providers](https://testng.org/doc/documentation-main.html#data-providers)
-   **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Data-Driven Testing with TestNG**: [https://www.toolsqa.com/testng/data-driven-testing-in-testng/](https://www.toolsqa.com/testng/data-driven-testing-in-testng/)
-   **ReqRes.in API (for practice)**: [https://reqres.in/](https://reqres.in/)
---
# api-4.4-ac2.md

# Data-Driven & Parameterized API Testing with Excel

## Overview
In modern API testing, ensuring comprehensive coverage often requires testing the same API endpoint with varying sets of input data. Data-driven testing (DDT) is a powerful approach that allows test cases to be executed multiple times with different data inputs, significantly enhancing test coverage and efficiency. When combined with TestNG's DataProvider and external data sources like Excel, this methodology becomes highly flexible and maintainable. This section explores how to implement data-driven API testing using Apache POI to read data from Excel files and feeding it into TestNG DataProviders.

## Detailed Explanation
Data-driven testing separates test logic from test data. Instead of hardcoding test data within test scripts, it's stored externally in sources like Excel spreadsheets, CSV files, or databases. This approach offers several benefits:
- **Reusability**: Test scripts can be reused with different data sets without modification.
- **Maintainability**: Test data can be easily updated without touching the test code.
- **Coverage**: Allows for testing various scenarios, including positive, negative, and edge cases, by simply adding new rows to the data source.

For Java-based projects, Apache POI is a popular API for working with Microsoft Office format files, including `.xls` and `.xlsx` Excel files. TestNG's `@DataProvider` annotation is perfectly suited to supply this external data to test methods.

The typical workflow involves:
1.  **Prepare Excel Data**: Create an Excel file (`.xlsx` or `.xls`) with test data, where each row represents a test case and columns represent the parameters for that test case.
2.  **Read Excel using Apache POI**: Implement a utility method (or class) that uses Apache POI to read data from the Excel file. This method will parse the file and return the data in a format compatible with TestNG's DataProvider, typically a `Object[][]`.
3.  **Create TestNG DataProvider**: Define a `@DataProvider` method in your test class that calls the Excel reading utility and returns the `Object[][]`.
4.  **Integrate with API Test**: Associate your API test method with the `@DataProvider`. The test method will then execute once for each row of data provided by the DataProvider, receiving the data as method parameters.

## Code Implementation

First, ensure you have the necessary dependencies in your `pom.xml` for Apache POI and TestNG (assuming a Maven project):

```xml
<dependencies>
    <!-- TestNG -->
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version>
        <scope>test</scope>
    </dependency>

    <!-- REST Assured for API testing -->
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.3.0</version>
        <scope>test</scope>
    </dependency>

    <!-- Apache POI for Excel operations -->
    <dependency>
        <groupId>org.apache.poi</groupId>
        <artifactId>poi</artifactId>
        <version>5.2.3</version>
    </dependency>
    <dependency>
        <groupId>org.apache.poi</groupId>
        <artifactId>poi-ooxml</artifactId>
        <version>5.2.3</version>
    </dependency>
</dependencies>
```

**1. `ExcelDataReader.java` - Utility to Read Excel Data**

```java
package utils;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class ExcelDataReader {

    /**
     * Reads data from a specified Excel sheet and returns it as a 2D Object array.
     * The first row is treated as headers and is skipped.
     *
     * @param filePath The path to the Excel file.
     * @param sheetName The name of the sheet to read.
     * @return A 2D Object array containing the Excel data, or null if an error occurs.
     */
    public static Object[][] getExcelData(String filePath, String sheetName) {
        List<List<Object>> data = new ArrayList<>();
        FileInputStream fis = null;
        Workbook workbook = null;

        try {
            fis = new FileInputStream(filePath);
            workbook = new XSSFWorkbook(fis); // For .xlsx files
            // For .xls files, use new HSSFWorkbook(fis);

            Sheet sheet = workbook.getSheet(sheetName);
            if (sheet == null) {
                System.err.println("Sheet '" + sheetName + "' not found in " + filePath);
                return null;
            }

            Iterator<Row> rowIterator = sheet.iterator();

            // Skip header row
            if (rowIterator.hasNext()) {
                rowIterator.next();
            }

            while (rowIterator.hasNext()) {
                Row row = rowIterator.next();
                List<Object> rowData = new ArrayList<>();
                Iterator<Cell> cellIterator = row.cellIterator();

                while (cellIterator.hasNext()) {
                    Cell cell = cellIterator.next();
                    // Handle different cell types
                    switch (cell.getCellType()) {
                        case STRING:
                            rowData.add(cell.getStringCellValue());
                            break;
                        case NUMERIC:
                            // Check if it's a date
                            if (DateUtil.isCellDateFormatted(cell)) {
                                rowData.add(cell.getDateCellValue());
                            } else {
                                rowData.add(cell.getNumericCellValue());
                            }
                            break;
                        case BOOLEAN:
                            rowData.add(cell.getBooleanCellValue());
                            break;
                        case FORMULA:
                            // Evaluate formula to get its result
                            FormulaEvaluator evaluator = workbook.getCreationHelper().createFormulaEvaluator();
                            CellValue cellValue = evaluator.evaluate(cell);
                            switch (cellValue.getCellType()) {
                                case STRING:
                                    rowData.add(cellValue.getStringValue());
                                    break;
                                case NUMERIC:
                                    rowData.add(cellValue.getNumberValue());
                                    break;
                                case BOOLEAN:
                                    rowData.add(cellValue.getBooleanValue());
                                    break;
                                case ERROR:
                                    rowData.add(cellValue.getErrorValue());
                                    break;
                                default:
                                    rowData.add(""); // Or null, depending on requirements
                            }
                            break;
                        case BLANK:
                            rowData.add(""); // Treat blank cells as empty strings
                            break;
                        default:
                            rowData.add("");
                    }
                }
                data.add(rowData);
            }

        } catch (IOException e) {
            System.err.println("Error reading Excel file: " + e.getMessage());
            e.printStackTrace();
            return null;
        } finally {
            try {
                if (workbook != null) workbook.close();
                if (fis != null) fis.close();
            } catch (IOException e) {
                System.err.println("Error closing resources: " + e.getMessage());
            }
        }

        // Convert List<List<Object>> to Object[][]
        Object[][] array = new Object[data.size()][];
        for (int i = 0; i < data.size(); i++) {
            array[i] = data.get(i).toArray(new Object[0]);
        }
        return array;
    }
}
```

**2. `ApiTestData.xlsx` - Sample Excel Data File**

Create an Excel file named `ApiTestData.xlsx` in your project's `src/test/resources` directory (or any other accessible location), with a sheet named `CreateUser` and content like this:

| FirstName | LastName | Email            | ExpectedStatusCode |
|-----------|----------|------------------|--------------------|
| John      | Doe      | john.doe@example.com | 201                |
| Jane      | Smith    | jane.smith@example.com | 201                |
| Peter     | Jones    | invalid          | 400                |
| Alice     | Brown    | alice@example.com | 201                |


**3. `UserApiService.java` - Service Layer for API Calls (Example)**

```java
package services;

import io.restassured.http.ContentType;
import io.restassured.response.Response;

import static io.restassured.RestAssured.given;

public class UserApiService {

    private static final String BASE_URI = "https://api.example.com"; // Replace with your actual API base URI

    /**
     * Creates a new user via API.
     * @param firstName User's first name
     * @param lastName User's last name
     * @param email User's email
     * @return REST Assured Response object
     */
    public Response createUser(String firstName, String lastName, String email) {
        String requestBody = String.format("{ "firstName": "%s", "lastName": "%s", "email": "%s" }",
                firstName, lastName, email);

        return given()
                .contentType(ContentType.JSON)
                .body(requestBody)
                .post(BASE_URI + "/users"); // Replace with your actual create user endpoint
    }

    // Add other API methods as needed
}
```

**4. `CreateUserTests.java` - TestNG Test Class with DataProvider**

```java
package tests;

import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;
import services.UserApiService;
import utils.ExcelDataReader;
import io.restassured.response.Response;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotNull;

public class CreateUserTests {

    private final UserApiService userApiService = new UserApiService();
    private static final String EXCEL_FILE_PATH = "src/test/resources/ApiTestData.xlsx";
    private static final String SHEET_NAME = "CreateUser";

    @DataProvider(name = "userData")
    public Object[][] getUserData() {
        // Read data from Excel using the utility method
        Object[][] data = ExcelDataReader.getExcelData(EXCEL_FILE_PATH, SHEET_NAME);
        if (data == null) {
            throw new RuntimeException("Failed to load test data from Excel file: " + EXCEL_FILE_PATH);
        }
        return data;
    }

    @Test(dataProvider = "userData", description = "Verify user creation API with various data from Excel")
    public void testCreateUser(String firstName, String lastName, String email, String expectedStatusCodeStr) {
        int expectedStatusCode = Integer.parseInt(expectedStatusCodeStr);

        // Log the data being used for the current test iteration
        System.out.printf("Testing user creation with -> FirstName: %s, LastName: %s, Email: %s, Expected Status: %d%n",
                          firstName, lastName, email, expectedStatusCode);

        // Perform the API call
        Response response = userApiService.createUser(firstName, lastName, email);

        // Assertions
        assertNotNull(response, "API response should not be null");
        assertEquals(response.statusCode(), expectedStatusCode,
                     "Unexpected status code for user: " + email + ". Response: " + response.asString());

        // Further assertions based on successful creation (e.g., response body parsing)
        if (expectedStatusCode == 201) {
            String userId = response.jsonPath().getString("id"); // Assuming API returns an 'id' for new user
            assertNotNull(userId, "User ID should not be null for successful creation");
            System.out.println("Successfully created user with ID: " + userId + " and email: " + email);
        }
    }
}
```

**Project Structure:**
```
.
├── pom.xml
└── src
    └── test
        ├── java
        │   ├── services
        │   │   └── UserApiService.java
        │   ├── tests
        │   │   └── CreateUserTests.java
        │   └── utils
        │       └── ExcelDataReader.java
        └── resources
            └── ApiTestData.xlsx
```

## Best Practices
- **Separate Data from Code**: Always keep your test data external to your test scripts. This improves maintainability and allows non-technical team members to contribute to test data creation.
- **Clear Excel Structure**: Use meaningful column headers in your Excel sheets. Each sheet can correspond to a specific test scenario or API endpoint.
- **Error Handling**: Implement robust error handling in your Excel data reader to gracefully manage scenarios like file not found, sheet not found, or malformed data.
- **Type Conversion**: Be mindful of data types when reading from Excel. Excel cells can contain strings, numbers, dates, booleans, etc. Ensure your `ExcelDataReader` correctly converts these to appropriate Java types, and that your test methods expect the correct types.
- **Parameter Naming**: Use descriptive parameter names in your `@Test` method that clearly indicate the data they represent, aligning with your Excel column headers.
- **Resource Management**: Always ensure `FileInputStream` and `Workbook` objects are properly closed in a `finally` block to prevent resource leaks.
- **Small, Focused DataProviders**: While a DataProvider can return a large dataset, for very complex scenarios, consider breaking down your Excel file or DataProvider into smaller, more manageable units.

## Common Pitfalls
- **Incorrect File Path/Sheet Name**: A common mistake is providing an incorrect path to the Excel file or a misspelled sheet name, leading to `FileNotFoundException` or `NullPointerException`. Always double-check these.
- **Data Type Mismatches**: Expecting a `String` but receiving a `Double` (e.g., a numeric value read as a double by POI) can lead to `ClassCastException` or incorrect test logic. Explicitly handle type conversions.
- **Header Row Issues**: Forgetting to skip the header row can lead to the header data being processed as actual test data, resulting in test failures or exceptions.
- **Large Excel Files**: Reading extremely large Excel files into memory can cause `OutOfMemoryError`. For very big datasets, consider streaming data or processing in chunks if your framework allows, though for typical API testing, this is rarely an issue.
- **Missing Apache POI Dependencies**: Forgetting to add both `poi` and `poi-ooxml` dependencies (for `.xlsx` files) will lead to `NoClassDefFoundError` or `InvalidFormatException`.
- **Hardcoding API Endpoints**: While `BASE_URI` is defined in `UserApiService`, ensure dynamic parts of endpoints (like IDs) are parameterized and driven by test data where appropriate.

## Interview Questions & Answers
1.  **Q: Explain Data-Driven Testing (DDT) and its benefits in API automation.**
    **A:** Data-Driven Testing (DDT) is a test automation methodology where test data is externalized from the test logic. Test scripts are designed to execute multiple times, each time with a different set of input data read from an external source (e.g., Excel, CSV, database).
    **Benefits in API Automation:**
    -   **Increased Coverage:** Allows testing of various scenarios (valid, invalid, edge cases) without writing separate test cases for each.
    -   **Reusability:** The same test script can be reused with different data sets.
    -   **Maintainability:** Test data can be updated or extended without modifying the test code, simplifying maintenance.
    -   **Efficiency:** Automates repetitive tasks of running tests with different inputs.
    -   **Collaboration:** Test data can be managed by non-technical stakeholders (e.g., business analysts) in easily accessible formats like Excel.

2.  **Q: How do you integrate Excel data with TestNG DataProviders for API testing?**
    **A:** The integration involves a few key steps:
    -   **Apache POI**: Use Apache POI library to read data from an Excel file (`.xlsx` or `.xls`) into a Java `Object[][]`. This typically involves opening the workbook, navigating to the desired sheet, iterating through rows, and then iterating through cells to extract data, handling different cell types appropriately.
    -   **TestNG DataProvider**: Create a public method annotated with `@DataProvider` in your TestNG test class. This method will call the Apache POI utility to fetch the data and return it as `Object[][]`.
    -   **Test Method**: Link your API test method to this DataProvider by specifying `dataProvider = "yourDataProviderName"` in its `@Test` annotation. The test method's parameters should match the order and type of data columns returned by the DataProvider. Each row from the Excel file will then result in a separate invocation of the test method.

3.  **Q: What are the challenges of using Excel as a data source for DDT and how can they be mitigated?**
    **A:**
    -   **Data Type Management**: Excel stores all data as strings internally, requiring explicit type conversion (e.g., to `int`, `double`, `boolean`) in Java.
        *   *Mitigation:* Implement robust type handling in the Excel data reader, potentially inferring types or providing mechanisms to specify expected types.
    -   **Performance with Large Datasets**: Reading very large Excel files (tens of thousands of rows/columns) into memory can lead to performance issues or `OutOfMemoryError`.
        *   *Mitigation:* For extremely large datasets, consider alternative data sources (databases), or implement streaming/chunking mechanisms if feasible with Apache POI. For typical test data, this is often not an issue.
    -   **Concurrency Issues**: If multiple tests or threads try to access and modify the same Excel file concurrently, it can lead to data corruption or race conditions.
        *   *Mitigation:* Treat Excel files as read-only during test execution. If data modification is needed, do it before test execution or use unique test data sets per thread.
    -   **Maintainability & Version Control**: Managing Excel files in version control systems (like Git) can be cumbersome, as they are binary files and difficult to diff.
        *   *Mitigation:* Keep Excel files focused and specific. Consider using more text-friendly formats like CSV for simpler data sets, which are easier to version control. Document the Excel file structure clearly.

## Hands-on Exercise
1.  **Modify Existing Test**: Take an existing API test in your project (e.g., a GET or POST request).
2.  **Create Excel File**: Create an Excel file (`e.g., `api_test_data.xlsx`) with at least 3-4 rows of test data for your chosen API, including various valid and invalid inputs, and an expected status code or response message for each row.
3.  **Implement ExcelDataReader**: Adapt or use the `ExcelDataReader.java` provided above to read your Excel file.
4.  **Integrate DataProvider**: Create a TestNG `@DataProvider` that uses your `ExcelDataReader` to supply data to your test method.
5.  **Run Tests**: Execute your TestNG tests and observe how the single test method runs multiple times with different data, and verify the assertions.
6.  **Add a Negative Case**: Add a row to your Excel file that represents a negative test case (e.g., missing required field, invalid authentication) and ensure your test handles it correctly.

## Additional Resources
-   **Apache POI Official Documentation**: [https://poi.apache.org/](https://poi.apache.org/)
-   **TestNG DataProviders**: [https://testng.org/doc/documentation-main.html#data-providers](https://testng.org/doc/documentation-main.html#data-providers)
-   **REST Assured GitHub**: [https://github.com/rest-assured/rest-assured](https://github.com/rest-assured/rest-assured)
---
# api-4.4-ac3.md

# Data-Driven & Parameterized API Testing with JSON (Jackson/Gson)

## Overview
In modern test automation, especially for APIs, efficient handling of test data is crucial. Data-driven testing allows us to execute the same test logic multiple times with different sets of input data, ensuring comprehensive coverage and reducing redundancy. Parameterized testing, often achieved through data-driven approaches, involves supplying various inputs to a test method. This document focuses on leveraging JSON files as a robust source for test data and deserializing them into Plain Old Java Objects (POJOs) using popular libraries like Jackson or Gson within a Java test automation framework. This approach enhances test maintainability, readability, and scalability.

## Detailed Explanation

When performing API testing, scenarios often arise where the same API endpoint needs to be tested with varying request payloads, headers, or expected responses. Manually duplicating test methods for each data set is inefficient and prone to errors. Storing test data externally, such as in JSON files, decouples the data from the test logic, making tests more flexible and easier to update.

JSON (JavaScript Object Notation) is a lightweight, human-readable data interchange format that is widely used in web APIs. Its hierarchical structure makes it ideal for representing complex test data.

### Why JSON for Test Data?
-   **Readability**: JSON is easy for humans to read and write.
-   **Interoperability**: Widely supported across programming languages and systems.
-   **Flexibility**: Can represent complex nested data structures.
-   **Maintainability**: Data changes don't require code changes, only updates to the JSON file.

### Libraries for JSON Processing in Java
Two prominent libraries for JSON processing in Java are:
1.  **Jackson**: A powerful, high-performance JSON processor for Java. It offers a `ObjectMapper` class for seamless serialization and deserialization.
2.  **Gson**: Google's JSON library. It's often praised for its simplicity and ease of use, especially for common use cases.

Both libraries provide mechanisms to map JSON structures directly to Java objects (POJOs), making it straightforward to work with the data in a type-safe manner within your tests.

### Steps to Implement:

1.  **Create a JSON file with an array of test data objects**: This file will contain multiple test cases, each represented as a JSON object within an array.
2.  **Define POJOs**: Create Java classes that mirror the structure of your JSON objects. These POJOs will hold your test data.
3.  **Read and Deserialize JSON**: Use Jackson's `ObjectMapper` or Gson's `Gson` class to read the JSON file and convert its content into a `List` of your defined POJOs.
4.  **Iterate and Execute Tests**: Loop through the list of POJOs, extracting data for each test case and passing it to your API test methods.

## Code Implementation

Let's assume we are testing a user registration API that takes `username` and `password`.

### 1. `test_data.json`
```json
[
  {
    "username": "testuser1",
    "password": "password123",
    "expectedStatusCode": 201,
    "expectedMessage": "User registered successfully"
  },
  {
    "username": "testuser2",
    "password": "password456",
    "expectedStatusCode": 201,
    "expectedMessage": "User registered successfully"
  },
  {
    "username": "existinguser",
    "password": "somepassword",
    "expectedStatusCode": 409,
    "expectedMessage": "Username already exists"
  },
  {
    "username": "short",
    "password": "pw",
    "expectedStatusCode": 400,
    "expectedMessage": "Password too short"
  }
]
```

### 2. POJO for Test Data (`UserData.java`)
```java
// src/test/java/com/example/apitester/data/UserData.java
package com.example.apitester.data;

// Required for Jackson annotations (if used)
import com.fasterxml.jackson.annotation.JsonProperty;

public class UserData {
    private String username;
    private String password;
    private int expectedStatusCode;
    private String expectedMessage;

    // Default constructor is important for deserialization
    public UserData() {
    }

    public UserData(String username, String password, int expectedStatusCode, String expectedMessage) {
        this.username = username;
        this.password = password;
        this.expectedStatusCode = expectedStatusCode;
        this.expectedMessage = expectedMessage;
    }

    // Getters
    public String getUsername() {
        return username;
    }

    public String getPassword() {
        return password;
    }

    public int getExpectedStatusCode() {
        return expectedStatusCode;
    }

    public String getExpectedMessage() {
        return expectedMessage;
    }

    // Setters (optional, but good practice for full POJO compliance)
    public void setUsername(String username) {
        this.username = username;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public void setExpectedStatusCode(int expectedStatusCode) {
        this.expectedStatusCode = expectedStatusCode;
    }

    public void setExpectedMessage(String expectedMessage) {
        this.expectedMessage = expectedMessage;
    }

    @Override
    public String toString() {
        return "UserData{" +
               "username='" + username + ''' +
               ", password='" + password + ''' +
               ", expectedStatusCode=" + expectedStatusCode +
               ", expectedMessage='" + expectedMessage + ''' +
               '}';
    }
}
```

### 3. JSON Data Reader Utility (`JsonDataReader.java`)

#### Using Jackson
First, add Jackson dependency to your `pom.xml` (Maven) or `build.gradle` (Gradle):
```xml
<!-- Maven pom.xml -->
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.17.0</version> <!-- Use the latest version -->
</dependency>
```
or
```gradle
// Gradle build.gradle
implementation 'com.fasterxml.jackson.core:jackson-databind:2.17.0' // Use the latest version
```

```java
// src/test/java/com/example/apitester/utils/JsonDataReader.java
package com.example.apitester.utils;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.example.apitester.data.UserData;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;

public class JsonDataReader {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Reads a JSON file from the classpath and deserializes it into a List of specified POJOs.
     *
     * @param jsonFilePath The path to the JSON file (e.g., "test_data.json" or "data/users.json").
     * @return A List of UserData objects.
     * @throws IOException If the file cannot be read or deserialization fails.
     */
    public static List<UserData> readUserData(String jsonFilePath) throws IOException {
        try (InputStream is = JsonDataReader.class.getClassLoader().getResourceAsStream(jsonFilePath)) {
            if (is == null) {
                throw new IOException("JSON file not found on classpath: " + jsonFilePath);
            }
            // TypeReference is needed for deserializing generic types like List<T>
            return objectMapper.readValue(is, new TypeReference<List<UserData>>() {});
        }
    }

    // You can make this generic for any POJO type
    public static <T> List<T> readJsonArray(String jsonFilePath, Class<T> clazz) throws IOException {
        try (InputStream is = JsonDataReader.class.getClassLoader().getResourceAsStream(jsonFilePath)) {
            if (is == null) {
                throw new IOException("JSON file not found on classpath: " + jsonFilePath);
            }
            // For generic type List<T>, we need to create a TypeReference dynamically or pass a JavaType
            // A simpler approach for array of specific POJOs is to use TypeFactory
            return objectMapper.readValue(is, objectMapper.getTypeFactory().constructCollectionType(List.class, clazz));
        }
    }
}
```

#### Using Gson
First, add Gson dependency to your `pom.xml` (Maven) or `build.gradle` (Gradle):
```xml
<!-- Maven pom.xml -->
<dependency>
    <groupId>com.google.code.gson</groupId>
    <artifactId>gson</artifactId>
    <version>2.10.1</version> <!-- Use the latest version -->
</dependency>
```
or
```gradle
// Gradle build.gradle
implementation 'com.google.code.gson:gson:2.10.1' // Use the latest version
```

```java
// src/test/java/com/example/apitester/utils/GsonDataReader.java
package com.example.apitester.utils;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.example.apitester.data.UserData;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.reflect.Type;
import java.util.List;

public class GsonDataReader {

    private static final Gson gson = new Gson();

    /**
     * Reads a JSON file from the classpath and deserializes it into a List of specified POJOs using Gson.
     *
     * @param jsonFilePath The path to the JSON file (e.g., "test_data.json" or "data/users.json").
     * @return A List of UserData objects.
     * @throws IOException If the file cannot be read or deserialization fails.
     */
    public static List<UserData> readUserData(String jsonFilePath) throws IOException {
        try (InputStream is = GsonDataReader.class.getClassLoader().getResourceAsStream(jsonFilePath);
             InputStreamReader reader = new InputStreamReader(is)) {
            if (is == null) {
                throw new IOException("JSON file not found on classpath: " + jsonFilePath);
            }
            // TypeToken is needed for deserializing generic types like List<T>
            Type listType = new TypeToken<List<UserData>>() {}.getType();
            return gson.fromJson(reader, listType);
        }
    }

    // Generic method for reading any list of POJOs
    public static <T> List<T> readJsonArray(String jsonFilePath, Class<T> clazz) throws IOException {
        try (InputStream is = GsonDataReader.class.getClassLoader().getResourceAsStream(jsonFilePath);
             InputStreamReader reader = new InputStreamReader(is)) {
            if (is == null) {
                throw new IOException("JSON file not found on classpath: " + jsonFilePath);
            }
            Type listType = TypeToken.getParameterized(List.class, clazz).getType();
            return gson.fromJson(reader, listType);
        }
    }
}
```

### 4. API Test Class (`UserRegistrationTest.java` - using TestNG as an example)
Place `test_data.json` under `src/test/resources` so it's on the classpath.

```java
// src/test/java/com/example/apitester/tests/UserRegistrationTest.java
package com.example.apitester.tests;

import com.example.apitester.data.UserData;
import com.example.apitester.utils.JsonDataReader; // Or GsonDataReader
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.io.IOException;
import java.util.List;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertTrue;

// Assuming you have RestAssured or HttpClient for API calls
// For simplicity, we'll mock the API call in this example.
// In a real scenario, you'd use RestAssured.given().body(...).when().post(...).then()...

public class UserRegistrationTest {

    // --- Data Provider using Jackson ---
    @DataProvider(name = "userDataJackson")
    public Object[][] getUserDataJackson() throws IOException {
        List<UserData> users = JsonDataReader.readUserData("test_data.json");
        Object[][] data = new Object[users.size()][1]; // Each row has one UserData object
        for (int i = 0; i < users.size(); i++) {
            data[i][0] = users.get(i);
        }
        return data;
    }

    // --- Data Provider using Gson ---
    @DataProvider(name = "userDataGson")
    public Object[][] getUserDataGson() throws IOException {
        List<UserData> users = GsonDataReader.readUserData("test_data.json");
        Object[][] data = new Object[users.size()][1]; // Each row has one UserData object
        for (int i = 0; i < users.size(); i++) {
            data[i][0] = users.get(i);
        }
        return data;
    }

    @Test(dataProvider = "userDataJackson") // or "userDataGson"
    public void testUserRegistration(UserData userData) {
        System.out.println("Running test for user: " + userData.getUsername());

        // --- Simulate API Request and Response ---
        // In a real test, you would make an actual HTTP POST request here
        // using RestAssured or an HTTP client, sending userData.getUsername() and userData.getPassword()
        // and then receiving a response.

        // Mocking API response based on test data
        int actualStatusCode;
        String actualMessage;

        // Simple mock logic for demonstration
        if (userData.getUsername().equals("existinguser")) {
            actualStatusCode = 409;
            actualMessage = "Username already exists";
        } else if (userData.getPassword().length() < 6 && userData.getUsername().equals("short")) {
            actualStatusCode = 400;
            actualMessage = "Password too short";
        } else {
            actualStatusCode = 201;
            actualMessage = "User registered successfully";
        }

        System.out.println("Expected Status Code: " + userData.getExpectedStatusCode() + ", Actual Status Code: " + actualStatusCode);
        System.out.println("Expected Message: " + userData.getExpectedMessage() + ", Actual Message: " + actualMessage);

        // --- Assertions ---
        assertEquals(actualStatusCode, userData.getExpectedStatusCode(),
                "Status code mismatch for user: " + userData.getUsername());
        assertTrue(actualMessage.contains(userData.getExpectedMessage()),
                "Response message mismatch for user: " + userData.getUsername());

        System.out.println("Test Passed for user: " + userData.getUsername() + "
");
    }
}
```

## Best Practices
-   **Centralize Test Data**: Store all API test data in a dedicated `src/test/resources` folder, organized by feature or API endpoint.
-   **Schema Validation**: For complex JSON structures, consider using JSON Schema to validate your test data files, ensuring they conform to expected formats before tests run. This catches data errors early.
-   **Type Safety with POJOs**: Always map JSON data to POJOs. This provides compile-time checks, IDE auto-completion, and makes your test code much cleaner and less error-prone than working with raw JSON strings or maps.
-   **Error Handling**: Implement robust error handling in your data reading utilities (e.g., handling `FileNotFoundException`, `JsonParseException`).
-   **Environmental Data**: If test data varies by environment (dev, QA, prod), use environment-specific JSON files or integrate with a configuration management system.
-   **Parameterized Test Frameworks**: Integrate seamlessly with test frameworks' parameterized testing capabilities (e.g., TestNG's `@DataProvider`, JUnit 5's `@ParameterizedTest` with `MethodSource` or `JsonSource` extensions).
-   **Security**: Be cautious about what sensitive data is stored directly in JSON files, especially if repositories are public. Use secure means for handling credentials (e.g., environment variables, secret management tools).

## Common Pitfalls
-   **Missing Default Constructor**: POJOs used for deserialization *must* have a public no-argument constructor. Jackson/Gson use this to instantiate the object before populating its fields.
-   **Mismatched Field Names**: If POJO field names don't exactly match JSON keys, deserialization will fail or result in `null` values unless explicit annotations (e.g., `@JsonProperty("json_key_name")` for Jackson, `@SerializedName("json_key_name")` for Gson) are used.
-   **Incorrect Data Types**: Mismatch between JSON data types (e.g., JSON number vs. Java String) and POJO field types will lead to deserialization errors.
-   **File Not Found**: Ensure JSON data files are correctly placed on the classpath (`src/test/resources` is a common location) so `getClassLoader().getResourceAsStream()` can find them.
-   **Large JSON Files**: Reading extremely large JSON files into memory might consume significant resources. For very large datasets, consider streaming JSON parsing, though for typical test data, this is rarely an issue.
-   **Lack of Validation**: Without schema validation or careful data creation, invalid test data can lead to obscure test failures rather than clear data parsing errors.

## Interview Questions & Answers

1.  **Q: What is data-driven testing, and why is it important in API automation?**
    A: Data-driven testing is an approach where test logic is separated from test data. It's crucial in API automation because APIs often have numerous inputs and states. Instead of writing a separate test case for each combination, a single test script can be executed with various data sets, covering more scenarios efficiently. This reduces code duplication, makes tests easier to maintain, and improves test coverage by exploring a wider range of inputs, including edge cases and negative scenarios.

2.  **Q: When would you choose JSON over other data sources like Excel or CSV for API test data?**
    A: I would choose JSON for API test data primarily when the API requests/responses themselves are in JSON format, or when the test data has a complex, hierarchical structure (nested objects, arrays of objects) that is difficult to represent in a flat tabular format like Excel or CSV. JSON offers native support for such structures, making the mapping to Java POJOs straightforward and maintaining data integrity. It's also human-readable and easily shareable between developers and testers.

3.  **Q: Explain the role of POJOs in deserializing JSON test data. What happens if a POJO lacks a default constructor?**
    A: POJOs (Plain Old Java Objects) act as a schema or blueprint for your JSON data. When deserializing, libraries like Jackson or Gson map the JSON keys to the POJO's fields, converting JSON values to the corresponding Java data types. This provides type safety and allows you to work with your test data as strongly-typed Java objects rather than raw JSON strings or generic maps, making your test code cleaner and less error-prone. If a POJO lacks a public no-argument (default) constructor, deserialization will fail. Jackson/Gson need this constructor to instantiate the POJO object before they can use setters or direct field access to populate its data from the JSON.

4.  **Q: Discuss the advantages and disadvantages of using Jackson vs. Gson for JSON processing in a test automation framework.**
    A: **Jackson Advantages**: Generally considered faster and more feature-rich, offering extensive customization options through annotations and configuration. It's the de-facto standard in many Spring-based applications. **Jackson Disadvantages**: Can have a steeper learning curve due to its vast API.
    **Gson Advantages**: Simpler API, often easier to get started with for basic serialization/deserialization. Good for smaller projects or when simplicity is prioritized. **Gson Disadvantages**: Can be slightly slower than Jackson for very large or complex JSON structures. Less flexible for highly custom serialization needs.
    In a test automation framework, both are excellent choices. I would typically align with the choice made in the application under test's codebase if it's a Java application to maintain consistency. If not, I might lean towards Jackson for its performance and feature set in larger enterprise frameworks.

## Hands-on Exercise
**Scenario**: You are testing a simple "Product Catalog" API.

**Task**:
1.  **Define a Product POJO**: Create a Java class `ProductData` with fields like `id` (int), `name` (String), `price` (double), `category` (String), `available` (boolean), `expectedStatusCode` (int), and `expectedMessage` (String).
2.  **Create `products_test_data.json`**: Create a JSON file containing an array of `ProductData` objects. Include at least 4-5 test cases covering:
    *   Successful product creation (e.g., status 201)
    *   Product creation with missing mandatory fields (e.g., status 400)
    *   Product creation with an invalid price (e.g., negative price, status 400)
    *   Attempt to create a product with an existing ID (e.g., status 409)
3.  **Implement a Data Reader**: Create a utility method (e.g., `readProductData`) in your `JsonDataReader` (or `GsonDataReader`) to read `products_test_data.json` and return a `List<ProductData>`.
4.  **Write a TestNG Test**: Create a test class `ProductCatalogTest`.
    *   Implement a `@DataProvider` that uses your `readProductData` utility.
    *   Write a `@Test` method `testProductCreation` that accepts a `ProductData` object.
    *   Inside the test method, simulate an API call (as done in the `UserRegistrationTest`) and assert against `expectedStatusCode` and `expectedMessage` from the `ProductData` object.
    *   Print the details of each product being tested.

## Additional Resources
-   **Jackson GitHub**: [https://github.com/FasterXML/jackson](https://github.com/FasterXML/jackson)
-   **Gson GitHub**: [https://github.com/google/gson](https://github.com/google/gson)
-   **TestNG Data Providers**: [https://testng.org/doc/documentation-main.html#parameters-dataproviders](https://testng.org/doc/documentation-main.html#parameters-dataproviders)
-   **RestAssured (for actual API calls)**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Baeldung Tutorial on Jackson**: [https://www.baeldung.com/jackson-object-mapper-tutorial](https://www.baeldung.com/jackson-object-mapper-tutorial)
-   **Baeldung Tutorial on Gson**: [https://www.baeldung.com/java-json-gson](https://www.baeldung.com/java-json-gson)
---
# api-4.4-ac4.md

# API 4.4 AC4: Parameterized Tests for Positive and Negative API Scenarios

## Overview
Parameterized testing is a powerful technique in API test automation that allows you to execute the same test logic multiple times with different sets of input data. This approach is crucial for thoroughly validating API endpoints, ensuring they handle both expected (positive) and unexpected (negative/edge case) inputs gracefully. By externalizing test data, we can achieve better test coverage, reduce code duplication, and make tests more maintainable and readable.

This document will cover how to implement parameterized tests using TestNG and REST Assured for both positive (successful responses) and negative (error responses) scenarios, using a data-driven approach to verify API robustness.

## Detailed Explanation

### What is Parameterized Testing?
Parameterized testing involves running a single test method multiple times, each time with a different set of data. Instead of writing separate test cases for each data variation, you define the test logic once and feed it various inputs. This is particularly useful for APIs where responses vary based on input, or where you need to validate a range of possible values.

### Why Use Parameterized Tests for APIs?
1.  **Comprehensive Coverage**: Easily test various combinations of valid, invalid, and boundary values without writing repetitive code.
2.  **Reduced Duplication**: The core test logic is written once, simplifying maintenance.
3.  **Improved Readability**: Test data is often separated from test logic, making tests easier to understand.
4.  **Robustness Verification**: Essential for validating how an API behaves under different conditions, including error handling.

### Positive vs. Negative Scenarios
*   **Positive Scenarios**: Test cases designed to verify that the API functions correctly with valid inputs, returning expected successful responses (e.g., HTTP 200 OK, 201 Created).
*   **Negative Scenarios**: Test cases designed to verify that the API handles invalid or unexpected inputs gracefully, returning appropriate error responses (e.g., HTTP 400 Bad Request, 401 Unauthorized, 404 Not Found, 500 Internal Server Error). These are critical for API security and reliability.

### Data Sources for Parameterized Tests
TestNG offers several ways to supply data to parameterized tests:
*   **`@DataProvider` Method**: A method within the test class or a separate utility class that returns a `Object[][]` or `Iterator<Object[]>`. This is highly flexible for programmatic data generation.
*   **`@Parameters` and `testng.xml`**: Data can be defined directly in the `testng.xml` suite file. Suitable for a small, fixed number of parameters.
*   **External Files (CSV, Excel, JSON)**: Data can be read from external files, providing greater flexibility and separation of concerns. This often involves custom utility methods or libraries.

For this example, we will focus on `@DataProvider` for its simplicity and direct integration with TestNG.

## Code Implementation

Let's assume we are testing a simple user registration API endpoint `POST /api/users`.

*   **Positive Scenario**: Valid user data (username, email, password) should result in a `201 Created` status and the user object returned.
*   **Negative Scenarios**:
    *   Missing required fields should result in a `400 Bad Request`.
    *   Invalid email format should result in a `400 Bad Request`.
    *   Weak password (e.g., too short) should result in a `400 Bad Request`.
    *   Existing username/email should result in a `409 Conflict`.

**Prerequisites**:
*   Java Development Kit (JDK)
*   Maven or Gradle for dependency management
*   TestNG
*   REST Assured

**`pom.xml` dependencies**:
```xml
<dependencies>
    <!-- TestNG -->
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version>
        <scope>test</scope>
    </dependency>
    <!-- REST Assured -->
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.3.0</version>
        <scope>test</scope>
    </dependency>
    <!-- GSON for JSON processing (optional, but good for building JSON bodies) -->
    <dependency>
        <groupId>com.google.code.gson</groupId>
        <artifactId>gson</artifactId>
        <version>2.10.1</version>
    </dependency>
</dependencies>
```

**`UserRegistrationTests.java`**:
```java
import com.google.gson.JsonObject;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

public class UserRegistrationTests {

    private static final String BASE_URI = "http://localhost:8080"; // Replace with your API base URI

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URI;
        // Optionally, configure common request details here, e.g., authentication
    }

    /**
     * DataProvider for positive user registration scenarios.
     * Contains valid user data expecting successful registration (201 Created).
     */
    @DataProvider(name = "positiveUserData")
    public Object[][] getPositiveUserData() {
        return new Object[][] {
                {"john.doe", "john.doe@example.com", "SecurePassword123!", "John", "Doe"},
                {"jane_smith", "jane.smith@example.com", "AnotherStrongPwd!@#", "Jane", "Smith"},
                {"bob_tester", "bob.tester@test.com", "TestPwd456$", "Bob", "Tester"}
        };
    }

    /**
     * Test for positive user registration scenarios.
     * Verifies successful user creation with valid data.
     *
     * @param username The username for registration.
     * @param email The email for registration.
     * @param password The password for registration.
     * @param firstName The first name of the user.
     * @param lastName The last name of the user.
     */
    @Test(dataProvider = "positiveUserData", description = "Verify successful user registration with valid data")
    public void testPositiveUserRegistration(String username, String email, String password, String firstName, String lastName) {
        // Build the request body using JsonObject
        JsonObject requestBody = new JsonObject();
        requestBody.addProperty("username", username);
        requestBody.addProperty("email", email);
        requestBody.addProperty("password", password);
        requestBody.addProperty("firstName", firstName);
        requestBody.addProperty("lastName", lastName);

        given()
            .contentType(ContentType.JSON)
            .body(requestBody.toString())
        .when()
            .post("/api/users") // Assuming /api/users is the registration endpoint
        .then()
            .statusCode(201) // Expect 201 Created for successful registration
            .body("id", notNullValue()) // Assert that an ID is generated
            .body("username", equalTo(username))
            .body("email", equalTo(email))
            .body("firstName", equalTo(firstName))
            .body("lastName", equalTo(lastName));

        System.out.println("Positive Test Passed for User: " + username);
    }

    /**
     * DataProvider for negative user registration scenarios.
     * Contains invalid user data expecting various error responses (e.g., 400, 409).
     *
     * @param username The username for registration.
     * @param email The email for registration.
     * @param password The password for registration.
     * @param expectedStatusCode The expected HTTP status code for the error.
     * @param expectedErrorMessagePart A part of the expected error message in the response.
     * @param description A description for the test case.
     */
    @DataProvider(name = "negativeUserData")
    public Object[][] getNegativeUserData() {
        return new Object[][] {
                // Missing username
                {"", "missing.user@example.com", "ValidPass123!", 400, "username cannot be empty", "Missing Username"},
                // Invalid email format
                {"invalid.email.user", "invalid-email", "ValidPass123!", 400, "Invalid email format", "Invalid Email"},
                // Weak password (e.g., too short, no special characters, no numbers, etc.)
                {"weak.pass.user", "weak.pass@example.com", "pass", 400, "Password is too weak", "Weak Password"},
                // Missing password
                {"missing.pass.user", "missing.pass@example.com", "", 400, "password cannot be empty", "Missing Password"},
                // Duplicate username (assuming an existing user with 'john.doe' already exists from positive tests or setup)
                // Note: For a real test, you'd ensure this user actually exists or is created in a @BeforeMethod.
                {"john.doe", "another.email@example.com", "DuplicateUserPass1!", 409, "Username already exists", "Duplicate Username"},
                // Duplicate email (assuming an existing user with 'john.doe@example.com' already exists)
                {"another.user", "john.doe@example.com", "AnotherPass123!", 409, "Email already exists", "Duplicate Email"},
                // Boundary values for username (e.g., too long)
                {"a_very_long_username_that_exceeds_the_maximum_allowed_length_for_this_api_endpoint_and_should_fail",
                        "long.user@example.com", "ValidPass123!", 400, "Username too long", "Long Username"}
        };
    }

    /**
     * Test for negative user registration scenarios.
     * Verifies API's error handling with invalid data.
     *
     * @param username The username for registration.
     * @param email The email for registration.
     * @param password The password for registration.
     * @param expectedStatusCode The expected HTTP status code for the error.
     * @param expectedErrorMessagePart A part of the expected error message in the response.
     * @param description A description for the test case (used for logging).
     */
    @Test(dataProvider = "negativeUserData", description = "Verify API error handling for invalid user registration data")
    public void testNegativeUserRegistration(String username, String email, String password, int expectedStatusCode, String expectedErrorMessagePart, String description) {
        // Build the request body. Note: firstName and lastName are omitted or can be null/empty
        JsonObject requestBody = new JsonObject();
        requestBody.addProperty("username", username);
        requestBody.addProperty("email", email);
        requestBody.addProperty("password", password);
        // For negative tests, sometimes you intentionally omit fields or send nulls.
        // For simplicity, we are passing empty strings or specific invalid values here.

        given()
            .contentType(ContentType.JSON)
            .body(requestBody.toString())
        .when()
            .post("/api/users")
        .then()
            .statusCode(expectedStatusCode) // Expect specific error status code
            .body("message", containsString(expectedErrorMessagePart)); // Assert specific error message part

        System.out.println("Negative Test Passed for Scenario (" + description + ") with User: " + username);
    }
}
```

**`testng.xml`**:
To run these tests, create a `testng.xml` file:
```xml
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd" >
<suite name="API Regression Suite">
    <test name="User Registration API Tests">
        <classes>
            <class name="UserRegistrationTests" />
        </classes>
    </test>
</suite>
```

**How to Run**:
1.  Ensure you have a running API service at `http://localhost:8080` that implements the `/api/users` endpoint with appropriate validation and error handling for user registration.
2.  Compile your Java project.
3.  Run the tests using TestNG, e.g., via Maven: `mvn clean test` or directly from your IDE by running the `testng.xml` file.

## Best Practices
-   **Separate Data from Logic**: Keep test data in `@DataProvider` methods or external files for better organization and maintainability.
-   **Clear Naming Conventions**: Name your `@DataProvider` methods and test methods descriptively (e.g., `getPositiveUserData`, `testPositiveUserRegistration`).
-   **Comprehensive Data Sets**: Include a wide range of valid, invalid, boundary, and edge cases in your data providers. Think about:
    *   **Valid**: Typical, minimum, maximum valid inputs.
    *   **Invalid**: Missing required fields, incorrect data types, out-of-range values, invalid formats (email, date).
    *   **Boundary**: Values just at the edge of valid/invalid ranges.
    *   **Edge Cases**: Empty strings, nulls (if the API handles them), special characters, extremely long strings.
    *   **Security-related**: SQL injection attempts, XSS payloads (though these might be more for specific security tests, they can sometimes be included in negative functional tests).
-   **Clear Assertions**: For positive tests, assert on key response body fields and status codes. For negative tests, assert on specific error codes and informative error messages or error structures.
-   **Idempotency and Test Data Management**: For API tests, especially those involving creation/modification, consider how to manage test data.
    *   **Clean-up**: Delete created resources after tests (e.g., in `@AfterMethod` or `@AfterClass`).
    *   **Setup**: Create preconditions before tests (e.g., in `@BeforeMethod` or `@BeforeClass`).
    *   **Unique Data**: Generate unique data for each test run (e.g., append timestamps or random strings to usernames/emails) to prevent conflicts, especially in positive tests.
-   **Performance Considerations**: For very large data sets, consider streaming data or using external tools to avoid loading all data into memory at once.

## Common Pitfalls
-   **Insufficient Data Coverage**: Only testing a few positive cases and neglecting negative or boundary scenarios leaves significant gaps in API validation.
-   **Hardcoding Data**: Embedding test data directly within test methods makes them difficult to update and maintain.
-   **Generic Error Assertions**: Simply checking for a `400 Bad Request` without verifying the specific error message or error code doesn't confirm the correct validation logic was triggered. Always assert on the expected error details.
-   **Lack of Test Data Isolation**: Tests interfering with each other due to shared or persistent data. For example, a successful registration test might leave data that causes a "duplicate user" error in a subsequent test when it shouldn't.
-   **Not Cleaning Up Test Data**: Leaving behind large amounts of test data in your system, especially in non-development environments, can lead to performance issues or data pollution.

## Interview Questions & Answers
1.  **Q**: Explain the concept of parameterized testing in the context of API automation. Why is it important?
    **A**: Parameterized testing involves running the same test logic multiple times with different input data. For API automation, it's crucial because APIs often have varied responses based on inputs. It helps achieve high test coverage for diverse scenarios (valid, invalid, boundary), reduces code duplication by centralizing test logic, and improves test maintainability by separating data from code. It's essential for verifying the API's robustness and handling of both success and error conditions.

2.  **Q**: How do you handle positive and negative test scenarios in API parameterized tests?
    **A**: For positive scenarios, I use valid input data sets that are expected to result in successful API responses (e.g., 200 OK, 201 Created). Assertions focus on verifying the correct status code and the structure/content of the successful response body. For negative scenarios, I provide invalid, malformed, or boundary-violating data. These tests expect error responses (e.g., 400 Bad Request, 401 Unauthorized, 409 Conflict). Assertions here verify the expected error status code and often check for specific error messages or error codes within the response body to ensure the correct validation was triggered.

3.  **Q**: What are some strategies for creating effective data sets for parameterized API testing?
    **A**: Effective data sets should cover:
    *   **Valid Inputs**: Typical, minimum, maximum allowed values.
    *   **Invalid Inputs**: Missing required fields, incorrect data types, out-of-range values, invalid formats (e.g., email, date).
    *   **Boundary Values**: Values at the edges of valid and invalid ranges.
    *   **Edge Cases**: Empty strings, nulls, special characters, extremely long strings, duplicate data (for uniqueness constraints).
    *   **Real-world Data**: Data that closely mimics actual user input.
    I would typically use `@DataProvider` in TestNG for simpler cases or external files like CSV, Excel, or JSON for larger, more complex data sets.

4.  **Q**: Describe a situation where parameterized testing significantly improved your API testing efforts.
    **A**: In a previous project, we had an e-commerce product API with many fields, each having different validation rules (length, format, range). Manually writing individual test cases for each valid and invalid combination would have been extremely time-consuming and led to massive code duplication. By implementing parameterized tests using TestNG's `@DataProvider`, we created a single test method and fed it hundreds of data combinations from an Excel sheet for different product attributes. This allowed us to quickly achieve high coverage for field validations, easily add new test cases by simply updating the data file, and identify validation gaps much faster.

## Hands-on Exercise
**Scenario**: Test a `POST /api/products` endpoint for creating a new product.

**Task**:
1.  **Define Product Schema**: A product requires a `name` (string, max 50 chars), `price` (float, > 0), and `category` (string, enum: "Electronics", "Books", "Clothing").
2.  **Create Positive Data**: Create at least 3 sets of valid product data.
3.  **Create Negative Data**: Create at least 5 sets of invalid product data, covering:
    *   Missing `name`.
    *   `name` too long.
    *   `price` <= 0.
    *   `category` not in the allowed enum.
    *   Missing `price`.
4.  **Implement Tests**: Write TestNG `@Test` methods using `@DataProvider` to test both positive (expect 201 Created) and negative (expect 400 Bad Request, with specific error messages) scenarios.
5.  **Run Tests**: Set up a dummy API endpoint or mock the response to run your tests.

## Additional Resources
-   **TestNG DataProviders**: [https://testng.org/doc/documentation-main.html#parameters-dataproviders](https://testng.org/doc/documentation-main.html#parameters-dataproviders)
-   **REST Assured Official Documentation**: [http://rest-assured.io/](http://rest-assured.io/)
-   **Baeldung Tutorial on Parameterized Tests with TestNG**: [https://www.baeldung.com/testng-parameterized-tests](https://www.baeldung.com/testng-parameterized-tests)
---
# api-4.4-ac5.md

# POJO Classes for Request/Response Serialization in API Testing

## Overview
In modern API testing, especially with RESTful services, dealing with JSON or XML data is ubiquitous. Plain Old Java Objects (POJOs) serve as a fundamental building block for effectively managing and manipulating this data within your Java automation framework. By mapping JSON payloads to POJOs, we introduce type safety, improve code readability, and significantly enhance the maintainability of our API tests. This approach abstracts away the complexities of parsing JSON strings, allowing testers to interact with API data using familiar Java objects and their properties.

## Detailed Explanation
A POJO is essentially a simple Java object that encapsulates data, typically without complex framework dependencies. In the context of API testing, POJOs are used for two primary purposes:
1.  **Request Serialization:** Converting a Java object into a JSON (or XML) string that can be sent as a request body to an API.
2.  **Response Deserialization:** Converting a JSON (or XML) response from an API into a Java object for easier assertion and data extraction.

This mapping is usually handled by libraries like Jackson (which REST Assured uses by default) or Gson. When you define a POJO, the library automatically maps JSON keys to POJO field names (case-insensitively by default, or explicitly with `@JsonProperty`).

**Why use POJOs in API testing?**
*   **Type Safety:** You interact with strongly typed Java objects, reducing the chance of runtime errors due to incorrect data access.
*   **Readability:** Code becomes much cleaner and easier to understand than manipulating raw JSON strings.
*   **Maintainability:** Changes in API structure can often be confined to POJO updates, minimizing impact on test logic.
*   **Reusability:** POJOs can be reused across multiple tests and even shared between different layers of an automation framework.

**Lombok for Boilerplate Reduction:**
Manually writing getters, setters, constructors, `equals()`, `hashCode()`, and `toString()` methods for every POJO can be tedious and error-prone. Project Lombok is a popular library that helps reduce this boilerplate code through annotations. Key Lombok annotations for POJOs include:
*   `@Data`: Generates getters, setters, `equals()`, `hashCode()`, and `toString()`.
*   `@NoArgsConstructor`: Generates a constructor with no arguments. Essential for deserialization by some libraries.
*   `@AllArgsConstructor`: Generates a constructor with arguments for all fields.
*   `@Builder`: Provides a fluent builder API for creating instances of your class, which is particularly useful for constructing complex request objects.

## Code Implementation

Let's consider a simple API for managing user profiles.

**Sample JSON Request (to create a user):**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "age": 30
}
```

**Sample JSON Response (after creating a user):**
```json
{
  "id": "USR12345",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "age": 30,
  "status": "active"
}
```

**Java POJO Classes with Lombok:**

First, ensure you have Lombok configured in your project (e.g., added as a dependency in `pom.xml` for Maven or `build.gradle` for Gradle and IDE plugin installed).

**`CreateUserRequest.java` (Request POJO):**
```java
package com.example.api.payloads;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data // Generates getters, setters, toString, equals, hashCode
@NoArgsConstructor // Generates a no-argument constructor
@AllArgsConstructor // Generates a constructor with all fields
@Builder // Provides a builder pattern for object creation
public class CreateUserRequest {
    private String firstName;
    private String lastName;
    private String email;
    private Integer age; // Use Integer for nullable numeric fields
}
```

**`CreateUserResponse.java` (Response POJO):**
```java
package com.example.api.payloads;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateUserResponse {
    private String id;
    private String firstName;
    private String lastName;
    private String email;
    private Integer age;
    private String status;
}
```

**Using POJOs with REST Assured (Example Test):**
```java
package com.example.api.tests;

import com.example.api.payloads.CreateUserRequest;
import com.example.api.payloads.CreateUserResponse;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

public class UserApiTest {

    @BeforeClass
    public void setup() {
        // Base URI for the API
        RestAssured.baseURI = "https://api.example.com";
        // Base Path, if any
        RestAssured.basePath = "/users";
    }

    @Test
    public void testCreateUserWithPojo() {
        // 1. Create a request object using the Builder pattern from Lombok
        CreateUserRequest userRequest = CreateUserRequest.builder()
                .firstName("Jane")
                .lastName("Doe")
                .email("jane.doe@example.com")
                .age(28)
                .build();

        // 2. Send the request and deserialize the response into a POJO
        CreateUserResponse userResponse = given()
                .contentType(ContentType.JSON)
                .body(userRequest) // REST Assured automatically serializes the POJO to JSON
                .when()
                .post()
                .then()
                .statusCode(201) // Assuming 201 Created for success
                .extract()
                .as(CreateUserResponse.class); // REST Assured automatically deserializes JSON to POJO

        // 3. Perform assertions on the response POJO
        System.out.println("User Created: " + userResponse.getId());
        System.out.println("First Name: " + userResponse.getFirstName());
        System.out.println("Email: " + userResponse.getEmail());

        // Assertions using Hamcrest matchers on POJO properties
        given()
                .contentType(ContentType.JSON)
                .body(userRequest)
                .when()
                .post()
                .then()
                .statusCode(201)
                .body("id", notNullValue()) // Assert that id is not null
                .body("firstName", equalTo(userRequest.getFirstName()))
                .body("email", equalTo(userRequest.getEmail()))
                .body("status", equalTo("active")); // Assert on status from response
    }
}
```

## Best Practices
-   **Immutability for Response POJOs:** For response objects, consider making them immutable using `@Value` (a Lombok annotation that makes all fields final and generates only getters, `equals`, `hashCode`, `toString`, and an all-args constructor) or by simply declaring fields as `final` and relying on the `@Builder` pattern for initial construction. This prevents accidental modification of response data.
-   **Consistent Naming Conventions:** Ensure your POJO field names align closely with JSON keys. If there are discrepancies (e.g., `user_name` in JSON vs. `userName` in Java), use `@JsonProperty("json_key_name")` from Jackson to explicitly map them.
-   **Handling Optional Fields:** For fields that might be absent in the JSON payload, use `Optional<T>` or wrap primitive types with their object counterparts (e.g., `Integer` instead of `int`) which can be `null`.
-   **Nested POJOs for Complex Structures:** Break down complex JSON structures into smaller, dedicated POJO classes. For example, if a user object contains an `address` object, create an `Address` POJO and use it as a field in your `User` POJO.
-   **Serialization Features:** Leverage Jackson's `@JsonInclude(JsonInclude.Include.NON_NULL)` to exclude `null` fields from the serialized JSON request, or `@JsonIgnoreProperties(ignoreUnknown = true)` to ignore any JSON fields not present in your POJO during deserialization, making your POJOs more robust to API changes.
-   **Version Control:** Store your POJO classes in a dedicated package (e.g., `com.example.api.payloads`) for better organization.

## Common Pitfalls
-   **Mismatched Field Names/Types:** The most common issue. If a JSON key `user_name` is mapped to a Java field `username` without `@JsonProperty`, deserialization will fail to populate that field. Similarly, type mismatches (e.g., expecting a `String` but receiving a `Number`) will lead to errors.
-   **Missing No-Argument Constructor:** Many deserialization libraries (including Jackson) require a public no-argument constructor to instantiate the POJO before populating its fields. `@NoArgsConstructor` from Lombok addresses this.
-   **Not Handling Nested Objects Correctly:** For nested JSON objects or arrays, ensure you have corresponding nested POJO classes or `List`s of POJOs in your main POJO.
-   **Overlooking `null` Values:** If a JSON field can be `null`, your Java field should be an object type (e.g., `String`, `Integer`, `List`) rather than a primitive to avoid `NullPointerException`s during deserialization.
-   **Forgetting Lombok Annotation Processors:** If Lombok is not correctly set up in your IDE or build system, the generated methods won't be available, leading to compilation errors.

## Interview Questions & Answers
1.  **Q: What are POJO classes, and why are they essential for robust API automation frameworks?**
    **A:** POJO (Plain Old Java Object) classes are simple Java objects used to model the data structures exchanged with an API. They are essential because they provide type safety, greatly improve code readability and maintainability by allowing interaction with API data as native Java objects rather than raw strings, and facilitate seamless serialization/deserialization of JSON/XML payloads. This reduces errors, simplifies assertions, and makes the automation framework more scalable.

2.  **Q: How do you handle complex JSON structures (e.g., nested objects, arrays of objects) using POJOs?**
    **A:** Complex JSON structures are handled by creating a hierarchy of POJOs. For nested JSON objects, you define separate POJO classes for each nested object and use them as fields within the parent POJO. For JSON arrays of objects, you use `List<ChildPojo>` as a field type in the parent POJO. This mirrors the JSON structure directly in your Java code.

3.  **Q: Explain the role of Lombok annotations like `@Data`, `@NoArgsConstructor`, `@AllArgsConstructor`, and `@Builder` in POJO creation for API testing.**
    **A:** Lombok annotations drastically reduce boilerplate code in POJOs.
    *   `@Data`: Automatically generates getters, setters, `equals()`, `hashCode()`, and `toString()` methods, centralizing data management.
    *   `@NoArgsConstructor`: Generates a default public constructor with no arguments, which is often required by deserialization libraries like Jackson to instantiate the object.
    *   `@AllArgsConstructor`: Generates a constructor with arguments for all fields in the class, useful for creating immutable objects or initializing all fields at once.
    *   `@Builder`: Provides a fluent API for constructing objects, making the creation of complex request payloads more readable and less error-prone, especially when many fields are optional.

4.  **Q: What are some common challenges or pitfalls you've encountered when mapping JSON responses to POJOs, and how did you resolve them?**
    **A:**
    *   **Mismatched Field Names:** JSON keys not matching Java field names. Resolved using `@JsonProperty("jsonKeyName")` annotation from Jackson.
    *   **Missing No-Arg Constructor:** Deserialization failure. Resolved by adding `@NoArgsConstructor` or explicitly creating a public no-arg constructor.
    *   **Type Mismatches:** JSON values not matching Java field types (e.g., number as string). Resolved by adjusting Java field type or using custom deserializers if needed.
    *   **Ignoring Unknown Fields:** API responses containing fields not present in the POJO causing deserialization errors. Resolved with `@JsonIgnoreProperties(ignoreUnknown = true)` on the POJO class.
    *   **`null` Values:** JSON `null` mapping to primitive Java types causing `NullPointerException`. Resolved by using wrapper classes (e.g., `Integer` instead of `int`) or `Optional<T>`.

## Hands-on Exercise

**Scenario:** You are testing a simple "Product Catalog" API.

**JSON Request to add a product:**
```json
{
  "productName": "Laptop Pro",
  "category": "Electronics",
  "price": 1200.00,
  "inStock": true,
  "tags": ["powerful", "portable"]
}
```

**JSON Response after adding a product:**
```json
{
  "productId": "PROD9876",
  "productName": "Laptop Pro",
  "category": "Electronics",
  "price": 1200.00,
  "inStock": true,
  "tags": ["powerful", "portable"],
  "createdAt": "2026-02-05T10:30:00Z"
}
```

**Task:**
1.  Create two Java POJO classes: `AddProductRequest` and `AddProductResponse` using Lombok annotations (`@Data`, `@NoArgsConstructor`, `@AllArgsConstructor`, `@Builder`).
2.  Ensure correct data types for all fields, including handling the `tags` array and `createdAt` field.
3.  Write a simple REST Assured test method that:
    *   Constructs an `AddProductRequest` object.
    *   Sends a POST request to a mock API endpoint (you can use `RestAssured.given().baseUri("http://localhost:8080/products")`).
    *   Deserializes the response into an `AddProductResponse` object.
    *   Performs assertions to verify `productId` is not null, and `productName` and `category` match the request.

## Additional Resources
-   **Project Lombok:** [https://projectlombok.org/](https://projectlombok.org/)
-   **REST Assured Documentation:** [https://rest-assured.io/](https://rest-assured.io/)
-   **Jackson Annotations:** [https://github.com/FasterXML/jackson-annotations](https://github.com/FasterXML/jackson-annotations)
-   **Baeldung Tutorial on Lombok:** [https://www.baeldung.com/lombok](https://www.baeldung.com/lombok)
---
# api-4.4-ac6.md

# API 4.4 AC6: Serialization using Jackson ObjectMapper in REST Assured

## Overview
Serialization is the process of converting an object's state into a format that can be stored or transmitted and reconstructed later. In the context of API testing with REST Assured and Java, this often means converting a Java Plain Old Java Object (POJO) into a JSON (or XML) payload to be sent in an API request body. Jackson ObjectMapper is a powerful and widely used library for this purpose, providing flexible and efficient JSON processing capabilities. REST Assured integrates seamlessly with Jackson, allowing for automatic serialization of POJOs to JSON when provided as the request body.

This section will cover how to leverage Jackson ObjectMapper for serialization within REST Assured, focusing on creating POJO instances, passing them to the request body, and verifying automatic JSON conversion.

## Detailed Explanation
When testing RESTful APIs, it's common to send complex data structures in the request body. Manually constructing JSON strings can be error-prone and difficult to maintain. POJOs, combined with a serialization library like Jackson, offer a cleaner and more robust approach.

REST Assured, by default, uses Jackson Databind (if present on the classpath) to serialize Java objects into JSON. When you provide a POJO to `body()` method of a REST Assured request, it automatically attempts to serialize that object into its JSON representation.

### How it Works:
1.  **POJO Definition**: You define a Java class (POJO) that mirrors the structure of the JSON payload you intend to send. This class typically has private fields, public getters and setters for these fields, and a no-argument constructor.
2.  **Jackson Annotations (Optional but Recommended)**: While basic serialization works out-of-the-box, Jackson annotations (e.g., `@JsonProperty`, `@JsonIgnore`, `@JsonInclude`, `@JsonFormat`) provide fine-grained control over the serialization process. For instance, `@JsonProperty("json_field_name")` allows mapping a Java field name to a different JSON field name.
3.  **Instantiation and Population**: You create an instance of your POJO and populate its fields with the desired data.
4.  **REST Assured `body()`**: You pass this populated POJO instance directly to the `body()` method of your REST Assured request.
5.  **Automatic Serialization**: REST Assured, detecting the POJO, uses Jackson to convert it into a JSON string, which then becomes the request body.

## Code Implementation
Let's assume we have an API endpoint `POST /api/users` that accepts a JSON payload to create a new user:
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "age": 30
}
```

First, define the POJO class:

```java
// src/main/java/com/example/api/payloads/User.java
package com.example.api.payloads;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

// @JsonInclude(JsonInclude.Include.NON_NULL) can be used to exclude null fields from the JSON output
public class User {

    @JsonProperty("firstName") // Maps Java field to JSON field "firstName"
    private String firstName;

    @JsonProperty("lastName") // Maps Java field to JSON field "lastName"
    private String lastName;

    private String email; // Field name matches JSON field name, so @JsonProperty is optional

    private int age;

    // No-argument constructor is essential for Jackson (for both serialization and deserialization)
    public User() {
    }

    public User(String firstName, String lastName, String email, int age) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.age = age;
    }

    // Getters and Setters
    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        return lastName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    @Override
    public String toString() {
        return "User{" +
               "firstName='" + firstName + ''' +
               ", lastName='" + lastName + ''' +
               ", email='" + email + ''' +
               ", age=" + age +
               '}';
    }
}
```

Now, the REST Assured test demonstrating serialization:

```java
// src/test/java/com/example/api/tests/UserCreationTest.java
package com.example.api.tests;

import com.example.api.payloads.User;
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

public class UserCreationTest {

    @BeforeClass
    public void setup() {
        // Set base URI for all tests in this class
        RestAssured.baseURI = "https://api.example.com"; // Replace with your actual API base URI
        // Optional: Log all requests and responses
        RestAssured.enableLoggingOfRequestAndResponseIfValidationFails();
    }

    @Test
    public void testCreateUserWithPojoSerialization() {
        // 1. Create an instance of the POJO
        User newUser = new User("Jane", "Doe", "jane.doe@example.com", 28);

        System.out.println("Attempting to create user: " + newUser);

        // 2. Pass POJO to .body(myObject) in RestAssured
        // Rest Assured automatically serializes the 'newUser' POJO to JSON using Jackson
        Response response = given()
                                .header("Content-Type", "application/json")
                                .body(newUser) // POJO passed directly
                            .when()
                                .post("/users") // Replace with your actual endpoint
                            .then()
                                .statusCode(201) // Expecting 201 Created status
                                .log().all() // Log the entire response for debugging
                                .extract().response();

        // 3. Verify it is automatically converted to JSON and processed by the API
        // We can assert on the response body to ensure the user was created correctly
        response.then()
                .body("id", notNullValue()) // Assuming the API returns an ID for the created user
                .body("firstName", equalTo(newUser.getFirstName()))
                .body("email", equalTo(newUser.getEmail()));

        System.out.println("User created successfully with ID: " + response.jsonPath().getString("id"));
    }

    @Test
    public void testCreateUserWithPartialData() {
        // Example of sending partial data, if the API supports it and Jackson handles nulls
        User partialUser = new User();
        partialUser.setFirstName("Alice");
        partialUser.setEmail("alice@example.com");

        System.out.println("Attempting to create partial user: " + partialUser);

        given()
                .header("Content-Type", "application/json")
                .body(partialUser)
        .when()
                .post("/users")
        .then()
                .statusCode(201)
                .log().all()
                .body("id", notNullValue())
                .body("firstName", equalTo(partialUser.getFirstName()))
                .body("lastName", is(emptyOrNullString())) // Assuming API sets lastName to null/empty if not provided
                .body("email", equalTo(partialUser.getEmail()));
    }
}
```

**Dependencies for `pom.xml` (Maven) or `build.gradle` (Gradle):**
To make this work, ensure you have the necessary dependencies for REST Assured and Jackson Databind.

**Maven (`pom.xml`):**
```xml
<dependencies>
    <!-- REST Assured -->
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.3.0</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>json-schema-validator</artifactId>
        <version>5.3.0</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
    <!-- Jackson Databind for JSON processing (usually pulled by RestAssured, but explicit is good) -->
    <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-databind</artifactId>
        <version>2.15.2</version> <!-- Use the latest compatible version -->
        <scope>test</scope>
    </dependency>
    <!-- TestNG (or JUnit) -->
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
    <!-- Hamcrest for assertions (usually pulled by TestNG/RestAssured, but explicit is good) -->
    <dependency>
        <groupId>org.hamcrest</groupId>
        <artifactId>hamcrest</artifactId>
        <version>2.2</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
</dependencies>
```

**Gradle (`build.gradle`):**
```gradle
dependencies {
    // REST Assured
    testImplementation 'io.rest-assured:rest-assured:5.3.0' // Use the latest version
    testImplementation 'io.rest-assured:json-schema-validator:5.3.0' // Use the latest version
    // Jackson Databind
    testImplementation 'com.fasterxml.jackson.core:jackson-databind:2.15.2' // Use the latest compatible version
    // TestNG
    testImplementation 'org.testng:testng:7.8.0' // Use the latest version
    // Hamcrest
    testImplementation 'org.hamcrest:hamcrest:2.2' // Use the latest version
}
```

## Best Practices
- **Use POJOs for Request/Response Bodies**: Always define POJOs for both request and response bodies. This makes your tests more readable, maintainable, and less prone to errors compared to building JSON strings manually.
- **Keep POJOs Simple**: POJOs should primarily contain fields, getters, setters, and a no-arg constructor. Avoid complex business logic within payload POJOs.
- **Utilize Jackson Annotations**: For complex JSON structures or when Java field names differ from JSON field names, use Jackson annotations like `@JsonProperty`, `@JsonIgnore`, `@JsonInclude`, etc., for precise control over serialization.
- **Handle Null Values**: Be mindful of how null values are serialized. `@JsonInclude(JsonInclude.Include.NON_NULL)` on a POJO or individual fields can prevent null fields from being included in the JSON payload, which is often desirable.
- **Version Control POJOs**: Treat your POJOs as part of your contract with the API. Keep them under version control and update them as the API evolves.

## Common Pitfalls
- **Missing No-Argument Constructor**: Jackson requires a no-argument constructor to both serialize and deserialize objects correctly. Forgetting this will lead to runtime errors.
- **Incorrect Getters/Setters**: Ensure that your getters and setters follow standard Java bean conventions (`getFieldName()`, `setFieldName(value)`). Jackson relies on these conventions.
- **Mismatched Field Names**: If your Java field names do not exactly match the JSON field names, Jackson might not serialize/deserialize correctly. Use `@JsonProperty` to resolve these mismatches.
- **Missing Jackson Databind Dependency**: If `jackson-databind` is not on the classpath, REST Assured won't be able to perform automatic POJO to JSON serialization, leading to errors.
- **Ignoring API Contract Changes**: As the API evolves, the structure of request/response bodies may change. Failing to update your POJOs accordingly will result in serialization/deserialization issues and test failures.

## Interview Questions & Answers
1.  **Q: Explain the concept of serialization in the context of API testing. Why is it important?**
    **A:** Serialization is the process of converting a Java object's state into a byte stream or a transferable format (like JSON or XML) for storage or transmission. In API testing, it's crucial for converting Java POJOs (representing data models) into the request body format (e.g., JSON) that the API expects. This simplifies test data management, improves readability, and makes tests more robust and maintainable compared to manual JSON string construction. It allows testers to interact with the API using strong-typed Java objects.

2.  **Q: How does REST Assured handle POJO serialization to JSON, and what role does Jackson play?**
    **A:** REST Assured leverages Jackson Databind, a popular JSON processing library, for automatic POJO serialization. When a Java object is passed to the `body()` method of a REST Assured request, REST Assured detects the object and, if Jackson is on the classpath, uses it to convert the object into its JSON representation. This happens seamlessly without explicit calls to `ObjectMapper`.

3.  **Q: What are some key Jackson annotations you might use for serialization and why?**
    **A:**
    *   `@JsonProperty("jsonFieldName")`: Used to map a Java field name to a different JSON field name. Essential when Java naming conventions (e.g., `firstName`) differ from JSON naming conventions (e.g., `first_name`).
    *   `@JsonIgnore`: Marks a field to be ignored during serialization (and deserialization). Useful for internal fields that should not be exposed in the API payload.
    *   `@JsonInclude(JsonInclude.Include.NON_NULL)`: Placed at class or field level, it instructs Jackson to exclude fields with `null` values from the JSON output. This helps in sending cleaner payloads and can be crucial when an API expects certain fields to be absent rather than null.
    *   `@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")`: Used for formatting dates, numbers, or other types during serialization into a specific string pattern.

## Hands-on Exercise
1.  **Objective**: Create a new `Product` POJO and use it to send a `POST` request to a mock API.
2.  **Steps**:
    *   Set up a mock API endpoint (e.g., using `MockServer` or `WireMock`, or a simple online mock API service like `JSONPlaceholder` or `Reqres.in` if it supports POST). Let's assume a `POST /products` endpoint that expects:
        ```json
        {
          "name": "Laptop",
          "price": 1200.00,
          "inStock": true
        }
        ```
    *   Define a `Product` POJO with fields `name`, `price`, and `inStock`. Ensure it has a no-argument constructor and appropriate getters/setters.
    *   Write a REST Assured test that:
        *   Creates an instance of the `Product` POJO.
        *   Populates its fields.
        *   Uses `given().body(productPojo).when().post("/products").then()...`
        *   Asserts the status code (e.g., 201 Created).
        *   Asserts that the response body contains the data sent, or a generated ID, confirming successful serialization and creation.

## Additional Resources
-   **Jackson GitHub**: [https://github.com/FasterXML/jackson](https://github.com/FasterXML/jackson)
-   **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Baeldung Tutorial on Jackson**: [https://www.baeldung.com/jackson](https://www.baeldung.com/jackson)
-   **POJO with REST Assured (Example)**: [https://www.toolsqa.com/rest-assured/pojo-with-rest-assured/](https://www.toolsqa.com/rest-assured/pojo-with-rest-assured/)
---
# api-4.4-ac7.md

# API 4.4 AC7: Deserialization to Extract Response into Objects

## Overview
In API testing, deserialization is the process of converting a JSON or XML API response into a structured object (often a Plain Old Java Object, or POJO) in your programming language. This is a crucial technique for robust and maintainable API test automation. Instead of navigating complex JSON structures using tools like JsonPath, deserialization allows you to interact with the API response as strongly-typed Java objects, making assertions cleaner, code more readable, and refactoring safer. This approach is fundamental for data-driven and parameterized API testing, enabling efficient validation of complex response payloads.

## Detailed Explanation
When an API returns a response, it's typically in a string format (e.g., JSON). To work with this data in a structured way within your test code, you need to "deserialize" it into a Java object. This object acts as a model for your API response, with fields corresponding to the keys in the JSON.

Libraries like RestAssured, Jackson, or Gson provide mechanisms to easily perform this conversion. RestAssured, in particular, has built-in support, allowing you to cast the response directly to a POJO using the `.as(MyClass.class)` method.

Consider an API endpoint that returns user details:
```json
{
    "id": 101,
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "isActive": true
}
```

To deserialize this, you would create a Java POJO that mirrors this structure:

```java
// src/main/java/com/example/api/models/User.java
package com.example.api.models;

import com.fasterxml.jackson.annotation.JsonProperty; // Optional, for mapping JSON keys to different field names

public class User {
    private int id;
    private String firstName;
    private String lastName;
    private String email;
    private boolean isActive;

    // Default constructor is required by some deserialization libraries (e.g., Jackson, Gson)
    public User() {
    }

    // Constructor for convenience (optional, but good for creating test data)
    public User(int id, String firstName, String lastName, String email, boolean isActive) {
        this.id = id;
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.isActive = isActive;
    }

    // Getters and setters for all fields
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    @Override
    public String toString() {
        return "User{" +
               "id=" + id +
               ", firstName='" + firstName + ''' +
               ", lastName='" + lastName + ''' +
               ", email='" + email + ''' +
               ", isActive=" + isActive +
               '}';
    }
}
```

Once you have your POJO, deserializing the response and validating its fields becomes straightforward:

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.Test;
import static org.testng.Assert.*;

// Assuming User.java is in com.example.api.models package
import com.example.api.models.User;

public class UserApiTest {

    @Test
    public void testGetUserByIdAndValidateWithPojo() {
        RestAssured.baseURI = "https://api.example.com"; // Replace with your actual API base URI

        Response response = RestAssured.given()
                                .pathParam("userId", 101)
                                .when()
                                .get("/users/{userId}")
                                .then()
                                .statusCode(200) // Assert HTTP status code first
                                .extract()
                                .response();

        // Deserialize the JSON response body into a User object
        User user = response.as(User.class);

        // Validate fields using Java getters instead of JsonPath
        assertNotNull(user, "User object should not be null after deserialization");
        assertEquals(user.getId(), 101, "User ID mismatch");
        assertEquals(user.getFirstName(), "John", "First name mismatch");
        assertEquals(user.getLastName(), "Doe", "Last name mismatch");
        assertEquals(user.getEmail(), "john.doe@example.com", "Email mismatch");
        assertTrue(user.isActive(), "User should be active");

        System.out.println("Deserialized User: " + user);
    }

    @Test
    public void testCreateUserAndValidateResponseWithPojo() {
        RestAssured.baseURI = "https://api.example.com";

        // Create a User object to send in the request body
        User newUser = new User(0, "Jane", "Smith", "jane.smith@example.com", true);

        Response response = RestAssured.given()
                                .contentType("application/json")
                                .body(newUser) // RestAssured will serialize this POJO to JSON
                                .when()
                                .post("/users")
                                .then()
                                .statusCode(201) // Assuming 201 Created for successful POST
                                .extract()
                                .response();

        User createdUser = response.as(User.class);

        assertNotNull(createdUser.getId(), "Created User ID should not be null");
        assertNotEquals(createdUser.getId(), 0, "Created User ID should be assigned by server");
        assertEquals(createdUser.getFirstName(), newUser.getFirstName());
        assertEquals(createdUser.getLastName(), newUser.getLastName());
        assertEquals(createdUser.getEmail(), newUser.getEmail());
        assertTrue(createdUser.isActive());

        System.out.println("Created User: " + createdUser);
    }
}
```

For more complex JSON structures, such as nested objects or arrays, your POJOs will need to reflect that hierarchy. For example, if a user has an `Address` object:

```json
{
    "id": 101,
    "firstName": "John",
    "address": {
        "street": "123 Main St",
        "city": "Anytown"
    }
}
```

You would create an `Address` POJO and include it in the `User` POJO:

```java
// src/main/java/com/example/api/models/Address.java
package com.example.api.models;

public class Address {
    private String street;
    private String city;

    // Getters, setters, constructors
    public Address() {}

    public Address(String street, String city) {
        this.street = street;
        this.city = city;
    }

    public String getStreet() { return street; }
    public void setStreet(String street) { this.street = street; }
    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    @Override
    public String toString() {
        return "Address{" + "street='" + street + ''' + ", city='" + city + ''' + '}';
    }
}

// src/main/java/com/example/api/models/User.java (updated)
package com.example.api.models;

public class User {
    private int id;
    private String firstName;
    private Address address; // Nested object

    // Getters, setters, constructors for all fields including Address
    public User() {}

    public User(int id, String firstName, Address address) {
        this.id = id;
        this.firstName = firstName;
        this.address = address;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }
    public Address getAddress() { return address; }
    public void setAddress(Address address) { this.address = address; }

    @Override
    public String toString() {
        return "User{" + "id=" + id + ", firstName='" + firstName + ''' + ", address=" + address + '}';
    }
}
```

The deserialization with `.as(User.class)` would still work seamlessly, populating the `Address` object within the `User` object.

## Code Implementation
```java
// Maven dependencies for RestAssured and TestNG
/*
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
    <version>2.15.2</version>
    <scope>test</scope>
</dependency>
*/

// src/main/java/com/example/api/models/Product.java
package com.example.api.models;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties; // Useful for ignoring unknown fields
import java.util.Objects;

@JsonIgnoreProperties(ignoreUnknown = true) // Ignore any JSON fields not present in this POJO
public class Product {
    private String id;
    private String name;
    private double price;
    private String category;
    private int stock;
    private boolean available;

    // Default constructor is essential for deserialization
    public Product() {
    }

    // All-args constructor for easy object creation
    public Product(String id, String name, double price, String category, int stock, boolean available) {
        this.id = id;
        this.name = name;
        this.price = price;
        this.category = category;
        this.stock = stock;
        this.available = available;
    }

    // Getters and Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public double getPrice() {
        return price;
    }

    public void setPrice(double price) {
        this.price = price;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public int getStock() {
        return stock;
    }

    public void setStock(int stock) {
        this.stock = stock;
    }

    public boolean isAvailable() {
        return available;
    }

    public void setAvailable(boolean available) {
        this.available = available;
    }

    // Override equals and hashCode for easier object comparison in tests
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Product product = (Product) o;
        return Double.compare(product.price, price) == 0 &&
               stock == product.stock &&
               available == product.available &&
               Objects.equals(id, product.id) &&
               Objects.equals(name, product.name) &&
               Objects.equals(category, product.category);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, name, price, category, stock, available);
    }

    @Override
    public String toString() {
        return "Product{" +
               "id='" + id + ''' +
               ", name='" + name + ''' +
               ", price=" + price +
               ", category='" + category + ''' +
               ", stock=" + stock +
               ", available=" + available +
               '}';
    }
}

// src/test/java/com/example/api/tests/ProductApiDeserializationTest.java
package com.example.api.tests;

import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import static org.testng.Assert.*;

import com.example.api.models.Product; // Import our POJO

public class ProductApiDeserializationTest {

    // Ideally, base URI should come from a configuration file
    private static final String BASE_URI = "https://api.example.com/products"; // Placeholder API endpoint

    @BeforeClass
    public void setup() {
        // Set up RestAssured base URI, headers, etc. for all tests in this class
        RestAssured.baseURI = BASE_URI;
        // RestAssured.authentication = preemptive().basic("user", "password"); // Example for basic auth
    }

    @Test(description = "Verify fetching a single product and deserializing it into a Product POJO")
    public void testGetProductByIdAndDeserialize() {
        String productId = "PROD001"; // Assuming an existing product ID

        // Perform the GET request and extract the response
        Response response = RestAssured.given()
                                .pathParam("productId", productId)
                                .when()
                                .get("/{productId}")
                                .then()
                                .statusCode(200) // Ensure the request was successful
                                .extract()
                                .response();

        // Deserialize the JSON response body into a Product object
        Product product = response.as(Product.class);

        // Validate the deserialized object using its getters
        assertNotNull(product, "The deserialized product object should not be null.");
        assertEquals(product.getId(), productId, "Product ID mismatch.");
        assertEquals(product.getName(), "Laptop Pro", "Product name mismatch.");
        assertEquals(product.getPrice(), 1200.00, 0.01, "Product price mismatch."); // Delta for double comparison
        assertEquals(product.getCategory(), "Electronics", "Product category mismatch.");
        assertTrue(product.getStock() > 0, "Product stock should be positive.");
        assertTrue(product.isAvailable(), "Product should be available.");

        System.out.println("Successfully deserialized and validated product: " + product);
    }

    @Test(description = "Verify creating a new product and deserializing the response, then updating it")
    public void testCreateAndUpdateProductWithDeserialization() {
        // 1. Create a new product POJO to send in the request
        Product newProduct = new Product(null, "Wireless Mouse", 25.99, "Accessories", 150, true);

        // Perform POST request to create the product
        Response createResponse = RestAssured.given()
                                        .contentType("application/json") // Specify content type as JSON
                                        .body(newProduct) // RestAssured automatically serializes the POJO to JSON
                                        .when()
                                        .post("/") // Assuming POST to base URI creates new product
                                        .then()
                                        .statusCode(201) // Expect 201 Created status
                                        .extract()
                                        .response();

        // Deserialize the creation response to get the server-assigned ID and other details
        Product createdProduct = createResponse.as(Product.class);
        assertNotNull(createdProduct.getId(), "Created product should have an ID assigned by the server.");
        assertEquals(createdProduct.getName(), newProduct.getName());
        assertEquals(createdProduct.getPrice(), newProduct.getPrice());

        System.out.println("Created product: " + createdProduct);

        // 2. Update the created product
        createdProduct.setPrice(29.99); // Update the price
        createdProduct.setStock(130);   // Update the stock

        Response updateResponse = RestAssured.given()
                                        .contentType("application/json")
                                        .body(createdProduct) // Send the updated POJO
                                        .when()
                                        .put("/{productId}", createdProduct.getId()) // Assuming PUT to update
                                        .then()
                                        .statusCode(200) // Expect 200 OK for update
                                        .extract()
                                        .response();

        // Deserialize the update response (often returns the updated object)
        Product updatedProduct = updateResponse.as(Product.class);
        assertEquals(updatedProduct.getPrice(), 29.99, 0.01, "Updated price mismatch.");
        assertEquals(updatedProduct.getStock(), 130, "Updated stock mismatch.");

        System.out.println("Updated product: " + updatedProduct);

        // 3. (Optional) Verify the update by fetching the product again
        Response getResponse = RestAssured.given()
                                .pathParam("productId", updatedProduct.getId())
                                .when()
                                .get("/{productId}")
                                .then()
                                .statusCode(200)
                                .extract()
                                .response();

        Product verifiedProduct = getResponse.as(Product.class);
        assertEquals(verifiedProduct.getPrice(), 29.99, 0.01, "Verification failed: Price after re-fetch incorrect.");
        assertEquals(verifiedProduct.getStock(), 130, "Verification failed: Stock after re-fetch incorrect.");
    }

    @Test(description = "Verify handling of a product not found scenario with deserialization (e.g., error object)")
    public void testProductNotFoundDeserialization() {
        String nonExistentId = "NONEXISTENT123";

        // For this test, we might expect a different POJO if the API returns a structured error
        // Let's assume a generic error response structure like:
        // { "timestamp": "...", "status": 404, "error": "Not Found", "message": "Product not found" }
        // We'd need an `ErrorResponse` POJO. For simplicity here, we'll just check status code.

        Response response = RestAssured.given()
                                .pathParam("productId", nonExistentId)
                                .when()
                                .get("/{productId}")
                                .then()
                                .statusCode(404) // Expect 404 Not Found
                                .extract()
                                .response();

        // If the API returns a standard error object, we could deserialize it like:
        // ErrorResponse error = response.as(ErrorResponse.class);
        // assertNotNull(error);
        // assertEquals(error.getMessage(), "Product not found");

        System.out.println("Handled product not found for ID: " + nonExistentId + ". Response body: " + response.asString());
    }
}
```

## Best Practices
- **Create Dedicated POJOs:** For each distinct API response structure, create a corresponding Java POJO. These should accurately reflect the JSON/XML structure, including nested objects and arrays.
- **Use `JsonIgnoreProperties(ignoreUnknown = true)`:** Annotate your POJOs with `@JsonIgnoreProperties(ignoreUnknown = true)` from Jackson. This prevents your tests from breaking if the API introduces new fields in the response that your POJO doesn't yet model.
- **Implement `equals()`, `hashCode()`, and `toString()`:** Override these methods in your POJOs. `equals()` and `hashCode()` are crucial for comparing objects in assertions (e.g., comparing a deserialized response object with an expected object). `toString()` is invaluable for debugging.
- **Separate POJOs from Tests:** Keep your POJO classes in a separate package (e.g., `com.example.api.models`) from your test classes. This promotes a clean architecture and reusability.
- **Use Default Constructors:** Ensure your POJOs have a public no-argument constructor, as most deserialization libraries rely on it.
- **Handle Collections:** For JSON arrays, deserialize into `List<MyPojo>` or `MyPojo[]`. RestAssured's `.as()` method can often handle this directly if the type is specified correctly.
- **Consider Data Builders:** For creating complex request bodies or expected response objects, consider using the Builder pattern to make object creation more readable and flexible, especially in data-driven tests.

## Common Pitfalls
- **Missing Default Constructor:** Forgetting to add a public no-argument constructor to your POJO will often lead to `InstantiationException` or similar errors during deserialization.
- **Field Name Mismatches:** If your Java field names don't exactly match the JSON keys (case-sensitive), deserialization will fail to populate those fields. Use `@JsonProperty("jsonKeyName")` (Jackson) or `@SerializedName("jsonKeyName")` (Gson) annotations to map them correctly.
- **Type Mismatches:** Trying to deserialize a JSON string into an `int` field, or a JSON array into a single object, will cause errors. Ensure your Java types precisely match the JSON data types.
- **Ignoring Unknown Fields:** Without `@JsonIgnoreProperties(ignoreUnknown = true)`, your tests might fail when an API adds new fields, even if those fields aren't relevant to your current test case.
- **Nested Object Issues:** Incorrectly defining nested POJOs or missing the appropriate POJO for a nested JSON object will result in `null` values or deserialization errors for those parts of the response.
- **Performance Overhead for Very Large Responses:** While generally negligible, for extremely large responses (MBs of data), repeated deserialization might have a minor performance impact. For most API testing, this is not a concern.
- **Not Asserting on Deserialized Object:** Just deserializing isn't enough; you must then use the getters of the deserialized object to perform meaningful assertions against your expected values.

## Interview Questions & Answers
1.  **Q: What is deserialization in the context of API testing, and why is it important?**
    A: Deserialization is the process of converting an API response (typically JSON or XML string) into a strongly-typed object in your programming language (e.g., a Java POJO). It's crucial because it transforms raw string data into a structured format, allowing testers to interact with the response using object-oriented principles. This leads to more readable, maintainable, and less error-prone assertions compared to parsing strings or using complex path expressions (like JsonPath) for every field. It enables better data validation and facilitates data-driven testing.

2.  **Q: How do you handle cases where API response JSON keys don't match your Java POJO field names?**
    A: You can use annotations provided by the deserialization library. For Jackson (commonly used with RestAssured), you would use `@JsonProperty("json_key_name")` above the corresponding Java field. For example, if the JSON has `"first_name"`, but your Java field is `firstName`, you'd use `@JsonProperty("first_name") private String firstName;`.

3.  **Q: What are POJOs, and why are they fundamental to deserialization in API automation?**
    A: POJO stands for Plain Old Java Object. In API automation, POJOs are simple Java classes that represent the structure of your API's request or response payloads. They are fundamental because deserialization libraries map the JSON/XML fields directly to the POJO's fields. By defining POJOs, you create a contract for your API's data, making your test code strongly typed, easy to read, and maintainable. Changes in the API contract are immediately visible as compilation errors in your POJOs, acting as an early warning system.

4.  **Q: What happens if your POJO is missing a field that exists in the API response JSON? How can you mitigate this?**
    A: By default, many deserialization libraries (like Jackson) will throw an exception (e.g., `UnrecognizedPropertyException`) if they encounter a JSON field that doesn't have a corresponding field in the POJO. To mitigate this, you can annotate your POJO class with `@JsonIgnoreProperties(ignoreUnknown = true)` (from Jackson). This tells the deserializer to simply ignore any unknown fields in the JSON payload, preventing test failures due to non-critical additions to the API response.

## Hands-on Exercise
**Scenario:** You are testing a simple "Bookstore" API.

**Task:**
1.  **Define POJOs:** Create Java POJOs for a `Book` and `Author` based on the sample JSON responses below.
    *   `Book` fields: `id` (String), `title` (String), `genre` (String), `publicationYear` (int), `author` (Author object).
    *   `Author` fields: `id` (String), `name` (String), `nationality` (String).
2.  **Implement API Test:** Write a TestNG test method that performs the following steps:
    *   Set up RestAssured base URI to a placeholder (e.g., `http://localhost:8080/api/v1`).
    *   **GET /books/{bookId}**: Make a GET request to retrieve a specific book (e.g., `/books/BK001`).
        *   Deserialize the response into a `Book` POJO.
        *   Assert the `title`, `genre`, `publicationYear`, and the `author`'s `name` and `nationality` using the POJO's getters.
    *   **POST /books**: Create a new book.
        *   Construct a `Book` object in your test with an embedded `Author` object.
        *   Send this `Book` object as the request body.
        *   Deserialize the response (which should be the newly created book, potentially with a server-generated ID) back into a `Book` POJO.
        *   Assert that the server assigned an `id` and that other fields match what you sent.

**Sample JSON Responses:**

**GET /books/BK001 Response:**
```json
{
    "id": "BK001",
    "title": "The Hitchhiker's Guide to the Galaxy",
    "genre": "Science Fiction",
    "publicationYear": 1979,
    "author": {
        "id": "AUTH001",
        "name": "Douglas Adams",
        "nationality": "British"
    }
}
```

**POST /books Request Body Example:**
```json
{
    "title": "A Brief History of Time",
    "genre": "Science",
    "publicationYear": 1988,
    "author": {
        "name": "Stephen Hawking",
        "nationality": "British"
    }
}
```

**POST /books Response (after successful creation, server adds ID):**
```json
{
    "id": "BK002",
    "title": "A Brief History of Time",
    "genre": "Science",
    "publicationYear": 1988,
    "author": {
        "id": "AUTH002",
        "name": "Stephen Hawking",
        "nationality": "British"
    }
}
```

## Additional Resources
-   **RestAssured Deserialization Documentation:** [https://github.com/rest-assured/rest-assured/wiki/Usage#deserialization](https://github.com/rest-assured/rest-assured/wiki/Usage#deserialization)
-   **Jackson Annotations Tutorial:** [https://www.baeldung.com/jackson-annotations](https://www.baeldung.com/jackson-annotations)
-   **Gson User Guide (if using Gson instead of Jackson):** [https://github.com/google/gson/blob/master/UserGuide.md](https://github.com/google/gson/blob/master/UserGuide.md)
-   **POJO Best Practices:** [https://www.baeldung.com/java-pojo-class](https://www.baeldung.com/java-pojo-class)
---
# api-4.4-ac8.md

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
