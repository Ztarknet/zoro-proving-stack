use core::blake::{Blake2bState, Blake2bInput, blake2b_finalize};
use core::box::BoxTrait;

#[executable]
fn main() -> [u64; 8] {
    // RFC 7693 test vector: blake2b("abc") with 64-byte output
    //
    // Blake2b IV constants (64-bit):
    //   IV[0] = 0x6a09e667f3bcc908
    //   IV[1] = 0xbb67ae8584caa73b
    //   IV[2] = 0x3c6ef372fe94f82b
    //   IV[3] = 0xa54ff53a5f1d36f1
    //   IV[4] = 0x510e527fade682d1
    //   IV[5] = 0x9b05688c2b3e6c1f
    //   IV[6] = 0x1f83d9abfb41bd6b
    //   IV[7] = 0x5be0cd19137e2179
    //
    // Parameter block (little-endian, first 8 bytes):
    //   byte 0: digest_length = 64 (0x40)
    //   byte 1: key_length = 0
    //   byte 2: fanout = 1
    //   byte 3: depth = 1
    //   bytes 4-7: leaf_length = 0
    // So first 64-bit word of param block = 0x0000000001010040
    //
    // Initial state: h[0] = IV[0] ^ param_block[0], rest unchanged
    // h[0] = 0x6a09e667f3bcc908 ^ 0x0000000001010040 = 0x6a09e667f2bdc948
    let state: Blake2bState = BoxTrait::new([
        0x6a09e667f2bdc948, // IV[0] ^ param_block (digest_len=64, key_len=0, fanout=1, depth=1)
        0xbb67ae8584caa73b,
        0x3c6ef372fe94f82b,
        0xa54ff53a5f1d36f1,
        0x510e527fade682d1,
        0x9b05688c2b3e6c1f,
        0x1f83d9abfb41bd6b,
        0x5be0cd19137e2179,
    ]);

    // Message "abc" in little-endian 64-bit word:
    // 'a' = 0x61, 'b' = 0x62, 'c' = 0x63
    // Packed little-endian: 0x0000000000636261
    // Remaining 15 words are zero-padded
    let msg: Blake2bInput = BoxTrait::new([
        0x0000000000636261, // "abc" in little-endian
        0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
    ]);

    // byte_count = 3 (length of "abc")
    let result = blake2b_finalize(state, 3, msg);

    // Expected output for blake2b("abc", 64):
    // ba80a53f981c4d0d 6a2797b69f12f6e9 4c212f14685ac4b7 4b12bb6fdbffa2d1
    // 7d87c5392aab792d c252d5de4533cc95 18d38aa8dbf1925a b92386edd4009923
    //
    // As little-endian u64 words:
    //   [0] = 0x0d4d1c983fa580ba
    //   [1] = 0xe9f6129fb697276a
    //   [2] = 0xb7c45a68142f214c
    //   [3] = 0xd1a2fffdb62bb14b
    //   [4] = 0x2d79ab2a39c5877d
    //   [5] = 0x95cc3345ded552c2
    //   [6] = 0x5a92f1dba88ad318
    //   [7] = 0x239900d4ed8623b9

    result.unbox()
}
