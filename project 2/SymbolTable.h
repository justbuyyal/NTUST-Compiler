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
    _OBJECT,
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
    Symbol(string* id, syntactic syn):id_name(*id), syn_dec(syn){}
    string get_name(){return id_name;}
    syntactic get_syn(){return syn_dec;}
    
    virtual bool verified(){return false;}
    virtual variable get_type() {return NONE;}
    virtual void set_data(sValue v){}
    virtual sValue* get_data(){return new sValue();}

    virtual void new_value(sValue* ar){}
    virtual void new_data(sValue v, int index){}
    virtual sValue* get_data(int index){return new sValue();}

    virtual bool verified(vector<sValue>* tmp){return false;}
    virtual void load_data(variable d){}
};

class VarSymbol:public Symbol
{
private:
    sValue variable_value;
public:
    VarSymbol(string* id, sValue v, syntactic syn):Symbol(id, syn), variable_value(v){}
    VarSymbol(string* id, variable t, syntactic syn):Symbol(id, syn), variable_value(t){}
    bool verified(){return variable_value.flag;}
    variable get_type(){return variable_value.get_type();}
    void set_data(sValue v){variable_value = v;}
    sValue* get_data(){return &variable_value;}
};

class ArrSymbol:public Symbol
{
private:
    sValue* array_value; // an array of data
    variable array_type;
    int arr_size;
public:
    ArrSymbol(string* id, variable t, syntactic syn, int len):Symbol(id, syn), array_type(t), arr_size(len){
        array_value = new sValue[len];
        for(int i = 0; i < len; i++){
            array_value[i].set_type(t);
        }
    }
    variable get_type() {return array_type;}
    sValue* get_data(int index) {
        if(index < arr_size - 1) return (array_value + index);
        else cout << "Array access out of range\n";
    }
    void new_value(sValue* ar) {array_value = ar;}
    void new_data(sValue v, int index) {
        if(index < arr_size - 1) *(array_value + index) = v;
        else cout << "Array access out of range\n";
    }
};

class FuncSymbol:public Symbol
{
private:
    vector<variable>input_data;
    variable return_type;
    int arg_size;
    sValue* return_value;
public:
    FuncSymbol(string* id, variable r, syntactic syn):Symbol(id, syn), return_type(r), arg_size(0){}
    variable get_type() { return return_type;}
    void load_data(variable i) {input_data.push_back(i); arg_size++;}
    bool verified(vector<sValue>* tmp){
        if(tmp->size() != arg_size) return false;
        if(return_type == NONE) return false;
        for(int i = 0; i < arg_size; i++){
            if(input_data[i] != (*tmp)[i].get_type()){
                return false;
            }
        }
        return true;
    }
    void set_return_value(sValue* tmp) {return_value = tmp;}
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
        // cout << "Current insert\n";
        if(lookup(s->get_name()) == NULL){
            table.insert(pair<string, Symbol*>(s->get_name(), s));
            return 1;
        }
        // found in table
        else return -1;
    }
    void dump(){
        for(auto iter : table)
        {
            string dump_type, dump_syn;
            // cout << iter.first << " : " << iter.second->get_type() << endl;
            switch (iter.second->get_type())
            {
                case 0: dump_type = "int";break;
                case 1: dump_type = "float";break;
                case 2: dump_type = "bool";break;
                case 3: dump_type = "char";break;
                case 4: dump_type = "string";break;
                case 5: dump_type = "NONE";break;
                default: dump_type = "NONE"; break;
            }
            switch (iter.second->get_syn())
            {
                case 0: dump_syn = "const";break;
                case 1: dump_syn = "variable";break;
                case 2: dump_syn = "array";break;
                case 3: dump_syn = "function";break;
                case 4: dump_syn = "object";break;
                case 5: dump_syn = "ERROR";break;
            }
            cout << "Name: " << iter.second->get_name() << "\tType: " << dump_type << "\tSyn: " << dump_syn << endl;
        }
    }
};

class Symbol_list
{
    private:
        vector<SymbolTable>list;
        int index;
    public:
        Symbol_list() {index = 0; list.resize(1); cout << "initialized table created" << endl;}
        Symbol* lookup(string* name) {
            // cout << "lookup" << endl;
            int temp = index;
            while(temp >= 0){
                if(list[temp].lookup(*name) != NULL) return list[temp].lookup(*name);
                temp--;
            }
            return NULL;
        }
        int insert(Symbol* s) {
            return list[index].insert(s);
        }
        void AddTable() {cout << "create new table" << endl; list.push_back(SymbolTable()); index++;}
        void PopTable() {cout << "pop table\n" << endl; list.pop_back(); index--;}
        void DumpTable() {
                cout << "table " << index << " dump: \n------------------------------------\n"; list[index].dump();
                cout << "------------------------------------\n";
        }
};
