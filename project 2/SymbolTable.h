#include <iostream>
#include <string>
#include <vector>

using namespace std;

// type of value
enum valueType
{
    INT,
    FLOAT,
    BOOL,
    CHAR,
    STRING,
    NONE
};

// type of identifier
enum idType
{
    CONST,
    VARIABLE,
    ARRAY,
    FUNCTION,
    OBJECT
};

class Symbol
{
    private:
        /* data */
        string name;
        valueType type;
        class Symbol *next;
    public:
        Symbol(string s):name(s), next(NULL), type(INT){};
        ~Symbol(){free(this->next);};
        Symbol(string s, valueType t):name(s), next(NULL), type(t){};
};

class SymbolTable
{
    private:
        /* data */
        Symbol *first;
        class SymbolTable *next;
    public:
        SymbolTable(/* args */):first(NULL), next(NULL){};
        ~SymbolTable(){free(this->first); free(this->next);};
        SymbolTable(string s):first(Symbol(s)), next(NULL){};
        void insert(Symbol* t){
            first = t;
        };
        void lookup(){
            int tcount = 0;
            SymbolTable* Ttemp = this;
            Symbol* stemp = this->first;
            if(this != NULL)
            {
                while(Ttemp != NULL)
                {
                    printf("table %d:\n", tcount);
                    while(stemp != NULL)
                    {
                        printf("Symbol: %s\n", stemp->name);
                        stemp = stemp->next;
                    }
                    Ttemp = Ttemp->next;
                    tcount++;
                }
            }
            else printf("No SymbolTables\n");
        };
};