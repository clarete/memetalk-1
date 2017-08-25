.preamble(ometa_base)
  ometa_base: meme:ometa_base;
  [OMetaBase] <= ometa_base;
.code

class MemeScriptTranslator < OMetaBase
fields: proc;
init new: fun(proc, input) {
  super.new(input);
  @proc = proc;
}

instance_method start: fun() {
  var license = null;
  var meta = null;
  var modobj = null;
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:module]);
      license = this._apply(:anything);
      meta = this._apply(:anything);
      modobj = @proc.new_module();
      this._apply_with_args(:preamble, [modobj]);
      this._apply_with_args(:code_sec, [modobj]);});
  }]);
}
instance_method preamble: fun() {
  var params = null;
  var modobj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:preamble]);
      params = this._apply(:anything);
      modobj.set_params(params);
      this._form(fun() {
        this._many(fun() {
          this._apply_with_args(:module_default_param, [modobj]);}, null);});
      this._form(fun() {
        this._many(fun() {
          this._apply_with_args(:module_alias, [modobj]);}, null);});});
  }]);
}
instance_method module_default_param: fun() {
  var lhs = null;
  var ns = null;
  var name = null;
  var modobj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:param]);
      lhs = this._apply(:anything);
      this._form(fun() {
        this._apply_with_args(:exactly, [:library]);
        ns = this._apply(:anything);
        name = this._apply(:anything);});});
    return modobj.add_default_param(lhs, ns, name);
  }]);
}
instance_method module_alias: fun() {
  var libname = null;
  var alias = null;
  var modobj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:alias]);
      libname = this._apply(:anything);
      alias = this._apply(:anything);});
    return modobj.module_alias(libname, alias);
  }]);
}
instance_method code_sec: fun() {
  var modobj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:code]);
      this._not(fun() {
        this._not(fun() {
          this._form(fun() {
            this._many(fun() {
              this._apply_with_args(:load_top_level_name, [modobj]);}, null);});});});
      this._form(fun() {
        this._many(fun() {
          this._apply_with_args(:definition, [modobj]);}, null);});});
  }]);
}
instance_method load_top_level_name: fun() {
  var name = null;
  var modobj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:class]);
      this._form(fun() {
        this._apply_with_args(:exactly, [:name]);
        this._apply(:anything);});
      this._many(fun() {
        this._apply(:anything);}, null);});
    return modobj.add_top_level_name(name);
  }, fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:object]);
      name = this._apply(:anything);
      this._many(fun() {
        this._apply(:anything);}, null);});
    return modobj.add_top_level_name(name);
  }, fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:fun]);
      name = this._apply(:anything);
      this._many(fun() {
        this._apply(:anything);}, null);});
    return modobj.add_top_level_name(name);
  }]);
}
instance_method definition: fun() {
  var modobj = this._apply(:anything);
  return this._or([fun() {
    this._apply_with_args(:function_definition, [modobj]);
  }, fun() {
    this._apply_with_args(:class_definition, [modobj]);
  }, fun() {
    this._apply_with_args(:object_definition, [modobj]);
  }]);
}
instance_method function_definition: fun() {
  var ast = null;
  var name = null;
  var p = null;
  var fnobj = null;
  var uses_env = null;
  var bproc = null;
  var modobj = this._apply(:anything);
  return this._or([fun() {
    ast = this.input.head();
    this._form(fun() {
      this._apply_with_args(:exactly, [:fun]);
      name = this._apply(:anything);
      p = this._apply(:params);
      fnobj = modobj.new_function(name, p);
      fnobj.set_line(ast);
      uses_env = this._apply(:anything);
      fnobj.uses_env(uses_env);
      bproc = fnobj.body_processor;
      this._form(fun() {
        this._apply_with_args(:exactly, [:body]);
        this._apply_with_args(:body, [bproc]);});});
    fnobj.set_text(ast.text);
  }]);
}
instance_method class_definition: fun() {
  var parent = null;
  var fields = null;
  var klass = null;
  var modobj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:class]);
      this._form(fun() {
        this._apply_with_args(:exactly, [:name]);
        parent = this._apply(:anything);});
      this._form(fun() {
        this._apply_with_args(:exactly, [:fields]);
        fields = this._apply(:anything);});
      klass = modobj.new_class(name, parent, fields);
      this._apply_with_args(:constructors, [klass]);
      this._form(fun() {
        this._many(fun() {
          this._apply_with_args(:instance_method, [klass]);}, null);});
      this._form(fun() {
        this._many(fun() {
          this._apply_with_args(:class_method, [klass]);}, null);});});
  }]);
}
instance_method constructor: fun() {
  var ast = null;
  var name = null;
  var p = null;
  var fnobj = null;
  var uses_env = null;
  var bproc = null;
  var klass = this._apply(:anything);
  return this._or([fun() {
    ast = this.input.head();
    this._form(fun() {
      this._apply_with_args(:exactly, [:ctor]);
      name = this._apply(:anything);
      p = this._apply(:params);
      fnobj = klass.new_ctor(name, p);
      fnobj.set_line(ast);
      uses_env = this._apply(:anything);
      fnobj.uses_env(uses_env);
      bproc = fnobj.body_processor;
      this._form(fun() {
        this._apply_with_args(:exactly, [:body]);
        this._apply_with_args(:body, [bproc]);});});
    fnobj.set_text(ast.text);
  }]);
}
instance_method constructors: fun() {
  var klass = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:ctors]);
      this._form(fun() {
        this._many(fun() {
          this._apply_with_args(:constructor, [klass]);}, null);});});
  }, fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:ctors]);
      this._form(fun() {
});});
  }]);
}
instance_method instance_method: fun() {
  var ast = null;
  var name = null;
  var p = null;
  var fnobj = null;
  var uses_env = null;
  var bproc = null;
  var klass = this._apply(:anything);
  return this._or([fun() {
    ast = this.input.head();
    this._form(fun() {
      this._apply_with_args(:exactly, [:fun]);
      name = this._apply(:anything);
      p = this._apply(:params);
      fnobj = klass.new_instance_method(name, p);
      fnobj.set_line(ast);
      uses_env = this._apply(:anything);
      fnobj.uses_env(uses_env);
      bproc = fnobj.body_processor;
      this._form(fun() {
        this._apply_with_args(:exactly, [:body]);
        this._apply_with_args(:body, [bproc]);});});
    fnobj.set_text(ast.text);
  }]);
}
instance_method class_method: fun() {
  var ast = null;
  var name = null;
  var fnobj = null;
  var p = null;
  var uses_env = null;
  var bproc = null;
  var klass = this._apply(:anything);
  return this._or([fun() {
    ast = this.input.head();
    this._form(fun() {
      this._apply_with_args(:exactly, [:fun]);
      name = this._apply(:anything);
      fnobj = klass.new_class_method(name);
      p = this._apply_with_args(:fparams, [fnobj]);
      fnobj.set_params(p);
      fnobj.set_line(ast);
      uses_env = this._apply(:anything);
      fnobj.uses_env(uses_env);
      bproc = fnobj.body_processor;
      this._form(fun() {
        this._apply_with_args(:exactly, [:body]);
        this._apply_with_args(:body, [bproc]);});});
    fnobj.set_text(ast.text);
  }]);
}
instance_method fparams: fun() {
  var x = null;
  var obj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:params]);
      this._form(fun() {
        x = this._many(fun() {
          this._apply_with_args(:fparam, [obj]);}, null);});});
    return x;
  }]);
}
instance_method fparam: fun() {
  var x = null;
  var obj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:var-arg]);
      x = this._apply(:anything);
      obj.set_vararg(x);});
    return x;
  }, fun() {
    x = this._apply(:anything);
  }]);
}
instance_method params: fun() {
  var x = null;
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:params]);
      this._form(fun() {
        x = this._many(fun() {
          this._apply(:param);}, null);});});
    return x;
  }]);
}
instance_method param: fun() {
  var x = null;
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:var-arg]);
      x = this._apply(:anything);});
    return x;
  }, fun() {
    x = this._apply(:anything);
  }]);
}
instance_method object_definition: fun() {
  var name = null;
  var obj = null;
  var modobj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:object]);
      name = this._apply(:anything);
      obj = modobj.new_object(name);
      this._form(fun() {
        this._many1(fun() {
          this._apply_with_args(:obj_slot, [obj]);});});
      this._form(fun() {
        this._many(fun() {
          this._apply_with_args(:obj_function, [obj]);}, null);});});
  }]);
}
instance_method obj_slot: fun() {
  var obj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:slot]);
      this._apply_with_args(:obj_slot_value, [obj]);});
  }]);
}
instance_method obj_slot_value: fun() {
  var name = null;
  var x = null;
  var null = null;
  var obj = this._apply(:anything);
  return this._or([fun() {
    name = this._apply(:anything);
    this._form(fun() {
      this._apply_with_args(:exactly, [:literal-number]);
      x = this._apply(:anything);});
    return obj.add_slot_literal_num(name,x);
  }, fun() {
    name = this._apply(:anything);
    this._form(fun() {
      this._apply_with_args(:exactly, [:literal-string]);
      x = this._apply(:anything);});
    return obj.add_slot_literal_string(name,x);
  }, fun() {
    name = this._apply(:anything);
    this._form(fun() {
      null = this._apply_with_args(:exactly, [:literal]);});
    return obj.add_slot_literal_null(name);
  }, fun() {
    name = this._apply(:anything);
    this._form(fun() {
      this._apply_with_args(:exactly, [:literal-array]);
      x = this._form(fun() {
        this._many(fun() {
          this._apply(:anything);}, null);});});
    return obj.add_slot_literal_array(name, x);
  }, fun() {
    name = this._apply(:anything);
    this._form(fun() {
      this._apply_with_args(:exactly, [:literal-dict]);
      x = this._many(fun() {
        this._apply(:anything);}, null);});
    return obj.add_slot_literal_dict(name, x);
  }, fun() {
    name = this._apply(:anything);
    x = this._apply(:anything);
    return obj.add_slot_ref(name, x);
  }]);
}
instance_method obj_function: fun() {
  var obj = this._apply(:anything);
  return this._or([fun() {
    this._apply_with_args(:constructor, [obj]);
  }, fun() {
    this._apply_with_args(:function_definition, [obj]);
  }]);
}
instance_method body: fun() {
  var ast = null;
  var name = null;
  var fnobj = this._apply(:anything);
  return this._or([fun() {
    ast = this._form(fun() {
      this._many(fun() {
        this._apply_with_args(:expr, [fnobj]);}, null);
      this._form(fun() {
        this._apply_with_args(:exactly, [:end-body]);});});
    return fnobj.emit_return_this(ast);
  }, fun() {
    this._form(fun() {
      this._form(fun() {
        this._apply_with_args(:exactly, [:primitive]);
        this._form(fun() {
          this._apply_with_args(:exactly, [:literal-string]);
          name = this._apply(:anything);});});
      this._many(fun() {
        this._apply(:anything);}, null);});
    return fnobj.set_primitive(name);
  }]);
}
instance_method exprs: fun() {
  var fnobj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._many(fun() {
        this._apply_with_args(:expr, [fnobj]);}, null);});
  }]);
}
instance_method expr_elif: fun() {
  var label = null;
  var fnobj = this._apply(:anything);
  var lb = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:elif]);
      this._apply_with_args(:expr, [fnobj]);
      label = fnobj.emit_jz();
      this._form(fun() {
        this._many(fun() {
          this._apply_with_args(:expr, [fnobj]);}, null);
        fnobj.emit_jmp(lb);});});
    label.as_current();
  }]);
}
instance_method stm: fun() {
  var id = null;
  var s = null;
  var arity = null;
  var name = null;
  var e = null;
  var label = null;
  var lb2 = null;
  var lbcond = null;
  var lbend = null;
  var label_begin_try = null;
  var end_pos = null;
  var label_begin_catch = null;
  var cp = null;
  var v = null;
  var lhs = null;
  var f = null;
  var x = null;
  var this = null;
  var null = null;
  var true = null;
  var false = null;
  var module = null;
  var context = null;
  var p = null;
  var fnobj = this._apply(:anything);
  var ast = this._apply(:anything);
  return this._or([fun() {
    this._apply_with_args(:exactly, [:var-def]);
    id = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    return fnobj.emit_var_decl(ast, id);
  }, fun() {
    this._apply_with_args(:exactly, [:return]);
    this._apply_with_args(:expr, [fnobj]);
    return fnobj.emit_return_top(ast);
  }, fun() {
    this._apply_with_args(:exactly, [:return-null]);
    return fnobj.emit_return_null(ast);
  }, fun() {
    this._apply_with_args(:exactly, [:return-top]);
    return fnobj.emit_return_top(ast);
  }, fun() {
    this._apply_with_args(:exactly, [:non-local-return]);
    this._apply_with_args(:expr, [fnobj]);
    return fnobj.emit_non_local_return(ast);
  }, fun() {
    this._apply_with_args(:exactly, [:super-ctor-send]);
    s = this._apply(:anything);
    arity = this._apply_with_args(:args, [fnobj]);
    return fnobj.emit_super_ctor_send(ast, s, arity);
  }, fun() {
    this._apply_with_args(:exactly, [:send-or-local-call]);
    name = this._apply(:anything);
    arity = this._apply_with_args(:args, [fnobj]);
    return fnobj.emit_send_or_local_call(ast, name, arity);
  }, fun() {
    this._apply_with_args(:exactly, [:super-send]);
    arity = this._apply_with_args(:args, [fnobj]);
    return fnobj.emit_super_send(ast, arity);
  }, fun() {
    this._apply_with_args(:exactly, [:send]);
    e = this._apply(:anything);
    s = this._apply(:anything);
    arity = this._apply_with_args(:args, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_send(ast, s, arity);
  }, fun() {
    this._apply_with_args(:exactly, [:call]);
    e = this._apply(:anything);
    arity = this._apply_with_args(:args, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_call(ast, arity);
  }, fun() {
    this._apply_with_args(:exactly, [:expression]);
    this._apply_with_args(:expr, [fnobj]);
    return fnobj.emit_pop(ast);
  }, fun() {
    this._apply_with_args(:exactly, [:not]);
    this._apply_with_args(:expr, [fnobj]);
    return fnobj.emit_unary(ast,"!");
  }, fun() {
    this._apply_with_args(:exactly, [:negative]);
    this._apply_with_args(:expr, [fnobj]);
    return fnobj.emit_unary(ast,"neg");
  }, fun() {
    this._apply_with_args(:exactly, [:bit-neg]);
    this._apply_with_args(:expr, [fnobj]);
    return fnobj.emit_unary(ast,"~");
  }, fun() {
    this._apply_with_args(:exactly, [:and]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"and");
  }, fun() {
    this._apply_with_args(:exactly, [:or]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"or");
  }, fun() {
    this._apply_with_args(:exactly, [:+]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"+");
  }, fun() {
    this._apply_with_args(:exactly, [:-]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"-");
  }, fun() {
    this._apply_with_args(:exactly, [:*]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"*");
  }, fun() {
    this._apply_with_args(:exactly, [:/]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"/");
  }, fun() {
    this._apply_with_args(:exactly, [:&]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"&");
  }, fun() {
    this._apply_with_args(:exactly, [:|]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"|");
  }, fun() {
    this._apply_with_args(:exactly, [:<]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"<");
  }, fun() {
    this._apply_with_args(:exactly, [:<]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"<");
  }, fun() {
    this._apply_with_args(:exactly, [:<<]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"<<");
  }, fun() {
    this._apply_with_args(:exactly, [:>>]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,">>");
  }, fun() {
    this._apply_with_args(:exactly, [:<=]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"<=");
  }, fun() {
    this._apply_with_args(:exactly, [:>]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,">");
  }, fun() {
    this._apply_with_args(:exactly, [:>=]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,">=");
  }, fun() {
    this._apply_with_args(:exactly, [:==]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"==");
  }, fun() {
    this._apply_with_args(:exactly, [:!=]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_binary(ast,"!=");
  }, fun() {
    this._apply_with_args(:exactly, [:if]);
    this._apply_with_args(:expr, [fnobj]);
    label = fnobj.emit_jz();
    this._form(fun() {
      this._many(fun() {
        this._apply_with_args(:expr, [fnobj]);}, null);
      lb2 = fnobj.emit_jmp();});
    label.as_current();
    this._form(fun() {
      this._many(fun() {
        this._apply_with_args(:expr_elif, [fnobj,lb2]);}, null);});
    this._form(fun() {
      this._many(fun() {
        this._apply_with_args(:expr, [fnobj]);}, null);});
    lb2.as_current();
  }, fun() {
    this._apply_with_args(:exactly, [:while]);
    lbcond = fnobj.current_label(false);
    this._apply_with_args(:expr, [fnobj]);
    lbend = fnobj.emit_jz();
    this._form(fun() {
      this._many(fun() {
        this._apply_with_args(:expr, [fnobj]);}, null);});
    fnobj.emit_jmp_back(lbcond.as_current());
    return lbend.as_current();
  }, fun() {
    this._apply_with_args(:exactly, [:try]);
    label_begin_try = fnobj.current_label();
    this._form(fun() {
      this._many(fun() {
        this._apply_with_args(:expr, [fnobj]);}, null);});
    end_pos = fnobj.emit_catch_jump();
    label_begin_catch = fnobj.current_label();
    cp = this._apply(:catch_decl);
    fnobj.bind_catch_var(cp[1]);
    this._form(fun() {
      this._many(fun() {
        this._apply_with_args(:expr, [fnobj]);}, null);});
    return fnobj.emit_try_catch(label_begin_try, label_begin_catch, end_pos, cp[0]);
  }, fun() {
    this._apply_with_args(:exactly, [:=]);
    this._form(fun() {
      this._apply_with_args(:exactly, [:id]);
      v = this._apply(:anything);});
    this._apply_with_args(:expr, [fnobj]);
    return fnobj.emit_local_assignment(ast, v);
  }, fun() {
    this._apply_with_args(:exactly, [:=]);
    this._form(fun() {
      this._apply_with_args(:exactly, [:index]);
      lhs = this._apply(:anything);
      this._apply_with_args(:expr, [fnobj]);});
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,lhs]);
    return fnobj.emit_index_assignment(ast);
  }, fun() {
    this._apply_with_args(:exactly, [:=]);
    this._form(fun() {
      this._apply_with_args(:exactly, [:field]);
      f = this._apply(:anything);});
    this._apply_with_args(:expr, [fnobj]);
    return fnobj.emit_field_assignment(ast, f);
  }, fun() {
    this._apply_with_args(:exactly, [:literal-number]);
    x = this._apply(:anything);
    return fnobj.emit_push_num_literal(ast, x);
  }, fun() {
    this = this._apply_with_args(:exactly, [:literal]);
    return fnobj.emit_push_this(ast);
  }, fun() {
    this._apply_with_args(:exactly, [:literal-string]);
    x = this._apply(:anything);
    return fnobj.emit_push_str_literal(ast, x);
  }, fun() {
    this._apply_with_args(:exactly, [:literal-symbol]);
    x = this._apply(:anything);
    return fnobj.emit_push_sym_literal(ast, x);
  }, fun() {
    null = this._apply_with_args(:exactly, [:literal]);
    return fnobj.emit_push_null(ast);
  }, fun() {
    true = this._apply_with_args(:exactly, [:literal]);
    return fnobj.emit_push_true(ast);
  }, fun() {
    false = this._apply_with_args(:exactly, [:literal]);
    return fnobj.emit_push_false(ast);
  }, fun() {
    module = this._apply_with_args(:exactly, [:literal]);
    return fnobj.emit_push_module(ast);
  }, fun() {
    context = this._apply_with_args(:exactly, [:literal]);
    return fnobj.emit_push_context(ast);
  }, fun() {
    this._apply_with_args(:exactly, [:id]);
    name = this._apply(:anything);
    return fnobj.emit_push_var(ast, name);
  }, fun() {
    this._apply_with_args(:exactly, [:field]);
    name = this._apply(:anything);
    return fnobj.emit_push_field(ast, name);
  }, fun() {
    this._apply_with_args(:exactly, [:literal-array]);
    e = this._apply(:anything);
    this._apply_with_args(:exprs, [fnobj,e]);
    return fnobj.emit_push_list(ast, len(e));
  }, fun() {
    this._apply_with_args(:exactly, [:literal-dict]);
    p = this._apply_with_args(:dict_pairs, [fnobj]);
    return fnobj.emit_push_dict(ast, len(p));
  }, fun() {
    this._apply_with_args(:exactly, [:index]);
    e = this._apply(:anything);
    this._apply_with_args(:expr, [fnobj]);
    this._apply_with_args(:expr, [fnobj,e]);
    return fnobj.emit_push_index(ast);
  }]);
}
instance_method expr: fun() {
  var ast = null;
  var fnobj = this._apply(:anything);
  return this._or([fun() {
    ast = this.input.head();
    this._form(fun() {
      this._apply_with_args(:stm, [fnobj,ast]);});
  }, fun() {
    this._apply_with_args(:funliteral, [fnobj]);
  }]);
}
instance_method catch_decl: fun() {
  var type = null;
  var id = null;
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:catch]);
      this._form(fun() {
        this._apply_with_args(:exactly, [:id]);
        type = this._apply(:anything);});
      id = this._apply(:anything);});
    return [type, id];
  }, fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:catch]);
      id = this._apply(:anything);});
    return [null, id];
  }]);
}
instance_method dict_pairs: fun() {
  var e = null;
  var fnobj = this._apply(:anything);
  return this._or([fun() {
    e = this._many(fun() {
      this._or([fun() {
        this._form(fun() {
          this._apply_with_args(:exactly, [:pair]);
          this._apply_with_args(:expr, [fnobj]);
          this._apply_with_args(:expr, [fnobj]);});
      }]);}, null);
    return e;
  }]);
}
instance_method funliteral: fun() {
  var ast = null;
  var p = null;
  var fn = null;
  var fnobj = this._apply(:anything);
  return this._or([fun() {
    ast = this.input.head();
    ast = this._form(fun() {
      this._apply_with_args(:exactly, [:fun-literal]);
      p = this._apply(:params);
      fn = fnobj.new_closure(p);
      fn.set_line(ast);
      this._form(fun() {
        this._apply_with_args(:exactly, [:body]);
        this._form(fun() {
          this._many(fun() {
            this._apply_with_args(:expr, [fn]);}, null);});});});
    fn.set_text(ast.text);
    return fnobj.emit_push_closure(ast, fn);
  }]);
}
instance_method cfunliteral: fun() {
  var ast = null;
  var fnobj = this._apply(:anything);
  return this._or([fun() {
    ast = this.input.head();
    fnobj.set_line(ast);
    this._form(fun() {
      this._many(fun() {
        this._apply_with_args(:expr, [fnobj]);}, null);});
    return fnobj;
  }]);
}
instance_method args: fun() {
  var arity = null;
  var fnobj = this._apply(:anything);
  return this._or([fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:args]);
      this._form(fun() {
});});
    return 0;
  }, fun() {
    this._form(fun() {
      this._apply_with_args(:exactly, [:args]);
      arity = this._apply_with_args(:arglist, [fnobj]);});
    return arity;
  }]);
}
instance_method arglist: fun() {
  var x = null;
  var fnobj = this._apply(:anything);
  return this._or([fun() {
    x = this._form(fun() {
      this._many1(fun() {
        this._apply_with_args(:expr, [fnobj]);});});
    return x.size;
  }]);
}


end //MemeScriptTranslator

.endcode