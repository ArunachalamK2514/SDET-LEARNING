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
