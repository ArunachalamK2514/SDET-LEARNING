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
