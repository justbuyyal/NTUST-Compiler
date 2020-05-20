all: scanner lex.yy.o symbols.o parser

CC = gcc -o
LEX = my_lex.y

scanner: lex.yy.o symbols.o
	$(CC) p lex.yy.o symbols.o -ll

lex.yy.o: my_lex.y
	flex my_lex.y
	gcc -c -g lex.yy.c

symbols.o: symbols.c symbols.h
	gcc -c -g symbols.c

.PHONY: clean
clean:
	rm -f *.o lex.yy.c