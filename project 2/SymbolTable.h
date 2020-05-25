#include <iostream>
#include <string>
#include <vector>
#include <map>

using namespace std;

// type of variable
enum variable
{
    INT,
    FLOAT,
    BOOL,
    CHAR,
    STRING,
    NONE,
    ERR
};

// type of syntactic
enum syntactic
{
    CONST,
    VARIABLE,
    ARRAY,
    FUNCTION,
    OBJECT,
    _ERR
};

class Value
{
    public:
        variable type;
        bool flag = false;
        union
        {
            int ival;
            float fval;
            bool bval;
            char cval;
            string* strval;
        };
        Value():type(NONE){};
        Value(variable v):type(v){}
        variable get_type(){return type;}
        void as_int(int i){ival = i;}
        void as_float(float f){fval = f; flag = true;}
        void as_bool(bool b){bval = b; flag = true;}
        void as_char(char c){cval = c; flag = true;}
        void as_str(string* s){strval = s; flag = true;}
};

string get_varType(variable v)
{
    string output;
    switch (v)
    {
        case INT: output = "INTEGER"; break;
        case FLOAT: output = "FLOAT"; break;
        case BOOL: output = "BOOL"; break;
        case CHAR: output = "CHAR"; break;
        case STRING: output = "STRING"; break;
        case ERR: output = "ERROR"; break;
        default: output = "VAR_ERROR"; break;
    }
    return output;
}

string get_synType(syntactic s)
{
    string output;
    switch (s)
    {
        case CONST: output = "CONST"; break;
        case VARIABLE: output = "VARIABLE"; break;
        case ARRAY: output = "ARRAY"; break;
        case FUNCTION: output = "FUNCTION"; break;
        case OBJECT: output = "OBJECT"; break;
        case _ERR: output = "SYN_ERROR"; break;
    }
    return output;
}

class Symbol
{
    private:
        string name;
        syntactic syn;
    public:
        string get_name(){return name;}
        syntactic get_syn()(return syn;)
        Symbol(string s, syntactic n):name(s),syn(n){}
};

class VarSymbol: public Symbol
{
    private:
        Value var_value;
    public:
        VarSymbol(string id, variable type, syntactic syn):Symbol(id, syn), var_value(Value(type)){}
        VarSymbol(string id, Value v, syntactic syn):Symbol(id, syn), var_value(v){}
        variable get_type(){return var_value->get_type();}
        Value get_value(){return var_value;}
};

class FuncSymbol: public Symbol
{
    private:
        Value fun_value;
    public:
};

class ArraySymbol: public Symbol
{
    private:
        Value arr_value;
    public:
};

class SymbolTable
{
    private:
        map<string, Symbol*> table;
    public:
        SymbolTable() {

        }
        Symbol* lookup(string s){
            if(table.find(s) != table.end()) return table[s];
            else return NULL;
        }
        int insert(Symbol* s){
            if(table.find(s->name) != table.end()){ // found
                return -1;
            }
            else{ // not found
                table.insert(pair<string, Symbol*>(s->name, s));
                return 1;
            }
        }
        void dump(){
            for(auto iter = table)
            {
                cout << iter.second << endl;
            }
        }
};

class Symbol_list
{
    private:
        vector<SymbolTable>list;
        int size;
    public:
        Symbol_list(){size = 0; list.push_back(SymbolTable());}
        void push_table(){
            list.push_back();
        }
        void pop_table(){
            if(!list.empty()) list.pop_back();
        }
};