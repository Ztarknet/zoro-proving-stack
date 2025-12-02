use core::blake::{Blake2sParamsTrait, Blake2sHasherTrait};

#[executable]
fn main() -> [u32; 8] {
    // Demonstrate the fluent Blake2s API with keyed hashing and personalization
    //
    // Features used:
    // - Keyed hashing (MAC mode) with a secret key
    // - Personalization for domain separation
    // - Fluent chaining API
    // - Mixed update() and update_bytearray() calls

    // Key: "my_secret_key_32" (16 bytes) as little-endian u32 words
    let key: [u32; 8] = [0x735f796d, 0x65726365, 0x656b5f74, 0x32335f79, 0, 0, 0, 0];
    let key_length: u8 = 16;

    // Personal: "myapp_v1" (8 bytes) as little-endian u32 words
    let personal: [u32; 2] = [0x7061796d, 0x31765f70];

    // "Hello, " as Array<u8>
    let part1: Array<u8> = array![0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20];
    let part2: ByteArray = "Blake2s with params!";

    // Fluent API: chain params -> update (Array<u8>) -> update_bytearray
    let mut hasher = Blake2sParamsTrait::new()
        .key(key, key_length)
        .personal(personal)
        .update(part1);

    // Additional update using update_bytearray() for ByteArray
    hasher.update_bytearray(@part2);

    hasher.finalize().unbox()
}
