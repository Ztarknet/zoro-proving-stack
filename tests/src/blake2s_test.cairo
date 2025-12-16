use core::blake::blake2s_finalize;
use core::box::BoxTrait;

#[executable]
fn main() -> [u32; 8] {
    // RFC 7693 test vector: hash "abc"
    // Initial state is the IV, with parameter block XORed into h[0].
    // Parameter block (first 4 bytes): digest_length=32 (0x20), key_length=0, fanout=1, depth=1
    // h[0] = IV[0] ^ param_block = 0x6A09E667 ^ 0x01010020 = 0x6B08E647
    let state = BoxTrait::new([
        0x6B08E647,
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

    blake2s_finalize(state, 3, msg).unbox()
}
