use core::blake::{Blake2bState, Blake2bInput, blake2b_compress, blake2b_finalize};
use core::box::BoxTrait;

#[executable]
fn main() -> [u64; 8] {
    // RFC 7693 test vector: hash "abc"
    let state = BoxTrait::new([
        0x6A09E667F3BCC908 ^ (0x01010000 ^ 0x40),
        0xBB67AE8584CAA73B,
        0x3C6EF372FE94F82B,
        0xA54FF53A5F1D36F1,
        0x510E527FADE682D1,
        0x9B05688C2B3E6C1F,
        0x1F83D9ABFB41BD6B,
        0x5BE0CD19137E2179,
    ]);

    let msg = BoxTrait::new([0x636261_u64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0]);

    blake2b_finalize(state, 3, msg).unbox()
}
