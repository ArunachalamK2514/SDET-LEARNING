#!/bin/bash

# ==============================================================================
# Ralph Loop Command - UPDATED PRODUCTION VERSION
# ==============================================================================
# This version combines:
# 1. "Smart Context" logic (Python extraction to prevent context blindness)
# 2. "Detailed Prompt" (High-quality instructions for best content)
# 3. Full Production Logging & Error Handling
#
# Usage: ./ralph-loop-command-Updated.sh
# ==============================================================================

# Configuration
MAX_ITERATIONS=2
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

# Pre-flight check
if [ ! -f "$REQUIREMENTS_FILE" ] || [ ! -f "$PROGRESS_FILE" ]; then
    echo -e "${RED}Error: Required files ($REQUIREMENTS_FILE or $PROGRESS_FILE) missing!${NC}"
    exit 1
fi

# Initialize log file
echo "# SDET Learning Content Generation Logs - UPDATED RUN" > "$LOGS_FILE"
echo "" >> "$LOGS_FILE"
echo "Started at: $(date)" >> "$LOGS_FILE"
echo "Max iterations: $MAX_ITERATIONS" >> "$LOGS_FILE"
echo "Mode: SMART CONTEXT + DETAILED PROMPT + FULL LOGGING" >> "$LOGS_FILE"
echo "---" >> "$LOGS_FILE"
echo "" >> "$LOGS_FILE"

# Main loop
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Ralph Loop - UPDATED PRODUCTION MODE ($MAX_ITERATIONS Iterations)   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

while [ $iteration -lt $MAX_ITERATIONS ]; do
    iteration=$((iteration + 1))
    
    # ---------------------------------------------------------
    # STEP 1: IDENTIFY TARGET FEATURE
    # ---------------------------------------------------------
    # Identify the NEXT feature ID from progress.md
    NEXT_ID=$(grep "\[ \]" "$PROGRESS_FILE" | head -n 1 | sed -E 's/.*\[ \] ([^:]+):.*/\1/')

    if [ -z "$NEXT_ID" ]; then
        echo -e "${GREEN}🎉 No incomplete features found in $PROGRESS_FILE!${NC}"
        # If we are done, we still check properly at the end, but we can exit early here too.
        echo "$COMPLETION_PROMISE"
        exit 0
    fi

    # ---------------------------------------------------------
    # STEP 2: EXTRACT SPECIFIC CONTEXT (Python)
    # ---------------------------------------------------------
    # Extract the SPECIFIC feature details from requirements.json
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
        echo -e "${RED}Error: Could not find data for $NEXT_ID in $REQUIREMENTS_FILE${NC}"
        exit 1
    fi

    # Count files before iteration
    files_before=$(ls "$LEARNING_CONTENT_DIR" 2>/dev/null | wc -l)
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Iteration #$iteration | Target: $NEXT_ID ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Log iteration start
    echo "## Iteration $iteration - $(date)" >> "$LOGS_FILE"
    echo "Target Feature: $NEXT_ID" >> "$LOGS_FILE"
    echo "Files before: $files_before" >> "$LOGS_FILE"
    echo "" >> "$LOGS_FILE"

    # ---------------------------------------------------------
    # STEP 3: CONSTRUCT DETAILED PROMPT
    # ---------------------------------------------------------
    PROMPT="You are an expert SDET learning content creator with deep knowledge in test automation, Java, Selenium, REST Assured, Playwright, TestNG, CI/CD, and Docker.

### TARGET FEATURE DATA (INPUT) ###
The system has pre-selected the following feature for you to work on.
$FEATURE_DATA

### CONTEXT ###
This is part of a larger SDET Roadmap. You are specifically assigned to complete feature ID: $NEXT_ID.

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
4. **Update** 'progress.md':
   - Find the line for $NEXT_ID and change '[ ]' to '[x]'.
   - Add a brief entry in the 'Detailed Completion Log' at the bottom of progress.md (Date, Iteration, Feature ID).
5. **Commit**: Make ONE git commit with message: 'Content: $NEXT_ID - [Brief Description]'
6. **STOP**: Do not process any other features.

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

    # Save prompt to temporary file
    PROMPT_FILE="$ITERATION_LOG_DIR/prompt-iteration-$iteration.txt"
    echo "$PROMPT" > "$PROMPT_FILE"
    ITERATION_OUTPUT="$ITERATION_LOG_DIR/output-iteration-$iteration.log"

    echo -e "${BLUE}[$(date +%H:%M:%S)] Invoking agent for $NEXT_ID...${NC}"
    echo -e "${BLUE}[$(date +%H:%M:%S)] Output will be saved to: $ITERATION_OUTPUT${NC}"
    echo ""
    
    # ---------------------------------------------------------
    # STEP 4: EXECUTE AGENT
    # ---------------------------------------------------------
    gemini --yolo < "$PROMPT_FILE" 2>&1 | tee "$ITERATION_OUTPUT"
    
    # Capture exit code
    exit_code=${PIPESTATUS[0]}
    
    echo ""
    echo -e "${BLUE}[$(date +%H:%M:%S)] Gemini CLI completed with exit code: $exit_code${NC}"
    echo ""

    # ---------------------------------------------------------
    # STEP 5: VERIFY & LOG
    # ---------------------------------------------------------
    
    # Count files after iteration
    files_after=$(ls "$LEARNING_CONTENT_DIR" 2>/dev/null | wc -l)
    files_created=$((files_after - files_before))
    
    # Count completed features
    if [ -f "$PROGRESS_FILE" ]; then
        features_completed=$(grep -c "✅\|✔\|\[x\]" "$PROGRESS_FILE" || echo "0")
    fi
    
    # Append iteration output to main log
    echo "### Iteration $iteration Output" >> "$LOGS_FILE"
    cat "$ITERATION_OUTPUT" >> "$LOGS_FILE"
    echo "" >> "$LOGS_FILE"
    echo "Files after: $files_after" >> "$LOGS_FILE"
    echo "Files created this iteration: $files_created" >> "$LOGS_FILE"
    echo "Features marked complete: $features_completed" >> "$LOGS_FILE"
    echo "Exit code: $exit_code" >> "$LOGS_FILE"
    echo "---" >> "$LOGS_FILE"
    echo "" >> "$LOGS_FILE"
    
    # Display summary
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  Iteration $iteration Summary                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Files created this iteration: $files_created"
    echo "  Total files in directory: $files_after"
    echo "  Features marked complete: $features_completed"
    
    # Check file creation
    if [ $files_created -eq 0 ]; then
        echo -e "${RED}⚠️  Warning: No files created in this iteration${NC}"
        echo -e "${YELLOW}Agent may have skipped or encountered an error${NC}"
        echo ""
    elif [ $files_created -eq 1 ]; then
        echo -e "${GREEN}✅ Perfect: 1 file created for $NEXT_ID${NC}"
        echo ""
    else
        echo -e "${YELLOW}ℹ️  Agent created $files_created files${NC}"
        echo -e "${YELLOW}Processing multiple features per iteration (Monitoring)${NC}"
        echo ""
    fi
    
    # Check for completion promise
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