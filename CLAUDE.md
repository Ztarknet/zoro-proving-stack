# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Zoro** is a ZK client for Zcash implemented in Cairo (inspired by Raito for Bitcoin). It produces STARK proofs for Zcash consensus validity using the Stwo prover with Circle STARKs.

The repository is a monorepo containing multiple interconnected projects, all used together to build and prove Zcash validation logic.

## Repository Structure

```
zoro/
├── zoro/           # Main Zoro project (Cairo packages for Zcash validation)
├── cairo/          # Cairo compiler (Rust)
├── cairo-vm/       # Cairo VM implementation (Rust)
├── stwo-cairo/     # Stwo prover for Cairo programs
├── stwo-air-infra/ # AIR infrastructure for Stwo
└── tests/          # Integration tests (Cairo executable)
```

## Build Commands

### Main Zoro Project (Cairo)
```bash
cd zoro

# Build all packages
scarb build

# Build client for proving
scarb --profile release build --package client --target-kinds executable

# Run tests
scarb test

# Format Cairo code
scarb fmt
```

### Tests Directory
```bash
# Build test executable
make test-build

# Execute tests with output
make test-execute
```

### Installing Dependencies (from zoro/zoro/)
```bash
make install  # Installs all dependencies (bootloader-hints, stwo, cairo-execute, etc.)
```

## Cairo Packages (zoro/zoro/packages/)

- **client** - Standalone Cairo program implementing a Bitcoin client (light/full/utreexo modes)
- **consensus** - Bitcoin consensus validation primitives (types, validation, codec)
- **utreexo** - Hash-based accumulator for UTXO set compression (vanilla and stump flavors)
- **utils** - Common helpers not Bitcoin-specific
- **assumevalid** - Program for proving blocks trace back to genesis with sufficient confirmations

## Running the Client
```bash
cd zoro/zoro/packages/client
scarb run client START_HEIGHT END_HEIGHT BATCH_SIZE MODE STRATEGY
# MODE: light | full | utreexo
# STRATEGY: sequential | random
```

## Working with Subprojects

Each subproject has its own CLAUDE.md with detailed instructions:

### Cairo Compiler (cairo/)
- AST is auto-generated: read `crates/cairo-lang-syntax-codegen/src/generator.rs`, NOT `ast.rs`
- Format: `./scripts/rust_fmt.sh`
- Lint: `./scripts/clippy.sh`

### Cairo VM (cairo-vm/)
- Build: `cargo build --release`
- Test: `make test`
- Layouts: Use `all_cairo` for general purpose

### Stwo Prover (stwo-cairo/)
- Prove: `cairo-prove prove <executable.json> <output.json> --arguments <args>`
- Verify: `cairo-prove verify <proof.json>`
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
cd stwo-air-infra && cargo test blake2b
```

## Contribution Guidelines

- Branch naming: `feat/{issue#}-{name}`, `bug/{issue#}-{name}`, `dev/{issue#}-{name}`
- PR titles: `feat:`, `bug:`, `dev:`
- If adding TODOs: open issue and reference `TODO(#ISSUE_NUM):`
- Format with `scarb fmt` before submitting
