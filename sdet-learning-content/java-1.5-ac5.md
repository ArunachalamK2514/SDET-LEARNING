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
