use core::blake::{Blake2bParamsTrait, Blake2bHasherTrait};

/// Zcash Equihash Blake2b test with mainnet configuration
///
/// Zcash Equihash uses Blake2b with specific parameters:
/// - Personalization: "ZcashPoW" + n (u32 LE) + k (u32 LE)
/// - For mainnet: n=200, k=9
/// - Output length: 50 bytes
///
/// Personalization bytes (16): [0x5a, 0x63, 0x61, 0x73, 0x68, 0x50, 0x6f, 0x57,
///                              0xc8, 0x00, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00]
/// This matches the BLAKE2B_PERSONALIZATION constant in parity-zcash:
/// https://github.com/paritytech/parity-zcash/blob/master/verification/src/equihash.rs
///
/// Expected hash verified against Python hashlib.blake2b (RFC 7693 reference implementation,
/// same as used by zcash/zcash C++ implementation).

#[executable]
fn main() -> Array<u8> {
    // Build Zcash mainnet Equihash personalization: "ZcashPoW" + 200_u32_le + 9_u32_le
    let mut personal: ByteArray = "ZcashPoW";
    // Append 200 as u32 little-endian (n parameter)
    personal.append_byte(200);
    personal.append_byte(0);
    personal.append_byte(0);
    personal.append_byte(0);
    // Append 9 as u32 little-endian (k parameter)
    personal.append_byte(9);
    personal.append_byte(0);
    personal.append_byte(0);
    personal.append_byte(0);

    // Test input
    let input: ByteArray = "Zcash";

    // Hash with Zcash Equihash configuration (50-byte output)
    let mut hasher = Blake2bParamsTrait::new()
        .hash_length(50)
        .personal(@personal)
        .update(@input);
    let result: Array<u8> = hasher.finalize();

    // Expected hash from Python reference:
    // hashlib.blake2b(b'Zcash', digest_size=50, person=b'ZcashPoW\xc8\x00\x00\x00\x09\x00\x00\x00')
    let expected: Array<u8> = array![
        19, 201, 218, 118, 173, 199, 152, 145, 181, 21,
        14, 63, 12, 78, 6, 147, 49, 113, 61, 27,
        49, 220, 64, 62, 111, 170, 249, 3, 44, 7,
        209, 180, 160, 29, 79, 202, 241, 92, 3, 36,
        44, 79, 111, 69, 203, 67, 69, 253, 125, 126
    ];

    // Verify the hash matches expected value
    assert!(result == expected, "Zcash Equihash Blake2b hash mismatch");

    result
}
