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
/// Expected state verified against Python hashlib.blake2b (RFC 7693 reference implementation,
/// same as used by zcash/zcash C++ implementation).
/// Python: hashlib.blake2b(b'Zcash', digest_size=50, person=b'ZcashPoW\xc8\x00\x00\x00\x09\x00\x00\x00')

#[executable]
fn main() -> [u64; 8] {
    // Zcash mainnet Equihash personalization: "ZcashPoW" + 200_u32_le + 9_u32_le
    // As little-endian u64 words:
    // word0: "ZcashPoW" = 0x576f50687361635a
    // word1: 200_u32_le + 9_u32_le = 0x00000009000000c8
    let personal: [u64; 2] = [0x576f50687361635a, 0x00000009000000c8];

    // Test input
    let input: ByteArray = "Zcash";

    // Hash with Zcash Equihash configuration (50-byte output)
    let mut hasher = Blake2bParamsTrait::new()
        .hash_length(50)
        .personal(personal)
        .update_bytearray(@input);

    let result = hasher.finalize().unbox();

    // Expected hash from Python reference (first 50 bytes as little-endian u64 words):
    // hashlib.blake2b(b'Zcash', digest_size=50, person=b'ZcashPoW\xc8\x00\x00\x00\x09\x00\x00\x00')
    // Hex: 13c9da76adc79891b5150e3f0c4e0693317131b31dc403e6faaf9032c07d1b4a01d4fcaf15c0324...
    //
    // Original expected bytes (50):
    // [19, 201, 218, 118, 173, 199, 152, 145, 181, 21,
    //  14, 63, 12, 78, 6, 147, 49, 113, 61, 27,
    //  49, 220, 64, 62, 111, 170, 249, 3, 44, 7,
    //  209, 180, 160, 29, 79, 202, 241, 92, 3, 36,
    //  44, 79, 111, 69, 203, 67, 69, 253, 125, 126]
    //
    // As little-endian u64 words (only first 50 bytes are meaningful for hash_length=50):
    // Word 0: bytes[0..8]   = 0x9198c7ad76dac913
    // Word 1: bytes[8..16]  = 0x93064e0c3f0e15b5
    // Word 2: bytes[16..24] = 0x3e40dc311b3d7131
    // Word 3: bytes[24..32] = 0xb4d1072c03f9aa6f
    // Word 4: bytes[32..40] = 0x24035cf1ca4f1da0
    // Word 5: bytes[40..48] = 0xfd4543cb456f4f2c
    // Word 6: bytes[48..50] = 0x____________7e7d (only low 16 bits meaningful)

    // Destructure to verify individual words
    let [w0, w1, w2, w3, w4, w5, w6, _w7] = result;

    // Verify the first 6 complete words
    assert!(w0 == 0x9198c7ad76dac913, "Word 0 mismatch");
    assert!(w1 == 0x93064e0c3f0e15b5, "Word 1 mismatch");
    assert!(w2 == 0x3e40dc311b3d7131, "Word 2 mismatch");
    assert!(w3 == 0xb4d1072c03f9aa6f, "Word 3 mismatch");
    assert!(w4 == 0x24035cf1ca4f1da0, "Word 4 mismatch");
    assert!(w5 == 0xfd4543cb456f4f2c, "Word 5 mismatch");

    // Verify low 16 bits of word 6 (bytes 48-49)
    assert!(w6 & 0xFFFF == 0x7e7d, "Word 6 low bytes mismatch");

    result
}
