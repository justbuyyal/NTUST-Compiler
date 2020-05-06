all: my_lex lex

CC = gcc -o
LEX = my_lex.l
my_lex: my_lex.l
	flex $(LEX)
lex: lex.yy.c
	$(CC) a.out -O lex.yy.c -ll

.PHONY: clean,run
clean:
	rm a.out lex.yy.c
run:
	cat testing.scala | ./a.out
