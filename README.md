# Zoro Proving Stack

A development environment for building and proving Cairo programs with the Stwo prover. This stack bundles modified forks of the Cairo compiler, Cairo VM, and Stwo prover with coordinated changes for custom opcodes (like Blake2b).

Primary use case: Development of [Zoro](https://github.com/starkware-bitcoin/zoro), a ZK client for Zcash that produces STARK proofs for consensus validity.

## Repository Structure

```
zoro-proving-stack/
├── cairo/          # Cairo compiler (Ztarknet fork)
├── cairo-vm/       # Cairo VM implementation (Ztarknet fork)
├── scarb/          # Scarb - Cairo package manager (Ztarknet fork)
├── scarb-burn/     # Scarb extension for flamegraphs & profiling
├── stwo-cairo/     # Stwo prover for Cairo programs (Ztarknet fork)
├── stwo-air-infra/ # AIR infrastructure (private, optional)
├── zoro/           # Zoro - Zcash ZK client in Cairo
├── tests/          # Integration tests
└── scripts/        # Utility scripts
```

## Quick Start

### Prerequisites

- Git
- Rust 1.89+ (`rustup install 1.89`)

### Setup

```bash
# Clone with submodules
git clone --recursive https://github.com/Ztarknet/zoro-proving-stack.git
cd zoro-proving-stack

# Or if already cloned:
./setup.sh
```

The setup script will:
1. Initialize all git submodules
2. Create the `corelib` symlink
3. Optionally configure `stwo-air-infra` (private repo)

### Build

```bash
# Build all components
make cairo-build          # Cairo compiler
make cairo-vm-build       # Cairo VM
make stwo-cairo-build     # Stwo prover
make stwo-air-infra-build # AIR infrastructure (if available)
```

### Run Tests

```bash
# Component specific tests
make cairo-test          # Cairo compiler
make cairo-vm-test       # Cairo VM
make stwo-cairo-test     # Stwo prover
make stwo-air-infra-test # AIR infrastructure (if available)

# Full proving pipeline
make test-full-fib        # Fibonacci: compile -> prove -> verify
make test-full-blake2s    # Blake2s: compile -> prove -> verify
make test-full-blake2b    # Blake2b: compile -> prove -> verify
```

## Proving Zcash Blocks

The primary workflow for Zoro is generating STARK proofs for Zcash block validation. This uses the `assumevalid` package to prove that blocks trace back to genesis with sufficient confirmations.

### 1. Start the Bridge Node

The bridge node indexes Zcash blocks and serves them to the prover. Run this in a separate terminal:

```bash
make run-zoro-bridge-indexer
```

This connects to the Zcash RPC at `https://rpc.mainnet.ztarknet.cash` by default.

### 2. Generate Proofs

Once the indexer is running, generate proofs in another terminal:

```bash
make run-zoro-assumevalid-prove
```

By default this proves 2 blocks with step size 1 (good for local testing). Customize with:

```bash
# Prove 10 blocks, 5 blocks per proof
make run-zoro-assumevalid-prove ZORO_TOTAL_BLOCKS=10 ZORO_STEP_SIZE=5
```

### 3. Verify Proofs

Given a running indexer and a generated proof you can verify it via CLI tool.

First, install it locally:

```bash
make zoro-install-cli
```

Then follow the [instructions](./zoro/crates/zoro-spv-verify/).

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `ZORO_BRIDGE_RPC_URL` | `https://rpc.mainnet.ztarknet.cash` | Zcash RPC endpoint |
| `ZORO_BRIDGE_URL` | `http://127.0.0.1:5000` | Local bridge node URL |
| `ZORO_TOTAL_BLOCKS` | `2` | Total number of blocks to prove |
| `ZORO_STEP_SIZE` | `1` | Number of blocks per proof |
| `ZORO_PROOF_OUTPUT_DIR` | `/tmp/proofs` | Directory for generated proofs |

## Architecture

The proving pipeline:

```
Cairo Source -> Cairo Build -> Cairo VM -> Stwo Prover -> Stwo Verifier
     |              |            |            |                |
  Program     Executable     Execution     Generate          Verify
   Logic         JSON          Trace        Proof            Proof
```

## Submodules

| Submodule | Branch | Description |
|-----------|--------|-------------|
| `cairo` | `blake2b` | Cairo compiler with Blake2b support |
| `cairo-vm` | `blake2b` | Cairo VM with Blake2b hints |
| `scarb` | `blake2b` | Cairo package manager (Scarb) |
| `scarb-burn` | `main` | Flamegraph & pprof profiling for Cairo |
| `stwo-cairo` | `blake2b` | Stwo prover integration |
| `zoro` | `main` | Zcash validation logic in Cairo |

### stwo-air-infra (Private)

`stwo-air-infra` contains AIR (Algebraic Intermediate Representation) infrastructure and is hosted in a separate private repository. It's required for the stwo-cairo air generation, but is optional for basic development.

**Branch:** `brandon/blake2b`

**Setup options:**

1. **If you have access:** The setup script will prompt to clone it
2. **Use existing clone:** Set `STWO_AIR_INFRA_PATH` environment variable
3. **Skip:** Custom airs will not be generatable

## Development

### Updating Submodules

```bash
# Update all submodules to latest commits on their branches
git submodule update --remote

# Update a specific submodule
git submodule update --remote cairo
```

### Working on a Submodule

```bash
cd cairo
git checkout -b my-feature
# make changes
git commit -m "feat: my feature"
git push origin my-feature
```

### Running Benchmarks

```bash
./scripts/benchmark.sh
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| **Zoro Proving** | |
| `make run-zoro-bridge-indexer` | Start the Zcash bridge node indexer |
| `make run-zoro-assumevalid-prove` | Generate proofs for Zcash blocks |
| **Build** | |
| `make cairo-build` | Build Cairo compiler |
| `make cairo-vm-build` | Build Cairo VM |
| `make scarb-build` | Build Scarb package manager |
| `make stwo-cairo-build` | Build Stwo prover |
| `make stwo-air-infra-build` | Build AIR infrastructure |
| **Test** | |
| `make test-build` | Build test programs |
| `make test-execute` | Run test programs |
| `make test-full-fib` | Full pipeline for fibonacci |
| `make test-full-blake2s` | Full pipeline for blake2s |
| `make test-full-blake2b` | Full pipeline for blake2b |
| `make cairo-test` | Run Cairo compiler tests |
| `make cairo-vm-test` | Run Cairo VM tests |

## License

MIT - see [LICENSE](LICENSE)
