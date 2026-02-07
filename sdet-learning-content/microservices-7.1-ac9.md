# Service Virtualization and Mocking for Microservices Testing

## Overview
In a microservices architecture, services often depend on other services, both internal and external (third-party APIs). Testing an individual microservice in isolation can be challenging due to these dependencies. Service virtualization and mocking provide solutions to this problem by simulating the behavior of dependent services. This allows developers and testers to test their services without requiring actual external services to be available, stable, or without incurring costs. This is crucial for efficient development, automated testing in CI/CD pipelines, and ensuring robust error handling.

## Detailed Explanation

**Service Virtualization** is the process of emulating the behavior of specific components in heterogeneous, complex application environments to enable more effective testing. It captures and simulates the functional and performance characteristics of dependent systems (e.g., third-party APIs, legacy systems, databases) that are unavailable, difficult to access, or costly to use for development and testing. This simulation allows for comprehensive testing of the service under development without waiting for or being constrained by these dependencies.

**Mocking** is a technique used in unit and integration testing where objects (dependencies) are replaced with simplified, controllable, and verifiable substitutes. While often used interchangeably with "service virtualization," mocking typically refers to creating substitutes within the same codebase or test harness, often for smaller units of code, whereas service virtualization focuses on simulating entire services or external systems. Tools like WireMock bridge this gap by offering a standalone server that can virtualize HTTP-based services, making it a powerful tool for both mocking external APIs and virtualizing microservices.

### Why use Service Virtualization/Mocking?
*   **Decoupling Tests**: Isolates the service under test from its dependencies, making tests faster, more reliable, and less flaky.
*   **Early Testing**: Allows testing even when dependent services are not yet developed, unstable, or inaccessible.
*   **Cost Reduction**: Avoids transaction costs associated with third-party APIs.
*   **Scenario Simulation**: Enables simulation of various scenarios, including slow responses, network errors, specific data responses, and edge cases that are hard to reproduce with real services.
*   **Performance Testing**: Can simulate specific load patterns or response times to test how the service reacts under different performance conditions.

### WireMock
WireMock is a popular tool for HTTP-based service virtualization. It acts as a mock server that can respond to HTTP requests in a programmable way. You can define expectations for incoming requests and specify corresponding responses, including status codes, headers, and body content. It can run as a standalone process, a JUnit rule, or an embedded library in your application.

## Code Implementation

This example demonstrates how to set up WireMock to simulate a Stripe API, configure response delays and error states, and run a simple test against it using Java and JUnit.

**Prerequisites**:
*   Java Development Kit (JDK) 8 or higher
*   Maven or Gradle

**1. Maven `pom.xml` dependencies**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>microservice-testing-with-wiremock</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <junit.version>5.10.0</junit.version>
        <wiremock.version>3.5.2</wiremock.version>
        <okhttp.version>4.12.0</okhttp.version>
    </properties>

    <dependencies>
        <!-- JUnit 5 -->
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>

        <!-- WireMock -->
        <dependency>
            <groupId>com.github.tomakehurst</groupId>
            <artifactId>wiremock-standalone</artifactId>
            <version>${wiremock.version}</version>
            <scope>test</scope>
        </dependency>

        <!-- HTTP Client for testing (OkHttp in this example) -->
        <dependency>
            <groupId>com.squareup.okhttp3</groupId>
            <artifactId>okhttp</artifactId>
            <version>${okhttp.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
```

**2. Example Service (Client for Stripe API)**:
Let's assume we have a simple service that interacts with the Stripe API to create a charge.

`src/main/java/com/example/PaymentService.java`
```java
package com.example;

import okhttp3.*;
import java.io.IOException;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

public class PaymentService {

    private final OkHttpClient httpClient;
    private final String stripeApiBaseUrl;

    public PaymentService(String stripeApiBaseUrl) {
        // Configure OkHttpClient with reasonable timeouts
        this.httpClient = new OkHttpClient.Builder()
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .writeTimeout(10, TimeUnit.SECONDS)
                .build();
        this.stripeApiBaseUrl = stripeApiBaseUrl;
    }

    public String createCharge(double amount, String currency, String token) throws IOException {
        String json = String.format("{"amount": %s, "currency": "%s", "source": "%s"}",
                amount, currency, token);

        RequestBody body = RequestBody.create(json, MediaType.get("application/json; charset=utf-8"));
        Request request = new Request.Builder()
                .url(stripeApiBaseUrl + "/v1/charges")
                .post(body)
                .header("Authorization", "Bearer sk_test_your_stripe_secret_key") // Use a dummy key for testing
                .header("Content-Type", "application/json")
                .build();

        try (Response response = httpClient.newCall(request).execute()) {
            if (response.isSuccessful()) {
                return Objects.requireNonNull(response.body()).string();
            } else {
                throw new IOException("Failed to create charge: " + response.code() + " - " + Objects.requireNonNull(response.body()).string());
            }
        }
    }
}
```

**3. WireMock Test Implementation**:
This test class will start a WireMock server, configure it with stubs for the Stripe API, and then test our `PaymentService` against this virtualized service.

`src/test/java/com/example/PaymentServiceTest.java`
```java
package com.example;

import com.github.tomakehurst.wiremock.junit5.WireMockRuntimeInfo;
import com.github.tomakehurst.wiremock.junit5.WireMockExtension;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;

import java.io.IOException;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.wireMockConfig;
import static org.junit.jupiter.api.Assertions.*;

public class PaymentServiceTest {

    // Register WireMockExtension to manage the WireMock server lifecycle
    @RegisterExtension
    static WireMockExtension wiremock = WireMockExtension.newInstance()
            .options(wireMockConfig().dynamicPort()) // Use a dynamic port for flexibility
            .build();

    private PaymentService paymentService;

    @BeforeEach
    void setUp(WireMockRuntimeInfo wmRuntimeInfo) {
        // Initialize PaymentService with the WireMock server's base URL
        paymentService = new PaymentService(wmRuntimeInfo.getHttpBaseUrl());
        // Reset WireMock mappings before each test to ensure test isolation
        wiremock.resetMappings();
    }

    @Test
    void shouldCreateChargeSuccessfully() throws IOException {
        // Stub the successful Stripe charge creation response
        wiremock.stubFor(post(urlEqualTo("/v1/charges"))
                .withHeader("Content-Type", equalTo("application/json"))
                .withRequestBody(containing("{"amount": 10000, "currency": "usd", "source": "tok_visa"}"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{"id": "ch_1F4sRcCgTsd8J7Q1B7S9U2X3", "amount": 10000, "currency": "usd", "status": "succeeded"}")));

        // Call the service method
        String response = paymentService.createCharge(100.00, "usd", "tok_visa");

        // Assertions
        assertNotNull(response);
        assertTrue(response.contains(""status": "succeeded""));
        // Verify that the PaymentService made the expected call to WireMock
        wiremock.verify(postRequestedFor(urlEqualTo("/v1/charges"))
                .withHeader("Authorization", equalTo("Bearer sk_test_your_stripe_secret_key")));
    }

    @Test
    void shouldHandleStripeApiError() {
        // Simulate a Stripe API error (e.g., invalid card)
        wiremock.stubFor(post(urlEqualTo("/v1/charges"))
                .withRequestBody(containing("tok_invalid"))
                .willReturn(aResponse()
                        .withStatus(400)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{"error": {"code": "card_declined", "message": "Your card was declined."}}")));

        // Call the service method and expect an IOException
        IOException exception = assertThrows(IOException.class, () -> {
            paymentService.createCharge(50.00, "usd", "tok_invalid");
        });

        // Assertions
        assertTrue(exception.getMessage().contains("400 - {"error": {"code": "card_declined", "message": "Your card was declined."}}"));
        wiremock.verify(postRequestedFor(urlEqualTo("/v1/charges")));
    }

    @Test
    void shouldHandleTimeoutFromStripe() {
        // Simulate a very slow response from Stripe (timeout)
        wiremock.stubFor(post(urlEqualTo("/v1/charges"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withFixedDelay(15000) // 15-second delay, longer than our OkHttpClient's 10-second read timeout
                        .withHeader("Content-Type", "application/json")
                        .withBody("{"id": "ch_timeout", "status": "succeeded"}")));

        // Call the service method and expect an IOException (due to timeout)
        IOException exception = assertThrows(IOException.class, () -> {
            paymentService.createCharge(200.00, "usd", "tok_visa");
        });

        // Assertions: The message might vary based on the HTTP client, but it should indicate a timeout
        assertTrue(exception.getMessage().contains("timeout") || exception.getMessage().contains("failed to connect"),
                "Expected timeout or connection failure message, but got: " + exception.getMessage());
        wiremock.verify(postRequestedFor(urlEqualTo("/v1/charges")));
    }

    @Test
    void shouldHandleTransientServiceUnavailability() {
        // Simulate a 503 Service Unavailable error
        wiremock.stubFor(post(urlEqualTo("/v1/charges"))
                .willReturn(aResponse()
                        .withStatus(503)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{"error": {"message": "Service Unavailable"}}")));

        // Call the service and expect an IOException for 503
        IOException exception = assertThrows(IOException.class, () -> {
            paymentService.createCharge(30.00, "eur", "tok_mastercard");
        });

        assertTrue(exception.getMessage().contains("503 - {"error": {"message": "Service Unavailable"}}"));
        wiremock.verify(postRequestedFor(urlEqualTo("/v1/charges")));
    }
}
```

## Best Practices
*   **Isolate Dependencies**: Always mock or virtualize external dependencies to ensure your tests are fast, reliable, and independent.
*   **Realistic Mocks**: While simplifying, ensure your mocks return realistic data and errors that mimic the actual service behavior, especially for critical paths and error scenarios.
*   **Idempotency in Tests**: Design your tests to be idempotent, meaning they can be run multiple times without affecting the outcome or relying on the state of previous tests. WireMock's `resetMappings()` helps achieve this.
*   **Version Control Mocks**: If using JSON files to define WireMock stubs, version control them alongside your application code.
*   **Performance Simulation**: Use features like `withFixedDelay` to simulate network latency or slow responses, helping to identify potential performance bottlenecks or timeout issues in your service.
*   **Clear Naming**: Name your stub mappings descriptively so it's clear what scenario each stub is simulating.
*   **Start/Stop WireMock Programmatically**: For integration tests, use WireMock's JUnit extensions or embed it in your code to manage its lifecycle automatically, ensuring it starts before tests and stops after.
*   **Avoid Over-Mocking**: Only mock what is necessary for the specific test. Over-mocking can lead to tests that are brittle and don't accurately reflect real-world interactions.

## Common Pitfalls
*   **Outdated Mocks**: Mocks can become outdated if the actual API changes and the mock definitions are not updated accordingly. This can lead to false positives (tests pass, but integration fails). Regularly synchronize mock definitions with API contracts (e.g., using OpenAPI/Swagger).
*   **Insufficient Error Simulation**: Only simulating happy paths leads to services that fail catastrophically in real-world error conditions. Thoroughly test error states, network issues, and edge cases.
*   **Hardcoding URLs/Ports**: Hardcoding mock server URLs or ports makes tests inflexible. Use dynamic ports and configure your service under test to point to the mock server's URL provided by the testing framework (e.g., WireMock's `getHttpBaseUrl()`).
*   **Complex Mock Logic**: If your mock logic becomes overly complex, it might be a sign that you are trying to virtualize too much or that the dependent service itself is too complex. Simpler mocks are easier to maintain.
*   **Testing Mocks, Not Code**: Ensure your tests are verifying the behavior of your service, not just that the mock returns what you expect. The mock should be a means to an end, not the focus of verification.

## Interview Questions & Answers

1.  **Q: What is service virtualization, and when would you use it in a microservices architecture?**
    A: Service virtualization is the process of simulating the behavior of dependent services or external systems (like third-party APIs) during development and testing. You would use it when these dependencies are unavailable, unstable, costly, or difficult to control. In microservices, it's crucial for isolating a service under test, enabling parallel development, facilitating early testing, and simulating various error conditions that are hard to reproduce in real environments.

2.  **Q: How does WireMock differ from traditional mocking frameworks like Mockito?**
    A: Mockito is a code-level mocking framework primarily used for unit testing to create mock objects for dependencies *within* the same application's codebase. It intercepts method calls. WireMock, on the other hand, is an HTTP-level mocking server. It simulates entire external HTTP services, responding to actual HTTP requests over the network. It's used for integration testing where you need to verify how your service interacts with external APIs. You can use them together: Mockito for internal component mocks, WireMock for external service virtualization.

3.  **Q: Describe how you would simulate a transient network error (e.g., a 503 status code) from a third-party API using WireMock.**
    A: To simulate a 503 error, you would use WireMock's `stubFor` method. You'd define a `post` or `get` request matching the specific endpoint of the third-party API. In the `willReturn` part, you would set the status to `503` using `withStatus(503)` and optionally include a descriptive error body using `withBody("{"error": "Service Unavailable"}")`. You can also add `withFixedDelay(someMillis)` to simulate a slow or delayed error response. Your service under test should then be configured to point to the WireMock server's URL.

4.  **Q: What are the benefits of including response delays in your mocked services?**
    A: Including response delays helps test the resilience and performance of your service. It allows you to:
    *   Verify how your service handles slow responses (e.g., does it time out gracefully?).
    *   Test asynchronous operations and retry mechanisms.
    *   Identify potential bottlenecks or UI freezes caused by blocking calls.
    *   Ensure that your timeouts and circuit breakers are configured correctly and trigger as expected under realistic latency conditions.

## Hands-on Exercise
**Scenario**: You are developing an e-commerce microservice that relies on an external shipping provider API. This API is often slow and sometimes returns "Service Unavailable" errors.

**Task**:
1.  **Set up a WireMock server**: Create a JUnit 5 test class and use the `WireMockExtension` to start a WireMock server.
2.  **Develop a `ShippingService` class**: This class should have a method `createShipment(String orderId, String address)` that makes an HTTP POST request to `/api/shipping/create` on the shipping provider's API. It should handle successful responses (HTTP 200 with a tracking ID) and error responses (HTTP 500/503).
3.  **Create WireMock stubs**:
    *   One stub for a successful shipment creation, returning a 200 OK with a JSON body containing a `trackingId`.
    *   Another stub for a "Service Unavailable" (503) error with a reasonable delay (e.g., 2-3 seconds) to simulate a transient issue.
    *   A third stub for an internal server error (500) from the shipping provider.
4.  **Write JUnit tests**:
    *   Test case for successful shipment creation.
    *   Test case verifying your `ShippingService` correctly handles and propagates the 503 "Service Unavailable" error, possibly with a retry mechanism if you implement one.
    *   Test case for handling a 500 Internal Server Error.

## Additional Resources
*   **WireMock Official Documentation**: <https://wiremock.org/docs/>
*   **Martin Fowler on Mocks Aren't Stubs**: <https://martinfowler.com/articles/mocksArentStubs.html> (Provides a deeper understanding of testing doubles)
*   **Microservices Testing Strategies**: <https://microservices.io/patterns/testing/microservice-testing.html>
*   **Baeldung Tutorial on WireMock**: <https://www.baeldung.com/introduction-to-wiremock>
