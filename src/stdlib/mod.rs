#[no_mangle]
pub unsafe extern fn memcpy(dest: *mut u8, src: *const u8,
                            n: usize) -> *mut u8 {
  let mut i = 0;
  while i < n {
    *dest.offset(i as isize) = *src.offset(i as isize);
    i += 1
  }
  return dest;
}

#[no_mangle]
pub unsafe extern fn memset(dest: *mut u8, src: u8, n: usize) -> *mut u8 {
  let mut i = 0;
  while i < n {
    *dest.offset(i as isize) = src;
    i += 1;
  }
  return dest;
}
