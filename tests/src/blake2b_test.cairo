use core::blake::{Blake2bState, Blake2bInput, blake2b_compress, blake2b_finalize};
use core::box::BoxTrait;

#[executable]
fn main() -> [u64; 8] {
    // RFC 7693 test vector: hash "abc"
    // First state word is IV[0] XOR parameter block:
    // 0x6A09E667F3BCC908 ^ 0x01010040 = 0x6A09E667F2BCD948
    // (parameter block: 0x01010040 = digest_length=64, key_length=0, fanout=1, depth=1)
    let state = BoxTrait::new([
        0x6A09E667F2BCD948_u64,  // IV[0] ^ 0x01010040
        0xBB67AE8584CAA73B_u64,
        0x3C6EF372FE94F82B_u64,
        0xA54FF53A5F1D36F1_u64,
        0x510E527FADE682D1_u64,
        0x9B05688C2B3E6C1F_u64,
        0x1F83D9ABFB41BD6B_u64,
        0x5BE0CD19137E2179_u64,
    ]);

    // "abc" = 0x636261 in little-endian
    let msg = BoxTrait::new([
        0x636261_u64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ]);

    blake2b_finalize(state, 3, msg).unbox()
}
