package com.sdet.portfolio.core.stringperformance;

/**
 * java-1.1-ac5: Create comparison table for String, StringBuilder, and StringBuffer with performance benchmarks.
 * 
 * This class demonstrates the performance differences between immutable String 
 * and mutable StringBuilder/StringBuffer when performing multiple modifications.
 */
public class StringPerformanceBenchmark {

    public static final int ITERATIONS = 50000;

    public static void main(String[] args) {
        System.out.println("Starting String Performance Benchmarks with " + ITERATIONS + " iterations...");

        runStringBenchmark();
        runStringBuilderBenchmark();
        runStringBufferBenchmark();
        
        System.out.println("--- Hands-on Exercise: JSON Building ---");
        demonstrateJsonBuilding();
    }

    private static void runStringBenchmark() {
        long startTime = System.currentTimeMillis();
        String result = "";
        for (int i = 0; i < ITERATIONS; i++) {
            result += "x";
        }
        long endTime = System.currentTimeMillis();
        System.out.println("String (+) concatenation: " + (endTime - startTime) + " ms");
    }

    private static void runStringBuilderBenchmark() {
        long startTime = System.currentTimeMillis();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < ITERATIONS; i++) {
            sb.append("x");
        }
        String result = sb.toString();
        long endTime = System.currentTimeMillis();
        System.out.println("StringBuilder append:      " + (endTime - startTime) + " ms");
    }

    private static void runStringBufferBenchmark() {
        long startTime = System.currentTimeMillis();
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < ITERATIONS; i++) {
            sb.append("x");
        }
        String result = sb.toString();
        long endTime = System.currentTimeMillis();
        System.out.println("StringBuffer append:       " + (endTime - startTime) + " ms");
    }

    /**
     * Demonstrates building a JSON payload, a common SDET task.
     */
    private static void demonstrateJsonBuilding() {
        // StringBuilder is preferred for single-threaded tasks like this
        StringBuilder json = new StringBuilder();
        json.append("{")
            .append("\n  \"user\": \"sdet_tester\",")
            .append("\n  \"id\": 101,")
            .append("\n  \"status\": \"active\",")
            .append("\n  \"role\": \"admin\",")
            .append("\n  \"permissions\": [\"read\", \"write\"]")
            .append("\n}");
        
        System.out.println("Constructed JSON Payload:");
        System.out.println(json.toString());
    }
}
