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
MAX_ITERATIONS=8
COMPLETION_PROMISE="<promise>COMPLETE</promise>"
REQUIREMENTS_FILE="requirements.json"
PROGRESS_FILE="progress.md"
LOGS_FILE="logs.md"
LEARNING_CONTENT_DIR="./sdet-learning-content"
ITERATION_LOG_DIR="./iteration-logs"

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
mkdir -p "$ITERATION_LOG_DIR"

# Initialize log file
echo "# SDET Learning Content Generation Logs" > "$LOGS_FILE"
echo "" >> "$LOGS_FILE"
echo "Started at: $(date)" >> "$LOGS_FILE"
echo "Max iterations: $MAX_ITERATIONS" >> "$LOGS_FILE"
echo "Mode: STRICT SINGLE FEATURE + FIXED LOGGING" >> "$LOGS_FILE"
echo "---" >> "$LOGS_FILE"
echo "" >> "$LOGS_FILE"

# Main loop
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Ralph Loop - SDET Learning (Strict Mode + Fixed Logging)    ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo ""

while [ $iteration -lt $MAX_ITERATIONS ]; do
    iteration=$((iteration + 1))
    
    # Count files before iteration (STRICT Logic)
    files_before=$(ls "$LEARNING_CONTENT_DIR" 2>/dev/null | wc -l)
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Iteration #$iteration${NC}"
    echo -e "${YELLOW}  Files before: $files_before${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Log iteration start
    echo "## Iteration $iteration - $(date)" >> "$LOGS_FILE"
    echo "Files before: $files_before" >> "$LOGS_FILE"
    echo "" >> "$LOGS_FILE"
    
    # Construct the prompt
    # COMBINES: Detailed SDET context (Original) + Strict stopping rules (Strict)
    PROMPT="You are an expert SDET learning content creator with deep knowledge in test automation, Java, Selenium, REST Assured, Playwright, TestNG, CI/CD, and Docker.

🚨 CRITICAL INSTRUCTION - READ CAREFULLY 🚨
You MUST generate content for EXACTLY ONE (1) acceptance criterion ONLY.
DO NOT generate content for multiple features in a single response.
STOP immediately after completing ONE feature.

Your task:
1. Read the requirements.json file to see all features (acceptance criteria)
2. Read the progress.md file to see which features are already completed (marked with ✅ or [x])
3. Select the NEXT incomplete feature based on logical learning progression
4. Generate COMPREHENSIVE, PRODUCTION-GRADE content for that ONE feature:
   - Detailed explanation with real-world examples
   - Working code samples (complete, runnable, well-commented)
   - Best practices and common pitfalls
   - Interview tips related to this topic
   - Hands-on practice exercises
   - Links to additional resources
5. Create ONE markdown file in ./sdet-learning-content/ named by the feature ID (e.g., 'java-1.1-ac1.md')
6. Update progress.md with:
   - Feature ID marked as completed
   - Git commit message for tracking
7. Make ONE git commit with message: 'Content: [Feature ID] - [Feature Description]'
8. STOP. Do not process the next feature.

IMPORTANT STOPPING RULE:
After creating ONE feature file, your work for this iteration is COMPLETE.
Wait for the next iteration to process the next feature.

Only if ALL features are completed, meaning, if all the features are marked with ✅ or [x] in progress.md, output exactly: $COMPLETION_PROMISE

IMPORTANT QUALITY STANDARDS:
- Code must be production-ready, not pseudo-code
- Include error handling and edge cases
- Provide context and 'why' explanations, not just 'how'
- Make content interview-focused - what would senior SDETs be asked?
- Include practical, hands-on examples that can be executed

FILES TO READ:
- progress.md (completed features tracker) - READ THIS FILE FIRST to understand what is done and what should be done next in the logical order.
- requirements.json (file containing all features/acceptance criteria) - Then read this file to get the feature details of the item you are going to implement using the feature ID


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
- Focus on ONE feature per iteration. Quality over quantity.
- Output $COMPLETION_PROMISE only when ALL features are complete
"

    # Save prompt to temporary file (FIXED Logic)
    PROMPT_FILE="$ITERATION_LOG_DIR/prompt-iteration-$iteration.txt"
    echo "$PROMPT" > "$PROMPT_FILE"
    
    # Define output log (FIXED Logic)
    ITERATION_OUTPUT="$ITERATION_LOG_DIR/output-iteration-$iteration.log"
    
    echo -e "${BLUE}[$(date +%H:%M:%S)] Invoking Gemini CLI agent...${NC}"
    echo -e "${BLUE}[$(date +%H:%M:%S)] Output will be saved to: $ITERATION_OUTPUT${NC}"
    echo ""
    
    # Execute Gemini CLI with tee for real-time output AND logging (FIXED Logic)
    gemini --yolo < "$PROMPT_FILE" 2>&1 | tee "$ITERATION_OUTPUT"
    
    # Capture exit code
    exit_code=${PIPESTATUS[0]}
    
    echo ""
    echo -e "${BLUE}[$(date +%H:%M:%S)] Gemini CLI completed with exit code: $exit_code${NC}"
    echo ""
    
    # Count files after iteration (STRICT Logic)
    files_after=$(ls "$LEARNING_CONTENT_DIR" 2>/dev/null | wc -l)
    files_created=$((files_after - files_before))
    
    # Count completed features
    if [ -f "$PROGRESS_FILE" ]; then
        features_completed=$(grep -c "✅\|✔\|\[x\]" "$PROGRESS_FILE" || echo "0")
    fi
    
    # Append iteration output to main log (FIXED Logic)
    echo "### Iteration $iteration Output" >> "$LOGS_FILE"
    cat "$ITERATION_OUTPUT" >> "$LOGS_FILE"
    echo "" >> "$LOGS_FILE"
    echo "Files after: $files_after" >> "$LOGS_FILE"
    echo "Files created this iteration: $files_created" >> "$LOGS_FILE"
    echo "Features marked complete: $features_completed" >> "$LOGS_FILE"
    echo "Exit code: $exit_code" >> "$LOGS_FILE"
    echo "---" >> "$LOGS_FILE"
    echo "" >> "$LOGS_FILE"
    
    # Display summary (STRICT + FIXED Logic)
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  Iteration $iteration Summary                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Files created this iteration: $files_created"
    echo "  Total files in directory: $files_after"
    echo "  Features marked complete: $features_completed"
    
    # Check file creation (STRICT Logic)
    if [ $files_created -eq 0 ]; then
        echo -e "${RED}⚠️  Warning: No files created in this iteration${NC}"
        echo -e "${YELLOW}Agent may have skipped or encountered an error${NC}"
        echo ""
    elif [ $files_created -eq 1 ]; then
        echo -e "${GREEN}✅ Perfect: 1 file created (as expected)${NC}"
        echo ""
    else
        echo -e "${YELLOW}ℹ️  Agent created $files_created files${NC}"
        echo -e "${YELLOW}Processing multiple features per iteration (Monitoring)${NC}"
        echo ""
    fi
    
    # Check for completion promise (ORIGINAL Logic)
    if grep -q "$COMPLETION_PROMISE" "$ITERATION_OUTPUT"; then
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║              🎉 ALL FEATURES COMPLETED! 🎉                     ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}Total iterations: $iteration${NC}"
        echo -e "${GREEN}Total files created: $files_after${NC}"
        echo -e "${GREEN}Features completed: $features_completed${NC}"
        
        # Final log entry
        echo "## COMPLETION" >> "$LOGS_FILE"
        echo "" >> "$LOGS_FILE"
        echo "All features completed successfully!" >> "$LOGS_FILE"
        echo "Total iterations: $iteration" >> "$LOGS_FILE"
        echo "Total files: $files_after" >> "$LOGS_FILE"
        echo "Completed at: $(date)" >> "$LOGS_FILE"
        
        exit 0
    fi
    
    # Small delay between iterations
    echo -e "${BLUE}Waiting 3 seconds before next iteration...${NC}"
    echo ""
    sleep 3
done

# Max iterations reached
echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║          ⚠️  Max iterations reached ($MAX_ITERATIONS)          ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Features completed: $features_completed${NC}"
echo -e "${YELLOW}Files created: $files_after${NC}"
echo ""

# Final log entry
echo "## MAX ITERATIONS REACHED" >> "$LOGS_FILE"
echo "" >> "$LOGS_FILE"
echo "Stopped at iteration $MAX_ITERATIONS" >> "$LOGS_FILE"
echo "Features completed: $features_completed" >> "$LOGS_FILE"
echo "Files created: $files_after" >> "$LOGS_FILE"
echo "Stopped at: $(date)" >> "$LOGS_FILE"

exit 1