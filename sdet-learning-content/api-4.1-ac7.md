# Request and Response Specifications in REST Assured

## Overview
In REST Assured, Request and Response Specifications are powerful features that promote reusability, reduce code duplication, and enhance the maintainability of your API test automation framework. They allow you to define common configurations for requests (like base URI, headers, authentication, parameters) and responses (like expected status codes, content types, or body validations) once, and then apply them across multiple tests. This centralizes common setups, making your tests cleaner, more readable, and easier to manage.

## Detailed Explanation
When testing APIs, you often find yourself repeating the same configurations for requests (e.g., `baseUri`, `contentType`, `headers`) and validations for responses (e.g., `statusCode`, `contentType`). Request and Response Specifications address this by allowing you to pre-configure these elements.

### RequestSpecification
A `RequestSpecification` allows you to define common request parameters such as:
- Base URI (`baseUri()`, `basePath()`)
- Headers (`header()`)
- Content Type (`contentType()`)
- Authentication (`auth()`)
- Query parameters (`queryParam()`)
- Form parameters (`formParam()`)
- Cookies (`cookie()`)

You build a `RequestSpecification` using `RestAssured.given().spec(specification)` or by using `RequestSpecBuilder`.

### ResponseSpecification
A `ResponseSpecification` allows you to define common response expectations such as:
- Status Code (`statusCode()`)
- Content Type (`contentType()`)
- Body Validations (`body()`, `jsonPath()`, `xmlPath()`)
- Headers (`header()`)
- Cookies (`cookie()`)

You build a `ResponseSpecification` using `RestAssured.expect().spec(specification)` or by using `ResponseSpecBuilder`.

### Advantages
- **Reusability**: Define common configurations once and reuse them.
- **Readability**: Tests become cleaner and focus on specific test logic rather than setup.
- **Maintainability**: Changes to common configurations only need to be made in one place.
- **Consistency**: Ensures all tests adhere to a consistent set of request/response standards.

## Code Implementation

Let's imagine we are testing a simple "To-Do List" API.

```java
import io.restassured.RestAssured;
import io.restassured.builder.RequestSpecBuilder;
import io.restassured.builder.ResponseSpecBuilder;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import io.restassured.specification.ResponseSpecification;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItems;

public class TodoApiSpecificationTest {

    // Declare RequestSpecification and ResponseSpecification
    private static RequestSpecification requestSpec;
    private static ResponseSpecification responseSpec;

    @BeforeAll
    public static void setup() {
        // Assume our API is running locally on port 8080
        // And we always send/receive JSON and expect a 200 OK for successful operations

        // 1. Create a RequestSpecification using RequestSpecBuilder
        requestSpec = new RequestSpecBuilder()
                .setBaseUri("http://localhost")
                .setPort(8080)
                .setBasePath("/api/v1/todos")
                .setContentType(ContentType.JSON)
                .addHeader("Accept", ContentType.JSON.toString())
                .build();

        // 2. Create a ResponseSpecification using ResponseSpecBuilder
        responseSpec = new ResponseSpecBuilder()
                .expectStatusCode(200)
                .expectContentType(ContentType.JSON)
                .build();

        // Optional: Set default specifications if you want them applied to ALL RestAssured calls
        // RestAssured.requestSpecification = requestSpec;
        // RestAssured.responseSpecification = responseSpec;
    }

    @Test
    void testGetAllTodos() {
        // Reuse the defined specifications
        given()
            .spec(requestSpec) // Apply request specification
        .when()
            .get()
        .then()
            .spec(responseSpec) // Apply response specification
            .body("size()", equalTo(2)) // Example: Assuming there are 2 todos initially
            .body("title", hasItems("Buy groceries", "Learn REST Assured"));
    }

    @Test
    void testCreateNewTodo() {
        String newTodo = "{"title": "Write API tests", "completed": false}";

        given()
            .spec(requestSpec) // Apply request specification
            .body(newTodo)
        .when()
            .post()
        .then()
            .spec(responseSpec) // Apply response specification
            .statusCode(201) // Expect 201 Created for POST
            .body("title", equalTo("Write API tests"));
    }

    @Test
    void testGetSingleTodo() {
        // We can override or add to the specification for specific tests
        given()
            .spec(requestSpec)
            .pathParam("id", "1") // Add a path parameter for this specific test
        .when()
            .get("/{id}")
        .then()
            .spec(responseSpec)
            .body("title", equalTo("Buy groceries"));
    }

    @Test
    void testDeleteTodo() {
        given()
            .spec(requestSpec)
            .pathParam("id", "3") // Assuming a todo with ID 3 exists and can be deleted
        .when()
            .delete("/{id}")
        .then()
            .spec(responseSpec)
            .statusCode(204); // Expect 204 No Content for successful DELETE
    }

    // Example of a negative test case, where we expect a different status code
    @Test
    void testGetNonExistentTodo() {
        given()
            .spec(requestSpec)
            .pathParam("id", "999") // An ID that surely doesn't exist
        .when()
            .get("/{id}")
        .then()
            .expect()
            .statusCode(404) // Override the default 200 from responseSpec
            .contentType(ContentType.JSON); // We still expect JSON content
    }
}
```

## Best Practices
- **Centralize Specifications**: Define `RequestSpecification` and `ResponseSpecification` in a dedicated utility class or a base test class (`@BeforeAll` or `@BeforeEach`) for easy access and management.
- **Layer Specifications**: Create multiple specifications for different purposes (e.g., one for authenticated requests, another for public requests, one for different API versions). You can combine them using `merge()`.
- **Use `ResponseSpecBuilder` for Complex Validations**: For validations that involve multiple checks (e.g., `body("field1", equalTo("value"))`, `body("field2", notNullValue())`), `ResponseSpecBuilder` keeps the logic organized.
- **Don't Over-specify**: Only include truly common elements in your specifications. Specific parameters or validations for a single test should remain within that test.
- **Override When Necessary**: It's perfectly fine to override or add to a specification within a specific test if it has unique requirements, as shown in `testGetSingleTodo` and `testGetNonExistentTodo`.

## Common Pitfalls
- **Overriding Global `RestAssured` Config**: While `RestAssured.requestSpecification` and `RestAssured.responseSpecification` can set global defaults, using `given().spec()` and `then().spec()` directly in tests is generally preferred for clarity and avoiding unintended global side effects, especially in complex frameworks or parallel test execution.
- **Ignoring Specific Test Needs**: Not all tests will fit a generic specification. Forgetting to override or add specific details can lead to failed tests or incomplete validation.
- **Lack of Clarity**: Creating specifications that are too broad or contain too many varying elements can make them less useful and harder to understand. Keep them focused on distinct, reusable patterns.
- **Not Handling Errors in Specifications**: A `ResponseSpecification` might typically expect a 200 OK. For negative test cases, you MUST override the status code expectation to match the expected error code (e.g., 400, 401, 404).

## Interview Questions & Answers
1.  **Q: What are Request and Response Specifications in REST Assured, and why are they useful?**
    **A:** Request and Response Specifications are objects that encapsulate common configurations for requests (like base URI, headers, authentication) and common validations for responses (like status code, content type, body assertions). They are useful because they promote reusability, reduce code duplication across tests, improve test readability by separating setup from test logic, and make test suites easier to maintain by centralizing common patterns.

2.  **Q: How do you create and use RequestSpecification and ResponseSpecification?**
    **A:** You typically create them using `RequestSpecBuilder` and `ResponseSpecBuilder`, respectively. For example:
    ```java
    RequestSpecification requestSpec = new RequestSpecBuilder()
        .setBaseUri("https://api.example.com")
        .setContentType(ContentType.JSON)
        .build();

    ResponseSpecification responseSpec = new ResponseSpecBuilder()
        .expectStatusCode(200)
        .expectContentType(ContentType.JSON)
        .build();
    ```
    You then apply them to your tests using `given().spec(requestSpec)` and `then().spec(responseSpec)`.

3.  **Q: Can you combine multiple specifications or override parts of a specification? Provide an example.**
    **A:** Yes, you can combine specifications using the `merge()` method. For example, you might have a base specification and another for authenticated requests. You can also override parts of a specification by simply adding more configurations to your `given()` or `then()` chain after applying the spec.
    ```java
    RequestSpecification baseSpec = new RequestSpecBuilder().setBaseUri("http://localhost").build();
    RequestSpecification authSpec = new RequestSpecBuilder().addHeader("Authorization", "Bearer token").build();
    RequestSpecification finalSpec = baseSpec.merge(authSpec); // Combines both

    given().spec(finalSpec).queryParam("id", "123") // Adding specific parameter
    // ...
    ```

## Hands-on Exercise
**Scenario**: You are testing a user management API.
**Task**:
1.  Create a `RequestSpecification` that sets the `baseUri` to `https://your-user-api.com/v1`, `basePath` to `/users`, and `ContentType` to `JSON`. Also, add an `Authorization` header with a dummy bearer token (e.g., `Bearer abcdef12345`).
2.  Create a `ResponseSpecification` that expects a `statusCode` of `200` and `ContentType` of `JSON`.
3.  Write a test method `testCreateUser()` that uses these specifications to send a POST request to create a new user. The response should assert the `name` of the created user in the response body.
4.  Write another test method `testGetUserById()` that uses the same `RequestSpecification`, but overrides the `basePath` to include a specific user ID (`/users/{id}`) and validates the response using the `ResponseSpecification`. Ensure you use a path parameter.
5.  Implement a negative test case `testCreateUserWithInvalidData()` that uses the `RequestSpecification` but expects a `statusCode` of `400` for a malformed request body.

## Additional Resources
-   **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Baeldung Tutorial on REST Assured Specifications**: [https://www.baeldung.com/rest-assured-specifications](https://www.baeldung.com/rest-assured-specifications)
-   **RestAssured API Docs - RequestSpecBuilder**: [https://javadoc.io/doc/io.rest-assured/rest-assured/latest/io/restassured/builder/RequestSpecBuilder.html](https://javadoc.io/doc/io.rest-assured/rest-assured/latest/io/restassured/builder/RequestSpecBuilder.html)
-   **RestAssured API Docs - ResponseSpecBuilder**: [https://javadoc.io/doc/io.rest-assured/rest-assured/latest/io/restassured/builder/ResponseSpecBuilder.html](https://javadoc.io/doc/io.rest-assured/rest-assured/latest/io/restassured/builder/ResponseSpecBuilder.html)
