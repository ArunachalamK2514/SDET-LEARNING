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
