# Jenkins Build Triggers: SCM Polling, Webhooks, and Scheduled Builds

## Overview
Automating build initiation is a cornerstone of efficient CI/CD pipelines. Jenkins offers several mechanisms to trigger builds, ensuring that your projects are built and tested at the right time, whether it's in response to code changes, on a fixed schedule, or through external calls. Understanding and configuring these triggers is crucial for maintaining a continuous integration flow.

## Detailed Explanation

Jenkins build triggers define when and how a Jenkins job should start. The most common types are:

### 1. Poll SCM (Source Code Management)
This trigger periodically checks your SCM repository (e.g., Git, SVN) for changes. If changes are detected, Jenkins initiates a new build. It's simple to set up but can be resource-intensive for large teams and frequent polling intervals, as Jenkins has to perform a checkout or diff operation each time.

**Configuration:**
In your Jenkins job configuration, under "Build Triggers," check "Poll SCM."
In the "Schedule" field, use cron syntax to define the polling interval.
- `H/15 * * * *`: Polls every 15 minutes. 'H' (for "hash") distributes the load on Jenkins by running jobs at various times rather than all at once.
- `H * * * *`: Polls hourly.
- `H H(0-3) * * 1-5`: Polls every weekday between midnight and 3 AM.

### 2. Build Periodically
This trigger starts a build at a fixed interval, regardless of whether there have been any SCM changes. This is useful for nightly builds, weekly reports, or scheduled deployments where you want a consistent build even if no code has changed.

**Configuration:**
In your Jenkins job configuration, under "Build Triggers," check "Build Periodically."
In the "Schedule" field, use cron syntax.
- `H H * * *`: Builds daily at a random hour.
- `0 0 * * *`: Builds daily at midnight.
- `0 0 * * 1`: Builds every Monday at midnight.

### 3. GitHub Hook Trigger for GITScm polling (Webhooks)
Webhooks are a more efficient and real-time alternative to SCM polling. Instead of Jenkins constantly checking the repository, the repository (e.g., GitHub, GitLab, Bitbucket) sends a "hook" (an HTTP POST request) to Jenkins whenever a specific event occurs (e.g., a push to a branch). Jenkins then initiates a build. This reduces resource consumption on Jenkins and provides immediate feedback on code changes.

**Configuration (GitHub Example):**
1.  **Jenkins Side:**
    *   In your Jenkins job configuration, under "Build Triggers," check "GitHub hook trigger for GITScm polling."
    *   Ensure your Jenkins instance is accessible from GitHub (if self-hosted, you might need a public IP or a tool like `ngrok`).
    *   Go to "Manage Jenkins" -> "Configure System" -> "GitHub" and add your GitHub server.
2.  **GitHub Repository Side:**
    *   Navigate to your repository on GitHub.
    *   Go to "Settings" -> "Webhooks" -> "Add webhook."
    *   **Payload URL:** `http://YOUR_JENKINS_URL/github-webhook/` (e.g., `http://localhost:8080/github-webhook/` or your public Jenkins URL).
    *   **Content type:** `application/json`.
    *   **Secret (Optional but Recommended):** A secret key to secure the webhook. You'll need to configure this in Jenkins as well (Credentials -> Jenkins -> Global credentials (unrestricted) -> Add Credentials -> Secret text).
    *   **Which events would you like to trigger this webhook?** Select "Just the push event" or other relevant events.
    *   Click "Add webhook."

### 4. Remote Trigger (Trigger builds remotely (e.g., from script))
This allows an external system or script to trigger a build by making an HTTP GET/POST request to a specific Jenkins URL. It requires a security token.

**Configuration:**
In your Jenkins job configuration, under "Build Triggers," check "Trigger builds remotely (e.g., from script)."
Set an "Authentication Token" (e.g., `MY_SECRET_TOKEN`).
The URL to trigger the build will be `JENKINS_URL/job/JOB_NAME/build?token=MY_SECRET_TOKEN` or `JENKINS_URL/job/JOB_NAME/buildWithParameters?token=MY_SECRET_TOKEN` for parameterized builds.

## Code Implementation

### Example: Jenkinsfile (Declarative Pipeline) with SCM Polling and Webhook
While triggers are typically configured in the Jenkins UI for Freestyle jobs, for declarative pipelines, the `triggers` block is used. However, `poll SCM` and `build periodically` are often configured in the UI or in a `pipeline.triggers` section within an `options` block if you want to define them *inside* the Jenkinsfile. GitHub webhooks are primarily configured on the GitHub side and in the Jenkins job configuration (not usually within the Jenkinsfile itself for the hook URL part, but the `githubPush()` trigger can be used).

Let's illustrate how triggers are conceptually associated with a Jenkinsfile-based pipeline.

```groovy
// Jenkinsfile for a sample project

pipeline {
    agent any

    triggers {
        // Poll SCM every 15 minutes (using cron syntax)
        // This is often configured in the job's UI for better separation,
        // but can be declared here.
        pollSCM('H/15 * * * *')

        // Build periodically every night at midnight (random minute)
        // Similar to pollSCM, often configured in UI.
        cron('H 0 * * *')

        // This trigger listens for GitHub push events.
        // The actual webhook URL and secret are configured in Jenkins UI and GitHub.
        // This line in Jenkinsfile ensures the pipeline responds to the trigger.
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                // This step is implicitly handled by the SCM block when the pipeline starts
                script {
                    git url: 'https://github.com/your-org/your-repo.git', branch: 'main'
                }
            }
        }
        stage('Build') {
            steps {
                echo 'Building the application...'
                // Example: execute a shell command to build
                sh 'mvn clean install' // For a Maven project
            }
        }
        stage('Test') {
            steps {
                echo 'Running tests...'
                // Example: execute tests
                sh 'mvn test' // For a Maven project
            }
        }
        stage('Deploy (Staging)') {
            steps {
                echo 'Deploying to staging environment...'
                // Example: deploy using a shell script or another Jenkins plugin
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
            // Clean up workspace, send notifications, etc.
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

**Explanation for triggers within a Jenkinsfile:**
*   `pollSCM('H/15 * * * *')`: This explicitly tells Jenkins to poll the SCM every 15 minutes for changes. If changes are detected, a new build of this pipeline will be triggered.
*   `cron('H 0 * * *')`: This schedules the pipeline to run periodically every day at a random minute past midnight.
*   `githubPush()`: This trigger integrates with the GitHub webhook mechanism. When GitHub sends a push event to the configured Jenkins endpoint, this `githubPush()` trigger ensures the pipeline job starts. This requires prior setup of the GitHub webhook in the repository settings and the Jenkins job configuration.

## Best Practices
-   **Prefer Webhooks over SCM Polling:** For frequently updated repositories, webhooks are more efficient as they trigger builds instantly and reduce the load on Jenkins. SCM polling should be used sparingly or for less critical, infrequently updated projects.
-   **Use "H" for Cron Schedules:** The "H" (hash) symbol in cron expressions helps distribute the load on the Jenkins master by letting Jenkins choose a suitable minute to run the job, preventing many jobs from starting simultaneously.
-   **Secure Webhooks:** Always use a secret token for webhooks (e.g., GitHub webhooks) to ensure that only legitimate requests from your SCM provider can trigger builds.
-   **Combine Triggers Judiciously:** You can use multiple triggers for a single job (e.g., a webhook for immediate pushes and a nightly periodic build for comprehensive checks).
-   **Clear Trigger Descriptions:** Document why a particular trigger is used and its frequency, especially in shared environments.

## Common Pitfalls
-   **Over-Polling SCM:** Setting SCM polling to a very frequent interval (e.g., every minute) for many jobs can overwhelm your Jenkins master and SCM server, leading to performance issues.
-   **Incorrect Cron Syntax:** Misconfigured cron expressions can lead to builds not triggering as expected or triggering at unintended times. Always test your cron expressions.
-   **Webhook Connectivity Issues:** If Jenkins is behind a firewall or not publicly accessible, webhooks from external SCMs (like GitHub.com) won't reach it. Solutions include exposing Jenkins publicly, using reverse proxies, or tools like `ngrok` for testing.
-   **Missing Permissions:** The Jenkins user or API token used for SCM access might not have the necessary permissions to read the repository or receive webhook events.
-   **GitHub/GitLab plugin not installed/configured:** For webhooks to work correctly, the relevant SCM integration plugins (e.g., GitHub plugin) must be installed and properly configured in Jenkins.

## Interview Questions & Answers
1.  **Q: Explain the difference between "Poll SCM" and "GitHub hook trigger for GITScm polling" in Jenkins.**
    **A:** "Poll SCM" is a pull mechanism where Jenkins periodically checks the SCM repository for changes. If changes are found, a build is triggered. It can be resource-intensive. "GitHub hook trigger" (webhooks) is a push mechanism where GitHub actively notifies Jenkins (via an HTTP POST request) when a specific event (like a code push) occurs. This is more efficient as builds are triggered immediately upon change, reducing unnecessary checks by Jenkins.

2.  **Q: When would you use "Build Periodically" over "Poll SCM"?**
    **A:** "Build Periodically" is used when you need to run a build at a fixed, regular interval regardless of code changes. This is ideal for nightly regression tests, scheduled deployments, generating daily reports, or performing maintenance tasks, ensuring a consistent execution even during periods of no development activity. "Poll SCM" is for triggering builds specifically *because* of code changes.

3.  **Q: How do you secure a Jenkins webhook?**
    **A:** You secure a Jenkins webhook by configuring a "Secret" token (also known as a shared secret or webhook secret) on both the SCM provider's side (e.g., GitHub) and in your Jenkins job/system configuration. Jenkins uses this secret to verify the authenticity of incoming webhook requests, ensuring they originate from the legitimate SCM source and haven't been tampered with.

4.  **Q: A Jenkins build is not triggering despite code pushes. What are the common troubleshooting steps you would take?**
    **A:**
    *   **Check Jenkins System Log:** Look for errors related to SCM polling or webhook reception.
    *   **Verify SCM Configuration:** Ensure the repository URL and credentials are correct in Jenkins.
    *   **Check Trigger Configuration:** Double-check the cron syntax for "Poll SCM" or "Build Periodically." For webhooks, confirm "GitHub hook trigger" is checked.
    *   **Verify Webhook Configuration (if applicable):**
        *   On the SCM side (e.g., GitHub settings), check the webhook's "Recent Deliveries" to see if GitHub sent the payload successfully and if Jenkins responded with a 2xx status code.
        *   Ensure the Payload URL in GitHub points to the correct Jenkins webhook endpoint (e.g., `/github-webhook/`).
        *   Verify network connectivity between GitHub and Jenkins.
        *   Check that the webhook secret matches on both sides.
    *   **Check for Ignored Paths/Branches:** Ensure the build trigger isn't configured to ignore changes in the branch or paths where commits were made.
    *   **Jenkins Plugin Status:** Verify that the relevant SCM integration plugins (e.g., GitHub plugin) are installed and up-to-date in Jenkins.

## Hands-on Exercise
1.  **Create a Freestyle Job:** Set up a new Jenkins Freestyle job named `MyTriggerTest`.
2.  **Configure SCM:** Point it to a public Git repository you can push to (or create a new one).
3.  **Add a Build Step:** Add a simple "Execute Windows batch command" or "Execute shell" step (e.g., `echo "Build triggered at %DATE% %TIME%"` for Windows, or `echo "Build triggered at $(date)"` for Linux/macOS).
4.  **Implement "Poll SCM":**
    *   Configure "Poll SCM" with a schedule of `H/2 * * * *` (every 2 minutes).
    *   Make a small change to your Git repository and push it. Observe if Jenkins triggers a build within 2 minutes.
5.  **Implement "Build Periodically":**
    *   Disable "Poll SCM."
    *   Configure "Build Periodically" with a schedule of `H/1 * * * *` (every minute for testing).
    *   Observe if Jenkins triggers builds every minute without any SCM changes.
6.  **Set up GitHub Webhook:**
    *   Disable "Build Periodically."
    *   Enable "GitHub hook trigger for GITScm polling" in the Jenkins job.
    *   Go to your GitHub repository settings -> Webhooks. Add a new webhook with the Payload URL pointing to your Jenkins instance (`http://YOUR_JENKINS_URL/github-webhook/`).
    *   Make a push to your repository and verify that the build is triggered instantly.
    *   Check GitHub webhook "Recent Deliveries" for success.

## Additional Resources
-   **Jenkins Documentation on Build Triggers:** [https://www.jenkins.io/doc/book/getting-started/build-a-software-project/](https://www.jenkins.io/doc/book/getting-started/build-a-software-project/) (Look for "Triggers")
-   **Jenkins Handbook - Scheduled Builds:** [https://www.jenkins.io/doc/developer/pipeline/tour/#scheduled-builds](https://www.jenkins.io/doc/developer/pipeline/tour/#scheduled-builds)
-   **GitHub Webhooks Documentation:** [https://docs.github.com/en/developers/webhooks-and-events/webhooks/about-webhooks](https://docs.github.com/en/developers/webhooks-and-events/webhooks/about-webhooks)
-   **Cron Tutorial:** [https://crontab.guru/](https://crontab.guru/)