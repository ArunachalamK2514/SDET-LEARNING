# REST Assured Filters for Request/Response Modification and Logging

## Overview
REST Assured filters provide a powerful mechanism to intercept and modify HTTP requests and responses, or to perform actions like logging, before they are sent or processed. This feature is crucial for advanced test automation scenarios, enabling global configurations, adding dynamic headers, masking sensitive data, or implementing custom logging strategies without cluttering individual test methods. Understanding and utilizing filters efficiently is a hallmark of a robust test automation framework.

## Detailed Explanation
In REST Assured, a `Filter` is an interface that allows you to hook into the request and response lifecycle. When a filter is applied, it gets a chance to inspect and modify the `RequestSpecification`, `ResponseSpecification`, and `Response` objects. This provides a centralized way to handle cross-cutting concerns.

There are primarily two types of operations you can perform with filters:
1.  **Request Modification**: Adding headers, parameters, authentication details, or even modifying the request body before it's sent.
2.  **Response Modification/Inspection**: Intercepting the response to perform custom assertions, mask sensitive data before logging, or extract specific information for later use.
3.  **Logging**: Implementing custom logging logic, perhaps integrating with an external logging framework or logging requests/responses in a specific format.

### How Filters Work:
The `Filter` interface has a single method:
```java
Response filter(FilterableRequestSpecification requestSpec, FilterableResponseSpecification responseSpec, FilterContext ctx);
```
-   `FilterableRequestSpecification`: Represents the request that is about to be sent. You can modify headers, base URI, authentication, etc.
-   `FilterableResponseSpecification`: Represents the expected response.
-   `FilterContext`: Provides access to the next filter in the chain or the actual request execution. Calling `ctx.next(requestSpec, responseSpec)` passes control to the next filter or executes the request if it's the last filter.

### Applying Filters:
Filters can be applied in several ways:
-   **Per-request**: Directly to a `RequestSpecification` instance.
-   **Globally**: To the static `RestAssured` configuration, affecting all subsequent requests. This is ideal for common requirements like logging all requests/responses or adding a default header.

## Code Implementation

This example demonstrates how to create a custom filter for logging request and response details, and another filter to add a custom header to every request.

```java
import io.restassured.RestAssured;
import io.restassured.filter.Filter;
import io.restassured.filter.FilterContext;
import io.restassured.filter.log.LogDetail;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import io.restassured.specification.FilterableRequestSpecification;
import io.restassured.specification.FilterableResponseSpecification;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

/**
 * Demonstrates the use of REST Assured Filters for logging and modifying requests.
 */
public class RestAssuredFilterExample {

    // A simple endpoint for demonstration. Replace with a real API if needed.
    // This example assumes a POST endpoint that echoes back the sent data and a GET endpoint.
    private static final String BASE_URI = "https://jsonplaceholder.typicode.com";

    @BeforeAll
    public static void setup() {
        RestAssured.baseURI = BASE_URI;
        // Optionally, reset filters before each test run if configured globally elsewhere
        // RestAssured.filters(new CustomLoggingFilter(), new CustomHeaderFilter("X-Client-ID", "MyAwesomeApp"));
    }

    /**
     * Custom filter to log request and response details.
     * This filter logs the request method, URI, headers, and body,
     * and then the response status, headers, and body.
     */
    public static class CustomLoggingFilter implements Filter {
        @Override
        public Response filter(FilterableRequestSpecification requestSpec, FilterableResponseSpecification responseSpec, FilterContext ctx) {
            System.out.println("--- Request Log ---");
            System.out.println("Method: " + requestSpec.getMethod());
            System.out.println("URI: " + requestSpec.getURI());
            System.out.println("Headers: " + requestSpec.getHeaders());
            // Log body only if present
            if (requestSpec.getBody() != null) {
                System.out.println("Body: " + requestSpec.getBody());
            }
            System.out.println("-------------------");

            Response response = ctx.next(requestSpec, responseSpec); // Execute the request and get the response

            System.out.println("--- Response Log ---");
            System.out.println("Status: " + response.getStatusLine());
            System.out.println("Headers: " + response.getHeaders());
            // Log body only if present and not too large
            if (response.getBody() != null && response.getBody().asString().length() < 2000) { // Limit logging large bodies
                System.out.println("Body: " + response.getBody().asString());
            } else if (response.getBody() != null) {
                System.out.println("Body: (truncated due to size)");
            }
            System.out.println("--------------------");
            return response;
        }
    }

    /**
     * Custom filter to add a specific header to every outgoing request.
     */
    public static class CustomHeaderFilter implements Filter {
        private final String headerName;
        private final String headerValue;

        public CustomHeaderFilter(String headerName, String headerValue) {
            this.headerName = headerName;
            this.headerValue = headerValue;
        }

        @Override
        public Response filter(FilterableRequestSpecification requestSpec, FilterableResponseSpecification responseSpec, FilterContext ctx) {
            System.out.println("Applying header: " + headerName + " = " + headerValue + " to request: " + requestSpec.getURI());
            requestSpec.header(headerName, headerValue);
            return ctx.next(requestSpec, responseSpec); // Pass control to the next filter or execute the request
        }
    }

    @Test
    void testGetRequestWithGlobalFilters() {
        System.out.println("
--- Running testGetRequestWithGlobalFilters ---");
        // Apply filters globally for all tests in this context
        RestAssured.filters(new CustomLoggingFilter(), new CustomHeaderFilter("X-Global-Correlation-ID", "abc-123"));

        given()
            .when()
                .get("/todos/1")
            .then()
                .statusCode(200)
                .body("id", equalTo(1));

        // Clear filters after test if you don't want them to affect other tests
        RestAssured.reset();
        System.out.println("--- testGetRequestWithGlobalFilters Finished ---
");
    }

    @Test
    void testPostRequestWithSpecificFilters() {
        System.out.println("
--- Running testPostRequestWithSpecificFilters ---");
        // Apply filters only for this specific request
        given()
            .filter(new CustomLoggingFilter())
            .filter(new CustomHeaderFilter("X-Request-Trace", "post-test-456"))
            .contentType(ContentType.JSON)
            .body("{ "title": "foo", "body": "bar", "userId": 1 }")
        .when()
            .post("/posts")
        .then()
            .statusCode(201)
            .body("title", equalTo("foo"))
            .body("userId", equalTo(1));
        System.out.println("--- testPostRequestWithSpecificFilters Finished ---
");
    }

    @Test
    void testDefaultRestAssuredLoggingFilter() {
        System.out.println("
--- Running testDefaultRestAssuredLoggingFilter ---");
        // REST Assured's built-in logging filter
        given()
            .filter(new io.restassured.filter.log.RequestLoggingFilter(LogDetail.ALL))
            .filter(new io.restassured.filter.log.ResponseLoggingFilter(LogDetail.ALL))
            .when()
                .get("/todos/2")
            .then()
                .statusCode(200)
                .body("id", equalTo(2));
        System.out.println("--- testDefaultRestAssuredLoggingFilter Finished ---
");
    }
}
```

## Best Practices
-   **Keep Filters Focused**: Each filter should ideally have a single responsibility (e.g., logging, header modification, authentication). This improves readability and maintainability.
-   **Global vs. Per-Request**: Use global filters (`RestAssured.filters(...)`) for concerns that apply to almost all requests (e.g., default authentication, universal logging). Use per-request filters (`given().filter(...)`) for specific scenarios or when a filter should only apply to a subset of requests.
-   **Order Matters**: The order in which filters are applied matters, as each filter passes the request/response to the next. For example, a logging filter should generally come before a filter that masks sensitive data if you want to log the unmasked data.
-   **Error Handling**: Consider how your filters behave in case of API errors. You might want to log error responses differently or add specific headers for error tracking.
-   **Performance**: While powerful, too many complex filters can introduce overhead. Profile your tests if performance becomes a concern.
-   **Reset Global Filters**: If you set global filters in `@BeforeAll` or `@BeforeEach`, remember to reset them in `@AfterAll` or `@AfterEach` using `RestAssured.reset()` to prevent them from interfering with other tests or test classes.

## Common Pitfalls
-   **Forgetting `ctx.next()`**: If you forget to call `ctx.next(requestSpec, responseSpec)` in your filter, the request will not proceed, and your tests will hang or fail.
-   **Infinite Loops**: If filters are not designed carefully, they might lead to infinite loops, especially if a filter somehow re-triggers the request execution.
-   **Modifying Immutable Objects**: Be aware that `RequestSpecification` and `Response` objects might have immutable aspects. Always use the methods provided by `FilterableRequestSpecification` to modify the request.
-   **Over-logging Sensitive Data**: Ensure your logging filters do not expose sensitive information (e.g., API keys, passwords) in logs, especially in shared environments. Implement masking if necessary.
-   **Unexpected Global Impact**: Applying a filter globally and forgetting to clear it can lead to unexpected side effects in other tests. Always be mindful of the scope of your filters.

## Interview Questions & Answers
1.  **Q**: What are REST Assured Filters and why are they useful in test automation?
    **A**: REST Assured Filters are interceptors that allow you to inspect and modify HTTP requests and responses at different stages of their lifecycle. They are useful because they provide a centralized, reusable mechanism to handle cross-cutting concerns like logging, adding common headers (e.g., authentication tokens), modifying payloads, or implementing custom error handling, without duplicating code in every test. This leads to cleaner, more maintainable, and robust test suites.

2.  **Q**: Explain the `filter()` method signature and the role of `FilterableRequestSpecification`, `FilterableResponseSpecification`, and `FilterContext`.
    **A**: The `filter()` method signature is `Response filter(FilterableRequestSpecification requestSpec, FilterableResponseSpecification responseSpec, FilterContext ctx)`.
    -   `FilterableRequestSpecification`: This object allows you to inspect and modify the outgoing request, such as adding headers, query parameters, changing the base URI, or altering the request body.
    -   `FilterableResponseSpecification`: This object represents the expected response and can be used to influence how REST Assured validates the response, though direct modification of the incoming `Response` object is typically done after `ctx.next()`.
    -   `FilterContext`: This object provides the means to pass control to the next filter in the chain or to execute the actual HTTP request if it's the last filter. You must call `ctx.next(requestSpec, responseSpec)` to ensure the request proceeds.

3.  **Q**: When would you use a global filter versus a per-request filter in REST Assured? Provide examples.
    **A**:
    -   **Global Filters**: Used when a specific concern applies to almost all or a large majority of your API requests. They are configured once (e.g., in a `@BeforeAll` method or static block) and affect all subsequent `given()` calls.
        *   *Example*: A logging filter that logs all requests and responses for debugging purposes.
        *   *Example*: An authentication filter that automatically adds an `Authorization` header with a bearer token to every request after login.
    -   **Per-request Filters**: Used when a filter's logic is specific to a particular test case or a small subset of requests. They are applied directly to a `RequestSpecification` using `given().filter(...)`.
        *   *Example*: A filter that adds a unique `X-Trace-ID` header for a specific test to trace a single request in system logs.
        *   *Example*: A filter to mask sensitive data in the request body for a particular test's logging output, while other tests might not require this.

## Hands-on Exercise
1.  **Objective**: Create a REST Assured custom filter that injects an `Accept-Language: en-US` header into all requests.
2.  **Steps**:
    *   Create a new class `AcceptLanguageFilter` that implements the `io.restassured.filter.Filter` interface.
    *   Inside the `filter` method, add the `Accept-Language` header to the `requestSpec`.
    *   Apply this filter globally using `RestAssured.filters()`.
    *   Write a test that makes a GET request to `https://httpbin.org/headers`.
    *   Assert that the response body contains the `Accept-Language` header with the value `en-US`.
    *   Remember to call `RestAssured.reset()` after your test to clean up global configurations.

## Additional Resources
-   **REST Assured Filters Documentation**: [https://rest-assured.io/docs/filters/](https://rest-assured.io/docs/filters/)
-   **Baeldung Tutorial on REST Assured Filters**: [https://www.baeldung.com/rest-assured-filters](https://www.baeldung.com/rest-assured-filters)
-   **GitHub Example of Custom Filters**: Search for `RestAssured custom filter example` on GitHub for more practical implementations.
