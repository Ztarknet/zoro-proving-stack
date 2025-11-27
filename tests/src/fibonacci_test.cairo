#[executable]
fn main() -> felt252 {
    // Compute the 10th Fibonacci number
    // F(0) = 0, F(1) = 1, F(10) = 55
    fib(0, 1, 10)
}

fn fib(a: felt252, b: felt252, n: felt252) -> felt252 {
    match n {
        0 => a,
        _ => fib(b, a + b, n - 1),
    }
}
