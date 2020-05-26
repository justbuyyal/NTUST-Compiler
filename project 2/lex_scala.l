%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "y.tab.h"

#define MAX_LINE_LENG 256
#define LIST strcat(buf,yytext)
#define token(t) {LIST; return(t);}
#define tokenOP(t) {LIST; return(t);}
#define tokenDoubleOP(t) {LIST;}

int linenum = 1;
char buf[MAX_LINE_LENG];
char str_buf[MAX_LINE_LENG];

%}
DIGIT [0-9]
NUMBER {DIGIT}+
IDENTIFIER [a-zA-Z][a-zA-Z0-9]*
REAL [+-]?{NUMBER}"."{NUMBER}([Ee][+-]?{NUMBER})?
DELIMITERS [,|:|\.|;|\(|\)|\[|\]|\{|\}|=]
ARITHMETIC [\+|\-|\*|\/%]
RELATIONAL [\>|\<]
LOGICAL !

 // Create a state for comment
%x COMMENT
%x STRING

%%
 /* Double Operator */
"=="            {tokenDoubleOP("=="); return DE;}
"<="            {tokenDoubleOP("<="); return LE;}
">="            {tokenDoubleOP(">="); return BE;}
"!="            {tokenDoubleOP("!="); return NE;}
"&&"            {tokenDoubleOP("&&"); return AND_OP;}
"||"            {tokenDoubleOP("||"); return OR_OP;}
 /* Delimiters */
{DELIMITERS} |
 /* arithmetic */
{ARITHMETIC} |
 /* relational */
{RELATIONAL} |
 /* logical */
{LOGICAL}       {tokenOP(*yytext);} // Single operator
 /* keywords */
boolean         {token(BOOLEAN);}
break           {token(BREAK);}
char            {token(CHAR);}
case            {token(CASE);}
class           {token(CLASS);}
continue        {token(CONTIUNE);}
def             {token(DEF);}
do              {token(DO);}
else            {token(ELSE);}
exit            {token(EXIT);}
float           {token(FLOAT);}
for             {token(FOR);}
if              {token(IF);}
int             {token(INT);}
null            {token(NULL);}
object          {token(OBJECT);}
print           {token(PRINT);}
println         {token(PRINTLN);}
repeat          {token(REPEAT);}
return          {token(RETURN);}
string          {token(STRING);}
to              {token(TO);}
type            {token(TYPE);}
val             {token(VAL);}
var             {token(VAR);}
while           {token(WHILE);}
 /* boolean value */
true            {
    LIST;
    yylval.bval = true;
    return BOOL_VAL;
}
false           {
    LIST;
    yylval.bval = false;
    return BOOL_VAL;
}
 /* identifier */
{IDENTIFIER}    {
    yylval.strval = new string(yytext);
    return ID;
}
 /* integer */
{NUMBER}        {
    yylval.ival = atoi(yytext);
    return INT_VAL;
}
 /* real number */
{REAL}          {
    double temp;
    sscanf(yytext, "%lf", temp);
    yylval.fval = temp;
    return FLOAT_VAL;
}
 /* string constant */
\"                          {BEGIN(STRING); LIST;}
<STRING>\"\"                {LIST; strcat(str_buf, "\"");}
<STRING>\n                  {LIST; printf("%d:%s\n", linenum, buf); printf("bad character:'\"'\n"); exit(-1);}
<STRING>[ \t]*              {LIST; strcat(str_buf, yytext);}
<STRING>[^\"\n]*            {LIST; strcat(str_buf, yytext);}
<STRING>\"                  {BEGIN(INITIAL); yylval.strval = new string(str_buf); str_buf[0] = '\0'; return STR_VAL;}
 /* comment */
"//"            {
    strcat(buf, "//");
    char temp, x[1];
    while((temp = input()) != '\n')
    {
        x[0] = temp;
        strcat(buf, x);
    }   
    printf("%d:%s\n", linenum, buf);
    linenum++;
    buf[0] = '\0';
}
 /* comment for mutiple line */
"/*"                        {BEGIN(COMMENT); LIST;}
<COMMENT>"*/"               {BEGIN(INITIAL); LIST;}
<COMMENT>"\n"               {LIST; printf("%d: %s", linenum, buf); buf[0] = '\0'; linenum++;}
<COMMENT>.                  {LIST;}
<<EOF>>                     {BEGIN(INITIAL); printf("%d: %s\n", linenum, buf); buf[0] = '\0';}
 /* newline */
\n              {
    LIST;
    printf("%d: %s", linenum, buf);
    linenum++;
    buf[0] = '\0';
}
 /* space */
[ \t]* {LIST;}

.               {
    LIST;
    printf("%d:%s\n", linenum, buf);
    printf("bad character:'%s'\n",yytext);
    exit(-1);
}
%%