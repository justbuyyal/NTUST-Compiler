all: my_lex lex

CC = gcc -o
LEX = my_lex.l
my_lex: my_lex.l
	flex $(LEX)
lex: lex.yy.c
	$(CC) a.out -O lex.yy.c -ll

.PHONY: clean,run,test,yy
clean:
	rm a.out lex.yy.c
run:
	./a.out
test:
	cat testing.scala | ./a.out
yy:
	cat yy.scala | ./a.out