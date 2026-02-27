package com.sdet.portfolio.core.oop;

/**
 * Inheritance: Deriving a new class from an existing one for code reuse.
 * 
 * Your Task:
 * 1. Implement 'BaseElement' with common methods like 'click()' and 'getText()'.
 * 2. Create a child class 'Button' that extends 'BaseElement'.
 * 3. In 'Button', override the 'click()' method to add a custom log message like "Button clicked: [label]".
 */
public class InheritanceExample {

    public static class BaseElement {
        protected String name;

        public BaseElement(String name) {
            this.name = name;
        }

        // TODO: Implement public void click() { System.out.println("Clicking element: " + name); }
        public void click() {
            System.out.println("Clicking element: " + name);
        }
        
        // TODO: Implement public String getText() { return "Text from " + name; }
        public String getText() {
            return "Text from " + name;
        }
    }

    // TODO: Create public static class Button extends BaseElement
    // 1. Add a constructor that calls super(name)
    // 2. Override click() to be more specific
    public static class Button extends BaseElement {
        public Button(String name) {
            super(name);
        }

        @Override
        public void click() {
            System.out.println("Button clicked: " + name);
        }
    }
}
