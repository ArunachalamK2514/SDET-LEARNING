#!/bin/bash

# ==============================================================================
# Ralph Loop Test - DETAILED PROMPT VERSION
# ==============================================================================
# This version combines:
# 1. The "Smart Context" logic (Python extraction of specific JSON data)
# 2. The "Detailed Prompt" (Your original high-quality instructions)
#
# Usage: ./ralph-loop-test.sh
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

# Create directories if they don't exist
mkdir -p "$LEARNING_CONTENT_DIR"
mkdir -p "$ITERATION_LOG_DIR"

# Pre-flight check
if [ ! -f "$REQUIREMENTS_FILE" ] || [ ! -f "$PROGRESS_FILE" ]; then
    echo -e "${RED}Error: Required files missing!${NC}"
    exit 1
fi

# Initialize log file
echo "# SDET Learning Content Generation TEST Logs" > "$LOGS_FILE"
echo "Started Test at: $(date)" >> "$LOGS_FILE"
echo "---" >> "$LOGS_FILE"

# Main loop
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Ralph Loop - DETAILED PROMPT MODE (2 Iterations Max)        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

while [ $iteration -lt $MAX_ITERATIONS ]; do
    iteration=$((iteration + 1))
    
    # 1. Identify the NEXT feature ID from progress.md
    NEXT_ID=$(grep "\[ \]" "$PROGRESS_FILE" | head -n 1 | sed -E 's/.*\[ \] ([^:]+):.*/\1/')

    if [ -z "$NEXT_ID" ]; then
        echo -e "${GREEN}🎉 No incomplete features found!${NC}"
        exit 0
    fi

    # 2. Extract the SPECIFIC feature details from requirements.json
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
        echo -e "${RED}Error: Could not find data for $NEXT_ID${NC}"
        exit 1
    fi

    files_before=$(ls "$LEARNING_CONTENT_DIR" 2>/dev/null | wc -l)
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Test Iteration #$iteration | Target: $NEXT_ID ${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # ------------------------------------------------------------------
    #  THE MERGED PROMPT (Smart Data Injection + Detailed Instructions)
    # ------------------------------------------------------------------
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

    PROMPT_FILE="$ITERATION_LOG_DIR/test-prompt-$iteration.txt"
    echo "$PROMPT" > "$PROMPT_FILE"
    ITERATION_OUTPUT="$ITERATION_LOG_DIR/test-output-$iteration.log"

    echo -e "${BLUE}[$(date +%H:%M:%S)] Invoking agent for $NEXT_ID...${NC}"
    
    # Run Gemini CLI
    gemini --yolo < "$PROMPT_FILE" 2>&1 | tee "$ITERATION_OUTPUT"
    
    exit_code=${PIPESTATUS[0]}
    
    files_after=$(ls "$LEARNING_CONTENT_DIR" 2>/dev/null | wc -l)
    files_created=$((files_after - files_before))
    
    echo "### Test Iteration $iteration ($NEXT_ID)" >> "$LOGS_FILE"
    echo "Files created: $files_created" >> "$LOGS_FILE"
    echo "---" >> "$LOGS_FILE"

    if [ $files_created -gt 0 ]; then
        echo -e "${GREEN}✅ Test Success for $NEXT_ID${NC}"
    else
        echo -e "${RED}⚠️  No files were created. Check $ITERATION_OUTPUT${NC}"
    fi

    echo -e "${BLUE}Waiting 3 seconds...${NC}"
    sleep 3
done

echo ""
echo -e "${YELLOW}Test complete. Check sdet-learning-content/ and progress.md for updates.${NC}"