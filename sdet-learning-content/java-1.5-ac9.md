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