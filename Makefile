.PHONY: test-build test-execute test-steps test-steps-fib test-steps-blake2s test-steps-blake2b \
        test-run-fib test-run-blake2b test-run-blake2s test-run-all \
        test-compile-fib test-compile-blake2b test-compile-blake2s test-exec-fib test-exec-blake2b test-exec-blake2s \
        test-compile-blake2s-params test-compile-blake2b-params test-exec-blake2s-params test-exec-blake2b-params \
        test-run-blake2s-params test-run-blake2b-params \
        test-compile-zcash-blake test-exec-zcash-blake test-run-zcash-blake \
        stwo-prover-build test-prove-fib test-verify-fib test-prove-blake2b test-verify-blake2b test-prove-blake2s test-verify-blake2s \
        test-prove-blake2s-params test-prove-blake2b-params test-verify-blake2s-params test-verify-blake2b-params \
        test-prove-zcash-blake test-verify-zcash-blake \
        test-prove-all test-verify-all test-full-fib test-full-blake2b test-full-blake2s \
        test-full-blake2s-params test-full-blake2b-params test-full-zcash-blake \
        test-prove-cv-fib test-prove-cv-blake2b test-prove-cv-blake2s \
        test-prove-cv-blake2s-params test-prove-cv-blake2b-params test-prove-cv-zcash-blake \
        test-verify-cv-fib test-verify-cv-blake2b test-verify-cv-blake2s \
        test-verify-cv-blake2s-params test-verify-cv-blake2b-params test-verify-cv-zcash-blake \
        test-full-cv-fib test-full-cv-blake2b test-full-cv-blake2s \
        test-full-cv-blake2s-params test-full-cv-blake2b-params test-full-cv-zcash-blake test-full-cv-all \
        stwo-air-infra-build stwo-air-infra-test stwo-cairo-build stwo-cairo-test \
        stwo-cairo-verifier-build stwo-cairo-verifier-test \
        cairo-build cairo-test cairo-vm-build cairo-vm-deps cairo-vm-test zoro-build zoro-test zoro-base-test zoro-opcodes-test \
        scarb-build scarb-build-release scarb-test scarb-burn-build scarb-burn-test \
        proving-utils-build proving-utils-test \
        air-codegen air-codegen-all air-write-json \
        benchmark benchmark-quick test-resources-fib test-resources-blake2s test-resources-blake2b test-resources-zcash-blake \
        zoro-flamegraph zoro-flamegraph-build zoro-flamegraph-blake2b \
        zoro-regenerate-tests zoro-regenerate-client-tests zoro-regenerate-assumevalid-tests \
        run-zoro-bridge-indexer run-zoro-assumevalid-prove \
        clean clean-tests clean-cargo clean-scarb

# Directories
BUILD_DIR := target/tests
CAIRO_EXECUTE := ./cairo/target/release/cairo-execute
STWO_PROVER_DIR := ./stwo-cairo/stwo_cairo_prover
STWO_VERIFIER_DIR := ./stwo-cairo/stwo_cairo_verifier
SCARB := ./scarb/target/release/scarb

# Test targets using local scarb fork
test-build:
	cd tests && ../$(SCARB) build

test-execute:
	cd tests && ../$(SCARB) execute --executable-name fibonacci --print-program-output

# Get step count for specific test executables
test-steps-fib:
	@echo "=== Fibonacci ==="
	@cd tests && ../$(SCARB) execute --executable-name fibonacci --print-resource-usage 2>&1 | grep -E '(steps:|memory holes:|range_check:)'

test-steps-blake2s:
	@echo "=== Blake2s ==="
	@cd tests && ../$(SCARB) execute --executable-name blake2s --print-resource-usage 2>&1 | grep -E '(steps:|memory holes:|range_check:)'

test-steps-blake2b:
	@echo "=== Blake2b ==="
	@cd tests && ../$(SCARB) execute --executable-name blake2b --print-resource-usage 2>&1 | grep -E '(steps:|memory holes:|range_check:)'

# Run all step counts
test-steps: test-steps-fib test-steps-blake2s test-steps-blake2b

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
# Cairo Verifier proving and verification targets (using stwo_cairo_verifier)
# =============================================================================
# Generate STARK proofs in cairo-serde format and verify them using the Cairo verifier
#
# Usage:
#   make test-prove-cv-fib      # Generate proof for fibonacci (cairo-serde format)
#   make test-verify-cv-fib     # Verify fibonacci proof with Cairo verifier
#   make test-full-cv-fib       # Full pipeline: compile -> prove -> verify (Cairo)
#   make test-full-cv-all       # Run all Cairo verifier tests
# =============================================================================

# Prove test programs with cairo-serde format (for Cairo verifier)
test-prove-cv-fib: test-compile-fib
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/fibonacci_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/fibonacci_proof.serde.json \
		--proof-format cairo-serde

test-prove-cv-blake2b: test-compile-blake2b
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/blake2b_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/blake2b_proof.serde.json \
		--proof-format cairo-serde

test-prove-cv-blake2s: test-compile-blake2s
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/blake2s_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/blake2s_proof.serde.json \
		--proof-format cairo-serde

test-prove-cv-blake2s-params: test-compile-blake2s-params
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/blake2s_params_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/blake2s_params_proof.serde.json \
		--proof-format cairo-serde

test-prove-cv-blake2b-params: test-compile-blake2b-params
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/blake2b_params_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/blake2b_params_proof.serde.json \
		--proof-format cairo-serde

test-prove-cv-zcash-blake: test-compile-zcash-blake
	cd $(STWO_PROVER_DIR) && cargo run --release --bin run_and_prove -- \
		--program ../../$(BUILD_DIR)/zcash_blake_exec.json \
		--program_type executable \
		--proof_path ../../$(BUILD_DIR)/zcash_blake_proof.serde.json \
		--proof-format cairo-serde

# Verify proofs with Cairo verifier (using scarb execute)
test-verify-cv-fib:
	cd $(STWO_VERIFIER_DIR) && ../../$(SCARB) execute \
		-p stwo_cairo_verifier \
		-F qm31_opcode \
		--arguments-file ../../$(BUILD_DIR)/fibonacci_proof.serde.json \
		--print-program-output

test-verify-cv-blake2b:
	cd $(STWO_VERIFIER_DIR) && ../../$(SCARB) execute \
		-p stwo_cairo_verifier \
		-F qm31_opcode \
		--arguments-file ../../$(BUILD_DIR)/blake2b_proof.serde.json \
		--print-program-output

test-verify-cv-blake2s:
	cd $(STWO_VERIFIER_DIR) && ../../$(SCARB) execute \
		-p stwo_cairo_verifier \
		-F qm31_opcode \
		--arguments-file ../../$(BUILD_DIR)/blake2s_proof.serde.json \
		--print-program-output

test-verify-cv-blake2s-params:
	cd $(STWO_VERIFIER_DIR) && ../../$(SCARB) execute \
		-p stwo_cairo_verifier \
		-F qm31_opcode \
		--arguments-file ../../$(BUILD_DIR)/blake2s_params_proof.serde.json \
		--print-program-output

test-verify-cv-blake2b-params:
	cd $(STWO_VERIFIER_DIR) && ../../$(SCARB) execute \
		-p stwo_cairo_verifier \
		-F qm31_opcode \
		--arguments-file ../../$(BUILD_DIR)/blake2b_params_proof.serde.json \
		--print-program-output

test-verify-cv-zcash-blake:
	cd $(STWO_VERIFIER_DIR) && ../../$(SCARB) execute \
		-p stwo_cairo_verifier \
		-F qm31_opcode \
		--arguments-file ../../$(BUILD_DIR)/zcash_blake_proof.serde.json \
		--print-program-output

# Full pipeline with Cairo verifier: compile -> prove (cairo-serde) -> verify (Cairo)
test-full-cv-fib: test-prove-cv-fib test-verify-cv-fib

test-full-cv-blake2b: test-prove-cv-blake2b test-verify-cv-blake2b

test-full-cv-blake2s: test-prove-cv-blake2s test-verify-cv-blake2s

test-full-cv-blake2s-params: test-prove-cv-blake2s-params test-verify-cv-blake2s-params

test-full-cv-blake2b-params: test-prove-cv-blake2b-params test-verify-cv-blake2b-params

test-full-cv-zcash-blake: test-prove-cv-zcash-blake test-verify-cv-zcash-blake

# Run all Cairo verifier tests
test-full-cv-all: test-full-cv-fib test-full-cv-blake2b test-full-cv-blake2s \
                  test-full-cv-blake2s-params test-full-cv-blake2b-params test-full-cv-zcash-blake

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

stwo-cairo-verifier-build:
	cd stwo-cairo/stwo_cairo_verifier && ../../$(SCARB) build -p stwo_cairo_verifier --features qm31_opcode

stwo-cairo-verifier-test:
	cd stwo-cairo/stwo_cairo_verifier && ../../$(SCARB) test -p stwo_cairo_verifier --features qm31_opcode

cairo-build:
	cd cairo && cargo +1.89 build --release

cairo-test:
	cd cairo && cargo +1.89 test

cairo-vm-build:
	cd cairo-vm && cargo build --release

cairo-vm-deps:
	cd cairo-vm && make deps

cairo-vm-test:
	@if [ ! -d "cairo-vm/cairo-vm-env" ]; then $(MAKE) cairo-vm-deps; fi
	cd cairo-vm && . cairo-vm-env/bin/activate && make test

zoro-build:
	cd zoro && ../$(SCARB) --profile release build
	cd zoro && cargo build --release

zoro-install-cli:
	cd zoro && cargo install --path crates/zoro-spv-verify --bin spv-cli

zoro-test:
	cd zoro && ../$(SCARB) cairo-test
	cd zoro && cargo test

zoro-full-base-test:
	cd zoro && ../$(SCARB) test

zoro-full-opcodes-test:
	@# For blake2b, we need to skip cairo-test for assumevalid (it doesn't support the opcode)
	@# and run the custom test-blake2b script instead
	cd zoro/packages/assumevalid && ../../../$(SCARB) run test-blake2b
	cd zoro && ../$(SCARB) test --package client --features=blake2b
	@# consensus and utils cairo-test don't require blake2b feature (tests use pure Cairo impl)
	cd zoro && ../$(SCARB) cairo-test --package consensus
	cd zoro && ../$(SCARB) cairo-test --package utils

# =============================================================================
# Zoro test data regeneration
# =============================================================================
# Regenerate test JSON files from Zcash RPC for client and assumevalid packages.
# Requires: python3 with requests package (pip install requests)
# Uses: ZCASH_RPC env var or defaults to https://rpc.mainnet.ztarknet.cash
#
# Usage:
#   make zoro-regenerate-tests              # Regenerate all test data
#   make zoro-regenerate-client-tests       # Regenerate client package tests only
#   make zoro-regenerate-assumevalid-tests  # Regenerate assumevalid package tests only
# =============================================================================

ZORO_DATA_SCRIPT := zoro/scripts/data/generate_data.py
ZORO_CLIENT_DATA_DIR := zoro/packages/client/tests/data
ZORO_ASSUMEVALID_DATA_DIR := zoro/packages/assumevalid/tests/data

# Client test heights (light_*.json files - each with 1 block)
# Includes network upgrade boundaries: Overwinter (347500), Sapling (419200),
# Blossom (653600), Heartwood (903000), Canopy (1046400), NU5 (1687104)
ZORO_CLIENT_HEIGHTS := 100 1000 10000 347499 347500 419199 419200 653599 653600 \
                       902999 903000 1046399 1046400 1687103 1687104 2000000 3000000

# Assumevalid batch sizes (batch_*.json files - from height 0)
ZORO_ASSUMEVALID_BATCHES := 5 10 100 200 400

# Regenerate all client test data (light_*.json)
zoro-regenerate-client-tests:
	@echo "=== Regenerating zoro client test data ==="
	@for height in $(ZORO_CLIENT_HEIGHTS); do \
		echo "Generating light_$${height}.json (height=$${height}, blocks=1)..."; \
		python3 $(ZORO_DATA_SCRIPT) \
			--height $${height} \
			--num_blocks 1 \
			--output_file $(ZORO_CLIENT_DATA_DIR)/light_$${height}.json; \
	done
	@echo "=== Client test data regeneration complete ==="

# Regenerate all assumevalid test data (batch_*.json and blocks_*.json)
zoro-regenerate-assumevalid-tests:
	@echo "=== Regenerating zoro assumevalid test data ==="
	@# Generate batch files (from height 0)
	@for num in $(ZORO_ASSUMEVALID_BATCHES); do \
		echo "Generating batch_$${num}.json (height=0, blocks=$${num})..."; \
		python3 $(ZORO_DATA_SCRIPT) \
			--height 0 \
			--num_blocks $${num} \
			--output_file $(ZORO_ASSUMEVALID_DATA_DIR)/batch_$${num}.json; \
	done
	@# Generate blocks_0_1.json (height=0, 1 block)
	@echo "Generating blocks_0_1.json (height=0, blocks=1)..."
	@python3 $(ZORO_DATA_SCRIPT) \
		--height 0 \
		--num_blocks 1 \
		--output_file $(ZORO_ASSUMEVALID_DATA_DIR)/blocks_0_1.json
	@# Generate blocks_1_2.json (height=1, 1 block)
	@echo "Generating blocks_1_2.json (height=1, blocks=1)..."
	@python3 $(ZORO_DATA_SCRIPT) \
		--height 1 \
		--num_blocks 1 \
		--output_file $(ZORO_ASSUMEVALID_DATA_DIR)/blocks_1_2.json
	@echo "=== Assumevalid test data regeneration complete ==="

# Regenerate all zoro test data
zoro-regenerate-tests: zoro-regenerate-client-tests zoro-regenerate-assumevalid-tests
	@echo "=== All zoro test data regeneration complete ==="

# =============================================================================
# Zoro Bridge Node and Assumevalid Proving
# =============================================================================
# Run the bridge node indexer and generate proofs for Zcash blocks.
#
# Usage:
#   make run-zoro-bridge-indexer    # Start bridge node (run in separate terminal)
#   make run-zoro-assumevalid-prove # Generate proofs (requires indexer running)
#
# The indexer must be running before you can generate proofs.
# Default proves 2 blocks with step size 1 (good for local testing).
# =============================================================================

ZORO_BRIDGE_RPC_URL ?= https://rpc.mainnet.ztarknet.cash
ZORO_BRIDGE_URL ?= http://127.0.0.1:5000
ZORO_ASSUMEVALID_EXECUTABLE ?= crates/zoro-assumevalid/compiled/assumevalid.executable.json
ZORO_PROOF_OUTPUT_DIR ?= /tmp/proofs
ZORO_TOTAL_BLOCKS ?= 2
ZORO_STEP_SIZE ?= 1

# Start the bridge node indexer (run this first, in a separate terminal)
run-zoro-bridge-indexer:
	cd zoro && cargo run -p zoro-bridge-node --bin zoro-bridge-node -- \
		--zcash-rpc-url "$(ZORO_BRIDGE_RPC_URL)" \
		--log-level info

# Generate proofs for Zcash blocks (requires bridge indexer running)
run-zoro-assumevalid-prove:
	cd zoro && cargo run --release -p zoro-assumevalid --bin zoro-assumevalid -- \
		--bridge-url $(ZORO_BRIDGE_URL) \
		--log-level info \
		prove \
		--executable $(ZORO_ASSUMEVALID_EXECUTABLE) \
		--total-blocks $(ZORO_TOTAL_BLOCKS) \
		--step-size $(ZORO_STEP_SIZE) \
		--output-dir $(ZORO_PROOF_OUTPUT_DIR) \
		--keep-temp-files

scarb-build:
	@# Clear Scarb std cache to ensure corelib changes are picked up
	rm -rf ~/Library/Caches/com.swmansion.scarb/registry/std/
	rm -rf ~/.cache/scarb/registry/std/
	@# Force scarb to re-embed corelib by cleaning build artifacts and touching build.rs
	rm -rf scarb/target/debug/build/scarb-*
	touch scarb/scarb/build.rs
	cd scarb && cargo build -p scarb --no-default-features
	cd scarb && cargo clean -p scarb-execute && cargo build -p scarb-execute

scarb-build-release:
	@# Clear Scarb std cache to ensure corelib changes are picked up
	rm -rf ~/Library/Caches/com.swmansion.scarb/registry/std/
	rm -rf ~/.cache/scarb/registry/std/
	@# Force scarb to re-embed corelib by cleaning build artifacts and touching build.rs
	rm -rf scarb/target/release/build/scarb-*
	touch scarb/scarb/build.rs
	cd scarb && cargo build -p scarb --no-default-features --release
	cd scarb && cargo clean -p scarb-execute && cargo build -p scarb-execute --release

scarb-burn-build:
	cd scarb-burn && cargo build --release

# TODO: Get scarb tests working with the local scarb fork
scarb-test:
	cd scarb && cargo test --workspace --no-default-features --exclude scarb-prove --exclude scarb-verify

scarb-burn-test:
	cd scarb-burn && cargo test

proving-utils-build:
	cd proving-utils && cargo build --release

proving-utils-test:
	cd proving-utils && cargo test

# =============================================================================
# Flamegraph profiling (using scarb-burn)
# =============================================================================
# Generate flame charts for Cairo programs to visualize execution costs
#
# Usage:
#   make scarb-burn-build      # Build the scarb-burn tool (one-time)
#   make zoro-flamegraph       # Generate flamegraph for light_100 test
#   make zoro-flamegraph-build # Build client without syscalls for profiling
#
# Note: Must build client with --no-default-features to disable syscalls,
# as syscalls require gas which is disabled in the zoro workspace.
# =============================================================================

SCARB_BURN := ./scarb-burn/target/release/scarb-burn
ZORO_CLIENT_DIR := zoro/packages/client
ZORO_ARGS_SCRIPT := zoro/scripts/data/format_args.py

# Build zoro client without syscalls feature (required for profiling)
zoro-flamegraph-build:
	cd $(ZORO_CLIENT_DIR) && ../../../$(SCARB) build --no-default-features

# Generate flamegraph for light_100 integration test
zoro-flamegraph: zoro-flamegraph-build
	@mkdir -p $(BUILD_DIR)
	python3 $(ZORO_ARGS_SCRIPT) \
		--input_file $(ZORO_CLIENT_DIR)/tests/data/light_100.json \
		> $(BUILD_DIR)/zoro_arguments.json
	cd $(ZORO_CLIENT_DIR) && \
		PATH="../../../scarb/target/release:$$PATH" \
		SCARB_TARGET_DIR="$$(pwd)/../../target" \
		SCARB_PROFILE="dev" \
		../../../$(SCARB_BURN) \
		--no-build \
		--arguments-file ../../../$(BUILD_DIR)/zoro_arguments.json \
		--output-file ../../../$(BUILD_DIR)/zoro_flamegraph.svg \
		--open-in-browser
	@echo "Flamegraph written to $(BUILD_DIR)/zoro_flamegraph.svg"

# Generate flamegraph for light_100 with blake2b feature enabled
zoro-flamegraph-blake2b:
	@mkdir -p $(BUILD_DIR)
	python3 $(ZORO_ARGS_SCRIPT) \
		--input_file $(ZORO_CLIENT_DIR)/tests/data/light_100.json \
		> $(BUILD_DIR)/zoro_arguments.json
	cd $(ZORO_CLIENT_DIR) && \
		PATH="../../../scarb/target/release:$$PATH" \
		SCARB_TARGET_DIR="$$(pwd)/../../target" \
		SCARB_PROFILE="dev" \
		../../../$(SCARB_BURN) \
		--no-default-features \
		--features blake2b \
		--arguments-file ../../../$(BUILD_DIR)/zoro_arguments.json \
		--output-file ../../../$(BUILD_DIR)/zoro_flamegraph_blake2b.svg \
		--open-in-browser
	@echo "Flamegraph written to $(BUILD_DIR)/zoro_flamegraph_blake2b.svg"

zoro-flamegraph-blake2b-mock:
	@mkdir -p $(BUILD_DIR)
	python3 $(ZORO_ARGS_SCRIPT) \
		--input_file $(ZORO_CLIENT_DIR)/tests/data/light_100.json \
		> $(BUILD_DIR)/zoro_arguments.json
	cd $(ZORO_CLIENT_DIR) && \
		PATH="../../../scarb/target/release:$$PATH" \
		SCARB_TARGET_DIR="$$(pwd)/../../target" \
		SCARB_PROFILE="dev" \
		../../../$(SCARB_BURN) \
		--no-default-features \
		--features blake2b_mock \
		--arguments-file ../../../$(BUILD_DIR)/zoro_arguments.json \
		--output-file ../../../$(BUILD_DIR)/zoro_flamegraph_blake2b_mock.svg \
		--open-in-browser
	@echo "Flamegraph written to $(BUILD_DIR)/zoro_flamegraph_blake2b_mock.svg"

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
	cd scarb-burn && cargo clean
	cd stwo-cairo/stwo_cairo_prover && cargo clean
	cd stwo-air-infra && cargo clean
	cd proving-utils && cargo clean
	cd zoro && cargo clean

# Clean scarb build directories
clean-scarb:
	rm -rf tests/target
	rm -rf zoro/target

# Clean everything
clean: clean-tests clean-cargo clean-scarb
	@echo "Cleaned all build artifacts"
