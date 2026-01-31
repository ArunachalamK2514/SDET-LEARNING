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