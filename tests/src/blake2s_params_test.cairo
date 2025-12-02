use core::blake::{Blake2sParamsTrait, Blake2sHasherTrait};

#[executable]
fn main() -> Array<u8> {
    // Demonstrate the fluent Blake2s API with keyed hashing and personalization
    //
    // Features used:
    // - Keyed hashing (MAC mode) with a secret key
    // - Personalization for domain separation
    // - Fluent chaining API

    let key: ByteArray = "my_secret_key_32";
    let personal: ByteArray = "myapp_v1";
    let message: ByteArray = "Hello, Blake2s with params!";

    // Fluent API: chain params -> update -> finalize
    let mut hasher = Blake2sParamsTrait::new()
        .key(@key)
        .personal(@personal)
        .update(@message);

    hasher.finalize()
}
