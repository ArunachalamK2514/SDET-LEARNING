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
