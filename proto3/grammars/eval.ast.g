exec_fun = exprlist:x -> x
         | [['primitive' ['literal-string' :name]]:ast (:ignore)*]   -> self.i.do_eval('eval_prim', name,ast)

exprlist = [(expr:x)+] -> x
         | [] -> None

pair = ['pair' expr:key expr:val] -> (key,val)

expr = ['super-ctor-send' :s args:a]:ast     -> self.i.do_eval('eval_do_super_ctor_send',s,a,ast)
     | ['super-send' args:a]:ast             -> self.i.do_eval('eval_do_super_send',a,ast)
     | ['var-def' :id expr:e]:ast            -> self.i.do_eval('eval_do_var_def',id,e,ast)
     | ['return' expr:x]:ast                 -> self.i.do_eval('eval_do_return',x,ast)
     | ['non-local-return' expr:x]:ast       -> self.i.do_eval('eval_do_non_local_return',x,ast)
     | ['not' expr:x]:ast                    -> self.i.do_eval('eval_do_un_not',x,ast)
     | ['negative' expr:x]:ast               -> self.i.do_eval('eval_do_un_neg',x,ast)
     | ['and' expr:x :y]:ast                 -> self.i.do_eval('eval_do_and',x,y,ast)
     | ['++' expr:x expr:y]                  -> self.i.todo6()
     | ['+' expr:x expr:y]:ast               -> self.i.do_eval('eval_do_bin_send','+',x,y,ast)
     | ['-' expr:x expr:y]:ast               -> self.i.do_eval('eval_do_bin_send','-',x,y,ast)
     | ['*' expr:x expr:y]                   -> self.i.todo8()
     | ['<' expr:x expr:y]:ast               -> self.i.do_eval('eval_do_bin_send','<',x,y,ast)
     | ['<=' expr:x expr:y]:ast              -> self.i.do_eval('eval_do_bin_send','<=',x,y,ast)
     | ['>=' expr:x expr:y]:ast              -> self.i.do_eval('eval_do_bin_send','>=',x,y,ast)
     | ['==' expr:x expr:y]:ast              -> self.i.do_eval('eval_do_bin_send','==',x,y,ast)
     | ['!=' expr:x expr:y]:ast              -> self.i.do_eval('eval_do_bin_send','!=',x,y,ast)
     | ['call' expr:e args:a]:ast            -> self.i.do_eval('eval_do_call',e,a,ast)
     | ['setter' expr:r :s args:a]           -> self.i.todo14()
     | ['getter' expr:r :s]                  -> self.i.todo15()
     | ['send-or-call' :e args:a]:ast        -> self.i.do_eval('eval_do_send_or_call',e,a,ast)
     | ['send' expr:r :s args:a]:ast         -> self.i.do_eval('eval_do_send',r,s,a,ast)
     | ['index' expr:r expr:i]:ast           -> self.i.do_eval('eval_do_access_index',r,i,ast)
     | ['if' :c :yes]:ast
          apply('expr' c):cond               -> self.i.do_eval('eval_do_if',cond,yes)
     | ['if' :c :yes :no]:ast
          apply('expr' c):cond               -> self.i.do_eval('eval_do_if_else',cond,yes,no)
     | ['while' :cond :yes]:ast              -> self.i.do_eval('eval_do_while',cond,yes,ast)
     | ['try' :tr ['catch' :id] :ct]:ast     -> self.i.do_eval('eval_do_try',ast,tr,None,id,ct)
     | ['try' :tr ['catch' expr:type :id] :ct]:ast -> self.i.do_eval('eval_do_try',ast,tr,type,id,ct)
     | ['literal-array'  expr*:r]            -> r
     | ['literal-dict'  pair*:r]             -> dict(r)
     | ['fun-literal'  ['params' :p]
          ['body' :b]]:ast                   -> self.i.do_eval('eval_do_fun_lit',p,b,ast)
     | ['return-this']:ast                   -> self.i.do_eval('eval_do_return',self.i.reg('r_rp'),ast)
     | ['return-null']:ast                   -> self.i.do_eval('eval_do_return',None,ast)
     | ['return-top']                        -> self.i.todo26()
     | assignment
     | atom

assignment = ['=' ['id' :v] expr:rhs]:ast    -> self.i.do_eval('eval_do_local_assign',v,rhs,ast)
           | ['=' ['field' :f] expr:rhs]:ast -> self.i.do_eval('eval_do_field_assign',f,rhs,ast)

args =  ['args' arglist:x] -> x
     |  ['args' []] -> []

arglist = [expr+:lst] -> lst

atom = ['literal-string' :x]      -> x
    |  ['literal-number' :x]      -> x
    |  ['literal-symbol' :x]      -> self.i.do_eval("eval_symbol",x)
    |  ['literal' 'this']         -> self.i.do_eval('eval_access_this',)
    |  ['literal' 'null']         -> None
    |  ['literal' 'true']         -> True
    |  ['literal' 'false']        -> False
    |  ['literal' 'module']       -> self.i.do_eval('eval_access_module',)
    |  ['literal' 'context']      -> self.i.do_eval('eval_access_context',)
    |  ['id' :x]:ast              -> self.i.do_eval('eval_access_var',x,ast)
    |  ['field' :x]               -> self.i.do_eval('eval_access_field',x)