#!/bin/bash

# ==============================================================================
# Ralph Loop Command for SDET Learning with Gemini CLI
# ==============================================================================
# This script implements the Ralph Wiggum loop approach for continuous
# AI-driven learning content generation using Gemini CLI.
#
# Based on Anthropic's long-running agent harnesses research:
# https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
#
# Usage: ./ralph-loop-command.sh
# ==============================================================================

# Configuration
MAX_ITERATIONS=2
COMPLETION_PROMISE="<promise>COMPLETE</promise>"
REQUIREMENTS_FILE="requirements.json"
PROGRESS_FILE="progress.md"
LOGS_FILE="logs.md"
LEARNING_CONTENT_DIR="./sdet-learning-content"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize counters
iteration=0
features_completed=0

# Create directories if they don't exist
mkdir -p "$LEARNING_CONTENT_DIR"

# Initialize log file
echo "# SDET Learning Content Generation Logs" > "$LOGS_FILE"
echo "" >> "$LOGS_FILE"
echo "Started at: $(date)" >> "$LOGS_FILE"
echo "Max iterations: $MAX_ITERATIONS" >> "$LOGS_FILE"
echo "---" >> "$LOGS_FILE"
echo "" >> "$LOGS_FILE"

# Main loop
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Ralph Loop - SDET Learning Content Generator with Gemini    ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo ""

while [ $iteration -lt $MAX_ITERATIONS ]; do
    iteration=$((iteration + 1))
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Iteration #$iteration${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Log iteration start
    echo "## Iteration $iteration - $(date)" >> "$LOGS_FILE"
    echo "" >> "$LOGS_FILE"
    
    # Construct the prompt for Gemini CLI
    PROMPT="You are an expert SDET learning content creator with deep knowledge in test automation, Java, Selenium, REST Assured, Playwright, TestNG, CI/CD, and Docker.

Your task is to generate production-grade learning content for ONE acceptance criterion from the requirements.json file.

CRITICAL INSTRUCTIONS:
1. Read the requirements.json file to see all features (acceptance criteria) that need content
2. Read the progress.md file to see which features are already completed
3. Select the NEXT incomplete feature based on logical learning progression
4. Generate COMPREHENSIVE, PRODUCTION-GRADE content for that ONE feature including:
   - Detailed explanation with real-world examples
   - Working code samples (complete, runnable, well-commented)
   - Best practices and common pitfalls
   - Interview tips related to this topic
   - Hands-on practice exercises
   - Links to additional resources
5. Create a markdown file in ./sdet-learning-content/ named by the feature ID (e.g., 'java-1.1-ac1.md')
6. Update progress.md with:
   - Feature ID marked as completed
   - Summary of content created
   - Git commit message for tracking
7. Make a git commit with message: 'Content: [Feature ID] - [Feature Description]'
8. If ALL features are completed, output $COMPLETION_PROMISE

IMPORTANT QUALITY STANDARDS:
- Code must be production-ready, not pseudo-code
- Include error handling and edge cases
- Provide context and 'why' explanations, not just 'how'
- Make content interview-focused - what would senior SDETs be asked?
- Include practical, hands-on examples that can be executed

FILES TO READ:
- requirements.json (all features/acceptance criteria)
- progress.md (completed features tracker)

OUTPUT STRUCTURE FOR EACH FEATURE:
# [Feature Title]
## Overview
[Brief introduction and why this matters]

## Detailed Explanation
[Comprehensive explanation with examples]

## Code Implementation
\`\`\`java or \`\`\`typescript or \`\`\`bash
[Complete, runnable code with comments]
\`\`\`

## Best Practices
- [Key best practice 1]
- [Key best practice 2]

## Common Pitfalls
- [Pitfall 1 and how to avoid it]
- [Pitfall 2 and how to avoid it]

## Interview Questions & Answers
1. Q: [Common interview question]
   A: [Detailed answer]

## Hands-on Exercise
[Practical exercise to reinforce learning]

## Additional Resources
- [Resource 1 with URL]
- [Resource 2 with URL]

Remember:
- Focus on ONE feature per iteration
- Ensure content is comprehensive and production-grade
- Update progress.md after each completion
- Commit to git for tracking
- Output $COMPLETION_PROMISE only when ALL features are complete
"

    # Execute Gemini CLI with the prompt
    echo -e "${BLUE}[$(date +%H:%M:%S)] Invoking Gemini CLI agent...${NC}"
    
    # Save prompt to temporary file
    echo "$PROMPT" > /tmp/gemini_prompt.txt
    
    # Execute Gemini CLI (assumes gemini CLI is installed and configured)
    # Adjust command based on your Gemini CLI setup
    result=$(gemini --yolo < /tmp/gemini_prompt.txt 2>&1)
    
    # Log the result
    echo "$result" >> "$LOGS_FILE"
    echo "" >> "$LOGS_FILE"
    echo "---" >> "$LOGS_FILE"
    echo "" >> "$LOGS_FILE"
    
    # Display abbreviated result
    echo -e "${GREEN}Agent Response:${NC}"
    echo "$result" | head -n 20
    if [ $(echo "$result" | wc -l) -gt 20 ]; then
        echo "... (truncated, full output in $LOGS_FILE)"
    fi
    echo ""
    
    # Check for completion promise
    if echo "$result" | grep -q "$COMPLETION_PROMISE"; then
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║              🎉 ALL FEATURES COMPLETED! 🎉                     ║${NC}"
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo ""
        echo -e "${GREEN}Total iterations: $iteration${NC}"
        echo -e "${GREEN}Learning content generated in: $LEARNING_CONTENT_DIR${NC}"
        echo ""
        
        # Final log entry
        echo "## COMPLETION" >> "$LOGS_FILE"
        echo "" >> "$LOGS_FILE"
        echo "All features completed successfully!" >> "$LOGS_FILE"
        echo "Total iterations: $iteration" >> "$LOGS_FILE"
        echo "Completed at: $(date)" >> "$LOGS_FILE"
        
        exit 0
    fi
    
    # Count completed features from progress file
    if [ -f "$PROGRESS_FILE" ]; then
        features_completed=$(grep -c "✅" "$PROGRESS_FILE" || echo "0")
    fi
    
    echo -e "${BLUE}[$(date +%H:%M:%S)] Features completed: $features_completed${NC}"
    echo ""
    
    # Small delay between iterations to prevent overwhelming the system
    sleep 2
done

# Max iterations reached
echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║          ⚠️  Max iterations reached ($MAX_ITERATIONS)          ║${NC}"
echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
echo ""
echo -e "${YELLOW}Features completed: $features_completed${NC}"
echo -e "${YELLOW}Learning content generated in: $LEARNING_CONTENT_DIR${NC}"
echo ""

# Final log entry for max iterations
echo "## MAX ITERATIONS REACHED" >> "$LOGS_FILE"
echo "" >> "$LOGS_FILE"
echo "Stopped at iteration $MAX_ITERATIONS" >> "$LOGS_FILE"
echo "Features completed: $features_completed" >> "$LOGS_FILE"
echo "Stopped at: $(date)" >> "$LOGS_FILE"

exit 1
