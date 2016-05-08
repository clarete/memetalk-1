#ifndef PROCESS_HPP
#define PROCESS_HPP

#include <string>
#include <map>
#include <list>
#include <fstream>

#include "defs.hpp"
#include "log.hpp"

class VM;
class MMObj;
class ProcessControl;

typedef std::pair<bytecode*,bytecode*> bytecode_range_t;

class mm_exception_rewind {
public:
  mm_exception_rewind(oop ex) : mm_exception(ex) {}
  oop mm_exception;
};

class mm_frame_rewind {
public:
  mm_frame_rewind(oop fp) : mm_frame(fp) {}
  oop mm_frame;
};


class Process {
  enum {
    INVALID_STATE,
    RUN_STATE,
    STEP_INTO_STATE,
    STEP_OVER_STATE,
    STEP_OUT_STATE,
    REWIND_STATE,
    HALT_STATE
  };


public:
  Process(VM*, int debugger_id = 0);

  oop run(oop, oop, int*);

  int read_eval_loop();

  bool is_running() { return _state == RUN_STATE; }

  void fail(oop e);

  VM* vm() { return _vm; }
  oop sp() { return _sp; }
  oop fp() { return _fp; }
  oop cp() { return _cp; }
  oop mp() { return _mp; }
  oop bp() { return _bp; }
  bytecode* ip() { return _ip; }

  oop rp();
  oop dp();

  oop set_rp(oop);
  oop set_dp(oop);

  oop get_arg(number idx);
  oop cp_from_base(oop bp);
  oop fp_from_base(oop bp);
  bytecode* ip_from_base(oop bp);

  // oop get_rp() { return _rp; };
  // oop get_dp() { return _dp; };

  MMObj* mmobj() { return _mmobj; }

  void stack_push(oop);
  void stack_push(word);
  void stack_push(bytecode*);

  oop current_exception() { return _current_exception; }

  oop unwind_with_exception(oop);

  // oop do_call_protected(oop, int*);
  oop call(oop, oop, int*);
  oop do_call(oop, int*);

  oop send_0(oop recv, oop selector, int* exc);
  oop send_1(oop recv, oop selector, oop arg, int* exc);
  oop send(oop recv, oop selector, oop args, int* exc);
  oop do_send(oop recv, oop selector, int num_args, int *exc);

  std::pair<oop,oop> lookup(oop, oop, oop);

  void raise(const char*, const char*);
  oop mm_exception(const char*, const char*);

  void maybe_debug_on_raise(oop);
  void halt_and_debug();
  void step_into();
  void step_over();
  void step_over_line();
  void step_out();
  void resume();
  void reload_frame();

  word* stack() { return _stack; };
  unsigned int stack_depth();
  oop bp_at(unsigned int);

  void bail(const std::string& msg);
  void bail();

  void unload_fun_and_return(oop retval);

  bool has_debugger_attached();

  void clear_exception_state();

  void break_at_addr(bytecode*);
  void rewind_to_frame_and_continue(oop frame);

  oop protected_fetch_cycle(oop recv, oop drecv, oop fun, int* exc, bool should_allocate);
  void unwind_with_frame(oop frame);

private:
  std::string log_label();
  std::string dump_code_body();
  std::string dump_stack_top();
  const char* meme_curr_fname();

  void init();

  bool load_fun(oop, oop, oop, bool);


  oop stack_pop();
  int execute_primitive(std::string);
  void fetch_cycle(void*);

  void push_frame(oop,oop,number, number);
  void pop_frame();

  oop ctor_rdp_for(oop rp, oop cp);

  void setup_fp(number, number);
  void copy_params_to_env(oop, number, number);
  void restore_fp(oop, number, number);

  void dispatch(int, int);
  void handle_send(number);
  void handle_super_ctor_send(number);
  void handle_call(number);
  void handle_return(oop);
  void basic_new_and_load(oop);

  bool exception_has_handler(oop e, oop bp);

  void tick();
  void maybe_break_on_call();
  void maybe_break_on_return();
  void maybe_break_on_exception();

  MMLog _log;
  int _debugger_id;
  VM* _vm;
  MMObj* _mmobj;

  int _state;
  bool _unwinding_exception;
  ProcessControl* _control;
  std::pair<Process*, oop> _dbg_handler;

  //this order is important: it reflects the order of registers
  //in the stack, and is used by bp_at()
  oop _fp;
  oop _cp;
  bytecode* _ip;
  number _ss;
  oop _bp;
  //
  oop _mp;
  word* _sp;

  word* _stack;
  unsigned int _stack_depth;
  number _code_size;
  std::list<bytecode_range_t> _volatile_breakpoints;
  oop _step_bp;
  oop _unwind_to_bp;
  oop _current_exception;
};

#endif
