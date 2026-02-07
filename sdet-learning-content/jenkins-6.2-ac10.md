# Jenkins Email Notifications on Build Success/Failure

## Overview
Email notifications are a crucial aspect of Continuous Integration/Continuous Delivery (CI/CD) pipelines, providing immediate feedback to development teams about the status of their builds. Timely alerts on build success or, more critically, build failures, enable rapid identification and resolution of issues, preventing them from escalating. This feature focuses on configuring Jenkins to send automated email notifications, enhancing team communication and operational efficiency.

## Detailed Explanation

Jenkins uses plugins, primarily the "Email Extension Plugin" (often referred to as `emailext`), to send customizable email notifications. This plugin offers extensive flexibility over standard Jenkins email functionality, allowing for rich HTML content, attachments, and conditional sending based on build status (e.g., success, failure, unstable, aborted).

The process generally involves:
1.  **Configuring an SMTP Server in Jenkins**: Jenkins needs to know how to send emails. This involves setting up the SMTP server details, authentication credentials, and sender email address in Jenkins' global configuration.
2.  **Integrating `emailext` in Jenkins Pipelines**: For Pipeline jobs (declarative or scripted), the `emailext` step is typically placed within the `post` section. This ensures that the email is sent after the main build steps have completed, regardless of their outcome.
3.  **Configuring Recipients and Subject Line**: The `emailext` step allows you to define who receives the emails (e.g., developers, project managers), the subject line, and the body of the email. You can use Groovy scripts to dynamically generate content based on build variables.
4.  **Conditional Sending**: The `emailext` plugin supports various triggers within the `post` block, such as `always`, `success`, `failure`, `unstable`, `aborted`, and `fixed`. This enables sending different emails or to different recipients based on the build's final status.

### Example Scenario:
Imagine a `Jenkinsfile` for a Java project using Maven. We want to send an email to the committer and a development lead on build failure, and a summary email to the team on success.

## Code Implementation

```groovy
// Jenkinsfile (Declarative Pipeline)

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your-org/your-repo.git' // Replace with your repository URL
            }
        }
        stage('Build') {
            steps {
                script {
                    try {
                        sh 'mvn clean install'
                    } catch (Exception e) {
                        currentBuild.result = 'FAILURE'
                        throw e // Re-throw to mark pipeline as failure
                    }
                }
            }
        }
        stage('Test') {
            steps {
                script {
                    try {
                        sh 'mvn test'
                    } catch (Exception e) {
                        currentBuild.result = 'UNSTABLE' // Or FAILURE if tests are critical
                        throw e
                    }
                }
            }
        }
        // ... potentially more stages like Deploy, etc.
    }

    post {
        always {
            // Clean up workspace regardless of build status
            deleteDir()
        }
        success {
            echo "Build successful! Sending success notification..."
            emailext (
                subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - SUCCESS",
                body: """
                    <h2>${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - SUCCESS</h2>
                    <p>Check console output at: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p>Commit: ${currentBuild.changeSets.collect { it.items.collect { i -> i.commitId + ' - ' + i.msg } }.join('<br/>')}</p>
                    <p>Started by: ${currentBuild.getCauseOf("hudson.model.Cause$UserIdCause").getUserName() ?: 'Unknown User'}</p>
                """,
                to: "team@example.com", // Static recipient for success
                mimeType: 'text/html'
            )
        }
        failure {
            echo "Build failed! Sending failure notification..."
            emailext (
                subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - FAILED!",
                body: """
                    <h2>${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - FAILED!</h2>
                    <p><b>Cause of failure:</b> ${currentBuild.result}</p>
                    <p>Check console output at: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p>Error details: ${currentBuild.log.split('
').findAll { it.contains('ERROR') }.join('<br/>')}</p>
                    <p>Started by: ${currentBuild.getCauseOf("hudson.model.Cause$UserIdCause").getUserName() ?: 'Unknown User'}</p>
                """,
                to: "dev-lead@example.com, ${currentBuild.changeSets.collect { it.items.collect { i -> i.authorEmail } }.join(',')}", // Dynamic recipients: lead + committer
                mimeType: 'text/html'
            )
        }
        unstable {
            echo "Build unstable! Sending unstable notification..."
            emailext (
                subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - UNSTABLE",
                body: """
                    <h2>${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - UNSTABLE</h2>
                    <p>Some tests failed, but build might still be deployable.</p>
                    <p>Check console output at: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                """,
                to: "qa@example.com",
                mimeType: 'text/html'
            )
        }
        // fixed block can be used when a build transitions from FAILED to SUCCESS
        fixed {
            echo "Build fixed! Sending fixed notification..."
            emailext (
                subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - FIXED!",
                body: """
                    <h2>${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - FIXED!</h2>
                    <p>The build has been restored to a stable state!</p>
                    <p>Check console output at: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                """,
                to: "team@example.com",
                mimeType: 'text/html'
            )
        }
    }
}
```

### Setup in Jenkins UI:
1.  **Install "Email Extension Plugin"**: Navigate to `Manage Jenkins` -> `Manage Plugins` -> `Available plugins`. Search for "Email Extension Plugin" and install it.
2.  **Configure System Email**: Navigate to `Manage Jenkins` -> `Configure System`.
    *   Scroll down to the "Extended E-mail Notification" section.
    *   **SMTP Server**: `smtp.example.com` (e.g., `smtp.gmail.com` for Gmail, requiring app password)
    *   **Default user E-mail suffix**: `@example.com`
    *   **Use SMTP Authentication**: Check this if your SMTP server requires it.
        *   **Username**: Your SMTP username
        *   **Password**: Your SMTP password
    *   **Use SSL/TLS**: Check if required (e.g., for Gmail, port 465 with SSL, or 587 with TLS).
    *   **SMTP Port**: `465` or `587`
    *   **Charset**: `UTF-8`
    *   **Default Content Type**: `HTML (text/html)`
    *   **Default Subject**: `${DEFAULT_SUBJECT}`
    *   **Default Content**: `${DEFAULT_CONTENT}`
    *   **Default Recipients**: Comma-separated list of default recipients.
    *   **Advanced**: Test Configuration by sending a test email.

## Best Practices
-   **Use the `emailext` plugin**: It provides far more flexibility and customization than Jenkins' built-in email notifier.
-   **Configure globally and override locally**: Set up default SMTP settings globally, then customize email content and recipients per pipeline using the `emailext` step.
-   **Dynamic Recipients**: Utilize Jenkins environment variables and Groovy to send emails to relevant parties (e.g., `currentBuild.changeSets` for committers, `env.BUILD_USER_EMAIL`).
-   **Clear Subject Lines**: Make subject lines informative, including job name, build number, and status.
-   **Actionable Email Body**: Provide links to the build console output, test reports, and relevant logs to help recipients quickly diagnose issues. Include key information like commit messages and who started the build.
-   **HTML Content**: Use HTML for better readability and formatting of email notifications.
-   **Rate Limiting/Throttling**: For very active pipelines, consider plugins or strategies to prevent email floods, especially for unstable or rapidly failing builds.
-   **Security**: Use Jenkins Credentials for SMTP authentication instead of hardcoding passwords in `Configure System`.

## Common Pitfalls
-   **Incorrect SMTP Configuration**: Mismatched port numbers, incorrect authentication, or firewall blocking outgoing SMTP traffic. Always test the configuration in `Manage Jenkins` -> `Configure System`.
-   **Missing "Email Extension Plugin"**: The `emailext` step will fail if the plugin is not installed.
-   **Permissions Issues**: The Jenkins user might not have permission to send emails through the configured SMTP server.
-   **Email Spam Filters**: Notifications might end up in spam folders. Advise users to whitelist the sender's email address.
-   **Overly Verbose Emails**: Sending too much information or too many emails can lead to recipients ignoring them. Be concise and provide links to detailed information.
-   **Hardcoding Recipients**: While quick for initial setup, hardcoding `to` addresses makes maintenance difficult. Use dynamic methods for flexibility.
-   **Encoding Issues**: Ensure `Charset` is set correctly (e.g., `UTF-8`) to avoid garbled characters in emails.

## Interview Questions & Answers
1.  **Q: How do you configure email notifications in Jenkins for a pipeline job?**
    **A:** First, I ensure the "Email Extension Plugin" is installed. Then, I configure the global SMTP settings under `Manage Jenkins` -> `Configure System` (SMTP server, port, credentials). For the pipeline job, I use the `emailext` step within the `post` block of my `Jenkinsfile`. I typically define `success`, `failure`, and `fixed` blocks to send different notifications. Inside `emailext`, I specify `subject`, `body` (often in HTML with dynamic build variables), and `to` recipients, which can be static or dynamically derived from committers.

2.  **Q: What are the advantages of using the Email Extension Plugin over the default Jenkins email notification?**
    **A:** The Email Extension Plugin offers significantly more flexibility. Key advantages include:
    *   **Rich HTML Content**: Allows for well-formatted, readable emails.
    *   **Dynamic Content**: Extensive use of Groovy scripts and build variables to customize subject and body.
    *   **Conditional Triggers**: More granular control over when emails are sent (e.g., `failure`, `unstable`, `fixed`, `regression`, `always`).
    *   **Recipient Lists**: Supports more complex recipient logic, including dynamic lists based on committers, build status, or even email-ext properties files.
    *   **Attachments**: Ability to attach build artifacts or logs.
    *   **Throttling**: Built-in features to prevent spamming.

3.  **Q: How would you dynamically send a build failure email to the committer(s) of the failing build?**
    **A:** In the `failure` block of the `post` section in the `Jenkinsfile`, I would use the `currentBuild.changeSets` object. This object contains information about the changes that triggered the build, including committer details. I can iterate through `currentBuild.changeSets.collect { it.items.collect { i -> i.authorEmail } }` to extract the email addresses of the committers and add them to the `to` field of the `emailext` step. This ensures that the people responsible for the changes are immediately notified.

## Hands-on Exercise
1.  **Set up a local Jenkins instance**: You can use Docker to quickly spin up a Jenkins container (`docker run -p 8080:8080 -p 50000:50000 --name jenkins jenkins/jenkins:lts`).
2.  **Install Email Extension Plugin**: Follow the steps in the "Setup in Jenkins UI" section.
3.  **Configure an SMTP server**: Use a free SMTP service (like Mailtrap.io for testing, or a Gmail account with an app password) to configure the "Extended E-mail Notification" in Jenkins System Configuration. Test the configuration.
4.  **Create a new Pipeline job**: Name it `Email_Notification_Demo`.
5.  **Paste the provided `Jenkinsfile` example**: Modify the `git` repository URL to a simple public repository or even remove the `git` step and use a placeholder `sh 'echo "Simulating build..."'` for quick testing.
6.  **Simulate Success and Failure**:
    *   For success, ensure all `sh` commands pass.
    *   For failure, intentionally introduce an error in the `sh` command, e.g., `sh 'exit 1'`, in the `Build` stage to trigger a failure.
7.  **Verify Email Delivery**: Check your configured email inbox (or Mailtrap inbox) for the notifications. Observe the subject line, body content, and recipients for both success and failure scenarios.

## Additional Resources
-   **Jenkins Email Extension Plugin Wiki**: [https://plugins.jenkins.io/email-ext/](https://plugins.jenkins.io/email-ext/)
-   **Jenkins Pipeline Syntax - Post section**: [https://www.jenkins.io/doc/book/pipeline/syntax/#post](https://www.jenkins.io/doc/book/pipeline/syntax/#post)
-   **Mailtrap (for testing SMTP)**: [https://mailtrap.io/](https://mailtrap.io/)
