%{
#include <stdio.h>
#include <string.h>
#define MAX_LINE_LENG 256
#define LIST strcat(buf,yytext)
#define token(t) {LIST; printf("<'%s'>\n",yytext);}
#define tokenInteger(t,i) {LIST; printf("<%s:%d>\n","int",i);}
#define tokenFloat(t,f) {LIST; printf("<%s:%f>\n","float",f);}
#define tokenString(t,s) {LIST; printf("<%s:%s>\n","id",s);}
int linenum = 0;
char buf[MAX_LINE_LENG];
%}
number [0-9]+
identifier [a-zA-Z][a-zA-Z0-9]*
real [0-9]+.[0-9]+

%%

","             {token(',');}
":"             {token(':');}
"."             {token('.');}
";"             {token(';');}
"("             {token('(');}
")"             {token(')');}
"["             {token('[');}
"]"             {token(']');}
"{"             {token('{');}
"}"             {token('}');}

"+"             {token('+');}
"-"             {token('-');}
"*"             {token('*');}
"/"             {token('/');}

"%"             {token('%');}

"<"             {token('<');}
"<="            {token('<=');}
">="            {token('>=');}
">"             {token('>');}
"=="            {token('==');}
"!="            {token('!=');}

"&&"            {token('&&');}
"||"            {token('||');}
"!"             {token('!');}

"boolean"       {token('boolean');}
"break"         {token('break');}
"char"          {token('char');}
"case"          {token('case');}
"class"         {token('class');}
"continue"      {token('continue');}
"def"           {token('def');}
"do"            {token('do');}
"else"          {token('else');}
"exit"          {token('exit');}
"false"         {token('false');}
"float"         {token('float');}
"for"           {token('for');}
"if"            {token('if');}
"int"           {token('int');}
"null"          {token('null');}
"object"        {token('object');}
"print"         {token('print');}
"println"       {token('println');}
"repeat"        {token('repeat');}
"return"        {token('return');}
"string"        {token('string');}
"to"            {token('to');}
"true"          {token('TRUE');}
"type"          {token('type');}
"val"           {token('val');}
"var"           {token('var');}
"while"         {token('while');}

{number}        {
    tokenInteger(number, atoi(yytext));
}

{identifier}    {
    tokenString(identifier, yytext);
}

{real}          {
    tokenFloat(real, atof(yytext));
}

\n              {
    LIST;
    printf("%d: %s", linenum, buf);
    linenum++;
    buf[0] = '\0';
}

[ \t]* {LIST;}

\"[.]*\"        {
    LIST;

}

"//"            {
    char x, set[1];
    while((x = yyinput()) != '\n')
    {
        set[0] = x;
        strcat(buf, set[0]);
    }
    printf("%d:%s\n", linenum, buf);
    linenum++;
    buf[0] = '\0';
}

.               {
    LIST;
    printf("%d:%s\n", linenum, buf);
    printf("bad character:'%s'\n",yytext);
    exit(-1);
}

%%
int main()
{
    while(yylex());
    return 0;
}