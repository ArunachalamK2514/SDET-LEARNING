# WireMock for API Mocking

## Overview
In modern software development, especially within microservices architectures and during the testing phase, external API dependencies can be a bottleneck. These dependencies might be unstable, slow, rate-limited, or simply not yet implemented. Mocking API responses allows developers and SDETs to isolate the system under test (SUT) from these external factors, enabling faster, more reliable, and consistent testing. WireMock is a powerful, flexible, and developer-friendly tool for HTTP-based API mocking. It acts as a configurable HTTP server that can return specific responses to specific requests.

This document covers how to set up WireMock, stub API endpoints to return predefined responses, and test application logic against these stubbed responses using a Java and REST Assured example.

## Detailed Explanation

WireMock provides a versatile solution for simulating HTTP APIs. It can be used as a standalone process (running as a proxy or a separate server) or integrated into a JUnit test as a library. For SDETs, integrating it within JUnit tests is often the most convenient approach, as it allows dynamic stubbing and verification within the test lifecycle.

Key concepts in WireMock:
- **Stubbing:** Defining rules that map incoming HTTP requests to outgoing HTTP responses. This is the core functionality.
- **Request Matching:** WireMock can match requests based on URL, HTTP method, headers, cookies, query parameters, and request body (using various matching strategies like exact match, regex, JSONPath, XMLPath).
- **Response Definition:** Specifying the HTTP status code, headers, body, and even delays or fault injection for the stubbed response.
- **Verification:** Asserting that specific requests were made to WireMock, which is crucial for testing interactions.
- **Record/Proxy:** WireMock can also record interactions with real APIs and proxy requests.

### Setup WireMock Server (within a JUnit Test)

When used as a JUnit rule or extension, WireMock manages its lifecycle automatically.

**Maven Dependency:**
To use WireMock with JUnit 5:
```xml
<dependency>
    <groupId>com.github.tomakehurst</groupId>
    <artifactId>wiremock-jre8</artifactId>
    <version>2.35.0</version>
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
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <version>5.3.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.assertj</groupId>
    <artifactId>assertj-core</artifactId>
    <version>3.25.1</version>
    <scope>test</scope>
</dependency>
```

### Stub a Specific Endpoint to Return a Canned Response

Let's imagine we have an application that calls an external user service at `/api/users/{id}` to fetch user details. We want to mock this.

```java
import com.github.tomakehurst.wiremock.client.WireMock;
import com.github.tomakehurst.wiremock.junit5.WireMockExtension;
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.wireMockConfig;
import static org.assertj.core.api.Assertions.assertThat;

public class UserApiMockingTest {

    // Register the WireMock extension for JUnit 5
    @RegisterExtension
    static WireMockExtension wireMockExtension = WireMockExtension.newInstance()
            .options(wireMockConfig().port(8080)) // Configure WireMock to run on port 8080
            .build();

    @BeforeEach
    void setup() {
        // Base URI for REST Assured to point to the WireMock server
        RestAssured.baseURI = "http://localhost";
        RestAssured.port = 8080;
        
        // Reset WireMock before each test to ensure a clean state
        WireMock.reset();
    }

    @Test
    void shouldReturnUserDetailsWhenUserExists() {
        // 1. Stub a specific endpoint
        wireMockExtension.stubFor(get(urlEqualTo("/api/users/123"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "id": 123, "name": "John Doe", "email": "john.doe@example.com" }")));

        // 2. Test application logic against the stubbed response
        // In a real scenario, your application would make this HTTP call.
        // Here, we simulate it with REST Assured for demonstration.
        Response response = RestAssured.given()
                .when()
                .get("/api/users/123")
                .then()
                .extract().response();

        // Assertions on the received response
        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.jsonPath().getInt("id")).isEqualTo(123);
        assertThat(response.jsonPath().getString("name")).isEqualTo("John Doe");
        assertThat(response.jsonPath().getString("email")).isEqualTo("john.doe@example.com");

        // Optional: Verify that the request was made to WireMock
        wireMockExtension.verify(getRequestedFor(urlEqualTo("/api/users/123")));
    }

    @Test
    void shouldReturnNotFoundWhenUserDoesNotExist() {
        // Stub for a non-existent user
        wireMockExtension.stubFor(get(urlEqualTo("/api/users/404"))
                .willReturn(aResponse()
                        .withStatus(404)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "message": "User not found" }")));

        Response response = RestAssured.given()
                .when()
                .get("/api/users/404")
                .then()
                .extract().response();

        assertThat(response.statusCode()).isEqualTo(404);
        assertThat(response.jsonPath().getString("message")).isEqualTo("User not found");
        
        wireMockExtension.verify(getRequestedFor(urlEqualTo("/api/users/404")));
    }
    
    @Test
    void shouldHandlePostRequests() {
        // Stub a POST request with a specific request body
        wireMockExtension.stubFor(post(urlEqualTo("/api/users"))
                .withHeader("Content-Type", containing("application/json"))
                .withRequestBody(equalToJson("{ "name": "Jane Doe", "email": "jane.doe@example.com" }"))
                .willReturn(aResponse()
                        .withStatus(201)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "id": 456, "name": "Jane Doe", "email": "jane.doe@example.com" }")));

        String requestBody = "{ "name": "Jane Doe", "email": "jane.doe@example.com" }";
        Response response = RestAssured.given()
                .header("Content-Type", "application/json")
                .body(requestBody)
                .when()
                .post("/api/users")
                .then()
                .extract().response();

        assertThat(response.statusCode()).isEqualTo(201);
        assertThat(response.jsonPath().getInt("id")).isEqualTo(456);
        assertThat(response.jsonPath().getString("name")).isEqualTo("Jane Doe");
        
        wireMockExtension.verify(postRequestedFor(urlEqualTo("/api/users"))
                .withRequestBody(equalToJson(requestBody)));
    }
}
```

### Advanced Stubbing: Scenarios and State Management

WireMock can also simulate stateful behavior using scenarios, which is useful for testing workflows where API responses change based on previous interactions.

```java
import com.github.tomakehurst.wiremock.junit5.WireMockExtension;
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.wireMockConfig;
import static org.assertj.core.api.Assertions.assertThat;

public class OrderProcessingScenarioTest {

    @RegisterExtension
    static WireMockExtension wireMockExtension = WireMockExtension.newInstance()
            .options(wireMockConfig().port(8080))
            .build();

    @BeforeEach
    void setup() {
        RestAssured.baseURI = "http://localhost";
        RestAssured.port = 8080;
        wireMockExtension.resetAll(); // Reset all stubs and scenarios
    }

    @Test
    void shouldProcessOrderSuccessfullyThroughDifferentStates() {
        String ORDER_SCENARIO = "Order processing";
        String INITIAL_STATE = "Started";
        String PAYMENT_PROCESSED_STATE = "Payment Processed";
        String ORDER_SHIPPED_STATE = "Order Shipped";

        // 1. Initial order creation - returns PENDING status
        wireMockExtension.stubFor(post(urlEqualTo("/orders"))
                .inScenario(ORDER_SCENARIO)
                .whenScenarioStateIs(INITIAL_STATE)
                .willReturn(aResponse()
                        .withStatus(201)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "orderId": "ABC-123", "status": "PENDING" }"))
                .willSetStateTo(PAYMENT_PROCESSED_STATE));

        // 2. Process payment - moves to PAYMENT_PROCESSED state
        wireMockExtension.stubFor(post(urlEqualTo("/orders/ABC-123/payment"))
                .inScenario(ORDER_SCENARIO)
                .whenScenarioStateIs(PAYMENT_PROCESSED_STATE)
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "orderId": "ABC-123", "status": "PAID" }"))
                .willSetStateTo(ORDER_SHIPPED_STATE));

        // 3. Get order status after payment - returns PAID status
        wireMockExtension.stubFor(get(urlEqualTo("/orders/ABC-123"))
                .inScenario(ORDER_SCENARIO)
                .whenScenarioStateIs(ORDER_SHIPPED_STATE) // This state is actually "Order Shipped"
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "orderId": "ABC-123", "status": "SHIPPED" }")));
                        
        // 4. Get order status in initial state
        wireMockExtension.stubFor(get(urlEqualTo("/orders/ABC-123"))
                .inScenario(ORDER_SCENARIO)
                .whenScenarioStateIs(INITIAL_STATE)
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "orderId": "ABC-123", "status": "PENDING" }")));

        // -- Test Execution --

        // Create order (expect PENDING)
        Response createOrderResponse = RestAssured.given()
                .header("Content-Type", "application/json")
                .body("{ "item": "Laptop", "quantity": 1 }")
                .when()
                .post("/orders")
                .then()
                .extract().response();
        assertThat(createOrderResponse.statusCode()).isEqualTo(201);
        assertThat(createOrderResponse.jsonPath().getString("status")).isEqualTo("PENDING");
        
        // Get order status (expect PENDING)
        Response getOrderInitialResponse = RestAssured.given()
                .when()
                .get("/orders/ABC-123")
                .then()
                .extract().response();
        assertThat(getOrderInitialResponse.statusCode()).isEqualTo(200);
        assertThat(getOrderInitialResponse.jsonPath().getString("status")).isEqualTo("PENDING");


        // Process payment (expect PAID)
        Response processPaymentResponse = RestAssured.given()
                .header("Content-Type", "application/json")
                .body("{ "amount": 1200.00, "currency": "USD" }")
                .when()
                .post("/orders/ABC-123/payment")
                .then()
                .extract().response();
        assertThat(processPaymentResponse.statusCode()).isEqualTo(200);
        assertThat(processPaymentResponse.jsonPath().getString("status")).isEqualTo("PAID");

        // Get order status after payment (expect SHIPPED)
        Response getOrderShippedResponse = RestAssured.given()
                .when()
                .get("/orders/ABC-123")
                .then()
                .extract().response();
        assertThat(getOrderShippedResponse.statusCode()).isEqualTo(200);
        assertThat(getOrderShippedResponse.jsonPath().getString("status")).isEqualTo("SHIPPED");

        // Verify interactions
        wireMockExtension.verify(1, postRequestedFor(urlEqualTo("/orders")));
        wireMockExtension.verify(1, postRequestedFor(urlEqualTo("/orders/ABC-123/payment")));
        wireMockExtension.verify(2, getRequestedFor(urlEqualTo("/orders/ABC-123"))); // One for initial, one for shipped
    }
}
```

## Code Implementation
The code examples above demonstrate the setup, basic stubbing, and scenario-based stubbing. Ensure you have the necessary Maven dependencies.

## Best Practices
- **Isolation:** Use WireMock to isolate the system under test from external dependencies. This ensures that your tests are fast, reliable, and deterministic.
- **Dynamic Stubbing:** Integrate WireMock directly into your test suite (e.g., as a JUnit extension) to dynamically configure stubs for each test, ensuring tests are self-contained and reproducible.
- **Clear Matchers:** Be as specific as possible with request matchers to avoid unintended stubbing conflicts. Use `urlPathEqualTo`, `urlMatching`, `header`, `queryParam`, `requestBody` as needed.
- **Realistic Responses:** Provide realistic and representative mock responses, including appropriate HTTP status codes, headers, and body content, to accurately simulate real API behavior.
- **Verification:** Use WireMock's verification capabilities (`verify` and `requestedFor`) to assert that your application made the expected calls to the external services, especially for outbound integrations.
- **Reset State:** Always reset WireMock state (`wireMockExtension.resetAll()`) before each test to prevent test interference and ensure a clean environment.

## Common Pitfalls
- **Over-mocking:** Mocking too much of an external API can lead to brittle tests that break easily if the real API changes. Focus on mocking only the interactions relevant to your test case.
- **Under-mocking:** Not mocking enough can lead to tests that are still dependent on external services, making them slow and unreliable.
- **Incorrect Matchers:** Using overly broad matchers (e.g., `anyUrl()`) or incorrect matchers can lead to unexpected stub behavior or tests passing for the wrong reasons.
- **State Management Issues:** Forgetting to reset WireMock's state between tests can lead to test contamination, where one test's stubs or scenario states affect subsequent tests.
- **Missing Dependencies:** Forgetting to include the `wiremock-jre8` dependency (or the appropriate version for your Java runtime) in your `pom.xml` or `build.gradle`.

## Interview Questions & Answers

1.  **Q:** What is API mocking, and why is it important in SDET?
    **A:** API mocking is the process of simulating the behavior of a real API by providing predefined responses to specific requests. It's crucial in SDET for several reasons:
    *   **Isolation:** Decouples tests from external dependencies, making them faster, more stable, and independent of external service availability or network issues.
    *   **Early Testing:** Enables testing of features that depend on APIs not yet implemented or under development.
    *   **Edge Case Testing:** Facilitates testing of error conditions, slow responses, and other hard-to-reproduce scenarios from real APIs.
    *   **Cost Reduction:** Avoids incurring costs associated with repeated calls to external paid APIs during testing.

2.  **Q:** When would you choose WireMock over other mocking frameworks like Mockito?
    **A:** WireMock is specifically designed for **HTTP-based API mocking**, operating at the network level. It creates a real HTTP server that listens for requests. Mockito, on the other hand, is a **code-level mocking framework** primarily used for mocking Java interfaces or classes (dependencies within your application code). You would choose WireMock when:
    *   Testing interactions with external microservices or third-party APIs.
    *   Performing integration tests where actual HTTP communication is involved, but the external service needs to be controlled.
    *   Simulating network-related issues (latency, timeouts, errors).
    You would use Mockito for mocking internal collaborators of a class under test in unit tests.

3.  **Q:** How do you handle dynamic responses (e.g., different responses based on sequential calls) with WireMock?
    **A:** WireMock supports scenarios for handling dynamic responses based on sequential calls or state changes. You define a scenario with different states, and each stub can specify `whenScenarioStateIs` (the state it should be in for the stub to apply) and `willSetStateTo` (the state to transition to after the stub is matched). This allows you to model workflows and stateful interactions with APIs.

4.  **Q:** Explain how WireMock can be used for "fault injection" during API testing.
    **A:** Fault injection is the practice of intentionally introducing errors or delays into a system to test its resilience and error-handling capabilities. WireMock facilitates fault injection by allowing you to define stub responses with:
    *   **Non-2xx status codes:** Return 404 Not Found, 500 Internal Server Error, etc.
    *   **Fixed or random delays:** Use `withFixedDelay()` or `withRandomDelay()` to simulate slow networks or overloaded services.
    *   **Malform responses:** Return invalid JSON/XML, incomplete bodies, or empty responses to test parsing robustness.
    *   **Connection close:** Simulate abrupt connection termination.

## Hands-on Exercise

**Scenario:** You are testing an e-commerce application that relies on a "Product Catalog Service" to fetch product details. This service exposes a `GET /products/{id}` endpoint.

**Task:**
1.  Set up a JUnit 5 test with WireMock.
2.  Create a stub for `GET /products/PROD-001` that returns a 200 OK status with a JSON body representing a product (e.g., `{"id": "PROD-001", "name": "Laptop", "price": 1200.00}`).
3.  Create another stub for `GET /products/PROD-999` that returns a 404 Not Found status with an appropriate error message (e.g., `{"message": "Product not found"}`).
4.  Using REST Assured, make calls to these mock endpoints and assert the responses, verifying both successful and not-found scenarios.
5.  Add verification to ensure the expected GET requests were made to WireMock.

## Additional Resources
- **WireMock Official Documentation:** [http://wiremock.org/docs/](http://wiremock.org/docs/)
- **WireMock GitHub Repository:** [https://github.com/wiremock/wiremock](https://github.com/wiremock/wiremock)
- **Baeldung - Guide to WireMock:** [https://www.baeldung.com/introduction-to-wiremock](https://www.baeldung.com/introduction-to-wiremock)
- **REST Assured Official Documentation:** [https://rest-assured.io/](https://rest-assured.io/)