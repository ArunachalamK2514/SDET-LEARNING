# java-1.3-ac1.md

# Java Collections Framework: Collection vs. Collections

## Overview
In Java, `Collection` and `Collections` are two distinct but related concepts that often cause confusion. Understanding their differences is fundamental for effectively working with data structures in Java, especially in test automation where managing test data is crucial. This document clarifies these concepts, providing examples, best practices, and interview insights.

- **`java.util.Collection`**: This is an **interface** that represents a group of objects, known as its elements. It is the root interface in the collection hierarchy.
- **`java.util.Collections`**: This is a **utility class** that consists exclusively of static methods that operate on or return collections. It provides polymorphic algorithms that operate on collections, such as sorting, searching, and shuffling.

## Detailed Explanation

### `java.util.Collection` (Interface)
The `Collection` interface defines the common behavior for all collection types (like `List`, `Set`, and `Queue`). It declares methods that every basic collection should have, such as adding elements, removing elements, checking for element existence, and iterating over elements.

Key characteristics:
- It's an **interface**, meaning it cannot be instantiated directly. You work with its concrete implementations (e.g., `ArrayList`, `HashSet`).
- Represents a **group of individual objects**.
- Does **not** allow direct manipulation by index (like `List` does).
- Common methods include: `add()`, `remove()`, `contains()`, `isEmpty()`, `size()`, `iterator()`.

**Example in Test Automation Context**:
Imagine you're collecting a list of error messages from a web page. You might store them in a `List`, which is a sub-interface of `Collection`.

```java
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

public class ErrorMessageCollector {

    public static void main(String[] args) {
        // Declaring a Collection of Strings
        Collection<String> errorMessages = new ArrayList<>();

        // Adding elements to the collection
        errorMessages.add("Element not found: Login button");
        errorMessages.add("Timeout exception: Page did not load");
        errorMessages.add("Invalid credentials provided");

        System.out.println("All error messages: " + errorMessages);

        // Checking if an element exists
        boolean containsTimeoutError = errorMessages.contains("Timeout exception: Page did not load");
        System.out.println("Contains 'Timeout exception': " + containsTimeoutError);

        // Removing an element
        errorMessages.remove("Invalid credentials provided");
        System.out.println("Error messages after removal: " + errorMessages);

        // Iterating over the collection
        System.out.println("Iterating through messages:");
        for (String message : errorMessages) {
            System.out.println("- " + message);
        }

        // Size of the collection
        System.out.println("Number of error messages: " + errorMessages.size());

        // Clearing the collection
        errorMessages.clear();
        System.out.println("Is collection empty after clear? " + errorMessages.isEmpty());
    }
}
```

### `java.util.Collections` (Utility Class)
The `Collections` class is a utility class that provides static methods for performing operations on `Collection` objects. It's like a toolkit for collections. These methods provide various functionalities such as sorting, searching, shuffling, reversing, and synchronizing collections.

Key characteristics:
- It's a **class** with only static methods. You don't create instances of `Collections`.
- Operates on `Collection` implementations (e.g., `List`, `Set`, `Map` via `List` of entries).
- Provides **algorithms** and utility functions.
- Examples of methods: `sort()`, `min()`, `max()`, `binarySearch()`, `reverse()`, `shuffle()`, `synchronizedList()`.

**Example in Test Automation Context**:
You might have a list of test cases that you want to sort alphabetically or find the minimum/maximum value in a list of performance metrics.

```java
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Comparator;

public class TestDataManipulator {

    public static void main(String[] args) {
        List<String> testCases = new ArrayList<>();
        testCases.add("Verify Login Functionality");
        testCases.add("Validate User Profile Update");
        testCases.add("Check Search Results Filter");
        testCases.add("Ensure Order Placement Workflow");
        testCases.add("Test API Endpoint Response");

        System.out.println("Original Test Cases: " + testCases);

        // 1. Sorting a List
        Collections.sort(testCases);
        System.out.println("Sorted Test Cases: " + testCases);

        // 2. Reversing a List
        Collections.reverse(testCases);
        System.out.println("Reversed Test Cases: " + testCases);

        // 3. Shuffling a List (useful for randomizing test execution order)
        Collections.shuffle(testCases);
        System.out.println("Shuffled Test Cases: " + testCases);

        // 4. Finding min/max element
        System.out.println("Smallest Test Case (lexicographically): " + Collections.min(testCases));
        System.out.println("Largest Test Case (lexicographically): " + Collections.max(testCases));

        // Let's use a list of numbers for a more numerical min/max example
        List<Integer> responseTimes = new ArrayList<>();
        responseTimes.add(250);
        responseTimes.add(100);
        responseTimes.add(800);
        responseTimes.add(120);
        responseTimes.add(400);

        System.out.println("\nResponse Times: " + responseTimes);
        System.out.println("Minimum Response Time: " + Collections.min(responseTimes));
        System.out.println("Maximum Response Time: " + Collections.max(responseTimes));

        // 5. Binary Search (requires sorted list)
        Collections.sort(responseTimes); // Must be sorted first!
        System.out.println("Sorted Response Times: " + responseTimes);
        int index = Collections.binarySearch(responseTimes, 400);
        System.out.println("Index of 400 (after sorting): " + index); // Will return index or negative if not found
    }
}
```

### Key Differences at a Glance

| Feature        | `java.util.Collection`                    | `java.util.Collections`                        |
|----------------|-------------------------------------------|------------------------------------------------|
| **Type**       | Interface                                 | Class (Utility Class)                          |
| **Purpose**    | Defines common behavior for groups of objects; represents a data structure. | Provides static utility methods for operating on collection objects. |
| **Instantiated?** | No, implemented by concrete classes (e.g., `ArrayList`, `HashSet`). | No, all methods are static; never instantiated. |
| **Usage**      | Used to declare type for various collection implementations. | Used to perform operations like sorting, searching, synchronizing. |
| **Example**    | `List<String> names = new ArrayList<>();` | `Collections.sort(names);`                     |
| **Location**   | Top-level interface in Java Collections Framework. | Part of the utility classes in Java Collections Framework. |

## Best Practices
- **Use `Collection` interface for polymorphism**: When declaring variables, method parameters, or return types, prefer `Collection` or its sub-interfaces (`List`, `Set`, `Map`) over concrete implementation classes. This promotes flexibility and makes your code more adaptable to different collection types.
- **Utilize `Collections` for common operations**: Instead of writing your own sorting or searching algorithms, leverage the optimized methods provided by the `Collections` utility class. This saves time and reduces the likelihood of bugs.
- **Understand method prerequisites**: Some `Collections` methods, like `binarySearch()`, require the list to be sorted. Always check the method documentation.
- **Thread safety**: Most `Collection` implementations (`ArrayList`, `HashMap`) are not thread-safe. `Collections` provides wrapper methods (e.g., `Collections.synchronizedList()`) to create synchronized (thread-safe) versions of collections if needed in a multi-threaded test environment.

## Common Pitfalls
- **Confusing the two**: The most common pitfall is misunderstanding which one is the interface and which is the class. Remember: **C**ollection is the **I**nterface (I for Interface), **C**ollections is the **S**tatic (S for Static) class.
- **Using `Collection` directly**: You cannot `new Collection()`. You must instantiate one of its concrete implementations (e.g., `new ArrayList<>()`).
- **Ignoring method preconditions**: Using `Collections.binarySearch()` on an unsorted list will yield unpredictable results. Always ensure the list is sorted first.
- **Overlooking thread safety**: In parallel test execution, modifying shared collections without proper synchronization (or using thread-safe alternatives like `ConcurrentHashMap`) can lead to race conditions and incorrect test results.

## Interview Questions & Answers
1.  **Q: Explain the difference between `java.util.Collection` and `java.util.Collections`.**
    A: `java.util.Collection` is the root **interface** of the Java Collections Framework, defining basic operations common to all collections (like `add`, `remove`, `contains`). It represents a group of objects. `java.util.Collections` is a **utility class** consisting solely of static methods that operate on or return collections, providing algorithms like `sort`, `binarySearch`, `reverse`, and methods to return synchronized views of collections.

2.  **Q: When would you use `Collection` and when would you use `Collections` in a test automation framework?**
    A: I would use `Collection` (or its sub-interfaces like `List` or `Set`) to declare and manage groups of test data, web elements, or error messages. For example, `List<WebElement> productElements = driver.findElements(By.cssSelector(".product"));`. I would use `Collections` to perform utility operations on these groups, such as `Collections.sort(testDataList)` to sort test data, or `Collections.shuffle(testCaseOrder)` to randomize test execution order for better test coverage.

3.  **Q: Can you instantiate `java.util.Collection`? Why or why not?**
    A: No, you cannot instantiate `java.util.Collection` directly. It is an interface. Interfaces define a contract or a blueprint of methods that concrete classes must implement. To use a `Collection`, you must instantiate a class that implements it, such as `ArrayList`, `HashSet`, or `LinkedList`.

4.  **Q: If you have a `List<String>` of test data and you want to sort it alphabetically, which one would you use and how?**
    A: I would use the `Collections` utility class, specifically its `sort()` method.
    ```java
    List<String> testData = new ArrayList<>(Arrays.asList("Test Case A", "Test Case C", "Test Case B"));
    Collections.sort(testData); // testData will now be sorted: [Test Case A, Test Case B, Test Case C]
    ```

## Hands-on Exercise
**Scenario**: You are testing a feature that displays a list of product names on an e-commerce website. You need to verify that these product names can be sorted both alphabetically and in reverse alphabetical order.

**Task**:
1.  Create a Java `List<String>` containing at least 5 unsorted product names.
2.  Use the `Collections` class to sort the list alphabetically. Print the sorted list.
3.  Use the `Collections` class to sort the list in reverse alphabetical order. Print the reversed list.
4.  Optionally, try to find a specific product name using `Collections.binarySearch()` (remember the prerequisite!).

## Additional Resources
-   **Oracle Java Docs - Collection Interface**: [https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/Collection.html](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/Collection.html)
-   **Oracle Java Docs - Collections Class**: [https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/Collections.html](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/util/Collections.html)
-   **GeeksforGeeks - Difference between Collection and Collections in Java**: [https://www.geeksforgeeks.org/difference-between-collection-and-collections-in-java/](https://www.geeksforgeeks.org/difference-between-collection-and-collections-in-java/)
---
# java-1.3-ac2.md

# Java Collections: ArrayList, LinkedList, HashSet, and TreeSet

## Overview
Understanding the core collection classes in Java is fundamental for any SDET. The choice of collection can significantly impact the performance and clarity of your test automation framework, test data management, and even the test scripts themselves. This guide explores four of the most common collection implementations: `ArrayList`, `LinkedList`, `HashSet`, and `TreeSet`, comparing their characteristics and performance to help you make informed decisions.

## Detailed Explanation

The Java Collections Framework provides a set of interfaces and classes to represent and manage groups of objects. Let's break down these four key implementations.

### 1. `ArrayList`
- **Underlying Data Structure**: Dynamic Array.
- **Ordering**: Maintains insertion order.
- **Duplicates**: Allows duplicate elements.
- **Synchronization**: Not synchronized (not thread-safe). Use `Collections.synchronizedList()` or `CopyOnWriteArrayList` for concurrent access.
- **Performance**:
    - **`get(index)`**: Fast, O(1) constant time, as it can directly access any element by its index.
    - **`add(element)`**: Fast, amortized O(1) time. It adds to the end of the array. If the internal array is full, it creates a new, larger array and copies elements, which is an O(n) operation, but this happens infrequently.
    - **`add(index, element)` / `remove(index)`**: Slow, O(n) linear time. Adding or removing an element from the middle requires shifting all subsequent elements.

**When to use in Test Automation**:
`ArrayList` is the most commonly used `List`. It's the default choice when you need to store and retrieve a list of items by their index, such as a list of `WebElements` returned by `driver.findElements()`, or a list of expected values for a dropdown menu.

### 2. `LinkedList`
- **Underlying Data Structure**: Doubly-Linked List. Each element (node) holds a reference to the previous and next element.
- **Ordering**: Maintains insertion order.
- **Duplicates**: Allows duplicate elements.
- **Synchronization**: Not synchronized.
- **Performance**:
    - **`add(element)` / `remove(element)` (at ends)**: Fast, O(1) time. It's very efficient to add or remove from the head or tail of the list.
    - **`add(index, element)` / `remove(index)` (in middle)**: Fast, O(1) time, *if you already have a reference to the node*. However, to get to the middle of the list to perform the operation, it must traverse from the beginning or end, making it an O(n) operation overall.
    - **`get(index)`**: Slow, O(n) linear time. It has to traverse the list from the beginning (or end) to find the element at a specific index.

**When to use in Test Automation**:
`LinkedList` is ideal when you have a large list and frequently need to add or remove elements from the beginning or end. For example, implementing a queue of test data to be processed, where you add to one end and remove from the other.

### 3. `HashSet`
- **Underlying Data Structure**: Hash Table (backed by a `HashMap`).
- **Ordering**: Does **not** guarantee any order. The order can even change over time.
- **Duplicates**: Does **not** allow duplicate elements. `add()` returns `false` if the element already exists. It uses the `hashCode()` and `equals()` methods of the objects to determine uniqueness.
- **Synchronization**: Not synchronized. Use `Collections.synchronizedSet()` or `ConcurrentHashMap.newKeySet()` for concurrent access.
- **Performance**:
    - **`add(element)` / `remove(element)` / `contains(element)`**: Very fast, average O(1) constant time, assuming a good `hashCode()` function that distributes elements evenly. In the worst-case (many hash collisions), performance can degrade to O(n).

**When to use in Test Automation**:
`HashSet` is perfect when you need to store a collection of unique items and don't care about their order. A great use case is to verify that all links on a page are unique or to find the unique set of error messages displayed after submitting a form with multiple validation errors.

### 4. `TreeSet`
- **Underlying Data Structure**: Red-Black Tree (a self-balancing binary search tree).
- **Ordering**: Maintains elements in a sorted order (natural ordering or by a `Comparator` provided at creation).
- **Duplicates**: Does **not** allow duplicate elements.
- **Synchronization**: Not synchronized.
- **Performance**:
    - **`add(element)` / `remove(element)` / `contains(element)`**: Good, O(log n) logarithmic time. These operations are slightly slower than `HashSet` but still very efficient, as the tree structure allows for quick searching, insertion, and deletion.

**When to use in Test Automation**:
`TreeSet` is the go-to choice when you need a collection of unique elements that are always kept in a sorted order. For example, after scraping a list of product prices from a search results page, you can store them in a `TreeSet` to easily verify that they are sorted correctly by default.

## Code Implementation
This code benchmarks the performance of `add`, `get` (for lists), `contains` (for sets), and `remove` operations for each collection type.

```java
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

public class CollectionPerformanceComparison {

    private static final int NUM_ELEMENTS = 100_000;

    public static void main(String[] args) {
        // --- List Implementations ---
        List<Integer> arrayList = new ArrayList<>();
        List<Integer> linkedList = new LinkedList<>();

        System.out.println("--- List Performance (Adding " + NUM_ELEMENTS + " elements) ---");
        benchmarkListAdd(arrayList, "ArrayList");
        benchmarkListAdd(linkedList, "LinkedList");

        System.out.println("\n--- List Performance (Getting middle element) ---");
        benchmarkListGet(arrayList, "ArrayList");
        benchmarkListGet(linkedList, "LinkedList");

        System.out.println("\n--- List Performance (Removing from middle) ---");
        benchmarkListRemove(arrayList, "ArrayList");
        benchmarkListRemove(linkedList, "LinkedList");


        // --- Set Implementations ---
        Set<Integer> hashSet = new HashSet<>();
        Set<Integer> treeSet = new TreeSet<>();

        System.out.println("\n\n--- Set Performance (Adding " + NUM_ELEMENTS + " elements) ---");
        benchmarkSetAdd(hashSet, "HashSet");
        benchmarkSetAdd(treeSet, "TreeSet");

        System.out.println("\n--- Set Performance (Checking for contains) ---");
        benchmarkSetContains(hashSet, "HashSet");
        benchmarkSetContains(treeSet, "TreeSet");

        System.out.println("\n--- Set Performance (Removing element) ---");
        benchmarkSetRemove(hashSet, "HashSet");
        benchmarkSetRemove(treeSet, "TreeSet");
    }

    // --- List Benchmarks ---

    private static void benchmarkListAdd(List<Integer> list, String type) {
        long startTime = System.nanoTime();
        for (int i = 0; i < NUM_ELEMENTS; i++) {
            list.add(i);
        }
        long endTime = System.nanoTime();
        System.out.printf("%s add: %.3f ms\n", type, (endTime - startTime) / 1_000_000.0);
    }

    private static void benchmarkListGet(List<Integer> list, String type) {
        long startTime = System.nanoTime();
        list.get(NUM_ELEMENTS / 2); // Get element from the middle
        long endTime = System.nanoTime();
        System.out.printf("%s get (middle): %.6f ms\n", type, (endTime - startTime) / 1_000_000.0);
    }

    private static void benchmarkListRemove(List<Integer> list, String type) {
        long startTime = System.nanoTime();
        list.remove(list.size() / 2); // Remove element from the middle
        long endTime = System.nanoTime();
        System.out.printf("%s remove (middle): %.3f ms\n", type, (endTime - startTime) / 1_000_000.0);
    }

    // --- Set Benchmarks ---

    private static void benchmarkSetAdd(Set<Integer> set, String type) {
        long startTime = System.nanoTime();
        for (int i = 0; i < NUM_ELEMENTS; i++) {
            set.add(i);
        }
        long endTime = System.nanoTime();
        System.out.printf("%s add: %.3f ms\n", type, (endTime - startTime) / 1_000_000.0);
    }

    private static void benchmarkSetContains(Set<Integer> set, String type) {
        int searchElement = NUM_ELEMENTS / 2;
        long startTime = System.nanoTime();
        set.contains(searchElement);
        long endTime = System.nanoTime();
        System.out.printf("%s contains: %.6f ms\n", type, (endTime - startTime) / 1_000_000.0);
    }
    
    private static void benchmarkSetRemove(Set<Integer> set, String type) {
        int removeElement = NUM_ELEMENTS / 2;
        long startTime = System.nanoTime();
        set.remove(removeElement);
        long endTime = System.nanoTime();
        System.out.printf("%s remove: %.6f ms\n", type, (endTime - startTime) / 1_000_000.0);
    }
}
```
**Expected Output (times will vary):**
```
--- List Performance (Adding 100000 elements) ---
ArrayList add: 6.831 ms
LinkedList add: 8.542 ms

--- List Performance (Getting middle element) ---
ArrayList get (middle): 0.000800 ms
LinkedList get (middle): 1.543200 ms

--- List Performance (Removing from middle) ---
ArrayList remove (middle): 0.145 ms
LinkedList remove (middle): 1.489 ms


--- Set Performance (Adding 100000 elements) ---
HashSet add: 14.321 ms
TreeSet add: 25.432 ms

--- Set Performance (Checking for contains) ---
HashSet contains: 0.001200 ms
TreeSet contains: 0.003400 ms

--- Set Performance (Removing element) ---
HashSet remove: 0.001100 ms
TreeSet remove: 0.005300 ms
```
This clearly demonstrates `ArrayList`'s O(1) random access speed vs `LinkedList`'s O(n), and `HashSet`'s O(1) add/contains speed vs `TreeSet`'s O(log n).

## Best Practices
- **Default to `ArrayList`**: When you need a `List`, `ArrayList` is usually the right choice unless you have a specific, proven need for `LinkedList`'s performance characteristics (frequent additions/removals at the ends).
- **Program to the Interface**: Always declare your variables by the interface type (`List<String> list = new ArrayList<>();` or `Set<WebElement> elements = new HashSet<>();`). This makes your code more flexible, allowing you to change the implementation later without affecting the rest of the code.
- **Understand `hashCode()` and `equals()`**: When using `HashSet` or `TreeSet` with custom objects, it's critical to properly override `hashCode()` and `equals()` to ensure uniqueness is determined correctly.
- **Specify Initial Capacity**: If you know the approximate number of elements you'll be storing, initialize your `ArrayList` or `HashSet` with an initial capacity (e.g., `new ArrayList<>(100)`). This prevents the overhead of resizing as elements are added.

## Common Pitfalls
- **Using `LinkedList` for `get(index)`**: A common mistake is using a `LinkedList` and then frequently accessing elements by index in a loop. This leads to O(n^2) performance and can severely slow down your tests.
- **Ignoring Thread Safety**: Using a standard `ArrayList` or `HashSet` in a multi-threaded context (like parallel test execution) without proper synchronization can lead to `ConcurrentModificationException` and unpredictable behavior.
- **Forgetting `equals()`/`hashCode()`**: Storing custom objects in a `HashSet` without overriding `equals()` and `hashCode()` will result in the default `Object` class implementation being used, which compares memory addresses. This means you can have "duplicate" objects in your set.
- **Modifying a Collection While Iterating**: Trying to remove an element from a collection using a standard `for-each` loop will throw a `ConcurrentModificationException`. Use an `Iterator`'s `remove()` method instead.

## Interview Questions & Answers
1. **Q:** You need to retrieve a list of all product links from a webpage and then check for duplicates. Which collections would you use and why?
   **A:** I would first use an `ArrayList` to store the `WebElements` returned by `driver.findElements(By.tagName("a"))`. I'd iterate through this list, get the `href` attribute for each element, and add it to a `HashSet<String>`. The `HashSet` is ideal here because it automatically handles uniqueness. If I try to add a URL that already exists, the `add` method will simply return `false`. This is far more efficient than iterating through a list to check for duplicates manually.

2. **Q:** When would you choose a `LinkedList` over an `ArrayList` in a test automation context?
   **A:** I would choose a `LinkedList` in a scenario where I'm treating a collection as a queue or a stack. For instance, if I'm managing a pool of test data records to be consumed one by one, I might use a `LinkedList` and its `addLast()` and `removeFirst()` methods. These operations are O(1) and very efficient, whereas removing from the front of an `ArrayList` is an O(n) operation and would be very slow for a large dataset.

3. **Q:** You've scraped a list of prices from a website, and you need to verify they are sorted in ascending order. How would you do this?
   **A:** I would scrape the prices and store them in two lists. First, an `ArrayList<Double>` to preserve the original order as displayed on the page. Second, I would add all the prices to a `TreeSet<Double>`. The `TreeSet` will automatically sort the prices in ascending (natural) order. Finally, I would convert the `TreeSet` back to a list and assert that the original `ArrayList` is equal to the sorted list from the `TreeSet`. This confirms both the content and the order.

## Hands-on Exercise
1. **Objective**: Write a test utility method that takes a `List<WebElement>` as input and returns `true` if all the elements have unique text, and `false` otherwise.
2. **Steps**:
    - Create a public static method `areElementTextsUnique(List<WebElement> elements)`.
    - Inside the method, create an empty `HashSet<String>`.
    - Iterate through the input list of `WebElements`.
    - For each element, get its text using `.getText()`.
    - Try to add the text to the `HashSet`. The `add` method returns `false` if the element already exists. If it does, you've found a duplicate, so you can immediately return `false` from the method.
    - If the loop completes without finding any duplicates, return `true`.
3. **Bonus**: Create a second method that returns a `Set<String>` containing the text of the duplicate elements.

## Additional Resources
- [Baeldung: ArrayList vs. LinkedList](https://www.baeldung.com/java-arraylist-vs-linkedlist)
- [GeeksForGeeks: HashSet in Java](https://www.geeksforgeeks.org/hashset-in-java/)
- [Oracle Docs: The Set Interface](https://docs.oracle.com/javase/8/docs/api/java/util/Set.html)
- [Baeldung: A Guide to the Java TreeSet](https://www.baeldung.com/java-treeset)
---
# java-1.3-ac3.md

# HashMap vs Hashtable vs ConcurrentHashMap for Thread-Safety

## Overview
In Java, when working with collections, especially in multi-threaded environments, understanding the nuances of `HashMap`, `Hashtable`, and `ConcurrentHashMap` is crucial. While all three implement the `Map` interface and store key-value pairs, their approaches to thread-safety, performance, and null handling differ significantly. As an SDET, you'll often encounter scenarios where concurrent access to shared test data or configuration maps requires careful selection of the right `Map` implementation to avoid concurrency issues, ensure data integrity, and optimize performance.

This section will delve into the characteristics of each, focusing on their thread-safety mechanisms, performance implications, and practical application in test automation scenarios.

## Detailed Explanation

### 1. HashMap
- **Thread-Safety**: **Not thread-safe**. `HashMap` is designed for single-threaded environments or situations where external synchronization is handled. If used in a multi-threaded context without external synchronization, it can lead to inconsistent data, infinite loops, or `ConcurrentModificationException` during concurrent modifications (additions, deletions, updates).
- **Null Values**: Allows one `null` key and multiple `null` values.
- **Performance**: Generally offers the best performance in single-threaded environments due to no synchronization overhead.
- **Internal Mechanism**: Uses an array of buckets (nodes) where each bucket can contain a linked list or a tree (for high collision rates) of entries.

**When to use in Test Automation**:
- Storing test configuration that is initialized once and then only read (no concurrent writes).
- Storing temporary test data within a single test method or a test class where no other threads will access it concurrently.

### 2. Hashtable
- **Thread-Safety**: **Thread-safe** by using internal `synchronized` methods for almost every operation. This means only one thread can access a `Hashtable` instance at a time, making it inherently thread-safe.
- **Null Values**: Does **not** allow `null` keys or `null` values. Attempting to insert a null key or value will result in a `NullPointerException`.
- **Performance**: Slower than `HashMap` and `ConcurrentHashMap` in multi-threaded environments due to its coarse-grained locking mechanism (locking the entire table for each operation). This leads to contention when multiple threads try to access it.
- **Legacy Class**: `Hashtable` is a legacy class (part of the original Java Development Kit, JDK 1.0) and is generally discouraged in new code in favor of `ConcurrentHashMap`.

**When to use in Test Automation**:
- Almost never. `ConcurrentHashMap` is a modern, more performant alternative for thread-safe map operations.

### 3. ConcurrentHashMap
- **Thread-Safety**: **Highly thread-safe** and designed for high-concurrency environments. It achieves thread-safety without locking the entire map. In Java 8 and later, it uses a technique called *fine-grained locking* or *segment locking* (prior to Java 8), along with `CAS` (Compare-And-Swap) operations and `synchronized` blocks on individual nodes or buckets when modifications occur. Read operations generally do not require any locking.
- **Null Values**: Does **not** allow `null` keys or `null` values.
- **Performance**: Offers significantly better performance than `Hashtable` in multi-threaded scenarios because multiple threads can read from and write to different parts of the map concurrently without blocking each other.
- **Internal Mechanism**: In Java 8, `ConcurrentHashMap` uses an array of `Node` objects, and each node head is protected by a `synchronized` block, preventing multiple threads from modifying the same bucket simultaneously. It leverages `volatile` fields and `CAS` operations for updates.

**When to use in Test Automation**:
- Storing shared test context or configuration data that needs to be updated by multiple parallel test threads.
- Managing WebDriver instances in a multi-threaded test framework (e.g., using `ThreadLocal` backed by a `ConcurrentHashMap` for cleanup).
- Caching test data or resources that are accessed and potentially modified by multiple test threads.

### Comparison Table

| Feature              | HashMap           | Hashtable            | ConcurrentHashMap       |
|----------------------|-------------------|----------------------|-------------------------|
| **Thread-Safety**    | Not thread-safe   | Thread-safe          | Highly thread-safe      |
| **Null Key/Value**   | Yes (1 key, many values) | No (throws `NullPointerException`) | No (throws `NullPointerException`) |
| **Performance**      | High (single-threaded) | Low (multi-threaded, high contention) | High (multi-threaded, low contention) |
| **Legacy**           | No                | Yes (Java 1.0)       | No (Java 5+)            |
| **Synchronization**  | None              | Coarse-grained (locks entire table) | Fine-grained (Java 8: `synchronized` on nodes, `CAS`) |
| **Typical Use Case** | Single-threaded maps, internal to methods | Avoid; use `ConcurrentHashMap` | High-concurrency shared maps, caches |

## Code Implementation

Let's demonstrate thread-safety differences with a simple example where multiple threads try to add elements to each map concurrently.

```java
import java.util.Collections;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public class MapThreadSafetyDemo {

    private static final int NUM_THREADS = 10;
    private static final int NUM_OPERATIONS_PER_THREAD = 1000;

    public static void main(String[] args) throws InterruptedException {
        System.out.println("--- Demonstrating HashMap (Not Thread-Safe) ---");
        // HashMap is not thread-safe. Wrapping it with Collections.synchronizedMap
        // provides basic thread-safety but still has performance drawbacks due to coarse-grained locking.
        // Even with synchronizedMap, issues like ConcurrentModificationException can occur
        // if iteration is not externally synchronized.
        // For a pure HashMap, we expect inconsistent results or exceptions.
        runMapDemo(new HashMap<>(), "HashMap (Unsynchronized)", true);

        System.out.println("\n--- Demonstrating Hashtable (Thread-Safe with Coarse-Grained Locking) ---");
        // Hashtable is thread-safe, but its performance suffers due to coarse-grained locking.
        runMapDemo(new Hashtable<>(), "Hashtable", false);

        System.out.println("\n--- Demonstrating ConcurrentHashMap (Highly Thread-Safe) ---");
        // ConcurrentHashMap is highly efficient and thread-safe for concurrent operations.
        runMapDemo(new ConcurrentHashMap<>(), "ConcurrentHashMap", false);

        System.out.println("\n--- Demonstrating Collections.synchronizedMap (Wrapper for Thread-Safety) ---");
        // Collections.synchronizedMap provides a thread-safe view of a HashMap.
        // It's still coarse-grained locking, similar to Hashtable in terms of performance.
        runMapDemo(Collections.synchronizedMap(new HashMap<>()), "Collections.synchronizedMap", false);
    }

    private static void runMapDemo(Map<Integer, String> map, String mapType, boolean expectIssues) throws InterruptedException {
        AtomicInteger successfulPuts = new AtomicInteger(0);
        ExecutorService executor = Executors.newFixedThreadPool(NUM_THREADS);

        System.out.println("Running " + NUM_THREADS + " threads, each performing " + NUM_OPERATIONS_PER_THREAD + " put operations.");

        for (int i = 0; i < NUM_THREADS; i++) {
            final int threadId = i;
            executor.submit(() -> {
                for (int j = 0; j < NUM_OPERATIONS_PER_THREAD; j++) {
                    try {
                        int key = threadId * NUM_OPERATIONS_PER_THREAD + j;
                        String value = "Value-" + key;
                        map.put(key, value);
                        successfulPuts.incrementAndGet();
                    } catch (Exception e) {
                        // We might see ConcurrentModificationException or other issues with HashMap
                        if (expectIssues) {
                            System.err.println(mapType + " experienced an issue: " + e.getClass().getSimpleName());
                        }
                    }
                }
            });
        }

        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);

        System.out.println(mapType + " final size: " + map.size());
        System.out.println(mapType + " successful put operations: " + successfulPuts.get());
        if (map.size() != NUM_THREADS * NUM_OPERATIONS_PER_THREAD) {
            System.out.println("WARNING: " + mapType + " did not reach expected size. Expected: " + (NUM_THREADS * NUM_OPERATIONS_PER_THREAD) + ", Actual: " + map.size());
        }
    }
}
```

**Explanation of the Code:**
- The `runMapDemo` method simulates concurrent `put` operations on a given `Map` instance using an `ExecutorService` with a fixed number of threads.
- For `HashMap` (unsynchronized), you will likely see a `WARNING` indicating that the final size is less than expected, or even a `ConcurrentModificationException` if you were to iterate while modifying. The `successfulPuts` count might also be inconsistent with the final map size, indicating lost updates.
- For `Hashtable` and `ConcurrentHashMap`, you should observe that the final size is equal to the expected number of operations (`NUM_THREADS * NUM_OPERATIONS_PER_THREAD`), demonstrating their thread-safety.
- The `Collections.synchronizedMap` wrapper also provides thread-safety, but it uses an object-level lock, similar to `Hashtable`.

**Expected Output (will vary slightly on each run, especially for HashMap):**

```
--- Demonstrating HashMap (Not Thread-Safe) ---
Running 10 threads, each performing 1000 put operations.
HashMap (Unsynchronized) final size: 9965 // This will vary, often less than 10000
HashMap (Unsynchronized) experienced an issue: NullPointerException
HashMap (Unsynchronized) experienced an issue: NullPointerException
HashMap (Unsynchronized) experienced an issue: NullPointerException
HashMap (Unsynchronized) successful put operations: 9993
WARNING: HashMap (Unsynchronized) did not reach expected size. Expected: 10000, Actual: 9965

--- Demonstrating Hashtable (Thread-Safe with Coarse-Grained Locking) ---
Running 10 threads, each performing 1000 put operations.
Hashtable final size: 10000
Hashtable successful put operations: 10000

--- Demonstrating ConcurrentHashMap (Highly Thread-Safe) ---
Running 10 threads, each performing 1000 put operations.
ConcurrentHashMap final size: 10000
ConcurrentHashMap successful put operations: 10000

--- Demonstrating Collections.synchronizedMap (Wrapper for Thread-Safety) ---
Running 10 threads, each performing 1000 put operations.
Collections.synchronizedMap final size: 10000
Collections.synchronizedMap successful put operations: 10000
```
*(Note: `NullPointerException` or other issues might be observed with `HashMap` depending on JVM and exact timing of threads.)*

## Best Practices
- **Default to `HashMap` for single-threaded**: If you are certain that the `Map` will only be accessed by a single thread, or if external synchronization is guaranteed, `HashMap` offers the best performance.
- **Prefer `ConcurrentHashMap` for multi-threaded**: For almost all concurrent scenarios requiring a thread-safe `Map`, `ConcurrentHashMap` is the preferred choice over `Hashtable` due to its superior performance characteristics (fine-grained locking) and modern design.
- **Avoid `Hashtable`**: `Hashtable` is a legacy class; there's rarely a good reason to use it in new Java code.
- **`Collections.synchronizedMap()` for existing maps**: If you have an existing `HashMap` and need to make it thread-safe, `Collections.synchronizedMap(map)` can be used. However, be aware that its performance is similar to `Hashtable` (coarse-grained locking). For high-contention scenarios, migrating to `ConcurrentHashMap` is better.
- **Consider `null` values**: Remember that `Hashtable` and `ConcurrentHashMap` do not permit `null` keys or values. If your use case requires `null`s and thread-safety, you might need to use `Collections.synchronizedMap(new HashMap<>())` but handle the performance implications, or rethink your data structure.
- **Immutable Maps**: For configuration that doesn't change after initialization, consider creating an immutable `Map` using `Collections.unmodifiableMap()` or `Map.of()` (Java 9+). This is inherently thread-safe as no modifications are possible.

## Common Pitfalls
- **Using `HashMap` in multi-threaded environments without synchronization**: This is the most common pitfall, leading to subtle and hard-to-debug concurrency issues like data corruption, infinite loops, or `ConcurrentModificationException`.
- **Mixing `Collections.synchronizedMap` and direct `HashMap` access**: If you wrap a `HashMap` with `Collections.synchronizedMap` but then some parts of your code still access the original `HashMap` reference directly without synchronization, you lose the thread-safety. Always use the synchronized wrapper.
- **Assuming `ConcurrentHashMap` allows `null`s**: Forgetting that `ConcurrentHashMap` (like `Hashtable`) does not permit `null` keys or values can lead to `NullPointerException` at runtime.
- **Performance overhead of `Hashtable`**: Using `Hashtable` when `ConcurrentHashMap` would be more appropriate can lead to performance bottlenecks, especially under high concurrent write loads, due to unnecessary locking of the entire map.
- **Iteration over `Collections.synchronizedMap`**: While `Collections.synchronizedMap` makes individual operations thread-safe, iteration over it still requires external synchronization to prevent `ConcurrentModificationException`.
    ```java
    Map<String, String> syncMap = Collections.synchronizedMap(new HashMap<>());
    // ... populate map ...

    // Correct way to iterate:
    synchronized (syncMap) {
        for (Map.Entry<String, String> entry : syncMap.entrySet()) {
            System.out.println(entry.getKey() + ":" + entry.getValue());
        }
    }
    // Incorrect way (can throw ConcurrentModificationException if another thread modifies it):
    // for (Map.Entry<String, String> entry : syncMap.entrySet()) { ... }
    ```
    `ConcurrentHashMap`, on the other hand, provides *weakly consistent* iterators that reflect the state of the map at some point during iteration and do not throw `ConcurrentModificationException`.

## Interview Questions & Answers

1.  **Q: Explain the difference between `HashMap`, `Hashtable`, and `ConcurrentHashMap` in terms of thread-safety.**
    A: `HashMap` is not thread-safe; it's designed for single-threaded environments. `Hashtable` is thread-safe, achieving this by synchronizing almost every method, which means only one thread can access it at a time. `ConcurrentHashMap` is also thread-safe but achieves much higher concurrency by using fine-grained locking (e.g., synchronizing on segments or individual nodes in Java 8+) and Compare-And-Swap (CAS) operations, allowing multiple threads to read and write to different parts of the map concurrently.

2.  **Q: When would you use `ConcurrentHashMap` over `HashMap` or `Hashtable` in a test automation framework?**
    A: I would primarily use `ConcurrentHashMap` when I have shared test data or configuration that needs to be accessed and modified by multiple parallel test threads. For instance, managing a pool of WebDriver instances where each parallel test requires its own driver but all threads might be acquiring/releasing them from a central manager. `ConcurrentHashMap` ensures data consistency and avoids concurrency issues while maintaining good performance under heavy load, unlike `Hashtable` which would become a performance bottleneck due to its coarse-grained locking.

3.  **Q: Can `HashMap` handle null keys/values? What about `Hashtable` and `ConcurrentHashMap`?**
    A: `HashMap` allows one null key and multiple null values. Both `Hashtable` and `ConcurrentHashMap` do not allow null keys or null values; attempting to use them will result in a `NullPointerException`.

4.  **Q: If you need a thread-safe `HashMap`, why not just use `Collections.synchronizedMap(new HashMap<>())`? What are the implications?**
    A: `Collections.synchronizedMap()` can provide a thread-safe wrapper for a `HashMap`. However, it achieves thread-safety through coarse-grained locking, similar to `Hashtable`. This means all operations on the map are protected by a single lock, leading to contention and reduced performance in high-concurrency scenarios, especially with many write operations. While it makes individual operations safe, iterating over it still requires external synchronization. For high-performance, high-concurrency needs, `ConcurrentHashMap` is a much better choice because its fine-grained locking allows more parallel operations.

5.  **Q: What are the performance considerations when choosing between these three map types in a multi-threaded test execution environment?**
    A: In a multi-threaded test execution environment:
    *   `HashMap` will lead to data corruption or `ConcurrentModificationException` if used without external synchronization; it offers high performance only in single-threaded contexts.
    *   `Hashtable` is thread-safe but introduces significant performance overhead due to its coarse-grained locking, where the entire map is locked for every operation. This creates a bottleneck.
    *   `ConcurrentHashMap` provides the best performance for concurrent access because it uses more sophisticated locking mechanisms (e.g., locking only specific segments or nodes) that allow multiple threads to perform operations simultaneously on different parts of the map, greatly reducing contention.

## Hands-on Exercise

**Scenario:** You are building a test framework that runs tests in parallel. You need a central repository to store test execution statistics (e.g., number of passed tests, failed tests per browser type) that multiple test threads will update simultaneously.

**Task:**
1.  Create a class `TestStatsManager` that manages these statistics.
2.  Inside `TestStatsManager`, use a `Map<String, AtomicInteger>` to store counts for different categories (e.g., "Chrome_Passed", "Firefox_Failed").
3.  Implement a method `incrementStat(String statName)` that safely increments the count for a given statistic.
4.  Implement a `getStat(String statName)` method.
5.  Write a main method to simulate `N` parallel test threads, each incrementing several statistics multiple times. Observe the final counts.

**Hint:** Think about which `Map` implementation is most suitable here and why. An `AtomicInteger` is used for thread-safe incrementing of individual counts within the map values.

## Additional Resources
*   **Oracle Documentation - HashMap**: [https://docs.oracle.com/javase/8/docs/api/java/util/HashMap.html](https://docs.oracle.com/javase/8/docs/api/java/util/HashMap.html)
*   **Oracle Documentation - Hashtable**: [https://docs.oracle.com/javase/8/docs/api/java/util/Hashtable.html](https://docs.oracle.com/javase/8/docs/api/java/util/Hashtable.html)
*   **Oracle Documentation - ConcurrentHashMap**: [https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ConcurrentHashMap.html](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ConcurrentHashMap.html)
*   **Baeldung - Guide to ConcurrentHashMap**: [https://www.baeldung.com/java-concurrenthashmap](https://www.baeldung.com/java-concurrenthashmap)
*   **GeeksforGeeks - Difference between HashMap, TreeMap and LinkedHashMap**: [https://www.geeksforgeeks.org/difference-hashmap-treemap-linkedhashmap/](https://www.geeksforgeeks.org/difference-hashmap-treemap-linkedhashmap/) (While not directly about thread-safety, useful for general Map understanding).
---
# java-1.3-ac4.md

# Test Data Management Utility using Java Collections

## Overview
Effective test data management is crucial for robust and maintainable test automation frameworks. It ensures that tests are reliable, repeatable, and easy to update. This section focuses on building a simple, yet powerful, test data utility using Java's `Map` and `List` collections to store and retrieve test data. This approach promotes data separation from test logic, making tests cleaner and more organized.

## Detailed Explanation
In test automation, tests often require various inputs – usernames, passwords, product IDs, expected results, etc. Hardcoding this data directly into test cases makes them rigid and difficult to manage. A test data management utility centralizes data, allowing easy modifications without touching test logic.

We will design a utility that can handle two common test data structures:
1.  **Key-Value Pairs for single data sets**: For simple scenarios where you need a set of related data points (e.g., login credentials for a single user). A `Map<String, String>` is ideal here, where the key is the data field name (e.g., "username") and the value is the data itself (e.g., "testuser").
2.  **Data Tables for multiple data sets (Data-Driven Testing)**: For scenarios like creating multiple users, testing different product configurations, or validating a feature with various inputs. A `List<Map<String, String>>` perfectly represents a table where each `Map` is a row (a set of key-value pairs) and the `List` holds all these rows.

This utility will provide methods to load data from a source (for this example, we'll simulate loading from an external source using static data) and access it efficiently.

### Example Scenario
Imagine we are testing a login page. We need different credentials for valid, invalid, and locked accounts.
*   `validUser`: username="standard_user", password="secret_sauce"
*   `lockedUser`: username="locked_out_user", password="secret_sauce"

For a product search, we might need multiple search terms and expected results:
*   `search1`: term="backpack", expectedCount="1"
*   `search2`: term="bike", expectedCount="1"
*   `search3`: term="jacket", expectedCount="1"

Our utility will allow us to store and retrieve such data programmatically.

## Code Implementation

We'll create a `TestDataManager` class.

First, ensure you have a basic Maven or Gradle project setup.
**Maven `pom.xml` dependency (for `org.json` if you were to parse JSON files, not strictly needed for this example, but good to have for future expansion):**
```xml
<dependencies>
    <!-- For demonstration, we'll use static data. 
         For real-world JSON/CSV, you'd add dependencies like GSON or Jackson, Apache POI etc. -->
    <!-- Example if reading JSON: -->
    <dependency>
        <groupId>org.json</groupId>
        <artifactId>json</artifactId>
        <version>20231013</version>
    </dependency>
    <!-- Other dependencies like TestNG or JUnit can be added here if integrating with tests -->
</dependencies>
```

**`src/main/java/com/sdetlearning/util/TestDataManager.java`**
```java
package com.sdetlearning.util;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * A utility class for managing test data using Java Collections.
 * Supports storing data as key-value maps for single data sets or
 * lists of maps for tabular data (data-driven testing).
 */
public class TestDataManager {

    // Store single data sets (e.g., login credentials for a specific user)
    // Key: data set name (e.g., "validUser"), Value: Map of data (e.g., {username: "user", password: "pwd"})
    private final Map<String, Map<String, String>> singleDataSets;

    // Store data tables (e.g., multiple search queries with expected results)
    // Key: table name (e.g., "searchQueries"), Value: List of Maps (each Map is a row)
    private final Map<String, List<Map<String, String>>> dataTables;

    public TestDataManager() {
        this.singleDataSets = new HashMap<>();
        this.dataTables = new HashMap<>();
        loadStaticTestData(); // Load initial data (in a real scenario, this would come from files)
    }

    /**
     * Simulates loading test data from an external source.
     * In a real framework, this would involve reading from JSON, CSV, Excel, DB, etc.
     */
    private void loadStaticTestData() {
        // --- Single Data Sets ---
        // Valid Login Credentials
        Map<String, String> validUser = new HashMap<>();
        validUser.put("username", "standard_user");
        validUser.put("password", "secret_sauce");
        singleDataSets.put("validUser", validUser);

        // Locked Out User Credentials
        Map<String, String> lockedUser = new HashMap<>();
        lockedUser.put("username", "locked_out_user");
        lockedUser.put("password", "secret_sauce");
        singleDataSets.put("lockedUser", lockedUser);

        // --- Data Tables ---
        // Product Search Queries
        List<Map<String, String>> searchQueries = new ArrayList<>();
        Map<String, String> query1 = new HashMap<>();
        query1.put("searchTerm", "backpack");
        query1.put("expectedCount", "1");
        searchQueries.add(query1);

        Map<String, String> query2 = new HashMap<>();
        query2.put("searchTerm", "bike light");
        query2.put("expectedCount", "1");
        searchQueries.add(query2);

        Map<String, String> query3 = new HashMap<>();
        query3.put("searchTerm", "jacket");
        query3.put("expectedCount", "1");
        searchQueries.add(query3);
        dataTables.put("productSearchQueries", searchQueries);

        // Invalid Login Attempts (for data-driven testing)
        List<Map<String, String>> invalidLogins = new ArrayList<>();
        Map<String, String> invalid1 = new HashMap<>();
        invalid1.put("username", "bad_user");
        invalid1.put("password", "wrong_password");
        invalid1.put("expectedError", "Username and password do not match any user in this service!");
        invalidLogins.add(invalid1);

        Map<String, String> invalid2 = new HashMap<>();
        invalid2.put("username", "standard_user");
        invalid2.put("password", "wrong_password");
        invalid2.put("expectedError", "Username and password do not match any user in this service!");
        invalidLogins.add(invalid2);

        Map<String, String> invalid3 = new HashMap<>();
        invalid3.put("username", "locked_out_user");
        invalid3.put("password", "secret_sauce"); // Correct password, but user is locked
        invalid3.put("expectedError", "Sorry, this user has been locked out.");
        invalidLogins.add(invalid3);
        dataTables.put("invalidLoginAttempts", invalidLogins);
    }

    /**
     * Retrieves a specific single data set by its name.
     *
     * @param dataSetName The name of the data set (e.g., "validUser").
     * @return An Optional containing the Map of key-value pairs if found, empty Optional otherwise.
     */
    public Optional<Map<String, String>> getSingleDataSet(String dataSetName) {
        return Optional.ofNullable(singleDataSets.get(dataSetName));
    }

    /**
     * Retrieves a specific value from a single data set.
     *
     * @param dataSetName The name of the data set.
     * @param key         The key for the desired value within the data set.
     * @return An Optional containing the value if found, empty Optional otherwise.
     */
    public Optional<String> getSingleDataValue(String dataSetName, String key) {
        return getSingleDataSet(dataSetName)
                .map(dataMap -> dataMap.get(key));
    }

    /**
     * Retrieves a data table (list of data sets) by its name.
     *
     * @param tableName The name of the data table (e.g., "productSearchQueries").
     * @return An Optional containing the List of Maps if found, empty Optional otherwise.
     */
    public Optional<List<Map<String, String>>> getDataTable(String tableName) {
        return Optional.ofNullable(dataTables.get(tableName));
    }

    /**
     * Retrieves a specific row from a data table by its index.
     *
     * @param tableName The name of the data table.
     * @param rowIndex  The 0-based index of the desired row.
     * @return An Optional containing the Map for the specified row if found, empty Optional otherwise.
     */
    public Optional<Map<String, String>> getTableRow(String tableName, int rowIndex) {
        return getDataTable(tableName)
                .filter(table -> rowIndex >= 0 && rowIndex < table.size())
                .map(table -> table.get(rowIndex));
    }

    /**
     * Retrieves a specific value from a specific row in a data table.
     *
     * @param tableName The name of the data table.
     * @param rowIndex  The 0-based index of the desired row.
     * @param key       The key for the desired value within the row.
     * @return An Optional containing the value if found, empty Optional otherwise.
     */
    public Optional<String> getTableValue(String tableName, int rowIndex, String key) {
        return getTableRow(tableName, rowIndex)
                .map(rowMap -> rowMap.get(key));
    }
}
```

**`src/test/java/com/sdetlearning/tests/TestDataManagerTest.java`**
```java
package com.sdetlearning.tests;

import com.sdetlearning.util.TestDataManager;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.util.List;
import java.util.Map;
import java.util.Optional;

public class TestDataManagerTest {

    private TestDataManager testDataManager;

    @BeforeClass
    public void setup() {
        testDataManager = new TestDataManager();
    }

    @Test(description = "Verify retrieval of a single data set")
    public void testGetSingleDataSet() {
        Optional<Map<String, String>> validUser = testDataManager.getSingleDataSet("validUser");
        Assert.assertTrue(validUser.isPresent(), "validUser data set should be present");
        Assert.assertEquals(validUser.get().get("username"), "standard_user");
        Assert.assertEquals(validUser.get().get("password"), "secret_sauce");

        Optional<Map<String, String>> nonExistentUser = testDataManager.getSingleDataSet("nonExistent");
        Assert.assertFalse(nonExistentUser.isPresent(), "nonExistent data set should not be present");
    }

    @Test(description = "Verify retrieval of a single data value from a data set")
    public void testGetSingleDataValue() {
        Optional<String> username = testDataManager.getSingleDataValue("lockedUser", "username");
        Assert.assertTrue(username.isPresent(), "Username should be present");
        Assert.assertEquals(username.get(), "locked_out_user");

        Optional<String> invalidKey = testDataManager.getSingleDataValue("validUser", "email");
        Assert.assertFalse(invalidKey.isPresent(), "Email key should not be present in validUser");
    }

    @Test(description = "Verify retrieval of a data table")
    public void testGetDataTable() {
        Optional<List<Map<String, String>>> searchQueries = testDataManager.getDataTable("productSearchQueries");
        Assert.assertTrue(searchQueries.isPresent(), "productSearchQueries table should be present");
        Assert.assertEquals(searchQueries.get().size(), 3, "Expected 3 search queries");

        Optional<List<Map<String, String>>> nonExistentTable = testDataManager.getDataTable("nonExistentTable");
        Assert.assertFalse(nonExistentTable.isPresent(), "nonExistentTable should not be present");
    }

    @Test(description = "Verify retrieval of a specific row from a data table")
    public void testGetTableRow() {
        Optional<Map<String, String>> firstQuery = testDataManager.getTableRow("productSearchQueries", 0);
        Assert.assertTrue(firstQuery.isPresent(), "First query row should be present");
        Assert.assertEquals(firstQuery.get().get("searchTerm"), "backpack");

        Optional<Map<String, String>> outOfBoundsRow = testDataManager.getTableRow("productSearchQueries", 99);
        Assert.assertFalse(outOfBoundsRow.isPresent(), "Out of bounds row should not be present");
    }

    @Test(description = "Verify retrieval of a specific value from a specific row in a data table")
    public void testGetTableValue() {
        Optional<String> expectedCount = testDataManager.getTableValue("productSearchQueries", 1, "expectedCount");
        Assert.assertTrue(expectedCount.isPresent(), "Expected count should be present for second query");
        Assert.assertEquals(expectedCount.get(), "1");

        Optional<String> invalidKey = testDataManager.getTableValue("productSearchQueries", 0, "nonExistentKey");
        Assert.assertFalse(invalidKey.isPresent(), "Non-existent key should not return a value");
    }

    @DataProvider(name = "invalidLoginData")
    public Object[][] getInvalidLoginData() {
        List<Map<String, String>> invalidLogins = testDataManager.getDataTable("invalidLoginAttempts")
                .orElseThrow(() -> new RuntimeException("Invalid login attempts data not found!"));
        
        Object[][] data = new Object[invalidLogins.size()][3]; // username, password, expectedError
        for (int i = 0; i < invalidLogins.size(); i++) {
            Map<String, String> row = invalidLogins.get(i);
            data[i][0] = row.get("username");
            data[i][1] = row.get("password");
            data[i][2] = row.get("expectedError");
        }
        return data;
    }

    @Test(dataProvider = "invalidLoginData", description = "Data-driven test example using TestDataManager")
    public void testInvalidLoginScenarios(String username, String password, String expectedError) {
        System.out.println(String.format("Testing login with User: %s, Pass: %s, Expected Error: %s", username, password, expectedError));
        // In a real test, you would perform UI login actions here and assert the error message
        // For demonstration, we just assert the expected error is not null or empty
        Assert.assertNotNull(expectedError, "Expected error message should not be null");
        Assert.assertFalse(expectedError.isEmpty(), "Expected error message should not be empty");
        // Example: Assert.assertEquals(loginPage.getErrorMessage(), expectedError);
    }
}
```

To run the tests, you'll need TestNG in your `pom.xml`:
```xml
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>7.8.0</version>
    <scope>test</scope>
</dependency>
```
You can run the tests using your IDE or via Maven: `mvn clean test`.

## Best Practices
-   **Separate Data from Code**: Never hardcode test data directly into your test methods. Use a data management utility.
-   **Externalize Data**: Store test data in external files (CSV, JSON, Excel, XML, database) rather than directly in code. This makes it easier for non-developers to update data and allows version control of data.
-   **Clear Naming Conventions**: Use descriptive names for your data sets and table names (e.g., "validLoginCredentials", "productSearchData").
-   **Immutable Data**: Once loaded, consider making the retrieved data immutable to prevent accidental modifications during test execution, especially in parallel testing.
-   **Error Handling**: Implement robust error handling (e.g., using `Optional` as shown, or throwing custom exceptions) for when data is not found.
-   **Lazy Loading**: For very large datasets, consider lazy loading data only when it's needed to conserve memory.
-   **Type Safety**: While `Map<String, String>` is flexible, for complex data objects, consider using POJOs (Plain Old Java Objects) and then mapping your data to these objects for better type safety and compile-time checks.

## Common Pitfalls
-   **Hardcoding Data**: The most common pitfall. Leads to unmaintainable, rigid tests.
-   **Mixing Data Loading Logic**: Directly embedding file reading logic in every test class. This makes the framework harder to maintain and less flexible.
-   **Inconsistent Data Structure**: Using different formats or structures for similar types of test data across the framework, leading to confusion and boilerplate code.
-   **Not Handling Missing Data**: Assuming data will always be present, leading to `NullPointerException`s if a key or dataset is missing. Using `Optional` helps mitigate this.
-   **Performance Overhead**: For extremely large datasets, inefficient loading or parsing can slow down test execution. Optimize data loading if performance becomes an issue.
-   **Security**: Storing sensitive data (like production credentials) directly in plain text files. Always use secure methods for managing sensitive data, such as environment variables, secure vaults, or encrypted files.

## Interview Questions & Answers
1.  **Q: Why is test data management important in test automation?**
    A: Test data management is critical because it separates test data from test logic, making tests more maintainable, reusable, and readable. It facilitates data-driven testing, allows for easy updates of data without code changes, and prevents hardcoding, which can lead to brittle tests. It also helps in managing complex scenarios and enabling parallel execution with unique data.

2.  **Q: How would you design a test data management utility using Java collections?**
    A: I would typically use `Map<String, String>` for individual data records (e.g., login credentials) and `List<Map<String, String>>` for tabular data (e.g., multiple test cases for data-driven testing). The utility would have methods to load this data from external sources (like JSON, CSV, Excel) into these collections and provide safe retrieval methods, possibly using `Optional` to handle missing data gracefully.

3.  **Q: What are the benefits of using `Optional` when retrieving data from your utility?**
    A: `Optional` helps prevent `NullPointerException`s by explicitly indicating that a value might be absent. It forces the developer to consider the case where data is not found, leading to more robust and fault-tolerant code. It improves readability by clearly stating the intent and removes the need for explicit `null` checks everywhere.

4.  **Q: What are the alternatives to using static data in `TestDataManager` for real projects?**
    A: In real projects, test data is externalized. Common alternatives include:
    *   **JSON Files**: Easy to read and write, human-readable, good for structured data.
    *   **CSV Files**: Simple, good for tabular data, easily editable in spreadsheets.
    *   **Excel Files**: Good for large, complex tabular data, accessible to non-technical users.
    *   **Databases**: For very large or dynamic datasets, allows complex queries and integration with data generation tools.
    *   **Environment Variables/Configuration Files**: For sensitive or environment-specific data.

## Hands-on Exercise
**Objective**: Extend the `TestDataManager` to load data from a JSON file.

1.  **Create a JSON file**: In your project's `src/test/resources` directory, create a file named `testdata.json` with content like this:
    ```json
    {
      "users": [
        {
          "type": "admin",
          "username": "admin_user",
          "password": "admin_password"
        },
        {
          "type": "guest",
          "username": "guest_user",
          "password": "guest_password"
        }
      ],
      "config": {
        "baseUrl": "https://www.example.com",
        "timeout": "10000"
      }
    }
    ```
2.  **Add JSON parsing library**: Add a dependency for a JSON parsing library (e.g., `com.fasterxml.jackson.core:jackson-databind` or `org.json:json`) to your `pom.xml`.
3.  **Modify `TestDataManager`**:
    *   Add a new method `loadFromJsonFile(String filePath)` that reads the `testdata.json` file.
    *   Parse the JSON content into appropriate `Map` and `List<Map>` structures.
    *   Integrate this method into the constructor or a separate initialization method.
4.  **Update `TestDataManagerTest`**: Add new test methods to verify that the data from the JSON file is loaded and accessible correctly.

## Additional Resources
*   **Java Collections Framework Tutorial**: [https://docs.oracle.com/javase/tutorial/collections/index.html](https://docs.oracle.com/javase/tutorial/collections/index.html)
*   **Jackson JSON Processor**: [https://github.com/FasterXML/jackson](https://github.com/FasterXML/jackson)
*   **org.json Library**: [https://github.com/stleary/JSON-java](https://github.com/stleary/JSON-java)
*   **Data-Driven Testing in Selenium**: [https://www.toolsqa.com/selenium-webdriver/data-driven-testing-in-selenium/](https://www.toolsqa.com/selenium-webdriver/data-driven-testing-in-selenium/)
*   **Test Data Management Best Practices**: [https://www.tricentis.com/resources/test-data-management-best-practices/](https://www.tricentis.com/resources/test-data-management-best-practices/)
---
# java-1.3-ac5.md

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
---
# java-1.3-ac6.md

# Custom Comparator for Test Data Sorting

## Overview

In test automation, we often work with lists of objects—test data, UI elements, API responses, etc. While Java's default sorting mechanisms are powerful, they only work for "natural" orders (like alphabetical or numerical). To sort custom objects based on specific business rules (e.g., sorting test users by age, or test results by execution time), we need to define our own sorting logic. This is achieved by implementing a `Comparator`.

A `Comparator` is a powerful interface in Java that allows you to define custom, externalized sorting logic for any object, without modifying the object's source code. This is crucial for creating clean, maintainable, and flexible test automation frameworks.

## Detailed Explanation

The `java.util.Comparator` interface has one primary method that needs to be implemented: `compare(T o1, T o2)`.

This method compares two objects (`o1` and `o2`) of the same type and returns an integer with the following meaning:
- **Negative integer (`-1`)**: `o1` should come *before* `o2`.
- **Zero (`0`)**: `o1` and `o2` are *equal* in terms of sorting order.
- **Positive integer (`+1`)**: `o1` should come *after* `o2`.

Let's consider a practical test automation scenario: you have a list of `TestResult` objects from a test run, and you want to sort them to analyze the results. Each `TestResult` object might have properties like `testName`, `status` (e.g., "PASS", "FAIL"), and `duration` in milliseconds. You might want to sort these results by duration to identify the slowest tests, or by status to group all failures together.

## Code Implementation

Here is a complete, runnable example demonstrating how to create a custom object (`TestResult`) and then sort a list of these objects using different `Comparator` implementations.

### 1. The Custom Object: `TestResult.java`

This class represents the data we want to sort. It's a simple POJO (Plain Old Java Object).

```java
// File: src/main/java/com/example/sorting/TestResult.java
package com.example.sorting;

public class TestResult {
    private final String testName;
    private final String status;
    private final long duration; // in milliseconds

    public TestResult(String testName, String status, long duration) {
        this.testName = testName;
        this.status = status;
        this.duration = duration;
    }

    public String getTestName() {
        return testName;
    }

    public String getStatus() {
        return status;
    }

    public long getDuration() {
        return duration;
    }

    @Override
    public String toString() {
        return "TestResult{"
               + "testName='" + testName + "'"
               + ", status='" + status + "'"
               + ", duration=" + duration + "ms"
               + '}'
    }
}
```

### 2. Custom Comparators

We'll create two comparators: one to sort by duration (longest first) and another to sort by status.

#### `SortByDurationDesc.java`

This comparator sorts `TestResult` objects in descending order of their execution duration.

```java
// File: src/main/java/com/example/sorting/SortByDurationDesc.java
package com.example.sorting;

import java.util.Comparator;

public class SortByDurationDesc implements Comparator<TestResult> {
    @Override
    public int compare(TestResult o1, TestResult o2) {
        // To sort in descending order, we compare o2 with o1.
        // Long.compare is a safe way to compare longs, avoiding integer overflow.
        return Long.compare(o2.getDuration(), o1.getDuration());
    }
}
```

#### `SortByStatus.java`

This comparator sorts `TestResult` objects alphabetically by their status ("FAIL" will come before "PASS").

```java
// File: src/main/java/com/example/sorting/SortByStatus.java
package com.example.sorting;

import java.util.Comparator;

public class SortByStatus implements Comparator<TestResult> {
    @Override
    public int compare(TestResult o1, TestResult o2) {
        // String's compareTo method provides natural alphabetical sorting.
        return o1.getStatus().compareTo(o2.getStatus());
    }
}
```

### 3. Main Execution Class: `TestResultSorter.java`

This class demonstrates how to use our custom comparators to sort a list of `TestResult` objects.

```java
// File: src/main/java/com/example/sorting/TestResultSorter.java
package com.example.sorting;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class TestResultSorter {
    public static void main(String[] args) {
        List<TestResult> results = new ArrayList<>();
        results.add(new TestResult("LoginTest", "PASS", 1200));
        results.add(new TestResult("HomePageTest", "PASS", 3400));
        results.add(new TestResult("CheckoutTest", "FAIL", 5600));
        results.add(new TestResult("SearchTest", "PASS", 800));
        results.add(new TestResult("APITest", "FAIL", 450));

        System.out.println("--- Original List ---");
        results.forEach(System.out::println);

        // Sort by duration in descending order
        Collections.sort(results, new SortByDurationDesc());
        System.out.println("\n--- Sorted by Duration (Slowest First) ---");
        results.forEach(System.out::println);

        // Sort by status
        Collections.sort(results, new SortByStatus());
        System.out.println("\n--- Sorted by Status (FAIL then PASS) ---");
        results.forEach(System.out::println);

        // Using Lambda expression for ad-hoc sorting (Java 8+)
        System.out.println("\n--- Sorted by Test Name (Alphabetical) using Lambda ---");
        results.sort((r1, r2) -> r1.getTestName().compareTo(r2.getTestName()));
        results.forEach(System.out::println);
    }
}
```

**Output of `TestResultSorter.java`:**
```
--- Original List ---
TestResult{testName='LoginTest', status='PASS', duration=1200ms}
TestResult{testName='HomePageTest', status='PASS', duration=3400ms}
TestResult{testName='CheckoutTest', status='FAIL', duration=5600ms}
TestResult{testName='SearchTest', status='PASS', duration=800ms}
TestResult{testName='APITest', status='FAIL', duration=450ms}

--- Sorted by Duration (Slowest First) ---
TestResult{testName='CheckoutTest', status='FAIL', duration=5600ms}
TestResult{testName='HomePageTest', status='PASS', duration=3400ms}
TestResult{testName='LoginTest', status='PASS', duration=1200ms}
TestResult{testName='SearchTest', status='PASS', duration=800ms}
TestResult{testName='APITest', status='FAIL', duration=450ms}

--- Sorted by Status (FAIL then PASS) ---
TestResult{testName='CheckoutTest', status='FAIL', duration=5600ms}
TestResult{testName='APITest', status='FAIL', duration=450ms}
TestResult{testName='LoginTest', status='PASS', duration=1200ms}
TestResult{testName='HomePageTest', 'PASS', duration=3400ms}
TestResult{testName='SearchTest', 'PASS', duration=800ms}

--- Sorted by Test Name (Alphabetical) using Lambda ---
TestResult{testName='APITest', status='FAIL', duration=450ms}
TestResult{testName='CheckoutTest', status='FAIL', duration=5600ms}
TestResult{testName='HomePageTest', status='PASS', duration=3400ms}
TestResult{testName='LoginTest', status='PASS', duration=1200ms}
TestResult{testName='SearchTest', status='PASS', duration=800ms}
```

## Best Practices

- **Favor `Comparator` over `Comparable`**: Implement `Comparable` for a single, natural ordering. For all other sorting needs, use `Comparator`s. This decouples sorting logic from your domain objects.
- **Use Static Factory Methods**: For common comparators, define them as static instances within the class they sort (e.g., `public static final Comparator<TestResult> BY_DURATION = ...`).
- **Leverage Java 8+ Features**: Use lambda expressions for simple, ad-hoc comparators. For more complex or reusable logic, use `Comparator.comparing()` and `thenComparing()` for creating clean, chained comparators.
- **Handle Nulls Gracefully**: If properties can be null, use `Comparator.nullsFirst()` or `Comparator.nullsLast()` to avoid `NullPointerException`.
- **Ensure Transitivity**: Your compare logic must be transitive. If `compare(a, b) > 0` and `compare(b, c) > 0`, then `compare(a, c)` must be `> 0`.

## Common Pitfalls

- **Integer Overflow**: Never use `o1.value - o2.value` to compare integer or long primitives if the numbers can be very large or small. The subtraction can overflow. Always use `Integer.compare(o1.value, o2.value)` or `Long.compare(o1.value, o2.value)`.
- **Violating the `compare` Contract**: Forgetting to handle all three return cases (negative, zero, positive) can lead to unpredictable sorting behavior or exceptions.
- **Modifying Objects during Comparison**: The `compare` method should be a pure function and must not modify the state of the objects being compared.
- **Inconsistent `equals` and `compare`**: If `compare(o1, o2) == 0`, it is strongly recommended, but not strictly required, that `o1.equals(o2)` is true. If they are inconsistent, collections like `TreeSet` or `TreeMap` can behave unexpectedly.

## Interview Questions & Answers

1. **Q: When would you use `Comparable` vs `Comparator`?**
   **A:** Use `Comparable` to define the *natural* sorting order for a class (e.g., sorting `Employee` objects by employee ID). This requires modifying the class itself and you only get one implementation. Use `Comparator` when you want to define *multiple, external* sorting strategies (e.g., sorting employees by last name, salary, or hire date), or when you cannot modify the source code of the class you want to sort. In test automation, `Comparator` is far more flexible and common.

2. **Q: How can you sort a list of custom objects on multiple fields? For example, sort test results by status first, and then by duration for tests with the same status.**
   **A:** With Java 8+, the best way is to use `Comparator.comparing()` chained with `thenComparing()`. This is highly readable and less error-prone.
   ```java
   // Sort by status (alphabetical), then by duration (descending)
   Comparator<TestResult> multiSort = Comparator.comparing(TestResult::getStatus)
                                                .thenComparing(TestResult::getDuration, Comparator.reverseOrder());
   results.sort(multiSort);
   ```
   Before Java 8, you would implement this with nested `if/else` logic inside a single `compare` method.

3. **Q: Your `compare` method returns `0` for two distinct objects. What is the implication of this when using a `TreeSet`?**
   **A:** A `TreeSet` (and `TreeMap`) uses the `compare` method (or `compareTo` from `Comparable`) to determine uniqueness. If `compare(o1, o2)` returns `0`, the `TreeSet` considers the objects to be duplicates and will not add the second object (`o2`) to the set, even if `o1.equals(o2)` is `false`. This can lead to silent data loss if you're not aware of this behavior.

## Hands-on Exercise

1. **Objective**: Create a `Comparator` to sort a list of `WebElement` objects based on their vertical position on a web page. This is useful for verifying items are displayed in the correct visual order.

2. **Steps**:
   a. Create a simple Java project with Selenium WebDriver as a dependency.
   b. Write a test that navigates to a page with a vertical list of items (e.g., the product list on `https://www.saucedemo.com`).
   c. Use `driver.findElements()` to get a `List<WebElement>` of all the items.
   d. Create a `WebElementYPositionComparator` that implements `Comparator<WebElement>`.
   e. In the `compare` method, use `element.getLocation().getY()` to get the vertical coordinate for each element.
   f. Compare the Y-coordinates to sort the elements from top to bottom.
   g. In your main test, create two lists: one is the original list from `findElements`, and the other is a sorted copy of that list using your new comparator.
   h. Use `Assert.assertEquals(originalList, sortedList)` to verify that the elements were already rendered in the correct order on the page. If they weren't, the assertion would fail, indicating a UI bug.

## Additional Resources

- [Java Docs - Comparator Interface](https://docs.oracle.com/javase/8/docs/api/java/util/Comparator.html)
- [Baeldung - Java 8 Comparators](https://www.baeldung.com/java-8-comparator-comparing)
- [GeeksforGeeks - Comparable vs Comparator in Java](https://www.geeksforgeeks.org/comparable-vs-comparator-in-java/)
---
# java-1.3-ac7.md

# java-1.3-ac7: Build Utility Methods for Reading Test Data from Excel/JSON into Collections

## Overview
In robust test automation frameworks, managing and providing test data efficiently is crucial. Rather than hardcoding data within tests, externalizing it into formats like Excel or JSON allows for easier maintenance, scalability, and reusability. This section focuses on creating utility methods to "simulate" reading test data from these external sources and structuring it into Java Collections (specifically `List<Map<String, String>>` for tabular data and `Map<String, String>` for single-record data). This approach ensures that our tests can consume diverse datasets without modifying test logic.

## Detailed Explanation
Test data management is a cornerstone of effective test automation. When tests need to run with different inputs, a robust mechanism to supply this data is essential. Excel and JSON are two popular formats for storing test data due to their human-readability and structured nature.

*   **Excel (or CSV)** is often used for tabular data, where each row represents a test case and columns represent parameters. In Java, this maps well to a `List<Map<String, String>>`, where each `Map` represents a row (test record) and keys are column headers.
*   **JSON** is excellent for structured, hierarchical data. It can store complex objects and arrays. For simpler cases, a single JSON object can represent a record, mapping directly to a `Map<String, String>`. For a collection of records, it maps to a `List<Map<String, String>>`.

This feature focuses on creating utility methods that *simulate* reading this data. In a real-world scenario, these simulation methods would be replaced with actual parsing logic (e.g., using Apache POI for Excel or Jackson/Gson for JSON). The simulation helps us define the expected structure and interface for our data utilities.

### Why use Collections for Test Data?
1.  **Flexibility**: `Map` allows access to data points by named keys (column headers), making test methods more readable (e.g., `testData.get("username")`).
2.  **Dynamic Nature**: `List` can hold multiple test records, facilitating data-driven testing where the same test logic runs with different inputs.
3.  **Standardization**: Using standard Java Collections ensures compatibility with various data processing utilities and framework components.

## Code Implementation

Let's create a `TestDataLoader` utility class with methods to simulate reading data.

```java
package utils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Utility class for simulating the loading of test data from external sources
 * like Excel or JSON files into Java Collections.
 * In a real framework, actual file parsing logic (e.g., Apache POI for Excel, 
 * Jackson/Gson for JSON) would be integrated here.
 */
public class TestDataLoader {

    /**
     * Simulates reading tabular test data, typically from an Excel sheet or CSV.
     * Each row is represented as a Map, and the entire sheet as a List of Maps.
     *
     * @param fileName The name of the Excel/CSV file (for simulation purposes).
     * @return A List of Maps, where each Map represents a row of data
     *         (key=column header, value=cell value).
     */
    public static List<Map<String, String>> getExcelTestData(String fileName) {
        System.out.println("Simulating reading Excel data from: " + fileName);
        List<Map<String, String>> testData = new ArrayList<>();

        // Simulate row 1
        Map<String, String> row1 = new HashMap<>();
        row1.put("TestCaseID", "TC001");
        row1.put("Username", "user1");
        row1.put("Password", "pass123");
        row1.put("ExpectedResult", "Login Successful");
        testData.add(row1);

        // Simulate row 2
        Map<String, String> row2 = new HashMap<>();
        row2.put("TestCaseID", "TC002");
        row2.put("Username", "invalid_user");
        row2.put("Password", "wrong_pass");
        row2.put("ExpectedResult", "Invalid Credentials");
        testData.add(row2);

        // Simulate row 3
        Map<String, String> row3 = new HashMap<>();
        row3.put("TestCaseID", "TC003");
        row3.put("Username", "locked_user");
        row3.put("Password", "pass123");
        row3.put("ExpectedResult", "Account Locked");
        testData.add(row3);

        System.out.println("Excel Data Loaded (Simulated): " + testData);
        return testData;
    }

    /**
     * Simulates reading a single record of test data, typically from a JSON object.
     *
     * @param fileName The name of the JSON file (for simulation purposes).
     * @param keyIdentifier An optional key to identify a specific record if the JSON contains an array. 
     *                        For this simulation, it's just for logging.
     * @return A Map representing a single JSON record (key=JSON field, value=field value).
     */
    public static Map<String, String> getJsonTestData(String fileName, String keyIdentifier) {
        System.out.println("Simulating reading JSON data from: " + fileName + " for key: " + keyIdentifier);
        Map<String, String> testData = new HashMap<>();

        // Simulate a single JSON record
        if ("userProfile".equals(keyIdentifier)) {
            testData.put("firstName", "John");
            testData.put("lastName", "Doe");
            testData.put("email", "john.doe@example.com");
            testData.put("age", "30");
        } else if ("productDetails".equals(keyIdentifier)) {
            testData.put("productName", "Laptop");
            testData.put("price", "1200.00");
            testData.put("currency", "USD");
        } else {
            // Default simulated data
            testData.put("defaultKey1", "defaultValueA");
            testData.put("defaultKey2", "defaultValueB");
        }

        System.out.println("JSON Data Loaded (Simulated): " + testData);
        return testData;
    }

    /**
     * Helper method to fetch a specific data record from a List<Map> by a given key and value.
     * Useful when you need to select a particular test case from a larger dataset.
     *
     * @param allData The list of all data records.
     * @param key The key to search by (e.g., "TestCaseID").
     * @param value The value associated with the key to find (e.g., "TC002").
     * @return The first Map that matches the criteria, or null if not found.
     */
    public static Map<String, String> fetchDataByKey(List<Map<String, String>> allData, String key, String value) {
        if (allData == null || allData.isEmpty()) {
            return null;
        }
        for (Map<String, String> record : allData) {
            if (record.containsKey(key) && record.get(key).equals(value)) {
                return record;
            }
        }
        System.out.println("No data found for key '" + key + "' with value '" + value + "'");
        return null;
    }

    public static void main(String[] args) {
        System.out.println("--- Demonstrating Excel Data Loading ---");
        List<Map<String, String>> excelData = getExcelTestData("LoginData.xlsx");
        if (excelData != null) {
            System.out.println("All Excel Data: " + excelData);
            Map<String, String> tc002Data = fetchDataByKey(excelData, "TestCaseID", "TC002");
            System.out.println("Data for TC002: " + tc002Data);
            if(tc002Data != null) {
                System.out.println("Username for TC002: " + tc002Data.get("Username"));
            }
        }

        System.out.println("\n--- Demonstrating JSON Data Loading ---");
        Map<String, String> userProfileData = getJsonTestData("UserProfile.json", "userProfile");
        if (userProfileData != null) {
            System.out.println("User Profile Data: " + userProfileData);
            System.out.println("User Email: " + userProfileData.get("email"));
        }

        Map<String, String> productDetailsData = getJsonTestData("Product.json", "productDetails");
        if (productDetailsData != null) {
            System.out.println("Product Details Data: " + productDetailsData);
            System.out.println("Product Price: " + productDetailsData.get("price"));
        }
    }
}
```

**To run this code:**
1.  Save the code as `TestDataLoader.java` in a `utils` directory (e.g., `your_project_root/src/main/java/utils/`).
2.  Compile and run the `main` method from your IDE or command line.
    *   `javac src/main/java/utils/TestDataLoader.java`
    *   `java -cp src/main/java utils.TestDataLoader`

The output will show the simulated data being loaded and accessed.

## Best Practices
-   **Separate Data from Tests**: Always externalize test data. This makes tests more readable, maintainable, and easier to update without touching test logic.
-   **Choose Appropriate Format**: Use Excel/CSV for simpler tabular data; JSON/XML for complex, hierarchical data structures.
-   **Use Meaningful Keys**: For `Map`s, use descriptive keys (like column headers in Excel or field names in JSON) for easy access to data points.
-   **Centralized Data Loader**: Create a dedicated utility class (`TestDataLoader` as shown) for all data loading operations. This promotes reusability and makes it easy to switch underlying parsing implementations later.
-   **Handle File Not Found/Parsing Errors**: In a real implementation, robust error handling (e.g., `try-catch` blocks for `IOException`, `JsonParseException`) is critical.
-   **Lazy Loading/Caching**: For very large datasets, consider loading data on demand or caching frequently used data to improve performance.
-   **Parameterization**: Integrate these data loading utilities with test frameworks like TestNG's `@DataProvider` or JUnit's `@ParameterizedTest` for data-driven testing.

## Common Pitfalls
-   **Hardcoding File Paths**: Avoid hardcoding absolute file paths. Use relative paths or configure paths via a properties file or environment variables.
-   **Mixing Data Parsing Logic with Test Logic**: Keep your test methods clean and focused on verification. Delegate all data loading and parsing to utility classes.
-   **Inefficient Data Structures**: Using incorrect Java Collections can lead to performance bottlenecks (e.g., frequent linear searches on large `List`s without `Map` for quick lookups).
-   **Ignoring Edge Cases**: Ensure your data loader handles empty files, malformed data, missing keys, and other edge cases gracefully.
-   **Lack of Readability**: If the keys in your `Map`s are obscure, tests using this data will be hard to understand. Use clear, descriptive names for your data fields.

## Interview Questions & Answers
1.  **Q: Why is externalizing test data important in automation frameworks?**
    **A:** Externalizing test data (e.g., in Excel, JSON, CSV, databases) separates test inputs from test logic. This offers several benefits:
    *   **Maintainability**: Changes to data don't require changes to code.
    *   **Reusability**: The same test logic can be run with different datasets.
    *   **Scalability**: Easily add more test cases by adding rows/records to the data file.
    *   **Readability**: Keeps test code clean and focused on test steps.
    *   **Collaboration**: Non-technical team members can often contribute to or review test data.

2.  **Q: When would you use `List<Map<String, String>>` versus just `Map<String, String>` for test data?**
    **A:**
    *   `Map<String, String>` is suitable for a single set of key-value pairs, representing one test record or a configuration. For example, storing user credentials for a single login attempt.
    *   `List<Map<String, String>>` is used when you have multiple test records, often for data-driven testing. Each `Map` in the `List` represents a distinct test case or row of data, making it ideal for scenarios like testing login with multiple valid/invalid users, product searches, or form submissions.

3.  **Q: How would you handle reading a large Excel file with thousands of rows efficiently?**
    **A:** For large files, efficiency is key.
    *   **Streaming APIs**: Instead of loading the entire file into memory, use streaming APIs (like Apache POI's SAX-based event API for `.xlsx` or CSV parsers) to process data row by row.
    *   **Lazy Loading**: Only load the data required for the current test or batch of tests, rather than the entire dataset at once.
    *   **Caching**: If certain data is frequently accessed, implement a caching mechanism (e.g., Guava Cache or a simple `HashMap`) to store it after the first read.
    *   **Database Integration**: For extremely large or complex datasets, consider storing test data in a database and querying it as needed.

4.  **Q: Discuss the challenges of managing test data and how your utility methods address them.**
    **A:**
    *   **Data Freshness**: Ensuring test data is always current and relevant. My utility provides a clear interface; in a real scenario, it would connect to a TDM system or generate fresh data.
    *   **Data Volume**: Handling large amounts of data. The current simulation is small, but the `List<Map>` structure is extensible for more records. Real implementation would need streaming.
    *   **Data Complexity**: Nested or varying data structures. JSON (and a more advanced JSON parser) handles this well.
    *   **Data Security/Privacy**: Sensitive data in test environments. This utility only simulates; real implementation would require masking or generating synthetic data.
    *   **Data Maintenance**: Keeping data synchronized with application changes. Centralizing the loader helps, as updates only happen in one place.
    My utility methods address the **structure** and **access** to data by providing consistent `List<Map>` and `Map` representations, simplifying how tests consume data. For other challenges, it provides a clear point of integration for more advanced solutions.

## Hands-on Exercise
1.  **Expand the `TestDataLoader`**: Modify the `getExcelTestData` method to simulate at least two more test cases, perhaps for different login scenarios (e.g., empty username, special characters in password).
2.  **Simulate a JSON Array**: Add a new method `getJsonArrayTestData(String fileName)` that returns a `List<Map<String, String>>`, simulating an array of JSON objects. Each `Map` in the list should represent one JSON object from the array. For example, data for multiple products or users.
3.  **Integrate with a Mock Test**: Create a simple TestNG test class (or a plain Java class with a `main` method) that uses the `TestDataLoader` to retrieve data and print it, simulating how a test would consume this data.

## Additional Resources
-   **Apache POI (for Excel)**: [https://poi.apache.org/](https://poi.apache.org/) - Official documentation for reading and writing Microsoft Office file formats.
-   **Jackson JSON Processor**: [https://github.com/FasterXML/jackson](https://github.com/FasterXML/jackson) - A popular library for JSON processing in Java.
-   **Google Gson**: [https://github.com/google/gson](https://github.com/google/gson) - Another widely used Java library to serialize and deserialize Java objects to/from JSON.
-   **Test Data Management Best Practices**: [https://www.tricentis.com/blog/test-data-management-strategy/](https://www.tricentis.com/blog/test-data-management-strategy/)
-   **Data-Driven Testing in TestNG**: [https://www.tutorialspoint.com/testng/testng_data_provider.htm](https://www.tutorialspoint.com/testng/testng_data_provider.htm)
