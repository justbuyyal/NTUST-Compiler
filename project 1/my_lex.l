%{
#include <stdio.h>
#define MAX_LINE_LENG 256
#define LIST strcat(buf,yytext)
#define token(t) {LIST; printf("<%s>\n","t");}
#define tokenInteger(t,i) {LIST; printf("<%s:%d>\n","t",i);}
#define tokenString(t,s) {LIST; printf("<%s:%s>\n","t",s);}
int linenum = 0;
char buf[MAX_LINE_LENG];
%}
number [0-9]+
identifier [a-zA-Z][a-zA-Z0-9]*
real [0-9]+.[0-9]+

%%
"," {token(’,’);}
":" {token(’:’);}
"." {token(’.’);}
";" {token(’;’);}
"(" {token(’(’);}
")" {token(’)’);}

\n {
LIST;
printf("%d: %s", linenum, buf);
linenum++;
buf[0] = ’\0’;
}
[ \t]* {LIST;}
. {
LIST;
printf("%d:%s\n", linenum, buf);
printf("bad character:’%s’\n",yytext);
exit(-1);
}
%%