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
