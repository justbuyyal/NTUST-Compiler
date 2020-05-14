# Compiler Project 1 ReadMe
---
### Environment
* Ubuntu 14.06
* WSL(Windows Subsystem Linux)
* flex
### MakeFile
```
all: my_lex lex

CC = gcc -o
LEX = my_lex.l
my_lex: my_lex.l
	flex $(LEX)
lex: lex.yy.c
	$(CC) parser -O lex.yy.c -ll

.PHONY: clean,run,test
clean:
	rm parser lex.yy.c
run:
	./parser example.scala
test:
	./parser HelloWorld.scala
```
### Build
```
make // build
./parser {FileName} // execute scanner
make run // execute scanner with testing code = example.scala
make test // execute scanner with testing code = HellowWorld.scala
```
### Remove
```
make clean // remove parser and lex.yy.c
```
### Main
```cpp=
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
```
---
###### tags: `Compiler` `編譯器`