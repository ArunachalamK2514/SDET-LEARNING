# Java Collections: Filtering, Sorting, Mapping & Reducing with Streams

## Overview

In modern test automation, we constantly deal with collections of data: lists of web elements, sets of test data, or maps of configuration properties. Performing operations like filtering for specific items, sorting them, transforming them into another format (mapping), or aggregating results (reducing) are fundamental daily tasks. The Java Stream API, introduced in Java 8, provides a powerful, declarative, and highly efficient way to perform these operations, leading to cleaner, more readable, and often more performant code compared to traditional loops.

For an SDET, mastering stream operations is non-negotiable. It's essential for validating complex data sets, preparing test data, and analyzing results.

## Detailed Explanation

The Stream API allows you to process sequences of elements from a source (like a Collection) in a functional style. A stream pipeline consists of:

1.  **Source**: A collection, array, or I/O channel that provides the data.
2.  **Intermediate Operations (0 or more)**: These transform a stream into another stream. They are *lazy*, meaning they don't execute until a terminal operation is invoked.
    *   `filter()`: Selects elements based on a predicate (a condition that returns true or false).
    *   `map()`: Transforms each element into another object.
    *   `sorted()`: Sorts the elements based on their natural order or a custom `Comparator`.
3.  **Terminal Operation (1)**: This produces a result or a side-effect, triggering the processing of the stream.
    *   `collect()`: Gathers the stream elements into a Collection (e.g., `List`, `Set`).
    *   `reduce()`: Combines stream elements into a single summary result.
    *   `forEach()`: Performs an action for each element.

### Example Scenario

Imagine we have a list of `WebElement` text values from a search results page. Each string contains a product name and its price, like `"Product A - $19.99"`. Our goal is to:
1.  **Filter**: Only include products cheaper than $50.
2.  **Map**: Extract just the product name.
3.  **Sort**: Sort the names alphabetically.
4.  **Reduce**: Concatenate the names into a single comma-separated string for logging.

## Code Implementation

This example demonstrates the four key operations on a list of product strings.

```java
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

public class CollectionOperations {

    public static class Product {
        private String name;
        private double price;
        private String category;

        public Product(String name, double price, String category) {
            this.name = name;
            this.price = price;
            this.category = category;
        }

        public String getName() {
            return name;
        }

        public double getPrice() {
            return price;
        }

        public String getCategory() {
            return category;
        }

        @Override
        public String toString() {
            return "Product{"
                   + "name='" + name + "'"
                   + ", price=" + price
                   + ", category='" + category + "'"
                   + '}';
        }
    }

    public static void main(String[] args) {
        List<Product> products = Arrays.asList(
            new Product("Laptop", 1200.00, "Electronics"),
            new Product("Mouse", 25.50, "Electronics"),
            new Product("Keyboard", 75.00, "Electronics"),
            new Product("Chair", 150.00, "Furniture"),
            new Product("Desk", 300.00, "Furniture"),
            new Product("USB-C Cable", 15.00, "Accessories")
        );

        System.out.println("Original Products: " + products);

        // 1. FILTERING: Get all electronic products cheaper than $100
        System.out.println("\n--- FILTERING ---");
        List<Product> cheapElectronics = products.stream()
            .filter(p -> p.getCategory().equals("Electronics")) // First filter by category
            .filter(p -> p.getPrice() < 100.00) // Then filter by price
            .collect(Collectors.toList());
        System.out.println("Cheap Electronics: " + cheapElectronics);

        // 2. SORTING: Get all products sorted by price (descending)
        System.out.println("\n--- SORTING ---");
        List<Product> sortedByPriceDesc = products.stream()
            .sorted(Comparator.comparingDouble(Product::getPrice).reversed())
            .collect(Collectors.toList());
        System.out.println("Products sorted by price (desc): " + sortedByPriceDesc);

        // 3. MAPPING: Get the names of all products
        System.out.println("\n--- MAPPING ---");
        List<String> productNames = products.stream()
            .map(Product::getName) // Transform Product object to its name (String)
            .collect(Collectors.toList());
        System.out.println("Product Names: " + productNames);

        // 4. REDUCING: Calculate the total cost of all furniture
        System.out.println("\n--- REDUCING ---");
        double totalFurnitureCost = products.stream()
            .filter(p -> p.getCategory().equals("Furniture"))
            .mapToDouble(Product::getPrice) // Use mapToDouble for primitive stream
            .reduce(0.0, Double::sum); // Start with 0.0 and add each price
        System.out.println("Total cost of all furniture: $" + totalFurnitureCost);
        
        // Chaining them all together: Get the names of electronics under $100, sorted alphabetically.
        System.out.println("\n--- CHAINING EXAMPLE ---");
        List<String> result = products.stream()
            .filter(p -> p.getCategory().equals("Electronics") && p.getPrice() < 100) // Filter
            .sorted(Comparator.comparing(Product::getName)) // Sort
            .map(Product::getName) // Map
            .collect(Collectors.toList());
        System.out.println("Sorted names of cheap electronics: " + result);
    }
}
```

## Best Practices

-   **Prefer Method References**: Use `Product::getName` instead of the lambda `p -> p.getName()`. It's shorter and more readable.
-   **Chain Predicates for Readability**: Instead of `filter(p -> p.getCategory().equals("Electronics") && p.getPrice() < 100)`, you can chain `.filter(p -> p.getCategory().equals("Electronics")).filter(p -> p.getPrice() < 100)`. This can make complex conditions easier to read.
-   **Use Primitive Streams**: When working with numbers (int, double, long), use primitive streams like `IntStream`, `DoubleStream`, or `LongStream` (e.g., via `mapToInt`, `mapToDouble`). This avoids the overhead of boxing/unboxing with wrapper classes (`Integer`, `Double`) and provides specialized terminal operations like `sum()`, `average()`, and `summaryStatistics()`.
-   **Streams are Single-Use**: Once a terminal operation is called on a stream, it is "consumed" and cannot be reused. If you need to perform multiple operations on the same source data, create a new stream from the source collection each time.

## Common Pitfalls

-   **Modifying the Source Collection**: Modifying the underlying collection while a stream is processing it can lead to a `ConcurrentModificationException`. Streams are designed for processing, not for mutating the source.
-   **Forgetting the Terminal Operation**: Intermediate operations are lazy. If you write a chain of `filter()` and `map()` but forget to add a `collect()`, `forEach()`, or `reduce()`, no computation will happen.
-   **Overusing Parallel Streams**: `products.parallelStream()` can speed up processing on large datasets by using multiple CPU cores. However, for small collections or simple operations, the overhead of managing threads can make it *slower*. Always benchmark before using parallel streams in performance-critical code.
-   **NullPointerExceptions in Lambdas**: If any element in your stream is `null`, or if a method called within a lambda (e.g., `p.getName()`) returns `null` and is then dereferenced, it will throw a `NullPointerException`. It's often wise to add a `filter(Objects::nonNull)` step if your source collection might contain nulls.

## Interview Questions & Answers

1.  **Q: What is the difference between an intermediate and a terminal operation in the Stream API?**
    **A:** An **intermediate operation** transforms a stream into another stream. It is always *lazy*, meaning it doesn't execute until a terminal operation is invoked. Examples include `filter()`, `map()`, and `sorted()`. A **terminal operation** produces a final result or a side effect. It triggers the execution of all intermediate operations in the pipeline and consumes the stream, so it can't be used again. Examples include `collect()`, `forEach()`, and `reduce()`.

2.  **Q: You have a `List<WebElement>`. How would you get a `List<String>` containing the text of only the visible elements?**
    **A:** You would use a stream pipeline. First, `filter()` the list to keep only visible elements using `WebElement::isDisplayed`. Then, `map()` the filtered `WebElement` objects to their text using `WebElement::getText`. Finally, use `collect(Collectors.toList())` to gather the results into a new list.
    ```java
    List<WebElement> elements = driver.findElements(By.tagName("a"));
    List<String> visibleTexts = elements.stream()
                                        .filter(WebElement::isDisplayed)
                                        .map(WebElement::getText)
                                        .collect(Collectors.toList());
    ```

3.  **Q: When would you use `map()` versus `flatMap()`?**
    **A:** You use `map()` for a one-to-one transformation: one input element produces one output element (e.g., transforming a `Product` object to its `String` name). You use `flatMap()` for a one-to-many transformation, where one input element can produce multiple (or zero) output elements. It's used to "flatten" a stream of streams into a single stream. For example, if you have a list of authors and you want a single list of all books written by all authors, you would `flatMap` the stream of `author.getBooks()`.

## Hands-on Exercise

1.  **Setup**: Create a new Java class. Copy the `Product` class and the `main` method from the **Code Implementation** section above.
2.  **Task 1 (Filtering & Mapping)**: Create a `List<String>` containing the names of all "Furniture" products that cost more than $200.
3.  **Task 2 (Mapping & Reducing)**: Find the average price of all products in the "Accessories" category. (Hint: Use `mapToDouble` and `average()`).
4.  **Task 3 (Sorting & Finding)**: Find the most expensive "Electronics" product. (Hint: Use `filter`, `max`, and a `Comparator`).
5.  **Task 4 (Advanced)**: Create a `Map<String, List<Product>>` that groups all products by their category. (Hint: Use `Collectors.groupingBy(Product::getCategory)`).

## Additional Resources

-   [Baeldung - Introduction to Java 8 Streams](https://www.baeldung.com/java-8-streams-introduction)
-   [Oracle Java Docs - Stream API](https://docs.oracle.com/javase/8/docs/api/java/util/stream/Stream.html)
-   [DigitalOcean - Java 8 Stream API Tutorial](https://www.digitalocean.com/community/tutorials/java-8-stream-api-example-tutorial)
