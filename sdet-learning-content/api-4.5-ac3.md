# API 4.5 AC3: Request/Response Logging with REST Assured

## Overview
In the world of API testing, understanding the exact request being sent and the response being received is crucial for debugging, validating, and ensuring the correct behavior of your services. REST Assured, a popular Java library for testing RESTful APIs, provides robust logging capabilities that allow testers to inspect every detail of the HTTP communication. This acceptance criterion focuses on leveraging `log().all()` for requests and `then().log().all()` for responses, with an emphasis on conditional logging—only printing logs when validation fails—to keep test output clean and focused.

## Detailed Explanation

### Why Logging is Essential in API Testing
Logging API requests and responses helps in:
- **Debugging**: Quickly pinpointing issues when an API call doesn't behave as expected. You can verify if the request payload, headers, or parameters are correctly formed, and if the response matches the expected structure and data.
- **Validation**: Confirming that the API behaves as documented under various conditions.
- **Troubleshooting**: Providing detailed information to developers when reporting bugs.

### `log().all()` for Request Details
When building an API request with REST Assured, you can use `.log().all()` directly after `given()` to print all details of the request *before* it is sent. This includes:
- HTTP Method and URI
- Request Headers
- Request Cookies
- Request Body (if any)

This is invaluable for verifying that your test is constructing the request as intended.

### `then().log().all()` for Response Details
Similarly, after making the API call and receiving a response, you can use `.then().log().all()` to print all details of the response *after* it is received. This includes:
- HTTP Status Line
- Response Headers
- Response Cookies
- Response Body

This allows for immediate inspection of the API's reply, aiding in both positive and negative testing scenarios.

### Conditional Logging: `log().ifValidationFails()`
While `log().all()` is useful, printing every request and response can quickly clutter the console, especially in large test suites. REST Assured offers a more intelligent logging mechanism: `log().ifValidationFails()`. This method allows you to configure logging such that request and/or response details are *only* printed to the console if any assertion or validation within the `then()` block fails. This keeps your test output clean when tests pass and provides critical debugging information exactly when you need it.

You can combine this with `.log().all()` by chaining `ifValidationFails()`:
- `given().log().ifValidationFails().all()`: Logs request details only if validation fails.
- `then().log().ifValidationFails().all()`: Logs response details only if validation fails.

This is the recommended approach for maintaining readable and efficient test logs.

## Code Implementation

Let's assume we have a simple REST API for managing users, accessible at `http://localhost:8080/api/users`.

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

public class ApiLoggingTests {

    // Base URI for the API
    private static final String BASE_URI = "http://localhost:8080";

    @BeforeAll
    static void setup() {
        RestAssured.baseURI = BASE_URI;
        // In a real scenario, you might start a mock server here or ensure the target API is running.
        // For demonstration, assume http://localhost:8080 is accessible.
        System.out.println("------------------------------------------------------------------");
        System.out.println("NOTE: For this test to run, a service must be running at " + BASE_URI);
        System.out.println("If no service is running, the tests will fail with connection errors.");
        System.out.println("------------------------------------------------------------------");
    }

    @Test
    void testGetUserByIdWithFullLogging() {
        // Example: Get a user by ID with full request and response logging
        given()
            .pathParam("id", 1) // Assuming user with ID 1 exists
            .log().all() // Log all request details before sending
        .when()
            .get("/api/users/{id}")
        .then()
            .log().all() // Log all response details after receiving
            .statusCode(200)
            .contentType(ContentType.JSON)
            .body("id", equalTo(1))
            .body("name", notNullValue());
    }

    @Test
    void testCreateUserWithConditionalLogging() {
        String requestBody = "{ "name": "John Doe", "email": "john.doe@example.com" }";

        // Example: Create a new user with conditional logging (only if validation fails)
        // This test is designed to pass, so no logs will be printed.
        given()
            .contentType(ContentType.JSON)
            .body(requestBody)
            .log().ifValidationFails().all() // Log request only if validation fails
        .when()
            .post("/api/users")
        .then()
            .log().ifValidationFails().all() // Log response only if validation fails
            .statusCode(201) // Assuming 201 Created on success
            .contentType(ContentType.JSON)
            .body("name", equalTo("John Doe"))
            .body("email", equalTo("john.doe@example.com"))
            .body("id", notNullValue());
    }

    @Test
    void testCreateUserWithConditionalLogging_FailingScenario() {
        // Simulating a failing scenario where email format is invalid, assuming API returns 400
        String invalidRequestBody = "{ "name": "Jane Doe", "email": "invalid-email" }";

        // This test is designed to fail due to incorrect status code expectation (200 instead of 400),
        // so logs will be printed.
        given()
            .contentType(ContentType.JSON)
            .body(invalidRequestBody)
            .log().ifValidationFails().all() // Request logs will be printed due to subsequent failure
        .when()
            .post("/api/users")
        .then()
            .log().ifValidationFails().all() // Response logs will be printed due to failure
            .statusCode(400) // Expecting 400 Bad Request if email is invalid
            .body("error", containsString("Invalid email format")); // Assuming API provides an error message
    }
}
```

## Best Practices
- **Use Conditional Logging**: Always prefer `log().ifValidationFails().all()` or specific log options like `log().ifError().body()` to keep your console output clean and focused on failures. Full logging (`log().all()`) should be used sparingly, primarily during initial test development or when deeply debugging a specific issue.
- **Avoid Logging Sensitive Data**: Be cautious about logging sensitive information such as passwords, API keys, or personal identifiable information (PII) to the console or log files. If necessary, ensure logs are secured and purged regularly. REST Assured allows logging specific parts of a request/response, e.g., `.log().headers()` or `.log().body()`, which can be more granular.
- **Integrate with Reporting**: Combine REST Assured logging with your test reporting tools (e.g., ExtentReports, Allure) to include request/response details in test reports for better traceability and debugging.
- **Performance Consideration**: While logging is useful, excessive logging, especially of large payloads, can introduce a slight overhead. In performance-critical test environments, be mindful of what and how much you log.

## Common Pitfalls
- **Over-logging**: Printing all request and response details for every single test case can make test output unreadable and difficult to parse, obscuring actual failures.
- **Logging Sensitive Information**: Accidentally logging sensitive data can lead to security vulnerabilities. Always review what is being logged.
- **Misinterpreting Logs**: Just because a log shows a certain request or response doesn't mean it's correct. Always compare logs against expected API behavior and documentation.
- **Not Logging Enough**: On the flip side, not logging anything makes debugging extremely difficult when tests fail unexpectedly. Find a balance, typically achieved with conditional logging.

## Interview Questions & Answers
1. **Q: How do you handle request and response logging in your API automation framework, and why is it important?**
   **A:** I primarily use REST Assured's built-in logging capabilities. For debugging and initial development, I might use `given().log().all()` and `then().log().all()`. However, in a mature test suite, I predominantly use `log().ifValidationFails().all()`. This approach is crucial because it ensures that our test output remains clean and focused. When a test fails, all relevant request and response details are automatically logged, providing immediate context for debugging without cluttering the console with successful test interactions. It significantly speeds up root cause analysis and helps developers understand the exact communication that led to an issue.

2. **Q: What considerations do you take into account when logging API requests and responses, especially in a production-like environment?**
   **A:** The primary considerations are security and performance.
   - **Security**: I ensure that no sensitive data (like authentication tokens, PII, or confidential business data) is logged to the console or persistent logs. If full logging is unavoidable for specific scenarios, strict access controls and retention policies must be in place for those logs. I would opt for logging specific headers or parts of the body if only certain information is needed.
   - **Performance**: Excessive logging, especially of large request/response bodies, can introduce overhead, particularly in high-volume test runs or CI/CD pipelines. Conditional logging mitigates this by only logging when necessary. In extreme cases, logging might be entirely disabled or reduced to error-only levels in performance-sensitive environments.

3. **Q: Can you describe a scenario where conditional logging significantly helped you debug an API test failure?**
   **A:** Absolutely. I was working on an API that involved complex data transformations. One specific test started failing intermittently in the CI/CD pipeline, but passed locally. With conditional logging (`log().ifValidationFails().all()`) enabled, when the test failed in CI, the full request and response details were automatically printed in the build logs. I immediately saw that a specific header, which was dynamically generated, had an incorrect value only in the CI environment due to an environmental configuration issue. Without conditional logging, finding this subtle difference in a sea of successful test logs would have been significantly harder and more time-consuming. It allowed me to quickly identify the discrepancy and work with the DevOps team to correct the environment variable.

## Hands-on Exercise
1. **Setup**: If you don't have one, set up a simple mock API server (e.g., using WireMock, MockServer, or even a simple Spring Boot/Node.js app) that has:
    - A `GET /api/products/{id}` endpoint that returns product details.
    - A `POST /api/products` endpoint that creates a product and returns the created product with a 201 status.
    - Ensure your POST endpoint can return a 400 status if an invalid product name (e.g., empty string) is provided.
2. **Implement**: Write two REST Assured tests:
    - One `GET` test for `/api/products/{id}` that passes and uses `log().all()` for both request and response.
    - One `POST` test for `/api/products` that:
        - Attempts to create a valid product (should pass, no logs with conditional logging).
        - Attempts to create an invalid product (should fail, and logs should automatically appear due to `log().ifValidationFails().all()`).
3. **Observe**: Run your tests and observe the console output. Verify that the logs appear as expected only for the failing scenario when using conditional logging.

## Additional Resources
- **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/) (Refer to the "Logging" section)
- **REST Assured GitHub Repository**: [https://github.com/rest-assured/rest-assured](https://github.com/rest-assured/rest-assured)
