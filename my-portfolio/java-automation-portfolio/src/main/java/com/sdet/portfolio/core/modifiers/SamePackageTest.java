package com.sdet.portfolio.core.modifiers;

public class SamePackageTest {
    public static void main(String[] args) {
        AccessModifiersDemo demo = new AccessModifiersDemo();

        System.out.println("Accessing from a different class in the same package:");
        System.out.println("Public: " + demo.publicVar); // Accessible
        // System.out.println("Private: " + demo.privateVar); // Not Accessible
        System.out.println("Protected: " + demo.protectedVar); // Accessible
        System.out.println("Default: " + demo.defaultVar); // Accessible

    }
}
