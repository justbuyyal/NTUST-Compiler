all: parser

CC = g++
LEX_FILENAME = lex_scala.l
YACC_FILENAME = yacc_scala.y
TABLE = SymbolTable.h

parser: lex.yy.cc y.tab.cpp SymbolTable.h
	$(CC) y.tab.cpp $(TABLE) -o parser -ll -ly -std=c++11 -Wno-deprecated-register

lex.yy.cc:
	flex -o lex.yy.cpp $(LEX_FILENAME)

y.tab.cpp:
	bison -d $(YACC_FILENAME) -o y.tab.cpp

.PHONY: clean
clean:
	rm -f *.cc *.c parser *.hpp *.cpp
