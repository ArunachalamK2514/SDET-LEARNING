# java-1.5-ac1.md

# Java Coding Practice: String Manipulation Algorithms

## Overview
String manipulation is a fundamental skill for any programmer and a frequent topic in technical interviews. As an SDET, you'll constantly work with strings, whether for parsing test data, validating UI text, constructing API requests, or analyzing log files. Mastering common string algorithms demonstrates strong problem-solving skills and a good command of the Java language. This guide covers three essential string manipulation tasks: reversing a string, checking for palindromes, and finding duplicate characters.

## Detailed Explanation

### 1. Reversing a String
Reversing a string is a classic problem with multiple solutions. The most common and efficient approach in Java is to use the `StringBuilder` or `StringBuffer` class, which are mutable sequences of characters.

**Example:**
- **Input:** "hello"
- **Output:** "olleh"

### 2. Palindrome Check
A palindrome is a word, phrase, number, or other sequence of characters that reads the same backward as forward. To check if a string is a palindrome, you can reverse it and see if it equals the original string. A more optimized approach is to use a two-pointer technique, comparing characters from the beginning and end of the string, moving inwards.

**Example:**
- **Input:** "madam" -> **Output:** `true`
- **Input:** "test" -> **Output:** `false`

When checking for palindromes, it's crucial to clarify requirements:
- Is the check case-sensitive? ("Madam" is not a palindrome if case-sensitive).
- Should whitespace and punctuation be ignored? ("A man, a plan, a canal: Panama" is a famous palindrome).

For robustness, it's best to normalize the string first by converting it to lowercase and removing non-alphanumeric characters.

### 3. Finding Duplicate Characters
This task involves identifying which characters appear more than once in a string. The most effective way to solve this is by using a `Map` (like `HashMap`) to store character counts. You iterate through the string, and for each character, you increment its count in the map. Afterward, you can iterate through the map to find characters with a count greater than one.

**Example:**
- **Input:** "automation"
- **Output:** 'a' (count 2), 'o' (count 2)

## Code Implementation
Here is a complete, runnable Java class demonstrating all three algorithms.

```java
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * A utility class for common string manipulation algorithms frequently asked in coding interviews.
 */
public class StringManipulationAlgorithms {

    /**
     * Reverses a string using StringBuilder.
     * Time Complexity: O(n) - where n is the length of the string.
     * Space Complexity: O(n) - as StringBuilder creates a copy of the string.
     *
     * @param str The string to reverse.
     * @return The reversed string.
     */
    public String reverseString(String str) {
        if (str == null) {
            return null;
        }
        return new StringBuilder(str).reverse().toString();
    }

    /**
     * Checks if a string is a palindrome using a two-pointer approach.
     * This implementation is case-insensitive and ignores non-alphanumeric characters.
     * Time Complexity: O(n) - where n is the length of the string.
     * Space Complexity: O(1) - as it operates in-place.
     *
     * @param str The string to check.
     * @return true if the string is a palindrome, false otherwise.
     */
    public boolean isPalindrome(String str) {
        if (str == null) {
            return false; // Or throw an exception based on requirements
        }

        // Normalize the string: convert to lowercase and remove non-alphanumeric chars
        String normalized = str.toLowerCase().replaceAll("[^a-z0-9]", "");

        int left = 0;
        int right = normalized.length() - 1;

        while (left < right) {
            if (normalized.charAt(left) != normalized.charAt(right)) {
                return false;
            }
            left++;
            right--;
        }
        return true;
    }

    /**
     * Finds and returns a map of duplicate characters and their counts.
     * Time Complexity: O(n) - where n is the length of the string (one pass to build the map).
     * Space Complexity: O(k) - where k is the number of unique characters in the string.
     *
     * @param str The string to analyze.
     * @return A map containing characters that appear more than once and their frequencies.
     */
    public Map<Character, Integer> findDuplicateCharacters(String str) {
        if (str == null || str.isEmpty()) {
            return new HashMap<>();
        }

        Map<Character, Integer> charCounts = new HashMap<>();
        for (char c : str.toCharArray()) {
            charCounts.put(c, charCounts.getOrDefault(c, 0) + 1);
        }

        // Filter the map to keep only characters with a count > 1
        return charCounts.entrySet().stream()
                .filter(entry -> entry.getValue() > 1)
                .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
    }

    public static void main(String[] args) {
        StringManipulationAlgorithms solver = new StringManipulationAlgorithms();

        // 1. Test String Reversal
        System.out.println("--- Testing String Reversal ---");
        String original = "Test Automation";
        String reversed = solver.reverseString(original);
        System.out.println("Original: '" + original + "'");
        System.out.println("Reversed: '" + reversed + "'");
        System.out.println();

        // 2. Test Palindrome Check
        System.out.println("--- Testing Palindrome Check ---");
        String p1 = "A man, a plan, a canal: Panama";
        String p2 = "Selenium";
        System.out.println("Is '" + p1 + "' a palindrome? " + solver.isPalindrome(p1)); // true
        System.out.println("Is '" + p2 + "' a palindrome? " + solver.isPalindrome(p2)); // false
        System.out.println();

        // 3. Test Finding Duplicate Characters
        System.out.println("--- Testing Duplicate Character Finder ---");
        String d1 = "sdet interview preparation";
        Map<Character, Integer> duplicates = solver.findDuplicateCharacters(d1);
        System.out.println("Duplicate characters in '" + d1 + "':");
        if (duplicates.isEmpty()) {
            System.out.println("None.");
        } else {
            duplicates.forEach((key, value) -> System.out.println("'" + key + "' appears " + value + " times."));
        }
    }
}
```

## Best Practices
- **Handle Null and Edge Cases:** Always check for `null` or empty strings to prevent `NullPointerException`.
- **Choose the Right Tool:** Use `StringBuilder` for string concatenation or modification in a single thread, as it's faster than `String` and `StringBuffer`.
- **Normalize Data:** When comparing strings (like in the palindrome check), normalize them by converting to a consistent case and removing irrelevant characters. This makes your logic more robust.
- **Understand Time/Space Complexity:** Be aware of the performance implications of your chosen algorithm. For example, using a two-pointer approach for palindrome checking is more memory-efficient than reversing the entire string.

## Common Pitfalls
- **Forgetting String Immutability:** Trying to modify a `String` object directly. Any "modification" to a `String` actually creates a new object. Using `StringBuilder` avoids this overhead.
- **Incorrect Palindrome Logic:** Failing to handle case sensitivity or special characters can lead to incorrect results. Always clarify these requirements with your interviewer.
- **Inefficient Duplicate Finding:** A brute-force approach with nested loops to find duplicates has a time complexity of O(n^2), which is highly inefficient. Using a `HashMap` is the standard, O(n) solution.

## Interview Questions & Answers
1.  **Q: You used `StringBuilder` to reverse the string. Could you do it without using any built-in reverse methods?**
    **A:** Yes. You can convert the string to a character array and use a two-pointer technique. Initialize one pointer at the beginning and one at the end. Swap the characters at these pointers and move the pointers towards the center until they meet or cross. This is an in-place reversal of the array, which you then convert back to a string. This demonstrates a deeper understanding of array manipulation.

2.  **Q: What is the difference between `StringBuilder` and `StringBuffer`? When would you use one over the other?**
    **A:** The main difference is thread safety. `StringBuffer`'s methods are `synchronized`, making it thread-safe but slower. `StringBuilder` is not thread-safe but is more performant. For SDETs, in most test automation scripts that run in a single thread, `StringBuilder` is the preferred choice. You would only use `StringBuffer` if you were manipulating a shared string resource across multiple threads, such as in a complex parallel testing utility.

3.  **Q: How would you modify your `findDuplicateCharacters` method to find the *first non-repeating* character instead?**
    **A:** I would use a `LinkedHashMap` to maintain the insertion order of characters while counting their frequencies. After populating the map by iterating through the string once, I would iterate through the map's `entrySet`. The first character I find with a count of 1 is the first non-repeating character in the original string. This is an efficient O(n) solution that requires two passes.

## Hands-on Exercise
1.  **Task:** Write a Java method `public boolean areAnagrams(String s1, String s2)` that checks if two strings are anagrams of each other.
2.  **Definition:** Anagrams are words or phrases formed by rearranging the letters of a different word or phrase (e.g., "listen" and "silent").
3.  **Requirements:**
    - The check should be case-insensitive.
    - It should ignore whitespace.
    - Handle null or different-length strings appropriately.
4.  **Hint:** Consider sorting the character arrays of the normalized strings or using a `HashMap` to count character frequencies.

## Additional Resources
- [GeeksforGeeks: Reverse a String in Java](https://www.geeksforgeeks.org/reverse-a-string-in-java/) - A great resource with multiple methods for string reversal.
- [Baeldung: Check if a String is a Palindrome](https://www.baeldung.com/java-palindrome) - Provides several robust methods for palindrome checking.
- [Java Revisited: How to find duplicate characters in a String?](https://www.java67.com/2014/03/how-to-find-duplicate-characters-in-String-Java-program.html) - A detailed article on different ways to find duplicates.
---
# java-1.5-ac2.md

# Java Coding Practice: Essential Array Operations

## Overview
Array operations are a cornerstone of programming and a very common subject in technical interviews for SDETs. Proficiency in manipulating arrays demonstrates a solid understanding of data structures, algorithms, and complexity analysis. This guide covers three critical array operations: finding the largest and second-largest elements, removing duplicates, and finding a missing number in a sequence. These tasks are essential for data validation, test result analysis, and general problem-solving.

## Detailed Explanation & Code Implementation

### 1. Find Largest and Second-Largest Number
A common requirement is to find the top two values in a dataset. A naive approach would be to sort the array and pick the last two elements, but this is inefficient (typically O(n log n)). A much better solution is to iterate through the array once, keeping track of the two largest numbers found so far.

**Logic:**
1. Initialize `largest` and `secondLargest` to the smallest possible integer value.
2. Iterate through the array.
3. If the current element is greater than `largest`, update `secondLargest` to the old `largest`, and update `largest` to the current element.
4. Else, if the current element is greater than `secondLargest` (but not `largest`), update `secondLargest`.

```java
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

public class ArrayManipulationAlgorithms {

    /**
     * Finds the largest and second-largest numbers in an integer array in a single pass.
     * Time Complexity: O(n) - where n is the number of elements in the array.
     * Space Complexity: O(1) - constant space is used.
     *
     * @param arr The input integer array. Must contain at least two elements.
     * @return An array of two integers: {largest, secondLargest}.
     */
    public int[] findLargestAndSecondLargest(int[] arr) {
        if (arr == null || arr.length < 2) {
            throw new IllegalArgumentException("Input array must contain at least two elements.");
        }

        int largest = Integer.MIN_VALUE;
        int secondLargest = Integer.MIN_VALUE;

        for (int currentNumber : arr) {
            if (currentNumber > largest) {
                secondLargest = largest;
                largest = currentNumber;
            } else if (currentNumber > secondLargest && currentNumber != largest) {
                secondLargest = currentNumber;
            }
        }
        return new int[]{largest, secondLargest};
    }

    /**
     * Removes duplicate elements from an array using a HashSet.
     * Note: This does not preserve the original order of elements.
     * Time Complexity: O(n) - as each element is added to the set once.
     * Space Complexity: O(n) - in the worst case, all elements are unique and stored in the set.
     *
     * @param arr The input array with duplicates.
     * @return A new array with only unique elements.
     */
    public int[] removeDuplicatesUsingSet(int[] arr) {
        if (arr == null) {
            return null;
        }
        Set<Integer> uniqueElements = new HashSet<>();
        for (int num : arr) {
            uniqueElements.add(num);
        }
        return uniqueElements.stream().mapToInt(Integer::intValue).toArray();
    }
    
    /**
     * Removes duplicate elements from an array using Java 8 Streams.
     * This preserves the original order of elements.
     * Time Complexity: O(n)
     * Space Complexity: O(n)
     *
     * @param arr The input array with duplicates.
     * @return A new array with only unique elements, order preserved.
     */
    public int[] removeDuplicatesUsingStream(int[] arr) {
        if (arr == null) {
            return null;
        }
        return Arrays.stream(arr).distinct().toArray();
    }


    /**
     * Finds the missing number in a sequence of n-1 integers from a range of 1 to n.
     * This method uses the sum formula for an arithmetic series.
     * Time Complexity: O(n) - for the initial summation of the array elements.
     * Space Complexity: O(1) - no extra space is needed.
     *
     * @param arr An array containing n-1 distinct numbers from 1 to n.
     * @param n The total number of elements that should be in the sequence.
     * @return The missing integer.
     */
    public int findMissingNumber(int[] arr, int n) {
        if (arr == null) {
            throw new IllegalArgumentException("Input array cannot be null.");
        }
        // Formula for the sum of the first n natural numbers
        int expectedSum = n * (n + 1) / 2;
        
        int actualSum = 0;
        for (int num : arr) {
            actualSum += num;
        }

        return expectedSum - actualSum;
    }

    public static void main(String[] args) {
        ArrayManipulationAlgorithms solver = new ArrayManipulationAlgorithms();

        // 1. Test Find Largest and Second-Largest
        System.out.println("--- Testing Find Largest and Second-Largest ---");
        int[] numbers = {10, 5, 20, 8, 15, 20};
        int[] topTwo = solver.findLargestAndSecondLargest(numbers);
        System.out.println("Array: " + Arrays.toString(numbers));
        System.out.println("Largest: " + topTwo[0] + ", Second-Largest: " + topTwo[1]);
        System.out.println();

        // 2. Test Remove Duplicates
        System.out.println("--- Testing Remove Duplicates ---");
        int[] duplicatesArray = {4, 3, 2, 4, 9, 2};
        int[] uniqueArraySet = solver.removeDuplicatesUsingSet(duplicatesArray);
        int[] uniqueArrayStream = solver.removeDuplicatesUsingStream(duplicatesArray);
        System.out.println("Original Array: " + Arrays.toString(duplicatesArray));
        System.out.println("Unique (Set): " + Arrays.toString(uniqueArraySet)); // Order not guaranteed
        System.out.println("Unique (Stream): " + Arrays.toString(uniqueArrayStream)); // Order preserved
        System.out.println();

        // 3. Test Find Missing Number
        System.out.println("--- Testing Find Missing Number ---");
        int n = 8;
        int[] sequence = {1, 2, 4, 6, 3, 7, 8}; // Missing 5
        int missingNumber = solver.findMissingNumber(sequence, n);
        System.out.println("Sequence (1 to " + n + "): " + Arrays.toString(sequence));
        System.out.println("Missing number is: " + missingNumber);
    }
}
```

### 2. Remove Duplicates from an Array
There are several ways to remove duplicates. The most common and readable methods involve using a `HashSet` or Java 8 Streams.

- **Using `HashSet`:** A `Set` is a collection that cannot contain duplicate elements. By iterating through the array and adding each element to a `HashSet`, you automatically handle duplicates. This is very efficient but does not preserve the original order of the elements.
- **Using Java 8 Streams:** The `stream().distinct().toArray()` chain provides a clean, functional approach. It is highly readable and preserves the original order of the elements.

### 3. Find the Missing Number in a Sequence
Given an array of `n-1` distinct integers from a range of `1` to `n`, the goal is to find the single missing integer.

- **Summation Method:** The most elegant solution involves mathematics. Calculate the expected sum of the first `n` natural numbers using the formula `n * (n + 1) / 2`. Then, calculate the actual sum of the elements in the given array. The difference between the expected sum and the actual sum is the missing number.
- **XOR Method:** A more advanced approach uses the XOR bitwise operator. XOR all numbers from 1 to `n`, and then XOR all elements in the array. The final result will be the missing number because `x ^ x = 0` and `x ^ 0 = x`. This method is highly efficient and avoids potential integer overflow if `n` is very large.

## Best Practices
- **Analyze Time and Space Complexity:** Always state the complexity of your solution. The single-pass O(n) solution for finding the largest numbers is vastly superior to an O(n log n) sorting approach.
- **Use the Right Data Structure:** Leveraging the properties of a `HashSet` to eliminate duplicates is a prime example of using the right tool for the job.
- **Prefer Readability:** The Java 8 Stream `distinct()` method is often preferred for removing duplicates because it's concise and clearly states its intent.
- **Consider Edge Cases:** What if the array is empty? What if it's `null`? What if it contains duplicates when you expect it not to? A production-ready solution handles these gracefully.

## Common Pitfalls
- **Inefficient Sorting:** Don't sort an array unless you absolutely need a fully ordered collection. For problems like finding the top `k` elements, there are often more efficient algorithms.
- **Ignoring Edge Cases:** For the "second-largest" problem, failing to handle an array with fewer than two elements or an array where all elements are the same can lead to errors.
- **Integer Overflow:** In the "missing number" problem, the summation method can lead to an integer overflow if `n` is very large. The XOR method is safer in such scenarios.

## Interview Questions & Answers
1.  **Q: Your `findLargestAndSecondLargest` method works well. How would you generalize it to find the k-th largest element?**
    **A:** For finding the k-th largest element, there are a few standard approaches. A simple one is to sort the array and return the element at index `length - k`, which is O(n log n). A more optimal approach is to use a Min-Heap (a `PriorityQueue` in Java). We can maintain a heap of size `k`. Iterate through the array; if the heap has fewer than `k` elements, add the current element. Otherwise, if the current element is larger than the smallest element in the heap (the root), remove the root and add the current element. After the loop, the root of the heap is the k-th largest element. This approach has a time complexity of O(n log k).

2.  **Q: You used a `HashSet` to remove duplicates, which doesn't preserve order. How would you remove duplicates while preserving the original order of the array?**
    **A:** The Java 8 Stream API with `distinct()` is the most straightforward way, as it preserves order. Alternatively, one could use a `LinkedHashSet`, which is a `Set` implementation that maintains the insertion order of elements. By adding all array elements to a `LinkedHashSet` and then converting it back to an array, we get a collection of unique elements in their original order.

3.  **Q: For `findMissingNumber`, you used the summation formula. What is an alternative, and why might it be better?**
    **A:** An alternative is the XOR method. You calculate the XOR sum of all numbers from 1 to `n`. Then, you calculate the XOR sum of all elements in the input array. Finally, you XOR these two results. Since any number XOR'd with itself is 0, all numbers present in both sequences will cancel out, leaving only the missing number. This method is often considered better because it avoids the risk of integer overflow that can occur with the summation method if `n` is extremely large.

## Hands-on Exercise
1.  **Task:** Given an integer array, move all the zeros to the end of the array while maintaining the relative order of the non-zero elements.
2.  **Example:**
    - **Input:** `{0, 1, 0, 3, 12}`
    - **Output:** `{1, 3, 12, 0, 0}`
3.  **Constraint:** You must do this in-place without making a copy of the array.
4.  **Hint:** Use a two-pointer approach. One pointer can be used to track the position of the next non-zero element.

## Additional Resources
- [Baeldung: Find the Missing Number in an Array](https://www.baeldung.com/java-find-missing-number-in-array) - Covers both the summation and XOR methods.
- [GeeksforGeeks: Find the largest three elements in an array](https://www.geeksforgeeks.org/find-the-largest-three-elements-in-an-array/) - A good extension of the largest/second-largest problem.
- [Java Docs: The `Arrays` Class](https://docs.oracle.com/javase/8/docs/api/java/util/Arrays.html) - Official documentation for array utility methods, a must-read for any Java developer.
---
# java-1.5-ac3.md

# Java Coding Practice: Fibonacci Series (Recursion vs. Iteration)

## Overview
The Fibonacci series is a sequence where each number is the sum of the two preceding ones, usually starting with 0 and 1. It's a classic computer science problem used to teach and evaluate understanding of two fundamental concepts: iteration and recursion. For an SDET, solving this problem demonstrates logical thinking and an ability to analyze and compare different algorithmic approaches, which is crucial for writing efficient and scalable test code.

**The sequence:** 0, 1, 1, 2, 3, 5, 8, 13, 21, ...

## Detailed Explanation & Code Implementation

### 1. Iterative Approach
The iterative approach uses a loop to build the sequence from the bottom up. It's generally the most efficient way to calculate the n-th Fibonacci number in terms of both time and space.

**Logic:**
1. Handle the base cases: if `n` is 0 or 1, return `n`.
2. Initialize three variables: `a = 0`, `b = 1`, and `c` to store the sum.
3. Loop from 2 up to `n`. In each iteration, calculate `c = a + b`, then update `a` to `b` and `b` to `c`.
4. After the loop, `b` will hold the n-th Fibonacci number.

```java
public class Fibonacci {

    /**
     * Calculates the n-th Fibonacci number using an iterative (bottom-up) approach.
     * Time Complexity: O(n) - The loop runs n times.
     * Space Complexity: O(1) - Uses a fixed number of variables.
     *
     * @param n The position in the Fibonacci sequence (0-based).
     * @return The n-th Fibonacci number.
     */
    public long fibonacciIterative(int n) {
        if (n < 0) {
            throw new IllegalArgumentException("Input cannot be negative.");
        }
        if (n <= 1) {
            return n;
        }

        long a = 0;
        long b = 1;

        for (int i = 2; i <= n; i++) {
            long temp = a + b;
            a = b;
            b = temp;
        }
        return b;
    }
}
```

### 2. Recursive Approach
The recursive approach defines the Fibonacci number in terms of itself. It's often more intuitive and closer to the mathematical definition: `F(n) = F(n-1) + F(n-2)`.

**Logic:**
1.  Define the base cases: if `n` is 0 or 1, return `n`.
2.  For any other `n`, the function calls itself for `n-1` and `n-2` and returns their sum.

While elegant, this naive recursive solution is highly inefficient due to redundant calculations. For example, to calculate `fib(5)`, it calculates `fib(3)` twice, `fib(2)` three times, and so on.

```java
public class Fibonacci {
    /**
     * Calculates the n-th Fibonacci number using a recursive approach.
     * WARNING: This is highly inefficient for n > 40.
     * Time Complexity: O(2^n) - Exponential, due to recalculating the same values.
     * Space Complexity: O(n) - Due to the depth of the recursion stack.
     *
     * @param n The position in the Fibonacci sequence.
     * @return The n-th Fibonacci number.
     */
    public long fibonacciRecursive(int n) {
        if (n < 0) {
            throw new IllegalArgumentException("Input cannot be negative.");
        }
        if (n <= 1) {
            return n;
        }
        return fibonacciRecursive(n - 1) + fibonacciRecursive(n - 2);
    }
}
```

### 3. Recursive Approach with Memoization
To overcome the inefficiency of the naive recursive approach, we can use memoization (a form of dynamic programming). We store the results of expensive function calls (Fibonacci numbers we've already calculated) and return the cached result when the same inputs occur again.

**Logic:**
1.  Use a `Map` or an array to act as a cache.
2.  Before computing `fib(n)`, check if the result is already in the cache.
3.  If it is, return the cached value.
4.  If not, compute it, store it in the cache, and then return it.

```java
import java.util.HashMap;
import java.util.Map;

public class Fibonacci {

    // Cache for memoization
    private final Map<Integer, Long> memo = new HashMap<>();

    /**
     * Calculates the n-th Fibonacci number using recursion with memoization.
     * Time Complexity: O(n) - Each Fibonacci number is computed only once.
     * Space Complexity: O(n) - For the recursion stack and the memoization map.
     *
     * @param n The position in the Fibonacci sequence.
     * @return The n-th Fibonacci number.
     */
    public long fibonacciRecursiveWithMemo(int n) {
        if (n < 0) {
            throw new IllegalArgumentException("Input cannot be negative.");
        }
        if (n <= 1) {
            return n;
        }
        // Check if the value is already in the cache
        if (memo.containsKey(n)) {
            return memo.get(n);
        }
        
        // Compute, store in cache, and then return
        long result = fibonacciRecursiveWithMemo(n - 1) + fibonacciRecursiveWithMemo(n - 2);
        memo.put(n, result);
        return result;
    }
}
```

## Performance & Stack Usage Comparison

| Approach                      | Time Complexity | Space Complexity | Performance (for n=45) | Stack Usage      |
| ----------------------------- | --------------- | ---------------- | ----------------------- | ---------------- |
| **Iterative**                 | O(n)            | O(1)             | Excellent (instant)     | Minimal (O(1))   |
| **Naive Recursive**           | O(2^n)          | O(n)             | Extremely Poor (minutes)| Deep (O(n))      |
| **Recursive with Memoization**| O(n)            | O(n)             | Excellent (instant)     | Deep (O(n))      |

**Stack Usage:** The recursive approaches can lead to a `StackOverflowError` for very large values of `n` because each function call is added to the call stack. The iterative approach avoids this completely, making it the safest and most scalable solution.

## Best Practices
- **Prefer Iteration for Performance:** For simple sequential problems like Fibonacci, the iterative solution is almost always superior in performance and memory usage.
- **Use Memoization for Complex Recursion:** If a problem is naturally recursive and involves overlapping subproblems, use memoization to make it efficient. This is the core idea behind dynamic programming.
- **Handle Edge Cases:** Always check for invalid inputs, such as negative numbers, and handle the base cases (0 and 1) correctly.
- **Use `long` for Results:** The Fibonacci sequence grows very quickly. Using `long` instead of `int` prevents integer overflow for `n` up to 92.

## Common Pitfalls
- **Using Naive Recursion in Production:** Implementing a naive O(2^n) recursive solution for Fibonacci in an interview or production code is a major red flag, as it shows a lack of awareness of performance implications.
- **Forgetting Base Cases:** Incorrectly defining or missing the base cases (`n=0` and `n=1`) in a recursive solution will lead to infinite recursion and a `StackOverflowError`.
- **Integer Overflow:** Not using a large enough data type (like `long`) will produce incorrect results for `n > 46`.

## Interview Questions & Answers
1.  **Q: You've shown three ways to solve this. Which one would you choose to use in a production environment and why?**
    **A:** I would choose the **iterative approach**. It has the best performance characteristics with O(n) time complexity and O(1) space complexity. It's simple to understand, easy to debug, and doesn't run the risk of causing a `StackOverflowError` for large inputs, making it the most robust and scalable solution for a production environment.

2.  **Q: Can you explain what a `StackOverflowError` is and why the naive recursive solution is likely to cause it?**
    **A:** A `StackOverflowError` is a runtime error that occurs when a program exhausts its call stack space. Each time a method is called, a new "stack frame" is pushed onto the call stack to store local variables and the return address. In the naive recursive Fibonacci solution, `fib(n)` calls `fib(n-1)` and `fib(n-2)`, leading to a deep chain of nested method calls. For a large `n`, this chain becomes so deep that it exceeds the memory allocated for the stack, causing the error.

3.  **Q: Besides Fibonacci, can you name another problem where comparing iterative and recursive solutions (especially with memoization) is common?**
    **A:** A classic example is calculating the **Factorial** of a number. Like Fibonacci, it can be solved with a simple loop (iteration) or a recursive function `fact(n) = n * fact(n-1)`. Another common interview problem is the "Climbing Stairs" problem, where you have to find the number of distinct ways to climb `n` stairs if you can take either 1 or 2 steps at a time. This problem is a direct application of the Fibonacci sequence.

## Hands-on Exercise
1.  **Task:** Write a method that prints the first `k` numbers of the Fibonacci sequence.
2.  **Method Signature:** `public void printFibonacciSequence(int k)`
3.  **Example:** `printFibonacciSequence(10)` should print: `0, 1, 1, 2, 3, 5, 8, 13, 21, 34`
4.  **Requirement:** Implement this using the efficient iterative approach.

## Additional Resources
- [GeeksforGeeks: Program for Fibonacci Numbers](https://www.geeksforgeeks.org/program-for-nth-fibonacci-number/) - A comprehensive article covering multiple approaches, including matrix exponentiation for an O(log n) solution.
- [Baeldung: Fibonacci Numbers in Java](https://www.baeldung.com/java-fibonacci) - Clear explanations of iterative, recursive, and dynamic programming solutions.
- [YouTube: Dynamic Programming - Fibonacci Sequence](https://www.youtube.com/watch?v=oBt53YbR9Kk) - A great visual explanation of why naive recursion is slow and how memoization fixes it.
---
# java-1.5-ac4.md

# Factorial Calculation Using Recursion

## Overview
Factorial calculation is a fundamental mathematical concept often used to introduce recursion in programming. For a non-negative integer `n`, the factorial of `n` (denoted as `n!`) is the product of all positive integers less than or equal to `n`. For example, `5! = 5 * 4 * 3 * 2 * 1 = 120`. The factorial of 0 is defined as 1 (`0! = 1`). In test automation, while not directly used in day-to-day scripting, understanding recursive solutions like factorial is crucial for improving logical thinking, problem-solving skills, and preparing for coding interviews that assess algorithmic proficiency. This document focuses on implementing factorial calculation using a recursive approach in Java.

## Detailed Explanation
Recursion is a programming technique where a function calls itself to solve a smaller instance of the same problem. To solve a problem recursively, two main conditions must be met:
1.  **Base Case**: A stopping condition that does not involve further recursion. Without a base case, the recursion would run indefinitely, leading to a `StackOverflowError`. For factorial, the base cases are `0! = 1` and `1! = 1`.
2.  **Recursive Step**: The step where the function calls itself with a smaller input, moving closer to the base case. For `n > 1`, `n! = n * (n-1)!`.

Let's break down the recursive factorial:
- If `n` is 0 or 1, the result is 1 (base case).
- If `n` is greater than 1, the function returns `n` multiplied by the factorial of `n-1`. This `factorial(n-1)` is the recursive call, reducing the problem size until it hits the base case.

**Example Walkthrough for `factorial(3)`:**
1.  `factorial(3)` is called. Since `3 > 1`, it returns `3 * factorial(2)`.
2.  `factorial(2)` is called. Since `2 > 1`, it returns `2 * factorial(1)`.
3.  `factorial(1)` is called. This is a base case, so it returns `1`.
4.  The call to `factorial(2)` now resolves to `2 * 1 = 2`.
5.  The call to `factorial(3)` now resolves to `3 * 2 = 6`.

This process builds up the solution from the base case.

## Code Implementation

```java
public class FactorialCalculator {

    /**
     * Calculates the factorial of a non-negative integer using recursion.
     *
     * @param n The non-negative integer for which to calculate the factorial.
     * @return The factorial of n.
     * @throws IllegalArgumentException if n is negative.
     */
    public long calculateFactorial(int n) {
        // Step 1: Handle invalid input (negative numbers)
        if (n < 0) {
            throw new IllegalArgumentException("Factorial is not defined for negative numbers. Input: " + n);
        }

        // Step 2 & 3: Implement base case for recursion (0! = 1, 1! = 1)
        // This is the stopping condition for the recursion.
        if (n == 0 || n == 1) {
            return 1;
        }

        // Step 3: Recursive step: n! = n * (n-1)!
        // The method calls itself with a smaller input (n-1), moving towards the base case.
        return n * calculateFactorial(n - 1);
    }

    public static void main(String[] args) {
        FactorialCalculator calculator = new FactorialCalculator();

        // Test with boundary values and valid inputs
        System.out.println("Factorial of 0: " + calculator.calculateFactorial(0));   // Expected: 1
        System.out.println("Factorial of 1: " + calculator.calculateFactorial(1));   // Expected: 1
        System.out.println("Factorial of 5: " + calculator.calculateFactorial(5));   // Expected: 120
        System.out.println("Factorial of 10: " + calculator.calculateFactorial(10)); // Expected: 3628800

        // Test with a larger value (be cautious with long data type limits)
        System.out.println("Factorial of 20: " + calculator.calculateFactorial(20)); // Expected: 2432902008176640000

        // Test with invalid input (negative number)
        try {
            System.out.println("Factorial of -3: " + calculator.calculateFactorial(-3));
        } catch (IllegalArgumentException e) {
            System.err.println("Error for -3: " + e.getMessage());
        }

        // Demonstrate potential StackOverflowError for very large inputs
        // Be careful when uncommenting and running this, as it might crash your program
        // try {
        //     System.out.println("Factorial of 100000: " + calculator.calculateFactorial(100000));
        // } catch (StackOverflowError e) {
        //     System.err.println("Error for 100000: StackOverflowError - recursion depth limit reached.");
        // }
    }
}
```

## Best Practices
-   **Define Clear Base Cases**: Always ensure your recursive function has one or more base cases that correctly terminate the recursion.
-   **Ensure Progress Towards Base Case**: Each recursive call must simplify the problem, moving closer to the base case, to avoid infinite recursion.
-   **Handle Invalid Inputs**: Validate input parameters to prevent unexpected behavior (e.g., negative numbers for factorial).
-   **Consider Stack Depth**: Be aware of the maximum recursion depth. Deep recursion can lead to `StackOverflowError`. For problems requiring very deep recursion, an iterative solution might be more appropriate or techniques like memoization/tail recursion optimization (if supported by the language/compiler) should be considered.
-   **Choose `long` for Factorial**: Factorial values grow very rapidly. Use `long` to accommodate larger results, though even `long` has limits (e.g., `20!` is the largest factorial that fits in a `long`). For larger numbers, `BigInteger` is required.

## Common Pitfalls
-   **Missing Base Case**: The most common pitfall, leading to infinite recursion and `StackOverflowError`.
-   **Incorrect Base Case**: A base case that doesn't provide the correct terminal value will lead to incorrect results for all subsequent calculations.
-   **No Progress Towards Base Case**: If the recursive call does not reduce the problem size, it also results in infinite recursion.
-   **Stack Overflow**: Even with correct logic, extremely large inputs can exhaust the call stack, leading to a `StackOverflowError`.
-   **Performance Overhead**: Recursive calls typically incur more overhead (function call stack management) than iterative loops, which can impact performance for certain problems.

## Interview Questions & Answers
1.  **Q: Explain the concept of recursion and its two main components.**
    **A:** Recursion is a programming technique where a function calls itself to solve a problem. Its two main components are:
    *   **Base Case**: The condition that stops the recursion. It's the simplest form of the problem that can be solved directly without further calls.
    *   **Recursive Step**: The part where the function calls itself with a modified (usually smaller or simpler) input, moving closer to the base case.

2.  **Q: When would you choose a recursive solution over an iterative one, and vice-versa?**
    **A:**
    *   **Choose Recursion when**: The problem naturally breaks down into smaller, self-similar subproblems (e.g., tree traversals, certain sorting algorithms like quicksort/mergesort, fractal generation). Recursive code can often be more concise and easier to read for such problems.
    *   **Choose Iteration when**: Performance is critical, or the problem involves very deep recursion that might lead to a `StackOverflowError`. Iterative solutions typically have less overhead and better memory efficiency. Many recursive problems can be converted to iterative ones using a stack data structure.

3.  **Q: What is a `StackOverflowError` in the context of recursion? How can it be prevented?**
    **A:** A `StackOverflowError` occurs when a recursive function calls itself too many times without reaching a base case, or if the base case is never met. Each function call adds a frame to the call stack. If the stack grows beyond its allocated memory limit, this error is thrown.
    It can be prevented by:
    *   Ensuring a correct and reachable base case.
    *   Guaranteeing that each recursive call makes progress towards the base case.
    *   For very large inputs, converting the recursive solution to an iterative one or using techniques like memoization to reduce redundant calls.

## Hands-on Exercise
**Problem**: Implement a recursive function to calculate the sum of digits of a given non-negative integer.

**Example**:
- `sumDigits(123)` should return `1 + 2 + 3 = 6`
- `sumDigits(45)` should return `4 + 5 = 9`
- `sumDigits(7)` should return `7`
- `sumDigits(0)` should return `0`

**Steps**:
1.  Define the base case: What is the sum of digits for a single-digit number (0-9)?
2.  Define the recursive step: How can you break down a multi-digit number into a smaller number plus its last digit? (Hint: modulo and division operators).
3.  Implement the `sumDigits` method recursively.
4.  Write `main` method to test with various inputs, including boundary conditions.

## Additional Resources
-   **GeeksforGeeks - Recursion in Java**: [https://www.geeksforgeeks.org/recursion-in-java/](https://wwweksforgeeks.org/recursion-in-java/)
-   **Baeldung - Guide to Java Recursion**: [https://www.baeldung.com/java-recursion](https://www.baeldung.com/java-recursion)
-   **TutorialsPoint - Java Factorial Program**: [https://www.tutorialspoint.com/java-program-to-find-the-factorial-of-a-number](https://www.tutorialspoint.com/java-program-to-find-the-factorial-of-a-number)
---
# java-1.5-ac5.md

# Swap Two Numbers Without a Third Variable

## Overview
Swapping the values of two variables is a fundamental operation in programming. While typically a temporary third variable is used, in Java (and many other languages), it's possible to achieve this swap without allocating extra memory for a third variable. This technique is often encountered in coding interviews to assess a candidate's problem-solving skills and understanding of arithmetic or bitwise operations. For SDETs, while not directly applicable to day-to-day automation, it reinforces foundational logic and can be useful in specific scenarios like optimizing utility methods or understanding algorithms.

## Detailed Explanation

There are primarily two common methods to swap two numbers without using a third variable:

1.  **Using Arithmetic Operators (+ and -)**: This method leverages basic addition and subtraction. It works by storing the sum of the two numbers in one variable, then subtracting the original value of the other number to derive its new value.

    *   **Step 1:** `a = a + b;` (Now `a` holds the sum of original `a` and `b`)
    *   **Step 2:** `b = a - b;` (Since `a` is `(original_a + original_b)`, `(original_a + original_b) - original_b` gives `original_a`. So `b` now holds the original value of `a`.)
    *   **Step 3:** `a = a - b;` (Since `b` now holds `original_a`, and `a` still holds `(original_a + original_b)`, `(original_a + original_b) - original_a` gives `original_b`. So `a` now holds the original value of `b`.)

    **Important Consideration:** This method can lead to an arithmetic overflow if the sum `a + b` exceeds the maximum value that the data type can hold (e.g., `Integer.MAX_VALUE`). This is a critical pitfall to be aware of.

2.  **Using Bitwise XOR Operator (^)**: The XOR (exclusive OR) operator is a bitwise operator that returns `1` if the bits are different and `0` if they are the same. A key property of XOR is that `A ^ B ^ B = A`. This property allows for an elegant three-step swap.

    *   **Step 1:** `a = a ^ b;` (`a` now holds the XOR sum of original `a` and `b`)
    *   **Step 2:** `b = a ^ b;` (Since `a` is `(original_a ^ original_b)`, then `(original_a ^ original_b) ^ original_b` evaluates to `original_a`. So `b` now holds the original value of `a`.)
    *   **Step 3:** `a = a ^ b;` (Since `b` now holds `original_a`, and `a` still holds `(original_a ^ original_b)`, then `(original_a ^ original_b) ^ original_a` evaluates to `original_b`. So `a` now holds the original value of `b`.)

    **Advantage:** This method does not suffer from the overflow issues that the arithmetic method might. It works well with integer types.

## Code Implementation

```java
import java.util.Arrays;

public class NumberSwapper {

    /**
     * Swaps two numbers using arithmetic operators (+ and -).
     *
     * @param nums An array containing two integers to be swapped.
     *             The array will be modified in place.
     * @throws IllegalArgumentException if the array does not contain exactly two elements.
     * @throws ArithmeticException if an arithmetic overflow occurs during addition.
     */
    public static void swapUsingArithmetic(int[] nums) {
        if (nums == null || nums.length != 2) {
            throw new IllegalArgumentException("Input array must contain exactly two numbers.");
        }

        System.out.println("Before swap (Arithmetic): a = " + nums[0] + ", b = " + nums[1]);

        long sum = (long) nums[0] + nums[1]; // Use long to detect potential overflow
        if (sum > Integer.MAX_VALUE || sum < Integer.MIN_VALUE) {
            // This is a simplified check. More robust check would involve checking signs.
            // If nums[0] and nums[1] are both positive, and their sum exceeds MAX_VALUE, it overflows.
            // If nums[0] and nums[1] are both negative, and their sum goes below MIN_VALUE, it overflows.
            // If they have different signs, overflow is less likely unless one is very large and the other very small.
            // For simplicity, we assume basic positive integer overflow here.
            System.err.println("Warning: Potential arithmetic overflow if sum exceeds int limits.");
            // Or throw new ArithmeticException("Arithmetic overflow during swap operation.");
        }

        // Perform the swap
        nums[0] = nums[0] + nums[1]; // a becomes original_a + original_b
        nums[1] = nums[0] - nums[1]; // b becomes (original_a + original_b) - original_b = original_a
        nums[0] = nums[0] - nums[1]; // a becomes (original_a + original_b) - original_a = original_b

        System.out.println("After swap (Arithmetic): a = " + nums[0] + ", b = " + nums[1]);
    }

    /**
     * Swaps two numbers using the bitwise XOR operator (^).
     *
     * @param nums An array containing two integers to be swapped.
     *             The array will be modified in place.
     * @throws IllegalArgumentException if the array does not contain exactly two elements.
     */
    public static void swapUsingXOR(int[] nums) {
        if (nums == null || nums.length != 2) {
            throw new IllegalArgumentException("Input array must contain exactly two numbers.");
        }

        System.out.println("Before swap (XOR): a = " + nums[0] + ", b = " + nums[1]);

        // Perform the swap
        nums[0] = nums[0] ^ nums[1]; // a becomes original_a XOR original_b
        nums[1] = nums[0] ^ nums[1]; // b becomes (original_a XOR original_b) XOR original_b = original_a
        nums[0] = nums[0] ^ nums[1]; // a becomes (original_a XOR original_b) XOR original_a = original_b

        System.out.println("After swap (XOR): a = " + nums[0] + ", b = " + nums[1]);
    }

    public static void main(String[] args) {
        // Example 1: Arithmetic swap
        int[] arr1 = {5, 10};
        swapUsingArithmetic(arr1); // Expected: a=10, b=5

        System.out.println("\n--------------------------\n");

        // Example 2: XOR swap
        int[] arr2 = {-3, 7};
        swapUsingXOR(arr2); // Expected: a=7, b=-3

        System.out.println("\n--------------------------\n");

        // Example 3: Edge case - zero
        int[] arr3 = {0, 99};
        swapUsingArithmetic(arr3); // Expected: a=99, b=0

        System.out.println("\n--------------------------\n");

        // Example 4: Edge case - negative numbers
        int[] arr4 = {-10, -20};
        swapUsingXOR(arr4); // Expected: a=-20, b=-10

        System.out.println("\n--------------------------\n");

        // Example 5: Potential overflow scenario (for arithmetic swap)
        // int a = Integer.MAX_VALUE; // 2147483647
        // int b = 1;
        // int[] arr5 = {a, b};
        // swapUsingArithmetic(arr5); // This would cause overflow with simple int arithmetic
        // The current implementation uses long for sum calculation to show potential issue, but direct
        // modification of int variables would still overflow.
        // For demonstration, let's show an overflow:
        try {
            int maxVal = Integer.MAX_VALUE - 5; // A value close to MAX_VALUE
            int otherVal = 10;
            int[] arr5_overflow = {maxVal, otherVal};
            System.out.println("Before swap (Arithmetic with potential overflow): a = " + arr5_overflow[0] + ", b = " + arr5_overflow[1]);
            arr5_overflow[0] = arr5_overflow[0] + arr5_overflow[1]; // This will overflow
            arr5_overflow[1] = arr5_overflow[0] - arr5_overflow[1];
            arr5_overflow[0] = arr5_overflow[0] - arr5_overflow[1];
            System.out.println("After swap (Arithmetic with overflow): a = " + arr5_overflow[0] + ", b = " + arr5_overflow[1] + " (Values might be unexpected due to overflow)");
        } catch (Exception e) {
            System.err.println("Caught an unexpected exception during arithmetic overflow test: " + e.getMessage());
        }

        System.out.println("\n--------------------------\n");

        // Example 6: Identical numbers
        int[] arr6 = {100, 100};
        swapUsingXOR(arr6); // Expected: a=100, b=100
        System.out.println("\n--------------------------\n");
        int[] arr7 = {100, 100};
        swapUsingArithmetic(arr7); // Expected: a=100, b=100
    }
}
```

## Best Practices
-   **Understand Data Type Limits:** Always be mindful of potential arithmetic overflow when using the `+` and `-` method, especially with large numbers or when dealing with integer types close to their `MAX_VALUE` or `MIN_VALUE`. For the XOR method, this is generally not an issue as XOR operates bit by bit.
-   **Clarity over Trickery:** In most production code, using a temporary variable for swapping is more readable and less prone to subtle bugs (like self-swapping issues in some languages, though not typically Java). Optimize for readability unless profiling explicitly indicates a performance bottleneck that this optimization solves.
-   **Immutability:** Be aware that primitive `int` types are passed by value in Java. To swap values that are effectively "outside" the method call, you need to either return a new array/object or pass a mutable container (like an array or a custom wrapper object). The examples use an `int[]` to demonstrate in-place modification.

## Common Pitfalls
-   **Arithmetic Overflow:** As mentioned, `a = a + b` can exceed the `int` data type's maximum value, leading to incorrect results if not handled. This is the most significant pitfall of the arithmetic method.
-   **Self-Swapping (Less common in Java):** In some languages, if `a` and `b` refer to the *same memory location*, the XOR swap (`a = a ^ b; b = a ^ b; a = a ^ b;`) might unexpectedly set both to zero. However, in Java, primitive types are passed by value, and array elements are distinct memory locations, so this is not a concern for the typical `int[]` example. If `a` and `b` were references to the same `Integer` object (which is immutable), this method wouldn't modify the original values anyway.
-   **Readability:** For developers unfamiliar with bitwise operations or this specific arithmetic trick, the code can be less intuitive than a simple swap with a temporary variable.

## Interview Questions & Answers
1.  **Q: Why would you want to swap two numbers without a third variable?**
    **A:** Primarily as an interview question to assess a candidate's understanding of arithmetic properties or bitwise operations, and their ability to think creatively about resource optimization. In rare cases, it might be used in performance-critical code where memory allocation (even for a single primitive) is extremely costly, or in embedded systems with very limited memory. However, for most modern applications, the readability of using a temporary variable outweighs the minor performance gain.

2.  **Q: Explain the arithmetic method for swapping and its potential drawbacks.**
    **A:** The arithmetic method uses addition and subtraction: `a = a + b; b = a - b; a = a - b;`. The first step calculates the sum, the second extracts the original `a` from the sum, and the third extracts the original `b`. The main drawback is the risk of **arithmetic overflow** if `a + b` exceeds the maximum value of the data type (e.g., `Integer.MAX_VALUE`), leading to incorrect results.

3.  **Q: Explain the XOR method for swapping and its advantages.**
    **A:** The XOR method uses the bitwise exclusive OR operator: `a = a ^ b; b = a ^ b; a = a ^ b;`. It relies on the property that `A ^ B ^ B = A`. The first step computes the XOR sum. The second step then uses this sum and `b` to recover the original `a`. The third step uses the XOR sum and the newly recovered `a` (which is original `b`) to recover the original `b`. The primary advantage is that it **does not suffer from arithmetic overflow**, making it generally safer for integer types.

4.  **Q: In Java, if I pass two `int` variables `x` and `y` to a method `swap(int a, int b)`, and swap them inside, will `x` and `y` change in the calling method?**
    **A:** No, they will not. In Java, primitives (like `int`) are passed by value. When `x` and `y` are passed to `swap`, their values are copied into `a` and `b`. Any changes to `a` and `b` inside the `swap` method affect only those local copies, not the original `x` and `y` variables in the calling method. To achieve a "swap" that affects the caller's variables, you would need to pass a mutable container like an array (`int[]`) or a custom object.

## Hands-on Exercise
**Exercise:** Implement a utility class `ArrayUtils` with a method `reverseArrayInPlace(int[] arr)` that reverses an array of integers without using any additional array or `List` (i.e., perform in-place swapping). Utilize one of the "swap without a third variable" techniques discussed.

**Instructions:**
1.  Create a class `ArrayUtils`.
2.  Inside `ArrayUtils`, create a static method `reverseArrayInPlace` that takes an `int[]` as input.
3.  The method should reverse the array in place, swapping elements from the beginning with elements from the end until the middle is reached.
4.  For each pair of elements to be swapped, use either the arithmetic or XOR method to swap them without a third variable.
5.  Include a `main` method to test your `reverseArrayInPlace` method with several example arrays.

## Additional Resources
-   **GeeksforGeeks - Swap two numbers without using a temporary variable:** [https://www.geeksforgeeks.org/swap-two-numbers-without-using-a-temporary-variable/](https://www.geeksforgeeks.org/swap-two-numbers-without-using-a-temporary-variable/)
-   **Baeldung - Swap Two Numbers in Java:** [https://www.baeldung.com/java-swap-two-numbers](https://www.baeldung.com/java-swap-two-numbers)
-   **Java Bitwise Operators:** [https://www.w3schools.com/java/java_bitwise.asp](https://www.w3schools.com/java/java_bitwise.asp)
---
# java-1.5-ac6.md

# Java Algorithms: Counting Word Occurrences with HashMap

## Overview
A frequent task in data processing, text analysis, and test automation is counting the occurrences of elements in a collection. A classic interview question involves counting how many times each word appears in a given sentence. The `HashMap` is the perfect data structure for this job, offering an efficient and elegant solution.

This guide explains how to use a `HashMap` to count word frequencies, a fundamental skill for any SDET dealing with data validation or text processing.

## Detailed Explanation
The problem is to take a string of text (a sentence) and produce a count for each unique word. For example, the sentence "The quick brown fox jumps over the lazy dog" should result in "the" having a count of 2, while all other words have a count of 1.

The `HashMap<K, V>` is ideal for this because it stores data in key-value pairs. We can use the word itself as the key (`String`) and its frequency count as the value (`Integer`).

The algorithm is as follows:
1.  **Normalize and Split:** Clean the input sentence by converting it to lowercase (to treat "The" and "the" as the same word) and removing punctuation. Then, split the sentence into an array of words based on whitespace.
2.  **Initialize HashMap:** Create an empty `HashMap<String, Integer>` to store the word counts.
3.  **Iterate and Count:** Loop through each word in the array.
    -   **If the word (key) already exists in the map:** Retrieve its current count, increment it by 1, and update the map with the new count.
    -   **If the word (key) does not exist in the map:** It's the first time we've seen this word, so add it to the map with a count of 1.
4.  **Display Results:** After iterating through all the words, the `HashMap` will contain the final frequency count for each word.

This approach is highly efficient, with a time complexity of approximately O(n), where 'n' is the number of words, because `HashMap` provides average O(1) (constant time) for `get` and `put` operations.

## Code Implementation
Here is a complete, runnable Java program that implements the word counting algorithm.

```java
import java.util.HashMap;
import java.util.Map;

/**
 * This class demonstrates how to count the occurrences of each word in a sentence
 * using a HashMap. This is a common requirement in test data validation and a
 * popular coding interview question.
 */
public class WordCounter {

    /**
     * Counts the frequency of each word in a given sentence.
     * The method is case-insensitive and handles basic punctuation.
     *
     * @param sentence The input string to be analyzed.
     * @return A Map<String, Integer> where keys are the words and values are their frequencies.
     */
    public Map<String, Integer> countWords(String sentence) {
        // 1. Pre-validation and Initialization
        if (sentence == null || sentence.isEmpty()) {
            System.out.println("Input sentence is null or empty. Returning an empty map.");
            return new HashMap<>();
        }

        Map<String, Integer> wordCounts = new HashMap<>();

        // 2. Normalize the String: convert to lowercase and remove non-alphabetic chars
        // The regex [^a-zA-Z\s] matches any character that is not a letter or whitespace.
        String normalizedSentence = sentence.toLowerCase().replaceAll("[^a-zA-Z\\s]", "");

        // 3. Split the sentence into words
        String[] words = normalizedSentence.split("\\s+");

        // 4. Iterate through the words and count frequencies
        for (String word : words) {
            if (word.isEmpty()) {
                continue; // Skip any empty strings that might result from multiple spaces
            }
            
            // The getOrDefault method is a concise way to handle the logic.
            // It gets the current value for the word, or 0 if the word isn't in the map yet.
            // Then it adds 1 and puts the new value back into the map.
            wordCounts.put(word, wordCounts.getOrDefault(word, 0) + 1);
        }

        return wordCounts;
    }

    /**
     * A utility method to print the word counts in a readable format.
     *
     * @param wordCounts The map containing the word frequencies.
     */
    public void displayCounts(Map<String, Integer> wordCounts) {
        if (wordCounts == null || wordCounts.isEmpty()) {
            System.out.println("No word counts to display.");
            return;
        }

        System.out.println("Word Occurrence Counts:");
        // Using entrySet() is an efficient way to iterate over a map's key-value pairs
        for (Map.Entry<String, Integer> entry : wordCounts.entrySet()) {
            System.out.printf("- '%s': %d%n", entry.getKey(), entry.getValue());
        }
    }

    public static void main(String[] args) {
        WordCounter wordCounter = new WordCounter();

        // --- Test Case 1: Standard sentence ---
        System.out.println("--- Test Case 1: Standard Sentence ---");
        String sentence1 = "The quick brown fox jumps over the lazy dog. The dog is quick.";
        Map<String, Integer> counts1 = wordCounter.countWords(sentence1);
        wordCounter.displayCounts(counts1);
        /*
         * Expected Output:
         * - 'quick': 2
         * - 'brown': 1
         * - 'lazy': 1
         * - 'the': 3
         * - 'fox': 1
         * - 'is': 1
         * - 'dog': 2
         * - 'jumps': 1
         * - 'over': 1
         */

        System.out.println("\n--- Test Case 2: Sentence with varied casing and more punctuation ---");
        String sentence2 = "Test, test, test... Is this a test? YES, this is a TEST!";
        Map<String, Integer> counts2 = wordCounter.countWords(sentence2);
        wordCounter.displayCounts(counts2);
        /*
         * Expected Output:
         * - 'is': 2
         * - 'test': 5
         * - 'a': 2
         * - 'this': 2
         * - 'yes': 1
         */
        
        System.out.println("\n--- Test Case 3: Empty Sentence ---");
        String sentence3 = "";
        Map<String, Integer> counts3 = wordCounter.countWords(sentence3);
        wordCounter.displayCounts(counts3);
        /*
         * Expected Output:
         * Input sentence is null or empty. Returning an empty map.
         * No word counts to display.
         */
    }
}
```

## Best Practices
- **Case Insensitivity:** Always normalize the input string (e.g., convert to lowercase) to ensure that words like "The" and "the" are counted as the same.
- **Handle Punctuation:** Pre-process the string to remove punctuation marks. A simple `replaceAll` with a regular expression is often sufficient.
- **Use `getOrDefault()`:** The `map.getOrDefault(key, defaultValue)` method is cleaner and more readable than manually checking if a key exists with `containsKey()`. It simplifies the core counting logic into a single line.
- **Edge Cases:** Always consider edge cases such as `null` input, empty strings, or strings containing only whitespace. Your function should handle these gracefully without throwing exceptions.
- **Iterate Efficiently:** When displaying the results, iterating over the `entrySet()` is generally more performant than getting the key set and then looking up the value for each key.

## Common Pitfalls
- **Forgetting to Normalize:** Failing to convert the sentence to a consistent case will lead to incorrect counts (e.g., "Word" and "word" being treated as two different words).
- **Poor Splitting Logic:** Using a simple split like `split(" ")` can fail if there are multiple spaces between words or other whitespace characters like tabs. Using `split("\\s+")` is more robust as it handles one or more whitespace characters.
- **Modifying a Collection While Iterating:** Avoid adding or removing items from a collection you are actively iterating over, as it can lead to a `ConcurrentModificationException`. The approach shown above correctly avoids this by updating values rather than changing the map's structure during the loop.

## Interview Questions & Answers
1.  **Q: Why is a `HashMap` a good choice for counting word frequencies?**
    **A:** A `HashMap` is an excellent choice because it offers average O(1) or constant-time complexity for `put` and `get` operations. This makes the overall algorithm very efficient, with a time complexity of O(n), where 'n' is the number of words. The key-value structure maps directly to the problem: the word is the key, and its count is the value.

2.  **Q: What would happen if you used a `TreeMap` instead of a `HashMap`?**
    **A:** A `TreeMap` could also be used. The main difference is that `TreeMap` stores its keys in sorted order (natural or via a `Comparator`). This means that when you print the results, the words will be in alphabetical order. However, its `put` and `get` operations have a time complexity of O(log n), making it slightly less performant than `HashMap` for this specific task where order is not required.

3.  **Q: How would you make this word counter thread-safe?**
    **A:** To make it thread-safe, you could use a `ConcurrentHashMap` instead of a `HashMap`. `ConcurrentHashMap` allows for concurrent reads and a limited number of concurrent writes, providing much better performance than a `Hashtable` or a synchronized `HashMap` (`Collections.synchronizedMap(new HashMap<>())`), which lock the entire map for any operation.

## Hands-on Exercise
**Objective:** Modify the `WordCounter` program to find the most frequent word in the sentence.

1.  Take the `wordCounts` map generated by the `countWords` method.
2.  Write a new method, `findMostFrequentWord(Map<String, Integer> wordCounts)`, that iterates through the map.
3.  Keep track of the word with the highest count seen so far.
4.  The method should return the most frequent word. If there's a tie, returning any one of the tied words is acceptable.
5.  Add a test case in your `main` method to verify your new function.

## Additional Resources
- [Baeldung - Java HashMap](https://www.baeldung.com/java-hashmap): A comprehensive guide to `HashMap` in Java.
- [GeeksforGeeks - Find the frequency of words in a string in Java](https://www.geeksforgeeks.org/find-the-frequency-of-words-in-a-string-in-java/): Another take on the same problem with different approaches.
- [Oracle Docs - HashMap](https://docs.oracle.com/javase/8/docs/api/java/util/HashMap.html): The official Java documentation for the `HashMap` class.
---
# java-1.5-ac7.md

# Java Algorithm: Anagram Checker

## Overview
An anagram is a word or phrase formed by rearranging the letters of a different word or phrase, typically using all the original letters exactly once. For example, "listen" and "silent" are anagrams. Being able to efficiently check if two strings are anagrams is a classic computer science problem and a frequent question in technical interviews for SDETs. This skill demonstrates your understanding of string manipulation, data structures (like arrays and HashMaps), and algorithm efficiency analysis (time and space complexity).

In test automation, this can be useful for validating data transformations, checking for permutations in displayed text, or creating test data where labels might appear in a different order but should contain the same characters.

## Detailed Explanation
There are two primary and efficient methods to check if two strings are anagrams. Before applying either method, it's crucial to perform a pre-check and normalization:

1.  **Pre-check**: If the two strings have different lengths, they cannot be anagrams. This is a simple and fast way to fail early.
2.  **Normalization**: Anagrams are typically case-insensitive and ignore spaces and punctuation. Therefore, both strings should be converted to lowercase and have non-alphanumeric characters removed.

### Method 1: Sorting Characters
This is the most intuitive approach. If two strings are anagrams, they are composed of the same characters. If you sort the characters of both strings, the resulting sorted strings will be identical.

**Steps:**
1.  Perform the length pre-check and normalization.
2.  Convert both normalized strings into character arrays.
3.  Sort both character arrays.
4.  Compare the sorted arrays. If they are equal, the original strings are anagrams.

**Example:**
- `s1 = "Listen"`
- `s2 = "Silent"`
- Normalize: `s1 = "listen"`, `s2 = "silent"`
- To char array: `['l', 'i', 's', 't', 'e', 'n']` and `['s', 'i', 'l', 'e', 'n', 't']`
- Sort: `['e', 'i', 'l', 'n', 's', 't']` and `['e', 'i', 'l', 'n', 's', 't']`
- Compare: They are identical, so they are anagrams.

### Method 2: Character Frequency Count (Using a HashMap or an Array)
This method is generally more performant. Instead of sorting, we count the occurrences of each character in both strings. If the character counts (frequency maps) are identical for both strings, they are anagrams.

**Steps using a HashMap:**
1.  Perform the length pre-check and normalization.
2.  Create a `HashMap<Character, Integer>` to store the character counts for the first string.
3.  Iterate through the first string, populating the map with character counts.
4.  Iterate through the second string. For each character, decrement its count in the map.
5.  After iterating through the second string, all counts in the map should be zero. If any count is not zero, or if a character from the second string is not in the map, they are not anagrams.

**For ASCII or a known character set, an integer array is even faster:**
1.  Perform the length pre-check and normalization.
2.  Create an integer array of size 256 (for extended ASCII) or 26 (for lowercase English letters), initialized to zeros.
3.  Iterate through the first string, incrementing the count for each character at its corresponding index (e.g., `count[char - 'a']++`).
4.  Iterate through the second string, decrementing the count for each character.
5.  Finally, iterate through the count array. If all values are zero, the strings are anagrams.

## Code Implementation
Here is a complete, runnable Java class demonstrating both the sorting and frequency counting methods.

```java
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

public class AnagramChecker {

    /**
     * Method 1: Checks if two strings are anagrams by sorting their characters.
     * Time Complexity: O(n log n) due to sorting.
     * Space Complexity: O(n) to store character arrays.
     *
     * @param s1 The first string.
     * @param s2 The second string.
     * @return true if the strings are anagrams, false otherwise.
     */
    public static boolean areAnagramsBySorting(String s1, String s2) {
        // Pre-validation and normalization
        if (s1 == null || s2 == null) {
            return false;
        }
        String normalizedS1 = s1.toLowerCase().replaceAll("[^a-z0-9]", "");
        String normalizedS2 = s2.toLowerCase().replaceAll("[^a-z0-9]", "");

        if (normalizedS1.length() != normalizedS2.length()) {
            return false;
        }

        // Convert to char arrays and sort
        char[] arr1 = normalizedS1.toCharArray();
        char[] arr2 = normalizedS2.toCharArray();

        Arrays.sort(arr1);
        Arrays.sort(arr2);

        // Compare sorted arrays
        return Arrays.equals(arr1, arr2);
    }

    /**
     * Method 2: Checks if two strings are anagrams using a frequency map (character counts).
     * Time Complexity: O(n) because we iterate through the strings a constant number of times.
     * Space Complexity: O(k) where k is the number of unique characters (or a constant O(1) for a fixed character set like ASCII).
     *
     * @param s1 The first string.
     * @param s2 The second string.
     * @return true if the strings are anagrams, false otherwise.
     */
    public static boolean areAnagramsByFrequencyCount(String s1, String s2) {
        // Pre-validation and normalization
        if (s1 == null || s2 == null) {
            return false;
        }
        String normalizedS1 = s1.toLowerCase().replaceAll("[^a-z0-9]", "");
        String normalizedS2 = s2.toLowerCase().replaceAll("[^a-z0-9]", "");

        if (normalizedS1.length() != normalizedS2.length()) {
            return false;
        }

        // Using an array for frequency counting (assuming lowercase English alphabet)
        int[] charCounts = new int[26]; // For 'a' through 'z'

        // Count characters for the first string
        for (char c : normalizedS1.toCharArray()) {
            charCounts[c - 'a']++;
        }

        // Decrement counts for the second string
        for (char c : normalizedS2.toCharArray()) {
            charCounts[c - 'a']--;
            // If a count goes below zero, it means s2 has a character
            // that is either not in s1 or is more frequent.
            if (charCounts[c - 'a'] < 0) {
                return false;
            }
        }
        
        // If all counts are zero, they are anagrams.
        // Since we checked for equal length, we don't need to iterate the counts array again.
        // If lengths are equal and no count went negative, all counts must be zero.
        return true;
    }

    public static void main(String[] args) {
        // Test cases
        String[][] testPairs = {
            {"Listen", "Silent"},
            {"Debit card", "Bad credit"},
            {"The eyes", "They see"},
            {"hello", "world"},
            {"rail safety", "fairy tales"},
            {"Dormitory", "Dirty room"},
            {"apple", "paple"},
            {"test", "tess"}
        };

        System.out.println("--- Checking Anagrams by Sorting ---");
        for (String[] pair : testPairs) {
            System.out.printf("'%s' and '%s' are anagrams? -> %b\n", pair[0], pair[1], areAnagramsBySorting(pair[0], pair[1]));
        }

        System.out.println("\n--- Checking Anagrams by Frequency Count ---");
        for (String[] pair : testPairs) {
            System.out.printf("'%s' and '%s' are anagrams? -> %b\n", pair[0], pair[1], areAnagramsByFrequencyCount(pair[0], pair[1]));
        }
    }
}
```

## Best Practices
- **Fail Fast**: Always check for `null` inputs and differing lengths first. This is the cheapest check and avoids unnecessary processing.
- **Normalize Correctly**: Your definition of an anagram (case-sensitive, space-ignoring, etc.) dictates your normalization strategy. Clearly define it and implement it robustly, for example, using a regular expression like `[^a-z0-9]` to strip out unwanted characters.
- **Choose the Right Tool**: For a fixed and small character set (like English letters), an array for frequency counting is more efficient than a HashMap due to lower overhead. For Unicode strings with a vast number of characters, a HashMap is more appropriate.
- **Write Clean Code**: Use meaningful variable names (`charCounts` instead of `arr`) and comment on the time/space complexity of your solution.

## Common Pitfalls
- **Forgetting Normalization**: Failing to convert strings to a common case (e.g., lowercase) is the most common mistake. "Listen" and "silent" would fail a check if case isn't handled.
- **Mishandling Unicode**: If the strings can contain non-ASCII characters, a simple array of size 256 might not be sufficient. In such cases, using a `HashMap<Character, Integer>` is a safer, more robust solution.
- **Inefficient Comparison**: After building frequency maps, don't use a complex loop to compare them. The `equals()` method of maps (`map1.equals(map2)`) can compare them efficiently. In the array frequency count method, you only need to iterate through the second string and check for negative counts; a final loop over the counts array is redundant if the strings are the same length.

## Interview Questions & Answers
1.  **Q: What is the time and space complexity of your anagram solution?**
    **A:** *For the sorting method:* The time complexity is dominated by the sorting algorithm, which is typically **O(n log n)**, where n is the length of the strings. The space complexity is **O(n)** because we need to create character arrays to perform the sort. In Java, `toCharArray()` creates a new copy.
    *For the frequency counting method:* The time complexity is **O(n)** because we iterate through the strings once to build the character map and once again to check it. The space complexity is **O(k)**, where k is the number of unique characters. If the character set is fixed (like ASCII or a 26-letter alphabet), this can be considered **O(1)** or constant space.

2.  **Q: Between the sorting and frequency counting methods, which one is better?**
    **A:** The frequency counting method is generally better because of its superior time complexity (O(n) vs O(n log n)). It is more scalable for very long strings. However, the sorting method can be very concise and easy to write, making it a reasonable choice if the input strings are known to be short.

3.  **Q: How would you modify your solution to handle Unicode characters?**
    **A:** I would use the frequency counting method with a `HashMap<Character, Integer>` instead of a fixed-size integer array. The array is only suitable for a small, known character set like ASCII. A HashMap can handle any character, including the full range of Unicode, by mapping each character to its count. This makes the solution more robust and scalable for internationalized strings.

## Hands-on Exercise
1.  **Objective**: Write a function that groups an array of strings by anagrams.
2.  **Task**: Given an array of strings, `["eat", "tea", "tan", "ate", "nat", "bat"]`, write a method `groupAnagrams(String[] strs)` that returns a list of lists, where each inner list contains strings that are anagrams of each other.
3.  **Expected Output**: `[["eat", "tea", "ate"], ["tan", "nat"], ["bat"]]`
4.  **Hint**: Use a `HashMap`. The key of the map can be the sorted version of a string, and the value can be a `List<String>` of all its anagrams. Iterate through the input array, sort each string to find its canonical representation, and add it to the corresponding list in the map.

## Additional Resources
- [GeeksforGeeks: Check whether two strings are an Anagram of each other](https://geeksforgeeks.org/check-whether-two-strings-are-anagram-of-each-other/)
- [Baeldung: A Guide to Anagrams in Java](https://www.baeldung.com/java-anagrams)
- [LeetCode - Valid Anagram](https://leetcode.com/problems/valid-anagram/): Practice implementing the solution and see how it is tested against various edge cases.
---
# java-1.5-ac8.md

# Find First Non-Repeating Character in a String

## Overview
Identifying the first non-repeating character in a string is a classic coding challenge that frequently appears in technical interviews. It tests your understanding of data structures (like HashMaps or arrays for frequency counting) and efficient string traversal. In real-world SDET scenarios, this logic can be adapted for tasks like analyzing log files for unique error codes or processing user input for data validation.

## Detailed Explanation
The most efficient approach to finding the first non-repeating character involves two passes through the string, often utilizing a frequency map.

1.  **First Pass (Frequency Counting):**
    Iterate through the string once to build a frequency map of all characters. A `HashMap<Character, Integer>` is a flexible choice, mapping each character to its count. Alternatively, for ASCII characters, a simple `int[]` array of size 256 (or 128 for extended ASCII) can be used for faster access, where the index represents the character's ASCII value and the value stores its count.

2.  **Second Pass (Finding First Non-Repeating):**
    Iterate through the string a second time. For each character, check its count in the frequency map. The first character encountered with a count of `1` is our desired result. This second pass is crucial because it preserves the original order of characters, ensuring we find the *first* non-repeating one, not just *any* non-repeating one.

If, after the second pass, no character has a count of `1`, it means all characters repeat, or the string is empty. In such cases, a special indicator (e.g., `null`, `' '`, or throwing an exception) should be returned.

**Time Complexity:** O(N), where N is the length of the string. Both passes iterate through the string once.
**Space Complexity:** O(C), where C is the size of the character set (e.g., 256 for extended ASCII, or potentially more for Unicode characters if using a HashMap, which depends on the number of unique characters in the string).

## Code Implementation

```java
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

public class FirstNonRepeatingChar {

    /**
     * Finds the first non-repeating character in a given string.
     * Uses a LinkedHashMap to maintain insertion order, which is crucial for
     * identifying the *first* non-repeating character efficiently.
     *
     * @param str The input string.
     * @return An Optional containing the first non-repeating character, or empty if none exists.
     */
    public Optional<Character> findFirstNonRepeating(String str) {
        if (str == null || str.isEmpty()) {
            return Optional.empty();
        }

        // Use LinkedHashMap to preserve the insertion order of characters.
        // This is important because we need to find the *first* non-repeating character.
        Map<Character, Integer> charCounts = new LinkedHashMap<>();

        // First pass: Populate character counts
        for (char c : str.toCharArray()) {
            charCounts.put(c, charCounts.getOrDefault(c, 0) + 1);
        }

        // Second pass: Iterate through the LinkedHashMap entries to find the first character
        // with a count of 1. Because LinkedHashMap maintains order, the first entry with count 1
        // will correspond to the first non-repeating character in the original string.
        for (Map.Entry<Character, Integer> entry : charCounts.entrySet()) {
            if (entry.getValue() == 1) {
                return Optional.of(entry.getKey());
            }
        }

        // If no character has a count of 1, return empty Optional
        return Optional.empty();
    }

    /**
     * An alternative approach using an array for frequency counting (optimized for ASCII/Extended ASCII).
     * This approach requires two passes through the string to preserve order.
     *
     * @param str The input string.
     * @return An Optional containing the first non-repeating character, or empty if none exists.
     */
    public Optional<Character> findFirstNonRepeatingUsingArray(String str) {
        if (str == null || str.isEmpty()) {
            return Optional.empty();
        }

        // Assuming ASCII or Extended ASCII characters (0-255).
        // Using 256 for convenience to cover all possible char values within byte range.
        int[] charCounts = new int[256];

        // First pass: Populate character counts
        for (char c : str.toCharArray()) {
            charCounts[c]++;
        }

        // Second pass: Find the first character with a count of 1 based on its original position
        for (char c : str.toCharArray()) {
            if (charCounts[c] == 1) {
                return Optional.of(c);
            }
        }

        return Optional.empty();
    }


    public static void main(String[] args) {
        FirstNonRepeatingChar solver = new FirstNonRepeatingChar();

        // Test cases for findFirstNonRepeating (LinkedHashMap approach)
        System.out.println("--- LinkedHashMap Approach ---");
        System.out.println("'swiss' -> " + solver.findFirstNonRepeating("swiss").orElse(' ')); // 'w'
        System.out.println("'aabbcdeeff' -> " + solver.findFirstNonRepeating("aabbcdeeff").orElse(' ')); // 'c'
        System.out.println("'aabbcc' -> " + solver.findFirstNonRepeating("aabbcc").orElse(' ')); // ' '
        System.out.println("'abc' -> " + solver.findFirstNonRepeating("abc").orElse(' ')); // 'a'
        System.out.println("'z' -> " + solver.findFirstNonRepeating("z").orElse(' ')); // 'z'
        System.out.println("'' -> " + solver.findFirstNonRepeating("").orElse(' ')); // ' '
        System.out.println("null -> " + solver.findFirstNonRepeating(null).orElse(' ')); // ' '
        System.out.println("'stress' -> " + solver.findFirstNonRepeating("stress").orElse(' ')); // 't'
        System.out.println("'teeter' -> " + solver.findFirstNonRepeating("teeter").orElse(' ')); // 'r'
        System.out.println("'racecar' -> " + solver.findFirstNonRepeating("racecar").orElse(' ')); // 'e'

        System.out.println("\n--- Array Approach (for ASCII) ---");
        System.out.println("'swiss' -> " + solver.findFirstNonRepeatingUsingArray("swiss").orElse(' ')); // 'w'
        System.out.println("'aabbcdeeff' -> " + solver.findFirstNonRepeatingUsingArray("aabbcdeeff").orElse(' ')); // 'c'
        System.out.println("'aabbcc' -> " + solver.findFirstNonRepeatingUsingArray("aabbcc").orElse(' ')); // ' '
        System.out.println("'abc' -> " + solver.findFirstNonRepeatingUsingArray("abc").orElse(' ')); // 'a'
        System.out.println("'z' -> " + solver.findFirstNonRepeatingUsingArray("z").orElse(' ')); // 'z'
        System.out.println("'' -> " + solver.findFirstNonRepeatingUsingArray("").orElse(' ')); // ' '
        System.out.println("null -> " + solver.findFirstNonRepeatingUsingArray(null).orElse(' ')); // ' '
        System.out.println("'stress' -> " + solver.findFirstNonRepeatingUsingArray("stress").orElse(' ')); // 't'
        System.out.println("'teeter' -> " + solver.findFirstNonRepeatingUsingArray("teeter").orElse(' ')); // 'r'
        System.out.println("'racecar' -> " + solver.findFirstNonRepeatingUsingArray("racecar").orElse(' ')); // 'e'
    }
}
```

## Best Practices
-   **Handle Edge Cases:** Always consider empty strings, null strings, and strings where all characters repeat. Returning an `Optional` is a clean way to handle cases where no such character is found.
-   **Preserve Order:** For "first" non-repeating, use data structures that maintain insertion order (like `LinkedHashMap`) or perform a second pass through the original string.
-   **Character Set Awareness:** For pure ASCII characters, an array is often faster due to direct indexing. For broader character sets (like Unicode), a `HashMap` is more appropriate and flexible.
-   **Case Sensitivity:** Clarify with the interviewer if the solution should be case-sensitive or case-insensitive. If case-insensitive, convert the string to a consistent case (e.g., lowercase) before processing.
-   **Immutable Input:** Avoid modifying the input string directly unless explicitly required, as strings are immutable in Java.

## Common Pitfalls
-   **Using `HashMap` without a second pass:** If you iterate only through a standard `HashMap` (which does not guarantee order), the "first" character you find with a count of 1 might not be the *actual first* non-repeating character from the original string.
-   **Ignoring `null` or empty strings:** This can lead to `NullPointerExceptions` or incorrect results.
-   **Off-by-one errors with array indexing:** Ensure your array size is sufficient for the character set you intend to cover (e.g., 256 for extended ASCII).
-   **Not clarifying requirements:** Always ask about case sensitivity, expected return value for no non-repeating characters, and the character set.

## Interview Questions & Answers

1.  **Q: How do you find the first non-repeating character in a string? Describe your approach.**
    **A:** My preferred approach involves two passes. In the first pass, I iterate through the string and populate a frequency map (like a `LinkedHashMap` in Java) where keys are characters and values are their counts. Using `LinkedHashMap` is critical because it preserves the insertion order. In the second pass, I iterate through the entries of this `LinkedHashMap`. The first character encountered with a count of `1` is the first non-repeating character in the original string. If no such character is found after checking all entries, it means there isn't one, and I'd return an empty `Optional`.

2.  **Q: What is the time and space complexity of your solution?**
    **A:**
    *   **Time Complexity:** O(N), where N is the length of the input string. This is because we traverse the string twice (or once for populating the array and once for checking if using an array, or once for populating and once for iterating through the LinkedHashMap's unique keys, which at most is N). Each character lookup and update in the hash map (or array) takes O(1) on average.
    *   **Space Complexity:** O(C), where C is the size of the character set. For ASCII characters, this is a constant space (e.g., 256 for an `int[]` array). For Unicode or if using a `HashMap`, it would be O(k) where k is the number of unique characters in the string, which can be at most N, but practically much smaller for typical strings.

3.  **Q: How would you modify your solution to handle strings with Unicode characters (e.g., emojis or characters from different languages)?**
    **A:** The `LinkedHashMap<Character, Integer>` approach inherently handles Unicode characters correctly because Java's `char` type (UTF-16) can represent most common Unicode characters, and `HashMap` keys are based on `equals()` and `hashCode()`. However, for characters outside the Basic Multilingual Plane (BMP), which require surrogate pairs, a single `char` is not enough. For full Unicode compatibility, especially for code points that require two `char`s (like many emojis), it's more robust to work with `String` code points or use a `Map<Integer, Integer>` where the `Integer` key represents the Unicode code point. The `String.codePoints()` method returns an `IntStream` of code points, which can then be used to populate the frequency map. The two-pass logic remains the same.

## Hands-on Exercise
1.  **Case-Insensitive Search:** Modify the `findFirstNonRepeating` method to ignore case. For example, in "aAbBcC", 'A' should be considered a duplicate of 'a', and the result should be an empty `Optional`.
2.  **Return All Non-Repeating Characters:** Change the method to return a `List<Character>` containing all non-repeating characters in their original order.
3.  **String with Special Characters:** Test your solution with a string containing spaces, numbers, and special symbols (e.g., "hello world! 123 123 hello").

## Additional Resources
-   [GeeksforGeeks: Find the first non-repeating character in a stream of characters](https://www.geeksforgeeks.org/find-first-non-repeating-character-stream-characters/)
-   [Baeldung: Guide to Java LinkedHashMap](https://www.baeldung.com/java-linked-hash-map)
-   [Oracle Java Documentation: Character Class](https://docs.oracle.com/javase/8/docs/api/java/lang/Character.html)

```
---
# java-1.5-ac9.md

# Perfect Number Checker

## Overview
A perfect number is a positive integer that is equal to the sum of its proper positive divisors (the sum of its positive divisors excluding the number itself). For instance, 6 has divisors 1, 2, and 3 (excluding itself), and 1 + 2 + 3 = 6, so 6 is a perfect number.

This concept, while seemingly academic, is an excellent problem for honing fundamental programming skills such as loop usage, conditional logic, and algorithmic efficiency. It's a common screening question in technical interviews to assess a candidate's problem-solving approach and code quality.

## Detailed Explanation
The algorithm to check if a number is perfect is straightforward:
1.  Initialize a variable, `sumOfDivisors`, to 0.
2.  Iterate from 1 up to `n / 2`. The largest possible proper divisor of any number `n` is `n / 2`. Iterating all the way up to `n - 1` is inefficient.
3.  In each iteration, check if the current number `i` is a divisor of `n`. This is done using the modulo operator (`%`). If `n % i == 0`, then `i` is a divisor.
4.  If `i` is a divisor, add it to `sumOfDivisors`.
5.  After the loop completes, compare `sumOfDivisors` with the original number `n`.
6.  If they are equal, the number is a perfect number. The number must also be greater than 1, as 1 is not considered a perfect number.

**Example Walkthrough (n = 28):**
- **`sumOfDivisors`** starts at 0.
- **`i = 1`**: `28 % 1 == 0`. `sumOfDivisors` = 0 + 1 = 1.
- **`i = 2`**: `28 % 2 == 0`. `sumOfDivisors` = 1 + 2 = 3.
- **`i = 3`**: `28 % 3 != 0`.
- **`i = 4`**: `28 % 4 == 0`. `sumOfDivisors` = 3 + 4 = 7.
- **`i = 5`**: `28 % 5 != 0`.
- **`i = 6`**: `28 % 6 != 0`.
- **`i = 7`**: `28 % 7 == 0`. `sumOfDivisors` = 7 + 7 = 14.
- ...
- **`i = 14`**: `28 % 14 == 0`. `sumOfDivisors` = 14 + 14 = 28.
- The loop ends as the next check `i = 15` is greater than `28 / 2 = 14`.
- Finally, `sumOfDivisors` (28) is equal to `n` (28). Thus, 28 is a perfect number.

## Code Implementation
Here is a complete, runnable Java program that implements a perfect number checker.

```java
import java.util.stream.IntStream;

public class PerfectNumberChecker {

    /**
     * Checks if a number is a perfect number using a classic iterative approach.
     * A perfect number is a positive integer that is equal to the sum of its proper divisors.
     *
     * Time Complexity: O(n/2) which simplifies to O(n).
     *
     * @param number The number to check.
     * @return true if the number is perfect, false otherwise.
     */
    public static boolean isPerfect(int number) {
        // A perfect number must be a positive integer. By convention, 1 is not perfect.
        if (number <= 1) {
            return false;
        }

        int sumOfDivisors = 1; // Start with 1 as all numbers are divisible by 1.

        // Iterate from 2 up to number / 2.
        // We can optimize by iterating up to sqrt(number), but for clarity, n/2 is used here.
        for (int i = 2; i <= number / 2; i++) {
            if (number % i == 0) {
                sumOfDivisors += i;
            }
        }

        // Check if the sum of divisors equals the original number.
        return sumOfDivisors == number;
    }

    /**
     * A more optimized version using Java 8 Streams.
     * This demonstrates a functional programming approach.
     *
     * Time Complexity: O(n/2) which simplifies to O(n).
     *
     * @param number The number to check.
     * @return true if the number is perfect, false otherwise.
     */
    public static boolean isPerfectWithStreams(int number) {
        if (number <= 1) {
            return false;
        }

        // IntStream.rangeClosed generates numbers from 1 to number/2.
        // .filter() keeps only the numbers that are proper divisors.
        // .sum() calculates the sum of these divisors.
        int sumOfDivisors = IntStream.rangeClosed(1, number / 2)
                                     .filter(i -> number % i == 0)
                                     .sum();

        return sumOfDivisors == number;
    }


    public static void main(String[] args) {
        System.out.println("--- Perfect Number Checker ---");

        int[] numbersToTest = {0, 1, 5, 6, 27, 28, 496, 8128, 8129};

        System.out.println("\nUsing iterative approach:");
        for (int num : numbersToTest) {
            System.out.printf("Is %d a perfect number? %b\n", num, isPerfect(num));
        }
        // Expected output: 6, 28, 496, 8128 are perfect.

        System.out.println("\nUsing Java 8 Streams approach:");
        for (int num : numbersToTest) {
            System.out.printf("Is %d a perfect number? %b\n", num, isPerfectWithStreams(num));
        }

        System.out.println("\n--- Finding perfect numbers in a range (1 to 10000) ---");
        System.out.print("Perfect numbers found: ");
        IntStream.rangeClosed(1, 10000)
                 .filter(PerfectNumberChecker::isPerfect)
                 .forEach(p -> System.out.print(p + " "));
        System.out.println();
    }
}
```

## Best Practices
- **Handle Edge Cases**: Always handle edge cases like 0, 1, and negative numbers. Perfect numbers are positive, and 1 is not considered perfect.
- **Optimize the Loop**: For better performance, you can iterate up to the square root of the number (`Math.sqrt(number)`). If you find a divisor `i`, you also find another divisor `number / i`. This reduces the time complexity from O(n) to O(sqrt(n)).
- **Code Readability**: Write clean, self-commenting code. The functional approach using streams is concise, but the classic `for` loop might be more readable for developers less familiar with streams.
- **Use Final for Constants**: If you have constant values, declare them as `final` to prevent accidental modification.

## Common Pitfalls
- **Off-by-One Errors**: Be careful with loop boundaries. Iterating up to `number - 1` is correct but inefficient. Iterating up to `number` is a common mistake that would incorrectly include the number itself in the sum.
- **Forgetting to Handle `1`**: A common mistake is to consider 1 as a perfect number. The sum of its proper divisors is 0, not 1.
- **Inefficient Looping**: As mentioned, looping up to `n - 1` is a performance pitfall, especially for large numbers. The `n / 2` or `sqrt(n)` optimizations are crucial in a real-world scenario.

## Interview Questions & Answers
1. **Q:** What is a perfect number?
   **A:** A perfect number is a positive integer that equals the sum of its proper positive divisors (all divisors except the number itself). The first perfect number is 6, because its divisors are 1, 2, and 3, and 1 + 2 + 3 = 6.

2. **Q:** How would you optimize the algorithm to find perfect numbers?
   **A:** The naive approach is to iterate from 1 to `n-1`, which has a time complexity of O(n). A better approach is to iterate up to `n/2`. The most optimal approach is to iterate only up to the square root of `n`. For every divisor `i` you find, you also find a pair `n/i`. You sum both `i` and `n/i`. This reduces the time complexity to O(sqrt(n)), making it significantly faster for large numbers.

3. **Q:** Can you write a perfect number checker using Java Streams?
   **A:** Yes. You can use `IntStream.rangeClosed(1, number / 2)` to generate potential divisors, then use `.filter(i -> number % i == 0)` to find the actual divisors, and finally use `.sum()` to get their sum. This sum can then be compared to the original number. (Refer to the `isPerfectWithStreams` method in the code example).

## Hands-on Exercise
1.  **Modify the `isPerfect` method** to use the square root optimization. Remember to handle the case where the number is a perfect square to avoid adding the square root twice.
2.  **Write a new method `generatePerfectNumbers(int limit)`** that finds and returns a `List<Integer>` of all perfect numbers up to a given `limit`.
3.  **Test your new methods** with a `main` method or a TestNG/JUnit test class to ensure they work correctly. Verify that your `generatePerfectNumbers(10000)` method returns `[6, 28, 496, 8128]`.

## Additional Resources
- [Wikipedia: Perfect Number](https://en.wikipedia.org/wiki/Perfect_number)
- [GeeksforGeeks: Perfect Number](https://www.geeksforgeeks.org/perfect-number/)
- [Euclid's Elements - Proposition IX.36](https://mathcs.clarku.edu/~djoyce/java/elements/bookIX/propIX36.html) (The ancient Greek formula for generating perfect numbers)

```
---
# java-1.5-ac10.md

# Java Armstrong Number Checker and Generator

## Overview
An Armstrong number (also known as a narcissistic number, pluperfect digital invariant, or plus perfect number) is a number that is the sum of its own digits each raised to the power of the number of digits. Understanding the logic behind identifying these numbers is a common requirement in coding interviews to test a candidate's problem-solving, algorithmic thinking, and basic arithmetic manipulation skills in a language like Java.

For example:
- **153** is an Armstrong number because it has 3 digits, and 1³ + 5³ + 3³ = 1 + 125 + 27 = 153.
- **9** is an Armstrong number because it has 1 digit, and 9¹ = 9.
- **1634** is an Armstrong number because it has 4 digits, and 1⁴ + 6⁴ + 3⁴ + 4⁴ = 1 + 1296 + 81 + 256 = 1634.

This topic is valuable for SDETs as it demonstrates logical reasoning and the ability to break down a problem into smaller, manageable steps—a core skill in test automation development.

## Detailed Explanation
To determine if a number is an Armstrong number, we need to follow these steps:
1.  **Count the number of digits** in the given number. Let's call this `n`.
2.  **Extract each digit** from the number.
3.  **Raise each extracted digit** to the power of `n`.
4.  **Sum the results** from the previous step.
5.  **Compare the final sum** with the original number. If they are equal, the number is an Armstrong number; otherwise, it is not.

### Example Walkthrough: Checking `371`
1.  **Count digits**: The number `371` has 3 digits. So, `n = 3`.
2.  **Extract digits**: The digits are 3, 7, and 1.
3.  **Raise to power `n`**:
    *   3³ = 27
    *   7³ = 343
    *   1³ = 1
4.  **Sum the results**: 27 + 343 + 1 = 371.
5.  **Compare**: The sum (371) is equal to the original number (371). Therefore, 371 is an Armstrong number.

## Code Implementation
Here is a complete, runnable Java program that includes a method to check if a number is an Armstrong number and another method to generate all Armstrong numbers up to a specified limit.

```java
import java.util.ArrayList;
import java.util.List;

public class ArmstrongNumberGenerator {

    /**
     * Checks if a given number is an Armstrong number.
     *
     * @param number The number to check. Must be a non-negative integer.
     * @return true if the number is an Armstrong number, false otherwise.
     */
    public static boolean isArmstrong(int number) {
        if (number < 0) {
            return false; // Armstrong numbers are typically defined for non-negative integers
        }

        String numStr = String.valueOf(number);
        int numberOfDigits = numStr.length();
        
        // A more efficient way to get number of digits for positive integers
        // int numberOfDigits = (int) (Math.log10(number) + 1);

        long sumOfPowers = 0;
        int originalNumber = number;
        int temp = number;

        // Extract digits and calculate sum of powers
        while (temp > 0) {
            int digit = temp % 10;
            sumOfPowers += Math.pow(digit, numberOfDigits);
            temp /= 10;
        }

        return sumOfPowers == originalNumber;
    }

    /**
     * Generates a list of Armstrong numbers up to a specified limit.
     *
     * @param limit The upper bound (inclusive) for the search.
     * @return A List of integers containing Armstrong numbers.
     */
    public static List<Integer> generateArmstrongNumbers(int limit) {
        if (limit < 0) {
            throw new IllegalArgumentException("Limit cannot be negative.");
        }
        List<Integer> armstrongNumbers = new ArrayList<>();
        for (int i = 0; i <= limit; i++) {
            if (isArmstrong(i)) {
                armstrongNumbers.add(i);
            }
        }
        return armstrongNumbers;
    }

    public static void main(String[] args) {
        // --- Test the isArmstrong method ---
        int testNum1 = 153;
        System.out.printf("Is %d an Armstrong number? -> %b%n", testNum1, isArmstrong(testNum1));

        int testNum2 = 370;
        System.out.printf("Is %d an Armstrong number? -> %b%n", testNum2, isArmstrong(testNum2));

        int testNum3 = 9474;
        System.out.printf("Is %d an Armstrong number? -> %b%n", testNum3, isArmstrong(testNum3));
        
        int testNum4 = 500;
        System.out.printf("Is %d an Armstrong number? -> %b%n", testNum4, isArmstrong(testNum4));

        // --- Generate Armstrong numbers up to a limit ---
        int upperLimit = 10000;
        System.out.printf("%nGenerating Armstrong numbers up to %d...%n", upperLimit);
        List<Integer> result = generateArmstrongNumbers(upperLimit);
        System.out.println("Found Armstrong numbers: " + result);
    }
}
```

## Best Practices
-   **Handle Edge Cases**: Always consider edge cases such as 0, 1, and negative numbers. The provided code correctly handles non-negative integers.
-   **Use `long` for Sum**: When calculating the sum of powers, use a `long` data type to prevent potential integer overflow, especially for larger numbers.
-   **Efficient Digit Counting**: For positive integers, calculating the number of digits using `(int) (Math.log10(number) + 1)` is more mathematically efficient than converting the number to a string, though the string approach is often more readable.
-   **Readability**: Write clean, well-commented code. The logic for Armstrong numbers can be confusing, so clear variable names (`numberOfDigits`, `sumOfPowers`) are crucial.

## Common Pitfalls
-   **Modifying the Original Number**: A common mistake is to modify the original number variable during the digit extraction loop. Always use a temporary variable (`temp`) for calculations and keep the original number for the final comparison.
-   **Integer Overflow**: Using an `int` for `sumOfPowers` can fail for numbers with many digits, as the sum can exceed `Integer.MAX_VALUE`.
-   **Incorrectly Calculating Number of Digits**: Re-calculating the number of digits inside the loop is inefficient and incorrect. It should be calculated once before the loop begins.

## Interview Questions & Answers
1.  **Q: What is an Armstrong number, and can you give an example?**
    **A:** An Armstrong number is a number that equals the sum of its digits, each raised to the power of the total number of digits. For instance, 153 is an Armstrong number because it has 3 digits, and 1³ + 5³ + 3³ = 1 + 125 + 27 = 153.

2.  **Q: How would you optimize the process of finding Armstrong numbers in a large range?**
    **A:** Instead of checking every number, a more advanced approach involves generating numbers that could be Armstrong numbers. You can determine the number of digits `n`, then iterate through all possible digit combinations, calculate the sum of their `n`-th powers, and check if the resulting number has the same digits and is of length `n`. This avoids checking every single number in the range, but the logic is significantly more complex to implement. For most interview settings, the straightforward checking method is sufficient.

3.  **Q: What data type would you use for your sum variable and why?**
    **A:** I would use `long` for the sum variable (`sumOfPowers`). This is to prevent integer overflow. For a number with many digits, the sum of each digit raised to the power of the number of digits can easily exceed the maximum value of an `int` (2,147,483,647), leading to incorrect results. `long` provides a much larger range.

## Hands-on Exercise
1.  **Modify the `generateArmstrongNumbers` method**: Change the method to accept both a lower and an upper bound (e.g., `generateArmstrongNumbers(int start, int end)`).
2.  **Write Unit Tests**: Create a new class `ArmstrongNumberGeneratorTest` and use a testing framework like JUnit or TestNG to write at least five test cases for the `isArmstrong` method.
    *   Test a known Armstrong number (e.g., 1634).
    *   Test a known non-Armstrong number (e.g., 123).
    *   Test with zero (0).
    *   Test with a single-digit number (e.g., 7).
    *   Test with a negative number.
3.  **Extend the Generator**: Create a new method that finds and returns the *first `n`* Armstrong numbers, rather than all numbers up to a limit. For example, `findFirstNArmstrongNumbers(10)` should return the first 10 Armstrong numbers.

## Additional Resources
-   [GeeksforGeeks: Armstrong Numbers](https://www.geeksforgeeks.org/program-for-armstrong-numbers/)
-   [Baeldung: How to Check for an Armstrong Number in Java](https://www.baeldung.com/java-armstrong-number)
---
# java-1.5-ac11.md

# Java IO Fundamentals: Reading and Writing Files

## Overview
Reading from and writing to files are fundamental operations in any programming language, and they are especially critical in test automation. SDETs frequently need to interact with files to manage test data, configuration properties, logs, and test evidence like reports or screenshots. Mastering Java's Input/Output (I/O) capabilities is a non-negotiable skill for building robust and flexible automation frameworks. This guide will cover the modern and classic approaches to file I/O in Java.

## Detailed Explanation

Java I/O has evolved over the years. The original `java.io` package provides a stream-based, blocking I/O model. With Java 7, the `java.nio` (New I/O) package was introduced, offering a more powerful and flexible buffer-based, non-blocking model. For most day-to-day file operations in test automation, a combination of classic and new APIs provides the most readable and efficient solution.

### Key Classes for File I/O

1.  **Classic I/O (`java.io`)**:
    *   **`FileReader` / `FileWriter`**: Used for reading/writing character files. They are simple but less efficient for large files as they perform one character at a time I/O.
    *   **`BufferedReader` / `BufferedWriter`**: These are wrapper classes that significantly improve performance by buffering I/O operations. They read/write chunks of data from/to the disk at once, reducing the number of expensive disk access operations. `BufferedReader`'s `readLine()` method is particularly useful.
    *   **`FileInputStream` / `FileOutputStream`**: Used for reading/writing raw bytes, suitable for any file type (e.g., images, binary data).

2.  **Modern I/O (`java.nio.file`) - Recommended**:
    *   **`Paths`**: A utility class to create `Path` objects from a string. A `Path` represents a file or directory path and is a central entry point for the `nio` API.
    *   **`Files`**: A utility class with static methods for common file operations. It simplifies tasks like reading all lines from a file, writing a list of strings to a file, checking existence, creating directories, etc. It often uses `BufferedReader`/`BufferedWriter` under the hood but provides a much cleaner API.

For test automation, the methods in the `java.nio.file.Files` class are often the best choice as they are concise, efficient, and handle resource management automatically.

## Code Implementation

Here are code examples for reading and writing files using both the classic buffered approach and the modern `java.nio.file.Files` approach. The modern approach is generally preferred for its simplicity and robustness.

### 1. Reading a File

**Scenario**: Read a configuration file (`config.properties`) line by line.

#### Modern Approach: `Files.readAllLines()` (Recommended)

```java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

public class FileReadWriteNio {

    public static void main(String[] args) {
        String fileName = "config.properties";
        Path filePath = Paths.get(fileName);

        // First, let's write a sample file to read
        try {
            List<String> content = List.of(
                "browser=chrome",
                "baseUrl=http://example.com",
                "timeout=5000"
            );
            Files.write(filePath, content);
            System.out.println("Sample file '" + fileName + "' created successfully.");
        } catch (IOException e) {
            System.err.println("Error creating sample file: " + e.getMessage());
            return;
        }

        // Now, read the file using Files.readAllLines()
        System.out.println("\n--- Reading with java.nio.file.Files ---");
        try {
            List<String> lines = Files.readAllLines(filePath);
            lines.forEach(System.out::println);
        } catch (IOException e) {
            System.err.println("An error occurred while reading the file: " + e.getMessage());
        }
    }
}
```

#### Classic Approach: `BufferedReader`

```java
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class FileReadWriteClassic {

    public static void main(String[] args) {
        String fileName = "config.properties"; // Assuming the file from the previous example exists

        System.out.println("\n--- Reading with java.io.BufferedReader ---");
        // Using try-with-resources to ensure the reader is closed automatically
        try (BufferedReader reader = new BufferedReader(new FileReader(fileName))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
        } catch (IOException e) {
            System.err.println("An error occurred while reading the file: " + e.getMessage());
        }
    }
}
```

### 2. Writing to a File

**Scenario**: Write test output logs to a `test-log.txt` file.

#### Modern Approach: `Files.write()` (Recommended)

```java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.List;

public class FileWriteNio {

    public static void main(String[] args) {
        String fileName = "test-log.txt";
        Path filePath = Paths.get(fileName);

        List<String> logEntries = List.of(
            "INFO: Test suite started.",
            "DEBUG: Navigating to login page.",
            "ERROR: Login failed for user 'testuser'."
        );

        System.out.println("--- Writing with java.nio.file.Files ---");
        try {
            // This will create and write to the file, overwriting it if it exists.
            Files.write(filePath, logEntries);
            System.out.println("Successfully wrote to '" + fileName + "'.");

            // To append to the file instead of overwriting:
            Files.write(filePath, List.of("INFO: Test suite finished."), StandardOpenOption.APPEND);
            System.out.println("Successfully appended to '" + fileName + "'.");

        } catch (IOException e) {
            System.err.println("An error occurred while writing to the file: " + e.getMessage());
        }
    }
}
```

#### Classic Approach: `BufferedWriter`

```java
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

public class FileWriteClassic {

    public static void main(String[] args) {
        String fileName = "test-log-classic.txt";
        
        System.out.println("\n--- Writing with java.io.BufferedWriter ---");
        // Use try-with-resources for automatic closing
        // To overwrite the file, new FileWriter(fileName)
        // To append to the file, new FileWriter(fileName, true)
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(fileName, true))) {
            writer.write("INFO: Test suite started.");
            writer.newLine(); // Writes a platform-independent newline
            writer.write("DEBUG: Navigating to login page.");
            writer.newLine();
            writer.write("ERROR: Login failed for user 'testuser'.");
            writer.newLine();
            System.out.println("Successfully wrote to '" + fileName + "'.");
        } catch (IOException e) {
            System.err.println("An error occurred while writing to the file: " + e.getMessage());
        }
    }
}
```

## Best Practices

-   **Use `try-with-resources`**: Always wrap I/O stream objects in a `try-with-resources` statement. This ensures that the stream is automatically closed even if an exception occurs, preventing resource leaks.
-   **Prefer `java.nio.file.Files`**: For common operations like reading all lines or writing a list of strings, use the `Files` class. It's more concise and less error-prone.
-   **Handle `IOException`**: File operations are fragile; the file might not exist, you may not have permissions, or the disk could be full. Always handle `IOException` with appropriate logging and error-handling logic.
-   **Specify Character Encoding**: When dealing with text files that may contain non-ASCII characters, it's good practice to specify the character encoding (e.g., `StandardCharsets.UTF_8`) to avoid Mojibake (garbled text). The `Files` methods have overloads for this.
-   **Use Buffering for Large Files**: When using the classic `java.io` package, always wrap `FileReader`/`FileWriter` in `BufferedReader`/`BufferedWriter` for performance.

## Common Pitfalls

-   **Forgetting to Close Streams**: The single most common error is forgetting to call `.close()` on a stream, leading to resource leaks. `try-with-resources` solves this completely.
-   **Ignoring `IOException`**: Catching an `IOException` and doing nothing (an empty catch block) is a recipe for disaster. At a minimum, log the exception.
-   **Path Issues**: Hardcoding absolute paths (`C:\Users\...`) makes your code non-portable. Use relative paths or construct paths dynamically.
-   **Platform-Dependent Newlines**: Using `\n` for newlines can cause issues on Windows, which expects `\r\n`. Use `writer.newLine()` or `%n` in format strings to be platform-independent. `Files.write()` handles this automatically.

## Interview Questions & Answers

1.  **Q: Why is it important to buffer I/O operations in Java?**
    **A:** Buffering is crucial for performance. Disk I/O is one of the slowest operations a computer performs. Without buffering, each `read()` or `write()` call could result in a separate disk access. `BufferedReader` and `BufferedWriter` minimize physical I/O by reading or writing large chunks of data to/from an in-memory buffer at once. This drastically reduces the number of system calls and disk interactions, leading to much faster execution.

2.  **Q: What is the `try-with-resources` statement and why should you always use it for I/O?**
    **A:** The `try-with-resources` statement, introduced in Java 7, automatically manages the lifecycle of resources that implement the `AutoCloseable` interface (like I/O streams). You declare the resource in the `try()` parentheses, and the language guarantees that the `.close()` method will be called on that resource when the block is exited, whether normally or due to an exception. This prevents resource leaks and makes the code cleaner and safer by eliminating the need for an explicit `finally` block to close the resource.

3.  **Q: You need to read a properties file in your test framework. Which Java classes would you use and why?**
    **A:** For simplicity and readability, I would use the `java.nio.file.Files` and `java.util.Properties` classes. First, I'd create a `Path` object using `Paths.get("path/to/file.properties")`. Then, I would get a `BufferedReader` using `Files.newBufferedReader(path)`. Finally, I would load the properties using `properties.load(reader)`. This approach is clean and leverages the modern NIO library while integrating with the classic `Properties` class. The `try-with-resources` statement would ensure the reader is closed properly.

    ```java
    Properties props = new Properties();
    Path path = Paths.get("framework.properties");
    try (BufferedReader reader = Files.newBufferedReader(path)) {
        props.load(reader);
    } catch (IOException e) {
        // Handle exception: log and re-throw as a runtime exception
        throw new RuntimeException("Failed to load properties file: " + path, e);
    }
    String browser = props.getProperty("browser");
    ```

## Hands-on Exercise

1.  **Create a CSV Data Writer**: Write a Java method `writeCsvData(String fileName, List<String[]> data)` that takes a file name and a list of string arrays (representing rows and columns).
2.  **Implementation**: Use `BufferedWriter` or `Files.write` to write the data to the specified CSV file. Each inner array should be a row, and its elements should be joined by a comma. Each row should be on a new line.
3.  **Create a CSV Data Reader**: Write a Java method `readCsvData(String fileName)` that reads the CSV file you created and prints its contents to the console, parsing each line back into a structured format (e.g., print each "cell" value separately).
4.  **Verification**: In your `main` method, create some sample data (e.g., a list of user credentials), call your writer method, then call your reader method to verify the data was written and read correctly.

## Additional Resources

-   [Baeldung - Java Write to File](https://www.baeldung.com/java-write-to-file)
-   [Oracle Java Tutorials - Basic I/O](https://docs.oracle.com/javase/tutorial/essential/io/index.html)
-   [GeeksforGeeks - BufferedReader class in Java](https://www.geeksforgeeks.org/bufferedreader-class-in-java/)
---
# java-1.5-ac12.md

# Java Coding Practice: Triangle Number Pattern Program

## Overview
Pattern programming, especially with numbers, is a fundamental exercise in learning any programming language. It primarily tests a developer's logical thinking, understanding of loops, and problem-solving abilities. While these exact problems might not directly appear in daily SDET tasks, the underlying concepts of iterative processing, conditional logic, and precise output formatting are crucial. Mastering pattern programs builds a strong foundation for handling more complex data structures and algorithms, which are often encountered in test data manipulation, report generation, or custom test automation utilities.

This section will guide you through creating various triangle number patterns using nested loops in Java, explaining the logic behind each.

## Detailed Explanation
Pattern programs typically rely on nested loops. The outer loop usually controls the number of rows, and the inner loop controls the elements (numbers or characters) within each row. Additional loops or conditional statements might be needed for spacing or complex arrangements.

Let's break down the logic for different number patterns:

### 1. Right-Angled Number Triangle (Numbers Incrementing in Rows)
In this pattern, each row prints numbers starting from 1 up to the current row number.

Example for `rows = 5`:
```
1
1 2
1 2 3
1 2 3 4
1 2 3 4 5
```

**Logic**:
-   The outer loop iterates from `1` to `rows` (for each row).
-   The inner loop iterates from `1` to the current value of the outer loop variable (for printing numbers in the current row).
-   Print the inner loop variable.

### 2. Inverted Right-Angled Number Triangle
This pattern prints numbers from 1 up to a decreasing limit in each row.

Example for `rows = 5`:
```
1 2 3 4 5
1 2 3 4
1 2 3
1 2
1
```

**Logic**:
-   The outer loop iterates from `rows` down to `1`.
-   The inner loop iterates from `1` to the current value of the outer loop variable.
-   Print the inner loop variable.

### 3. Number Pyramid Pattern
This pattern creates a symmetrical pyramid shape, often requiring careful handling of spaces before printing numbers.

Example for `rows = 5`:
```
    1
   2 3
  4 5 6
 7 8 9 10
11 12 13 14 15
```

**Logic**:
-   A counter variable `num` is maintained to print sequential numbers.
-   The outer loop iterates for each row.
-   An inner loop prints leading spaces: `rows - i` spaces for each row `i`.
-   Another inner loop prints numbers: `i` numbers for each row `i`.
-   Increment `num` after printing each number.

## Code Implementation

```java
public class NumberPatternPrograms {

    /**
     * Prints a right-angled number triangle where numbers increment in each row.
     * Example (rows = 5):
     * 1
     * 1 2
     * 1 2 3
     * 1 2 3 4
     * 1 2 3 4 5
     *
     * @param rows The number of rows for the triangle.
     */
    public static void printRightAngledNumberTriangle(int rows) {
        System.out.println("Right-Angled Number Triangle:");
        if (rows <= 0) {
            System.out.println("Number of rows must be positive.");
            return;
        }
        for (int i = 1; i <= rows; i++) { // Outer loop for rows
            for (int j = 1; j <= i; j++) { // Inner loop for numbers in current row
                System.out.print(j + " ");
            }
            System.out.println(); // Move to the next line after each row
        }
        System.out.println();
    }

    /**
     * Prints an inverted right-angled number triangle.
     * Example (rows = 5):
     * 1 2 3 4 5
     * 1 2 3 4
     * 1 2 3
     * 1 2
     * 1
     *
     * @param rows The number of rows for the triangle.
     */
    public static void printInvertedRightAngledNumberTriangle(int rows) {
        System.out.println("Inverted Right-Angled Number Triangle:");
        if (rows <= 0) {
            System.out.println("Number of rows must be positive.");
            return;
        }
        for (int i = rows; i >= 1; i--) { // Outer loop for rows (decreasing)
            for (int j = 1; j <= i; j++) { // Inner loop for numbers in current row
                System.out.print(j + " ");
            }
            System.out.println();
        }
        System.out.println();
    }

    /**
     * Prints a number pyramid pattern.
     * Example (rows = 5):
     *     1
     *    2 3
     *   4 5 6
     *  7 8 9 10
     * 11 12 13 14 15
     *
     * @param rows The number of rows for the pyramid.
     */
    public static void printNumberPyramid(int rows) {
        System.out.println("Number Pyramid Pattern:");
        if (rows <= 0) {
            System.out.println("Number of rows must be positive.");
            return;
        }
        int num = 1; // Counter for sequential numbers
        for (int i = 1; i <= rows; i++) { // Outer loop for rows
            // Print leading spaces
            for (int j = 1; j <= rows - i; j++) {
                System.out.print("  "); // Two spaces for alignment
            }
            // Print numbers
            for (int k = 1; k <= i; k++) {
                System.out.print(num + " ");
                num++;
            }
            System.out.println();
        }
        System.out.println();
    }

    public static void main(String[] args) {
        int numberOfDesiredRows = 5;

        // Test the right-angled number triangle
        printRightAngledNumberTriangle(numberOfDesiredRows);

        // Test the inverted right-angled number triangle
        printInvertedRightAngledNumberTriangle(numberOfDesiredRows);

        // Test the number pyramid
        printNumberPyramid(numberOfDesiredRows);

        // Test with edge case
        System.out.println("Testing with 0 rows:");
        printRightAngledNumberTriangle(0);
    }
}
```

## Best Practices
-   **Meaningful Variable Names**: Use `rows`, `i` (for row index), `j` (for column index or number value), `num` (for sequential numbers). This makes the code easier to understand.
-   **Input Validation**: Always add checks for invalid inputs, such as `rows <= 0`, to prevent unexpected behavior or infinite loops.
-   **Modularize**: Break down different patterns into separate methods (as shown above) for better organization and reusability.
-   **Consistent Spacing**: Maintain consistent spacing (`" "` or `"  "`) between printed elements to ensure the pattern looks correct.
-   **Readability**: Use comments to explain the logic of each loop and section, especially for complex patterns.

## Common Pitfalls
-   **Off-by-one Errors**: Incorrect loop conditions (`<` vs `<=`) can lead to missing or extra rows/elements. Always trace the loops for the first few iterations.
-   **Incorrect Loop Boundaries**: Forgetting to adjust loop conditions when printing an inverted or a specific range of numbers.
-   **Ignoring Spaces**: For patterns like the pyramid, forgetting to print the correct number of leading spaces will distort the shape.
-   **Missing Newline**: Forgetting `System.out.println()` at the end of the outer loop will print all elements on a single line instead of creating rows.
-   **Hardcoding Values**: Avoid hardcoding the number of rows or any other dynamic values within the loops; always use variables passed as arguments or defined at the start.

## Interview Questions & Answers
1.  **Q: How do you approach solving a new pattern program?**
    **A:** I start by analyzing the pattern to identify key characteristics:
    *   **Rows**: How many rows are there? This determines the outer loop.
    *   **Columns/Elements per Row**: How many elements are in each row, and how does this number change (e.g., increments, decrements, fixed)? This defines the inner loop's condition.
    *   **What to Print**: What specific character or number should be printed? Is it `i`, `j`, a counter, or a fixed character?
    *   **Spaces**: Are leading or internal spaces required for alignment?
    *   **Symmetry**: Is the pattern symmetrical (like a pyramid)? This often implies two parts: one for spaces, one for elements.
    Once these are clear, I set up nested loops accordingly, typically starting with the outer loop for rows, then inner loops for spaces and elements.

2.  **Q: Explain the role of nested loops in pattern printing.**
    **A:** Nested loops are fundamental for generating patterns. The **outer loop** is responsible for iterating through each **row** of the pattern. For each iteration of the outer loop (i.e., for each row), the **inner loop** executes, controlling the **elements** (numbers, characters, or spaces) that are printed within that specific row. If there's a need for both leading spaces and elements, there might be two or more inner loops: one for spaces, and another for the actual pattern elements. The combination of their iteration ranges and the values they print dictates the final shape and content of the pattern.

3.  **Q: What is the time complexity of a typical `N`-row pattern program using nested loops?**
    **A:** The time complexity for most pattern programs involving nested loops (where the inner loop depends on the outer loop's iteration) is typically **O(N^2)**, where N is the number of rows.
    *   The outer loop runs `N` times.
    *   The inner loop runs approximately `N` times in its worst case (e.g., in the last row of a triangle).
    *   Therefore, the total operations are proportional to `N * N`.
    For patterns involving leading spaces, there might be an additional inner loop, but its iterations are also proportional to `N`, so the overall complexity remains O(N^2).

## Hands-on Exercise
Implement a Java program to print the following number diamond pattern for a given number of rows.

Example for `rows = 5`:
```
    1
   1 2
  1 2 3
 1 2 3 4
1 2 3 4 5
 1 2 3 4
  1 2 3
   1 2
    1
```
*(Hint: You can achieve this by combining and adapting the logic from the right-angled triangle and inverted right-angled triangle patterns, along with space handling.)*

## Additional Resources
-   **GeeksforGeeks - Java Program to Print Patterns**: [https://www.geeksforgeeks.org/java-program-to-print-patterns/](https://www.geeksforgeeks.org/java-program-to-print-patterns/)
-   **Programiz - Java Programs to Print Pattern**: [https://www.programiz.com/java-programming/examples/print-pattern](https://www.programiz.com/java-programming/examples/print-pattern)
-   **HackerRank / LeetCode**: Search for "Pattern Printing" or "Nested Loops" problems for more practice.
