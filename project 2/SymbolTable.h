#include <iostream>
#include <string>
#include <vector>
#include <map>

using namespace std;

// type of variable
enum variable
{
    iNT,
    fLOAT,
    bOOL,
    cHAR,
    sTRING,
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
public:
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
    sValue():flag(false), type(ERR){}
    sValue(variable t):flag(false), type(t){}
    variable get_type(){return type;}
    void set_type(variable t) {type = t;}
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

    virtual void new_value(sValue* ar){}
    virtual void new_data(sValue v, int index){}
    virtual sValue get_data(int index){return sValue();}

    virtual bool verified(vector<sValue>* tmp){return false;}
    virtual void set_type(variable v){}
};

class VarSymbol:public Symbol
{
private:
    sValue variable_value;
public:
    VarSymbol(string id, sValue v, syntactic syn):Symbol(id, syn), variable_value(v){}
    VarSymbol(string id, variable t, syntactic syn):Symbol(id, syn), variable_value(t){}
    bool verified(){return variable_value.flag;}
    variable get_type(){return variable_value.get_type();}
    void set_data(sValue v){variable_value = v;}
    sValue get_data(){return variable_value;}
};

class ArrSymbol:public Symbol
{
private:
    sValue* array_value; // an array of data
    int arr_size;
public:
    ArrSymbol(string id, variable t, syntactic syn, int len):Symbol(id, syn), arr_size(len){
        array_value = new sValue[len];
        for(auto iter : array_value){
            iter->set_type(t);
        }
    }
    variable get_type() {return array_value->get_type();}
    sValue get_data(int index) {return array_value[index];}
    void new_value(sValue* ar) {array_value = ar;}
    void new_data(sValue v, int index) {array_value[index] = v;}
};

class FuncSymbol:public Symbol
{
private:
    vector<VarSymbol>input_data;
    variable return_type;
    int data_size;
public:
    FuncSymbol(string id, variable r, syntactic syn):Symbol(id, syn), return_type(r), data_size(0){}
    variable get_type() { return return_type;}
    void load_data(VarSymbol i) {input_data.push_back(i); data_size++;}
    void set_type(variable v) {return_type = v;}
    bool verified(vector<sValue>* tmp){
        if(tmp->size() != data_size) return false;
        if(return_type == NONE) return false;
        for(int i = 0; i < data_size; i++){
            if(input_data[i].get_type() != *(tmp + i)->get_type()){
                return false;
            }
        }
        return true;
    }
};

class SymbolTable
{
private:
    map<string, Symbol*>table;
public:
    Symbol* lookup(string name){
        if(table.find(name) != table.end()) return table[name];
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
        for(auto iter : table)
        {
            cout << "Name: " << iter.second->get_name() << " ,Type: " << iter.second->get_type() << endl;
        }
    }
};

class Symbol_list
{
    private:
        vector<SymbolTable>list;
        int sum;
    public:
        Symbol_list():sum(0){list.resize(1);}
        Symbol* lookup(string name) {return list[sum].lookup(name);}
        int insert(Symbol* s) {return list[sum].insert(s);}
        void AddTable() {list.push_back(SymbolTable()); sum++;}
        void PopTable() {list.pop_back(); sum--;}
};