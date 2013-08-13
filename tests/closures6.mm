module foo() {

  main: fun() {
    var cmod = get_compiled_module(thisModule);
    var env = {"a": 10,'b':0};
    var cfun = CompiledFunction.new("bar","return a + b;", ['b'], cmod);
    var fn = cfun.asContext(thisModule, env);
    var res = fn.apply([20]);
    assert(res == 30, "CompiledFunction.asContext with var table");
  }
}
