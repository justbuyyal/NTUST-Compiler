all: scanner lex.yy.o symbols.o

CC = gcc

scanner: lex.yy.o symbols.o
	$(CC) p lex.yy.o symbols.o -ll

lex.yy.o: my_lex.y
	flex my_lex.y
	$(CC) -c -g lex.yy.c

symbols.o: symbols.c symbols.h
	$(CC) -c -g symbols.c

.PHONY: clean
clean:
	rm -f *.o lex.yy.c y.tab.h

.PHONY: run