use core::blake::{Blake2bParamsTrait, Blake2bHasherTrait};

#[executable]
fn main() -> [u64; 8] {
    // Demonstrate the fluent Blake2b API with custom hash length and incremental updates
    //
    // Features used:
    // - Custom hash length (40 bytes instead of default 64)
    // - Personalization for domain separation
    // - Incremental/streaming hashing with multiple updates
    // - Fluent chaining API
    // - Mixed update() and update_bytearray() calls

    // Personal: "test_app________" (16 bytes) as little-endian u64 words
    let personal: [u64; 2] = [0x7070615f74736574, 0x5f5f5f5f5f5f5f5f];

    // "First chunk of data. " as Array<u8>
    let chunk1: Array<u8> = array![
        0x46, 0x69, 0x72, 0x73, 0x74, 0x20, 0x63, 0x68, 0x75, 0x6e, 0x6b,
        0x20, 0x6f, 0x66, 0x20, 0x64, 0x61, 0x74, 0x61, 0x2e, 0x20
    ];
    let chunk2: ByteArray = "Second chunk of data.";

    // Fluent API with incremental updates using update() for Array<u8>
    let mut hasher = Blake2bParamsTrait::new()
        .hash_length(40)
        .personal(personal)
        .update(chunk1);

    // Additional update using update_bytearray() for ByteArray
    hasher.update_bytearray(@chunk2);

    hasher.finalize().unbox()
}
