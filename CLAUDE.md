# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Zoro Proving Stack** is a development environment for building and proving Cairo programs with the Stwo prover. It bundles modified forks of the Cairo compiler, Cairo VM, and Stwo prover with coordinated changes for custom opcodes (like Blake2b).

Primary use case: Development of [Zoro](https://github.com/starkware-bitcoin/zoro), a ZK client for Zcash that produces STARK proofs for consensus validity using Circle STARKs.

## Repository Structure

```
zoro-proving-stack/
├── cairo/          # Cairo compiler (Rust) - Ztarknet fork
├── cairo-vm/       # Cairo VM implementation (Rust) - Ztarknet fork
├── scarb/          # Cairo package manager (Rust) - Ztarknet fork
├── scarb-burn/     # Scarb extension for flamegraphs & profiling
├── stwo-cairo/     # Stwo prover for Cairo programs - Ztarknet fork
├── stwo-air-infra/ # AIR infrastructure for Stwo (private, optional)
├── zoro/           # Zoro - Zcash ZK client in Cairo
└── tests/          # Integration tests (Cairo executable)
```

## Build Commands

### Root Makefile Targets

**Subproject Builds:**
```bash
make cairo-build          # Build Cairo compiler (requires rust +1.89)
make cairo-vm-build       # Build Cairo VM
make scarb-build          # Build Scarb package manager
make stwo-cairo-build     # Build Stwo Cairo prover
make stwo-air-infra-build # Build AIR infrastructure
make zoro-build           # Build main Zoro project (release)
```

**Testing:**
```bash
make test-build           # Build tests with scarb
make test-execute         # Run tests with scarb (print output)
make test-run-fib         # Compile and run fibonacci test
make test-run-blake2b     # Compile and run blake2b test
```

**Proving Pipeline:**
```bash
make cairo-prove-build    # Build cairo-prove CLI (one-time)
make test-prove-fib       # Generate STARK proof for fibonacci
make test-verify-fib      # Verify fibonacci proof
make test-full-fib        # Full pipeline: compile -> prove -> verify
make test-full-blake2b    # Full pipeline for blake2b
```

**Subproject Tests:**
```bash
make cairo-test           # Test Cairo compiler
make cairo-vm-test        # Test Cairo VM (requires: make cairo-vm-deps first)
make stwo-cairo-test      # Test Stwo Cairo prover
make stwo-air-infra-test  # Test AIR infrastructure
make zoro-test            # Test Zoro packages
```

### Zoro Submodule (Cairo)
```bash
cd zoro
scarb build               # Build all packages
scarb test                # Run tests
scarb fmt                 # Format Cairo code
```

## Zoro Cairo Packages (zoro/packages/)

- **client** - Standalone Cairo program implementing a Bitcoin client (light/full/utreexo modes)
- **consensus** - Bitcoin consensus validation primitives (types, validation, codec)
- **utreexo** - Hash-based accumulator for UTXO set compression (vanilla and stump flavors)
- **utils** - Common helpers not Bitcoin-specific
- **assumevalid** - Program for proving blocks trace back to genesis with sufficient confirmations

## Running the Client
```bash
cd zoro/packages/client
scarb run client START_HEIGHT END_HEIGHT BATCH_SIZE MODE STRATEGY
# MODE: light | full | utreexo
# STRATEGY: sequential | random
```

## Working with Subprojects

Each subproject has its own CLAUDE.md. Use root Makefile targets for builds (see above).

### Cairo Compiler (cairo/)
- AST is auto-generated: read `crates/cairo-lang-syntax-codegen/src/generator.rs`, NOT `ast.rs`
- Format: `./scripts/rust_fmt.sh` | Lint: `./scripts/clippy.sh`

### Cairo VM (cairo-vm/)
- Layouts: Use `all_cairo` for general purpose
- Run `make cairo-vm-deps` before `make cairo-vm-test`

### Scarb (scarb/)
- Cairo package manager fork with Blake2b support
- Build: `make scarb-build` or `make scarb-build-release`

### Scarb Burn (scarb-burn/)
- Flamegraph and pprof profiling for Cairo programs
- Usage: `scarb burn --arguments-file args.json --output-file flamegraph.svg`
- Requires `[lib]` target and `#[executable]` entrypoint

### Stwo Prover (stwo-cairo/)
- Cairo programs must have `enable-gas = false`

## Architecture

The proving pipeline:
1. **Cairo Source** - Validation logic written in Cairo
2. **Scarb Build** - Compiles to executable JSON
3. **Cairo VM** - Executes the program and generates traces
4. **Stwo Prover** - Generates STARK proof from execution trace
5. **Verifier** - Verifies proof (Rust native or Cairo on-chain)

## Blake2b Implementation (Current Focus)

Implementing Blake2b opcode for Zcash Equihash PoW verification.

### Key Files

| Component | Location |
|-----------|----------|
| Blake2b AIR | `stwo-air-infra/crates/air_infra/src/airs/casm/opcodes/blake2b/` |
| Blake2s AIR (reference) | `stwo-cairo/stwo_cairo_prover/crates/cairo-air/src/components/blake_*.rs` |
| Blake2s VM hints | `cairo-vm/vm/src/hint_processor/builtin_hint_processor/blake2s_*.rs` |
| Blake Sierra ext | `cairo/crates/cairo-lang-sierra/src/extensions/modules/blake.rs` |

### Blake2s vs Blake2b

| | Blake2s | Blake2b |
|---|---------|---------|
| Word size | 32-bit | 64-bit |
| Rounds | 10 | 12 |
| Rotations | 16,12,8,7 | 32,24,16,63 |
| Output | 256-bit | 512-bit (400-bit for Equihash) |

### Testing Blake2b
```bash
make test-run-blake2b       # Run blake2b test
make test-full-blake2b      # Full prove/verify pipeline
make stwo-air-infra-test    # AIR tests (includes blake2b)
```

## Contribution Guidelines

- Branch naming: `feat/{issue#}-{name}`, `bug/{issue#}-{name}`, `dev/{issue#}-{name}`
- PR titles: `feat:`, `bug:`, `dev:`
- If adding TODOs: open issue and reference `TODO(#ISSUE_NUM):`
- Format with `scarb fmt` before submitting
