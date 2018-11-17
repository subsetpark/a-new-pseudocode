Nonterminals
a_symbol
symbols
expression
expressions
maybe_expressions
list
set
bunch
bin_operation
un_operation
function_application
term
program
section
head
head_line
declaration
decl_body
decl_args
decl_guard
decl_yield
alias
body
body_line.

Terminals
'{' '}' '[' ']' '(' ')' '.' ':' ';' ','
int literal float
comment
newline
symbol
binary_operator
unary_operator
yield_type
reverse_yield.

Rootsymbol program.

Left 100 binary_operator.
Left 300 unary_operator.

%
% RULES
%

program -> section : '$1'.

section -> head : [{head, '$1'}].
section -> head body : [{head, '$1'}, {body, '$2'}].

%
% head
%

head -> head_line : ['$1'].
head -> head_line head : ['$1' | '$2'].

head_line -> declaration newline : '$1'.
head_line -> alias newline : '$1'.
head_line -> comment newline : unwrap('$1').

% i. declarations

declaration ->
    a_symbol '(' decl_body ')' decl_yield  : {declaration,
        [{decl_ident, '$1'}|'$3' ++ '$5']
    }.

decl_body -> '$empty' : [].
decl_body -> decl_args : [{decl_args, '$1'}].
decl_body -> decl_args '.' decl_guard : [{decl_args, '$1'}, {decl_guards, '$3'}].

decl_args -> symbols ':' symbols : [{args, '$1'}, {doms, '$3'}].

decl_guard -> expressions : '$1'.

decl_yield -> '$empty' : [].
decl_yield -> yield_type a_symbol : [{decl_yield, unwrap('$1')}, {decl_domain, '$2'}].

% ii. aliases

alias -> symbols reverse_yield expression : {alias, [{alias_name, '$1'}, {alias_expr, '$3'}]}.

%
% body
%

body -> body_line : ['$1'].
body -> body_line body : ['$1' | '$2'].

body_line -> expression newline : '$1'.

% EXPRESSION PRECEDENCE
% This is a strange area. Here are the precedence levels of Pantagruel:
%
% Expression < Binary Operation < Function Application < Unary Operation.
%
% This is represented in the parse by a series of rules which evaluate
% either to themselves or the next most tightly binding level.
% Source: http://journal.stuffwithstuff.com/2008/12/28/fixing-ambiguities-in-yacc/

expression -> bin_operation : '$1'.

bin_operation ->
    function_application : '$1'.
bin_operation ->
    function_application binary_operator function_application : {appl, [{op, unwrap('$2')}, {x, '$1'}, {y, '$3'}]}.

function_application ->
    un_operation : '$1'.
function_application ->
    function_application un_operation : {appl, [{f, '$1'}, {x, '$2'}]}.

un_operation ->
    term : '$1'.
un_operation ->
    unary_operator un_operation : {appl, [{op, unwrap('$1')}, {x, '$2'}]}.

term -> a_symbol : '$1'.
term -> int : unwrap('$1').
term -> float : unwrap('$1').
term -> literal : unwrap('$1').
term -> list : '$1'.
term -> set : '$1'.
term -> bunch : '$1'.

%
% END EXPRESSION PRECEDENCE
%

bunch -> '(' maybe_expressions ')' : '$2'.
list -> '[' maybe_expressions ']' : {list, '$2'}.
set -> '{' maybe_expressions '}' : {set, '$2'}.

expressions -> expression : ['$1'].
expressions -> expression ',' expressions : ['$1' | '$3'].

maybe_expressions -> '$empty' : [].
maybe_expressions -> expressions : '$1'.

symbols -> a_symbol : ['$1'].
symbols -> a_symbol ',' symbols : ['$1' | '$3'].

a_symbol -> symbol : unwrap('$1').

Erlang code.

unwrap({comment, _, Symbol}) -> {comment, Symbol};
unwrap({_, _, Symbol}) -> Symbol.
