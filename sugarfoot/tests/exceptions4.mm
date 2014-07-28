.license
.endlicense

.preamble(test)

.code

// -- module functions --

f: fun(fn) {
  fn();
}

main: fun() {
  var a = 0;
  f(fun() {
    try {
      Exception.throw("XX");
      test.assert(false, "Shouldn't execute here");
    } catch(Exception e) {
      a = a + 1;
    }
    a = a + 1;
  });
  a = a + 1;
  test.assert(a == 3, "try/catch inside closure");
}

// -- module classes --


.end
