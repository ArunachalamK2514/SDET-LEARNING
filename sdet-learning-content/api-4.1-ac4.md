# Status Code Validation in REST Assured

## Overview
Status codes are a fundamental part of the HTTP protocol, indicating the outcome of an API request. Validating these codes is a critical step in API testing to ensure that the server responds as expected under various scenarios (success, client errors, server errors, etc.). REST Assured provides a straightforward and powerful way to assert HTTP status codes, making it an indispensable tool for robust API automation. This document covers how to validate common status codes like 200 (OK), 201 (Created), 400 (Bad Request), 404 (Not Found), and 500 (Internal Server Error).

## Detailed Explanation

HTTP status codes are three-digit integers grouped into five classes:
*   **1xx Informational:** Request received, continuing process.
*   **2xx Success:** The action was successfully received, understood, and accepted.
*   **3xx Redirection:** Further action needs to be taken to complete the request.
*   **4xx Client Error:** The request contains bad syntax or cannot be fulfilled.
*   **5xx Server Error:** The server failed to fulfill an apparently valid request.

In API testing, we primarily focus on `2xx`, `4xx`, and `5xx` codes. REST Assured's `statusCode()` matcher allows us to assert these codes directly.

### Common Status Codes and Their Usage in Testing:

*   **200 OK:** Indicates that the request has succeeded. This is the most common successful response.
    *   *Testing Scenario:* A successful GET request to retrieve resources.
*   **201 Created:** The request has been fulfilled and resulted in a new resource being created.
    *   *Testing Scenario:* A successful POST request to create a new resource.
*   **400 Bad Request:** The server cannot or will not process the request due to something that is perceived to be a client error (e.g., malformed request syntax, invalid request message framing, or deceptive request routing).
    *   *Testing Scenario:* Sending a POST/PUT request with invalid or missing mandatory fields.
*   **404 Not Found:** The server cannot find the requested resource. Links that lead to a 404 page are often called broken or dead links.
    *   *Testing Scenario:* Attempting to retrieve, update, or delete a resource that does not exist using an invalid ID.
*   **500 Internal Server Error:** A generic error message, given when an unexpected condition was encountered and no more specific message is suitable.
    *   *Testing Scenario:* Simulating server-side issues (e.g., through invalid parameters that cause an unhandled exception on the server) or testing system resilience.

## Code Implementation

Let's illustrate status code validation with practical REST Assured examples. We'll use a hypothetical API endpoint for `users`.

First, ensure you have the necessary REST Assured dependencies in your `pom.xml` (for Maven) or `build.gradle` (for Gradle).

```xml
<!-- Maven pom.xml -->
<dependencies>
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.3.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter-api</artifactId>
        <version>5.10.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter-engine</artifactId>
        <version>5.10.0</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

public class StatusCodeValidationTest {

    private static final String BASE_URL = "https://reqres.in/api"; // Using a public test API

    @BeforeAll
    public static void setup() {
        RestAssured.baseURI = BASE_URL;
    }

    @Test
    public void testStatusCode200_Success() {
        // Test a successful GET request, expecting 200 OK
        given()
            .when()
                .get("/users?page=2") // Endpoint that should return 200 OK
            .then()
                .statusCode(200) // Assert the status code is 200
                .log().body(); // Log the response body for debugging
    }

    @Test
    public void testStatusCode201_ResourceCreation() {
        // Test a successful POST request for resource creation, expecting 201 Created
        String requestBody = "{"name": "morpheus", "job": "leader"}";

        given()
            .contentType(ContentType.JSON) // Set content type for request body
            .body(requestBody) // Attach the JSON request body
            .when()
                .post("/users") // Endpoint for creating a user
            .then()
                .statusCode(201) // Assert the status code is 201
                .body("name", equalTo("morpheus")) // Optionally, validate response body
                .body("job", equalTo("leader"))
                .log().body();
    }

    @Test
    public void testStatusCode400_BadRequest() {
        // Test a POST request with invalid data, expecting 400 Bad Request
        // Note: reqres.in might return 200 for invalid POST, so this example is conceptual
        // For a real API, you'd send an invalid request (e.g., missing mandatory field)
        String invalidRequestBody = "{"invalid_field": "value"}"; // Missing 'name' and 'job'

        given()
            .contentType(ContentType.JSON)
            .body(invalidRequestBody)
            .when()
                .post("/register") // Using a /register endpoint that might return 400 for bad input
            .then()
                // On reqres.in, this might return 200 with an error message in body.
                // For a truly robust test, you'd need an API that explicitly returns 400.
                .statusCode(anyOf(equalTo(400), equalTo(200))) // Adjust based on API behavior
                // If it returns 200 with an error, you'd check the error message in the body
                .log().body();
    }

    @Test
    public void testStatusCode404_NotFound() {
        // Test a GET request for a non-existent resource, expecting 404 Not Found
        given()
            .when()
                .get("/users/99999") // User with ID 99999 unlikely to exist
            .then()
                .statusCode(404) // Assert the status code is 404
                .log().body();
    }

    @Test
    public void testStatusCode500_InternalServerErrorSimulation() {
        // Simulating a 500 Internal Server Error.
        // Public APIs rarely provide endpoints that intentionally throw 500 errors
        // via client-side input. For real-world scenarios, this would involve:
        // 1. Calling an endpoint with parameters known to cause server errors.
        // 2. Setting up a mock server that returns 500.
        // 3. Directly testing server-side logic that generates 500s.

        // This is a conceptual example as reqres.in doesn't have an endpoint to trigger 500 easily.
        // If an endpoint `/simulate-error` existed which is designed to fail with 500:
        given()
            .when()
                .get("/nonexistent-endpoint-to-force-error") // A URL that is likely to fail
            .then()
                .statusCode(anyOf(equalTo(500), equalTo(404))) // Adjust based on specific endpoint behavior
                .log().body();

        System.out.println("Note: Simulating 500 requires an API endpoint designed to return it, or a mock server.");
        System.out.println("The above example for 500 might return 404 if the endpoint just doesn't exist.");
    }
}
```

## Best Practices
-   **Use Descriptive Test Names:** Make test method names reflect the scenario and expected status code (e.g., `testStatusCode200_Success`).
-   **Parameterize Tests:** For endpoints that can return various error codes based on different inputs (e.g., 400 for invalid data, 401 for unauthorized, 403 for forbidden), use parameterized tests to cover all relevant scenarios efficiently.
-   **Combine with Body Assertions:** Always combine status code validation with assertions on the response body, especially for error cases, to verify the error message or structure.
-   **Avoid Hardcoding:** Use configuration files or environment variables for `BASE_URI` to easily switch between environments (dev, staging, prod).
-   **Test Negative Scenarios Thoroughly:** Explicitly test for `4xx` and `5xx` status codes to ensure your API handles errors gracefully and provides meaningful error messages.

## Common Pitfalls
-   **Ignoring Response Body for Errors:** Just checking the status code for `4xx` or `5xx` is insufficient. The response body often contains critical information about *why* the error occurred. Always inspect it.
-   **Assuming 200 for All Successes:** While 200 is common, `201 Created` (for POST), `202 Accepted` (for asynchronous processing), `204 No Content` (for successful DELETE), etc., are also success codes. Use the appropriate one.
-   **Not Handling Network Issues:** Status code validation primarily deals with API responses. Network issues (connection refused, timeouts) might manifest differently before a status code is even received. These require different handling (e.g., `try-catch` blocks or specific timeout configurations).
-   **Over-reliance on `statusCode(200)`:** Some APIs might return `200 OK` even for logical errors, with the actual error details in the response body. Always cross-check with body assertions.

## Interview Questions & Answers
1.  **Q: Why is validating HTTP status codes crucial in API testing?**
    **A:** Validating status codes is crucial because they are the primary indicator of the API's operational outcome. They tell us immediately if a request succeeded, if there was a client-side error, or a server-side error. This ensures that the API behaves as per its contract, handles valid inputs correctly, and gracefully manages invalid inputs or unexpected server conditions. Without status code validation, a test might pass even if the API returned an error, leading to false positives.

2.  **Q: Can an API return a 200 status code but still indicate an error? How would you test for this?**
    **A:** Yes, this is a common anti-pattern, especially in older or less-RESTful APIs. An API might return `200 OK` but include an error message, an error code, or an empty/malformed data structure within the JSON/XML response body.
    To test for this, you would:
    *   First, assert the `statusCode(200)`.
    *   Then, you would perform additional assertions on the response body to check for the presence of specific error fields (e.g., `"error": true`, `"errorCode": "some_code"`) or the absence of expected success data. For example: `body("status", equalTo("failure"))` or `body("data", is(empty()))`.

3.  **Q: How do you differentiate between 4xx and 5xx errors, and what are their implications for testing?**
    **A:**
    *   **4xx (Client Error):** These indicate that the client's request was somehow flawed (e.g., bad syntax, missing authentication, non-existent resource). From a testing perspective, 4xx errors usually mean the test itself provided invalid input or made an incorrect request. Tests for 4xx errors are often positive tests for *error handling capabilities*, ensuring the API correctly rejects bad requests.
    *   **5xx (Server Error):** These indicate that the server failed to fulfill a valid request. This points to an issue on the server side (e.g., database down, internal application error, unhandled exception). From a testing perspective, 5xx errors typically signify a bug in the API's implementation or infrastructure. Testing for 5xx often involves simulating extreme conditions or specific edge cases that might expose server vulnerabilities, or verifying that the server provides minimal information in public responses (to prevent information leakage).

## Hands-on Exercise
1.  **Setup a Mock API:** Use a tool like WireMock, MockServer, or a public service like `jsonplaceholder.typicode.com` or `reqres.in`.
2.  **Create a Test Class:** Set up a new Java project with Maven/Gradle and add REST Assured and JUnit 5 dependencies.
3.  **Write Tests for Each Scenario:**
    *   Write a test that makes a GET request to a valid endpoint and asserts a `200 OK`.
    *   Write a test that makes a POST request to create a resource and asserts a `201 Created`.
    *   Write a test that makes a GET request to a non-existent resource (e.g., `/users/nonexistentid`) and asserts a `404 Not Found`.
    *   *Challenge (Optional):* If you can configure your mock server or find a public API that explicitly returns `400 Bad Request` for malformed input, write a test for that. Otherwise, simulate it conceptually.

## Additional Resources
-   **REST Assured Official Documentation:** [https://rest-assured.io/](https://rest-assured.io/)
-   **HTTP Status Codes (MDN Web Docs):** [https://developer.mozilla.org/en-US/docs/Web/HTTP/Status](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
-   **JUnit 5 Official Documentation:** [https://junit.org/junit5/docs/current/user-guide/](https://junit.org/junit5/docs/current/user-guide/)
