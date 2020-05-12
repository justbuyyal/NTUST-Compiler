%{
#include <stdio.h>
#include <stdlib.h>
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
/* Symbol table */
typedef struct {
    int index;
    char *id_name;
    struct symbol *next;
}symbol;

typedef struct {
    int size;
    symbol *table;
}Symbol_table;

Symbol_table* create();
int lookup(char *, Symbol_table*);
int insert(char *, Symbol_table*);
void dump(Symbol_table*);

Symbol_table *new_table;

%}
number [+|-]?[0-9]+
identifier [a-zA-Z][a-zA-Z0-9]*
real [+|-]?[0-9]+.[0-9]+
delimiters [,|:|\.|;|\(|\)|\[|\]|\{|\}|=]
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
     /* copy identifier into symbol table */
    char *temp = malloc(sizeof(char)* yyleng);
    strcpy(temp, yytext);
    if(lookup(temp, new_table) == 0)
        insert(temp, new_table);
}
 /* integer */
{number}        {
    tokenInteger("integer", atoi(yytext));
}
 /* real number */
{real}          {
    tokenFloat("real", atof(yytext));
}
 /* string constant */
\"                          {BEGIN(STRING); LIST;}
<STRING>\"\"                {LIST; strcat(str_buf, "\"");}
<STRING>\n                  {LIST; printf("%d:%s\n", linenum, buf); printf("bad character:'\"'\n"); exit(-1);}
<STRING>[ \t]*              {LIST; strcat(str_buf, yytext);}
<STRING>[^\"\n]*            {LIST; strcat(str_buf, yytext);}
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
<<EOF>>                     {BEGIN(INITIAL); printf("%d: %s\n", linenum, buf); buf[0] = '\0'; return;}
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
Symbol_table *create()
{
    Symbol_table *new_symbol_table = malloc(sizeof(Symbol_table) * 1);
    new_symbol_table->size = 0;
    new_symbol_table->table = NULL;
    return new_symbol_table;
}
int lookup(char *s, Symbol_table *t)
{
    if(t->table == NULL)
    {
        return 0;
    }
    symbol *temp = t->table;
    while(temp != NULL)
    {
        if(strcmp(temp->id_name, s) == 0)
        {
            return temp->index;
        }
        temp = temp->next;
    }
    return 0;
}
int insert(char *s, Symbol_table *t)
{
    symbol *temp;
    if(t->table == NULL)
    {
        temp = malloc(sizeof(symbol) * 1);
        temp->id_name = s;
        temp->index = 1;
        temp->next = NULL;
        t->table = temp;
        t->size = 1;
        return 1;
    }
    temp = t->table;
    while(temp != NULL)
    {
        if(temp->next == NULL)
        {
            symbol *buf = malloc(sizeof(symbol) * 1);
            buf->id_name = s;
            buf->index = (temp->index + 1);
            buf->next = NULL;
            temp->next = buf;
            ++t->size;
            return buf->index;
        }
        temp = temp->next;
    }
}
void dump(Symbol_table *t)
{
    printf("Symbol Table:\n");
    symbol *temp = t->table;
    while(temp != NULL)
    {
        printf("%d: %s\n", temp->index, temp->id_name);
        temp = temp->next;
    }
}
int main(int argc, char *argv[])
{
    /* using yyin to read input file by lex */
    if(argc != 2) return -1;
    yyin = fopen(argv[1], "r");
    /* create symbol_table */
    new_table = create();
    /* read input file */
    yylex();
    fclose(yyin);
    dump(new_table);
    free(new_table);
    return 0;
}