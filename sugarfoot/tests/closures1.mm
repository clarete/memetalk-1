.preamble(test)

.code

main: fun() {
  var z = fun(k) { k + 1 };
  test.assert(z(10) == 11, "testing closure return value");
}

.end
