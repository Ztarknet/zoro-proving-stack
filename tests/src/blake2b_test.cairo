use core::blake::{Blake2bState, Blake2bInput, blake2b_compress, blake2b_finalize};
use core::box::BoxTrait;

#[executable]
fn main() -> [u32; 8] {
    // RFC 7693 test vector: hash "abc"
    // Initial state is the IV, with keylen 0 and output length 32.
    let state = BoxTrait::new([
        0x6A09E667 ^ (0x01010000 ^ 0x20),
        0xBB67AE85,
        0x3C6EF372,
        0xA54FF53A,
        0x510E527F,
        0x9B05688C,
        0x1F83D9AB,
        0x5BE0CD19,
    ]);

    // Message "abc" (little-endian: 'cba' = 0x636261) padded with zeros
    let msg = BoxTrait::new(['cba', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);

    blake2b_finalize(state, 3, msg).unbox()
}
