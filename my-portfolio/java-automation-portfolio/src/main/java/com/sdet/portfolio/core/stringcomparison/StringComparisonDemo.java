package com.sdet.portfolio.core.stringcomparison;

/**
 * java-1.1-ac3: == vs .equals() for String comparison
 */
public class StringComparisonDemo {
    public static void main(String[] args) {
        // Task: Demonstrate reference vs content comparison
        // 1. Literal Strings (String Pool)
        String s1 = "Hello";
        String s2 = "Hello";

        // 2. New String objects (Heap Memory)
        String s3 = new String("Hello");

        // Your task: Use == and .equals() to compare these and print the results
        System.out.println("--- String Comparison Demonstration ---");
        // Comparing s1 and s2 using ==
        System.out.println("s1 == s2 : " + (s1 == s2)); // true
        System.out.println("s1.equals(s2) : " + s1.equals(s2)); // true
        System.out.println("s1 == s3 : " + (s1 == s3)); // false
        System.out.println("s2.equals(s3) : " + s2.equals(s3)); // true

    }
}
