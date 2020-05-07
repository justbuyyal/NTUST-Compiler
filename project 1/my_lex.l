%{
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#define MAX_LINE_LENG 256
#define LIST strcat(buf,yytext)
#define token(t) {LIST; printf("<'%s'>\n",t);}
#define tokenInteger(t,i) {LIST; printf("<%s:%d>\n",t,i);}
#define tokenFloat(t,f) {LIST; printf("<%s:%f>\n",t,f);}
#define tokenString(t,s) {LIST; printf("<%s:%s>\n",t,s);}
int linenum = 1;
char buf[MAX_LINE_LENG];
char str_buf[MAX_LINE_LENG];
void create();
int lookup(string s);
int insert(string s);
int dump();
%}
number [+|-]?[0-9]+
identifier [a-zA-Z][a-zA-Z0-9]*
real [+|-]?[0-9]+.[0-9]+
delimiters [,|:|\.|;|\(|\)|\[|\]|\{|\}]
arithmetic [\+|\-|\*|\/]
relational \<|<=|>=|==|!=|\>
logical &&|\|\||!
keywords boolean|break|char|case|class|continue|def|do|else|exit|float|for|if|int|null|object|print|println|repeat|return|string|to|type|val|var|while
boolean true|false

 // Create a state for comment
%x COMMENT
%x STRING

%%
 /* Delimiters */
{delimiters}    {token(yytext);}
 /* arithmetic */
{arithmetic}    {token(yytext);}
 /* remainder */
%               {token("%");}
 /* relational */
{relational}    {token(yytext);}
 /* logical */
{logical}       {token(yytext);}
 /* keywords */
{keywords}      {
     /* create a dynamic char array to save keywords string */
    char *temp = malloc(sizeof(char) * yyleng);
    strcpy(temp, yytext);
     /* make every words to upper */
    for(int i=0; i<yyleng; i++) temp[i] = toupper(temp[i]);
    token(temp);
}
 /* boolean constant */
{boolean}       {
     /* create a dynamic char array to save boolean */
    char *temp = malloc(sizeof(char) * yyleng);
    strcpy(temp, yytext);
     /* make every words to upper */
    for(int i=0; i<yyleng; i++) temp[i] = toupper(temp[i]);
    tokenString("BOOLEAN", temp);
}
 /* identifier */
{identifier}    {
    tokenString("identifier", yytext);
}
 /* integer */
{number}        {
    tokenInteger("integer", atoi(yytext));
}
 /* real number */
{real}          {
    tokenFloat("REAL", atof(yytext));
}
 /* string constant */
\"                          {BEGIN(STRING); LIST;}
<STRING>\"\"                {LIST; strcat(str_buf, "\"");}
<STRING>[ \t]*              {LIST; strcat(str_buf, yytext);}
<STRING>[^\"]*              {LIST; strcat(str_buf, yytext);}
<STRING>\"                  {BEGIN(INITIAL); tokenString("string", str_buf); str_buf[0] = '\0';}
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
<<EOF>>                     {BEGIN(INITIAL); printf("%d: %s\n", linenum, buf); buf[0] = '\0'; exit(0);}
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
int main()
{
    while(yylex());
    return 0;
}