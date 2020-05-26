%{
#include "SymbolTable.h"
#include "lex.yy.c"
#define Trace(t)    printf(t)

Symbol_list symboltables;
void yyerror(string msg)
{
    cout << msg << endl;
}
void DiffDataType()
{
    yyerror("Different Data Type !");
}
void SymbolAdd(Symbol* s)
{
    if(Symbol_list.insert(s) == -1)
    {
        string warning = "ID name : " + s->get_name() + "had already inserted";
        yyerror(warning);
    }
}
%}

%union {
    int ival;
    float fval;
    bool bval;
    char cval;
    string* strval;
    variable type;
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
%type <type> data_type return_type
/* operator precedence */
%left OR_OP
%left AND_OP
%left '!'
%left '<' '>' DE LE BE NE
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS
%%
const_var_dec:
    const_dec const_var_dec
    | var_dec const_var_dec
    | /* zero */;
optional_type:
    ':' data_type
    |;
const_dec:
    VAL ID optional_type '=' expression
    {
    };
var_dec:
    VAR ID optional_type
    {

    }|
    VAR ID optional_type '=' expression
    {

    }|
    VAR ID ':' data_type '[' INT_VAL ']'
    {
        // array declaration
    };
arg:
    ID ':' data_type;
args:
    arg
    | args ',' arg;
optional_args:
    args | /* zero */;
return_type:
    ':' data_type
    | /* zero */;
simple:
    ID '=' expression
    |ID '[' expression ']' '=' expression
    | PRINT '(' expression ')'
    | PRINTLN '(' expression ')'
    | READ ID
    | RETURN
    | RETURN expression;
expression:
    const_dec
    | ID
    | func_invocation
    | ID '[' expression ']'
    | '-' expression %prec UMINUS
    | expression '*' expression
    | expression '/' expression
    | expression '+' expression
    | expression '-' expression
    | expression '<' expression
    | expression '>' expression
    | expression LE expression
    {
        // <=
    }
    | expression BE expression
    {
        // >=
    }
    | expression DE expression
    {
        // ==
    }
    | expression NE expression
    {
        // !=
    }
    | '!' expression
    | expression AND_OP expression
    {
        // &&
    }
    | expression OR_OP expression
    {
        // ||
    };
comma_separated_exp:
    expression
    | comma_separated_exp ',' expression
    | /* zero */;
func_invocation:
    ID '(' comma_separated_exp ')';
block:
    '{' const_var_dec stmts '}';
block_or_simple:
    block
    | simple;
conditional:
    IF '(' expression ')' block_or_simple ELSE block_or_simple
    | IF '(' expression ')' block_or_simple;
loop:
    WHILE '(' expression ')' block_or_simple
    | FOR '(' ID '<' '-' INT_VAL TO INT_VAL ')' block_or_simple;
stmt:
    simple
    | expression
    | func_invocation
    | block
    | conditional
    | loop;
stmts:
    stmt 
    | stmts stmt
    | /* zero */;
method:
    DEF ID '(' optional_args ')' return_type
    {

    }'{' const_var_dec '}'
    {};
program:
    OBJECT ID
    {

    }'{' const_var_dec '}'
    {};
%%

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