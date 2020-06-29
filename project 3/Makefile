all: parser
CC = g++
LEX_FILE = lex_scala.l
YACC_FILE = yacc_proj3.y
TABLE = SymbolTable.h

parser: lex.yy.cc y.tab.cpp $(TABLE)
	$(CC) y.tab.cpp $(TABLE) -o parser -ll -ly -std=c++11 -Wno-deprecated-register

lex.yy.cc:
	lex -o lex.yy.cpp $(LEX_FILE)

y.tab.cpp:
	yacc $(YACC_FILE) -d -o y.tab.cpp

.PHONY: clean run del
clean:
	rm -f *.cc parser *.hpp *.cpp *.txt
run:
	./parser example.scala
	rm scala.txt
	./javaa/javaa scala.jasm
del:
	rm -f *.txt *.class *.jasm *.cc *.cpp *.hpp
