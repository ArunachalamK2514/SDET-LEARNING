# OOP Pillars in Test Automation

## 1. Encapsulation
- **Definition:** Bundling data and methods that operate on that data within a single unit (class), and restricting direct access to internal fields.
- **Application in Automation:** Ensuring sensitive data like credentials are not directly accessible, and using getters/setters for controlled access.

## 2. Inheritance
- **Definition:** A mechanism where a new class inherits properties and methods from an existing class.
- **Application in Automation:** Creating base classes for common UI elements or test components, allowing derived classes to reuse and extend functionality.

## 3. Polymorphism
- **Definition:** The ability of an object to take many forms. It allows methods to be overridden in subclasses.
- **Application in Automation:** Using interfaces or abstract classes to define common behavior, enabling different implementations for different drivers (e.g., ChromeDriver, FirefoxDriver).

## 4. Abstraction
- **Definition:** Hiding complexity and showing only essential features.
- **Application in Automation:** Creating abstract base classes for common test page behaviors, allowing concrete implementations to define specific logic.