#include "vm.hpp"
#include "process.hpp"
#include "core_image.hpp"
#include "mmc_image.hpp"
#include "defs.hpp"
#include "mmobj.hpp"
#include "prims.hpp"
#include "report.hpp"
#include <assert.h>
#include "utils.hpp"
#include "mmc_fun.hpp"

VM::VM(int argc, char** argv, bool online, const char* core_img_filepath)
  : _argc(argc), _argv(argv), _online(online),
    _core_image(new CoreImage(this, core_img_filepath)), _mmobj(new MMObj(_core_image)) {
}

MMObj* VM::mmobj() {
  return _mmobj;
}

void VM::dictionary_dump(oop dict) {
  number size = _mmobj->mm_dictionary_size(dict);

  debug() << "  dict vt: " << _mmobj->mm_object_vt(dict) << endl;
  debug() << "  dict size: " << size << endl;
  for (int i = 3; i < (3 + (size*2)); i++) {
    debug() << "  [" << i << "]: & " << &((oop*)dict)[i];
    debug() << endl;
    // debug() << " vt:" << * ((oop**)dict)[i]  << endl;
  }
}

void VM::dump_prime_info() {
  std::map<std::string, oop> primes = _core_image->get_primes();
  std::map<std::string, oop>::iterator it;
  for (it = primes.begin(); it != primes.end(); it++) {
    if (it->first == "Behavior" || it->first == "Object_Behavior") continue;
    oop klass = it->second;
    debug() << "PRIME " << klass << " name: " << _mmobj->mm_string_cstr(_mmobj->mm_class_name(klass)) << " vt: "
            << _mmobj->mm_object_vt(klass) << " dict:" << _mmobj->mm_class_dict(klass) << endl;
    dictionary_dump(_mmobj->mm_class_dict(klass));
  }
}

void VM::print_retval(oop retval) {
  int exc;
  debug() << " ======== the end ======= " << endl;
  oop retval_str = _process->send_0(retval, new_symbol("toString"), &exc);
  debug() << "RETVAL: " << retval << " => " << _mmobj->mm_string_cstr(retval_str) << endl;
}

int VM::start() {
  if (_argc != 2) {
    bail("usage: sf-vm <file.mmc>");
  }

  _process = new Process(this);

  init_primitives(this); //module initialization could execute primitives

  char* filepath = _argv[1];


  _core_image->load();
  // dump_prime_info();

  oop imod;
  try {
    imod = instantiate_module(_process, filepath, _mmobj->mm_list_new());
  } catch(mm_rewind e) {
    print_retval(e.mm_exception);
    return * (int*) (void*) &(e.mm_exception);
  }

  oop retval = _process->run(imod, new_symbol("main"));
  print_retval(retval);
  return * (int*) (void*) &retval;
}

std::pair<Process*, oop> VM::start_debugger(Process* target) {
  oop imod;
  Process* dbg_proc = new Process(this);
  dbg_proc->is_debugger(true); //to help filter logs
  try {
    imod = instantiate_module(dbg_proc, "idez", _mmobj->mm_list_new());
  } catch(mm_rewind e) {
    bail("VM::start_debugger raised");
    // print_retval(e.mm_exception);
    // return * (int*) (void*) &(e.mm_exception);
  }

  oop oop_target_proc = _mmobj->mm_process_new(target);
  int exc;
  oop handler = dbg_proc->send_1(imod, new_symbol("debug"), oop_target_proc, &exc);
  if (exc != 0) {
    bail("VM::start_debugger: debug() raised");
  }
  return std::pair<Process*, oop>(dbg_proc, handler);
}

oop VM::new_symbol(const char* cstr) {
  std::string s = cstr;
  if (_symbols.find(s) == _symbols.end()) {
    _symbols[s] = _mmobj->mm_symbol_new(cstr);
    debug() << "new_symbol: Creating new symbol " << cstr << " = " << _symbols[s] << endl;
  } else {
    debug() << "new_symbol: returning existing symbol " << cstr << " = " << _symbols[s] << endl;
  }
  return _symbols[s];
}

oop VM::new_symbol(oop str) {
  assert(_mmobj->mm_object_vt(str) == _core_image->get_prime("String"));
  return new_symbol(_mmobj->mm_string_cstr(str));
}

void VM::register_primitive(std::string name, prim_function_t fun) {
  _primitives[name] = fun;
}

prim_function_t VM::get_primitive(std::string name) {
  debug() << "VM::get_primitive " << name << endl;
  assert(_primitives.find(name) != _primitives.end());
  return _primitives[name];
}

oop VM::instantiate_module(Process* proc, const char* name_or_path, oop module_args_list) {
  MMCImage* mmc = new MMCImage(proc, _core_image, name_or_path);
  mmc->load();
  return mmc->instantiate_module(module_args_list);
}

oop VM::get_prime(const char* name) {
  return _core_image->get_prime(name);
}

#include <iostream>
#include <cstdio>
#include <sstream>
#include <boost/iostreams/stream.hpp>
#include <boost/iostreams/device/file_descriptor.hpp>

#include <sstream>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>
using boost::property_tree::ptree;
using boost::property_tree::read_json;
using boost::property_tree::write_json;

static
std::string get_compile_fun_json(const char* text, oop vars, MMObj* mmobj) {
  ptree pt;
  ptree env;

  if (vars != MM_NULL) {
    std::map<oop,oop>::iterator it = mmobj->mm_dictionary_begin(vars);
    std::map<oop,oop>::iterator end = mmobj->mm_dictionary_end(vars);
    for ( ; it != end; it++) {
      oop name = it->first;
      char* str_name = mmobj->mm_symbol_cstr(name);
      env.push_back(std::make_pair("", str_name));
    }
  }

  pt.put ("text", text);
  pt.add_child("env_names",  env);
  std::ostringstream buf;
  write_json (buf, pt, false);
  return buf.str();
}

oop VM::compile_fun(const char* text, oop vars, oop /*cmod*/, int* exc) {
  std::stringstream s;
  std::string json = get_compile_fun_json(text, vars, _mmobj);

  s << "python -m pycompiler.compiler -o '" << json << "'";
  debug() << "Executing python compiler: " << s.str() << endl;

  *exc = 0;
  if (FILE* p = popen(s.str().c_str(), "r")) {
    boost::iostreams::file_descriptor_source d(fileno(p), boost::iostreams::close_handle);
    boost::iostreams::stream_buffer<boost::iostreams::file_descriptor_source> pstream(d);
    std::stringstream out;
    out << &pstream;
    std::string data = out.str();

    char* c_data = (char*) calloc(sizeof(char), data.size());
    data.copy(c_data, data.size());
    if (pclose(p) == 0) {
      MMCFunction* mmcf = new MMCFunction(this, _core_image, c_data, data.size());
      return mmcf->load();
    } else {
      *exc = 1;
      return _process->mm_exception("CompileError", c_data);
    }
  }
  *exc = 1;
  return _process->mm_exception("CompileError", "pipe error: Unable to call compiler");
}
