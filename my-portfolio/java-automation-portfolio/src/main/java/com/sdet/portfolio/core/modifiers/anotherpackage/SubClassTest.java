package com.sdet.portfolio.core.modifiers.anotherpackage;

import com.sdet.portfolio.core.modifiers.AccessModifiersDemo;

public class SubClassTest extends AccessModifiersDemo {
   
    public static void main(String[] args) {
        SubClassTest sub = new SubClassTest();

        System.out.println("Accessing from a different class in a different package:");
        System.out.println("Public: " + sub.publicVar); // Accessible
        // System.out.println("Private: " + sub.privateVar); // Not Accessible
        System.out.println("Protected: " + sub.protectedVar);
        // System.out.println("Default: " + sub.defaultVar); // Not Accessible
    }
     /*
     * Detailed Explanation: Static vs. Instance Context
     *
     * Why do we need to create an object of SubClassTest (e.g., `new SubClassTest()`)
     * when we are already "inside" the class?
     *
     * The reason is the difference between a `static` context and an `instance` (non-static) context.
     *
     * 1. Static vs. Instance:
     *    - Static members (like the `main` method) belong to the class itself, not to any particular
     *      object created from that class. They can be called without creating an object.
     *    - Instance members (like the `protectedVar` you inherited from AccessModifiersDemo) belong
     *      to a specific object (an instance) of the class. They don't exist until you create
     *      an object using `new`. Each object gets its own copy of these variables.
     *
     * 2. No `this` in a Static Context:
     *    Because a `static` method isn't attached to a specific object, there is no `this`
     *    reference. You can't write `this.protectedVar` inside the `main` method, because Java
     *    wouldn't know *which object's* `protectedVar` you're talking about. The `main` method
     *    is the entry point of the program and runs before any objects of your class might exist.
     *
     * 3. The Solution:
     *    To access an instance variable from a static context, you must first create an instance.
     *    `SubClassTest sub = new SubClassTest();`
     *    This line creates a new `sub` object, which now contains all the instance fields from
     *    its class and parent classes, including `protectedVar`. You can then access the variable
     *    through that specific object: `sub.protectedVar`.
     *
     * --- Example of Access in a Non-Static Context ---
     *
     * If you were in a non-static (instance) method, you would NOT need to create a new object
     * because the method itself would be called on an existing object.
     *
     * public class SubClassTest extends AccessModifiersDemo {
     *
     *     // This is an INSTANCE method, not static. It belongs to an object.
     *     public void myInstanceMethod() {
     *         // Here, you can access the inherited variable directly. The `this` keyword
     *         // is implicit, referring to the object this method was called on.
     *         System.out.println("Protected (from instance method): " + this.protectedVar);
     *         System.out.println("Public (from instance method): " + publicVar);
     *     }
     *
     *     // To call the instance method from a static context, you still need an object first.
     *     public static void main(String[] args) {
     *          SubClassTest anotherSub = new SubClassTest();
     *          anotherSub.myInstanceMethod(); // This is how you would call it.
     *     }
     * }
     */
}
