#!/bin/bash
# Zoro Proving Pipeline Benchmark Script
# Collects metrics for fib, blake2s, and blake2b tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT_DIR/target/tests"
STWO_PROVER_DIR="$ROOT_DIR/stwo-cairo/stwo_cairo_prover"
CAIRO_EXECUTE="$ROOT_DIR/cairo/target/release/cairo-execute"
RESULTS_DIR="$ROOT_DIR/target/benchmarks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test programs to benchmark
TESTS=("fibonacci" "blake2s" "blake2b")

# Create results directory
mkdir -p "$RESULTS_DIR"
mkdir -p "$BUILD_DIR"

# Timestamp for this benchmark run
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="$RESULTS_DIR/benchmark_$TIMESTAMP.json"
SUMMARY_FILE="$RESULTS_DIR/benchmark_$TIMESTAMP.txt"

echo -e "${BLUE}=== Zoro Proving Pipeline Benchmark ===${NC}"
echo "Timestamp: $TIMESTAMP"
echo "Results will be saved to: $RESULTS_FILE"
echo ""

# Initialize JSON results
echo "{" > "$RESULTS_FILE"
echo '  "timestamp": "'$TIMESTAMP'",' >> "$RESULTS_FILE"
echo '  "tests": {' >> "$RESULTS_FILE"

# Function to get file size in bytes
get_file_size() {
    if [[ -f "$1" ]]; then
        stat -f%z "$1" 2>/dev/null || stat --format=%s "$1" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to get file size in human readable format
get_file_size_human() {
    local size=$(get_file_size "$1")
    if [[ $size -ge 1048576 ]]; then
        echo "$(echo "scale=2; $size / 1048576" | bc) MB"
    elif [[ $size -ge 1024 ]]; then
        echo "$(echo "scale=2; $size / 1024" | bc) KB"
    else
        echo "$size B"
    fi
}

# Function to count bytecode instructions
count_bytecode() {
    if [[ -f "$1" ]]; then
        python3 -c "import json; d=json.load(open('$1')); print(len(d.get('program',{}).get('bytecode',[])))" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to count hints
count_hints() {
    if [[ -f "$1" ]]; then
        python3 -c "import json; d=json.load(open('$1')); print(len(d.get('program',{}).get('hints',[])))" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to extract timing from output (expects format like "completed in X.XXs")
extract_time() {
    echo "$1" | grep -oE '[0-9]+\.[0-9]+s' | tail -1 || echo "N/A"
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if [[ ! -f "$CAIRO_EXECUTE" ]]; then
    echo -e "${RED}Error: Cairo compiler not built. Run 'make cairo-build' first.${NC}"
    exit 1
fi

if [[ ! -f "$STWO_PROVER_DIR/target/release/run_and_prove" ]]; then
    echo -e "${RED}Error: Stwo prover not built. Run 'make stwo-prover-build' first.${NC}"
    exit 1
fi

echo -e "${GREEN}Prerequisites OK${NC}"
echo ""

# Process each test
FIRST_TEST=true
for test in "${TESTS[@]}"; do
    echo -e "${BLUE}=== Benchmarking: $test ===${NC}"

    TEST_SOURCE="$ROOT_DIR/tests/src/${test}_test.cairo"
    EXEC_JSON="$BUILD_DIR/${test}_exec.json"
    PROOF_JSON="$BUILD_DIR/${test}_proof.json"
    RESOURCES_JSON="$BUILD_DIR/${test}_resources.json"

    # Add comma between test entries (not before first)
    if [[ "$FIRST_TEST" == "true" ]]; then
        FIRST_TEST=false
    else
        echo ',' >> "$RESULTS_FILE"
    fi

    echo "    \"$test\": {" >> "$RESULTS_FILE"

    # 1. Compile
    echo -e "${YELLOW}  Compiling...${NC}"
    COMPILE_START=$(python3 -c "import time; print(time.time())")
    "$CAIRO_EXECUTE" \
        --single-file \
        --build-only \
        --output-path "$EXEC_JSON" \
        "$TEST_SOURCE" 2>&1
    COMPILE_END=$(python3 -c "import time; print(time.time())")
    COMPILE_TIME=$(python3 -c "print(f'{$COMPILE_END - $COMPILE_START:.3f}')")
    echo -e "${GREEN}  Compiled in ${COMPILE_TIME}s${NC}"

    # 2. Get execution resources
    echo -e "${YELLOW}  Getting execution resources...${NC}"
    cd "$STWO_PROVER_DIR"
    ./target/release/get_execution_resources \
        --program "$EXEC_JSON" \
        --program_type executable \
        --output "$RESOURCES_JSON" 2>&1 || true
    cd "$ROOT_DIR"

    # 3. Prove (with timing)
    echo -e "${YELLOW}  Generating proof...${NC}"
    PROVE_START=$(python3 -c "import time; print(time.time())")
    cd "$STWO_PROVER_DIR"
    PROVE_OUTPUT=$(./target/release/run_and_prove \
        --program "$EXEC_JSON" \
        --program_type executable \
        --proof_path "$PROOF_JSON" 2>&1) || true
    cd "$ROOT_DIR"
    PROVE_END=$(python3 -c "import time; print(time.time())")
    PROVE_TIME=$(python3 -c "print(f'{$PROVE_END - $PROVE_START:.3f}')")
    echo -e "${GREEN}  Proved in ${PROVE_TIME}s${NC}"

    # 4. Verify (with timing)
    echo -e "${YELLOW}  Verifying proof...${NC}"
    VERIFY_START=$(python3 -c "import time; print(time.time())")
    cd "$STWO_PROVER_DIR"
    VERIFY_OUTPUT=$(./target/release/verify \
        --proof_path "$PROOF_JSON" \
        --channel_hash blake2s \
        --pp_trace canonical 2>&1) || true
    cd "$ROOT_DIR"
    VERIFY_END=$(python3 -c "import time; print(time.time())")
    VERIFY_TIME=$(python3 -c "print(f'{$VERIFY_END - $VERIFY_START:.3f}')")
    echo -e "${GREEN}  Verified in ${VERIFY_TIME}s${NC}"

    # 5. Collect metrics
    EXEC_SIZE=$(get_file_size "$EXEC_JSON")
    PROOF_SIZE=$(get_file_size "$PROOF_JSON")
    BYTECODE_COUNT=$(count_bytecode "$EXEC_JSON")
    HINT_COUNT=$(count_hints "$EXEC_JSON")
    SOURCE_LINES=$(wc -l < "$TEST_SOURCE" | tr -d ' ')

    # Parse execution resources if available
    if [[ -f "$RESOURCES_JSON" ]]; then
        OPCODE_COUNTS=$(cat "$RESOURCES_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('opcode_instance_counts', {})))")
        BUILTIN_COUNTS=$(cat "$RESOURCES_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('builtin_instance_counts', {})))")
        MEMORY_TABLES=$(cat "$RESOURCES_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('memory_tables_sizes', {})))")
        VERIFY_INSTR=$(cat "$RESOURCES_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('verify_instructions_count', 0))")
    else
        OPCODE_COUNTS="{}"
        BUILTIN_COUNTS="{}"
        MEMORY_TABLES="{}"
        VERIFY_INSTR="0"
    fi

    # Write to JSON
    cat >> "$RESULTS_FILE" << EOF
      "source_lines": $SOURCE_LINES,
      "bytecode_instructions": $BYTECODE_COUNT,
      "hints": $HINT_COUNT,
      "executable_size_bytes": $EXEC_SIZE,
      "proof_size_bytes": $PROOF_SIZE,
      "compile_time_s": $COMPILE_TIME,
      "prove_time_s": $PROVE_TIME,
      "verify_time_s": $VERIFY_TIME,
      "cairo_steps": $VERIFY_INSTR,
      "opcode_counts": $OPCODE_COUNTS,
      "builtin_counts": $BUILTIN_COUNTS,
      "memory_tables": $MEMORY_TABLES
    }
EOF

    echo ""
done

# Close JSON
echo '  }' >> "$RESULTS_FILE"
echo '}' >> "$RESULTS_FILE"

# Generate summary table
echo -e "${BLUE}=== Benchmark Summary ===${NC}"
echo ""

# Create summary file
cat > "$SUMMARY_FILE" << 'EOF'
================================================================================
                      ZORO PROVING PIPELINE BENCHMARK RESULTS
================================================================================

EOF
echo "Timestamp: $TIMESTAMP" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Print comparison table
python3 << PYTHON_SCRIPT
import json

with open("$RESULTS_FILE") as f:
    data = json.load(f)

tests = data["tests"]

def format_size(bytes):
    if bytes >= 1048576:
        return f"{bytes/1048576:.2f} MB"
    elif bytes >= 1024:
        return f"{bytes/1024:.2f} KB"
    return f"{bytes} B"

def format_time(seconds):
    return f"{float(seconds):.2f}s"

# Header
print("=" * 80)
print(f"{'Metric':<30} {'Fibonacci':>15} {'Blake2s':>15} {'Blake2b':>15}")
print("=" * 80)

# Basic metrics
print(f"{'Source Lines':<30} {tests['fibonacci']['source_lines']:>15} {tests['blake2s']['source_lines']:>15} {tests['blake2b']['source_lines']:>15}")
print(f"{'Bytecode Instructions':<30} {tests['fibonacci']['bytecode_instructions']:>15} {tests['blake2s']['bytecode_instructions']:>15} {tests['blake2b']['bytecode_instructions']:>15}")
print(f"{'Hints':<30} {tests['fibonacci']['hints']:>15} {tests['blake2s']['hints']:>15} {tests['blake2b']['hints']:>15}")
print(f"{'Cairo Steps (unique PCs)':<30} {tests['fibonacci']['cairo_steps']:>15} {tests['blake2s']['cairo_steps']:>15} {tests['blake2b']['cairo_steps']:>15}")
print("-" * 80)

# Size metrics
print(f"{'Executable Size':<30} {format_size(tests['fibonacci']['executable_size_bytes']):>15} {format_size(tests['blake2s']['executable_size_bytes']):>15} {format_size(tests['blake2b']['executable_size_bytes']):>15}")
print(f"{'Proof Size':<30} {format_size(tests['fibonacci']['proof_size_bytes']):>15} {format_size(tests['blake2s']['proof_size_bytes']):>15} {format_size(tests['blake2b']['proof_size_bytes']):>15}")
print("-" * 80)

# Timing metrics
print(f"{'Compile Time':<30} {format_time(tests['fibonacci']['compile_time_s']):>15} {format_time(tests['blake2s']['compile_time_s']):>15} {format_time(tests['blake2b']['compile_time_s']):>15}")
print(f"{'Prove Time':<30} {format_time(tests['fibonacci']['prove_time_s']):>15} {format_time(tests['blake2s']['prove_time_s']):>15} {format_time(tests['blake2b']['prove_time_s']):>15}")
print(f"{'Verify Time':<30} {format_time(tests['fibonacci']['verify_time_s']):>15} {format_time(tests['blake2s']['verify_time_s']):>15} {format_time(tests['blake2b']['verify_time_s']):>15}")
print("=" * 80)

# Memory tables
print("\nMemory Table Sizes:")
print("-" * 80)
for test_name in ['fibonacci', 'blake2s', 'blake2b']:
    mt = tests[test_name].get('memory_tables', {})
    addr = mt.get('address_to_id', 0)
    big = mt.get('id_to_big', 0)
    small = mt.get('id_to_small', 0)
    print(f"  {test_name}: address_to_id={addr}, id_to_big={big}, id_to_small={small}")

# Opcode counts
print("\nOpcode Instance Counts:")
print("-" * 80)
all_opcodes = set()
for test_name in ['fibonacci', 'blake2s', 'blake2b']:
    all_opcodes.update(tests[test_name].get('opcode_counts', {}).keys())

for opcode in sorted(all_opcodes):
    fib = tests['fibonacci'].get('opcode_counts', {}).get(opcode, 0)
    b2s = tests['blake2s'].get('opcode_counts', {}).get(opcode, 0)
    b2b = tests['blake2b'].get('opcode_counts', {}).get(opcode, 0)
    if fib > 0 or b2s > 0 or b2b > 0:
        print(f"  {opcode:<26} {fib:>15} {b2s:>15} {b2b:>15}")

# Builtin counts
print("\nBuiltin Instance Counts:")
print("-" * 80)
all_builtins = set()
for test_name in ['fibonacci', 'blake2s', 'blake2b']:
    all_builtins.update(tests[test_name].get('builtin_counts', {}).keys())

for builtin in sorted(all_builtins):
    fib = tests['fibonacci'].get('builtin_counts', {}).get(builtin, 0)
    b2s = tests['blake2s'].get('builtin_counts', {}).get(builtin, 0)
    b2b = tests['blake2b'].get('builtin_counts', {}).get(builtin, 0)
    if fib > 0 or b2s > 0 or b2b > 0:
        print(f"  {builtin:<26} {fib:>15} {b2s:>15} {b2b:>15}")

print("=" * 80)
PYTHON_SCRIPT

# Also save to summary file
python3 << PYTHON_SCRIPT >> "$SUMMARY_FILE"
import json

with open("$RESULTS_FILE") as f:
    data = json.load(f)

tests = data["tests"]

def format_size(bytes):
    if bytes >= 1048576:
        return f"{bytes/1048576:.2f} MB"
    elif bytes >= 1024:
        return f"{bytes/1024:.2f} KB"
    return f"{bytes} B"

def format_time(seconds):
    return f"{float(seconds):.2f}s"

# Header
print("=" * 80)
print(f"{'Metric':<30} {'Fibonacci':>15} {'Blake2s':>15} {'Blake2b':>15}")
print("=" * 80)

# Basic metrics
print(f"{'Source Lines':<30} {tests['fibonacci']['source_lines']:>15} {tests['blake2s']['source_lines']:>15} {tests['blake2b']['source_lines']:>15}")
print(f"{'Bytecode Instructions':<30} {tests['fibonacci']['bytecode_instructions']:>15} {tests['blake2s']['bytecode_instructions']:>15} {tests['blake2b']['bytecode_instructions']:>15}")
print(f"{'Hints':<30} {tests['fibonacci']['hints']:>15} {tests['blake2s']['hints']:>15} {tests['blake2b']['hints']:>15}")
print(f"{'Cairo Steps (unique PCs)':<30} {tests['fibonacci']['cairo_steps']:>15} {tests['blake2s']['cairo_steps']:>15} {tests['blake2b']['cairo_steps']:>15}")
print("-" * 80)

# Size metrics
print(f"{'Executable Size':<30} {format_size(tests['fibonacci']['executable_size_bytes']):>15} {format_size(tests['blake2s']['executable_size_bytes']):>15} {format_size(tests['blake2b']['executable_size_bytes']):>15}")
print(f"{'Proof Size':<30} {format_size(tests['fibonacci']['proof_size_bytes']):>15} {format_size(tests['blake2s']['proof_size_bytes']):>15} {format_size(tests['blake2b']['proof_size_bytes']):>15}")
print("-" * 80)

# Timing metrics
print(f"{'Compile Time':<30} {format_time(tests['fibonacci']['compile_time_s']):>15} {format_time(tests['blake2s']['compile_time_s']):>15} {format_time(tests['blake2b']['compile_time_s']):>15}")
print(f"{'Prove Time':<30} {format_time(tests['fibonacci']['prove_time_s']):>15} {format_time(tests['blake2s']['prove_time_s']):>15} {format_time(tests['blake2b']['prove_time_s']):>15}")
print(f"{'Verify Time':<30} {format_time(tests['fibonacci']['verify_time_s']):>15} {format_time(tests['blake2s']['verify_time_s']):>15} {format_time(tests['blake2b']['verify_time_s']):>15}")
print("=" * 80)

# Memory tables
print("\nMemory Table Sizes:")
print("-" * 80)
for test_name in ['fibonacci', 'blake2s', 'blake2b']:
    mt = tests[test_name].get('memory_tables', {})
    addr = mt.get('address_to_id', 0)
    big = mt.get('id_to_big', 0)
    small = mt.get('id_to_small', 0)
    print(f"  {test_name}: address_to_id={addr}, id_to_big={big}, id_to_small={small}")

# Opcode counts
print("\nOpcode Instance Counts:")
print("-" * 80)
all_opcodes = set()
for test_name in ['fibonacci', 'blake2s', 'blake2b']:
    all_opcodes.update(tests[test_name].get('opcode_counts', {}).keys())

for opcode in sorted(all_opcodes):
    fib = tests['fibonacci'].get('opcode_counts', {}).get(opcode, 0)
    b2s = tests['blake2s'].get('opcode_counts', {}).get(opcode, 0)
    b2b = tests['blake2b'].get('opcode_counts', {}).get(opcode, 0)
    if fib > 0 or b2s > 0 or b2b > 0:
        print(f"  {opcode:<26} {fib:>15} {b2s:>15} {b2b:>15}")

# Builtin counts
print("\nBuiltin Instance Counts:")
print("-" * 80)
all_builtins = set()
for test_name in ['fibonacci', 'blake2s', 'blake2b']:
    all_builtins.update(tests[test_name].get('builtin_counts', {}).keys())

for builtin in sorted(all_builtins):
    fib = tests['fibonacci'].get('builtin_counts', {}).get(builtin, 0)
    b2s = tests['blake2s'].get('builtin_counts', {}).get(builtin, 0)
    b2b = tests['blake2b'].get('builtin_counts', {}).get(builtin, 0)
    if fib > 0 or b2s > 0 or b2b > 0:
        print(f"  {builtin:<26} {fib:>15} {b2s:>15} {b2b:>15}")

print("=" * 80)
PYTHON_SCRIPT

echo ""
echo -e "${GREEN}Benchmark complete!${NC}"
echo "JSON results: $RESULTS_FILE"
echo "Text summary: $SUMMARY_FILE"
