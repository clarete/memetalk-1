.license
.endlicense

.preamble(test)

.code

// -- module functions --

a: fun(fn) {
  fn();
  try {
    fn();
    b(fn);
    fn();
  } catch(e) {
    fn();
  }
  fn();
}

b: fun(fn) {
  fn();
  try {
    fn();
    r(fn);
    fn();
  } catch(e) {
    fn();
  }
  fn();
  Exception.throw("yy");
  fn();
}

main: fun() {
  var x = 0;
  var fn = fun() { x = x + 1; };
  a(fn);
  test.assert(x == 9, "Multiple try/catches");
}

r: fun(fn) {
  fn();
  Exception.throw("xx");
  fn();
}

// -- module classes --


.end
