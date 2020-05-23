%{
#include "SymbolTable.h"
#include "lex.yy.c"
#define Trace(t)    printf(t)

SymbolTable tables = SymbolTable();
void yyerror(string msg);
%}

%union {
    int ival;
    float fval;
    bool bval;
    char cval;
    string* strval;
}
/* tokens */
// keywords
%token SEMICOLON BOOLEAN BREAK CHAR CASE CLASS CONTINUE DEF DO ELSE EXIT FALSE FLOAT FOR IF INT NULL OBJECT PRINT PRINTLN REPEAT RETURN STRING TO TRUE TYPE VAL VAR WHILE
%token DE LE BE NE OR_OP AND_OP
// token assign
%token <bval> BOOL_VAL
%token <ival> INT
%token <cval> CHAR
%token <fval> FLOAT
%token <strval> STR_VAL
%token <strval> ID
/* operator precedence */
%left OR_OP
%left AND_OP
%left '!'
%left '<' '>' DE LE BE NE
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS
%%
program:        identifier semi
                {
                Trace("Reducing to program\n");
                }
                ;

semi:           SEMICOLON
                {
                Trace("Reducing to semi\n");
                }
                ;
%%

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