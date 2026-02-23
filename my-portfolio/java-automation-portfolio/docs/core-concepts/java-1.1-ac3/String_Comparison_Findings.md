# String Comparison: == vs .equals()

## Concepts
*   **== Operator:** *Explain what this compares (references).*
    The `==` operator compares the references of the two objects not the values. When 2 string literals with the same value are created, both point to the same object in the String pool and hence have the same reference.
*   **.equals() Method:** *Explain what this compares (content).*
    The `.equals()` operator compares actual value or the content (sequence of characters) of the objects and literals. Even of the objects point to different memory references, if the content / the sequence of the characters are same, this will return true. This operator should be used to compare the actual values in test automation.
*   **String Pool:** *Briefly explain what the String Pool is and how it affects comparison.*
    The String Pool is a special memory area in the Java heap where String literals are stored. When you declare a String literal (e.g., `String s1 = "test";`), the JVM checks the pool for an identical string. If one exists, it returns a reference to the existing string; otherwise, it creates a new one and adds it to the pool.

    This affects comparison because the `==` operator checks for reference equality (if two variables point to the same object in memory). For identical string literals, `==` will return `true`. However, strings created with `new String("test")` are allocated directly on the heap, outside the pool, so `==` will return `false` even if the content is the same. Therefore, always use `.equals()` to reliably compare the actual content of strings.

## Demonstration Results
| Comparison | Result (true/false) | Explanation |
|------------|---------------------|-------------|
| s1 == s2   |       true              |     Both are string literals so both s1 and s2 have same reference and hence the `==` operator returns true        |
| s1.equals(s2) |    true              |     Both s1 and s2 literals have the same content or the sequence of characters. Hence the `.equals()` operator returns true        |
| s1 == s3   |       false              |    s1 is inside the string pool with one reference and the string s3 is in heap memory with a different reference. So the `==` operator will return false         |
| s1.equals(s3) |    true              |     Though s1 and s2 have different references, the content or the sequence of characters is the same. So the `.equals()` operator in this case will return true        |
