# Contract Testing with Pact: Ensuring Microservice Compatibility

## Overview
Contract testing is a powerful technique for ensuring that services (microservices, APIs, etc.) can communicate with each other correctly, preventing integration issues and breaking changes in a distributed system. It focuses on the "contract" of communication between a consumer (client) and a provider (server), verifying that both adhere to the agreed-upon data formats and behaviors. This approach is particularly valuable in microservice architectures where services are developed and deployed independently.

This document will explore contract testing using Pact, a popular open-source framework, detailing its concepts, implementation, and benefits.

## Detailed Explanation

In contract testing, we define two primary roles:
-   **Consumer**: The service that makes a request to another service (the provider).
-   **Provider**: The service that receives and responds to requests from a consumer.

The core idea is that the consumer defines the expectations of the interaction with the provider. These expectations are recorded in a "Pact file," which is essentially a JSON document describing the request the consumer will make and the expected response it should receive.

The contract testing workflow typically involves these steps:

1.  **Consumer Test Generation**: The consumer service's tests are written first. During these tests, a mock provider is used. The consumer interacts with this mock, and the interactions (requests made and responses expected) are recorded into a Pact file. This file represents the consumer's "contract" with the provider.
2.  **Pact File Sharing**: The generated Pact file is then shared with the provider team. This can be done via a shared repository, a CI/CD pipeline, or a dedicated "Pact Broker."
3.  **Provider Verification**: The provider service then uses the Pact file to verify that it actually fulfills the contract defined by the consumer. This involves setting up the provider in a test environment, and Pact "replays" the requests defined in the Pact file against the real provider service. If the provider responds as expected according to the contract, the verification passes.
4.  **Preventing Breaking Changes**: If a provider makes a change that breaks the contract (e.g., changes an API endpoint, removes a required field, alters a response type), the provider's contract verification tests will fail. This failure occurs *before* deployment, alerting the provider team to a potential breaking change for their consumers, allowing them to fix it or communicate the change to consumers preemptively.

### Why is this important?
Traditional end-to-end integration tests can be flaky, slow, and hard to maintain, especially in large microservice landscapes. Contract testing provides faster feedback, isolates failures, and allows teams to develop and deploy independently with confidence, reducing the risk of integration bugs in production.

## Code Implementation (Java with Spring Boot and Pact)

Let's illustrate with a simple example: a `ProductConsumer` microservice that fetches product details from a `ProductProvider` microservice.

### `ProductProvider` Service (Simplified)

```java
// Product.java (Provider's model)
package com.example.productprovider.model;

public class Product {
    private String id;
    private String name;
    private double price;

    public Product(String id, String name, double price) {
        this.id = id;
        this.name = name;
        this.price = price;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }
}

// ProductController.java (Provider's REST endpoint)
package com.example.productprovider.controller;

import com.example.productprovider.model.Product;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ProductController {

    @GetMapping("/products/{id}")
    public Product getProductById(@PathVariable String id) {
        if ("101".equals(id)) {
            return new Product("101", "Laptop", 1200.00);
        }
        return null; // In a real app, handle not found
    }
}
```

### `ProductConsumer` Service

```java
// ProductClient.java (Consumer's client for ProductProvider)
package com.example.productconsumer.client;

import com.example.productconsumer.model.Product;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class ProductClient {

    private final String productProviderBaseUrl = "http://localhost:8080"; // Or dynamically configured
    private final RestTemplate restTemplate;

    public ProductClient(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    public Product getProduct(String id) {
        String url = productProviderBaseUrl + "/products/" + id;
        return restTemplate.getForObject(url, Product.class);
    }
}

// Product.java (Consumer's model, should match provider's)
package com.example.productconsumer.model;

public class Product {
    private String id;
    private String name;
    private double price;

    // Default constructor for Jackson deserialization
    public Product() {}

    public Product(String id, String name, double price) {
        this.id = id;
        this.name = name;
        this.price = price;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }
}
```

### Consumer-Side Test (Generates Pact File)

**Dependencies for Consumer (pom.xml):**
```xml
<!-- ... other Spring Boot dependencies ... -->
<dependency>
    <groupId>au.com.dius</groupId>
    <artifactId>pact-jvm-consumer-junit5</artifactId>
    <version>4.3.10</version> <!-- Use the latest stable version -->
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>au.com.dius</groupId>
    <artifactId>pact-jvm-consumer-java8</artifactId>
    <version>4.3.10</version>
    <scope>test</scope>
</dependency>
```

**`ProductConsumerPactTest.java`:**
```java
package com.example.productconsumer;

import au.com.dius.pact.consumer.MockServer;
import au.com.dius.pact.consumer.dsl.PactDslJsonBody;
import au.com.dius.pact.consumer.dsl.PactDslWith
        .given;
import au.com.dius.pact.consumer.junit5.PactConsumerTestExt;
import au.com.dius.pact.consumer.junit5.PactTestFor;
import au.com.dius.pact.core.model.RequestResponsePact;
import au.com.dius.pact.core.model.annotations.Pact;
import com.example.productconsumer.client.ProductClient;
import com.example.productconsumer.model.Product;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest
@ExtendWith(PactConsumerTestExt.class) // Enables Pact JUnit 5 extension
@PactTestFor(providerName = "ProductProvider", port = "8080") // Specifies the provider and mock server port
public class ProductConsumerPactTest {

    @Autowired
    private RestTemplate restTemplate; // Assuming RestTemplate is configured in your Spring Boot app

    // Define the contract for fetching a product by ID
    @Pact(consumer = "ProductConsumer")
    public RequestResponsePact getProductByIdPact(PactDslWithBuilder builder) {
        Map<String, String> headers = new HashMap<>();
        headers.put("Content-Type", "application/json");

        // Define the expected JSON body for the response
        PactDslJsonBody productBody = new PactDslJsonBody()
                .stringType("id", "101")
                .stringType("name", "Laptop")
                .numberType("price", 1200.00);

        return builder
                .given("product with ID 101 exists") // State for the provider
                .uponReceiving("a request for product 101")
                    .path("/products/101")
                    .method("GET")
                .willRespondWith()
                    .status(200)
                    .headers(headers)
                    .body(productBody)
                .toPact();
    }

    @Test
    @PactTestFor(pactMethod = "getProductByIdPact")
    void testGetProductById(MockServer mockServer) {
        // Set the base URL of the ProductClient to point to the Pact mock server
        // In a real Spring Boot app, you'd typically set this via configuration for tests.
        // For simplicity, we'll instantiate directly here.
        ProductClient productClient = new ProductClient(restTemplate) {
            @Override
            public Product getProduct(String id) {
                // Override to use the mock server's base URL
                String url = mockServer.getUrl() + "/products/" + id;
                return restTemplate.getForObject(url, Product.class);
            }
        };

        Product product = productClient.getProduct("101");

        assertNotNull(product);
        assertEquals("101", product.getId());
        assertEquals("Laptop", product.getName());
        assertEquals(1200.00, product.getPrice());
    }
}
```
Running this test will start a mock server, the consumer client will make a request to it, and a `productconsumer-productprovider.json` Pact file will be generated in `target/pacts`.

### Provider-Side Verification

**Dependencies for Provider (pom.xml):**
```xml
<!-- ... other Spring Boot dependencies ... -->
<dependency>
    <groupId>au.com.dius</groupId>
    <artifactId>pact-jvm-provider-junit5</artifactId>
    <version>4.3.10</version> <!-- Use the latest stable version -->
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>au.com.dius</groupId>
    <artifactId>pact-jvm-provider-spring</artifactId>
    <version>4.3.10</version>
    <scope>test</scope>
</dependency>
```

**`ProductProviderPactVerificationTest.java`:**
```java
package com.example.productprovider;

import au.com.dius.pact.provider.junit5.HttpTestTarget;
import au.com.dius.pact.provider.junit5.PactVerificationContext;
import au.com.dius.pact.provider.junit5.PactVerificationInvocationContextProvider;
import au.com.dius.pact.provider.junitsupport.Provider;
import au.com.dius.pact.provider.junitsupport.loader.PactFolder; // Or @PactBroker
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.TestTemplate;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort; // For Spring Boot 2.x use @LocalServerPort

@Provider("ProductProvider") // Specifies the provider name
@PactFolder("target/pacts") // Points to the folder where consumer pact files are stored
// In a real scenario, you'd use @PactBroker to fetch pacts from a Pact Broker
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ExtendWith(PactVerificationInvocationContextProvider.class)
public class ProductProviderPactVerificationTest {

    @LocalServerPort
    private int port; // Injects the random port Spring Boot starts on

    @BeforeEach
    void setup(PactVerificationContext context) {
        // Set the target for the provider verification to the running Spring Boot application
        context.setTarget(new HttpTestTarget("localhost", port));
    }

    @TestTemplate
    void pactVerificationTest(PactVerificationContext context) {
        context.verifyInteraction(); // Verifies each interaction defined in the pact file
    }
}
```
Running this test will start the `ProductProvider` Spring Boot application on a random port. Pact will then load the `productconsumer-productprovider.json` file from `target/pacts` and "replay" the consumer's defined requests against the running provider. If the provider's responses match the contract, the test passes. If the provider changes its `/products/{id}` endpoint (e.g., changes a field name, or returns a different status code), this test will fail, indicating a breaking change.

## Best Practices
-   **Consumer-Driven Contracts**: Always start by writing consumer tests to define the contract. This ensures the provider only implements what's truly needed by its consumers.
-   **Pact Broker**: Use a Pact Broker to manage and share Pact files between consumer and provider teams. It provides a central repository and helps visualize relationships between services.
-   **Clear States/Givens**: Define clear "given" states for each interaction (e.g., "product with ID 101 exists"). This helps the provider team set up appropriate data for verification.
-   **Atomic Contracts**: Keep pacts focused on specific interactions rather than trying to define the entire API in one go.
-   **Automate in CI/CD**: Integrate consumer pact generation and provider pact verification into your CI/CD pipelines to get immediate feedback on contract breaches.
-   **Semantic Versioning**: Combine contract testing with semantic versioning to manage API evolution and clearly communicate breaking changes.

## Common Pitfalls
-   **Over-specifying the Contract**: Don't be too prescriptive in the consumer tests. Only include the fields and behaviors that the consumer *actually uses*. If a field is present in the provider's response but the consumer doesn't care about it, don't include it in the Pact file. Over-specification leads to brittle tests.
-   **Forgetting to Run Provider Verification**: Generating a Pact file is only half the story. The provider *must* run the verification tests against its own service to confirm it adheres to the contract.
-   **Manual Pact File Management**: Copying Pact files manually is error-prone. Use a Pact Broker or automate file transfer in your CI/CD.
-   **Ignoring Provider States**: If the provider needs to be in a specific state (e.g., a user exists, an item is in stock) for an interaction to be valid, ensure these states are clearly defined in the consumer test's `given()` clause and handled appropriately in the provider's verification setup.
-   **Using Contract Tests for Functional Testing**: Contract tests are for integration contracts, not full functional testing of the provider's business logic. Keep them focused on input/output agreements.

## Interview Questions & Answers

1.  **Q: What is contract testing, and how does it differ from end-to-end testing?**
    **A:** Contract testing verifies that two integrating systems (consumer and provider) adhere to a shared understanding (contract) of their interaction. It tests only the communication interface. End-to-end testing, conversely, verifies an entire user flow across multiple integrated systems, including business logic and UI, from start to finish. Contract tests are faster, more stable, and provide quicker feedback on integration issues between specific services, allowing independent deployment. E2E tests are slower, more brittle, but validate the entire system's behavior from a user perspective.

2.  **Q: Explain the roles of "Consumer" and "Provider" in contract testing.**
    **A:** The **Consumer** is the client service that initiates an interaction, making a request to another service. It defines its expectations of the provider's API. The **Provider** is the server service that responds to the consumer's requests and must fulfill the contract. In contract testing, the consumer writes tests that generate a "Pact file" (the contract), and the provider then uses this Pact file to verify that its actual implementation meets those expectations.

3.  **Q: How does contract testing prevent breaking changes?**
    **A:** Contract testing prevents breaking changes by establishing an agreement between the consumer and provider. The consumer's tests define what requests it will send and what responses it expects. If the provider later modifies its API in a way that no longer matches the consumer's expectations (e.g., changes a required field, alters a response structure, or removes an endpoint), the provider's contract verification tests will fail. This failure acts as an early warning system, alerting the provider to a potential breaking change *before* it's deployed, giving them an opportunity to fix it or communicate necessary changes to their consumers.

4.  **Q: When would you choose contract testing over other testing types for microservices?**
    **A:** I would choose contract testing primarily for verifying the integration points (APIs) between microservices. It's ideal when:
    *   You need fast feedback on interface compatibility without running a full suite of slow end-to-end tests.
    *   Teams develop and deploy services independently and need assurance that their changes won't break upstream or downstream consumers/providers.
    *   You want to shift left integration defect detection to individual service teams.
    *   You want to reduce the flakiness and maintenance burden of traditional integration tests.
    It complements, rather than replaces, unit tests (for internal logic) and a smaller set of critical end-to-end tests (for critical business flows).

## Hands-on Exercise

**Scenario:** You are building a `OrderService` (Consumer) that interacts with an `InventoryService` (Provider) to check product stock.

**Task:**
1.  **Consumer Side**:
    *   Create a simple Spring Boot `OrderService`.
    *   Implement an `InventoryClient` in `OrderService` that makes an HTTP GET call to `InventoryService` to `/inventory/{productId}`.
    *   Write a consumer Pact test for `OrderService` that defines the contract for fetching inventory for a product ID (e.g., product "XYZ", quantity 10). This test should generate an `orderservice-inventoryservice.json` Pact file.
2.  **Provider Side**:
    *   Create a simple Spring Boot `InventoryService` with a `RestController` at `/inventory/{productId}` that returns dummy stock information.
    *   Implement a provider Pact verification test in `InventoryService` to verify that it adheres to the `orderservice-inventoryservice.json` Pact file generated by the consumer.
3.  **Experiment**:
    *   Modify the `InventoryService`'s response (e.g., change the field name for `quantity` to `stockAmount`) and observe the provider verification test failure.
    *   Fix the `InventoryService` to pass the provider verification.

## Additional Resources
-   **Pact Official Documentation**: [https://docs.pact.io/](https://docs.pact.io/) - The comprehensive guide for using Pact.
-   **Pact JVM GitHub Repository**: [https://github.com/pact-foundation/pact-jvm](https://github.com/pact-foundation/pact-jvm) - Source code and examples for Pact with JVM languages.
-   **Spring Cloud Contract**: [https://spring.io/projects/spring-cloud-contract](https://spring.io/projects/spring-cloud-contract) - Another popular contract testing framework, often preferred in Spring-heavy ecosystems.
-   **Martin Fowler on Contract Testing**: [https://martinfowler.com/articles/consumerDrivenContracts.html](https://martinfowler.com/articles/consumerDrivenContracts.html) - A classic article explaining the concept.
