# Java Core Concepts: JDK, JRE, and JVM

## 1. JDK (Java Development Kit)
*Explain what JDK is and list its main components.*
This is the Java Development Kit that comprises of JRE and JVM. This is the full development environment that facilitates writing and executing java files. The components of the JDK are:
 - JVM
 - JRE
 - javac
 - java
 - javadoc
 - jar
 - jdb

## 2. JRE (Java Runtime Environment)
*Explain what JRE is and its role in running Java applications.*

JRE is Java Runtime Environment that contains JVM and java libraries like java util library for running the compiled java code (.class files). For running a compiled java code, JRE is enough.

## 3. JVM (Java Virtual Machine)
*Describe the JVM architecture (ClassLoader, Runtime Data Areas, Execution Engine).*

The JVM consists of the ClassLoader (loads .class files), Runtime Data Areas (memory like the Heap and Stack), and the Execution Engine (converts bytecode to machine code via JIT or Interpretation). It serves as the abstract computing machine that enables Java's "Write Once, Run Anywhere" capability.

## 4. Key Differences & Relationship
*Provide a comparison or a diagram description showing how they relate.*

The JDK is the full development kit (tools + JRE), the JRE is the environment needed to run Java (JVM + libraries), and the JVM is the specific engine that executes the code. Think of the JDK as the kitchen (tools/appliances), the JRE as the pantry (ingredients), and the JVM as the chef who actually cooks the meal.

## 5. Real-World Examples in Test Automation
*Explain how understanding these components helps in setting up automation environments (e.g., setting JAVA_HOME, running JARs, etc.).*

Understanding these helps you correctly set JAVA_HOME (pointing to the JDK) so build tools like Maven/Gradle can compile tests, and allows you to optimize the JVM Heap Size (using -Xmx flags) to prevent OutOfMemoryErrors during heavy parallel execution. It also ensures you are running JAR files on a compatible JRE version to avoid "Unsupported Class Version" errors during CI/CD pipeline runs.
