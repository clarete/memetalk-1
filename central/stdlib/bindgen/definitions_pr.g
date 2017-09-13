meme central:memescript/compiler

requires io, ometa_base
where
  io             = central:stdlib/io
  ometa_base     = central:memescript/ometa_base
import OMetaBase from ometa_base

class SyscallDefinitionsParser < OMetaBase

<ometa>

space =  _:c ?{c.onlySpaces} => c
      | comment;

comment = '//' 'sys';

start = definition*;

definition
    = func:f "\n"* => f
    | include:i "\n"* => i
    | struct_def:s "\n"* => s
    ;

include
    = "#" spaces "include" spaces "<" {~">" _}+:fname ">"
      => [:include, "<" + fname.join("") + ">"]
    | "#" spaces "include" spaces '"' {~'"' _}+:fname '"'
      => [:include, "\"" + fname.join("") + "\""]
    ;

struct_def
    = struct:s spaces struct_body:b
        !{s.append(b)} => s
    | struct:s => s
    ;

struct_body = "{" spaces struct_field*:fields "}" => fields;

struct_field = typed:t ``;`` => t;

func = rtype:rp spaces id:funcname spaces params:p
    => [:func, funcname, p, rp];

rtype = type_pointer | type;

params = "(" paramlist:pl ")" => pl;
paramlist = typed:x {"," spaces typed}*:xs => [x] + xs | => [];

typed = type_with_annotations | type_list_or_id;
type_with_annotations = type_list_or_id:x spaces type_annotation+:as
    => [[:annotations, x[0], as], x[1]];
type_annotation = "+" {``out`` | ``null``}:x =>  x;

type_list_or_id = type_list | type_id;
type_list = type_id:x '[]' => [[:list, x[0]], x[1]];
type_id = {type_pointer | type}:t spaces id:n => [t, n];
type_pointer = type:x spaces "*"+:star => [:pointer, x, star.size()];
type = unsigned | const | struct | builtins;

struct = ``struct`` spaces id:x => [:struct, x];
const = ``const`` spaces type:x => [:const, x];
unsigned = ``unsigned`` spaces type:x => [:unsigned, x];
builtins = {``void`` | ``int`` | ``float`` | ``short`` | ``long`` | ``char``}:x
    => [:builtin, x];

id = {letter | '_'}:x identifier_rest*:xs => ([x] + xs).join("");


</ometa>

end