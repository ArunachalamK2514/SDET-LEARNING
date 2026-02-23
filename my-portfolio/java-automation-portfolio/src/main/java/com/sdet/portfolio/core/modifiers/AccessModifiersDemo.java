package com.sdet.portfolio.core.modifiers;

/**
 * java-1.1-ac2: Access Modifiers Demonstration
 */
public class AccessModifiersDemo {

    // 1. Public: Accessible from anywhere
    public String publicVar = "I am Public";

    // 2. Private: Accessible only within this class
    private String privateVar = "I am Private";

    // 3. Protected: Accessible within the same package and by subclasses
    protected String protectedVar = "I am Protected";

    // 4. Default (Package-Private): Accessible only within the same package
    String defaultVar = "I am Default";

    public void displayModifiers() {
        System.out.println("Accessing from within the same class:");
        System.out.println("Public: " + publicVar);
        System.out.println("Private: " + privateVar);
        System.out.println("Protected: " + protectedVar);
        System.out.println("Default: " + defaultVar);
    }
}
