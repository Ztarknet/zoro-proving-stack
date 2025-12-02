use core::blake::{Blake2bParamsTrait, Blake2bHasherTrait};

#[executable]
fn main() -> Array<u8> {
    // Demonstrate the fluent Blake2b API with custom hash length and incremental updates
    //
    // Features used:
    // - Custom hash length (40 bytes instead of default 64)
    // - Personalization for domain separation
    // - Incremental/streaming hashing with multiple updates
    // - Fluent chaining API

    let personal: ByteArray = "test_app________";  // 16 bytes for Blake2b
    let chunk1: ByteArray = "First chunk of data. ";
    let chunk2: ByteArray = "Second chunk of data.";

    // Fluent API with incremental updates
    let mut hasher = Blake2bParamsTrait::new()
        .hash_length(40)
        .personal(@personal)
        .update(@chunk1);

    // Additional update
    hasher.update(@chunk2);

    hasher.finalize()
}
