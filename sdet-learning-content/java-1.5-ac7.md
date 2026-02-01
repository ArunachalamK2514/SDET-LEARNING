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
