# Data-Driven & Parameterized API Testing with JSON (Jackson/Gson)

## Overview
In modern test automation, especially for APIs, efficient handling of test data is crucial. Data-driven testing allows us to execute the same test logic multiple times with different sets of input data, ensuring comprehensive coverage and reducing redundancy. Parameterized testing, often achieved through data-driven approaches, involves supplying various inputs to a test method. This document focuses on leveraging JSON files as a robust source for test data and deserializing them into Plain Old Java Objects (POJOs) using popular libraries like Jackson or Gson within a Java test automation framework. This approach enhances test maintainability, readability, and scalability.

## Detailed Explanation

When performing API testing, scenarios often arise where the same API endpoint needs to be tested with varying request payloads, headers, or expected responses. Manually duplicating test methods for each data set is inefficient and prone to errors. Storing test data externally, such as in JSON files, decouples the data from the test logic, making tests more flexible and easier to update.

JSON (JavaScript Object Notation) is a lightweight, human-readable data interchange format that is widely used in web APIs. Its hierarchical structure makes it ideal for representing complex test data.

### Why JSON for Test Data?
-   **Readability**: JSON is easy for humans to read and write.
-   **Interoperability**: Widely supported across programming languages and systems.
-   **Flexibility**: Can represent complex nested data structures.
-   **Maintainability**: Data changes don't require code changes, only updates to the JSON file.

### Libraries for JSON Processing in Java
Two prominent libraries for JSON processing in Java are:
1.  **Jackson**: A powerful, high-performance JSON processor for Java. It offers a `ObjectMapper` class for seamless serialization and deserialization.
2.  **Gson**: Google's JSON library. It's often praised for its simplicity and ease of use, especially for common use cases.

Both libraries provide mechanisms to map JSON structures directly to Java objects (POJOs), making it straightforward to work with the data in a type-safe manner within your tests.

### Steps to Implement:

1.  **Create a JSON file with an array of test data objects**: This file will contain multiple test cases, each represented as a JSON object within an array.
2.  **Define POJOs**: Create Java classes that mirror the structure of your JSON objects. These POJOs will hold your test data.
3.  **Read and Deserialize JSON**: Use Jackson's `ObjectMapper` or Gson's `Gson` class to read the JSON file and convert its content into a `List` of your defined POJOs.
4.  **Iterate and Execute Tests**: Loop through the list of POJOs, extracting data for each test case and passing it to your API test methods.

## Code Implementation

Let's assume we are testing a user registration API that takes `username` and `password`.

### 1. `test_data.json`
```json
[
  {
    "username": "testuser1",
    "password": "password123",
    "expectedStatusCode": 201,
    "expectedMessage": "User registered successfully"
  },
  {
    "username": "testuser2",
    "password": "password456",
    "expectedStatusCode": 201,
    "expectedMessage": "User registered successfully"
  },
  {
    "username": "existinguser",
    "password": "somepassword",
    "expectedStatusCode": 409,
    "expectedMessage": "Username already exists"
  },
  {
    "username": "short",
    "password": "pw",
    "expectedStatusCode": 400,
    "expectedMessage": "Password too short"
  }
]
```

### 2. POJO for Test Data (`UserData.java`)
```java
// src/test/java/com/example/apitester/data/UserData.java
package com.example.apitester.data;

// Required for Jackson annotations (if used)
import com.fasterxml.jackson.annotation.JsonProperty;

public class UserData {
    private String username;
    private String password;
    private int expectedStatusCode;
    private String expectedMessage;

    // Default constructor is important for deserialization
    public UserData() {
    }

    public UserData(String username, String password, int expectedStatusCode, String expectedMessage) {
        this.username = username;
        this.password = password;
        this.expectedStatusCode = expectedStatusCode;
        this.expectedMessage = expectedMessage;
    }

    // Getters
    public String getUsername() {
        return username;
    }

    public String getPassword() {
        return password;
    }

    public int getExpectedStatusCode() {
        return expectedStatusCode;
    }

    public String getExpectedMessage() {
        return expectedMessage;
    }

    // Setters (optional, but good practice for full POJO compliance)
    public void setUsername(String username) {
        this.username = username;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public void setExpectedStatusCode(int expectedStatusCode) {
        this.expectedStatusCode = expectedStatusCode;
    }

    public void setExpectedMessage(String expectedMessage) {
        this.expectedMessage = expectedMessage;
    }

    @Override
    public String toString() {
        return "UserData{" +
               "username='" + username + ''' +
               ", password='" + password + ''' +
               ", expectedStatusCode=" + expectedStatusCode +
               ", expectedMessage='" + expectedMessage + ''' +
               '}';
    }
}
```

### 3. JSON Data Reader Utility (`JsonDataReader.java`)

#### Using Jackson
First, add Jackson dependency to your `pom.xml` (Maven) or `build.gradle` (Gradle):
```xml
<!-- Maven pom.xml -->
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.17.0</version> <!-- Use the latest version -->
</dependency>
```
or
```gradle
// Gradle build.gradle
implementation 'com.fasterxml.jackson.core:jackson-databind:2.17.0' // Use the latest version
```

```java
// src/test/java/com/example/apitester/utils/JsonDataReader.java
package com.example.apitester.utils;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.example.apitester.data.UserData;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;

public class JsonDataReader {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Reads a JSON file from the classpath and deserializes it into a List of specified POJOs.
     *
     * @param jsonFilePath The path to the JSON file (e.g., "test_data.json" or "data/users.json").
     * @return A List of UserData objects.
     * @throws IOException If the file cannot be read or deserialization fails.
     */
    public static List<UserData> readUserData(String jsonFilePath) throws IOException {
        try (InputStream is = JsonDataReader.class.getClassLoader().getResourceAsStream(jsonFilePath)) {
            if (is == null) {
                throw new IOException("JSON file not found on classpath: " + jsonFilePath);
            }
            // TypeReference is needed for deserializing generic types like List<T>
            return objectMapper.readValue(is, new TypeReference<List<UserData>>() {});
        }
    }

    // You can make this generic for any POJO type
    public static <T> List<T> readJsonArray(String jsonFilePath, Class<T> clazz) throws IOException {
        try (InputStream is = JsonDataReader.class.getClassLoader().getResourceAsStream(jsonFilePath)) {
            if (is == null) {
                throw new IOException("JSON file not found on classpath: " + jsonFilePath);
            }
            // For generic type List<T>, we need to create a TypeReference dynamically or pass a JavaType
            // A simpler approach for array of specific POJOs is to use TypeFactory
            return objectMapper.readValue(is, objectMapper.getTypeFactory().constructCollectionType(List.class, clazz));
        }
    }
}
```

#### Using Gson
First, add Gson dependency to your `pom.xml` (Maven) or `build.gradle` (Gradle):
```xml
<!-- Maven pom.xml -->
<dependency>
    <groupId>com.google.code.gson</groupId>
    <artifactId>gson</artifactId>
    <version>2.10.1</version> <!-- Use the latest version -->
</dependency>
```
or
```gradle
// Gradle build.gradle
implementation 'com.google.code.gson:gson:2.10.1' // Use the latest version
```

```java
// src/test/java/com/example/apitester/utils/GsonDataReader.java
package com.example.apitester.utils;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.example.apitester.data.UserData;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.reflect.Type;
import java.util.List;

public class GsonDataReader {

    private static final Gson gson = new Gson();

    /**
     * Reads a JSON file from the classpath and deserializes it into a List of specified POJOs using Gson.
     *
     * @param jsonFilePath The path to the JSON file (e.g., "test_data.json" or "data/users.json").
     * @return A List of UserData objects.
     * @throws IOException If the file cannot be read or deserialization fails.
     */
    public static List<UserData> readUserData(String jsonFilePath) throws IOException {
        try (InputStream is = GsonDataReader.class.getClassLoader().getResourceAsStream(jsonFilePath);
             InputStreamReader reader = new InputStreamReader(is)) {
            if (is == null) {
                throw new IOException("JSON file not found on classpath: " + jsonFilePath);
            }
            // TypeToken is needed for deserializing generic types like List<T>
            Type listType = new TypeToken<List<UserData>>() {}.getType();
            return gson.fromJson(reader, listType);
        }
    }

    // Generic method for reading any list of POJOs
    public static <T> List<T> readJsonArray(String jsonFilePath, Class<T> clazz) throws IOException {
        try (InputStream is = GsonDataReader.class.getClassLoader().getResourceAsStream(jsonFilePath);
             InputStreamReader reader = new InputStreamReader(is)) {
            if (is == null) {
                throw new IOException("JSON file not found on classpath: " + jsonFilePath);
            }
            Type listType = TypeToken.getParameterized(List.class, clazz).getType();
            return gson.fromJson(reader, listType);
        }
    }
}
```

### 4. API Test Class (`UserRegistrationTest.java` - using TestNG as an example)
Place `test_data.json` under `src/test/resources` so it's on the classpath.

```java
// src/test/java/com/example/apitester/tests/UserRegistrationTest.java
package com.example.apitester.tests;

import com.example.apitester.data.UserData;
import com.example.apitester.utils.JsonDataReader; // Or GsonDataReader
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.io.IOException;
import java.util.List;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertTrue;

// Assuming you have RestAssured or HttpClient for API calls
// For simplicity, we'll mock the API call in this example.
// In a real scenario, you'd use RestAssured.given().body(...).when().post(...).then()...

public class UserRegistrationTest {

    // --- Data Provider using Jackson ---
    @DataProvider(name = "userDataJackson")
    public Object[][] getUserDataJackson() throws IOException {
        List<UserData> users = JsonDataReader.readUserData("test_data.json");
        Object[][] data = new Object[users.size()][1]; // Each row has one UserData object
        for (int i = 0; i < users.size(); i++) {
            data[i][0] = users.get(i);
        }
        return data;
    }

    // --- Data Provider using Gson ---
    @DataProvider(name = "userDataGson")
    public Object[][] getUserDataGson() throws IOException {
        List<UserData> users = GsonDataReader.readUserData("test_data.json");
        Object[][] data = new Object[users.size()][1]; // Each row has one UserData object
        for (int i = 0; i < users.size(); i++) {
            data[i][0] = users.get(i);
        }
        return data;
    }

    @Test(dataProvider = "userDataJackson") // or "userDataGson"
    public void testUserRegistration(UserData userData) {
        System.out.println("Running test for user: " + userData.getUsername());

        // --- Simulate API Request and Response ---
        // In a real test, you would make an actual HTTP POST request here
        // using RestAssured or an HTTP client, sending userData.getUsername() and userData.getPassword()
        // and then receiving a response.

        // Mocking API response based on test data
        int actualStatusCode;
        String actualMessage;

        // Simple mock logic for demonstration
        if (userData.getUsername().equals("existinguser")) {
            actualStatusCode = 409;
            actualMessage = "Username already exists";
        } else if (userData.getPassword().length() < 6 && userData.getUsername().equals("short")) {
            actualStatusCode = 400;
            actualMessage = "Password too short";
        } else {
            actualStatusCode = 201;
            actualMessage = "User registered successfully";
        }

        System.out.println("Expected Status Code: " + userData.getExpectedStatusCode() + ", Actual Status Code: " + actualStatusCode);
        System.out.println("Expected Message: " + userData.getExpectedMessage() + ", Actual Message: " + actualMessage);

        // --- Assertions ---
        assertEquals(actualStatusCode, userData.getExpectedStatusCode(),
                "Status code mismatch for user: " + userData.getUsername());
        assertTrue(actualMessage.contains(userData.getExpectedMessage()),
                "Response message mismatch for user: " + userData.getUsername());

        System.out.println("Test Passed for user: " + userData.getUsername() + "
");
    }
}
```

## Best Practices
-   **Centralize Test Data**: Store all API test data in a dedicated `src/test/resources` folder, organized by feature or API endpoint.
-   **Schema Validation**: For complex JSON structures, consider using JSON Schema to validate your test data files, ensuring they conform to expected formats before tests run. This catches data errors early.
-   **Type Safety with POJOs**: Always map JSON data to POJOs. This provides compile-time checks, IDE auto-completion, and makes your test code much cleaner and less error-prone than working with raw JSON strings or maps.
-   **Error Handling**: Implement robust error handling in your data reading utilities (e.g., handling `FileNotFoundException`, `JsonParseException`).
-   **Environmental Data**: If test data varies by environment (dev, QA, prod), use environment-specific JSON files or integrate with a configuration management system.
-   **Parameterized Test Frameworks**: Integrate seamlessly with test frameworks' parameterized testing capabilities (e.g., TestNG's `@DataProvider`, JUnit 5's `@ParameterizedTest` with `MethodSource` or `JsonSource` extensions).
-   **Security**: Be cautious about what sensitive data is stored directly in JSON files, especially if repositories are public. Use secure means for handling credentials (e.g., environment variables, secret management tools).

## Common Pitfalls
-   **Missing Default Constructor**: POJOs used for deserialization *must* have a public no-argument constructor. Jackson/Gson use this to instantiate the object before populating its fields.
-   **Mismatched Field Names**: If POJO field names don't exactly match JSON keys, deserialization will fail or result in `null` values unless explicit annotations (e.g., `@JsonProperty("json_key_name")` for Jackson, `@SerializedName("json_key_name")` for Gson) are used.
-   **Incorrect Data Types**: Mismatch between JSON data types (e.g., JSON number vs. Java String) and POJO field types will lead to deserialization errors.
-   **File Not Found**: Ensure JSON data files are correctly placed on the classpath (`src/test/resources` is a common location) so `getClassLoader().getResourceAsStream()` can find them.
-   **Large JSON Files**: Reading extremely large JSON files into memory might consume significant resources. For very large datasets, consider streaming JSON parsing, though for typical test data, this is rarely an issue.
-   **Lack of Validation**: Without schema validation or careful data creation, invalid test data can lead to obscure test failures rather than clear data parsing errors.

## Interview Questions & Answers

1.  **Q: What is data-driven testing, and why is it important in API automation?**
    A: Data-driven testing is an approach where test logic is separated from test data. It's crucial in API automation because APIs often have numerous inputs and states. Instead of writing a separate test case for each combination, a single test script can be executed with various data sets, covering more scenarios efficiently. This reduces code duplication, makes tests easier to maintain, and improves test coverage by exploring a wider range of inputs, including edge cases and negative scenarios.

2.  **Q: When would you choose JSON over other data sources like Excel or CSV for API test data?**
    A: I would choose JSON for API test data primarily when the API requests/responses themselves are in JSON format, or when the test data has a complex, hierarchical structure (nested objects, arrays of objects) that is difficult to represent in a flat tabular format like Excel or CSV. JSON offers native support for such structures, making the mapping to Java POJOs straightforward and maintaining data integrity. It's also human-readable and easily shareable between developers and testers.

3.  **Q: Explain the role of POJOs in deserializing JSON test data. What happens if a POJO lacks a default constructor?**
    A: POJOs (Plain Old Java Objects) act as a schema or blueprint for your JSON data. When deserializing, libraries like Jackson or Gson map the JSON keys to the POJO's fields, converting JSON values to the corresponding Java data types. This provides type safety and allows you to work with your test data as strongly-typed Java objects rather than raw JSON strings or generic maps, making your test code cleaner and less error-prone. If a POJO lacks a public no-argument (default) constructor, deserialization will fail. Jackson/Gson need this constructor to instantiate the POJO object before they can use setters or direct field access to populate its data from the JSON.

4.  **Q: Discuss the advantages and disadvantages of using Jackson vs. Gson for JSON processing in a test automation framework.**
    A: **Jackson Advantages**: Generally considered faster and more feature-rich, offering extensive customization options through annotations and configuration. It's the de-facto standard in many Spring-based applications. **Jackson Disadvantages**: Can have a steeper learning curve due to its vast API.
    **Gson Advantages**: Simpler API, often easier to get started with for basic serialization/deserialization. Good for smaller projects or when simplicity is prioritized. **Gson Disadvantages**: Can be slightly slower than Jackson for very large or complex JSON structures. Less flexible for highly custom serialization needs.
    In a test automation framework, both are excellent choices. I would typically align with the choice made in the application under test's codebase if it's a Java application to maintain consistency. If not, I might lean towards Jackson for its performance and feature set in larger enterprise frameworks.

## Hands-on Exercise
**Scenario**: You are testing a simple "Product Catalog" API.

**Task**:
1.  **Define a Product POJO**: Create a Java class `ProductData` with fields like `id` (int), `name` (String), `price` (double), `category` (String), `available` (boolean), `expectedStatusCode` (int), and `expectedMessage` (String).
2.  **Create `products_test_data.json`**: Create a JSON file containing an array of `ProductData` objects. Include at least 4-5 test cases covering:
    *   Successful product creation (e.g., status 201)
    *   Product creation with missing mandatory fields (e.g., status 400)
    *   Product creation with an invalid price (e.g., negative price, status 400)
    *   Attempt to create a product with an existing ID (e.g., status 409)
3.  **Implement a Data Reader**: Create a utility method (e.g., `readProductData`) in your `JsonDataReader` (or `GsonDataReader`) to read `products_test_data.json` and return a `List<ProductData>`.
4.  **Write a TestNG Test**: Create a test class `ProductCatalogTest`.
    *   Implement a `@DataProvider` that uses your `readProductData` utility.
    *   Write a `@Test` method `testProductCreation` that accepts a `ProductData` object.
    *   Inside the test method, simulate an API call (as done in the `UserRegistrationTest`) and assert against `expectedStatusCode` and `expectedMessage` from the `ProductData` object.
    *   Print the details of each product being tested.

## Additional Resources
-   **Jackson GitHub**: [https://github.com/FasterXML/jackson](https://github.com/FasterXML/jackson)
-   **Gson GitHub**: [https://github.com/google/gson](https://github.com/google/gson)
-   **TestNG Data Providers**: [https://testng.org/doc/documentation-main.html#parameters-dataproviders](https://testng.org/doc/documentation-main.html#parameters-dataproviders)
-   **RestAssured (for actual API calls)**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Baeldung Tutorial on Jackson**: [https://www.baeldung.com/jackson-object-mapper-tutorial](https://www.baeldung.com/jackson-object-mapper-tutorial)
-   **Baeldung Tutorial on Gson**: [https://www.baeldung.com/java-json-gson](https://www.baeldung.com/java-json-gson)