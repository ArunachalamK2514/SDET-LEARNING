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
