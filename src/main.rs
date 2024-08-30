#![no_main]
#![no_std]

use core::sync::atomic::{AtomicU32, Ordering};

#[used]
#[no_mangle]
#[link_section = ".entry_point"]
pub static ENTRY_POINT: extern "C" fn(&'static Api) -> i32 = entry_point;

#[no_mangle]
#[used]
static mut API: Option<&'static Api> = None;

static PRINT_COUNTER: AtomicU32 = AtomicU32::new(0);

pub trait Printable {
    fn print(&self, number: u32);
    fn sides(&self) -> u32;
}

#[allow(dead_code)]
pub struct Square {
    width: i32,
}

impl Printable for Square {
    #[inline(never)]
    fn print(&self, number: u32) {
        let api = unsafe { API.unwrap() };
        (api.puts)("Square".as_ptr(), number as usize);
        PRINT_COUNTER.store(PRINT_COUNTER.load(Ordering::Relaxed) + 1, Ordering::Relaxed);
    }

    fn sides(&self) -> u32 {
        4
    }
}

#[allow(dead_code)]
pub struct Circle {
    radius: i32,
}

impl Printable for Circle {
    #[inline(never)]
    fn print(&self, number: u32) {
        let api = unsafe { API.unwrap() };
        (api.puts)("Circle".as_ptr(), number as usize);
        PRINT_COUNTER.store(PRINT_COUNTER.load(Ordering::Relaxed) + 1, Ordering::Relaxed);
    }

    fn sides(&self) -> u32 {
        0xFFFFFFFF
    }
}

#[inline(never)]
pub fn print(item: &dyn Printable) {
    let x = item.sides();
    item.print(x)
}

#[repr(C)]
pub struct Api {
    puts: fn(data: *const u8, len: usize) -> i32,
}

#[no_mangle]
extern "C" fn entry_point(api: &'static Api) -> i32 {
    unsafe {
        API = Some(api);
    }
    let message = "Hello, world!\n";
    let x = testlib::test() as usize;
    (api.puts)(message.as_ptr(), x);

    unsafe {
        static mut BIG_BUFFER: [u8; 64] = [0xCC; 64];
        BIG_BUFFER[0] = 0xAA;
        BIG_BUFFER[1] = 0xBB;
        BIG_BUFFER[2] = 0xCC;
        BIG_BUFFER[3] = 0xDD;
        (api.puts)(BIG_BUFFER.as_ptr(), 64);
    }

    let square = Square { width: 5 };

    print(&square);

    let circle = Circle { radius: 10 };

    print(&circle);
    0
}

#[panic_handler]
fn panic_handler(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}
