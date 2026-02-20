# api-4.2-ac1.md

# JSON & XML Response Validation: Validate Simple JSON Responses using JsonPath Expressions

## Overview
In the realm of API testing, validating JSON responses is a fundamental task for any SDET. JsonPath provides a powerful and flexible way to navigate and extract data from JSON documents, similar to how XPath works for XML. Mastering JsonPath is crucial for efficiently asserting data correctness, especially in complex nested JSON structures. This section focuses on validating simple JSON responses using JsonPath expressions, covering scenarios like finding root values, values within lists, and filtering list items.

## Detailed Explanation

JsonPath is a query language for JSON. It allows you to select and extract specific elements from a JSON document. It's often used in conjunction with libraries like Rest Assured in Java or equivalent frameworks in other languages to assert the content of API responses.

### Basic JsonPath Syntax:

*   `$` : Represents the root element.
*   `.` : The dot notation for child operators (e.g., `$.store.book`).
*   `[]` : The bracket notation for child operators (e.g., `$['store']['book']`) or for array indices (e.g., `$.books[0]`).
*   `*` : Wildcard, matches all elements (e.g., `$.store.book[*]`).
*   `..` : Deep scan, finds all elements with a given name anywhere in the object graph (e.g., `..author`).
*   `[?()]` : Filter expressions (e.g., `$.books[?(@.price < 10)]`).
*   `[(start:end:step)]` : Array slice operator (e.g., `$.books[0:2]`).

### Use Cases:

1.  **Finding a Root Value:** Extracting a direct property of the JSON root.
2.  **Finding a Value Inside a List:** Accessing an element within a JSON array.
3.  **Filtering List Items:** Selecting elements from a list based on a specific condition.

## Code Implementation

Let's use `Rest Assured` (a popular Java library for testing REST services) to demonstrate JsonPath usage.

```java
import io.restassured.path.json.JsonPath;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import java.util.List;
import java.util.Map;

public class JsonPathValidationTests {

    // Sample JSON response for demonstration
    public static final String SAMPLE_JSON = "{
" +
            "  "store": {
" +
            "    "book": [
" +
            "      {
" +
            "        "category": "reference",
" +
            "        "author": "Nigel Rees",
" +
            "        "title": "Sayings of the Century",
" +
            "        "price": 8.95
" +
            "      },
" +
            "      {
" +
            "        "category": "fiction",
" +
            "        "author": "Evelyn Waugh",
" +
            "        "title": "Sword of Honour",
" +
            "        "price": 12.99
" +
            "      },
" +
            "      {
" +
            "        "category": "fiction",
" +
            "        "author": "Herman Melville",
" +
            "        "title": "Moby Dick",
" +
            "        "isbn": "0-553-21311-3",
" +
            "        "price": 8.99
" +
            "      },
" +
            "      {
" +
            "        "category": "fiction",
" +
            "        "author": "J.R.R. Tolkien",
" +
            "        "title": "The Lord of the Rings",
" +
            "        "isbn": "0-395-19395-8",
" +
            "        "price": 22.99
" +
            "      }
" +
            "    ],
" +
            "    "bicycle": {
" +
            "      "color": "red",
" +
            "      "price": 19.95
" +
            "    }
" +
            "  },
" +
            "  "expensive": 10
" +
            "}";

    @Test
    void testFindRootValue() {
        // Create a JsonPath object from the JSON string
        JsonPath jsonPath = new JsonPath(SAMPLE_JSON);

        // JsonPath expression to find a root value (e.g., "expensive")
        int expensiveValue = jsonPath.getInt("expensive");

        // Assert the extracted value
        assertEquals(10, expensiveValue, "Expected 'expensive' to be 10");
        System.out.println("Root value 'expensive': " + expensiveValue);
    }

    @Test
    void testFindValueInsideList() {
        JsonPath jsonPath = new JsonPath(SAMPLE_JSON);

        // JsonPath expression to find the title of the first book
        // $.store.book[0].title -> access 'store', then 'book' array, then the first element, then 'title'
        String firstBookTitle = jsonPath.getString("store.book[0].title");

        // Assert the extracted value
        assertEquals("Sayings of the Century", firstBookTitle, "Expected first book title to be 'Sayings of the Century'");
        System.out.println("Title of the first book: " + firstBookTitle);

        // Another example: price of the second book
        double secondBookPrice = jsonPath.getDouble("store.book[1].price");
        assertEquals(12.99, secondBookPrice, "Expected second book price to be 12.99");
        System.out.println("Price of the second book: " + secondBookPrice);
    }

    @Test
    void testFindAllToFilterListItems() {
        JsonPath jsonPath = new JsonPath(SAMPLE_JSON);

        // JsonPath expression to find all books with a price less than 10
        // 'store.book.findAll { it.price < 10 }' uses a GPath (Groovy Path) expression within JsonPath
        // 'it' refers to the current item in the list being iterated
        List<Map<String, Object>> cheapBooks = jsonPath.getList("store.book.findAll { it.price < 10 }");

        // Assert the number of filtered items
        assertEquals(2, cheapBooks.size(), "Expected 2 books with price less than 10");
        System.out.println("Books with price less than 10: " + cheapBooks);

        // Further assert details of the filtered items
        assertTrue(cheapBooks.stream().anyMatch(book -> "Sayings of the Century".equals(book.get("title"))),
                "Expected 'Sayings of the Century' to be in cheap books list");
        assertTrue(cheapBooks.stream().anyMatch(book -> "Moby Dick".equals(book.get("title"))),
                "Expected 'Moby Dick' to be in cheap books list");

        // Example: find authors of fiction books
        List<String> fictionAuthors = jsonPath.getList("store.book.findAll { it.category == 'fiction' }.author");
        assertEquals(3, fictionAuthors.size(), "Expected 3 fiction authors");
        assertTrue(fictionAuthors.contains("Evelyn Waugh"));
        assertTrue(fictionAuthors.contains("Herman Melville"));
        assertTrue(fictionAuthors.contains("J.R.R. Tolkien"));
        System.out.println("Authors of fiction books: " + fictionAuthors);
    }

    @Test
    void testFindBookByISBN() {
        JsonPath jsonPath = new JsonPath(SAMPLE_JSON);

        // Find a specific book by its ISBN
        Map<String, Object> mobyDick = jsonPath.getMap("store.book.find { it.isbn == '0-553-21311-3' }");

        assertEquals("Moby Dick", mobyDick.get("title"));
        assertEquals("Herman Melville", mobyDick.get("author"));
        System.out.println("Found Moby Dick: " + mobyDick);
    }
}
```

**To run this code:**

1.  **Project Setup (Maven `pom.xml`):**
    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <project xmlns="http://maven.apache.org/POM/4.0.0"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
        <modelVersion>4.0.0</modelVersion>

        <groupId>com.example</groupId>
        <artifactId>json-path-validation</artifactId>
        <version>1.0-SNAPSHOT</version>

        <properties>
            <maven.compiler.source>11</maven.compiler.source>
            <maven.compiler.target>11</maven.compiler.target>
            <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
            <rest-assured.version>5.3.0</rest-assured.version>
            <junit-jupiter.version>5.9.1</junit-jupiter.version>
        </properties>

        <dependencies>
            <!-- Rest Assured for JSONPath -->
            <dependency>
                <groupId>io.rest-assured</groupId>
                <artifactId>rest-assured</artifactId>
                <version>${rest-assured.version}</version>
                <scope>test</scope>
            </dependency>
            <dependency>
                <groupId>io.rest-assured</groupId>
                <artifactId>json-path</artifactId>
                <version>${rest-assured.version}</version>
                <scope>test</scope>
            </dependency>
            <dependency>
                <groupId>io.rest-assured</groupId>
                <artifactId>xml-path</artifactId>
                <version>${rest-assured.version}</version>
                <scope>test</scope>
            </dependency>
            <dependency>
                <groupId>io.rest-assured</groupId>
                <artifactId>json-schema-validator</artifactId>
                <version>${rest-assured.version}</version>
                <scope>test</scope>
            </dependency>

            <!-- JUnit 5 for testing -->
            <dependency>
                <groupId>org.junit.jupiter</groupId>
                <artifactId>junit-jupiter-api</artifactId>
                <version>${junit-jupiter.version}</version>
                <scope>test</scope>
            </dependency>
            <dependency>
                <groupId>org.junit.jupiter</groupId>
                <artifactId>junit-jupiter-engine</artifactId>
                <version>${junit-jupiter.version}</version>
                <scope>test</scope>
            </dependency>
        </dependencies>
    </project>
    ```
2.  **Save the Java file:** Save the above Java code as `JsonPathValidationTests.java` in `src/test/java/com/example/jsonpathvalidation/`.
3.  **Run tests:** Open your terminal in the project root and run `mvn clean test`.

## Best Practices
-   **Use Specific Paths**: Always strive to use the most specific JsonPath possible to avoid ambiguity, especially when dealing with large or complex JSON structures.
-   **Parameterize Paths**: For dynamic data, parameterize your JsonPath expressions (e.g., using variables for array indices or filter criteria).
-   **Error Handling**: Anticipate that certain paths might not exist. Implement checks (e.g., `jsonPath.get()` returning null) or use default values to prevent `PathNotFoundException` or similar errors.
-   **Readability**: Keep JsonPath expressions concise and readable. For very complex queries, consider breaking them down or adding comments to explain the logic.
-   **Combine with Schema Validation**: While JsonPath validates specific values, combine it with JSON Schema validation to ensure the overall structure and data types of the response are correct.

## Common Pitfalls
-   **Incorrect Data Types**: JsonPath extracts values as specific types (e.g., `getInt`, `getString`, `getDouble`, `getList`). Mismatching the expected type with the actual JSON value will lead to casting errors. Always verify the JSON structure.
-   **Off-by-one Errors in Arrays**: Remember that array indices in JsonPath (and most programming languages) are 0-based. `[0]` refers to the first element.
-   **Misunderstanding `.` vs `..`**: The dot operator (`.`) navigates directly to a child, while the deep scan (`..`) searches for a node anywhere in the descendant path. Overusing `..` can lead to unexpected results or performance issues on large JSONs.
-   **GPath vs JsonPath Syntax**: When using libraries like Rest Assured, be aware that some filtering and advanced operations leverage GPath (Groovy Path) syntax, which has its own nuances (e.g., `it` for current item in a closure).
-   **Whitespace and Case Sensitivity**: JsonPath expressions are generally case-sensitive for field names. Be mindful of this when constructing your paths.

## Interview Questions & Answers
1.  **Q: What is JsonPath and why is it important in API test automation?**
    **A:** JsonPath is a query language for JSON that allows you to precisely select and extract data from a JSON document. It's crucial in API test automation because it enables SDETs to validate specific data points within complex API responses without parsing the entire JSON manually. This makes tests more robust, readable, and maintainable, focusing on the data that truly matters for a given assertion.

2.  **Q: Can you give an example of when you would use `findAll` with JsonPath?**
    **A:** You would use `findAll` (or `find` for a single match) when you need to filter a list of JSON objects based on certain criteria. For instance, if an API returns a list of users, and you need to find all users whose `status` is "active" or find a specific user by their `email` address.
    Example: `$.users.findAll { it.status == 'active' }.name` to get names of all active users.

3.  **Q: How do you handle cases where a JsonPath might not exist in the response?**
    **A:** When using libraries like Rest Assured, if a JsonPath expression doesn't match any element, `jsonPath.get()` methods might return `null` or throw a `PathNotFoundException`. Best practice is to either check for `null` explicitly before performing operations on the extracted value or to use methods that allow for default values. For critical paths, a `try-catch` block around the extraction could be used to gracefully handle the absence of data, perhaps logging a warning or failing the test with a specific message.

## Hands-on Exercise
Given the following JSON response from a hypothetical e-commerce API:

```json
{
  "orderId": "ORD-12345",
  "customerInfo": {
    "name": "Alice Wonderland",
    "email": "alice@example.com"
  },
  "items": [
    {
      "productId": "P001",
      "name": "Laptop",
      "quantity": 1,
      "price": 1200.00
    },
    {
      "productId": "P005",
      "name": "Wireless Mouse",
      "quantity": 2,
      "price": 25.50
    },
    {
      "productId": "P008",
      "name": "USB-C Hub",
      "quantity": 1,
      "price": 49.99
    }
  ],
  "totalAmount": 1299.99,
  "currency": "USD"
}
```

Write Java code (using `JsonPath` from Rest Assured) to perform the following validations:
1.  Assert that the `orderId` is "ORD-12345".
2.  Assert that the customer's `email` is "alice@example.com".
3.  Find the `name` of the product with `productId` "P005" and assert it is "Wireless Mouse".
4.  Find all items where the `quantity` is greater than 1 and assert that only "Wireless Mouse" is returned.

## Additional Resources
-   **JsonPath GitHub**: [https://github.com/json-path/JsonPath](https://github.com/json-path/JsonPath) (Official documentation for the JsonPath syntax)
-   **Rest Assured JsonPath Documentation**: [https://rest-assured.io/docs/json-and-xml-path/](https://rest-assured.io/docs/json-and-xml-path/) (Specific to how JsonPath is used within Rest Assured)
-   **Online JsonPath Evaluator**: [http://jsonpath.com/](http://jsonpath.com/) (Great for testing your JsonPath expressions interactively)
---
# api-4.2-ac2.md

# JSON & XML Response Validation: Extract and Validate Nested JSON

## Overview
This module focuses on advanced techniques for validating JSON responses, specifically addressing scenarios involving deeply nested objects and arrays. As API responses become more complex, the ability to accurately extract specific elements and assert their properties, such as value, type, and array size, becomes crucial for robust test automation. We will leverage `JsonPath` for efficient traversal and validation.

## Detailed Explanation
In modern microservices architectures, API responses often contain intricate JSON structures with multiple levels of nesting and arrays. Manually parsing these responses can be error-prone and inefficient. `JsonPath` provides a powerful and flexible way to query JSON documents, similar to how XPath queries XML documents.

**Key `JsonPath` Concepts:**
*   `$` : Represents the root object/array.
*   `.` : Dot notation for child operators (e.g., `$.store.book`).
*   `[]` : Bracket notation for child operators, especially useful for keys with special characters or array indices (e.g., `$.store.book[0]`).
*   `[*]` : Wildcard for all elements in an array.
*   `..` : Deep scan operator to find a property anywhere in the JSON (e.g., `$..author`).
*   `[?(expression)]` : Filter expression for arrays (e.g., `$.store.book[?(@.price < 10)]`).

**Scenario 1: Traversing Deep Nesting**
Consider a JSON structure representing a bookstore:
```json
{
  "store": {
    "book": [
      {
        "category": "reference",
        "author": "Nigel Rees",
        "title": "Sayings of the Century",
        "price": 8.95
      },
      {
        "category": "fiction",
        "author": "Evelyn Waugh",
        "title": "Sword of Honour",
        "price": 12.99
      },
      {
        "category": "fiction",
        "author": "Herman Melville",
        "title": "Moby Dick",
        "isbn": "0-553-21311-3",
        "price": 8.99
      }
    ],
    "bicycle": {
      "color": "red",
      "price": 19.95
    }
  }
}
```
To get the author of the first book, we would use `$.store.book[0].author`.

**Scenario 2: Validating Size of a Nested Array**
To validate the number of books in the store, we can use `$.store.book.length()`.

**Scenario 3: Verifying Presence of a Key within a Nested Object**
To check if the third book has an ISBN, we can query for `$.store.book[2].isbn`. If the result is not null, the key is present. Alternatively, we can check if the list of keys contains 'isbn'.

## Code Implementation
Using REST Assured with JsonPath. First, ensure you have the necessary dependencies in your `pom.xml` (for Maven) or `build.gradle` (for Gradle):
```xml
<!-- Maven -->
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <version>5.3.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>json-path</artifactId>
    <version>5.3.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>7.8.0</version>
    <scope>test</scope>
</dependency>
```

```java
import io.restassured.path.json.JsonPath;
import io.restassured.response.Response;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.List;
import java.util.Map;

import static io.restassured.RestAssured.given;

public class JsonValidationTests {

    private String getSampleJsonPayload() {
        return "{" +
                "  "store": {" +
                "    "book": [" +
                "      {" +
                "        "category": "reference"," +
                "        "author": "Nigel Rees"," +
                "        "title": "Sayings of the Century"," +
                "        "price": 8.95" +
                "      }," +
                "      {" +
                "        "category": "fiction"," +
                "        "author": "Evelyn Waugh"," +
                "        "title": "Sword of Honour"," +
                "        "price": 12.99" +
                "      }," +
                "      {" +
                "        "category": "fiction"," +
                "        "author": "Herman Melville"," +
                "        "title": "Moby Dick"," +
                "        "isbn": "0-553-21311-3"," +
                "        "price": 8.99" +
                "      }" +
                "    ]," +
                "    "bicycle": {" +
                "      "color": "red"," +
                "      "price": 19.95" +
                "    }" +
                "  }" +
                "}";
    }

    @Test(description = "Verify extraction and validation of a deeply nested JSON object field")
    public void testDeeplyNestedJsonExtraction() {
        // Assume this is a response from an API call
        // Response response = given().when().get("/api/books");
        String jsonString = getSampleJsonPayload();
        JsonPath jsonPath = new JsonPath(jsonString);

        // Traverse deep nesting: store.book[0].author
        String firstBookAuthor = jsonPath.getString("store.book[0].author");
        System.out.println("First book author: " + firstBookAuthor);
        Assert.assertEquals(firstBookAuthor, "Nigel Rees", "Author of the first book is incorrect");

        // Extract a nested object and then its properties
        Map<String, Object> firstBook = jsonPath.getMap("store.book[0]");
        System.out.println("First book details: " + firstBook);
        Assert.assertEquals(firstBook.get("title"), "Sayings of the Century", "Title of the first book is incorrect");
    }

    @Test(description = "Validate the size of a nested JSON array")
    public void testNestedJsonArraySizeValidation() {
        String jsonString = getSampleJsonPayload();
        JsonPath jsonPath = new JsonPath(jsonString);

        // Validate size of a nested array: store.book
        List<Map<String, Object>> books = jsonPath.getList("store.book");
        System.out.println("Number of books: " + books.size());
        Assert.assertEquals(books.size(), 3, "Incorrect number of books in the store");

        // Direct JsonPath way to get size
        int numberOfBooks = jsonPath.getInt("store.book.size()");
        System.out.println("Number of books (using size() method): " + numberOfBooks);
        Assert.assertEquals(numberOfBooks, 3, "Incorrect number of books using size() method");
    }

    @Test(description = "Verify the presence of a key within a nested JSON object")
    public void testPresenceOfKeyInNestedObject() {
        String jsonString = getSampleJsonPayload();
        JsonPath jsonPath = new Path(jsonString);

        // Verify presence of a key within a nested object: isbn for the third book
        // Method 1: Get the value and check for null
        String isbnForThirdBook = jsonPath.getString("store.book[2].isbn");
        System.out.println("ISBN for third book: " + isbnForThirdBook);
        Assert.assertNotNull(isbnForThirdBook, "ISBN should be present for the third book");
        Assert.assertEquals(isbnForThirdBook, "0-553-21311-3");

        // Method 2: Check if the key exists in the map
        Map<String, Object> thirdBook = jsonPath.getMap("store.book[2]");
        Assert.assertTrue(thirdBook.containsKey("isbn"), "Third book should contain 'isbn' key");

        // Example of a key that does not exist
        String nonExistentKey = jsonPath.getString("store.book[0].isbn");
        System.out.println("ISBN for first book (non-existent): " + nonExistentKey);
        Assert.assertNull(nonExistentKey, "ISBN should not be present for the first book");
    }
}
```

## Best Practices
- **Use `JsonPath`:** For complex JSON structures, `JsonPath` is superior to manual parsing or string manipulation due to its readability and robustness.
- **Isolate Test Data:** Store large JSON payloads in separate files or dedicated methods to keep tests clean and readable.
- **Parametrize Tests:** If validating similar structures across multiple endpoints or with varying data, use data providers (TestNG) or parameterized tests (JUnit) to reduce code duplication.
- **Assertions:** Use appropriate assertion libraries (e.g., TestNG's `Assert`, Hamcrest matchers) for clear and descriptive failure messages.
- **Error Handling:** Anticipate scenarios where a path might not exist and handle them gracefully (e.g., `jsonPath.get()` might return `null` if a path is not found).

## Common Pitfalls
- **Incorrect `JsonPath` Syntax:** A common mistake is typos or incorrect usage of dot/bracket notation, especially with array filters or special characters. Always validate your `JsonPath` expressions.
- **NullPointerExceptions:** If a part of the path does not exist, `JsonPath.get()` might return `null`. Attempting to call methods on a `null` object will lead to `NullPointerException`. Always check for `null` or use methods that handle missing paths gracefully (e.g., `jsonPath.getString(path)` returning `null`).
- **Overly Specific Paths:** Relying on absolute array indices too much (e.g., `book[0]`) can make tests brittle if the order of elements changes. Use filters `[?()]` when possible to select elements based on their properties rather than position.
- **Ignoring Schema Changes:** Even with robust `JsonPath` expressions, changes in the API's JSON schema can break tests. Implement schema validation alongside content validation for comprehensive checks.

## Interview Questions & Answers
1.  **Q: How do you handle validation of deeply nested JSON structures in your automation framework?**
    A: I typically use libraries like `JsonPath` (with REST Assured for Java, or similar in other languages) to navigate and extract data from deeply nested JSONs. `JsonPath` allows me to use expressive queries to pinpoint specific elements, whether they are objects, arrays, or primitive values, and then apply assertions on them. This avoids verbose and brittle manual parsing.

2.  **Q: Describe how you would validate the presence of a specific key within an object inside a JSON array, without knowing its exact index.**
    A: I would use `JsonPath` with a filter expression. For example, to find a book with a specific title and then check for its ISBN, I could use `$.store.book[?(@.title == 'Moby Dick')].isbn`. This retrieves the ISBN only for the book matching the title, effectively verifying the key's presence within that specific object in the array, regardless of its position.

3.  **Q: What are the challenges of validating dynamic JSON array sizes, and how do you address them?**
    A: The main challenge is that array sizes can vary based on test data or system state. I address this by using `JsonPath`'s `size()` method (e.g., `$.items.size()`) to get the actual count and then asserting against an expected range or a minimum/maximum value rather than a fixed number. For example, `Assert.assertTrue(jsonPath.getInt("$.items.size()") > 0);` to ensure the array is not empty.

## Hands-on Exercise
Given the following JSON response:
```json
{
  "products": [
    {
      "id": "prod_1",
      "name": "Laptop",
      "details": {
        "brand": "Dell",
        "specs": ["8GB RAM", "256GB SSD"],
        "warranty": "1 year"
      },
      "price": 1200.00
    },
    {
      "id": "prod_2",
      "name": "Mouse",
      "details": {
        "brand": "Logitech",
        "specs": ["Wireless", "Ergonomic"],
        "warranty": "6 months"
      },
      "price": 25.50
    }
  ]
}
```
Write TestNG tests using REST Assured's `JsonPath` to:
1.  Extract and verify the brand of the second product (`Mouse`).
2.  Validate that the `specs` array for the `Laptop` product contains exactly two items.
3.  Verify that the `warranty` key is present for all products.

## Additional Resources
-   [JsonPath GitHub Repository](https://github.com/json-path/JsonPath)
-   [REST Assured Official Documentation](https://rest-assured.io/docs/json-and-xml-validation/)
-   [JsonPath Online Evaluator](https://jsonpath.com/)
---
# api-4.2-ac3.md

# JSON Schema Validation with `json-schema-validator` in REST Assured

## Overview
In the world of API testing, merely checking HTTP status codes or individual field values is often insufficient. Ensuring the structural integrity and data types of JSON responses against a predefined contract is crucial for robust test automation. JSON Schema provides a powerful way to describe the structure of JSON data, and `json-schema-validator` (often used with REST Assured) allows us to validate API responses against these schemas effortlessly. This capability is vital for maintaining API consistency, catching unexpected changes, and preventing issues early in the development cycle.

## Detailed Explanation
JSON Schema is a vocabulary that allows you to annotate and validate JSON documents. It's like a blueprint for your JSON data, defining what properties are expected, their data types, whether they are optional or required, and even their formats or patterns.

When testing APIs, particularly RESTful services that return JSON, validating against a schema provides a higher level of confidence than simply asserting on a few fields. It helps ensure:
1.  **Structural Consistency**: The response always adheres to the expected layout.
2.  **Data Type Integrity**: Each field contains data of the correct type (e.g., an `id` is an integer, a `name` is a string).
3.  **Completeness**: All required fields are present.
4.  **Early Bug Detection**: Catches unexpected changes in the API response structure that might break client applications.

The `json-schema-validator` library integrates seamlessly with REST Assured, allowing you to perform schema validation with a single line of code using `matchesJsonSchemaInClasspath`. This method expects the JSON Schema file to be available in the classpath of your test project.

**Steps to implement JSON Schema validation:**
1.  **Generate JSON Schema**: Obtain or create a JSON Schema file (`.json` extension) that represents the expected structure of your API response. Tools like JSON Schema Generator or online validators can help generate schemas from sample JSON responses.
2.  **Add Dependency**: Include the `json-schema-validator` dependency in your project's `pom.xml` (for Maven) or `build.gradle` (for Gradle).
3.  **Place Schema in Classpath**: Put the generated JSON Schema file(s) in a location that's part of your project's classpath (e.g., `src/test/resources/schemas/`).
4.  **Implement Validation**: Use `body(matchesJsonSchemaInClasspath("path/to/your/schema.json"))` in your REST Assured test.

## Code Implementation

Let's assume we have an API endpoint `/users/{id}` that returns a JSON response like this:
```json
{
  "id": 1,
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "age": 30,
  "isActive": true
}
```

First, let's create a JSON Schema for this response. Save this as `user_schema.json` in `src/test/resources/schemas/`:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "User",
  "description": "Schema for a user object",
  "type": "object",
  "required": [
    "id",
    "firstName",
    "lastName",
    "email",
    "age",
    "isActive"
  ],
  "properties": {
    "id": {
      "type": "integer",
      "description": "Unique identifier for the user"
    },
    "firstName": {
      "type": "string",
      "description": "First name of the user"
    },
    "lastName": {
      "type": "string",
      "description": "Last name of the user"
    },
    "email": {
      "type": "string",
      "format": "email",
      "description": "Email address of the user"
    },
    "age": {
      "type": "integer",
      "minimum": 0,
      "description": "Age of the user"
    },
    "isActive": {
      "type": "boolean",
      "description": "Whether the user account is active"
    }
  },
  "additionalProperties": false
}
```

Now, add the `json-schema-validator` dependency to your `pom.xml`:

```xml
<!-- pom.xml snippet -->
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>json-schema-validator</artifactId>
    <version>5.3.0</version> <!-- Use the latest version -->
    <scope>test</scope>
</dependency>
```

Finally, here's the REST Assured test code:

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchemaInClasspath;
import static org.hamcrest.Matchers.equalTo;

public class UserApiSchemaValidationTest {

    private static final String BASE_URI = "http://localhost:8080"; // Replace with your actual API base URI

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URI;
        // You might want to start a mock server for reliable testing
        // or ensure your API is running.
        // For demonstration, let's assume a mock server is running or API is accessible.
    }

    @Test
    public void testGetUserByIdAndValidateSchema() {
        int userId = 1;

        // Mock API response for demonstration purposes if a live API is not available
        // In a real scenario, this would be an actual API call.
        // For this example, we're assuming a real API call would return the JSON above.
        // If you're running a mock server (e.g., WireMock), configure it to return the sample JSON.

        // Example of a basic GET request with schema validation
        given()
            .pathParam("id", userId)
            .when()
            .get("/users/{id}")
            .then()
            .log().all() // Log all response details for debugging
            .statusCode(200) // Assert HTTP status code
            .contentType(ContentType.JSON) // Assert content type
            .body("id", equalTo(userId)) // Basic field assertion (optional, but good practice)
            .body(matchesJsonSchemaInClasspath("schemas/user_schema.json")); // Validate against JSON Schema
    }

    @Test
    public void testCreateUserAndValidateSchema() {
        String requestBody = "{
" +
                             "  "firstName": "Jane",
" +
                             "  "lastName": "Smith",
" +
                             "  "email": "jane.smith@example.com",
" +
                             "  "age": 28,
" +
                             "  "isActive": false
" +
                             "}";

        // This test would typically validate the response after a POST request
        // For schema validation, the response body would be validated.
        given()
            .contentType(ContentType.JSON)
            .body(requestBody)
            .when()
            .post("/users")
            .then()
            .log().all()
            .statusCode(201) // Assuming 201 Created for successful creation
            .body(matchesJsonSchemaInClasspath("schemas/user_schema.json")); // Validate the response of the created user
    }
}
```

## Best Practices
-   **Keep Schemas Versioned**: Treat your JSON Schemas as part of your API contract. Version them along with your API to ensure tests remain relevant.
-   **Granular Schemas**: For complex APIs, break down large schemas into smaller, reusable components using `$ref`. This improves readability and maintainability.
-   **Automate Schema Generation**: If your API is documented (e.g., OpenAPI/Swagger), consider automating JSON Schema generation from your API specification.
-   **`additionalProperties: false`**: Use `additionalProperties: false` in your schema to strictly disallow any properties not explicitly defined. This helps catch unexpected fields in the response.
-   **Early Integration**: Integrate schema validation early in the development lifecycle to catch API contract deviations as soon as they occur.
-   **Mock Servers**: Use mock servers (like WireMock) to provide stable and predictable responses for schema validation tests, isolating them from actual backend volatility.

## Common Pitfalls
-   **Outdated Schemas**: Schemas can quickly become outdated if the API evolves without corresponding schema updates. This leads to false positives (tests pass but API is broken) or false negatives (tests fail but API is actually correct).
    *   **How to Avoid**: Implement a robust API documentation and schema management strategy. Integrate schema generation/update into CI/CD if possible, or establish clear communication channels between API developers and testers.
-   **Incorrect Classpath**: The `matchesJsonSchemaInClasspath` method relies on the schema file being correctly placed in the test classpath. A common mistake is placing it in the wrong directory or having a typo in the path.
    *   **How to Avoid**: Always verify the path. The standard location is `src/test/resources/`. Ensure the path in the test method matches the relative path from `src/test/resources/` (e.g., `schemas/user_schema.json`).
-   **Overly Permissive Schemas**: If a schema is too lenient (e.g., allows `additionalProperties: true` everywhere, or doesn't specify required fields), it might not catch breaking changes effectively.
    *   **How to Avoid**: Be as strict as possible with your schemas. Define all expected properties, their types, and use `required` and `additionalProperties: false` where appropriate.
-   **Schema Complexity**: Overly complex or deeply nested schemas can be hard to read and maintain.
    *   **How to Avoid**: Use `$ref` to break down schemas into modular parts. Keep individual schema files focused on a single entity or object.

## Interview Questions & Answers
1.  **Q: Why is JSON Schema validation important in API test automation?**
    **A:** JSON Schema validation is critical because it verifies the contract between the API producer and consumer. It ensures that the API response adheres to a predefined structure, data types, and required fields. This helps in catching breaking changes early, preventing client-side issues, improving API reliability, and providing a higher level of confidence in the API's stability beyond just functional correctness.

2.  **Q: How do you integrate JSON Schema validation with REST Assured?**
    **A:** Integration with REST Assured is straightforward. First, add the `json-schema-validator` dependency. Then, place your JSON Schema files in the `src/test/resources` directory (or a subdirectory within it) to make them available in the classpath. Finally, in your REST Assured test, use the `body(matchesJsonSchemaInClasspath("path/to/your/schema.json"))` assertion method as part of your `.then()` block.

3.  **Q: What are the common challenges with JSON Schema validation and how do you address them?**
    **A:** Common challenges include maintaining up-to-date schemas as APIs evolve, correctly placing schema files in the classpath, and writing schemas that are sufficiently strict without being overly brittle. I address these by:
    *   **Schema Maintenance**: Establishing a process for schema updates alongside API changes, potentially integrating schema generation/validation into CI/CD pipelines.
    *   **Classpath Issues**: Double-checking file paths and ensuring schemas are in `src/test/resources`.
    *   **Strictness vs. Brittleness**: Using `additionalProperties: false` and `required` fields for strict validation, but also leveraging `$ref` for modularity to manage complexity and reduce brittleness when minor, non-breaking changes occur in sub-objects.

## Hands-on Exercise
**Scenario**: You are testing a simple "Product Catalog" API.
**Endpoint**: `GET /products/{id}`
**Sample Response**:
```json
{
  "productId": "PROD001",
  "name": "Laptop Pro",
  "description": "High-performance laptop for professionals",
  "price": 1299.99,
  "inStock": true,
  "categories": ["Electronics", "Computers"]
}
```
**Task**:
1.  Create a JSON Schema file (`product_schema.json`) for the above response, ensuring `productId`, `name`, `price`, and `inStock` are required. `price` should be a number with a minimum value of 0. `categories` should be an array of strings.
2.  Place the schema file in `src/test/resources/schemas/`.
3.  Write a REST Assured test that makes a `GET` request to `/products/{id}` (you can mock the response or use a real API if available) and validates the response against your `product_schema.json`.

## Additional Resources
-   **JSON Schema Official Website**: [https://json-schema.org/](https://json-schema.org/) - Comprehensive documentation on JSON Schema.
-   **REST Assured JSON Schema Validation Guide**: [https://github.com/rest-assured/json-schema-validator](https://github.com/rest-assured/json-schema-validator) - Official GitHub repository and usage examples.
-   **Online JSON to JSON Schema Converter**: [https://jsonschema.net/](https://jsonschema.net/) - A helpful tool to generate schemas from sample JSON.
-   **Baeldung Tutorial on REST Assured JSON Schema Validation**: [https://www.baeldung.com/rest-assured-json-schema](https://www.baeldung.com/rest-assured-json-schema) - Another good tutorial with practical examples.
---
# api-4.2-ac4.md

# XML Response Validation with XmlPath

## Overview
In modern software development, APIs often communicate using various data formats, including XML. As an SDET, ensuring the correctness and integrity of these XML responses is crucial for the reliability of the system under test. Rest Assured's `XmlPath` is a powerful and flexible tool specifically designed for parsing, navigating, and asserting against XML responses in Java. It allows you to traverse XML structures using XPath expressions, making validation straightforward and robust.

This document will guide you through parsing and validating XML responses using `XmlPath`, covering its core functionalities, practical examples, best practices, and common interview questions.

## Detailed Explanation

`XmlPath` in Rest Assured provides a fluent API to extract data from XML documents using GPath (similar to Groovy's GPath) or traditional XPath. It automatically handles the parsing of XML response bodies, allowing you to focus on the data extraction and validation logic.

### Key `XmlPath` functionalities:

1.  **Instantiation**: `XmlPath` can be instantiated directly from an XML string, an `InputStream`, or from a Rest Assured `Response` object.
    ```java
    // From a string
    XmlPath xmlPath = new XmlPath("<book><title>Rest Assured Guide</title></book>");

    // From a Rest Assured Response
    Response response = given().when().get("/api/books");
    XmlPath xmlPathFromResponse = response.xmlPath();
    ```

2.  **Navigation**: You can navigate the XML tree using XPath-like expressions to select single nodes, lists of nodes, attributes, or text content.

    *   **Selecting text content**: `xmlPath.getString("book.title")`
    *   **Selecting attributes**: `xmlPath.getString("book.@category")`
    *   **Selecting lists of elements**: `xmlPath.getList("books.book.title", String.class)`
    *   **Filtering collections**: `xmlPath.getList("books.book.findAll { it.price < 20 }.title", String.class)`

3.  **Assertions**: Once data is extracted, you can use standard assertion libraries (like TestNG's `Assert` or JUnit's `Assertions`) to validate the content, count, or presence of elements.

### Real-world Example Scenario:
Imagine an e-commerce application with an API endpoint that returns a list of products in XML format. We need to validate that the product details (name, price, category) are correct and that specific products exist.

**Example XML Response:**
```xml
<store>
    <book category="cooking">
        <title lang="en">Everyday Italian</title>
        <author>Giada De Laurentiis</author>
        <year>2005</year>
        <price>30.00</price>
    </book>
    <book category="children">
        <title lang="en">Harry Potter</title>
        <author>J.K. Rowling</author>
        <year>2005</year>
        <price>29.99</price>
    </book>
    <book category="web">
        <title lang="en">Learning XML</title>
        <author>Erik T. Ray</author>
        <year>2003</year>
        <price>39.95</price>
    </book>
</store>
```

## Code Implementation

To demonstrate `XmlPath` in action, we'll use Rest Assured to make an API call (simulated here) and then validate its XML response.

First, ensure you have the necessary dependencies in your `pom.xml` (for Maven):

```xml
<!-- Rest Assured -->
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <version>5.3.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>xml-path</artifactId>
    <version>5.3.0</version>
    <scope>test</scope>
</dependency>
<!-- TestNG for assertions -->
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>7.8.0</version>
    <scope>test</scope>
</dependency>
```

Now, let's create a test class:

```java
import io.restassured.path.xml.XmlPath;
import io.restassured.response.Response;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.util.List;
import java.util.Map;

import static io.restassured.RestAssured.given;

public class XmlResponseValidationTest {

    // Simulate an XML response for demonstration purposes
    private String getSampleXmlResponse() {
        return "<store>
" +
               "    <book category="cooking">
" +
               "        <title lang="en">Everyday Italian</title>
" +
               "        <author>Giada De Laurentiis</author>
" +
               "        <year>2005</year>
" +
               "        <price>30.00</price>
" +
               "    </book>
" +
               "    <book category="children">
" +
               "        <title lang="en">Harry Potter</title>
" +
               "        <author>J.K. Rowling</author>
" +
               "        <year>2005</year>
" +
               "        <price>29.99</price>
" +
               "    </book>
" +
               "    <book category="web">
" +
               "        <title lang="en">Learning XML</title>
" +
               "        <author>Erik T. Ray</author>
" +
               "        <year>2003</year>
" +
               "        <price>39.95</price>
" +
               "    </book>
" +
               "</store>";
    }

    @Test(description = "Validate a specific book's title and category attribute")
    public void validateSpecificBookDetails() {
        // In a real scenario, this would be an actual API call
        // Response response = given().when().get("http://your-api.com/store/books");
        // XmlPath xmlPath = response.xmlPath();
        
        // For demonstration, use the simulated XML string
        XmlPath xmlPath = new XmlPath(getSampleXmlResponse());

        // 1. Validate text content of a specific XML tag
        String cookingBookTitle = xmlPath.getString("store.book[0].title");
        Assert.assertEquals(cookingBookTitle, "Everyday Italian", "Incorrect title for the first book.");

        // 2. Validate an attribute of an XML tag
        String cookingBookCategory = xmlPath.getString("store.book[0].@category");
        Assert.assertEquals(cookingBookCategory, "cooking", "Incorrect category for the first book.");

        // Validate details for "Learning XML" book (third book)
        String xmlBookTitle = xmlPath.getString("store.book[2].title");
        String xmlBookAuthor = xmlPath.getString("store.book[2].author");
        Double xmlBookPrice = xmlPath.getDouble("store.book[2].price");

        Assert.assertEquals(xmlBookTitle, "Learning XML", "Incorrect title for Learning XML book.");
        Assert.assertEquals(xmlBookAuthor, "Erik T. Ray", "Incorrect author for Learning XML book.");
        Assert.assertEquals(xmlBookPrice, 39.95, "Incorrect price for Learning XML book.");
    }

    @Test(description = "Validate the count of books and titles using XPath")
    public void validateBookCountAndAllTitles() {
        XmlPath xmlPath = new XmlPath(getSampleXmlResponse());

        // Get count of all book elements
        List<String> allBookTitles = xmlPath.getList("store.book.title");
        Assert.assertEquals(allBookTitles.size(), 3, "Expected 3 books but found " + allBookTitles.size());

        // Validate that specific titles are present
        Assert.assertTrue(allBookTitles.contains("Everyday Italian"), "Everyday Italian not found.");
        Assert.assertTrue(allBookTitles.contains("Harry Potter"), "Harry Potter not found.");
        Assert.assertTrue(allBookTitles.contains("Learning XML"), "Learning XML not found.");
    }

    @Test(description = "Validate elements based on conditions using GPath expressions")
    public void validateBooksWithSpecificPrice() {
        XmlPath xmlPath = new XmlPath(getSampleXmlResponse());

        // Find all books with price less than 30.00
        List<String> cheapBookTitles = xmlPath.getList("store.book.findAll { it.price < 30 }.title");
        Assert.assertEquals(cheapBookTitles.size(), 1, "Expected 1 cheap book, but found " + cheapBookTitles.size());
        Assert.assertTrue(cheapBookTitles.contains("Harry Potter"), "Harry Potter should be a cheap book.");

        // Find a specific book by title and validate its author
        String authorOfLearningXml = xmlPath.getString("store.book.find { it.title == 'Learning XML' }.author");
        Assert.assertEquals(authorOfLearningXml, "Erik T. Ray", "Author of 'Learning XML' is incorrect.");
    }

    @Test(description = "Validate root attributes or elements if present")
    public void validateRootElementDetails() {
        // Example with a root attribute if it existed, e.g., <store totalBooks="3">
        // String totalBooks = xmlPath.getString("store.@totalBooks");
        // Assert.assertEquals(totalBooks, "3");
        
        // This test mostly serves as a placeholder for demonstrating root-level validation.
        // Our sample XML doesn't have attributes on the root <store> tag.
        // We can, however, validate the presence of the root element itself.
        String storeNode = xmlPath.getString("store");
        Assert.assertNotNull(storeNode, "Store root element should be present.");
    }
}
```

## Best Practices
- **Use meaningful XPath/GPath expressions**: Keep your expressions as specific as possible to avoid ambiguity.
- **Handle potential null values**: When extracting values that might not always be present, perform null checks before making assertions to prevent `NullPointerExceptions`.
- **Parameterize XML data**: For complex XML structures or frequently changing data, consider externalizing expected values or generating XML on the fly for better maintainability.
- **Focus on business-level validation**: While structural validation is important, prioritize assertions that verify business logic correctness rather than just the presence of tags.
- **Use `given().contentType(ContentType.XML)`**: When sending requests to XML endpoints, explicitly set the content type to ensure Rest Assured sends the correct `Content-Type` header.
- **Error Handling**: Implement try-catch blocks or use `Optional` for XML elements that might not always be present, to gracefully handle their absence rather than failing the test.

## Common Pitfalls
- **Incorrect XPath syntax**: Even small errors in XPath can lead to no match or incorrect data extraction. Double-check your paths.
- **Namespace issues**: If your XML uses namespaces, `XmlPath` might require explicit configuration or qualified names in your XPath expressions. This can be complex, so understanding the XML schema is key.
- **Assuming element order**: Avoid relying on the order of elements unless it's strictly guaranteed by the API contract. Use filtering (`findAll`, `find`) for more robust selections.
- **Not handling collection types**: When extracting multiple elements, always use `getList()` and specify the expected class type (e.g., `String.class`, `Integer.class`).
- **Ignoring root element**: Remember that `XmlPath` expressions start from the root of the XML document. If your XML has a root element like `<data>`, your path should start with `data`.

## Interview Questions & Answers
1.  **Q: What is `XmlPath` in Rest Assured, and why is it useful for API testing?**
    A: `XmlPath` is a class provided by Rest Assured that allows testers to parse, navigate, and extract data from XML response bodies using GPath or XPath expressions. It's useful because it simplifies the process of interacting with XML APIs, enabling robust validation of complex XML structures, attributes, and text content without needing to manually parse the XML.

2.  **Q: How do you extract an attribute value from an XML response using `XmlPath`? Provide an example.**
    A: You can extract an attribute value by appending `@attributeName` to your XPath expression.
    Example: If you have `<book category="fiction">`, you can extract "fiction" using `xmlPath.getString("book.@category")`.

3.  **Q: Suppose an XML response contains multiple `<item>` elements. How would you validate that an item with a specific `id` exists and then assert one of its properties?**
    A: You would use GPath's `find` or `findAll` methods.
    Example: `xmlPath.getString("items.item.find { it.@id == '123' }.name")` would find the item with `id='123'` and then return its `name`. You can then assert this value.

4.  **Q: What are some challenges you might face when validating XML responses with namespaces, and how would you approach them?**
    A: Challenges include needing to register namespaces with `XmlPath` or using qualified names in XPath expressions. One approach is to remove namespaces before parsing (if acceptable and safe for the test context), or configure `XmlPath` to understand the namespaces using `XmlPath.usingNamespace(prefix, uri)`. Understanding the WSDL or XSD (XML Schema Definition) is crucial.

## Hands-on Exercise
**Scenario:** You are testing an API for a music streaming service. The API endpoint `/api/artists` returns an XML response containing a list of artists and their albums.

**XML Response Structure (simulated):**
```xml
<artists>
    <artist id="A001">
        <name>Queen</name>
        <genre>Rock</genre>
        <album releaseYear="1975">
            <title>A Night at the Opera</title>
        </album>
        <album releaseYear="1974">
            <title>Sheer Heart Attack</title>
        </album>
    </artist>
    <artist id="A002">
        <name>Adele</name>
        <genre>Pop</genre>
        <album releaseYear="2011">
            <title>21</title>
        </album>
    </artist>
</artists>
```

**Task:**
1.  Write a TestNG test that simulates receiving the above XML response.
2.  Validate that there are exactly two artists in the response.
3.  Assert that the artist with `id="A001"` has the name "Queen" and genre "Rock".
4.  Verify that "A Night at the Opera" is an album by "Queen" and its `releaseYear` is "1975".
5.  Validate that "Adele" has an album titled "21".

## Additional Resources
-   **Rest Assured XmlPath Documentation**: [https://www.javadoc.io/doc/io.rest-assured/xml-path/latest/io/restassured/path/xml/XmlPath.html](https://www.javadoc.io/doc/io.rest-assured/xml-path/latest/io/restassured/path/xml/XmlPath.html)
-   **XPath Tutorial (W3Schools)**: [https://www.w3schools.com/xml/xpath_intro.asp](https://www.w3schools.com/xml/xpath_intro.asp)
-   **Rest Assured Official Site**: [https://rest-assured.io/](https://rest-assured.io/)
---
# api-4.2-ac5.md

# JSON Response Validation with Hamcrest Matchers

## Overview
Validating JSON responses is a critical aspect of API testing, ensuring that the API returns not just data, but *correct* and *expected* data. Hamcrest matchers, when used with REST Assured or similar libraries, provide a highly readable and expressive way to assert conditions on JSON fields. This feature focuses on leveraging powerful Hamcrest matchers like `equalTo`, `containsString`, `hasItem`, and chaining them with `and` to perform robust JSON validation. Understanding these techniques is crucial for any SDET to build reliable and maintainable API automation frameworks.

## Detailed Explanation
When dealing with JSON responses, we often need to verify individual field values, check for the presence of elements in arrays, or ensure that strings contain specific substrings. Hamcrest matchers excel at these types of assertions, offering a fluent API that makes tests easy to write and understand.

### `equalTo(value)`
This matcher checks if a specific JSON field's value is exactly equal to an expected value. It's used for precise value matching of strings, numbers, booleans, or even nested JSON objects.

### `containsString(substring)`
This is useful when a JSON field's value is a string, and you only need to verify that it contains a particular substring, rather than an exact match. This is common for dynamic content or descriptive fields.

### `hasItem(item)`
When dealing with JSON arrays, `hasItem` is invaluable. It asserts that the array contains at least one element that matches the provided `item`. This `item` can be a primitive value, another matcher, or even a partially matched JSON object.

### Chaining Matchers with `and()`
Hamcrest allows combining multiple matchers using `and()` (or `allOf()` for static imports) to assert several conditions on a single field or across multiple fields in one go. This enhances readability and can make tests more concise.

### `body("jsonPath", matcher)` Syntax
REST Assured provides the `body()` method to apply Hamcrest matchers directly to JSON response fields, identified by JSONPath expressions. The basic syntax is `body("jsonPath", matcher)`. For multiple assertions on different paths, you can chain multiple `body()` calls.

## Code Implementation

Let's assume we have an API endpoint `GET /api/products/123` that returns the following JSON:

```json
{
  "id": "prod123",
  "name": "Laptop Pro 15",
  "category": "Electronics",
  "price": 1200.50,
  "features": ["High Resolution Display", "Fast Processor", "Long Battery Life"],
  "availability": {
    "inStock": true,
    "storeLocation": "Downtown"
  },
  "reviews": [
    {"reviewer": "Alice", "rating": 5, "comment": "Excellent product!"},
    {"reviewer": "Bob", "rating": 4, "comment": "Good value for money."}
  ]
}
```

Here's how we can validate this response using REST Assured and Hamcrest:

```java
import io.restassured.RestAssured;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*; // Import all Hamcrest matchers statically

public class ProductApiValidationTest {

    @Test
    public void testProductDetailsJsonValidation() {
        // Set base URI for all requests
        RestAssured.baseURI = "http://localhost:8080"; // Replace with your actual API base URL

        given()
            .when()
                .get("/api/products/123")
            .then()
                .statusCode(200) // Validate HTTP status code
                .log().body() // Log the response body for debugging

                // Validate specific fields using equalTo
                .body("id", equalTo("prod123"))
                .body("name", equalTo("Laptop Pro 15"))
                .body("category", equalTo("Electronics"))
                .body("price", equalTo(1200.50f)) // Use 'f' for float/double comparison

                // Validate string content using containsString
                .body("name", containsString("Laptop"))
                .body("availability.storeLocation", containsString("Downtown"))

                // Validate array content using hasItem
                .body("features", hasItem("Fast Processor"))
                .body("features", hasItem(containsString("Display"))) // hasItem with a nested matcher

                // Validate nested JSON object field
                .body("availability.inStock", equalTo(true))

                // Validate a property within an array of objects using hasItem and hasEntry (for maps/objects)
                // This checks if any review has a rating of 5
                .body("reviews.rating", hasItem(5))
                // This checks if any review comment contains "Excellent"
                .body("reviews.comment", hasItem(containsString("Excellent")))
                // This checks if there is a review from "Alice" with rating 5
                .body("reviews", hasItem(allOf(
                        hasEntry("reviewer", "Alice"),
                        hasEntry("rating", 5)
                )))


                // Chaining multiple matchers on the same path using and() or allOf()
                // Validating both name and category in one body assertion
                .body("name", allOf(notNullValue(), containsString("Pro")))
                .body("category", allOf(equalTo("Electronics"), not(emptyString())))

                // Example of validating multiple aspects of the response in a single .body() call
                // Note: This applies matchers to the root of the JSON. For specific paths, use separate .body() calls.
                // .body("", allOf(
                //     hasKey("id"),
                //     hasKey("name"),
                //     hasKey("features")
                // ))
                ;
    }
}
```

## Best Practices
- **Use Static Imports:** Statically import Hamcrest matchers (`import static org.hamcrest.Matchers.*;`) for cleaner and more readable test code.
- **Clear JSONPath:** Use precise JSONPath expressions to target the exact field you want to validate. Avoid overly broad paths if a specific field is intended.
- **Combine Matchers Judiciously:** While chaining matchers is powerful, don't overdo it on a single field if it makes the assertion hard to read. Sometimes multiple `body()` calls are clearer.
- **Test Edge Cases:** Consider how your API responds to missing fields, null values, empty arrays, or invalid data types and write tests to cover these scenarios.
- **Meaningful Assertions:** Ensure your assertions truly validate the business logic, not just the presence of data. For example, if a price should always be positive, assert `greaterThan(0)`.

## Common Pitfalls
- **Incorrect JSONPath:** A common mistake is using an incorrect JSONPath, leading to `PathNotFoundException` or incorrect validation. Always verify your JSONPaths.
- **Type Mismatches:** Ensure the type of the expected value matches the actual JSON field's type. For example, comparing an integer to a string will fail. Be mindful of floating-point comparisons (e.g., `equalTo(1200.50f)` for floats).
- **Over-reliance on `containsString`:** While useful, don't use `containsString` when `equalTo` is more appropriate and provides stronger validation.
- **Forgetting `hasItem` for Arrays:** When checking if an array contains a specific element, remember to use `hasItem` (or `hasItems` for multiple) instead of directly comparing the array.
- **Not logging response:** During development, `log().body()` or `log().all()` is invaluable for understanding the actual response and debugging failed assertions. Remove or comment out for production runs if logging sensitive data.

## Interview Questions & Answers
1.  **Q:** How do you validate an element within a JSON array using Hamcrest and REST Assured?
    **A:** You would use the `hasItem()` matcher. For example, `body("arrayPath", hasItem("expectedValue"))` checks if the array at "arrayPath" contains "expectedValue". If the array contains objects, you might combine `hasItem` with `allOf` and `hasEntry` or `hasProperty` to match a specific object or its properties within the array.

2.  **Q:** Explain the difference between `equalTo()` and `containsString()` in the context of JSON validation. When would you use each?
    **A:** `equalTo()` performs an exact match of the field's value against the expected value. You use it when you need to ensure a field's content is precisely what you expect (e.g., an ID, a status, an exact name). `containsString()`, on the other hand, checks if a string field *contains* a specified substring. This is used when the full string value might be dynamic or longer, but a part of it is constant and needs to be verified (e.g., a descriptive message containing a keyword).

3.  **Q:** How can you perform multiple assertions on a single JSON field using Hamcrest in one `body()` call?
    **A:** You can chain multiple Hamcrest matchers using `allOf()` (or `and()` if imported statically). For example, `body("fieldName", allOf(notNullValue(), containsString("expected")))` would ensure the field is not null and contains the specified substring.

## Hands-on Exercise
**Scenario:** You are testing a user profile API `GET /api/users/{userId}` that returns the following JSON:

```json
{
  "userId": "user123",
  "username": "john.doe",
  "email": "john.doe@example.com",
  "roles": ["admin", "editor"],
  "isActive": true,
  "address": {
    "street": "123 Main St",
    "city": "Anytown",
    "zipCode": "12345"
  }
}
```

**Task:** Write a REST Assured test using Hamcrest matchers to validate the following:
1.  The `userId` is exactly "user123".
2.  The `email` contains "@example.com".
3.  The `roles` array includes "admin".
4.  The `isActive` field is `true`.
5.  The `address.city` is "Anytown" AND the `address.zipCode` is "12345".

## Additional Resources
- **REST Assured Documentation:** [https://rest-assured.io/](https://rest-assured.io/)
- **Hamcrest Tutorial:** [http://hamcrest.org/JavaHamcrest/tutorial](http://hamcrest.org/JavaHamcrest/tutorial)
- **JSONPath Cheat Sheet:** [https://goessner.net/articles/JsonPath/](https://goessner.net/articles/JsonPath/)
---
# api-4.2-ac6.md

# JSON Array Validation in REST Assured

## Overview
Validating JSON arrays is a common and crucial task when testing RESTful APIs. It ensures that the API responses not only conform to the expected structure but also contain the correct data, size, and specific elements. In REST Assured, this is efficiently handled using Hamcrest matchers, which provide a flexible and readable way to assert conditions on array properties like size, content, and the presence of specific items or objects within the array. This skill is vital for SDETs to ensure data integrity and API reliability.

## Detailed Explanation
When dealing with JSON responses that contain arrays, you often need to verify several aspects:
1.  **Array Size**: Ensure the array has a specific number of elements.
2.  **Array Contents**: Verify that the array contains certain elements, either exactly or as a subset.
3.  **Specific Items/Objects**: Assert that the array contains objects with particular property values.

REST Assured, combined with Hamcrest, provides powerful tools for these validations.

### 1. Asserting Array Size
You can use `jsonPath("items.size()")` along with `equalTo()` matcher to assert the exact size of an array.

### 2. Asserting Array Contains a Specific String
To check if an array contains a specific string, you can use `jsonPath("items")` with Hamcrest's `hasItem()` or `hasItems()`.

### 3. Asserting Array Contains Objects with Specific Property Values
This is more complex as it involves asserting properties of objects within an array. You can achieve this by iterating through the array in a custom matcher or using more advanced JSONPath expressions with Hamcrest matchers that can evaluate conditions on nested objects. For instance, `hasItem(hasEntry("key", "value"))` can be used on a list of maps. If the array contains complex objects, you might need to extract the array as a List and then use Java streams and Hamcrest matchers to assert properties.

## Code Implementation
Let's assume we have an API endpoint `/products` that returns a JSON array of product objects, e.g.:
```json
[
  {
    "id": 1,
    "name": "Laptop",
    "price": 1200.00,
    "inStock": true,
    "tags": ["electronics", "computers"]
  },
  {
    "id": 2,
    "name": "Mouse",
    "price": 25.00,
    "inStock": true,
    "tags": ["electronics", "peripherals"]
  },
  {
    "id": 3,
    "name": "Keyboard",
    "price": 75.00,
    "inStock": false,
    "tags": ["electronics", "peripherals"]
  },
  {
    "id": 4,
    "name": "Monitor",
    "price": 300.00,
    "inStock": true,
    "tags": ["electronics", "displays"]
  },
  {
    "id": 5,
    "name": "Webcam",
    "price": 50.00,
    "inStock": true,
    "tags": ["electronics", "peripherals"]
  }
]
```

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*; // Import all Hamcrest matchers

public class JsonArrayValidationTests {

    // Base URI for the API. In a real project, this would be configured.
    // For demonstration, let's assume a mock server or a local setup.
    private static final String BASE_URI = "http://localhost:8080"; // Replace with your actual base URI

    @BeforeAll
    public static void setup() {
        RestAssured.baseURI = BASE_URI;
        // You might set up a mock server here for isolated testing
        // For this example, we assume the mock API is running.
    }

    /**
     * Test to validate the size of the top-level JSON array.
     */
    @Test
    public void testArraySize() {
        // Assert body("items.size()", equalTo(5)) -> This assumes the array is nested under "items"
        // For a top-level array, the path is simply "$".size() or omit path and refer to root.
        given()
            .when()
                .get("/products") // Assuming /products returns the JSON array directly
            .then()
                .statusCode(200)
                .body("size()", equalTo(5)); // Validates the size of the root array
    }

    /**
     * Test to assert that the 'tags' array of a specific product contains a specific string.
     */
    @Test
    public void testArrayContainsSpecificString() {
        // Assert array contains a specific string (e.g., within tags of a product)
        given()
            .when()
                .get("/products")
            .then()
                .statusCode(200)
                // Check if any product has "electronics" tag
                .body("tags", hasItem(hasItem("electronics")))
                // More specific: check if product with id 2 has "peripherals" tag
                .body("find { it.id == 2 }.tags", hasItem("peripherals"));
    }

    /**
     * Test to assert that the array contains objects with specific property values.
     * This checks for the presence of an object that matches certain criteria.
     */
    @Test
    public void testArrayContainsObjectWithSpecificPropertyValues() {
        // Assert array contains objects with specific property values
        // Example: Check if there's a product with name "Laptop" and price 1200.00
        given()
            .when()
                .get("/products")
            .then()
                .statusCode(200)
                .body("", hasItem(allOf(
                    hasEntry("name", "Laptop"),
                    hasEntry("price", 1200.00F), // REST Assured might parse numbers as Float/Double
                    hasEntry("inStock", true)
                )));

        // Example: Check if there's a product that is out of stock (inStock: false)
        given()
            .when()
                .get("/products")
            .then()
                .statusCode(200)
                .body("", hasItem(hasEntry("inStock", false)));

        // Another way to assert using JsonPath directly for a specific item property
        given()
            .when()
                .get("/products")
            .then()
                .statusCode(200)
                // Finds a product where name is "Keyboard" and checks its inStock status
                .body("find { it.name == 'Keyboard' }.inStock", equalTo(false));
    }

    /**
     * Demonstrates extracting a list of maps and then using stream API for assertions.
     * This is useful for more complex conditions or when Hamcrest path doesn't directly support it.
     */
    @Test
    public void testArrayContentsWithJavaStreams() {
        Response response = given()
            .when()
                .get("/products");

        response.then().statusCode(200);

        // Extract the whole array as a List of Maps
        List<Map<String, Object>> products = response.jsonPath().getList("");

        // Assert that all products are either in stock or priced above 50
        products.forEach(product -> {
            boolean inStock = (boolean) product.get("inStock");
            double price = ((Number) product.get("price")).doubleValue();
            // Using JUnit's assertTrue for demonstration
            org.junit.jupiter.api.Assertions.assertTrue(inStock || price > 50.00,
                "Product " + product.get("name") + " should be in stock or priced above 50");
        });

        // Assert that no product has a negative price
        org.junit.jupiter.api.Assertions.assertFalse(products.stream()
                .anyMatch(product -> ((Number) product.get("price")).doubleValue() < 0),
            "No product should have a negative price");

        // Assert that there is at least one product with name "Monitor"
        org.junit.jupiter.api.Assertions.assertTrue(products.stream()
                .anyMatch(product -> "Monitor".equals(product.get("name"))),
            "Should contain a product named Monitor");
    }
}
```

## Best Practices
-   **Use Clear JSONPath Expressions**: Keep your JSONPath expressions as concise and readable as possible. Avoid overly complex paths that are hard to debug.
-   **Combine Hamcrest Matchers**: Leverage Hamcrest's `allOf`, `anyOf`, `hasItem`, `hasItems`, `hasEntry` for building robust and expressive assertions.
-   **Extract Complex Logic**: For very complex array validations (e.g., checking multiple conditions across many objects), consider extracting the array using `response.jsonPath().getList()` and then performing assertions using Java streams or custom assertion logic. This can improve readability and maintainability.
-   **Test Edge Cases**: Always test what happens with empty arrays, arrays with a single item, or arrays containing null values if applicable to your business logic.
-   **Parameterize Tests**: If you have similar array validations across different endpoints or with different expected values, consider parameterizing your tests to reduce duplication.

## Common Pitfalls
-   **Incorrect JSONPath for Root Array**: A common mistake is using `body("items.size()")` when the array is at the root of the JSON response. For a root array, use `body("size()", equalTo(expectedSize))` or `body("[0]", is(notNullValue()))` to assert elements.
-   **Type Mismatch in Assertions**: Be careful with numeric types. JSON numbers can be interpreted as `Integer`, `Float`, `Double`, or `Long` by `jsonPath().get()`. Ensure your Hamcrest matchers use the correct type (e.g., `1200.00F` for float or `1200.00D` for double).
-   **Over-reliance on Index-based Assertions**: While `body("[0].name", equalTo("Laptop"))` works, it can make tests brittle if the order of elements in the array is not guaranteed. Prefer `hasItem(allOf(hasEntry(...)))` when order doesn't matter.
-   **Ignoring Empty/Null Arrays**: If an array can sometimes be empty or null, ensure your tests cover these scenarios to prevent `NullPointerException` or assertion failures in unexpected situations.
-   **Performance for Large Arrays**: For extremely large arrays, extracting the entire list and processing it in Java might consume more memory and CPU than using optimized JSONPath expressions. Balance readability, maintainability, and performance.

## Interview Questions & Answers
1.  **Q: How do you validate that a JSON array returned by an API has exactly 10 elements using REST Assured?**
    A: We would use `body("size()", equalTo(10))` if it's a top-level array, or `body("path.to.array.size()", equalTo(10))` if it's nested. The `size()` method from `jsonPath` combined with Hamcrest's `equalTo` matcher is ideal for this.

2.  **Q: Describe how you would verify that a specific object, identified by a unique property (e.g., an "id"), exists within a JSON array and has certain attribute values.**
    A: I would use a combination of JSONPath filtering and Hamcrest `hasItem` with `allOf`. For example, `body("", hasItem(allOf(hasEntry("id", 5), hasEntry("name", "Webcam"), hasEntry("inStock", true))))`. This robustly checks for the presence of an object matching all specified criteria without relying on its position.

3.  **Q: What are the common challenges when validating dynamic content within JSON arrays, and how do you handle them in REST Assured?**
    A: Common challenges include variable array sizes, non-deterministic order of elements, and evolving schema for objects within the array. I handle these by:
    *   **Size**: Using `body("size()", greaterThan(0))` or `lessThan(expectedMax)` instead of `equalTo` if the exact size can vary.
    *   **Order**: Avoiding index-based assertions and using `hasItem` or `hasItems` for content validation.
    *   **Evolving Schema**: Using flexible matchers like `hasKey` or `hasValue` instead of strict `equalTo` for optional fields, or extracting the list to Java objects and validating with Java code for more complex business rules, making tests more resilient to minor schema changes.

## Hands-on Exercise
**Scenario**: You are testing an e-commerce API. The endpoint `/orders` returns a list of customer orders.
```json
[
  {
    "orderId": "ORD001",
    "customerId": "CUST123",
    "totalAmount": 150.75,
    "items": [
      {"productId": "PROD001", "quantity": 1},
      {"productId": "PROD002", "quantity": 2}
    ],
    "status": "DELIVERED"
  },
  {
    "orderId": "ORD002",
    "customerId": "CUST456",
    "totalAmount": 29.99,
    "items": [
      {"productId": "PROD003", "quantity": 1}
    ],
    "status": "PROCESSING"
  }
]
```

**Tasks**:
1.  Write a REST Assured test that asserts the total number of orders is exactly 2.
2.  Write a test that verifies there is an order with `orderId` "ORD001" and its `status` is "DELIVERED".
3.  Write a test that asserts at least one order has `totalAmount` greater than 100.
4.  Write a test that checks if the order with `orderId` "ORD002" has exactly 1 item.

## Additional Resources
-   **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Hamcrest Tutorial**: [http://hamcrest.org/JavaHamcrest/tutorial](http://hamcrest.org/JavaHamcrest/tutorial)
-   **JSONPath Syntax Guide**: [https://github.com/json-path/JsonPath](https://github.com/json-path/JsonPath) (for more advanced pathing)
---
# api-4.2-ac7.md

# API Chaining: Extracting and Reusing Response Data

## Overview
API chaining, also known as request chaining or dependency management, is a critical concept in API testing and automation. It involves using data extracted from the response of one API request as input for a subsequent API request. This approach simulates real-world user flows where operations are often interdependent (e.g., creating a user, then retrieving their profile, then updating it). Mastering API chaining is essential for building robust, realistic, and efficient API test suites.

## Detailed Explanation
In a typical API chaining scenario, an initial request (e.g., a POST request to create a resource) returns a unique identifier (like an ID) or other relevant data in its response. This extracted data is then stored and used dynamically in the path, query parameters, or body of a follow-up request (e.g., a GET request to retrieve the created resource, or a DELETE request to remove it).

This process ensures that:
1.  **Tests are dynamic**: They don't rely on static, pre-existing data that might change or become invalid.
2.  **Real-world scenarios are simulated**: Mimics how an application interacts with its backend.
3.  **Test coverage is enhanced**: Allows for testing complex workflows involving multiple API calls.

### Key Steps in API Chaining:
1.  **Execute Initial Request**: Send the first API call (e.g., POST).
2.  **Extract Data**: Parse the response body of the first request to extract the necessary data (e.g., `id`, `token`, `status`). Tools like JSONPath or XMLPath are commonly used for this.
3.  **Store Data**: Hold the extracted data in a variable for later use.
4.  **Construct Subsequent Request**: Build the next API call, injecting the extracted data into its URL, headers, or request body.
5.  **Execute Subsequent Request**: Send the second API call.
6.  **Validate**: Assert the expected outcome of the chained requests.

## Code Implementation
Here's a complete, runnable Java example using REST Assured to demonstrate API chaining. We'll use a hypothetical REST API endpoint to manage 'products'.

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

public class ApiChainingRestAssuredTest {

    private static final String BASE_URI = "https://api.example.com/v1"; // Replace with your actual API base URI
    private String createdProductId; // To store the ID extracted from the POST response

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URI;
        // Optionally, if your API requires authentication for all calls
        // RestAssured.authentication = RestAssured.oauth2("YOUR_ACCESS_TOKEN");
    }

    @Test(priority = 1, description = "Create a product and extract its ID")
    public void testCreateProductAndExtractId() {
        String requestBody = "{
" +
                "    "name": "Gemini Smartwatch",
" +
                "    "description": "A smartwatch powered by Google Gemini AI",
" +
                "    "price": 299.99,
" +
                "    "inStock": true
" +
                "}";

        Response response = given()
                .contentType(ContentType.JSON)
                .body(requestBody)
                .when()
                .post("/products")
                .then()
                .statusCode(201) // Assuming 201 Created for successful resource creation
                .body("id", notNullValue()) // Assert that 'id' field exists and is not null
                .body("name", equalTo("Gemini Smartwatch"))
                .extract()
                .response();

        createdProductId = response.jsonPath().getString("id");
        System.out.println("Created Product ID: " + createdProductId);
        Assert.assertNotNull(createdProductId, "Product ID should not be null after creation.");
    }

    @Test(priority = 2, description = "Fetch the created product using its ID")
    public void testFetchCreatedProduct() {
        // Ensure product ID was extracted from previous step
        Assert.assertNotNull(createdProductId, "createdProductId is null. POST request might have failed.");

        given()
                .pathParam("id", createdProductId)
                .when()
                .get("/products/{id}")
                .then()
                .statusCode(200) // Assuming 200 OK for successful retrieval
                .body("id", equalTo(createdProductId)) // Verify the fetched ID matches
                .body("name", equalTo("Gemini Smartwatch"))
                .body("description", equalTo("A smartwatch powered by Google Gemini AI"));
        System.out.println("Successfully fetched product with ID: " + createdProductId);
    }

    @Test(priority = 3, description = "Delete the created product using its ID")
    public void testDeleteCreatedProduct() {
        // Ensure product ID was extracted from previous step
        Assert.assertNotNull(createdProductId, "createdProductId is null. POST request might have failed.");

        given()
                .pathParam("id", createdProductId)
                .when()
                .delete("/products/{id}")
                .then()
                .statusCode(204); // Assuming 204 No Content for successful deletion
        System.out.println("Successfully deleted product with ID: " + createdProductId);
    }

    @Test(priority = 4, description = "Verify 404 after deletion")
    public void testVerifyNotFoundAfterDeletion() {
        // Ensure product ID was extracted from previous step
        Assert.assertNotNull(createdProductId, "createdProductId is null. POST request might have failed.");

        given()
                .pathParam("id", createdProductId)
                .when()
                .get("/products/{id}")
                .then()
                .statusCode(404); // Assuming 404 Not Found after successful deletion
        System.out.println("Verified 404 for deleted product with ID: " + createdProductId);
    }
}
```

**To run this code:**
1.  **Dependencies**: Add REST Assured and TestNG to your `pom.xml` (Maven) or `build.gradle` (Gradle).
    *   Maven:
        ```xml
        <dependency>
            <groupId>io.rest-assured</groupId>
            <artifactId>rest-assured</artifactId>
            <version>5.3.0</version> <!-- Use the latest version -->
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.testng</groupId>
            <artifactId>testng</artifactId>
            <version>7.8.0</version> <!-- Use the latest version -->
            <scope>test</scope>
        </dependency>
        ```
2.  **API Endpoint**: Replace `https://api.example.com/v1` with a real API endpoint you can use for testing. Make sure it supports POST, GET, and DELETE operations on a resource, and returns an ID upon creation. For learning purposes, you can use mock APIs like JSONPlaceholder, though it might not support DELETE operations that result in 404 for existing IDs. A better option would be to use a tool like `json-server` to quickly set up a local mock API.
3.  **Run**: Execute the TestNG tests.

## Best Practices
-   **Use a Dedicated Test Environment**: Always perform destructive operations (POST, PUT, DELETE) on a test environment to avoid impacting production data.
-   **Parameterization**: Extract base URIs, API keys, and common headers into configuration files or test setup methods for easier management and environment switching.
-   **Assertions at Each Step**: Don't just extract data; assert that the initial request was successful and returned valid data before proceeding. This helps pinpoint failures quickly.
-   **Error Handling**: Implement mechanisms to handle cases where an ID might not be found or an API call fails. Use `try-catch` blocks or conditional logic if your framework allows.
-   **Clear Naming Conventions**: Use meaningful variable names (e.g., `createdProductId`) to improve code readability.
-   **Test Data Management**: For complex scenarios, consider using test data builders or factories to create diverse input data, rather than hardcoding large JSON strings.

## Common Pitfalls
-   **Hardcoding IDs**: Relying on static IDs is a major anti-pattern. If the data is deleted or changed, your tests will fail. Always extract IDs dynamically.
-   **Ignoring API Contracts**: Assuming the ID field will always be `id`. Always refer to the API documentation or actual responses to confirm the correct JSONPath/XMLPath.
-   **Lack of Cleanup**: If you create data (POST), ensure you delete it afterwards to keep the test environment clean, especially in continuous integration pipelines. Our example demonstrates this by deleting the created resource.
-   **Order Dependency in Test Frameworks**: Be mindful of how your test framework executes tests. TestNG's `priority` attribute helps control the order, which is crucial for chaining. JUnit 5 also provides `@TestMethodOrder`.
-   **Timeouts**: Chained requests can sometimes take longer. Configure appropriate timeouts for your API calls to prevent premature test failures.

## Interview Questions & Answers
1.  **Q: What is API chaining, and why is it important in test automation?**
    *   **A**: API chaining is the practice of using data from one API response as input for subsequent API requests. It's crucial because it allows us to test real-world, end-to-end workflows that involve multiple interdependent API calls, making tests more realistic, dynamic, and robust by avoiding reliance on static data.

2.  **Q: How do you extract data from an API response in REST Assured?**
    *   **A**: In REST Assured, you can extract data using `response.jsonPath().getString("path.to.field")` for JSON responses or `response.xmlPath().getString("path.to.field")` for XML responses. You can also use `response.as(YourPojo.class)` to deserialize the entire response into a Java object.

3.  **Q: Can you give an example of a real-world scenario where API chaining would be necessary?**
    *   **A**:
        *   **E-commerce**: Create a user (POST), get their authentication token, then use the token to add items to their cart (POST), then proceed to checkout (POST).
        *   **CRM**: Create a new customer record (POST), extract the customer ID, then use that ID to add a new activity to that customer's timeline (POST).
        *   **Microservices**: An order service creates an order and returns an `orderId`. A separate payment service then processes the payment using that `orderId`.

4.  **Q: What challenges might you face when implementing API chaining, and how do you overcome them?**
    *   **A**:
        *   **Dependencies**: Ensuring the correct order of execution. Overcome by using test framework features like `dependsOnMethods` (TestNG) or explicit sequencing.
        *   **Data Consistency**: Ensuring the data created by one request is valid and available for the next. Using unique test data and proper cleanup helps.
        *   **Error Propagation**: A failure in an early chained request can cause subsequent requests to fail, masking the root cause. Overcome by asserting at each step and having clear error messages.
        *   **Asynchronous Operations**: If an API call is asynchronous, the data might not be immediately available. This requires polling or waiting mechanisms.

## Hands-on Exercise
**Scenario**: Testing a Blog API

Assume you have access to a blog API that has the following endpoints:
-   `POST /posts`: Create a new blog post. Returns the `id` of the created post.
-   `GET /posts/{id}`: Retrieve a specific blog post by its `id`.
-   `PUT /posts/{id}`: Update a specific blog post by its `id`.
-   `DELETE /posts/{id}`: Delete a specific blog post by its `id`.

**Task**:
1.  Write a TestNG test using REST Assured.
2.  **Create** a new blog post (POST request).
3.  **Extract** the `id` of the newly created post from the response.
4.  **Update** the title and content of this post using a PUT request, injecting the extracted `id`.
5.  **Retrieve** the updated post using a GET request with the same `id` and **verify** that the title and content have been updated successfully.
6.  Ensure proper assertions at each step.

## Additional Resources
-   **REST Assured Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **JSONPath for JSON**: [https://github.com/json-path/JsonPath](https://github.com/json-path/JsonPath)
-   **W3C XPath for XML**: [https://www.w3.org/TR/xpath/](https://www.w3.org/TR/xpath/)
-   **TestNG Official Site**: [https://testng.org/doc/index.html](https://testng.org/doc/index.html)
---
# api-4.2-ac8.md

# API 4.2-ac8: JSON & XML Response Validation with Hamcrest

## Overview
In API testing, validating the exact match of an entire response body can be brittle, especially for large and dynamic payloads. This feature focuses on robust and flexible partial content validation for JSON and XML responses using Hamcrest matchers. We will explore how to verify if a response body `contains()` a specific text fragment, if a list `hasItems()` that form a subset of expected values, and if specific keys `exist in a map` (JSON object). These techniques are crucial for building resilient API tests that are less prone to failures due to minor, non-critical changes in the response structure.

## Detailed Explanation

Validating API responses often goes beyond simply checking the HTTP status code. We need to ensure the data returned is correct and adheres to our expectations. Partial content validation is particularly useful when:
- The response contains dynamic data (e.g., timestamps, unique IDs) that changes with each request, making full body assertion impractical.
- We are only interested in a specific subset of the response data.
- The response structure is complex, and we want to verify the presence of certain elements or values without asserting the entire hierarchy.

Hamcrest is a framework for writing matcher objects, allowing us to define rules for properties that an object should satisfy. When combined with Rest Assured, it provides a powerful and readable way to perform sophisticated assertions on API responses.

### Verifying Response Body Contains a Specific Text Fragment
This is useful for checking the presence of a specific string within the entire response body, regardless of its position or surrounding content.

**Example Use Case:**
- Confirming an error message is present in an error response.
- Verifying a product name appears somewhere in a product search result.

### Verifying a List Has a Subset of Items (`hasItems()`)
The `hasItems()` matcher allows us to assert that a collection (like a JSON array) contains all of the specified items, but not necessarily only those items or in that specific order. This is highly flexible when dealing with lists where the order or the complete set of items might vary.

**Example Use Case:**
- Checking if a list of users includes "Alice" and "Bob" among other users.
- Validating that a list of allowed payment methods includes "Credit Card" and "PayPal".

### Verifying Keys Exist in a Map (JSON Object)
When dealing with JSON objects (which can be thought of as maps), we often need to ensure that specific keys are present, indicating that certain data fields are available. While Hamcrest doesn't have a direct `hasKeys()` matcher, we can achieve this by combining existing matchers or by parsing the JSON and then asserting on the map. Rest Assured, however, provides direct ways to check for key existence using path validation and Hamcrest.

**Example Use Case:**
- Confirming that a user object always returns `firstName`, `lastName`, and `email` fields.
- Ensuring a product object contains `id`, `name`, and `price` attributes.

## Code Implementation

We'll use Java with Rest Assured and Hamcrest for these examples.

**Prerequisites:**
Add the following dependencies to your `pom.xml` (for Maven) or `build.gradle` (for Gradle):

**Maven (`pom.xml`):**
```xml
<dependencies>
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.3.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.hamcrest</groupId>
        <artifactId>hamcrest</artifactId>
        <version>2.2</version>
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

**Gradle (`build.gradle`):**
```gradle
dependencies {
    testImplementation 'io.rest-assured:rest-assured:5.3.0'
    testImplementation 'org.hamcrest:hamcrest:2.2'
    testImplementation 'org.junit.jupiter:junit-jupiter-api:5.10.0'
    testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.10.0'
}
```

Let's assume we have a simple mock API that returns a JSON response like this:

**GET /products/1**
```json
{
  "id": 1,
  "name": "Laptop Pro",
  "description": "Powerful laptop for professionals",
  "price": 1200.00,
  "category": "Electronics",
  "tags": ["electronics", "computers", "premium"]
}
```

**GET /products**
```json
[
  {
    "id": 1,
    "name": "Laptop Pro",
    "price": 1200.00
  },
  {
    "id": 2,
    "name": "Mechanical Keyboard",
    "price": 150.00
  },
  {
    "id": 3,
    "name": "Gaming Mouse",
    "price": 75.00
  }
]
```

**GET /error**
```json
{
  "status": 500,
  "message": "Internal Server Error: Something went wrong."
}
```

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*; // Import Hamcrest matchers

public class PartialContentValidationTests {

    // Base URI for the mock API (replace with your actual API base URI)
    // For demonstration, you can use a tool like Mockoon or WireMock,
    // or a public API that returns similar structures.
    // For local testing, ensure a mock server is running, e.g., at http://localhost:8080
    private static final String BASE_URI = "http://localhost:8080";

    @BeforeAll
    static void setup() {
        RestAssured.baseURI = BASE_URI;
    }

    /**
     * Test to verify response body contains a specific text fragment.
     * Assumes an endpoint like /error that returns a JSON with a message field.
     */
    @Test
    void testResponseBodyContainsTextFragment() {
        given()
            .when()
                .get("/error") // Assuming this endpoint returns an error message
            .then()
                .statusCode(500)
                .body(containsString("Something went wrong")); // Checks if the body contains the specified string
    }

    /**
     * Test to verify a JSON list has a subset of items using hasItems().
     * Assumes an endpoint like /products that returns a list of product objects.
     */
    @Test
    void testJsonListHasSubsetOfItems() {
        given()
            .when()
                .get("/products") // Assuming this returns a list of products
            .then()
                .statusCode(200)
                // Verify that the names of products in the list include "Laptop Pro" and "Gaming Mouse"
                // The "$" represents the root of the JSON response (which is an array in this case)
                // ".name" extracts the 'name' field from each object in the array
                .body("name", hasItems("Laptop Pro", "Gaming Mouse"));
    }

    /**
     * Test to verify keys exist in a JSON object (map).
     * Assumes an endpoint like /products/1 that returns a single product object.
     */
    @Test
    void testJsonKeysExistInMap() {
        given()
            .when()
                .get("/products/1") // Assuming this returns a single product
            .then()
                .statusCode(200)
                // Verify that the root JSON object contains the keys 'id', 'name', and 'price'.
                // "$.id" checks for the existence of 'id' at the root
                // "$.name" checks for the existence of 'name' at the root
                // "$.price" checks for the existence of 'price' at the root
                .body("$", hasKey("id"))
                .body("$", hasKey("name"))
                .body("$", hasKey("price"))
                .body("category", notNullValue()); // Also useful for checking if a key exists and is not null
    }

    /**
     * Example for XML response validation using similar principles.
     * Assume GET /item/1 returns:
     * <item>
     *   <id>1</id>
     *   <name>Book</name>
     *   <authors>
     *     <author>Author A</author>
     *     <author>Author B</author>
     *   </authors>
     * </item>
     */
    @Test
    void testXmlContentValidation() {
        given()
            .when()
                .get("/item/1") // Assuming this returns an XML response
            .then()
                .statusCode(200)
                .contentType("application/xml")
                // Verify XML root contains a specific string
                .body(containsString("Book"))
                // Verify XML list (authors) has specific items
                .body("item.authors.author", hasItems("Author A", "Author C")) // Note: 'Author C' will fail this test if not present
                // Verify an XML element exists (Rest Assured path validation handles this implicitly for existing paths)
                .body("item.id", notNullValue());
    }

    /**
     * More complex scenario: validating multiple fields with hasItems and nested paths.
     */
    @Test
    void testComplexJsonValidation() {
        given()
            .when()
                .get("/products/1") // Assuming this returns the product details for ID 1
            .then()
                .statusCode(200)
                .body("name", equalTo("Laptop Pro")) // Exact match for a field
                .body("category", is(not(emptyString()))) // Check category is not empty
                .body("tags", hasSize(greaterThan(1))) // Check size of the tags array
                .body("tags", hasItems("electronics", "premium", "gadget")); // Check tags array contains these, 'gadget' will cause a failure if not present
    }
}
```

## Best Practices
- **Be Specific:** Only validate what's necessary for your test case. Over-validating makes tests brittle.
- **Use Hamcrest Matchers:** Leverage the rich set of Hamcrest matchers for more readable and expressive assertions.
- **Path Verification:** Use JSONPath (for JSON) and XPath (for XML) expressions effectively to target specific parts of the response.
- **Avoid Hardcoding Dynamic Values:** If parts of the response are dynamic (e.g., timestamps, IDs generated on the fly), avoid hardcoding them. Instead, use matchers like `notNullValue()` or regex-based assertions.
- **Focus on Business Logic:** Design your tests to validate the business-critical aspects of the response, rather than just the structure.
- **Error Handling:** Include assertions for error scenarios, ensuring that error messages and codes are as expected.

## Common Pitfalls
- **Over-specifying Assertions:** Asserting every single field in a large response, including dynamic ones, leads to fragile tests that break with minor, non-functional changes.
- **Incorrect JSONPath/XPath:** Typos or misunderstandings of JSONPath/XPath syntax can lead to assertion failures or not finding the correct elements.
- **Ignoring Content Type:** Not checking the `Content-Type` header can lead to unexpected parsing issues (e.g., trying to parse XML as JSON).
- **Missing Hamcrest Imports:** Forgetting to `import static org.hamcrest.Matchers.*;` will result in compilation errors.
- **Not Handling Nulls Gracefully:** Assuming certain fields will always be present can lead to `NullPointerExceptions` if the API response changes. Use `notNullValue()` where appropriate.
- **Testing Implementation Details:** Focusing on how the response is constructed rather than what data it conveys.

## Interview Questions & Answers

1.  **Q: What are the advantages of using Hamcrest matchers for API response validation compared to traditional assertions?**
    **A:** Hamcrest matchers offer several advantages:
    *   **Readability:** They make assertions more human-readable and expressive (e.g., `body("name", equalTo("Laptop Pro"))` reads like plain English).
    *   **Flexibility:** A wide range of matchers allows for precise validation, from exact equality (`equalTo`) to partial content (`containsString`, `hasItems`), and type checking (`instanceOf`).
    *   **Specificity:** You can validate only the parts of the response relevant to your test, making tests less brittle.
    *   **Failure Messages:** Hamcrest provides clear and descriptive failure messages, making debugging easier.

2.  **Q: How would you validate that a JSON array returned by an API contains at least "Item A" and "Item B", but you don't care about the order or if there are other items?**
    **A:** I would use Rest Assured with the Hamcrest `hasItems()` matcher. For example, if the array is at the root of the response:
    ```java
    given().when().get("/api/list").then().statusCode(200).body("$", hasItems("Item A", "Item B"));
    ```
    If the array is nested, I would use JSONPath:
    ```java
    given().when().get("/api/data").then().statusCode(200).body("data.items", hasItems("Item A", "Item B"));
    ```

3.  **Q: When would you use `containsString()` versus `equalTo()` for response body validation?**
    **A:**
    *   **`containsString()`**: Used when you want to verify the presence of a specific substring within a larger string. This is useful for error messages, dynamic content, or when you only care if a certain piece of text exists somewhere in the response body (e.g., `body(containsString("Error Code: 123"))`).
    *   **`equalTo()`**: Used for an exact match of a specific field's value. This is typically applied to individual fields targeted by JSONPath or XPath expressions (e.g., `body("product.name", equalTo("Laptop Pro"))`). It's more strict and ensures the entire value matches.

4.  **Q: Describe a scenario where partial content validation is more appropriate than full response body comparison.**
    **A:** A common scenario is when testing an API endpoint that returns a list of dynamic resources, such as a list of recent orders or user sessions. Each order/session might have unique IDs, timestamps, and other dynamic attributes. A full response body comparison would fail on every run due to these changing values. Instead, partial validation would focus on verifying the structural integrity (e.g., each item has an `orderId` and `status`), and that specific, expected items (e.g., `status: "Pending"`) are present, without caring about the full dataset or dynamic values.

## Hands-on Exercise

**Scenario:** You are testing a simple e-commerce API.

**API Endpoint:** `GET /users/{userId}/orders`
**Expected Response (JSON for `userId=1`):**
```json
[
  {
    "orderId": "ORD12345",
    "userId": 1,
    "items": [
      {"productId": 101, "quantity": 1},
      {"productId": 102, "quantity": 2}
    ],
    "status": "Processing",
    "orderDate": "2026-02-04T10:00:00Z"
  },
  {
    "orderId": "ORD67890",
    "userId": 1,
    "items": [
      {"productId": 103, "quantity": 1}
    ],
    "status": "Shipped",
    "orderDate": "2026-02-03T15:30:00Z"
  }
]
```

**Task:** Write Rest Assured tests using Hamcrest matchers to perform the following validations:

1.  Verify that the response body for `/users/1/orders` contains the text fragment "Processing".
2.  Verify that the list of orders for `userId=1` includes an order with `status` "Shipped".
3.  Verify that the first order in the list (index 0) contains the keys `orderId`, `userId`, and `status`.
4.  Verify that the `items` array within the first order contains a `productId` of `102`.

**Hint:** You might need to set up a mock server (e.g., using Mockoon or WireMock) to simulate this API endpoint for local execution.

## Additional Resources
- **Rest Assured GitHub:** [https://github.com/rest-assured/rest-assured](https://github.com/rest-assured/rest-assured)
- **Hamcrest Tutorial:** [http://hamcrest.org/JavaHamcrest/tutorial](http://hamcrest.org/JavaHamcrest/tutorial)
- **JSONPath Online Evaluator:** [http://jsonpath.com/](http://jsonpath.com/)
- **XPath Tutorial:** [https://www.w3schools.com/xml/xpath_intro.asp](https://www.w3schools.com/xml/xpath_intro.asp)
---
# api-4.2-ac9.md

# Custom JSON Validation Logic for Complex Scenarios

## Overview
While libraries like Hamcrest and JSONPath provide powerful ways to validate JSON responses, there are often scenarios in real-world API testing where the validation logic goes beyond simple matching or extraction. These complex scenarios might involve:
- Conditional validation based on other fields' values.
- Aggregation and calculation across multiple elements in an array.
- Business rule validation that requires custom code.
- Validation of dynamic keys or schema evolution.
- Cross-referencing data with external sources or previous API responses.

This section focuses on implementing custom JSON validation logic in Java, typically by parsing the JSON response into a traversable data structure (like `Map` or `List`) and then applying imperative or functional programming constructs (loops, streams) to enforce intricate business rules. This approach offers maximum flexibility and control over the validation process.

## Detailed Explanation
When standard matchers fall short, parsing the JSON response into Java objects (e.g., using Jackson or Gson) allows you to leverage the full power of Java for validation.

### Steps Involved:
1.  **Extract Full Response as a Map or List**:
    The first step is to deserialize the JSON string into a suitable Java data structure. For arbitrary JSON, `Map<String, Object>` for JSON objects and `List<Object>` for JSON arrays are common choices. For more structured responses, you might create specific POJO (Plain Old Java Object) classes. Libraries like Jackson's `ObjectMapper` are excellent for this.

2.  **Iterate Through the Data Structure Using Java Streams/Loops**:
    Once deserialized, you can navigate the data structure.
    -   **Loops**: Traditional `for` or `while` loops are straightforward for iterating over lists or map entries.
    -   **Java Streams**: For more concise and often more readable code, Java 8 Streams API can be used to filter, map, and reduce collections, making complex aggregations and conditional logic easier to express.

3.  **Implement Complex Business Logic Validation**:
    This is where custom logic shines. Instead of simple assertions, you can write full-fledged methods to:
    -   Check if a field's value falls within a dynamic range determined by another field.
    -   Verify that the sum of items in a cart matches the total price, considering discounts.
    -   Ensure that all dates in a response are in the future or a specific format.
    -   Validate that a certain percentage of items in a list meet a criterion.

### Example Scenario: E-commerce Order Validation
Imagine an e-commerce API that returns order details. We need to validate:
-   The `totalAmount` is the sum of all `item.price * item.quantity` after applying `item.discount`.
-   All `item.status` fields are valid (e.g., "SHIPPED", "DELIVERED", "PENDING").
-   If any item is marked "SHIPPED", then `shippingDate` must be present and in the past.

## Code Implementation

Let's use the Jackson library for JSON processing. First, ensure you have the dependency:

```xml
<!-- pom.xml -->
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.17.0</version> <!-- Use the latest version -->
</dependency>
```

```java
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.Map;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Set;
import java.util.HashSet;

public class CustomOrderValidator {

    private final ObjectMapper objectMapper = new ObjectMapper();

    // Simulating an API response JSON string
    private static final String VALID_ORDER_JSON = """
    {
      "orderId": "ORD12345",
      "customerName": "Alice Wonderland",
      "totalAmount": 145.00,
      "currency": "USD",
      "items": [
        {
          "itemId": "ITEM001",
          "name": "Laptop",
          "price": 120.00,
          "quantity": 1,
          "discount": 0.00,
          "status": "SHIPPED",
          "shippingDate": "2026-01-20"
        },
        {
          "itemId": "ITEM002",
          "name": "Mouse",
          "price": 20.00,
          "quantity": 2,
          "discount": 0.50,
          "status": "PENDING"
        },
        {
          "itemId": "ITEM003",
          "name": "Keyboard",
          "price": 30.00,
          "quantity": 1,
          "discount": 0.00,
          "status": "DELIVERED"
        }
      ],
      "orderDate": "2026-02-01"
    }
    """;

    private static final String INVALID_ORDER_JSON = """
    {
      "orderId": "ORD12346",
      "customerName": "Bob The Builder",
      "totalAmount": 100.00,
      "currency": "USD",
      "items": [
        {
          "itemId": "ITEM004",
          "name": "Hammer",
          "price": 10.00,
          "quantity": 2,
          "discount": 0.00,
          "status": "INVALID_STATUS"
        },
        {
          "itemId": "ITEM005",
          "name": "Nails",
          "price": 5.00,
          "quantity": 5,
          "discount": 0.00,
          "status": "SHIPPED"
        }
      ],
      "orderDate": "2026-02-01"
    }
    """;

    // Valid statuses for items
    private static final Set<String> VALID_ITEM_STATUSES = new HashSet<>(Set.of("SHIPPED", "DELIVERED", "PENDING", "CANCELLED"));

    /**
     * Validates a given JSON order string against a set of complex business rules.
     *
     * @param orderJson The JSON string representing the order.
     * @return true if the order is valid, false otherwise.
     * @throws Exception if JSON parsing fails or unexpected data types are encountered.
     */
    public boolean validateOrder(String orderJson) throws Exception {
        Map<String, Object> order = objectMapper.readValue(orderJson, Map.class);

        // Rule 1: Validate totalAmount calculation
        if (!validateTotalAmount(order)) {
            System.err.println("Validation failed: Total amount mismatch.");
            return false;
        }

        // Rule 2: Validate item statuses and shipping dates
        if (!validateItems(order)) {
            System.err.println("Validation failed: Item status or shipping date issue.");
            return false;
        }

        System.out.println("Order validation successful for orderId: " + order.get("orderId"));
        return true;
    }

    private boolean validateTotalAmount(Map<String, Object> order) {
        double expectedTotal = ((List<Map<String, Object>>) order.get("items")).stream()
                .mapToDouble(item -> {
                    double price = ((Number) item.get("price")).doubleValue();
                    int quantity = (Integer) item.get("quantity");
                    double discount = ((Number) item.getOrDefault("discount", 0.0)).doubleValue();
                    return (price * quantity) - discount;
                })
                .sum();

        double actualTotal = ((Number) order.get("totalAmount")).doubleValue();

        // Using a small delta for double comparison due to potential floating point inaccuracies
        return Math.abs(expectedTotal - actualTotal) < 0.01;
    }

    private boolean validateItems(Map<String, Object> order) {
        List<Map<String, Object>> items = (List<Map<String, Object>>) order.get("items");

        for (Map<String, Object> item : items) {
            String status = (String) item.get("status");
            String itemId = (String) item.get("itemId");

            // Validate item status is one of the allowed statuses
            if (!VALID_ITEM_STATUSES.contains(status)) {
                System.err.println("Invalid status '" + status + "' for item " + itemId);
                return false;
            }

            // If item is SHIPPED, shippingDate must be present and in the past
            if ("SHIPPED".equals(status)) {
                String shippingDateStr = (String) item.get("shippingDate");
                if (shippingDateStr == null || shippingDateStr.isEmpty()) {
                    System.err.println("Item " + itemId + " is SHIPPED but shippingDate is missing.");
                    return false;
                }
                if (!isDateInPast(shippingDateStr)) {
                    System.err.println("Item " + itemId + " is SHIPPED but shippingDate '" + shippingDateStr + "' is not in the past or invalid format.");
                    return false;
                }
            }
        }
        return true;
    }

    private boolean isDateInPast(String dateStr) {
        try {
            // Assuming "yyyy-MM-dd" format for dates
            LocalDate shippingDate = LocalDate.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE);
            return shippingDate.isBefore(LocalDate.now());
        } catch (DateTimeParseException e) {
            System.err.println("Error parsing date: " + dateStr + ". " + e.getMessage());
            return false;
        }
    }

    public static void main(String[] args) {
        CustomOrderValidator validator = new CustomOrderValidator();
        try {
            System.out.println("--- Validating VALID_ORDER_JSON ---");
            boolean isValid1 = validator.validateOrder(VALID_ORDER_JSON);
            System.out.println("Order 1 validity: " + isValid1 + "
");

            System.out.println("--- Validating INVALID_ORDER_JSON ---");
            boolean isValid2 = validator.validateOrder(INVALID_ORDER_JSON);
            System.out.println("Order 2 validity: " + isValid2 + "
");

            // Example of a truly invalid JSON for demonstration (e.g., bad total amount)
            String BAD_TOTAL_ORDER_JSON = VALID_ORDER_JSON.replace(""totalAmount": 145.00", ""totalAmount": 100.00");
            System.out.println("--- Validating BAD_TOTAL_ORDER_JSON ---");
            boolean isValid3 = validator.validateOrder(BAD_TOTAL_ORDER_JSON);
            System.out.println("Order 3 validity: " + isValid3 + "
");

            // Example of a truly invalid JSON for demonstration (e.g., future shipping date)
            String FUTURE_SHIPPING_ORDER_JSON = VALID_ORDER_JSON.replace(""shippingDate": "2026-01-20"", ""shippingDate": "2027-01-20"");
            System.out.println("--- Validating FUTURE_SHIPPING_ORDER_JSON ---");
            boolean isValid4 = validator.validateOrder(FUTURE_SHIPPING_ORDER_JSON);
            System.out.println("Order 4 validity: " + isValid4 + "
");


        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

## Best Practices
-   **Use a Robust JSON Library**: Libraries like Jackson (`jackson-databind`) or Gson are highly optimized for JSON parsing and offer flexible APIs.
-   **Create POJOs for Complex Structures**: For well-defined JSON structures, creating Plain Old Java Objects (POJOs) makes the code more type-safe, readable, and maintainable than using generic `Map<String, Object>` or `List<Object>`.
-   **Separate Validation Logic**: Encapsulate complex validation rules in dedicated methods or classes to keep the code modular and testable.
-   **Provide Clear Error Messages**: When a validation fails, log or return clear, actionable error messages that indicate exactly what went wrong and where.
-   **Handle Type Safety and Nulls**: JSON parsing can lead to `ClassCastException` or `NullPointerException`. Always perform null checks and type assertions carefully (e.g., using `instanceof` or `Map.getOrDefault()`).
-   **Consider Custom Exceptions**: For specific validation failures, custom exceptions can provide more granular error handling.
-   **Test Validation Logic Thoroughly**: Write comprehensive unit tests for your custom validation methods with various valid and invalid JSON inputs.

## Common Pitfalls
-   **Over-reliance on Generic Maps**: While flexible, deeply nested `Map<String, Object>` can lead to verbose and error-prone code with frequent type casting. Use POJOs when structure is consistent.
-   **Ignoring Floating Point Inaccuracies**: When comparing `double` or `float` values (like `totalAmount`), direct equality checks (`==`) can fail due to floating-point precision issues. Always use a small delta (`epsilon`) for comparison, e.g., `Math.abs(a - b) < epsilon`.
-   **Hardcoding Dates/Times**: Dates and times in validation often depend on the current system time. Be mindful when writing tests for time-sensitive logic; consider using a time-mocking library if necessary.
-   **Inefficient Iteration**: For very large JSON arrays, inefficient iteration (e.g., multiple passes over the same data for different validations) can impact performance. Java Streams can help, but profile critical paths.
-   **Missing Edge Cases**: Always consider empty arrays, null values, missing fields, and unexpected data types in your validation logic.
-   **Lack of Readability**: Complex nested conditions or long chains of stream operations can become difficult to read and maintain. Break down complex logic into smaller, well-named methods.

## Interview Questions & Answers
1.  **Q: When would you choose custom JSON validation over using declarative schema validation (like JSON Schema) or simple matchers (like Hamcrest)?**
    A: Custom validation is preferred when the validation logic involves complex business rules that are difficult or impossible to express purely declaratively or with simple matchers. This includes conditional logic (e.g., "if field A has value X, then field B must be Y"), cross-field dependencies, aggregate calculations (sums, averages), external data lookups, or validations that require specific programmatic computations. While JSON Schema is good for structural and type validation, it often falls short for deep semantic and business rule checks.

2.  **Q: How do you handle potential `NullPointerException` or `ClassCastException` when parsing arbitrary JSON into generic Java collections (`Map<String, Object>`, `List<Object>`)?**
    A: I primarily use defensive programming techniques. This involves:
    -   **Null Checks**: Explicitly checking if a `Map.get()` returns `null` before attempting to access its value or cast it.
    -   **Type Checks (`instanceof`)**: Using `instanceof` before casting to ensure the object is of the expected type.
    -   **`Map.getOrDefault()`**: Using this method to provide a default value if a key is missing, avoiding `null` and simplifying logic for optional fields.
    -   **Helper Methods**: Creating utility methods that safely extract values and handle defaults or throw specific exceptions if types are incorrect or values are missing when they shouldn't be.
    -   **POJOs**: For more structured JSON, using POJOs with `ObjectMapper` and proper annotations can often handle missing fields gracefully by setting them to `null` or default values, reducing manual checks.

3.  **Q: Describe a scenario where you used Java Streams for complex JSON validation and explain why Streams were beneficial.**
    A: In a project, I had to validate a list of transactions in a JSON response. The requirement was to ensure that the sum of all 'debit' transactions equaled the sum of all 'credit' transactions for a specific account, and also to check that no single transaction exceeded a certain limit.
    Java Streams were beneficial because:
    -   **Conciseness**: They allowed me to express the sum aggregations and filtering conditions in a very compact and readable way using `filter()`, `mapToDouble()`, and `sum()`.
    -   **Readability**: The declarative nature of streams (`items.stream().filter(...).mapToDouble(...).sum()`) made the intent of the validation clear compared to verbose `for` loops with accumulator variables.
    -   **Immutability**: Streams operate on data without modifying the source collection, which reduces side effects.
    -   **Potential for Parallelism**: While not always necessary for validation, streams offer an easy path to parallel processing (`parallelStream()`) if performance becomes a concern with very large datasets.

## Hands-on Exercise
**Scenario**: You are testing an API that provides a list of user profiles. Each profile has an `id`, `name`, `email`, and a list of `roles`.
**Task**: Write a Java method `validateUserProfiles(String jsonResponse)` that performs the following validations:
1.  Ensure all users have unique `id`s.
2.  Verify that all `email` addresses are valid (simple regex: `.*@.*\..*`).
3.  Check that every user has at least one role, and that all roles are from a predefined set (e.g., "ADMIN", "EDITOR", "VIEWER").
4.  If a user has the "ADMIN" role, their email must end with "@mycompany.com".

**Example JSON response:**
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "roles": ["VIEWER"]
  },
  {
    "id": 2,
    "name": "Jane Smith",
    "email": "jane.smith@mycompany.com",
    "roles": ["ADMIN", "EDITOR"]
  },
  {
    "id": 1,
    "name": "Duplicate ID",
    "email": "duplicate@test.com",
    "roles": ["VIEWER"]
  },
  {
    "id": 3,
    "name": "Invalid Email",
    "email": "invalid-email",
    "roles": ["EDITOR"]
  },
  {
    "id": 4,
    "name": "No Roles",
    "email": "no.roles@example.com",
    "roles": []
  },
  {
    "id": 5,
    "name": "Unknown Role",
    "email": "unknown.role@example.com",
    "roles": ["GUEST"]
  },
  {
    "id": 6,
    "name": "Admin with External Email",
    "email": "admin.external@external.com",
    "roles": ["ADMIN"]
  }
]
```

## Additional Resources
-   **Jackson Databind GitHub**: [https://github.com/FasterXML/jackson-databind](https://github.com/FasterXML/jackson-databind)
-   **Java 8 Stream API Tutorial**: [https://www.baeldung.com/java-8-streams](https://www.baeldung.com/java-8-streams)
-   **Baeldung: Guide to JSON in Java**: [https://www.baeldung.com/java-json](https://www.baeldung.com/java-json)
-   **Regex in Java**: [https://docs.oracle.com/javase/tutorial/essential/regex/](https://docs.oracle.com/javase/tutorial/essential/regex/)
