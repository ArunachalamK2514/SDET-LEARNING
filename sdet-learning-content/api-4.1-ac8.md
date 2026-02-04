# REST Assured Fundamentals: Base URI, Headers, Path & Query Parameters

## Overview
In REST Assured, effectively managing your API request configuration is crucial for writing clean, maintainable, and robust API tests. This guide focuses on four fundamental aspects: setting a base URI, and incorporating path parameters, query parameters, and custom headers into your requests. These elements allow you to target specific API endpoints, filter data, and provide necessary contextual information for your API calls, making your test suite highly adaptable to real-world API interactions.

## Detailed Explanation

### 1. Base URI (`RestAssured.baseURI`)
The Base Uniform Resource Identifier (URI) is the common, unchanging part of your API endpoint URL. Configuring it allows you to define this common part once, avoiding repetition across multiple tests. This improves readability and makes your tests easier to update if the API's base URL changes.

*   **Global Configuration**: Set `RestAssured.baseURI` once, typically in a setup method or a static block, to apply it to all subsequent requests.
*   **Local Overriding**: You can override the `baseURI` for specific requests using `given().baseUri(...)` if a test needs to hit a different service.

**Example**: If your API endpoints are `https://api.example.com/users` and `https://api.example.com/products`, then `https://api.example.com` would be your base URI.

### 2. Query Parameters (`queryParam`)
Query parameters are key-value pairs appended to the URL after a question mark (`?`), separated by ampersands (`&`). They are primarily used to filter, sort, paginate, or provide additional optional data for a resource.

**Syntax**: `?key1=value1&key2=value2`
**Usage**: In REST Assured, you add them using the `.queryParam(key, value)` method.

**Example**: To get a list of active users, you might use `/users?status=active`.

### 3. Path Parameters (`pathParam`)
Path parameters are variable parts of the URL path that identify specific resources or subsets of resources. They are embedded directly within the URI structure.

**Syntax**: `/resource/{id}` where `{id}` is a placeholder.
**Usage**: In REST Assured, you define placeholders in your path (e.g., `/api/users/{userId}`) and then use the `.pathParam(key, value)` method to substitute the actual values.

**Example**: To get details of a user with ID `2`, you would use `/users/2`. Here, `2` is the path parameter.

### 4. Custom Headers (`header`)
HTTP headers are key-value pairs that are sent along with an HTTP request or response. They provide metadata about the request or response, such as content type, authorization credentials, client information, or caching instructions.

**Common Uses**:
*   **Authorization**: `Authorization: Bearer <token>`
*   **Content Type**: `Content-Type: application/json`
*   **Accept**: `Accept: application/xml` (to specify expected response format)
*   **Custom Data**: `X-Client-ID: myApp`

**Usage**: In REST Assured, you can add headers using `.header(name, value)` or `.headers(Map<String, String> headers)`.

## Code Implementation

Let's demonstrate these concepts with practical examples using the `https://reqres.in/api` endpoint. We'll use TestNG for test execution.

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;
import java.util.Map;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

public class RestAssuredParametersAndHeadersTest {

    // Globally configure the base URI for all tests in this class
    @BeforeClass
    public void setup() {
        RestAssured.baseURI = "https://reqres.in";
        RestAssured.basePath = "/api"; // Optional: Can also set a base path
        System.out.println("Base URI and Path set to: " + RestAssured.baseURI + RestAssured.basePath);
    }

    @Test(description = "Verify GET request with a query parameter for filtering results")
    public void testGetUsersWithQueryParameter() {
        System.out.println("
--- Running testGetUsersWithQueryParameter ---");
        // GET /api/users?page=2
        given()
            .queryParam("page", 2) // Add query parameter
        .when()
            .get("/users") // Endpoint relative to baseURI and basePath
        .then()
            .statusCode(200)
            .body("page", equalTo(2))
            .body("data", hasSize(6)) // Verify response contains data for page 2
            .log().body(); // Log the response body for inspection
    }

    @Test(description = "Verify GET request with a path parameter for specific resource targeting")
    public void testGetSingleUserWithPathParameter() {
        System.out.println("
--- Running testGetSingleUserWithPathParameter ---");
        int userId = 5;
        // GET /api/users/5
        given()
            .pathParam("userId", userId) // Add path parameter
        .when()
            .get("/users/{userId}") // Use placeholder for path parameter
        .then()
            .statusCode(200)
            .body("data.id", equalTo(userId))
            .body("data.first_name", equalTo("Charles"))
            .log().body();
    }

    @Test(description = "Verify POST request with custom headers and a request body")
    public void testCreateUserWithCustomHeaders() {
        System.out.println("
--- Running testCreateUserWithCustomHeaders ---");
        String requestBody = "{ "name": "morpheus", "job": "leader" }";

        // Create a map for multiple headers (optional, can use multiple .header() calls)
        Map<String, String> headers = new HashMap<>();
        headers.put("X-Custom-Auth", "mySecretToken123"); // Example custom header
        headers.put("Accept", "application/json"); // Example standard header

        given()
            .contentType(ContentType.JSON) // Set Content-Type header
            .headers(headers) // Add multiple headers from a map
            .header("X-Request-ID", "unique-request-123") // Add a single header
            .body(requestBody)
        .when()
            .post("/users") // POST to /api/users
        .then()
            .statusCode(201) // Expected status code for resource creation
            .body("name", equalTo("morpheus"))
            .body("job", equalTo("leader"))
            .log().body();
    }

    @Test(description = "Demonstrate overriding baseURI for a specific request")
    public void testOverridingBaseURI() {
        System.out.println("
--- Running testOverridingBaseURI ---");
        // This test will hit a different base URI: "https://www.google.com"
        given()
            .baseUri("https://www.google.com") // Override baseURI for this request
        .when()
            .get() // Will hit "https://www.google.com/"
        .then()
            .statusCode(200)
            .log().status(); // Only log status as body might be large
    }
}
```

## Best Practices
-   **Centralize Base URI**: Always define your `RestAssured.baseURI` and `RestAssured.basePath` globally (e.g., in `@BeforeClass` or a common utility class) to ensure consistency and easy maintenance.
-   **Use `RequestSpecification` for Reusability**: For common headers, query parameters, or authentication, create and reuse `RequestSpecification` objects to avoid code duplication.
-   **Descriptive Parameter Names**: Use meaningful names for your path and query parameters that reflect their purpose.
-   **Encode Parameters**: REST Assured automatically encodes parameter values, but be mindful of special characters if constructing URLs manually or using complex values.
-   **Externalize Configuration**: Avoid hardcoding base URIs, API keys, or frequently changing parameters directly in your tests. Use configuration files (e.g., `config.properties`, environment variables) to manage these values.
-   **Clear Path Parameter Placeholders**: Use clear and consistent placeholders for path parameters (e.g., `{userId}`, `{productId}`).

## Common Pitfalls
-   **Confusing Path and Query Parameters**: Incorrectly using a path parameter when a query parameter is needed, or vice-versa, will lead to incorrect API calls or 404 errors.
-   **Hardcoding Values**: Directly embedding `baseURI` or other dynamic values makes tests brittle and hard to adapt to different environments.
-   **Missing Required Headers**: Forgetting to include essential headers like `Authorization` or `Content-Type` for POST/PUT requests can result in `401 Unauthorized` or `415 Unsupported Media Type` errors.
-   **Incorrect Placeholder Usage**: Mismatched path parameter names between the `.pathParam()` call and the URL string (e.g., `.pathParam("id", 1)` but `get("/users/{userId}")`) will cause issues.
-   **Not Resetting Global Configurations**: If you modify `RestAssured.baseURI` or `RestAssured.basePath` within a test without resetting it (or using `given().baseUri()`), it might affect subsequent tests unexpectedly.

## Interview Questions & Answers

1.  **Q: What is the primary difference between a path parameter and a query parameter in the context of RESTful APIs, and how would you implement them using REST Assured?**
    *   **A:** **Path parameters** are used to identify a specific resource or resources within a collection. They are part of the URL path itself, e.g., `/users/123` where `123` is the user ID. In REST Assured, you define them with placeholders like `given().pathParam("id", 123).when().get("/users/{id}")`.
        **Query parameters** are used to filter, sort, paginate, or provide additional optional information about a resource collection. They appear after a question mark (`?`) in the URL, e.g., `/users?status=active&limit=10`. In REST Assured, you use `given().queryParam("status", "active").queryParam("limit", 10).when().get("/users")`.

2.  **Q: How do you handle common headers like `Content-Type` and `Authorization` using REST Assured? Can you provide an example of setting multiple headers?**
    *   **A:** `Content-Type` can be set using `contentType(ContentType.JSON)` or `header("Content-Type", "application/json")`. `Authorization` is typically set using `header("Authorization", "Bearer <your_token>")`.
        To set multiple headers:
        ```java
        Map<String, String> headers = new HashMap<>();
        headers.put("Authorization", "Bearer abc123def456");
        headers.put("X-Custom-Client", "AutomationTest");
        given().headers(headers).when().get("/secure-endpoint");
        ```
        Alternatively, you can chain multiple `.header()` calls:
        ```java
        given().header("Header1", "Value1").header("Header2", "Value2").when().get("/endpoint");
        ```

3.  **Q: Explain the benefit of setting `RestAssured.baseURI` globally versus specifying the full URL in every `get()`, `post()`, etc., call.**
    *   **A:** Setting `RestAssured.baseURI` globally (e.g., `RestAssured.baseURI = "http://api.example.com";`) centralizes the base URL configuration. The main benefits are:
        1.  **Readability**: Test methods become cleaner, as they only need to specify the endpoint's relative path (e.g., `/users`).
        2.  **Maintainability**: If the API's base URL changes (e.g., from `dev.api.com` to `prod.api.com`), you only need to update it in one place, reducing the effort and risk of errors.
        3.  **Flexibility**: It integrates well with environment-specific configurations, allowing you to easily switch between different API environments (e.g., QA, Staging, Production) without modifying test code.

## Hands-on Exercise

Using a publicly available mock API (e.g., ReqRes.in or JSONPlaceholder) or setting up a local mock server:

1.  **Retrieve All Resources**: Write a test to retrieve a list of resources (e.g., users or posts) from a base endpoint (e.g., `/users`). Ensure you set the `baseURI` globally.
2.  **Filter Resources**: Add a query parameter to your GET request to filter the list of resources (e.g., `?page=2` for users on ReqRes.in). Assert that the response data matches the filter.
3.  **Retrieve Specific Resource**: Use a path parameter to retrieve a single, specific resource (e.g., `/users/1`). Assert the details of the retrieved resource.
4.  **Create Resource with Custom Header**: Send a POST request to create a new resource. Include a `Content-Type: application/json` header and at least one custom header (e.g., `X-Correlation-ID`). Verify the successful creation (status code 201) and that the response body contains the submitted data.

## Additional Resources
-   **REST Assured GitHub Wiki**: The official documentation for all features.
    [https://github.com/rest-assured/rest-assured/wiki/Usage#base-path](https://github.com/rest-assured/rest-assured/wiki/Usage#base-path)
-   **Baeldung - REST Assured Tutorial**: A comprehensive guide with various examples.
    [https://www.baeldung.com/rest-assured-tutorial](https://www.baeldung.com/rest-assured-tutorial)
-   **ReqRes - A Hosted REST-API ready to respond to your AJAX requests**: Useful for practicing API tests.
    [https://reqres.in/](https://reqres.in/)
