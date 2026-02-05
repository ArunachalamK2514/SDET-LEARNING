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