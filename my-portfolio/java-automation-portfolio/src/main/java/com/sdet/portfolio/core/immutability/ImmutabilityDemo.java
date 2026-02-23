package com.sdet.portfolio.core.immutability;

/**
 * java-1.1-ac4: String Immutability
 */
public class ImmutabilityDemo {
    public static void main(String[] args) {
        String s = "Hello";
        s.concat(" World");
        
        System.out.println("Original String after concat (without assignment): " + s);
        
        String sNew = s.concat(" World");
        System.out.println("New String after concat (with assignment): " + sNew);
        
        // Task: Demonstrate how 's' hasn't changed despite the concat() call.
        System.out.println("Final value of 's' is still: " + s);
        // The line above proves that the original string `s` was not modified by the .concat() method.
        // This is because String objects are immutable in Java. Methods like .concat() return a new String object with the result, leaving the original unchanged.
        
    }
}
