.PHONY: test-build test-execute test-run-fib test-run-blake2b test-run-blake2s test-run-all \
        test-compile-fib test-compile-blake2b test-compile-blake2s test-exec-fib test-exec-blake2b test-exec-blake2s \
        test-compile-blake2s-params test-compile-blake2b-params test-exec-blake2s-params test-exec-blake2b-params \
        test-run-blake2s-params test-run-blake2b-params \
        test-compile-zcash-blake test-exec-zcash-blake test-run-zcash-blake \
        stwo-prover-build test-prove-fib test-verify-fib test-prove-blake2b test-verify-blake2b test-prove-blake2s test-verify-blake2s \
        test-prove-blake2s-params test-prove-blake2b-params test-verify-blake2s-params test-verify-blake2b-params \
        test-prove-zcash-blake test-verify-zcash-blake \
        test-prove-all test-verify-all test-full-fib test-full-blake2b test-full-blake2s \
        test-full-blake2s-params test-full-blake2b-params test-full-zcash-blake \
        stwo-air-infra-build stwo-air-infra-test stwo-cairo-build stwo-cairo-test \
        cairo-build cairo-test cairo-vm-build cairo-vm-deps cairo-vm-test zoro-build zoro-test \
        scarb-build scarb-build-release \
        air-codegen air-codegen-all air-write-json \
        benchmark benchmark-quick test-resources-fib test-resources-blake2s test-resources-blake2b test-resources-zcash-blake \
        clean clean-tests clean-cargo clean-scarb

# Directories
BUILD_DIR := target/tests
CAIRO_EXECUTE := ./cairo/target/release/cairo-execute
STWO_PROVER_DIR := ./stwo-cairo/stwo_cairo_prover
SCARB := ./scarb/target/debug/scarb

# Test targets using local scarb fork
test-build:
	cd tests && ../$(SCARB) build

test-execute:
	cd tests && ../$(SCARB) execute --print-program-output

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

test-compile-blake2s-params: $(BUILD_DIR)
	$(CAIRO_EXECUTE) \
		--single-file \
		--build-only \
		--output-path $(BUILD_DIR)/blake2s_params_exec.json \
		tests/src/blake2s_params_test.cairo

test-compile-blake2b-params: $(BUILD_DIR)
	$(CAIRO_EXECUTE) \
		--single-file \
		--build-only \
		--output-path $(BUILD_DIR)/blake2b_params_exec.json \
		tests/src/blake2b_params_test.cairo

test-compile-zcash-blake: $(BUILD_DIR)
	$(CAIRO_EXECUTE) \
		--single-file \
		--build-only \
		--output-path $(BUILD_DIR)/zcash_blake_exec.json \
		tests/src/zcash_blake_test.cairo

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

test-exec-blake2s-params:
	$(CAIRO_EXECUTE) \
		--prebuilt \
		--layout all_cairo \
		--print-outputs \
		--output-path $(BUILD_DIR)/blake2s_params.pie \
		$(BUILD_DIR)/blake2s_params_exec.json

test-exec-blake2b-params:
	$(CAIRO_EXECUTE) \
		--prebuilt \
		--layout all_cairo \
		--print-outputs \
		--output-path $(BUILD_DIR)/blake2b_params.pie \
		$(BUILD_DIR)/blake2b_params_exec.json

test-exec-zcash-blake:
	$(CAIRO_EXECUTE) \
		--prebuilt \
		--layout all_cairo \
		--print-outputs \
		--output-path $(BUILD_DIR)/zcash_blake.pie \
		$(BUILD_DIR)/zcash_blake_exec.json

# Combined: compile and run in one command
test-run-fib: test-compile-fib test-exec-fib

test-run-blake2b: test-compile-blake2b test-exec-blake2b

test-run-blake2s: test-compile-blake2s test-exec-blake2s

test-run-blake2s-params: test-compile-blake2s-params test-exec-blake2s-params

test-run-blake2b-params: test-compile-blake2b-params test-exec-blake2b-params

test-run-zcash-blake: test-compile-zcash-blake test-exec-zcash-blake

# Run all tests
test-run-all: test-run-fib

# =============================================================================
# Proving and verification targets (using stwo_cairo_prover)
# =============================================================================
# Generate STARK proofs and verify them using stwo_cairo_prover binaries
#
# Usage:
#   make stwo-prover-build   # Build the stwo prover binaries (one-time)
#   make test-prove-fib      # Generate proof for fibonacci test
#   make test-verify-fib     # Verify fibonacci proof
#   make test-prove-all      # Generate proofs for all tests
#   make test-verify-all     # Verify all proofs
#   make test-full-fib       # Full pipeline: compile -> prove -> verify
# =============================================================================

# Build stwo_cairo_prover binaries
stwo-prover-build:
	cd $(STWO_PROVER_DIR) && cargo build --release

# Prove test programs (generates STARK proof using run_and_prove)
test-prove-fib: test-compile-fib
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/fibonacci_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/fibonacci_proof.json

test-prove-blake2b: test-compile-blake2b
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/blake2b_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/blake2b_proof.json

test-prove-blake2s: test-compile-blake2s
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/blake2s_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/blake2s_proof.json

test-prove-blake2s-params: test-compile-blake2s-params
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/blake2s_params_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/blake2s_params_proof.json

test-prove-blake2b-params: test-compile-blake2b-params
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/blake2b_params_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/blake2b_params_proof.json

test-prove-zcash-blake: test-compile-zcash-blake
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/zcash_blake_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/zcash_blake_proof.json

# Verify proofs (using verify binary)
test-verify-fib:
	cd $(STWO_PROVER_DIR) && cargo run --release --bin verify -- \
		--proof_path ../../$(BUILD_DIR)/fibonacci_proof.json \
		--channel_hash blake2s \
		--pp_trace canonical

test-verify-blake2b:
	cd $(STWO_PROVER_DIR) && cargo run --release --bin verify -- \
		--proof_path ../../$(BUILD_DIR)/blake2b_proof.json \
		--channel_hash blake2s \
		--pp_trace canonical

test-verify-blake2s:
	cd $(STWO_PROVER_DIR) && cargo run --release --bin verify -- \
		--proof_path ../../$(BUILD_DIR)/blake2s_proof.json \
		--channel_hash blake2s \
		--pp_trace canonical

test-verify-blake2s-params:
	cd $(STWO_PROVER_DIR) && cargo run --release --bin verify -- \
		--proof_path ../../$(BUILD_DIR)/blake2s_params_proof.json \
		--channel_hash blake2s \
		--pp_trace canonical

test-verify-blake2b-params:
	cd $(STWO_PROVER_DIR) && cargo run --release --bin verify -- \
		--proof_path ../../$(BUILD_DIR)/blake2b_params_proof.json \
		--channel_hash blake2s \
		--pp_trace canonical

test-verify-zcash-blake:
	cd $(STWO_PROVER_DIR) && cargo run --release --bin verify -- \
		--proof_path ../../$(BUILD_DIR)/zcash_blake_proof.json \
		--channel_hash blake2s \
		--pp_trace canonical

# Combined targets
test-prove-all: test-prove-fib

test-verify-all: test-verify-fib

# Full pipeline: compile -> prove -> verify
test-full-fib: test-prove-fib test-verify-fib

test-full-blake2b: test-prove-blake2b test-verify-blake2b

test-full-blake2s: test-prove-blake2s test-verify-blake2s

test-full-blake2s-params: test-prove-blake2s-params test-verify-blake2s-params

test-full-blake2b-params: test-prove-blake2b-params test-verify-blake2b-params

test-full-zcash-blake: test-prove-zcash-blake test-verify-zcash-blake

# =============================================================================
# Subproject build and test targets
# =============================================================================

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
	cd zoro && ../$(SCARB) --profile release build

zoro-test:
	cd zoro && ../$(SCARB) cairo-test

scarb-build:
	cd scarb && cargo build -p scarb --no-default-features
	cd scarb && cargo clean -p scarb-execute && cargo build -p scarb-execute

scarb-build-release:
	cd scarb && cargo build -p scarb --no-default-features --release

# =============================================================================
# AIR Code Generation (stwo-air-infra -> stwo-cairo)
# =============================================================================
# Generate Rust/Cairo constraint code from compiled AIR JSON files
#
# Usage:
#   make air-codegen       # Generate code for supported AIRs only
#   make air-codegen-all   # Generate code for ALL AIRs (including blake2b)
#   make air-write-json    # Recompile AIR definitions to JSON
# =============================================================================

AIR_INFRA_DIR := stwo-air-infra
AIR_JSON_SOURCE := $(AIR_INFRA_DIR)/crates/compiled_casm_air/src/compiled_jsons
STWO_CAIRO_DIR := stwo-cairo

# Destination paths in stwo-cairo
RUST_CONSTRAINTS_DEST := $(STWO_CAIRO_DIR)/stwo_cairo_prover/crates/cairo-air/src/components
WITNESS_DEST := $(STWO_CAIRO_DIR)/stwo_cairo_prover/crates/prover/src/witness
CAIRO_CONSTRAINTS_DEST := $(STWO_CAIRO_DIR)/stwo_cairo_verifier/crates/verifier_core/src/constraints

# Generate code for ALL AIRs into stwo-cairo
air-codegen:
	@mkdir -p $(CAIRO_CONSTRAINTS_DEST)/subroutines
	cd $(AIR_INFRA_DIR) && cargo run --bin cairo_code_gen -- generate-stwo-cairo \
		--source crates/compiled_casm_air/src \
		--stwo-cairo-path ../$(STWO_CAIRO_DIR)

# Alias for air-codegen (both now generate all AIRs)
air-codegen-all: air-codegen

# Recompile AIR definitions to JSON (run this after modifying AIR definitions)
air-write-json:
	@echo "Writing AIR JSONs..."
	@echo "Available opcodes: fib, bit-unpack, ret, assert-eq, call, jump"
	cd $(AIR_INFRA_DIR) && FIX=1 cargo test -p air_infra test_casm_registry --release

# =============================================================================
# Benchmarking targets
# =============================================================================
# Collect metrics for fib, blake2s, and blake2b tests
#
# Usage:
#   make benchmark           # Full benchmark with prove/verify timing
#   make benchmark-quick     # Quick metrics without proving (just resources)
#   make test-resources-fib  # Get execution resources for fibonacci only
# =============================================================================

# Full benchmark: compile, prove, verify all tests with timing
benchmark:
	./scripts/benchmark.sh

# Quick execution resources for individual tests (no proving)
test-resources-fib: test-compile-fib
	cd $(STWO_PROVER_DIR) && cargo run --release --bin get_execution_resources -- \
		--program ../../$(BUILD_DIR)/fibonacci_exec.json \
		--program_type executable \
		--output ../../$(BUILD_DIR)/fibonacci_resources.json
	@echo "Resources saved to $(BUILD_DIR)/fibonacci_resources.json"
	@cat $(BUILD_DIR)/fibonacci_resources.json | python3 -m json.tool

test-resources-blake2s: test-compile-blake2s
	cd $(STWO_PROVER_DIR) && cargo run --release --bin get_execution_resources -- \
		--program ../../$(BUILD_DIR)/blake2s_exec.json \
		--program_type executable \
		--output ../../$(BUILD_DIR)/blake2s_resources.json
	@echo "Resources saved to $(BUILD_DIR)/blake2s_resources.json"
	@cat $(BUILD_DIR)/blake2s_resources.json | python3 -m json.tool

test-resources-blake2b: test-compile-blake2b
	cd $(STWO_PROVER_DIR) && cargo run --release --bin get_execution_resources -- \
		--program ../../$(BUILD_DIR)/blake2b_exec.json \
		--program_type executable \
		--output ../../$(BUILD_DIR)/blake2b_resources.json
	@echo "Resources saved to $(BUILD_DIR)/blake2b_resources.json"
	@cat $(BUILD_DIR)/blake2b_resources.json | python3 -m json.tool

test-resources-zcash-blake: test-compile-zcash-blake
	cd $(STWO_PROVER_DIR) && cargo run --release --bin get_execution_resources -- \
		--program ../../$(BUILD_DIR)/zcash_blake_exec.json \
		--program_type executable \
		--output ../../$(BUILD_DIR)/zcash_blake_resources.json
	@echo "Resources saved to $(BUILD_DIR)/zcash_blake_resources.json"
	@cat $(BUILD_DIR)/zcash_blake_resources.json | python3 -m json.tool

# Quick benchmark: just execution resources without proving
benchmark-quick: test-resources-fib test-resources-blake2s test-resources-blake2b test-resources-zcash-blake
	@echo ""
	@echo "=== Quick Benchmark Summary ==="
	@echo "Fibonacci resources:"
	@cat $(BUILD_DIR)/fibonacci_resources.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'  Cairo steps: {d[\"verify_instructions_count\"]}')"
	@echo "Blake2s resources:"
	@cat $(BUILD_DIR)/blake2s_resources.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'  Cairo steps: {d[\"verify_instructions_count\"]}')"
	@echo "Blake2b resources:"
	@cat $(BUILD_DIR)/blake2b_resources.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'  Cairo steps: {d[\"verify_instructions_count\"]}')"
	@echo "Zcash Blake resources:"
	@cat $(BUILD_DIR)/zcash_blake_resources.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'  Cairo steps: {d[\"verify_instructions_count\"]}')"
	@echo ""
	@echo "File sizes:"
	@ls -lh $(BUILD_DIR)/*_exec.json $(BUILD_DIR)/*_proof.json 2>/dev/null || echo "  (run 'make benchmark' first for proof sizes)"

# =============================================================================
# Clean targets
# =============================================================================
# Remove build artifacts and cargo target directories
#
# Usage:
#   make clean           # Clean all build artifacts
#   make clean-tests     # Clean only test outputs
#   make clean-cargo     # Clean all cargo target directories
#   make clean-scarb     # Clean scarb build directories
# =============================================================================

# Clean test build outputs
clean-tests:
	rm -rf $(BUILD_DIR)

# Clean all cargo target directories in subprojects
clean-cargo:
	cd cairo && cargo clean
	cd cairo-vm && cargo clean
	cd scarb && cargo clean
	cd stwo-cairo/stwo_cairo_prover && cargo clean
	cd stwo-air-infra && cargo clean

# Clean scarb build directories
clean-scarb:
	rm -rf tests/target
	rm -rf zoro/target

# Clean everything
clean: clean-tests clean-cargo clean-scarb
	@echo "Cleaned all build artifacts"
