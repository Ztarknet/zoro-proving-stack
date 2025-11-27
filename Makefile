.PHONY: test-build test-execute test-run-fib test-run-blake2b test-run-blake2s test-run-all \
        test-compile-fib test-compile-blake2b test-compile-blake2s test-exec-fib test-exec-blake2b test-exec-blake2s \
        cairo-prove-build test-prove-fib test-verify-fib test-prove-blake2b test-verify-blake2b test-prove-blake2s test-verify-blake2s \
        test-prove-all test-verify-all test-full-fib test-full-blake2b test-full-blake2s \
        stwo-air-infra-build stwo-air-infra-test stwo-cairo-build stwo-cairo-test \
        cairo-build cairo-test cairo-vm-build cairo-vm-deps cairo-vm-test zoro-build zoro-test

# Directories
BUILD_DIR := target/tests
CAIRO_EXECUTE := ./cairo/target/release/cairo-execute
CAIRO_PROVE := ./stwo-cairo/cairo-prove/target/release/cairo-prove

# Test targets using scarb
test-build:
	cd tests && scarb build

test-execute:
	cd tests && scarb execute --print-program-output

# =============================================================================
# Test targets using local cairo-execute (from forked cairo compiler)
# =============================================================================
# Two-step process: 1) compile to executable JSON, 2) run with cairo-vm
#
# Usage:
#   make test-compile-fib   # Compile fibonacci test
#   make test-exec-fib      # Run compiled fibonacci test
#   make test-run-fib       # Compile and run fibonacci test
# =============================================================================

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Step 1: Compile test files to executable JSON
test-compile-fib: $(BUILD_DIR)
	$(CAIRO_EXECUTE) \
		--single-file \
		--build-only \
		--output-path $(BUILD_DIR)/fibonacci_exec.json \
		tests/src/fibonacci_test.cairo

test-compile-blake2b: $(BUILD_DIR)
	$(CAIRO_EXECUTE) \
		--single-file \
		--build-only \
		--output-path $(BUILD_DIR)/blake2b_exec.json \
		tests/src/blake2b_test.cairo

test-compile-blake2s: $(BUILD_DIR)
	$(CAIRO_EXECUTE) \
		--single-file \
		--build-only \
		--output-path $(BUILD_DIR)/blake2s_exec.json \
		tests/src/blake2s_test.cairo

# Step 2: Execute prebuilt test executables
test-exec-fib:
	$(CAIRO_EXECUTE) \
		--prebuilt \
		--layout all_cairo \
		--print-outputs \
		--output-path $(BUILD_DIR)/fibonacci.pie \
		$(BUILD_DIR)/fibonacci_exec.json

test-exec-blake2b:
	$(CAIRO_EXECUTE) \
		--prebuilt \
		--layout all_cairo \
		--print-outputs \
		--output-path $(BUILD_DIR)/blake2b.pie \
		$(BUILD_DIR)/blake2b_exec.json

test-exec-blake2s:
	$(CAIRO_EXECUTE) \
		--prebuilt \
		--layout all_cairo \
		--print-outputs \
		--output-path $(BUILD_DIR)/blake2s.pie \
		$(BUILD_DIR)/blake2s_exec.json

# Combined: compile and run in one command
test-run-fib: test-compile-fib test-exec-fib

test-run-blake2b: test-compile-blake2b test-exec-blake2b

test-run-blake2s: test-compile-blake2s test-exec-blake2s

# Run all tests
test-run-all: test-run-fib

# =============================================================================
# Proving and verification targets (using stwo-cairo prover)
# =============================================================================
# Generate STARK proofs and verify them using cairo-prove CLI
#
# Usage:
#   make cairo-prove-build   # Build the cairo-prove CLI (one-time)
#   make test-prove-fib      # Generate proof for fibonacci test
#   make test-verify-fib     # Verify fibonacci proof
#   make test-prove-all      # Generate proofs for all tests
#   make test-verify-all     # Verify all proofs
# =============================================================================

# Build cairo-prove CLI
cairo-prove-build:
	cd stwo-cairo/cairo-prove && ./build.sh

# Prove test programs (generates STARK proof)
test-prove-fib: test-compile-fib
	$(CAIRO_PROVE) prove \
		$(BUILD_DIR)/fibonacci_exec.json \
		$(BUILD_DIR)/fibonacci_proof.json

test-prove-blake2b: test-compile-blake2b
	$(CAIRO_PROVE) prove \
		$(BUILD_DIR)/blake2b_exec.json \
		$(BUILD_DIR)/blake2b_proof.json

test-prove-blake2s: test-compile-blake2s
	$(CAIRO_PROVE) prove \
		$(BUILD_DIR)/blake2s_exec.json \
		$(BUILD_DIR)/blake2s_proof.json

# Verify proofs
test-verify-fib:
	$(CAIRO_PROVE) verify $(BUILD_DIR)/fibonacci_proof.json

test-verify-blake2b:
	$(CAIRO_PROVE) verify $(BUILD_DIR)/blake2b_proof.json

test-verify-blake2s:
	$(CAIRO_PROVE) verify $(BUILD_DIR)/blake2s_proof.json

# Combined targets
test-prove-all: test-prove-fib

test-verify-all: test-verify-fib

# Full pipeline: compile -> prove -> verify
test-full-fib: test-prove-fib test-verify-fib

test-full-blake2b: test-prove-blake2b test-verify-blake2b

test-full-blake2s: test-prove-blake2s test-verify-blake2s

stwo-air-infra-build:
	cd stwo-air-infra && cargo build --release

stwo-air-infra-test:
	cd stwo-air-infra && cargo test --release

stwo-cairo-build:
	cd stwo-cairo/stwo_cairo_prover && cargo build --release

stwo-cairo-test:
	cd stwo-cairo/stwo_cairo_prover && cargo test

cairo-build:
	cd cairo && cargo +1.89 build --release

cairo-test:
	cd cairo && cargo +1.89 test

cairo-vm-build:
	cd cairo-vm && cargo build --release

cairo-vm-deps:
	cd cairo-vm && make deps

cairo-vm-test:
	cd cairo-vm && . cairo-vm-env/bin/activate && make test

zoro-build:
	cd zoro && scarb --profile release build

zoro-test:
	cd zoro && scarb cairo-test
