#include <stdlib.h>
#include <string>
#include <stdlib.h>
#include <assert.h>
#include <map>
#include "process.hpp"
#include "defs.hpp"
#include "vm.hpp"
#include "core_image.hpp"
#include "mmc_image.hpp"
#include "report.hpp"
#include "mmobj.hpp"
#include "utils.hpp"

class mm_rewind {
public:
  mm_rewind(oop ex) : mm_exception(ex) {}
  oop mm_exception;
};

Process::Process(VM* vm)
  : _vm(vm), _mmobj(vm->mmobj()) {
  init();
}

// int frame_count = 0;

oop Process::run(oop recv, oop selector_sym, int* exc) {
  return do_send_0(recv, selector_sym, exc);
}

void Process::init() {
  _stack = (word*) malloc(DEFAULT_STACK_SIZE);
  // debug() << " Initial stack " << _stack << endl;

  _sp = _stack; //stack
  _fp = _stack; //frame
  _bp = NULL; //base
  _ip = NULL; //instruction
  _mp = NULL; //module
  _cp = NULL; //context
  _rp = NULL; //receiver
  _dp = NULL; //receiver data
  _ep = NULL; //env
}

void Process::push_frame(number arity, number num_locals) {
  // debug() << "++ Push frame:  " << _sp << " num locals " << num_locals << endl;

  // oop curr_sp = _sp;

  stack_push(arity);

  word fp = (word) _fp;
  debug() << "push_frame: fp: " << _fp << endl;

  _fp = _sp;
  for (int i = 0; i < num_locals; i++) {
    stack_push((oop)0);
  }

  debug() << "push_frame arity: " << arity << " num locals: " << num_locals
          << " fp: " << (oop) fp << " cp: " << _cp << " ip: " << _ip << " ep: " << _ep
          << " rp: " << _rp << " dp: " << _dp << " mp: " << _mp << endl;

  stack_push(fp);
  stack_push(_cp);
  stack_push(_ip);
  stack_push(_ep);
  stack_push(_rp);
  stack_push(_dp);
  stack_push(_bp);
  _bp = _sp;
  // debug() << " push frame SP is: " << _sp << endl;
}

void Process::pop_frame() {
  number arity = *_fp;
  word fp = (word) _fp;

  // debug() << "pop_frame begin SP: " << _sp << endl;

  _bp = stack_pop();
  _dp = stack_pop();
  _rp = stack_pop();
  _ep = stack_pop();
  _ip = (bytecode*) stack_pop();
  _cp = stack_pop();
  _fp = stack_pop();

  debug() << "pop_frame: fp: " << _fp << " rp: " << _rp << " dp: " << _dp << endl;

  // debug() << "pop_frame [fm:" << --frame_count << " arity: " << arity
  //         << " fp: " << _fp << " cp: " << _cp << " ip: " << _ip << " ep: " << _ep
  //         << " rp: " << _rp << " dp: " << _dp << " mp (before): " << _mp << endl;

  if (_cp) {// first frame has _cp = null
    // debug() << "pop_frame: getting module from fun " << _cp << endl;
    _mp = _mmobj->mm_function_get_module(_cp);
    debug() << "MP for fun unloaded: " << _mp << endl;
  } else {
    debug() << "++ MP for fun unloaded is null!" << endl;
  }

  _sp = (oop) fp - (arity + 1);
  // debug() << "-- pop frame SP:" <<  _sp << endl;
}

void Process::unload_fun_and_return(oop retval) {
  pop_frame();
  stack_push(retval);
}

oop Process::ctor_rdp_for(oop rp, oop cp) {
  debug() << "ctor_rdp_for rp: " << rp << ", cp: " << cp << endl;
  if (!rp) {
    bail("no rdp for ctor!");
  }
  oop vt = _mmobj->mm_object_vt(rp);
  oop cclass = _mmobj->mm_class_get_compiled_class(vt);

  oop other_cclass = _mmobj->mm_function_get_owner(cp);

  debug() << "rdp_for_ctor cclass: " << cclass << ", other cclass: " << other_cclass << endl;

  if (cclass == other_cclass) {
    return rp;
  } else {
    return ctor_rdp_for(_mmobj->mm_object_delegate(rp), cp);
  }
}

void Process::basic_new_and_load(oop recv) {
  oop klass = recv;
  oop instance = _mmobj->alloc_instance(klass);
  _rp = instance;
  _dp = ctor_rdp_for(_rp, _cp);
  debug() << "basic_new: " << instance << " dp: " << _dp << endl;
  if (_ep) {
    ((oop*)_ep)[0] = _rp;
    ((oop*)_ep)[1] = _dp;
  }
}

void Process::setup_ep(oop fun, oop recv, oop drecv) {
  number params = _mmobj->mm_function_get_num_params(fun);
  number size = _mmobj->mm_function_get_num_locals_or_env(fun);
  _ep = (oop) calloc(sizeof(oop), size + 2); //+2: space for rp, dp
  debug() << "Allocated ep: " << _ep << " - " << " size: " << size
          << " params: " << params
          << " rp/dp: "<< recv << " " << drecv << endl;

  ((oop*)_ep)[0] = recv;
  ((oop*)_ep)[1] = drecv;

  copy_params_to_env(params, _mmobj->mm_function_get_env_offset(fun));
}

void Process::copy_params_to_env(number params, number env_offset) {
  debug() << "Process::copy_params_to_env " << params << " " << env_offset << endl;

  for (int i = 0; i < params; i++) {
    debug() << "ep[" << i+2+env_offset << "] = " << * (oop*)(_fp - (i+1)) << endl;
    ((oop*)_ep)[i+2+env_offset] = * (oop*)(_fp - (i+1));
  }
}

bool Process::load_fun(oop recv, oop drecv, oop fun, bool should_allocate) {
  assert(_mmobj->mm_is_function(fun) || _mmobj->mm_is_context(fun));

  if (_mmobj->mm_function_is_getter(fun)) {
    number idx = _mmobj->mm_function_access_field(fun);
    debug() << "GETTER: idx " << idx << " on " << recv << endl;
    oop val = ((oop*)drecv)[idx];
    debug() << "GETTER: pushing retval: " << val << endl;
    stack_push(val);
    return false;
  }


  push_frame(_mmobj->mm_function_get_num_params(fun),
             _mmobj->mm_function_get_num_locals_or_env(fun));

  if (_mmobj->mm_is_context(fun)) {
    _ep = _mmobj->mm_context_get_env(fun);
    _rp = ((oop*)_ep)[0];
    _dp = ((oop*)_ep)[1];
    debug() << "loaded ep with rp/dp: " << _rp << " " << _dp << endl;
    copy_params_to_env(_mmobj->mm_function_get_num_params(fun),
                       _mmobj->mm_function_get_env_offset(fun));
  } else {
    if (_mmobj->mm_function_uses_env(fun)) {
      setup_ep(fun, recv, drecv);
      _rp = NULL; //to remember me to use ep[rp] and dp[rp] if ep exists when executing bytecodes
      _dp = NULL;
      debug() << "look out! we should use ep[dp] and ep[rp]: " << _rp << " " << _dp << endl;
    } else {
      _ep = NULL;
      _rp = recv;
      _dp = drecv;
    }
  }

  _cp = fun;
  _mp = _mmobj->mm_function_get_module(_cp);
  debug() << "MP for fun load: " << _mp << endl;

  if (_mmobj->mm_function_is_ctor(fun) and should_allocate) {
    basic_new_and_load(recv);
  }

  if (_mmobj->mm_function_is_prim(fun)) {
    oop prim_name = _mmobj->mm_function_get_prim_name(fun);
    std::string str_prim_name = _mmobj->mm_string_cstr(prim_name);
    int ret = execute_primitive(str_prim_name);
    if (ret == 0) {
      oop value = stack_pop(); //shit
      unload_fun_and_return(value);
      return false;
    } else if (ret == PRIM_RAISED) {
      oop ex_oop = stack_pop(); //shit
      debug() << "load_fun: prim returned: RAISED " << ex_oop << endl;
      pop_frame();
      if (!unwind_with_exception(ex_oop)) {
        debug() << "load_fun: unwind_with_exception reached primitive. c++ throwing...: " << ex_oop << endl;
        throw mm_rewind(ex_oop);
      } else {
        debug() << "load_fun: unwind_with_exception rached catch block for " << ex_oop << endl;
        // oop value = stack_pop(); //shit
        // unload_fun_and_return(value);
        stack_push(ex_oop); //we rely on compiler generating a pop instruction to bind ex_oop to the catch var
        return false;
      }
    }
  }


  // debug() << "load_fun: module for fun " << fun << " is " << _mp << endl;
  // debug() << "load_fun: is ctor? " << _mmobj->mm_function_is_ctor(fun) << " alloc? " << should_allocate << endl;
  _ip = _mmobj->mm_function_get_code(fun);
  // debug() << "first instruction " << decode_opcode(*_ip) << endl;
  _code_size = _mmobj->mm_function_get_code_size(fun);
  return true;
}

oop Process::do_send_0(oop recv, oop selector, int* exc) {
  debug() << "-- begin do_send_0, recv: " << recv
          << ", selector: " << _mmobj->mm_symbol_cstr(selector) << endl;

  std::pair<oop, oop> res = lookup(recv, _mmobj->mm_object_vt(recv), selector);

  oop drecv = res.first;
  oop fun = res.second;
  if (!fun) {
    bail("do_send_0: lookup failed"); //todo
  }

  number arity = _mmobj->mm_function_get_num_params(fun);
  if (arity != 0) {
    debug() << 0 << " != " << arity << endl;
    bail("do_send_0: arity and num_args differ");
  }

  oop stop_at_fp = _fp;
  *exc = 0;
  try {
    if (load_fun(recv, drecv, fun, true)) {
      fetch_cycle(stop_at_fp);
    }
  } catch(mm_rewind e) {
    *exc = 1;
    return e.mm_exception;
  }

  oop val = stack_pop();
  debug() << "-- end do_send_0, val: " << val << endl;
  return val;
}

oop Process::do_call(oop fun, int* exc) {
  assert(_mmobj->mm_is_context(fun)); //since we pass NULL to load_fun

  debug() << "-- begin call, sp: " << _sp << ", fp: " << _fp << endl;
  oop stop_at_fp = _fp;

  *exc = 0;
  try {
    if (load_fun(NULL, NULL, fun, false)) {
      fetch_cycle(stop_at_fp);
    }
  } catch(mm_rewind e) {
    *exc = 1;
    return e.mm_exception;
  }

  oop val = stack_pop();
  debug() << "-- end call: " << val << " sp: " << _sp << ", fp: " << _fp << endl;
  return val;
}

oop Process::do_call(oop fun, oop args, int* exc) {
  assert(_mmobj->mm_is_context(fun)); //since we pass NULL to load_fun

  number num_args = _mmobj->mm_list_size(args);
  number arity = _mmobj->mm_function_get_num_params(fun);
  if (num_args != arity) {
    debug() << num_args << " != " << arity << endl;
    bail("call: arity and num_args differ");
  }

  for (int i = 0; i < num_args; i++) {
    stack_push(_mmobj->mm_list_entry(args, i));
  }
  return do_call(fun, exc);
}

void Process::fetch_cycle(void* stop_at_fp) {
  debug() << "begin fetch_cycle fp:" << _fp <<  " stop_fp:" <<  stop_at_fp
          << " ip: " << _ip << endl;
  while ((_fp > stop_at_fp) && _ip) { // && ((_ip - start_ip) * sizeof(bytecode))  < _code_size) {
    // debug() << "fp " << _fp << " stop " <<  stop_at_fp << " ip-start " <<  (_ip - start_ip)  << " codesize " <<  _code_size <<
    //   "ip " << _ip << std::endl;
    bytecode code = *_ip;
    if (_ip != 0) { // the bottommost frame has ip = 0
      _ip++; //this can't be done after dispatch, where an ip for a different fun may be set
             //(thus, doing so would skip the first instruction)
    }
    int opcode = decode_opcode(code);
    int arg = decode_args(code);
    // debug() << " [dispatching] " << opcode << endl;
    dispatch(opcode, arg);
    // debug() << " [end of dispatch] " << opcode << endl;
  }
  debug() << "end fetch_cycle" << endl;
}

void Process::handle_send(number num_args) {
  oop selector = stack_pop();
  oop recv = stack_pop(); //(oop) * _sp;

  debug() << " SEND " << selector << " name: " << _mmobj->mm_symbol_cstr(selector)
          << " " << "recv: " << recv << endl;

  std::pair<oop,oop> res = lookup(recv, _mmobj->mm_object_vt(recv), selector);
  oop drecv = res.first;
  oop fun = res.second;
  debug() << "Lookup FOUND " << fun << endl;

  if (!fun) {
    bail("lookup failed!!");
  }

  number arity = _mmobj->mm_function_get_num_params(fun);
  if (num_args != arity) {
    debug() << num_args << " != " << arity << endl;
    bail("handle_send: arity and num_args differ");
  }
  load_fun(recv, drecv, fun, true);
}

void Process::handle_super_ctor_send(number num_args) {
  oop selector = stack_pop();
  // debug() << " SUPER: " << selector << " -- " << _mmobj->mm_symbol_cstr(selector) << endl;

  // lookup starts at the parent of rp's class
  oop instance = get_dp();
  oop klass = _mmobj->mm_object_vt(instance);
  oop pklass = _mmobj->mm_object_delegate(klass);
  oop receiver = _mmobj->mm_object_delegate(instance);

  std::pair<oop, oop> res = lookup(receiver, _mmobj->mm_object_vt(pklass), selector);
  oop drecv = res.first;
  oop fun = res.second;

  if (!fun) {
    bail("Lookup failed");
  }

  debug() << "Lookup FOUND " << fun << endl;


  number arity = _mmobj->mm_function_get_num_params(fun);
  if (num_args != arity) {
    debug() << num_args << " != " << arity << endl;
    bail("handle_super_ctor_send: arity and num_args differ");
  }

  load_fun(_rp, drecv, fun, false);
}

void Process::handle_call(number num_args) {
  oop fun = stack_pop();
  number arity = _mmobj->mm_function_get_num_params(fun);
  if (num_args != arity) {
    bail("handle_call: arity and num_args differ");
  }
  load_fun(NULL, NULL, fun, false);

}

void Process::dispatch(int opcode, int arg) {
    // debug() << " executing " << opcode << " " << arg << endl;
    oop val;
    switch(opcode) {
      case PUSH_LOCAL:
        debug() << "PUSH_LOCAL " << arg << " " << (oop) *(_fp + arg + 1) << endl;
        stack_push(*(_fp + arg + 1));
        break;
      case PUSH_PARAM:
        debug() << "PUSH_PARAM " << arg << " " << (oop) *(_fp - ((number) *_fp - arg)) << endl;
        stack_push(*(_fp - ((number) *_fp - arg)));
        break;
      case PUSH_LITERAL:
        debug() << "PUSH_LITERAL " << arg << " " << _mmobj->mm_function_get_literal_by_index(_cp, arg) << endl;
        stack_push(_mmobj->mm_function_get_literal_by_index(_cp, arg));
        break;
      case PUSH_MODULE:
        debug() << "PUSH_MODULE " << arg << " " << _mp << endl;
        stack_push(_mp);
        break;
      case PUSH_FIELD:
        debug() << "PUSH_FIELD " << arg << " " << (oop) *(get_dp() + arg + 2) <<  " dp: " << get_dp() << endl;
        stack_push(*(get_dp() + arg + 2));
        break;
      case PUSH_THIS:
        if (_ep == NULL) {
          debug() << "PUSH_THIS " << arg << " " << get_rp() << endl;
          stack_push(get_rp());
        } else {
          debug() << "PUSH_THIS [env] " << arg << " " << ((oop*)_ep)[0] << endl;
          stack_push(((oop*)_ep)[0]);
        }
        break;
      case PUSH_ENV:
        debug() << "PUSH_ENV " << arg << " -- " << _ep << " " << (oop*)_ep[arg+2] << endl;//+2: skip dp,rp
        stack_push(((oop*)_ep)[arg+2]);
        break;
      case PUSH_EP:
        debug() << "PUSH_EP " << arg << " -- " << _ep << endl;
        stack_push(_ep);
        break;
      case PUSH_BIN:
        debug() << "PUSH_BIN " << arg << endl;
        stack_push(arg);
        break;
      case RETURN_TOP:
        val = stack_pop();
        debug() << "RETURN_TOP " << arg << " " << val << endl;
        unload_fun_and_return(val);
        break;
      case RETURN_THIS:
        if (_ep == NULL) {
          debug() << "RETURN_THIS " << get_rp() << endl;
          unload_fun_and_return(get_rp());
        } else {
          debug() << "RETURN_THIS [env] " << arg << " " << ((oop*)_ep)[0] << endl;
          unload_fun_and_return(((oop*)_ep)[0]);
        }
        break;
      case POP:
        val =stack_pop();
        debug() << "POP " << arg << " = " << val << endl;
        break;
      case POP_LOCAL:
        val = stack_pop();
        debug() << "POP_LOCAL " << arg << " on " << (oop) (_fp + arg + 1) << " -- "
                << (oop) *(_fp + arg + 1) << " = " << val << endl;
        *(_fp + arg + 1) = (word) val;
        break;
      case POP_FIELD:
        val = stack_pop();
        debug() << "POP_FIELD " << arg << " on " << (oop) (get_dp() + arg + 2) << " dp: " << get_dp() << " -- "
                << (oop) *(get_dp() + arg + 2) << " = " << val << endl; //2: vt, delegate
        *(get_dp() + arg + 2) = (word) val;
        break;
      case POP_ENV:
        val = stack_pop();
        debug() << "POP_ENV " << arg << " ep: " << _ep << " "
                << (oop) *(_ep + arg + 2) << " = " << val << endl; //+2: rp, dp
        *(_ep + arg + 2) = (word) val;
        break;
      case SEND:
        debug() << "SEND " << arg << endl;
        handle_send(arg);
        break;
      case SUPER_CTOR_SEND:
        handle_super_ctor_send(arg);
        break;
      case CALL:
        debug() << "CALL " << arg << endl;
        handle_call(arg);
        break;
      case JMP:
        debug() << "JMP " << arg << " " << endl;
        _ip += (arg -1); //_ip already suffered a ++ in dispatch
        break;
      case JZ:
        val = stack_pop();
        debug() << "JZ " << arg << " " << val << endl;
        if ((val == MM_FALSE) || (val == MM_NULL)) {
          _ip += (arg -1); //_ip already suffered a ++ in dispatch
        }
        break;
      // case SUPER_SEND:
      //   handle_super_send(arg);
      //   break;
      // case RETURN_THIS:
      //   break;
      default:
        debug() << "Unknown opcode " << opcode << endl;
        bail("opcode not implemented");
    }
}

std::pair<oop, oop> Process::lookup(oop drecv, oop vt, oop selector) {
  // assert( *(oop*) selector == _core_image->get_prime("Symbol"));
  if (vt == NULL) {
    return std::pair<oop, oop>(MM_NULL, MM_NULL);
  }

  // debug() << "lookup selector on vt: " << vt << " whose vt is " << _mmobj->mm_object_vt(*(oop*)vt) << endl;

  oop dict = _mmobj->mm_behavior_get_dict(vt);
  debug() << "Process::lookup dict: " << dict
          << " selector: " << _mmobj->mm_symbol_cstr(selector) << endl;

  if (_mmobj->mm_dictionary_has_key(dict, selector)) {
    oop fun = _mmobj->mm_dictionary_get(dict, selector);
    debug() << "Lookup of " << selector << " found in " << vt
            << " fun: " << fun << " drecv: " << drecv << endl;
    std::pair<oop,oop> res = std::pair<oop,oop>(drecv, fun);
    return res;
  } else {
    debug() << "Lookup of " << selector << " NOT found in " << vt << ", recursively looking up..." << endl;
    oop pklass = _mmobj->mm_object_delegate(vt);
    oop delegate = _mmobj->mm_object_delegate(drecv);
    return lookup(delegate, pklass, selector);
  }
}

oop Process::stack_pop() {
  oop val = * (oop*)_sp;
  _sp--;
  // debug() << "     POP " << val << " >> " << _sp << endl;
  return val;
}

void Process::stack_push(oop data) {
  _sp++;
  // debug() << "     PUSH " << data << " -> " << _sp << endl;
  * (word*) _sp = (word) data;
}

void Process::stack_push(word data) {
  _sp++;
  // debug() << "     PUSH " << data << " -> " << _sp << endl;
  * (word*) _sp = data;
}

void Process::stack_push(bytecode* data) {
  _sp++;
  // debug() << "     PUSH " << data << " -> " << _sp << endl;
  * (word*) _sp = (word) data;
}


int Process::execute_primitive(std::string name) {
  int val = _vm->get_primitive(name)(this);
  debug() << "primitive " << name << " returned " << val << endl;
  return val;
}


bool Process::unwind_with_exception(oop e) {
  debug() << "** unwind_with_exception e: " << e << " on cp: " << _cp << endl;
  if (_cp == NULL) {
    int exc;
    oop str = do_send_0(e, _vm->new_symbol("toString"), &exc);
    assert(exc == 0);
    std::cerr << "Terminated with exception: \""
              << _mmobj->mm_string_cstr(str) << "\"" << endl;
    bail();
  }

  debug() << "unwind_with_exception: " << _mmobj->mm_string_cstr(_mmobj->mm_function_get_name(_cp)) << endl;

  if (_mmobj->mm_function_is_prim(_cp)) {
    debug() << "->> unwind reached primitive " << _mmobj->mm_string_cstr(_mmobj->mm_function_get_prim_name(_cp)) << endl;
    return false;
  }

  bytecode* code = _mmobj->mm_function_get_code(_cp);

  number exception_frames_count = _mmobj->mm_function_exception_frames_count(_cp);
  if (exception_frames_count == 0) { //unable to handle
    pop_frame();
    return unwind_with_exception(e);
  }

  //exception frames are lexically ordered,
  //so iterating normally we always reach the innermost frame first
  oop exception_frames = _mmobj->mm_function_exception_frames(_cp);
  for(int i = 0; i < exception_frames_count; i++) {
    oop frame_begin = exception_frames + (4 * i);

    word try_block =  *(word*) frame_begin;
    word catch_block = *(word*) (frame_begin + 1);
    oop str_type_oop = *(oop*) (frame_begin + 3);

    oop type_oop;
    if (str_type_oop == MM_NULL) {
      type_oop  = MM_NULL;
    } else {
      debug() << "fetching exception type for name: " << str_type_oop << endl;
      int exc;
      type_oop = do_send_0(_mp, _vm->new_symbol(str_type_oop), &exc);
      assert(exc == 0);
      debug() << "fetching exception type got " << type_oop << endl;;
    }

    number instr = _ip - code;

    debug() << "RAISE instr: " << instr << " try: " << try_block
            << " catch: " << catch_block << " type: " << type_oop << endl;

    bool is_subtype = _mmobj->is_subtype(_mmobj->mm_object_vt(e), type_oop);
    debug() << "subtype == " << is_subtype  << endl;
    if (instr >= try_block && instr < catch_block &&
        (type_oop == MM_NULL || is_subtype)) {
      debug() << "CAUGHT " << endl;
      _ip = code + catch_block;
      return true;
    }
  }

  pop_frame();
  return unwind_with_exception(e);
}
