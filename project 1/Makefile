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