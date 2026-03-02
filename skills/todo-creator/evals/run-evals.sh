#!/usr/bin/env bash
#
# run-evals.sh — Automated evaluation runner for the todo-creator skill
#
# Usage:
#   ./skills/todo-creator/evals/run-evals.sh [OPTIONS]
#
# Options:
#   --dry-run           Print what would be executed without running anything
#   --iteration-name N  Override the auto-generated iteration name (e.g., "iteration-5")
#   --max-parallel N    Maximum number of parallel agent runs (default: 4)
#   --model MODEL       Model to use for agents (default: sonnet)
#   --eval-ids IDS      Comma-separated list of IDs to run (default: all)
#   --help              Show this help message
#
# Prerequisites:
#   - claude CLI (Claude Code) must be installed and on PATH
#   - jq must be installed
#   - Run from the project root directory
#
# Examples:
#   # Run all test cases with auto-increment iteration
#   ./skills/todo-creator/evals/run-evals.sh
#
#   # Dry run to see what would happen
#   ./skills/todo-creator/evals/run-evals.sh --dry-run
#
#   # Run specific test cases with a named iteration
#   ./skills/todo-creator/evals/run-evals.sh --iteration-name iteration-3 --eval-ids 1,2
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
EVALS_JSON="$SCRIPT_DIR/evals.json"
SKILL_MD="$PROJECT_ROOT/skills/todo-creator/SKILL.md"
WORKSPACE_DIR="$PROJECT_ROOT/skills/todo-creator-workspace"
CONFIGS="with_skill without_skill"

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
DRY_RUN=false
ITERATION_NAME=""
MAX_PARALLEL=4
MODEL="sonnet"
EVAL_IDS=""

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --iteration-name)
            ITERATION_NAME="$2"
            shift 2
            ;;
        --max-parallel)
            MAX_PARALLEL="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --eval-ids)
            EVAL_IDS="$2"
            shift 2
            ;;
        --help)
            sed -n '2,/^[^#]/{ /^[^#]/d; s/^# \{0,1\}//; p; }' "$0"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Run with --help for usage information." >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------
check_dependency() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: '$1' is required but not found on PATH." >&2
        exit 1
    fi
}

check_dependency jq
check_dependency claude

# Validate evals.json exists
if [[ ! -f "$EVALS_JSON" ]]; then
    echo "Error: evals.json not found at $EVALS_JSON" >&2
    exit 1
fi

# Validate SKILL.md exists
if [[ ! -f "$SKILL_MD" ]]; then
    echo "Error: SKILL.md not found at $SKILL_MD" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Utility functions
# ---------------------------------------------------------------------------
log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

log_section() {
    echo ""
    echo "========================================================================"
    echo "  $*"
    echo "========================================================================"
    echo ""
}

# Returns nanosecond-precision timestamp for timing measurements
now_ns() {
    if date +%s%N >/dev/null 2>&1 && [[ "$(date +%s%N)" != *"N"* ]]; then
        date +%s%N
    else
        # macOS: use perl for sub-second precision
        perl -MTime::HiRes=time -e 'printf "%.0f\n", time * 1000000000'
    fi
}

elapsed_seconds() {
    local start_ns="$1"
    local end_ns="$2"
    echo "scale=1; ($end_ns - $start_ns) / 1000000000" | bc
}

# Throttle parallel jobs: wait if we have >= MAX_PARALLEL background jobs
throttle() {
    while [[ "$(jobs -rp | wc -l)" -ge "$MAX_PARALLEL" ]]; do
        sleep 0.5
    done
}

# ---------------------------------------------------------------------------
# Lookup helpers (avoid bash 4+ associative arrays for macOS compat)
# These read from evals.json on each call — acceptable for small N.
# ---------------------------------------------------------------------------
get_case_name() {
    jq -r ".evals[$1].name" "$EVALS_JSON"
}

get_case_id() {
    jq -r ".evals[$1].id" "$EVALS_JSON"
}

get_case_prompt() {
    jq -r ".evals[$1].prompt" "$EVALS_JSON"
}

# ---------------------------------------------------------------------------
# Phase 0: Determine iteration name
# ---------------------------------------------------------------------------
log_section "Phase 0: Setup"

if [[ -n "$ITERATION_NAME" ]]; then
    ITER_DIR="$WORKSPACE_DIR/$ITERATION_NAME"
    log "Using specified iteration name: $ITERATION_NAME"
else
    # Auto-increment: find highest existing iteration-N and add 1
    HIGHEST=0
    if [[ -d "$WORKSPACE_DIR" ]]; then
        for dir in "$WORKSPACE_DIR"/iteration-*; do
            if [[ -d "$dir" ]]; then
                num="${dir##*iteration-}"
                if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -gt "$HIGHEST" ]]; then
                    HIGHEST="$num"
                fi
            fi
        done
    fi
    NEXT=$((HIGHEST + 1))
    ITERATION_NAME="iteration-$NEXT"
    ITER_DIR="$WORKSPACE_DIR/$ITERATION_NAME"
    log "Auto-detected next iteration: $ITERATION_NAME (previous highest: iteration-$HIGHEST)"
fi

# ---------------------------------------------------------------------------
# Phase 0b: Parse evals.json and determine which test cases to run
# ---------------------------------------------------------------------------
TOTAL_EVALS=$(jq '.evals | length' "$EVALS_JSON")
log "Found $TOTAL_EVALS test case(s) in evals.json"

# Build the list of indices to run
if [[ -n "$EVAL_IDS" ]]; then
    IFS=',' read -ra REQUESTED_IDS <<< "$EVAL_IDS"
    EVAL_INDICES=()
    for req_id in "${REQUESTED_IDS[@]}"; do
        req_id="$(echo "$req_id" | tr -d ' ')"
        idx=$(jq --argjson rid "$req_id" '[.evals[].id] | to_entries[] | select(.value == $rid) | .key' "$EVALS_JSON")
        if [[ -z "$idx" ]]; then
            echo "Warning: ID $req_id not found in evals.json, skipping." >&2
        else
            EVAL_INDICES+=("$idx")
        fi
    done
else
    EVAL_INDICES=()
    for ((i = 0; i < TOTAL_EVALS; i++)); do
        EVAL_INDICES+=("$i")
    done
fi

NUM_EVALS="${#EVAL_INDICES[@]}"
if [[ "$NUM_EVALS" -eq 0 ]]; then
    echo "Error: No test cases to run." >&2
    exit 1
fi

log "Will run $NUM_EVALS test case(s) x 2 configurations = $((NUM_EVALS * 2)) agent runs"

# ---------------------------------------------------------------------------
# Phase 1: Create directory structure
# ---------------------------------------------------------------------------
log_section "Phase 1: Create Directory Structure"

for idx in "${EVAL_INDICES[@]}"; do
    case_name=$(get_case_name "$idx")
    case_id=$(get_case_id "$idx")
    case_prompt=$(get_case_prompt "$idx")

    for config in $CONFIGS; do
        dir="$ITER_DIR/$case_name/$config/outputs"
        if [[ "$DRY_RUN" == true ]]; then
            log "[DRY RUN] mkdir -p $dir"
        else
            mkdir -p "$dir"
            log "Created: $dir"
        fi
    done

    # Write metadata json
    metadata_file="$ITER_DIR/$case_name/eval_metadata.json"
    if [[ "$DRY_RUN" == true ]]; then
        log "[DRY RUN] Write eval_metadata.json for $case_name"
    else
        jq -n \
            --argjson eid "$case_id" \
            --arg ename "$case_name" \
            --arg eprompt "$case_prompt" \
            --argjson assertions "$(jq ".evals[$idx].assertions" "$EVALS_JSON")" \
            '{
                eval_id: $eid,
                eval_name: $ename,
                prompt: $eprompt,
                assertions: $assertions
            }' > "$metadata_file"
        log "Wrote: $metadata_file"
    fi
done

# ---------------------------------------------------------------------------
# Phase 2: Run Agents (parallel)
# ---------------------------------------------------------------------------
log_section "Phase 2: Run Agents"

SKILL_CONTENT=$(cat "$SKILL_MD")
PIDS=()
PID_LABELS=()

run_agent() {
    local case_idx="$1"
    local config="$2"
    local case_name
    case_name=$(get_case_name "$case_idx")
    local case_prompt
    case_prompt=$(get_case_prompt "$case_idx")
    local out_dir="$ITER_DIR/$case_name/$config"
    local raw_output="$out_dir/raw_output.md"
    local timing_file="$out_dir/timing.json"
    local label="$case_name/$config"

    log "Starting agent: $label"

    local start_ns
    start_ns=$(now_ns)

    if [[ "$config" == "with_skill" ]]; then
        claude --print --model "$MODEL" \
            --system-prompt "$SKILL_CONTENT" \
            "Generate todo files for this request. Write each todo file as a markdown code block with the filename as the info string (e.g., \`\`\`01-some-file.md). Do NOT use any tools or read any files — just generate the content directly.

Prompt: $case_prompt" \
            > "$raw_output" 2>"$out_dir/agent_stderr.log" || {
                log "ERROR: Agent failed for $label (exit code: $?)"
                echo '{"error": true, "duration_seconds": 0}' > "$timing_file"
                return 1
            }
    else
        claude --print --model "$MODEL" \
            "Generate todo markdown files for this request. Each file should have an H1 title, a context paragraph, and a checklist with '- [ ]' items. Write each as a markdown code block with the filename as the info string (e.g., \`\`\`01-some-file.md). Do NOT use any tools or read any files — just generate the content directly.

Prompt: $case_prompt" \
            > "$raw_output" 2>"$out_dir/agent_stderr.log" || {
                log "ERROR: Agent failed for $label (exit code: $?)"
                echo '{"error": true, "duration_seconds": 0}' > "$timing_file"
                return 1
            }
    fi

    local end_ns
    end_ns=$(now_ns)
    local duration
    duration=$(elapsed_seconds "$start_ns" "$end_ns")

    # Write timing
    jq -n \
        --argjson dur "$duration" \
        '{
            duration_seconds: $dur,
            total_duration_seconds: $dur
        }' > "$timing_file"

    log "Completed agent: $label (${duration}s)"

    # Parse code blocks from raw_output.md into individual files
    parse_code_blocks "$raw_output" "$out_dir/outputs" "$label"
}

parse_code_blocks() {
    local input_file="$1"
    local output_dir="$2"
    local label="$3"

    if [[ ! -f "$input_file" ]]; then
        log "WARNING: No raw output file found for $label"
        return 1
    fi

    local in_block=false
    local current_file=""
    local block_content=""
    local file_count=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$in_block" == false ]]; then
            # Match: ```filename.md or ```markdown filename.md or ``` filename.md
            if [[ "$line" =~ ^\`\`\`[[:space:]]*([a-zA-Z0-9_-]+\.md)[[:space:]]*$ ]]; then
                in_block=true
                current_file="${BASH_REMATCH[1]}"
                block_content=""
            elif [[ "$line" =~ ^\`\`\`(markdown|md)[[:space:]]+([a-zA-Z0-9_-]+\.md) ]]; then
                in_block=true
                current_file="${BASH_REMATCH[2]}"
                block_content=""
            fi
        else
            if [[ "$line" =~ ^\`\`\`[[:space:]]*$ ]]; then
                # End of code block — write file
                if [[ -n "$current_file" ]]; then
                    printf '%s' "$block_content" > "$output_dir/$current_file"
                    file_count=$((file_count + 1))
                fi
                in_block=false
                current_file=""
                block_content=""
            else
                if [[ -n "$block_content" ]]; then
                    block_content="$block_content
$line"
                else
                    block_content="$line"
                fi
            fi
        fi
    done < "$input_file"

    # Handle case where file was still open (missing closing fence)
    if [[ "$in_block" == true ]] && [[ -n "$current_file" ]] && [[ -n "$block_content" ]]; then
        printf '%s' "$block_content" > "$output_dir/$current_file"
        file_count=$((file_count + 1))
        log "WARNING: Code block for '$current_file' was not properly closed in $label"
    fi

    if [[ "$file_count" -eq 0 ]]; then
        log "WARNING: No code blocks with .md filenames found in $label — trying fallback parse"
        parse_code_blocks_fallback "$input_file" "$output_dir" "$label"
    else
        log "Parsed $file_count file(s) from $label"
    fi
}

parse_code_blocks_fallback() {
    # Fallback: extract any fenced code block that looks like a todo file
    local input_file="$1"
    local output_dir="$2"
    local label="$3"
    local file_count=0
    local in_block=false
    local block_content=""
    local block_num=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$in_block" == false ]]; then
            if [[ "$line" =~ ^\`\`\` ]]; then
                in_block=true
                block_content=""
            fi
        else
            if [[ "$line" =~ ^\`\`\`[[:space:]]*$ ]]; then
                # Check if this block looks like a todo file (has H1 and checklist)
                if echo "$block_content" | grep -q '^# ' && echo "$block_content" | grep -q '^\- \[ \]'; then
                    block_num=$((block_num + 1))
                    local fname
                    fname=$(printf "%02d-todo.md" "$block_num")
                    printf '%s' "$block_content" > "$output_dir/$fname"
                    file_count=$((file_count + 1))
                fi
                in_block=false
                block_content=""
            else
                if [[ -n "$block_content" ]]; then
                    block_content="$block_content
$line"
                else
                    block_content="$line"
                fi
            fi
        fi
    done < "$input_file"

    log "Fallback parsed $file_count file(s) from $label"
}

if [[ "$DRY_RUN" == true ]]; then
    for idx in "${EVAL_INDICES[@]}"; do
        for config in $CONFIGS; do
            case_name=$(get_case_name "$idx")
            log "[DRY RUN] claude --print --model $MODEL ... > $ITER_DIR/$case_name/$config/raw_output.md"
        done
    done
else
    # Launch all agents in parallel (with throttle)
    for idx in "${EVAL_INDICES[@]}"; do
        for config in $CONFIGS; do
            throttle
            run_agent "$idx" "$config" &
            PIDS+=($!)
            PID_LABELS+=("$(get_case_name "$idx")/$config")
        done
    done

    # Wait for all agents to complete
    log ""
    log "Waiting for ${#PIDS[@]} agent(s) to complete..."
    FAILED_RUNS=0
    for i in "${!PIDS[@]}"; do
        if ! wait "${PIDS[$i]}" 2>/dev/null; then
            log "WARNING: ${PID_LABELS[$i]} failed"
            FAILED_RUNS=$((FAILED_RUNS + 1))
        fi
    done

    if [[ "$FAILED_RUNS" -gt 0 ]]; then
        log "WARNING: $FAILED_RUNS agent(s) failed. Continuing with grading for successful runs."
    fi
    log "All agents completed."
fi

# ---------------------------------------------------------------------------
# Phase 3: Grade (parallel)
# ---------------------------------------------------------------------------
log_section "Phase 3: Grading"

GRADE_PIDS=()
GRADE_PID_LABELS=()

run_grading_agent() {
    local case_idx="$1"
    local config="$2"
    local case_name
    case_name=$(get_case_name "$case_idx")
    local case_id
    case_id=$(get_case_id "$case_idx")
    local out_dir="$ITER_DIR/$case_name/$config"
    local outputs_dir="$out_dir/outputs"
    local grading_file="$out_dir/grading.json"
    local label="$case_name/$config"

    # Check if outputs exist
    local output_files
    output_files=$(find "$outputs_dir" -name '*.md' -type f 2>/dev/null | sort)
    if [[ -z "$output_files" ]]; then
        log "WARNING: No output files for $label, skipping grading"
        jq -n \
            --argjson eid "$case_id" \
            --arg rid "${case_name}-${config}" \
            '{
                eval_id: $eid,
                run_id: $rid,
                error: "No output files produced by agent",
                expectations: []
            }' > "$grading_file"
        return 1
    fi

    # Build the combined assertions list for the grading prompt
    local all_assertions
    all_assertions=$(jq -c "[
        (.evals[$case_idx].assertions.baseline[]  | . + {type: \"baseline\"}),
        (.evals[$case_idx].assertions.discriminating[] | . + {type: \"discriminating\"})
    ]" "$EVALS_JSON")

    # Concatenate all output files with filenames as headers
    local todo_contents=""
    while IFS= read -r fpath; do
        local fname
        fname=$(basename "$fpath")
        local fcontent
        fcontent=$(cat "$fpath")
        todo_contents="${todo_contents}--- FILE: ${fname} ---
${fcontent}

"
    done <<< "$output_files"

    log "Starting grading: $label"

    local start_ns
    start_ns=$(now_ns)

    claude --print --model "$MODEL" \
        "You are a grading agent for assessing todo file quality. Grade the following todo files against each assertion.

For EACH assertion, output a JSON object with these fields:
- \"text\": the assertion name
- \"type\": \"baseline\" or \"discriminating\"
- \"passed\": boolean
- \"evidence\": string explaining why it passed or failed with specific quotes from the files

Output ONLY a valid JSON object with this structure:
{
  \"eval_id\": $case_id,
  \"run_id\": \"${case_name}-${config}\",
  \"expectations\": [ ... array of assertion results ... ]
}

Do not include any text before or after the JSON. Do not wrap in code fences.

ASSERTIONS TO GRADE:
$all_assertions

TODO FILES TO GRADE:
$todo_contents" \
        > "$grading_file.tmp" 2>"$out_dir/grading_stderr.log" || {
            log "ERROR: Grading agent failed for $label"
            jq -n \
                --argjson eid "$case_id" \
                --arg rid "${case_name}-${config}" \
                '{
                    eval_id: $eid,
                    run_id: $rid,
                    error: "Grading agent failed",
                    expectations: []
                }' > "$grading_file"
            return 1
        }

    local end_ns
    end_ns=$(now_ns)
    local duration
    duration=$(elapsed_seconds "$start_ns" "$end_ns")

    # Validate and clean the grading output — extract JSON even if there is surrounding text
    if jq '.' "$grading_file.tmp" >/dev/null 2>&1; then
        mv "$grading_file.tmp" "$grading_file"
    else
        # Try to extract JSON from the output (model sometimes wraps in code fences)
        local extracted
        extracted=$(sed -n '/^[[:space:]]*{/,/^[[:space:]]*}[[:space:]]*$/p' "$grading_file.tmp" | head -1000)
        if echo "$extracted" | jq '.' >/dev/null 2>&1; then
            echo "$extracted" > "$grading_file"
            rm -f "$grading_file.tmp"
        else
            # Last resort: try stripping markdown code fences
            extracted=$(sed '1{/^```/d}; ${/^```/d}' "$grading_file.tmp")
            if echo "$extracted" | jq '.' >/dev/null 2>&1; then
                echo "$extracted" > "$grading_file"
                rm -f "$grading_file.tmp"
            else
                log "WARNING: Could not parse grading output as JSON for $label"
                mv "$grading_file.tmp" "$grading_file.raw"
                jq -n \
                    --argjson eid "$case_id" \
                    --arg rid "${case_name}-${config}" \
                    '{
                        eval_id: $eid,
                        run_id: $rid,
                        error: "Grading output was not valid JSON",
                        expectations: []
                    }' > "$grading_file"
            fi
        fi
    fi

    log "Completed grading: $label (${duration}s)"
}

if [[ "$DRY_RUN" == true ]]; then
    for idx in "${EVAL_INDICES[@]}"; do
        for config in $CONFIGS; do
            case_name=$(get_case_name "$idx")
            log "[DRY RUN] claude --print --model $MODEL (grading) > $ITER_DIR/$case_name/$config/grading.json"
        done
    done
else
    for idx in "${EVAL_INDICES[@]}"; do
        for config in $CONFIGS; do
            throttle
            run_grading_agent "$idx" "$config" &
            GRADE_PIDS+=($!)
            GRADE_PID_LABELS+=("$(get_case_name "$idx")/$config (grading)")
        done
    done

    log ""
    log "Waiting for ${#GRADE_PIDS[@]} grading agent(s) to complete..."
    FAILED_GRADES=0
    for i in "${!GRADE_PIDS[@]}"; do
        if ! wait "${GRADE_PIDS[$i]}" 2>/dev/null; then
            log "WARNING: ${GRADE_PID_LABELS[$i]} failed"
            FAILED_GRADES=$((FAILED_GRADES + 1))
        fi
    done

    if [[ "$FAILED_GRADES" -gt 0 ]]; then
        log "WARNING: $FAILED_GRADES grading agent(s) failed."
    fi
    log "All grading completed."
fi

# ---------------------------------------------------------------------------
# Phase 4: Aggregate results
# ---------------------------------------------------------------------------
log_section "Phase 4: Aggregate Results"

if [[ "$DRY_RUN" == true ]]; then
    log "[DRY RUN] Would aggregate grading results into:"
    log "[DRY RUN]   $ITER_DIR/benchmark.json"
    log "[DRY RUN]   $ITER_DIR/benchmark.md"
    log ""
    log "Dry run complete. No files were created or agents were run."
    exit 0
fi

BENCHMARK_JSON="$ITER_DIR/benchmark.json"
BENCHMARK_MD="$ITER_DIR/benchmark.md"
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Collect all runs into a JSON array
RUNS="[]"

for idx in "${EVAL_INDICES[@]}"; do
    case_name=$(get_case_name "$idx")
    case_id=$(get_case_id "$idx")

    for config in $CONFIGS; do
        grading_file="$ITER_DIR/$case_name/$config/grading.json"
        timing_file="$ITER_DIR/$case_name/$config/timing.json"

        # Read timing
        local_time=0
        if [[ -f "$timing_file" ]]; then
            local_time=$(jq '.total_duration_seconds // 0' "$timing_file")
        fi

        # Read grading results
        if [[ ! -f "$grading_file" ]] || jq -e '.error' "$grading_file" >/dev/null 2>&1; then
            # Error case — include with zero pass rate
            RUNS=$(echo "$RUNS" | jq \
                --argjson eid "$case_id" \
                --arg ename "$case_name" \
                --arg config "$config" \
                --argjson time "$local_time" \
                '. + [{
                    eval_id: $eid,
                    eval_name: $ename,
                    configuration: $config,
                    run_number: 1,
                    result: {
                        pass_rate: 0,
                        passed: 0,
                        failed: 0,
                        total: 0,
                        baseline_passed: 0,
                        baseline_total: 0,
                        discriminating_passed: 0,
                        discriminating_total: 0,
                        time_seconds: $time,
                        errors: 1
                    },
                    expectations: []
                }]')
            continue
        fi

        # Parse grading expectations
        expectations=$(jq -c '.expectations // []' "$grading_file")

        # Count passes
        total=$(echo "$expectations" | jq 'length')
        passed=$(echo "$expectations" | jq '[.[] | select(.passed == true)] | length')
        failed=$((total - passed))

        # Get assertion type counts from evals.json
        baseline_total=$(jq ".evals[$idx].assertions.baseline | length" "$EVALS_JSON")
        disc_total=$(jq ".evals[$idx].assertions.discriminating | length" "$EVALS_JSON")

        # Count baseline and discriminating passes by matching assertion names
        baseline_names=$(jq -r ".evals[$idx].assertions.baseline[].name" "$EVALS_JSON")
        disc_names=$(jq -r ".evals[$idx].assertions.discriminating[].name" "$EVALS_JSON")

        baseline_passed=0
        while IFS= read -r aname; do
            [[ -z "$aname" ]] && continue
            ap=$(echo "$expectations" | jq --arg n "$aname" '[.[] | select(.text == $n and .passed == true)] | length')
            baseline_passed=$((baseline_passed + ap))
        done <<< "$baseline_names"

        disc_passed=0
        while IFS= read -r aname; do
            [[ -z "$aname" ]] && continue
            ap=$(echo "$expectations" | jq --arg n "$aname" '[.[] | select(.text == $n and .passed == true)] | length')
            disc_passed=$((disc_passed + ap))
        done <<< "$disc_names"

        # Compute pass rate
        if [[ "$total" -gt 0 ]]; then
            pass_rate=$(echo "scale=3; $passed / $total" | bc)
        else
            pass_rate="0"
        fi

        # Build expectations array with type information
        expectations_with_type="[]"
        while IFS= read -r aname; do
            [[ -z "$aname" ]] && continue
            exp_entry=$(echo "$expectations" | jq -c --arg n "$aname" '[.[] | select(.text == $n)][0] // null')
            if [[ "$exp_entry" != "null" ]]; then
                exp_entry=$(echo "$exp_entry" | jq '. + {type: "baseline"}')
                expectations_with_type=$(echo "$expectations_with_type" | jq --argjson e "$exp_entry" '. + [$e]')
            fi
        done <<< "$baseline_names"

        while IFS= read -r aname; do
            [[ -z "$aname" ]] && continue
            exp_entry=$(echo "$expectations" | jq -c --arg n "$aname" '[.[] | select(.text == $n)][0] // null')
            if [[ "$exp_entry" != "null" ]]; then
                exp_entry=$(echo "$exp_entry" | jq '. + {type: "discriminating"}')
                expectations_with_type=$(echo "$expectations_with_type" | jq --argjson e "$exp_entry" '. + [$e]')
            fi
        done <<< "$disc_names"

        RUNS=$(echo "$RUNS" | jq \
            --argjson eid "$case_id" \
            --arg ename "$case_name" \
            --arg config "$config" \
            --argjson pr "$pass_rate" \
            --argjson p "$passed" \
            --argjson f "$failed" \
            --argjson t "$total" \
            --argjson bp "$baseline_passed" \
            --argjson bt "$baseline_total" \
            --argjson dp "$disc_passed" \
            --argjson dt "$disc_total" \
            --argjson time "$local_time" \
            --argjson exps "$expectations_with_type" \
            '. + [{
                eval_id: $eid,
                eval_name: $ename,
                configuration: $config,
                run_number: 1,
                result: {
                    pass_rate: $pr,
                    passed: $p,
                    failed: $f,
                    total: $t,
                    baseline_passed: $bp,
                    baseline_total: $bt,
                    discriminating_passed: $dp,
                    discriminating_total: $dt,
                    time_seconds: $time,
                    errors: 0
                },
                expectations: $exps
            }]')
    done
done

# Compute summary statistics per configuration
compute_summary() {
    local config="$1"
    echo "$RUNS" | jq --arg c "$config" '
        [.[] | select(.configuration == $c)] |
        if length == 0 then
            {
                overall_pass_rate: {mean: 0, stddev: 0, min: 0, max: 0},
                baseline_pass_rate: {mean: 0, stddev: 0, min: 0, max: 0},
                discriminating_pass_rate: {mean: 0, stddev: 0, min: 0, max: 0},
                time_seconds: {mean: 0, stddev: 0, min: 0, max: 0}
            }
        else
            . as $runs |
            # Overall pass rates
            [$runs[].result.pass_rate] as $opr |
            ($opr | add / length) as $omean |
            (if ($opr | length) > 1 then
                ([$opr[] | (. - $omean) * (. - $omean)] | add / (length - 1)) | sqrt
            else 0 end) as $ostd |

            # Baseline pass rates
            [$runs[] | .result | if .baseline_total > 0 then .baseline_passed / .baseline_total else 0 end] as $bpr |
            ($bpr | add / length) as $bmean |
            (if ($bpr | length) > 1 then
                ([$bpr[] | (. - $bmean) * (. - $bmean)] | add / (length - 1)) | sqrt
            else 0 end) as $bstd |

            # Discriminating pass rates
            [$runs[] | .result | if .discriminating_total > 0 then .discriminating_passed / .discriminating_total else 0 end] as $dpr |
            ($dpr | add / length) as $dmean |
            (if ($dpr | length) > 1 then
                ([$dpr[] | (. - $dmean) * (. - $dmean)] | add / (length - 1)) | sqrt
            else 0 end) as $dstd |

            # Time
            [$runs[].result.time_seconds] as $times |
            ($times | add / length) as $tmean |
            (if ($times | length) > 1 then
                ([$times[] | (. - $tmean) * (. - $tmean)] | add / (length - 1)) | sqrt
            else 0 end) as $tstd |

            {
                overall_pass_rate: {
                    mean: ($omean * 1000 | round / 1000),
                    stddev: ($ostd * 1000 | round / 1000),
                    min: ($opr | min),
                    max: ($opr | max)
                },
                baseline_pass_rate: {
                    mean: ($bmean * 1000 | round / 1000),
                    stddev: ($bstd * 1000 | round / 1000),
                    min: ($bpr | min),
                    max: ($bpr | max)
                },
                discriminating_pass_rate: {
                    mean: ($dmean * 1000 | round / 1000),
                    stddev: ($dstd * 1000 | round / 1000),
                    min: ($dpr | min),
                    max: ($dpr | max)
                },
                time_seconds: {
                    mean: ($tmean * 10 | round / 10),
                    stddev: ($tstd * 10 | round / 10),
                    min: ($times | min),
                    max: ($times | max)
                }
            }
        end
    '
}

WITH_SUMMARY=$(compute_summary "with_skill")
WITHOUT_SUMMARY=$(compute_summary "without_skill")

# Compute deltas
DELTA=$(jq -n \
    --argjson ws "$WITH_SUMMARY" \
    --argjson wos "$WITHOUT_SUMMARY" \
    '{
        overall_pass_rate: (($ws.overall_pass_rate.mean - $wos.overall_pass_rate.mean) * 1000 | round / 1000 | tostring | if startswith("-") then . else "+" + . end),
        baseline_pass_rate: (($ws.baseline_pass_rate.mean - $wos.baseline_pass_rate.mean) * 1000 | round / 1000 | tostring | if startswith("-") then . else "+" + . end),
        discriminating_pass_rate: (($ws.discriminating_pass_rate.mean - $wos.discriminating_pass_rate.mean) * 1000 | round / 1000 | tostring | if startswith("-") then . else "+" + . end),
        time_seconds: (($ws.time_seconds.mean - $wos.time_seconds.mean) * 10 | round / 10 | tostring | if startswith("-") then . else "+" + . end)
    }')

# Determine previous iteration
PREV_ITER=""
if [[ -d "$WORKSPACE_DIR" ]]; then
    for dir in "$WORKSPACE_DIR"/iteration-*; do
        if [[ -d "$dir" ]] && [[ "$dir" != "$ITER_DIR" ]]; then
            dirname_only=$(basename "$dir")
            if [[ -z "$PREV_ITER" ]] || [[ "$dirname_only" > "$PREV_ITER" ]]; then
                PREV_ITER="$dirname_only"
            fi
        fi
    done
fi

# Build the IDs array
IDS_ARRAY="["
first=true
for idx in "${EVAL_INDICES[@]}"; do
    cid=$(get_case_id "$idx")
    if [[ "$first" == true ]]; then
        IDS_ARRAY="${IDS_ARRAY}${cid}"
        first=false
    else
        IDS_ARRAY="${IDS_ARRAY},${cid}"
    fi
done
IDS_ARRAY="${IDS_ARRAY}]"

# Build benchmark.json
ITERATION_NUM="${ITERATION_NAME#iteration-}"
# If iteration name is not numeric (custom name), use 0
if ! [[ "$ITERATION_NUM" =~ ^[0-9]+$ ]]; then
    ITERATION_NUM=0
fi

jq -n \
    --arg sname "todo-creator" \
    --arg spath "$PROJECT_ROOT/skills/todo-creator" \
    --arg model "claude-$MODEL" \
    --arg ts "$TIMESTAMP" \
    --argjson iter_num "$ITERATION_NUM" \
    --arg prev "$PREV_ITER" \
    --argjson ids_run "$IDS_ARRAY" \
    --argjson runs "$RUNS" \
    --argjson ws "$WITH_SUMMARY" \
    --argjson wos "$WITHOUT_SUMMARY" \
    --argjson delta "$DELTA" \
    '{
        metadata: {
            skill_name: $sname,
            skill_path: $spath,
            executor_model: $model,
            grader_model: $model,
            timestamp: $ts,
            iteration: $iter_num,
            previous_iteration: $prev,
            evals_run: $ids_run,
            runs_per_configuration: 1
        },
        runs: $runs,
        run_summary: {
            with_skill: $ws,
            without_skill: $wos,
            delta: $delta
        }
    }' > "$BENCHMARK_JSON"

log "Wrote: $BENCHMARK_JSON"

# ---------------------------------------------------------------------------
# Generate benchmark.md
# ---------------------------------------------------------------------------
generate_benchmark_md() {
    local md="$BENCHMARK_MD"

    # Header
    cat > "$md" <<MDHEADER
# Skill Benchmark: todo-creator — ${ITERATION_NAME}

**Model**: claude-$MODEL
**Date**: $(date '+%Y-%m-%d')

## Summary

| Metric | with_skill | without_skill | Delta |
|--------|:----------:|:-------------:|:-----:|
MDHEADER

    # Summary rows
    local ws_overall wos_overall d_overall
    local ws_baseline wos_baseline d_baseline
    local ws_disc wos_disc d_disc
    local ws_time wos_time d_time

    ws_overall=$(echo "$WITH_SUMMARY" | jq -r '.overall_pass_rate.mean * 100 | round | tostring + "%"')
    wos_overall=$(echo "$WITHOUT_SUMMARY" | jq -r '.overall_pass_rate.mean * 100 | round | tostring + "%"')
    d_overall=$(echo "$DELTA" | jq -r '.overall_pass_rate')

    ws_baseline=$(echo "$WITH_SUMMARY" | jq -r '.baseline_pass_rate.mean * 100 | round | tostring + "%"')
    wos_baseline=$(echo "$WITHOUT_SUMMARY" | jq -r '.baseline_pass_rate.mean * 100 | round | tostring + "%"')
    d_baseline=$(echo "$DELTA" | jq -r '.baseline_pass_rate')

    ws_disc=$(echo "$WITH_SUMMARY" | jq -r '.discriminating_pass_rate.mean * 100 | round | tostring + "%"')
    wos_disc=$(echo "$WITHOUT_SUMMARY" | jq -r '.discriminating_pass_rate.mean * 100 | round | tostring + "%"')
    d_disc=$(echo "$DELTA" | jq -r '.discriminating_pass_rate')

    ws_time=$(echo "$WITH_SUMMARY" | jq -r '.time_seconds.mean | tostring + "s"')
    wos_time=$(echo "$WITHOUT_SUMMARY" | jq -r '.time_seconds.mean | tostring + "s"')
    d_time=$(echo "$DELTA" | jq -r '.time_seconds')

    {
        echo "| Overall Pass Rate | $ws_overall | $wos_overall | **${d_overall}** |"
        echo "| Baseline Pass Rate | $ws_baseline | $wos_baseline | ${d_baseline} |"
        echo "| **Discriminating Pass Rate** | **$ws_disc** | **$wos_disc** | **${d_disc}** |"
        echo "| Time (avg) | $ws_time | $wos_time | ${d_time}s |"
        echo ""
        echo "## Per-Case Breakdown"
    } >> "$md"

    # Per-case breakdown
    for idx in "${EVAL_INDICES[@]}"; do
        local case_name
        case_name=$(get_case_name "$idx")

        {
            echo ""
            echo "### ${case_name}"
            echo ""
            echo "| Assertion | with_skill | without_skill | Discriminates? |"
            echo "|-----------|:----------:|:-------------:|:--------------:|"
        } >> "$md"

        # Render baseline assertions
        local baseline_names_list
        baseline_names_list=$(jq -r ".evals[$idx].assertions.baseline[].name" "$EVALS_JSON")
        while IFS= read -r aname; do
            [[ -z "$aname" ]] && continue
            local ws_result wos_result
            ws_result=$(echo "$RUNS" | jq -r --arg en "$case_name" --arg n "$aname" \
                '[.[] | select(.eval_name == $en and .configuration == "with_skill") | .expectations[] | select(.text == $n)][0].passed // "N/A"')
            wos_result=$(echo "$RUNS" | jq -r --arg en "$case_name" --arg n "$aname" \
                '[.[] | select(.eval_name == $en and .configuration == "without_skill") | .expectations[] | select(.text == $n)][0].passed // "N/A"')

            local ws_label wos_label disc_label
            if [[ "$ws_result" == "true" ]]; then ws_label="Pass"; else ws_label="**Fail**"; fi
            if [[ "$wos_result" == "true" ]]; then wos_label="Pass"; else wos_label="**Fail**"; fi

            if [[ "$ws_result" == "true" && "$wos_result" != "true" ]]; then
                disc_label="**Yes**"
            elif [[ "$ws_result" != "true" && "$wos_result" == "true" ]]; then
                disc_label="**Reverse**"
            else
                disc_label="No"
            fi

            echo "| $aname | $ws_label | $wos_label | $disc_label |" >> "$md"
        done <<< "$baseline_names_list"

        # Render discriminating assertions (bold names)
        local disc_names_list
        disc_names_list=$(jq -r ".evals[$idx].assertions.discriminating[].name" "$EVALS_JSON")
        while IFS= read -r aname; do
            [[ -z "$aname" ]] && continue
            local ws_result wos_result
            ws_result=$(echo "$RUNS" | jq -r --arg en "$case_name" --arg n "$aname" \
                '[.[] | select(.eval_name == $en and .configuration == "with_skill") | .expectations[] | select(.text == $n)][0].passed // "N/A"')
            wos_result=$(echo "$RUNS" | jq -r --arg en "$case_name" --arg n "$aname" \
                '[.[] | select(.eval_name == $en and .configuration == "without_skill") | .expectations[] | select(.text == $n)][0].passed // "N/A"')

            local ws_label wos_label disc_label
            if [[ "$ws_result" == "true" ]]; then ws_label="Pass"; else ws_label="**Fail**"; fi
            if [[ "$wos_result" == "true" ]]; then wos_label="Pass"; else wos_label="**Fail**"; fi

            if [[ "$ws_result" == "true" && "$wos_result" != "true" ]]; then
                disc_label="**Yes**"
            elif [[ "$ws_result" != "true" && "$wos_result" == "true" ]]; then
                disc_label="**Reverse**"
            else
                disc_label="No"
            fi

            echo "| **$aname** | $ws_label | $wos_label | $disc_label |" >> "$md"
        done <<< "$disc_names_list"
    done

    log "Wrote: $BENCHMARK_MD"
}

generate_benchmark_md

# ---------------------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------------------
log_section "Complete"
log "Iteration: $ITERATION_NAME"
log "Results directory: $ITER_DIR"
log ""
log "Files:"
log "  benchmark.json: $BENCHMARK_JSON"
log "  benchmark.md:   $BENCHMARK_MD"
log ""

# Print quick summary to stdout
echo ""
echo "Quick Summary:"
echo "  with_skill overall:        $(echo "$WITH_SUMMARY" | jq -r '.overall_pass_rate.mean * 100 | round | tostring + "%"')"
echo "  without_skill overall:     $(echo "$WITHOUT_SUMMARY" | jq -r '.overall_pass_rate.mean * 100 | round | tostring + "%"')"
echo "  with_skill discriminating: $(echo "$WITH_SUMMARY" | jq -r '.discriminating_pass_rate.mean * 100 | round | tostring + "%"')"
echo "  without_skill discrim.:    $(echo "$WITHOUT_SUMMARY" | jq -r '.discriminating_pass_rate.mean * 100 | round | tostring + "%"')"
echo ""
