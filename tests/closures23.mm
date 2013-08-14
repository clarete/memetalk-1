module foo() {
  class X {
    fields: x;
    init new: fun() {
      @x = 1;
    }
    instance_method x: fun() {
      return thisContext;
    }
  }

  main: fun() {
    var x = X.new;
    var fn = x.x;
    fn.compiledFunction.setCode("fun(a) { return a + 10; }");
    assert(x.x(10) == 20, "Changing instance method");
  }
}