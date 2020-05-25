%{
#include "SymbolTable.h"
#include "lex.yy.c"
#define Trace(t)    printf(t)

Symbol_list symboltables;
void yyerror(string msg);
%}

%union {
    int ival;
    float fval;
    bool bval;
    char cval;
    string* strval;
    variable varType;
    Value value;
}
/* tokens */
// keywords
%token SEMICOLON BOOLEAN BREAK CHAR CASE CLASS CONTINUE DEF DO ELSE EXIT FALSE FLOAT FOR IF INT NULL OBJECT PRINT PRINTLN REPEAT RETURN STRING TO TRUE TYPE VAL VAR WHILE
// token assign
%token <bval> BOOL_VAL
%token <ival> INT_VAL
%token <cval> CHAR_VAL
%token <fval> FLOAT_VAL
%token <strval> STR_VAL
%token <strval> ID
// declare nonterminal
%type <varType> data_type
%type <value> expression const_value
/* operator precedence */
%left OR_OP
%left AND_OP
%left '!'
%left '<' '>' DE LE BE NE
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS
%%
const_value:
    INT_VAL
    {
        Value *i = new Value(INT);
        i->as_int($1);
        $$ = i;
    }|
    FLOAT_VAL
    {
        Value *i = new Value(FLOAT);
        i->as_float($1);
        $$ = i;
    }|
    BOOL_VAL
    {
        Value *i = new Value(BOOL);
        i->as_bool($1);
        $$ = i;
    }|
    CHAR_VAL
    {
        Value *i = new Value(CHAR);
        i->as_char($1);
        $$ = i;
    }|
    STR_VAL
    {
        Value *i = new Value(STRING);
        i->as_str($1);
        $$ = i;
    };
const_and_var_dec:
    const_dec const_and_var_dec
    | var_dec const_and_var_dec
    |; /* empty */
data_type:
    BOOLEAN
    {
        $$ = BOOL;
    }|
    INT
    {
        $$ = INT;
    }|
    CHAR
    {
        $$ = CHAR;
    }|
    FLOAT
    {
        $$ = FLOAT;
    }|
    STRING
    {
        $$ = STRING;
    };
optional_type:
    ':' data_type
    {
        $$ = $2;
    }|
    {
        $$ = NONE;
    };
const_dec:
    VAL ID optional_type '=' expression
    {
        
    };
var_dec:
    VAR ID optional_type
    {
    }|
    VAR ID '=' expression
    {
    }|
    VAR ID ':' data_type '=' expression
    {
    }|
    VAR ID ':' data_type '[' INT_VAL ']'
    {
        /* array type */
    };
arg:
    ID ':' data_type
    {
    };
args:
    arg
    {}|
    args ',' arg
    {}|
    /* empty */
    {};
methods:
    method_dec methods
    | method_dec;
method_dec:
    DEF ID '(' args ')' optional_type
    {
    } '{' const_and_var_dec stmts '}'
    {
    };
program:
    OBJECT ID '{' const_and_var_dec methods '}'
    {
    }
;
stmts:
    /* empty stmts */
    | stmt stmts;
stmt:
    simple_stmt
    | block
    | conditional
    | loop;
simple_stmt:
    ID '=' expression
    {

    }|
    ID '[' expression ']' '=' expression
    {

    }
    | PRINT '(' expression ')'
    | PRINTLN '(' expression ')'
    |
    READ ID
    {

    }
    | RETURN expression
    | RETURN;
expression:
    ID
    {}|
    '-' expression %prec UMINUS
    {}|
    expression '*' expression
    {}|
    expression '/' expression
    {}|
    expression '+' expression
    {}|
    expression '-' expression
    {}|
    expression '<' expression
    {}|
    expression LE expression
    {}|
    expression DE expression
    {}|
    expression BE expression
    {}|
    expression '>' expression
    {}|
    expression NE expression
    {}|
    '!' expression
    {}|
    expression AND_OP expression
    {}|
    expression OR_OP expression
    {}|
    ID '[' expression ']'
    {}|
    fun_invocation
    {
    }|
    data_type
    {
    };
fun_invocation:
    ID '(' comma_separated_exp ')'
    {
    };
comma_separated_exp:
    expression
    {}|
    comma_separated_exp ',' expression
    {}| /* empty */
    {};
block:
    '{' const_and_var_dec stmts'}';
block_or_simp_stmt:
    block | simple_stmt;
conditional:
    IF '(' expression ')' block_or_simp_stmt ELSE block_or_simp_stmt    
    {

    }|
    IF '(' expression ')' block_or_simp_stmt
    {

    };
loop:
    WHILE '(' expression ')' block_or_simp_stmt
    {}|
    FOR '(' ID '<' '-' INT_VAL TO INT_VAL ')' block_or_simp_stmt
    {};
%%

void DiffDataType()
{
    yyerror("Different Data Type !");
}

void yyerror(string msg)
{
    cout << msg << endl;
}

int main(int argc, char* argv[])
{
    /* open the source program file */
    if (argc != 2) {
        printf ("Usage: sc filename\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */

    /* perform parsing */
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error !");     /* syntax error */
}