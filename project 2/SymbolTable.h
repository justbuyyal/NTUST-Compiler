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

class sValue
{
private:
    variable type;
    bool flag;
    union 
    {
        int ival;
        float fval;
        bool bval;
        char cval;
        string* strval;
    };
public:
    sValue():flag(false), type(ERR){}
    sValue(variable t):flag(false), type(t){}
    variable get_type(){return type;}
    void assign_int(int i){ival = i; flag = true;}
    void assign_float(float f){fval = f; flag = true;}
    void assign_bool(bool b){bval = b; flag = true;}
    void assign_char(char c){cval = c; flag = true;}
    void assign_str(string* s){strval = s; flag = true;}
};

class Symbol
{
private:
    string id_name;
    syntactic syn_dec;
public:
    Symbol(string id, syntactic syn):id_name(id), syn_dec(syn){}
    string get_name(){return id_name;}
    syntactic get_syn(){return syn_dec;}
    
    virtual bool verified(){return false;}
    virtual variable get_type(){return NONE;}
    virtual void set_data(sValue v){}
    virtual sValue get_data(){return sValue();}
};

class VarSymbol:public Symbol
{
private:
    sValue variable_value;
public:
    VarSymbol(string id, sValue v, syntactic syn):Symbol(id, syn), variable_value(v){}
    VarSymbol(string id, variable t, syntactic syn):Symbol(id, syn){variable_value = new sValue(type);}
    virtual bool verified(){return variable_value->flag;}
    virtual variable get_type(){return variable_value->get_type();}
    virtual void set_data(sValue v){variable_value = v;}
    virtual sValue get_data(){return variable_value;}
};

class ArrSymbol:public Symbol
{

};

class FuncSymbol:public Symbol
{

};

class SymbolTable
{
private:
    map<string, Symbol*>table;
public:
    Symbol* lookup(string name){
        if(tale.find(name) != table.end()) return table[name];
        else return NULL;
    }
    int insert(Symbol* s){
        if(lookup(s->get_name()) == NULL){
            table.insert(pair<string, Symbol*>(s->get_name(), s));
            return 1;
        }
        else return -1;
    }
    void dump(){
        for(auto iter = table)
        {
            cout << "Name: " << iter->get_name() << " ,Type: " << iter->get_type() << endl;
        }
    }
};