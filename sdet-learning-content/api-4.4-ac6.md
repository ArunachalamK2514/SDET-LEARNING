# API 4.4 AC6: Serialization using Jackson ObjectMapper in REST Assured

## Overview
Serialization is the process of converting an object's state into a format that can be stored or transmitted and reconstructed later. In the context of API testing with REST Assured and Java, this often means converting a Java Plain Old Java Object (POJO) into a JSON (or XML) payload to be sent in an API request body. Jackson ObjectMapper is a powerful and widely used library for this purpose, providing flexible and efficient JSON processing capabilities. REST Assured integrates seamlessly with Jackson, allowing for automatic serialization of POJOs to JSON when provided as the request body.

This section will cover how to leverage Jackson ObjectMapper for serialization within REST Assured, focusing on creating POJO instances, passing them to the request body, and verifying automatic JSON conversion.

## Detailed Explanation
When testing RESTful APIs, it's common to send complex data structures in the request body. Manually constructing JSON strings can be error-prone and difficult to maintain. POJOs, combined with a serialization library like Jackson, offer a cleaner and more robust approach.

REST Assured, by default, uses Jackson Databind (if present on the classpath) to serialize Java objects into JSON. When you provide a POJO to `body()` method of a REST Assured request, it automatically attempts to serialize that object into its JSON representation.

### How it Works:
1.  **POJO Definition**: You define a Java class (POJO) that mirrors the structure of the JSON payload you intend to send. This class typically has private fields, public getters and setters for these fields, and a no-argument constructor.
2.  **Jackson Annotations (Optional but Recommended)**: While basic serialization works out-of-the-box, Jackson annotations (e.g., `@JsonProperty`, `@JsonIgnore`, `@JsonInclude`, `@JsonFormat`) provide fine-grained control over the serialization process. For instance, `@JsonProperty("json_field_name")` allows mapping a Java field name to a different JSON field name.
3.  **Instantiation and Population**: You create an instance of your POJO and populate its fields with the desired data.
4.  **REST Assured `body()`**: You pass this populated POJO instance directly to the `body()` method of your REST Assured request.
5.  **Automatic Serialization**: REST Assured, detecting the POJO, uses Jackson to convert it into a JSON string, which then becomes the request body.

## Code Implementation
Let's assume we have an API endpoint `POST /api/users` that accepts a JSON payload to create a new user:
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "age": 30
}
```

First, define the POJO class:

```java
// src/main/java/com/example/api/payloads/User.java
package com.example.api.payloads;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

// @JsonInclude(JsonInclude.Include.NON_NULL) can be used to exclude null fields from the JSON output
public class User {

    @JsonProperty("firstName") // Maps Java field to JSON field "firstName"
    private String firstName;

    @JsonProperty("lastName") // Maps Java field to JSON field "lastName"
    private String lastName;

    private String email; // Field name matches JSON field name, so @JsonProperty is optional

    private int age;

    // No-argument constructor is essential for Jackson (for both serialization and deserialization)
    public User() {
    }

    public User(String firstName, String lastName, String email, int age) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.age = age;
    }

    // Getters and Setters
    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        return lastName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    @Override
    public String toString() {
        return "User{" +
               "firstName='" + firstName + ''' +
               ", lastName='" + lastName + ''' +
               ", email='" + email + ''' +
               ", age=" + age +
               '}';
    }
}
```

Now, the REST Assured test demonstrating serialization:

```java
// src/test/java/com/example/api/tests/UserCreationTest.java
package com.example.api.tests;

import com.example.api.payloads.User;
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

public class UserCreationTest {

    @BeforeClass
    public void setup() {
        // Set base URI for all tests in this class
        RestAssured.baseURI = "https://api.example.com"; // Replace with your actual API base URI
        // Optional: Log all requests and responses
        RestAssured.enableLoggingOfRequestAndResponseIfValidationFails();
    }

    @Test
    public void testCreateUserWithPojoSerialization() {
        // 1. Create an instance of the POJO
        User newUser = new User("Jane", "Doe", "jane.doe@example.com", 28);

        System.out.println("Attempting to create user: " + newUser);

        // 2. Pass POJO to .body(myObject) in RestAssured
        // Rest Assured automatically serializes the 'newUser' POJO to JSON using Jackson
        Response response = given()
                                .header("Content-Type", "application/json")
                                .body(newUser) // POJO passed directly
                            .when()
                                .post("/users") // Replace with your actual endpoint
                            .then()
                                .statusCode(201) // Expecting 201 Created status
                                .log().all() // Log the entire response for debugging
                                .extract().response();

        // 3. Verify it is automatically converted to JSON and processed by the API
        // We can assert on the response body to ensure the user was created correctly
        response.then()
                .body("id", notNullValue()) // Assuming the API returns an ID for the created user
                .body("firstName", equalTo(newUser.getFirstName()))
                .body("email", equalTo(newUser.getEmail()));

        System.out.println("User created successfully with ID: " + response.jsonPath().getString("id"));
    }

    @Test
    public void testCreateUserWithPartialData() {
        // Example of sending partial data, if the API supports it and Jackson handles nulls
        User partialUser = new User();
        partialUser.setFirstName("Alice");
        partialUser.setEmail("alice@example.com");

        System.out.println("Attempting to create partial user: " + partialUser);

        given()
                .header("Content-Type", "application/json")
                .body(partialUser)
        .when()
                .post("/users")
        .then()
                .statusCode(201)
                .log().all()
                .body("id", notNullValue())
                .body("firstName", equalTo(partialUser.getFirstName()))
                .body("lastName", is(emptyOrNullString())) // Assuming API sets lastName to null/empty if not provided
                .body("email", equalTo(partialUser.getEmail()));
    }
}
```

**Dependencies for `pom.xml` (Maven) or `build.gradle` (Gradle):**
To make this work, ensure you have the necessary dependencies for REST Assured and Jackson Databind.

**Maven (`pom.xml`):**
```xml
<dependencies>
    <!-- REST Assured -->
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.3.0</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>json-schema-validator</artifactId>
        <version>5.3.0</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
    <!-- Jackson Databind for JSON processing (usually pulled by RestAssured, but explicit is good) -->
    <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-databind</artifactId>
        <version>2.15.2</version> <!-- Use the latest compatible version -->
        <scope>test</scope>
    </dependency>
    <!-- TestNG (or JUnit) -->
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
    <!-- Hamcrest for assertions (usually pulled by TestNG/RestAssured, but explicit is good) -->
    <dependency>
        <groupId>org.hamcrest</groupId>
        <artifactId>hamcrest</artifactId>
        <version>2.2</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
</dependencies>
```

**Gradle (`build.gradle`):**
```gradle
dependencies {
    // REST Assured
    testImplementation 'io.rest-assured:rest-assured:5.3.0' // Use the latest version
    testImplementation 'io.rest-assured:json-schema-validator:5.3.0' // Use the latest version
    // Jackson Databind
    testImplementation 'com.fasterxml.jackson.core:jackson-databind:2.15.2' // Use the latest compatible version
    // TestNG
    testImplementation 'org.testng:testng:7.8.0' // Use the latest version
    // Hamcrest
    testImplementation 'org.hamcrest:hamcrest:2.2' // Use the latest version
}
```

## Best Practices
- **Use POJOs for Request/Response Bodies**: Always define POJOs for both request and response bodies. This makes your tests more readable, maintainable, and less prone to errors compared to building JSON strings manually.
- **Keep POJOs Simple**: POJOs should primarily contain fields, getters, setters, and a no-arg constructor. Avoid complex business logic within payload POJOs.
- **Utilize Jackson Annotations**: For complex JSON structures or when Java field names differ from JSON field names, use Jackson annotations like `@JsonProperty`, `@JsonIgnore`, `@JsonInclude`, etc., for precise control over serialization.
- **Handle Null Values**: Be mindful of how null values are serialized. `@JsonInclude(JsonInclude.Include.NON_NULL)` on a POJO or individual fields can prevent null fields from being included in the JSON payload, which is often desirable.
- **Version Control POJOs**: Treat your POJOs as part of your contract with the API. Keep them under version control and update them as the API evolves.

## Common Pitfalls
- **Missing No-Argument Constructor**: Jackson requires a no-argument constructor to both serialize and deserialize objects correctly. Forgetting this will lead to runtime errors.
- **Incorrect Getters/Setters**: Ensure that your getters and setters follow standard Java bean conventions (`getFieldName()`, `setFieldName(value)`). Jackson relies on these conventions.
- **Mismatched Field Names**: If your Java field names do not exactly match the JSON field names, Jackson might not serialize/deserialize correctly. Use `@JsonProperty` to resolve these mismatches.
- **Missing Jackson Databind Dependency**: If `jackson-databind` is not on the classpath, REST Assured won't be able to perform automatic POJO to JSON serialization, leading to errors.
- **Ignoring API Contract Changes**: As the API evolves, the structure of request/response bodies may change. Failing to update your POJOs accordingly will result in serialization/deserialization issues and test failures.

## Interview Questions & Answers
1.  **Q: Explain the concept of serialization in the context of API testing. Why is it important?**
    **A:** Serialization is the process of converting a Java object's state into a byte stream or a transferable format (like JSON or XML) for storage or transmission. In API testing, it's crucial for converting Java POJOs (representing data models) into the request body format (e.g., JSON) that the API expects. This simplifies test data management, improves readability, and makes tests more robust and maintainable compared to manual JSON string construction. It allows testers to interact with the API using strong-typed Java objects.

2.  **Q: How does REST Assured handle POJO serialization to JSON, and what role does Jackson play?**
    **A:** REST Assured leverages Jackson Databind, a popular JSON processing library, for automatic POJO serialization. When a Java object is passed to the `body()` method of a REST Assured request, REST Assured detects the object and, if Jackson is on the classpath, uses it to convert the object into its JSON representation. This happens seamlessly without explicit calls to `ObjectMapper`.

3.  **Q: What are some key Jackson annotations you might use for serialization and why?**
    **A:**
    *   `@JsonProperty("jsonFieldName")`: Used to map a Java field name to a different JSON field name. Essential when Java naming conventions (e.g., `firstName`) differ from JSON naming conventions (e.g., `first_name`).
    *   `@JsonIgnore`: Marks a field to be ignored during serialization (and deserialization). Useful for internal fields that should not be exposed in the API payload.
    *   `@JsonInclude(JsonInclude.Include.NON_NULL)`: Placed at class or field level, it instructs Jackson to exclude fields with `null` values from the JSON output. This helps in sending cleaner payloads and can be crucial when an API expects certain fields to be absent rather than null.
    *   `@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")`: Used for formatting dates, numbers, or other types during serialization into a specific string pattern.

## Hands-on Exercise
1.  **Objective**: Create a new `Product` POJO and use it to send a `POST` request to a mock API.
2.  **Steps**:
    *   Set up a mock API endpoint (e.g., using `MockServer` or `WireMock`, or a simple online mock API service like `JSONPlaceholder` or `Reqres.in` if it supports POST). Let's assume a `POST /products` endpoint that expects:
        ```json
        {
          "name": "Laptop",
          "price": 1200.00,
          "inStock": true
        }
        ```
    *   Define a `Product` POJO with fields `name`, `price`, and `inStock`. Ensure it has a no-argument constructor and appropriate getters/setters.
    *   Write a REST Assured test that:
        *   Creates an instance of the `Product` POJO.
        *   Populates its fields.
        *   Uses `given().body(productPojo).when().post("/products").then()...`
        *   Asserts the status code (e.g., 201 Created).
        *   Asserts that the response body contains the data sent, or a generated ID, confirming successful serialization and creation.

## Additional Resources
-   **Jackson GitHub**: [https://github.com/FasterXML/jackson](https://github.com/FasterXML/jackson)
-   **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Baeldung Tutorial on Jackson**: [https://www.baeldung.com/jackson](https://www.baeldung.com/jackson)
-   **POJO with REST Assured (Example)**: [https://www.toolsqa.com/rest-assured/pojo-with-rest-assured/](https://www.toolsqa.com/rest-assured/pojo-with-rest-assured/)
