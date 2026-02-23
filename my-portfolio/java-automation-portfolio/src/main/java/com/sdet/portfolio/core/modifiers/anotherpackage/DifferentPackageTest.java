package com.sdet.portfolio.core.modifiers.anotherpackage;
import com.sdet.portfolio.core.modifiers.AccessModifiersDemo;

public class DifferentPackageTest {

    public static void main(String[] args){
        AccessModifiersDemo demo = new AccessModifiersDemo();

        System.out.println("Accessing from a different class in a different package:");
        System.out.println("Public: " + demo.publicVar); // Accessible
        // System.out.println("Private: " + demo.privateVar); // Not Accessible
        // System.out.println("Protected: " + demo.protectedVar); // Not Accessible
        // System.out.println("Default: " + demo.defaultVar); // Not Accessible
    }
    
}
