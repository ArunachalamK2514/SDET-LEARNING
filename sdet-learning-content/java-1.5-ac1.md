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
