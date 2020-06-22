#include <iostream>
#include <fstream>
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
    bool is_const;
    union
    {
        int ival;
        float fval;
        bool bval;
        char cval;
        string* strval;
    };
    sValue():type(ERR), is_const(false){}
    sValue(variable t):type(t), is_const(false){}
    variable get_type(){return type;}
    void set_const() {is_const = true;}
    void assign_int(int i){ival = i; type = iNT;}
    void assign_float(float f){fval = f; type = fLOAT;}
    void assign_bool(bool b){bval = b; type = bOOL;}
    void assign_char(char c){cval = c; type = cHAR;}
    void assign_str(string* s){strval = s; type = sTRING;}
};

class Symbol
{
private:
    string id_name;
    syntactic syn_dec;
public:
    int local_stack; // java code local variable
    Symbol(string* id, syntactic syn):id_name(*id), syn_dec(syn){}
    string get_name(){return id_name;}
    syntactic get_syn(){return syn_dec;}
    
    virtual variable get_type() {return NONE;}
    virtual sValue* get_data(){return new sValue();}
    virtual void set_global() {}
    virtual bool global() {return false;}
    virtual void set_stack(int s) {}
    virtual int get_stack() {return 0;}

    virtual bool verified(vector<sValue>* tmp){return false;}
    virtual void load_data(variable d){}
    virtual void func_arg(fstream &fp) {}
};

class VarSymbol:public Symbol
{
private:
    sValue variable_value;
    bool is_global;
    int local_stack;
public:
    VarSymbol(string* id, sValue v, syntactic syn):Symbol(id, syn), variable_value(v), is_global(false){}
    VarSymbol(string* id, variable t, syntactic syn):Symbol(id, syn), variable_value(t), is_global(false){}
    variable get_type(){return variable_value.get_type();}
    sValue* get_data(){return &variable_value;}
    void set_global() {is_global = true;}
    bool global() {return is_global;}
    void set_stack(int s) {local_stack = s;}
    int get_stack() {return local_stack;}
};

class FuncSymbol:public Symbol
{
private:
    variable return_type;
    int arg_size;
    sValue* return_value;
public:
    vector<VarSymbol*>input_data;
    FuncSymbol(string* id, variable r, syntactic syn):Symbol(id, syn), return_type(r), arg_size(0){input_data.clear();}
    variable get_type() { return return_type;}
    void load_data(VarSymbol* i) {input_data.push_back(i); arg_size++;}
    bool verified(vector<sValue>* tmp){
        if(tmp->size() != arg_size) {
            cout << "Debug: Function size wrong" << endl;
            return false;
        }
        for(int i = 0; i < arg_size; i++){
            if(input_data[i]->get_type() != (*tmp)[i].get_type()){
                cout << "Debug: Function data type wrong" << endl;
                return false;
            }
        }
        return true;
    }
    void func_arg(fstream &fp) {
        // cout << "Debug : Function arguments" << endl;
        for(int i = 0; i < arg_size; i++) {
                switch(input_data[i]->get_type()) {
                    case 0:
                    case 2:
                    case 5:
                            fp << "int"; break;
                    case 3: fp << "char"; break;
                    case 4: fp << "java.lang.String"; break;
                }
                if(i != arg_size - 1) {
                    fp << ", ";
                }
        }
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
        Symbol_list() {index = 0; list.resize(1);}
        Symbol* lookup(string* name, int deep) {
            if(deep == 0) deep = index + 1;
            int temp = index;
            while(temp >= 0 && deep > 0){
                if(list[temp].lookup(*name) != NULL) return list[temp].lookup(*name);
                temp--;
                deep--;
            }
            return NULL;
        }
        int insert(Symbol* s) {
            return list[index].insert(s);
        }
        int get_size() {return index;}
        void AddTable() {cout << "create new table" << endl; list.push_back(SymbolTable()); index++;}
        void PopTable() {cout << "pop table\n" << endl; list.pop_back(); index--;}
        void DumpTable() {
                cout << "table " << index << " dump: \n------------------------------------\n"; list[index].dump();
                cout << "------------------------------------\n";
        }
};
