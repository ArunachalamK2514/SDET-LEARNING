#!/bin/bash

# ==============================================================================
# Ralph Loop Command - GIT LOG SEPARATION VERSION
# ==============================================================================
# This version separates the 'Status Tracking' (progress.md) from the 
# 'Detailed Logging' (git_logs.md) to prevent accidental file overwrites.
#
# Usage: ./ralph-loop-command-Updated.sh
# ==============================================================================

# Configuration
MAX_ITERATIONS=8
COMPLETION_PROMISE="<promise>COMPLETE</promise>"
REQUIREMENTS_FILE="requirements.json"
PROGRESS_FILE="progress.md"
GIT_LOGS_FILE="git_logs.md"  # New separate file for detailed logs
LOGS_FILE="logs.md"          # System execution logs
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

# Create directories
mkdir -p "$LEARNING_CONTENT_DIR"
mkdir -p "$ITERATION_LOG_DIR"

# Pre-flight check
if [ ! -f "$REQUIREMENTS_FILE" ] || [ ! -f "$PROGRESS_FILE" ]; then
    echo -e "${RED}Error: Required files missing!${NC}"
    exit 1
fi

# Ensure git_logs.md exists
if [ ! -f "$GIT_LOGS_FILE" ]; then
    echo "# Detailed Git Completion Log" > "$GIT_LOGS_FILE"
    echo "" >> "$GIT_LOGS_FILE"
fi

# Initialize log file
echo "# SDET Learning Content Generation Logs" > "$LOGS_FILE"
echo "Started at: $(date)" >> "$LOGS_FILE"
echo "---" >> "$LOGS_FILE"

# Main loop
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Ralph Loop - GIT LOG MODE ($MAX_ITERATIONS Iterations)              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

while [ $iteration -lt $MAX_ITERATIONS ]; do
    iteration=$((iteration + 1))
    
    # ---------------------------------------------------------
    # CRITICAL FIX: SANITIZE FILES (INSIDE LOOP)
    # ---------------------------------------------------------
    # We sanitize inside the loop because the agent might corrupt the file 
    # during the previous iteration (e.g., saving as UTF-16).
    # Sanitize BOTH progress.md and the new git_logs.md
    if [ -f "$PROGRESS_FILE" ]; then
        tr -d '\000' < "$PROGRESS_FILE" > "${PROGRESS_FILE}.tmp" && mv "${PROGRESS_FILE}.tmp" "$PROGRESS_FILE"
    fi
    if [ -f "$GIT_LOGS_FILE" ]; then
        tr -d '\000' < "$GIT_LOGS_FILE" > "${GIT_LOGS_FILE}.tmp" && mv "${GIT_LOGS_FILE}.tmp" "$GIT_LOGS_FILE"
    fi

    # ---------------------------------------------------------
    # STEP 1: IDENTIFY TARGET FEATURE
    # ---------------------------------------------------------
    # Force grep to treat file as text (-a) just in case
    TARGET_LINE=$(grep -a "\[ \]" "$PROGRESS_FILE" | head -n 1)
    
    # Sanitize for prompt injection (remove carriage returns)
    TARGET_LINE=$(echo "$TARGET_LINE" | tr -d '\r')

    # Extract just the ID
    NEXT_ID=$(echo "$TARGET_LINE" | sed -E 's/.*\[ \] ([^:]+):.*/\1/')

    if [ -z "$NEXT_ID" ]; then
        echo -e "${GREEN}🎉 No incomplete features found!${NC}"
        echo "$COMPLETION_PROMISE"
        exit 0
    fi
    
    # Get context from the NEW git logs file instead of progress.md
    GIT_LOG_CONTEXT=$(tail -n 3 "$GIT_LOGS_FILE")

    # ---------------------------------------------------------
    # STEP 2: EXTRACT SPECIFIC CONTEXT (Python)
    # ---------------------------------------------------------
    # Changed 'python3' to 'python' as requested
    FEATURE_DATA=$(python -c "
import json
try:
    with open('$REQUIREMENTS_FILE', 'r') as f:
        data = json.load(f)
        feature = next((item for item in data['features'] if item['id'] == '$NEXT_ID'), None)
        print(json.dumps(feature, indent=2) if feature else 'NOT_FOUND')
except Exception as e:
    print(f'ERROR: {str(e)}')
")

    if [[ "$FEATURE_DATA" == "NOT_FOUND" ]] || [[ "$FEATURE_DATA" == ERROR* ]]; then
        echo -e "${RED}Error: Could not find data for '$NEXT_ID' (Extracted from: '$TARGET_LINE')${NC}"
        exit 1
    fi

    # Count files before iteration
    files_before=$(ls "$LEARNING_CONTENT_DIR" 2>/dev/null | wc -l)
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Iteration #$iteration | Target: $NEXT_ID ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo "## Iteration $iteration - $(date)" >> "$LOGS_FILE"
    echo "Target Feature: $NEXT_ID" >> "$LOGS_FILE"

    # ---------------------------------------------------------
    # STEP 3: CONSTRUCT DETAILED PROMPT
    # ---------------------------------------------------------
    PROMPT="You are an expert SDET learning content creator with deep knowledge in test automation, Java, Selenium, REST Assured, Playwright, TestNG, CI/CD, and Docker.

### TARGET FEATURE DATA (INPUT) ###
The system has pre-selected the following feature for you to work on.
$FEATURE_DATA

### FILE EDITING INSTRUCTIONS (READ CAREFULLY) ###
You need to update TWO different files. Do not mix them up.

1. **UPDATE STATUS in '$PROGRESS_FILE'**:
   - Locate this EXACT line: \`$TARGET_LINE\`
   - Replace it with: \`- [x] $NEXT_ID ...\` (keeping the original description).
   - **CRITICAL**: Do NOT add any logs, comments, or extra text to '$PROGRESS_FILE'. Only update the checkbox.

2. **APPEND LOG to '$GIT_LOGS_FILE'**:
   - The end of '$GIT_LOGS_FILE' looks like this:
     \`\`\`
     $GIT_LOG_CONTEXT
     \`\`\`
   - **Action**: Append a new log entry to the END of '$GIT_LOGS_FILE' in this format:
     \`\`\`markdown
     ### $(date +%Y-%m-%d) - Iteration $iteration
     - **Feature Completed**: $NEXT_ID
     - **Content File**: ./sdet-learning-content/$NEXT_ID.md
     - **Git Commit**: Content: $NEXT_ID - [Brief Description]
     \`\`\`

### CRITICAL INSTRUCTION - READ CAREFULLY ###
You MUST generate content for EXACTLY ONE (1) acceptance criterion ONLY (the one provided above).
DO NOT generate content for multiple features.
STOP immediately after completing ONE feature.

### YOUR TASK ###
1. **Analyze** the 'TARGET FEATURE DATA' provided above to understand the requirements.
2. **Generate** COMPREHENSIVE, PRODUCTION-GRADE content for this ONE feature ($NEXT_ID):
   - Detailed explanation with real-world examples
   - Working code samples (complete, runnable, well-commented)
   - Best practices and common pitfalls
   - Interview tips related to this topic
   - Hands-on practice exercises
   - Links to additional resources
3. **Create** ONE markdown file in ./sdet-learning-content/ named '$NEXT_ID.md'.
4. **Update** '$PROGRESS_FILE' (Checkbox ONLY) as per instructions above.
5. **Append** to '$GIT_LOGS_FILE' (Log Entry) as per instructions above.
6. **Commit**: Make ONE git commit with message: 'Content: $NEXT_ID - [Brief Description]'
7. **STOP**: Do not process any other features.

### IMPORTANT QUALITY STANDARDS ###
- Code must be production-ready, not pseudo-code
- Include error handling and edge cases
- Provide context and 'why' explanations, not just 'how'
- Make content interview-focused - what would senior SDETs be asked?
- Include practical, hands-on examples that can be executed

### OUTPUT STRUCTURE FOR THE FEATURE ###
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

### FINAL COMMAND ###
Process ONLY $NEXT_ID now. Output a summary of actions taken when done.
"

    PROMPT_FILE="$ITERATION_LOG_DIR/prompt-iteration-$iteration.txt"
    echo "$PROMPT" > "$PROMPT_FILE"
    ITERATION_OUTPUT="$ITERATION_LOG_DIR/output-iteration-$iteration.log"

    echo -e "${BLUE}[$(date +%H:%M:%S)] Invoking agent for $NEXT_ID...${NC}"
    
    # ---------------------------------------------------------
    # STEP 4: EXECUTE AGENT
    # ---------------------------------------------------------
    gemini --yolo < "$PROMPT_FILE" 2>&1 | tee "$ITERATION_OUTPUT"
    
    exit_code=${PIPESTATUS[0]}
    
    # ---------------------------------------------------------
    # STEP 5: VERIFY & LOG
    # ---------------------------------------------------------
    
    files_after=$(ls "$LEARNING_CONTENT_DIR" 2>/dev/null | wc -l)
    files_created=$((files_after - files_before))
    
    if [ -f "$PROGRESS_FILE" ]; then
        features_completed=$(grep -c "✅\|✔\|\[x\]" "$PROGRESS_FILE" || echo "0")
    fi
    
    echo "### Iteration $iteration Output" >> "$LOGS_FILE"
    cat "$ITERATION_OUTPUT" >> "$LOGS_FILE"
    echo "" >> "$LOGS_FILE"
    echo "Files created this iteration: $files_created" >> "$LOGS_FILE"
    echo "Features marked complete: $features_completed" >> "$LOGS_FILE"
    echo "---" >> "$LOGS_FILE"
    
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  Iteration $iteration Summary                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Files created this iteration: $files_created"
    echo "  Features marked complete: $features_completed"
    
    if [ $files_created -eq 0 ]; then
        echo -e "${RED}⚠️  Warning: No files created in this iteration${NC}"
    elif [ $files_created -eq 1 ]; then
        echo -e "${GREEN}✅ Perfect: 1 file created for $NEXT_ID${NC}"
    else
        echo -e "${YELLOW}ℹ️  Agent created $files_created files${NC}"
    fi
    
    if grep -q "$COMPLETION_PROMISE" "$ITERATION_OUTPUT"; then
        echo -e "${GREEN}🎉 ALL FEATURES COMPLETED! 🎉${NC}"
        echo "## COMPLETION" >> "$LOGS_FILE"
        echo "Completed at: $(date)" >> "$LOGS_FILE"
        exit 0
    fi
    
    echo -e "${BLUE}Waiting 3 seconds before next iteration...${NC}"
    sleep 3
done

echo -e "${YELLOW}Max iterations reached ($MAX_ITERATIONS).${NC}"
exit 1