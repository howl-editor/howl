// Copyright 2025 The Howl Developers
// Example Rust code for Howl Editor

/*
  This is a multi-line comment.
*/

// Basic function definition
fn greet(name: &str) {
    println!("Hello, {}!", name); // Print a greeting
}

// Struct definition
struct Point {
    x: f64,
    y: f64,
}

// Implementation block for the Point struct
impl Point {
    // Associated function (static method)
    fn origin() -> Point {
        Point { x: 0.0, y: 0.0 }
    }

    // Method
    fn distance_from_origin(&self) -> f64 {
        (self.x.powi(2) + self.y.powi(2)).sqrt()
    }
}

// Enum definition
enum Color {
    Red,
    Green,
    Blue,
    Rgb(u8, u8, u8), // Tuple variant
}

// Trait definition (like an interface)
trait Summary {
    fn summarize(&self) -> String;
}

// Implement the Summary trait for Point
impl Summary for Point {
    fn summarize(&self) -> String {
        format!("Point({}, {})", self.x, self.y)
    }
}

// Generic function
fn print_summary<T: Summary>(item: &T) {
    println!("{}", item.summarize());
}

// Macro usage
macro_rules! create_function {
    ($func_name:ident) => {
        fn $func_name() {
            println!("You called {:?}()", stringify!($func_name));
        }
    };
}

// Create a function using the macro
create_function!(foo);

fn main() {
    // Variable binding and type inference
    let message = "World";
    greet(message);

    // Mutable variable
    let mut count = 0;
    count += 1;
    println!("Count: {}", count);

    // Integer and float types
    let integer: i32 = 42;
    let float: f32 = 3.14;
    println!("Integer: {}, Float: {}", integer, float);

    // Boolean type
    let is_active: bool = true;
    println!("Is active: {}", is_active);

    // Character type
    let character: char = '🦀';
    println!("Character: {}", character);

    // Tuple
    let tup: (i32, f64, u8) = (500, 6.4, 1);
    let (x, _y, _z) = tup; // Destructuring, ignoring some values
    println!("The first value is: {}", x);
    println!("The second value is: {}", tup.1); // Access by index

    // Array (fixed size)
    let a: [i32; 5] = [1, 2, 3, 4, 5];
    println!("First element of array: {}", a[0]);

    // String literals and String type
    let s1: &str = "literal"; // String slice (borrowed)
    let s2: String = String::from("heap allocated"); // Owned String
    println!("Slices: {}, {}", s1, s2);

    // Control flow: if/else
    if integer > 50 {
        println!("Integer is large");
    } else {
        println!("Integer is not large");
    }

    // Control flow: loop
    let mut counter = 0;
    let result = loop {
        counter += 1;
        if counter == 10 {
            break counter * 2; // Exit loop and return a value
        }
    };
    println!("Loop result: {}", result);

    // Control flow: while
    let mut number = 3;
    while number != 0 {
        println!("{}!", number);
        number -= 1;
    }
    println!("LIFTOFF!!!");

    // Control flow: for (iterating over a collection)
    for element in a.iter() {
        println!("The value is: {}", element);
    }

    // Control flow: for (range)
    for num in 1..4 { // 1, 2, 3
        println!("{}!", num);
    }

    // Using the struct
    let p1 = Point { x: 3.0, y: 4.0 };
    let p2 = Point::origin();
    println!("Distance p1 from origin: {}", p1.distance_from_origin());
    println!("Distance p2 from origin: {}", p2.distance_from_origin());

    // Using the enum
    let c = Color::Rgb(255, 0, 0);
    match c {
        Color::Red => println!("The color is Red!"),
        Color::Green => println!("The color is Green!"),
        Color::Blue => println!("The color is Blue!"),
        Color::Rgb(r, g, b) => println!("RGB color: ({}, {}, {})", r, g, b),
    }

    // Using traits and generics
    print_summary(&p1);

    // Using the macro-generated function
    foo();

    // Example of a closure
    let add_one = |x: i32| -> i32 { x + 1 };
    println!("Closure result: {}", add_one(5));

    // Ownership and borrowing
    let s_own = String::from("hello");
    takes_ownership(s_own); // s_own's value moved into the function
    // println!("{}", s_own); // This would cause a compile-time error

    let x_own = 5;
    makes_copy(x_own); // x_own is copied, it's still valid here
    println!("x_own after copy: {}", x_own);

    let s_borrow = String::from("borrow me");
    let len = calculate_length(&s_borrow); // Pass a reference (borrow)
    println!("The length of '{}' is {}.", s_borrow, len); // s_borrow is still valid

    // Mutable borrow
    let mut s_mut = String::from("hello");
    change(&mut s_mut);
    println!("Mutated string: {}", s_mut);

    // Async example (requires tokio or async-std runtime)
    // Note: To run this, you need `tokio = { version = "1", features = ["full"] }` in Cargo.toml
    // And `#[tokio::main]` or similar attribute on main
    /*
    async fn async_task() {
        println!("Async task started");
        // Simulate async work
        tokio::time::sleep(std::time::Duration::from_secs(1)).await;
        println!("Async task finished");
    }
    // To run the async task:
    // tokio::spawn(async_task());
    */

    // Error handling with Result
    match might_fail(true) {
        Ok(value) => println!("Success: {}", value),
        Err(e) => println!("Error: {}", e),
    }

    match might_fail(false) {
        Ok(value) => println!("Success: {}", value),
        Err(e) => println!("Error: {}", e),
    }

    // Using the ? operator for cleaner error propagation
    match use_might_fail() {
        Ok(v) => println!("Propagated success: {}", v),
        Err(e) => println!("Propagated error: {}", e),
    }

    // Lifetimes (usually inferred by the compiler)
    let string1 = String::from("abcd");
    let result_lifetime;
    {
        let string2 = String::from("xyz");
        result_lifetime = longest(string1.as_str(), string2.as_str());
        println!("The longest string is {}", result_lifetime);
    }
    // println!("The longest string is {}", result_lifetime); // This would fail if lifetimes weren't handled

    // Static lifetime
    let static_str: &'static str = "I live forever";
    println!("Static string: {}", static_str);

    // Byte strings
    let byte_literal = b'A';
    let byte_string = b"this is a byte string";
    let raw_byte_string = br#"raw byte string with "quotes""#;
    println!("Bytes: {}, {:?}, {:?}", byte_literal, byte_string, raw_byte_string);

    // Numeric suffixes
    let num_suffix = 42u32;
    let float_suffix = 3.14f64;
    println!("Nums with suffix: {}, {}", num_suffix, float_suffix);

    // Compound operators
    let mut comp_val = 5;
    comp_val += 10; // 15
    comp_val -= 3;  // 12
    comp_val *= 2;  // 24
    comp_val /= 4;  // 6
    comp_val %= 5;  // 1
    println!("Compound op result: {}", comp_val);

    // Range operator
    for i in 0..=5 { // 0 through 5 inclusive
        print!("{} ", i);
    }
    println!();

    // Dyn trait
    let dynamic_point: Box<dyn Summary> = Box::new(Point { x: 1.0, y: 1.0 });
    print_summary(&*dynamic_point);

    // Union example (unsafe)
    let u = MyUnion { f1: 1 };
    let _value = unsafe { u.f1 };
    println!("Union value accessed (unsafe)");

    // Async/Await example (conceptual, needs runtime)
    // Requires `tokio = { version = "1", features = ["full"] }` in Cargo.toml
    /*
    use tokio::time::{sleep, Duration};

    async fn my_async_function() -> i32 {
        println!("Async function started");
        sleep(Duration::from_secs(1)).await;
        println!("Async function finished");
        42
    }

    #[tokio::main]
    async fn run_async() {
        let result = my_async_function().await;
        println!("Async result: {}", result);
    }
    // run_async(); // Call this to execute
    */
    println!("End of main");
}

// Function that takes ownership
fn takes_ownership(some_string: String) {
    println!("{}", some_string);
} // Here, some_string goes out of scope and `drop` is called.

// Function that makes a copy (for types that implement Copy trait)
fn makes_copy(some_integer: i32) {
    println!("{}", some_integer);
} // Here, some_integer goes out of scope. Nothing special happens.

// Function that borrows a string
fn calculate_length(s: &String) -> usize { // s is a reference to a String
    s.len()
} // Here, s goes out of scope. But because it does not have ownership, nothing happens.

// Function that takes a mutable reference
fn change(some_string: &mut String) {
    some_string.push_str(", world");
}

// Function that returns a Result
fn might_fail(success: bool) -> Result<String, String> {
    if success {
        Ok(String::from("Operation succeeded"))
    } else {
        Err(String::from("Operation failed"))
    }
}

// Function demonstrating the ? operator
fn use_might_fail() -> Result<String, String> {
    let result = might_fail(true)?; // If Err, returns Err from this function
    println!("Intermediate result: {}", result); // Only runs if might_fail was Ok
    Ok(String::from("Final success"))
}


// Function demonstrating lifetimes
// '<'a> defines a lifetime parameter
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

// Union definition (requires unsafe block to access)
union MyUnion {
    f1: u32,
    f2: f32,
}
