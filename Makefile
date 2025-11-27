.PHONY: test-build test-execute stwo-air-infra-build stwo-air-infra-test stwo-cairo-build stwo-cairo-test cairo-build cairo-test cairo-vm-build cairo-vm-deps cairo-vm-test zoro-build zoro-test

test-build:
	cd tests && scarb build

test-execute:
	cd tests && scarb execute --print-program-output

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
