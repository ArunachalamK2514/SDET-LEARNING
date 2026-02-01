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
