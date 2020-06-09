%{
#include "SymbolTable.h"
#include "lex.yy.cpp"
#define Trace(t)    if(0) {printf(t);}
Symbol_list* tables = new Symbol_list();
vector<Symbol*>current_method;
vector<Symbol*>arg_data;
bool main_method_flag = false;
int object_count = 0;

void yyerror(string msg)
{
    cout << msg << endl;
}
void DiffDataType()
{
    yyerror("Different Data Type !");
}
void Symbol_Not_Found()
{
    yyerror("Symbol in symboltable not found !");
}
void Assign_Error(string id_name)
{
    string temp = id_name + "\'s syntactic is not corresponded, can not assign !";
    yyerror(temp);
}
void Array_Error(int option)
{
    string temp = "Array Error ! ";
    switch(option)
    {
        case 0: temp += "Array index is not integer"; break;
        case 1: temp += "Array size can not less than one"; break;
    }
    yyerror(temp);
}
void Wrong_Data_Type()
{
    yyerror("Error data type !");
}
void addSymbol(Symbol* s)
{
    if(tables->insert(s) == -1) yyerror("Symbol already exist !");
    else Trace("Insert Symbol Successful\n");
}
%}
%union {
    int ival;
    float fval;
    bool bval;
    char cval;
    string* strval;
    variable type;
    sValue* symbol_value;
    vector<sValue>* exp_list;
    vector<variable>* args_data;
}
/* tokens */
// keywords
%token SEMICOLON BOOLEAN BREAK CHAR CASE CLASS CONTINUE DEF DO ELSE EXIT FALSE FLOAT FOR IF INT NULL_ OBJECT PRINT PRINTLN REPEAT RETURN STRING TO TRUE TYPE VAL VAR WHILE READ
// token assign
%token <bval> BOOL_VAL
%token <ival> INT_VAL
%token <cval> CHAR_VAL
%token <fval> FLOAT_VAL
%token <strval> STR_VAL
%token <strval> ID
/* operator precedence */
%left OR_OP
%left AND_OP
%left '!'
%left '<' '>' DE LE BE NE
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS
// declare nonterminal
%type <type> data_type optional_type return_type func_invocation arg
%type <symbol_value> const_val expression
%type <exp_list> comma_separated_exp comma_separated_exps
%type <args_data> args optional_args
%%
program:
    OBJECT ID
    {
        Trace("In object\n");
        if(object_count < 1){
            Symbol* temp = new Symbol($2, _OBJECT);
            addSymbol(temp); // add object symbol to table
            ++object_count;
        }
        else yyerror("Can only have one object !");
        tables->AddTable(); // create a new table for next scope
    }
    '{' dec_and_methods '}'
    {
        Trace("object out\n");
        // show the Symbols of top table
        tables->DumpTable();
        if(!main_method_flag) yyerror("There is no 'main' method !");
        tables->PopTable();
    };
dec_and_methods:
    const_dec dec_and_methods
    | var_dec dec_and_methods
    | method dec_and_methods
    | const_dec
    | var_dec
    | method;
dec_and_stmts:
    const_dec dec_and_stmts
    | var_dec dec_and_stmts
    | stmt dec_and_stmts
    | /* zero  */;
method:
    DEF ID '(' optional_args ')' return_type
    {
        Trace("In method\n");
        FuncSymbol* temp;
        if(tables->lookup($2) != NULL)
        {
            yyerror("There is a same name method !");
            string s_temp = "1_" + *$2;
            temp = new FuncSymbol(&s_temp, $6, FUNCTION);
        }
        else
        {
            temp = new FuncSymbol($2, $6, FUNCTION);
        }
        // input data assign to function symbol
        if($4->size() > 0){
            Trace("load args\n");
            for(int i = 0; i < $4->size(); i++){
                // load args data type
                temp->load_data((*$4)[i]);
            }
        }
        current_method.push_back(temp);
        if(temp->get_name() == "main") main_method_flag = true;
        addSymbol(temp); // add function symbol to table
        tables->AddTable(); // create a new table for current scope
        /* Insert args to table */
        if(arg_data.size() > 0) {
            for(int i = 0; i < arg_data.size(); i++){
                addSymbol(arg_data[i]);
            }
            arg_data.clear();
        }
    }
    '{' dec_and_stmts '}'
    {
        Trace("method out\n");
        current_method.pop_back();
        // show the Symbols of top table
        tables->DumpTable();
        tables->PopTable();
    };
data_type:
    INT
    {
        $$ = iNT;
    }|
    FLOAT
    {
        $$ = fLOAT;
    }|
    BOOLEAN
    {
        $$ = bOOL;
    }|
    CHAR
    {
        $$ = cHAR;
        Trace("get char\n");
    }|
    STRING
    {
        $$ = sTRING;
        Trace("get string\n");
    };
const_val:
    INT_VAL
    {
        sValue* temp = new sValue(iNT);
        temp->assign_int($1);
        $$ = temp;
    }|
    FLOAT_VAL
    {
        sValue* temp = new sValue(fLOAT);
        temp->assign_float($1);
        $$ = temp;
    }|
    BOOL_VAL
    {
        sValue* temp = new sValue(bOOL);
        temp->assign_bool($1);
        $$ = temp;
    }|
    CHAR_VAL
    {
        sValue* temp = new sValue(cHAR);
        temp->assign_char($1);
        $$ = temp;
    }|
    STR_VAL
    {
        sValue* temp = new sValue(sTRING);
        temp->assign_str($1);
        $$ = temp;
    };
optional_type:
    ':' data_type
    {
        $$ = $2;
    }|
    {
        $$ = NONE;
    };
const_dec:
    VAL ID optional_type '=' expression
    {
        if($3 != NONE){
            if($3 != $5->get_type()){
                DiffDataType();
            }
        }
        VarSymbol* temp = new VarSymbol($2, *$5, CONST);
        addSymbol(temp);
    };
var_dec:
    VAR ID optional_type
    {
        VarSymbol* temp = new VarSymbol($2, $3, VARIABLE);
        addSymbol(temp);
    }|
    VAR ID optional_type '=' expression
    {
        if($3 != NONE){
            if($3 != $5->get_type()){
                DiffDataType();
            }
        }
        VarSymbol* temp = new VarSymbol($2, *$5, VARIABLE);
        addSymbol(temp);
    }|
    VAR ID ':' data_type '[' INT_VAL ']'
    {
        Trace("In array\n");
        // array declaration
        if($6 < 1) Array_Error(1);
        Trace("array check size\n");
        ArrSymbol* temp = new ArrSymbol($2, $4, ARRAY, $6);
        addSymbol(temp);
    };
optional_args:
    args
    {
        $$ = $1;
        Trace("Args\n");
    }| /* zero */
    {
        vector<variable>* temp = new vector<variable>();
        $$ = temp;
        Trace("No Args\n");
    };
args:
    arg
    {
        vector<variable>* temp = new vector<variable>();
        temp->push_back($1);
        $$ = temp;
        Trace("First arg\n");
    }
    | args ',' arg
    {
        $1->push_back($3);
        $$ = $1;
        Trace("Adding arg\n");
    };
arg:
    ID ':' data_type
    {
        VarSymbol* temp = new VarSymbol($1, $3, VARIABLE);
        arg_data.push_back(temp);
        $$ = $3;
    };
return_type:
    ':' data_type
    {
        $$ = $2;
        Trace("Have return type\n");
    }
    | /* zero */
    {
        $$ = NONE;
        Trace("No return type\n");
    };
comma_separated_exps:
    comma_separated_exp
    {
        $$ = $1;
    }
    | /* zero */
    {
        vector<sValue>* temp = new vector<sValue>();
        $$ = temp;
    };
comma_separated_exp:
    expression
    {
        vector<sValue>* temp = new vector<sValue>();
        temp->push_back(*$1);
        $$ = temp;
    }
    | comma_separated_exp ',' expression
    {
        $1->push_back(*$3);
        $$ = $1;
    };
stmt:
    simple
    | func_invocation
    {
        if($1 != NONE) yyerror("Can not have return type");
    }
    | block
    | conditional
    | loop;
simple:
    ID '=' expression
    {
        Symbol* temp = tables->lookup($1);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        if(temp->get_type() != $3->get_type()) DiffDataType();
        if(temp->get_syn() != VARIABLE) Assign_Error(temp->get_name()); // Variable
        // set data
        temp->set_data(*$3); // variable
    }|
    ID '[' expression ']' '=' expression
    {
        Symbol* temp = tables->lookup($1);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        if(temp->get_type() != $6->get_type()) DiffDataType();
        if(temp->get_syn() != ARRAY) Assign_Error(temp->get_name()); // Array
        // array index error
        if($3->get_type() != iNT) Array_Error(0);
        // array index error(unset)
        // if(!$3->flag) yyerror("Unchecked value !");
        // assign a new value
        if($3->flag) temp->new_data(*$6, $3->ival);
    }
    | PRINT  expression
    | PRINTLN  expression
    | READ ID
    {
        Symbol* temp = tables->lookup($2);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        // $$ = temp;FUNCTION
    }
    | RETURN
    {
        int temp = current_method.size();
        /* check the current method declared before and check return type */
        if(temp > 0 && current_method[temp - 1]->get_type() == NONE){
            Trace("return nothing\n");
        }
        else{
            yyerror("None functional return !"); /* there is no function */
        }
    }
    | RETURN expression
    {
        int temp = current_method.size();
        /* check the current method declared before and check return type */
        if(temp <= 0){
             yyerror("None functional return !"); /* there is no function */
        }
        /* expression will lookup by itself, so do nothing */
    };
expression:
    const_val
    {
        $$ = $1;
    }
    | ID
    {
        Symbol* temp = tables->lookup($1);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        if(temp->get_syn() != VARIABLE) Assign_Error(temp->get_name()); // Variable
        $$ = temp->get_data(); // return data
    }
    | ID '[' expression ']'
    {
        if($3->get_type() != iNT) Array_Error(0); // array index error
        Symbol* temp = tables->lookup($1);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        if(temp->get_syn() != ARRAY) Assign_Error(temp->get_name()); // Array
        // return array value[ival]
        if($3->flag) $$ = temp->get_data($3->ival);
    }
    | '(' expression ')'
    {
        $$ = $2;
    }
    | '-' expression %prec UMINUS
    {
        variable temp = $2->get_type(); // only int and float can be calculated
        if(temp == iNT){
            $2->ival*= -1;
            $$ = $2;
        }
        else if(temp == fLOAT){
            $2->fval*= -1;
            $$ = $2;
        }
        else{
            Wrong_Data_Type();
        }
    }
    | expression '*' expression
    {
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp == iNT || temp == fLOAT){ // only int and float can be calculated
            if(temp == iNT){
                $1->ival*= $3->ival;
            }
            else{
                $1->fval*= $3->fval;
            }
            $$ = $1;
        }
        else{
            Wrong_Data_Type();
        }
    }
    | expression '/' expression
    {
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp == iNT || temp == fLOAT){ // only int and float can be calculated
            if(temp == iNT){
                $1->ival/= $3->ival;
            }
            else{
                $1->fval/= $3->fval;
            }
            $$ = $1;
        }
        else{
            Wrong_Data_Type();
        }
    }
    | expression '+' expression
    {
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp == iNT || temp == fLOAT){ // only int and float can be calculated
            if(temp == iNT){
                $1->ival+= $3->ival;
            }
            else{
                $1->fval+= $3->fval;
            }
            $$ = $1;
        }
        else{
            Wrong_Data_Type();
        }
    }
    | expression '-' expression
    {
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp == iNT || temp == fLOAT){ // only int and float can be calculated
            if(temp == iNT){
                $1->ival-= $3->ival;
            }
            else{
                $1->fval-= $3->fval;
            }
            $$ = $1;
        }
        else{
            Wrong_Data_Type();
        }
    }
    | expression '<' expression
    {
        Trace("< compare\n");
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        bool result;
        if(temp == iNT)
        {
            result = ($1->ival < $3->ival);
        }
        else if(temp == fLOAT)
        {
            result = ($1->fval < $3->fval);
        }
        else if(temp == bOOL)
        {
            result = ($1->bval < $3->bval);
        }
        else if(temp == cHAR)
        {
            result = ($1->cval < $3->cval);
        }
        else if(temp == sTRING)
        {
            result = ($1->strval < $3->strval);
        }
        else
        {
            Wrong_Data_Type();
        }
        sValue* output = new sValue(bOOL);
        output->assign_bool(result);
        Trace("set < bool\n");
        $$ = output;
    }
    | expression '>' expression
    {
        Trace("> compare\n");
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        bool result;
        if(temp == iNT)
        {
            result = ($1->ival > $3->ival);
        }
        else if(temp == fLOAT)
        {
            result = ($1->fval > $3->fval);
        }
        else if(temp == bOOL)
        {
            result = ($1->bval > $3->bval);
        }
        else if(temp == cHAR)
        {
            result = ($1->cval > $3->cval);
        }
        else if(temp == sTRING)
        {
            result = ($1->strval > $3->strval);
        }
        else
        {
            Wrong_Data_Type();
        }
        sValue* output = new sValue(bOOL);
        output->assign_bool(result);
        Trace("set > bool\n");
        $$ = output;
    }
    | expression LE expression
    {
        // <=
        Trace("<= compare\n");
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        bool result;
        if(temp == iNT)
        {
            result = ($1->ival <= $3->ival);
        }
        else if(temp == fLOAT)
        {
            result = ($1->fval <= $3->fval);
        }
        else if(temp == bOOL)
        {
            result = ($1->bval <= $3->bval);
        }
        else if(temp == cHAR)
        {
            result = ($1->cval <= $3->cval);
        }
        else if(temp == sTRING)
        {
            result = ($1->strval <= $3->strval);
        }
        else
        {
            Wrong_Data_Type();
        }
        sValue* output = new sValue(bOOL);
        output->assign_bool(result);
        Trace("set <= bool\n");
        $$ = output;
    }
    | expression BE expression
    {
        // >=
        Trace(">= compare\n");
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        bool result;
        if(temp == iNT)
        {
            result = ($1->ival >= $3->ival);
        }
        else if(temp == fLOAT)
        {
            result = ($1->fval >= $3->fval);
        }
        else if(temp == bOOL)
        {
            result = ($1->bval >= $3->bval);
        }
        else if(temp == cHAR)
        {
            result = ($1->cval >= $3->cval);
        }
        else if(temp == sTRING)
        {
            result = ($1->strval >= $3->strval);
        }
        else
        {
            Wrong_Data_Type();
        }
        sValue* output = new sValue(bOOL);
        output->assign_bool(result);
        Trace("set >= bool\n");
        $$ = output;
    }
    | expression DE expression
    {
        // ==
        Trace("== compare\n");
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        bool result;
        if(temp == iNT)
        {
            result = ($1->ival == $3->ival);
        }
        else if(temp == fLOAT)
        {
            result = ($1->fval == $3->fval);
        }
        else if(temp == bOOL)
        {
            result = ($1->bval == $3->bval);
        }
        else if(temp == cHAR)
        {
            result = ($1->cval == $3->cval);
        }
        else if(temp == sTRING)
        {
            result = ($1->strval == $3->strval);
        }
        else
        {
            Wrong_Data_Type();
        }
        sValue* output = new sValue(bOOL);
        output->assign_bool(result);
        Trace("set == bool\n");
        $$ = output;
    }
    | expression NE expression
    {
        // !=
        Trace("!= compare\n");
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        bool result = false;
        if(temp == iNT)
        {
            result = ($1->ival != $3->ival);
        }
        else if(temp == fLOAT)
        {
            result = ($1->fval != $3->fval);
        }
        else if(temp == bOOL)
        {
            result = ($1->bval != $3->bval);
        }
        else if(temp == cHAR)
        {
            result = ($1->cval != $3->cval);
        }
        else if(temp == sTRING)
        {
            result = ($1->strval != $3->strval);
        }
        else
        {
            Wrong_Data_Type();
        }
        sValue* output = new sValue(bOOL);
        output->assign_bool(result);
        Trace("set != bool\n");
        $$ = output;
    }
    | '!' expression
    {
        // only boolean can compare
        if($2->get_type() != bOOL) {
            Wrong_Data_Type();
            $$ = $2;
        }
        else
        {
            cout << "Is bool\n";
            sValue* output = new sValue(bOOL);
            output->assign_bool(!($2->bval));
            $$ = output;
        }
    }
    | expression AND_OP expression
    {
        // &&
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp != bOOL) {
            Wrong_Data_Type(); // only boolean can compare
            $$ = $1;
        }
        else {
            cout << "Is bool\n";
            sValue* output = new sValue(bOOL);
            output->assign_bool(($1->bval && $3->bval));
            $$ = output;
        }
    }
    | expression OR_OP expression
    {
        // ||
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp != bOOL) {
             Wrong_Data_Type(); // only boolean can compare
             $$ = $1;
        }
        else {
            cout << "Is bool\n";
            $1->bval = ($1->bval || $3->bval);
            sValue* output = new sValue(bOOL);
            output->assign_bool(($1->bval || $3->bval));
            $$ = output;
        }
    }
    | func_invocation
    {
        // function call
        sValue* temp = new sValue($1);
        $$ = temp;
    };
func_invocation:
    ID '(' comma_separated_exps ')'
    {
        Symbol* f_temp  = tables->lookup($1);
        if(f_temp == NULL) Symbol_Not_Found(); // no declaration before
        if(f_temp->get_syn() != FUNCTION) Assign_Error(f_temp->get_name()); // Function
        if(!f_temp->verified($3)) yyerror("func_invocation: Function input data correspondence error !");
        $$ = f_temp->get_type(); // return function return type
    };
block:
    '{'
    {
        Trace("In block\n");
        tables->AddTable();  // create a new table for current scope
    }
    dec_and_stmts '}'
    {
        Trace("block out\n");
        // show the Symbols of top table
        tables->DumpTable();
        tables->PopTable();
    };
block_or_simple:
    block
    | simple;
conditional:
    IF '(' expression ')' 
    {
        // only boolean can compare
        if($3->get_type() != bOOL) Wrong_Data_Type();
    } 
    block_or_simple else_stmt;
else_stmt:
    ELSE block_or_simple
    | /* zero */;
loop:
    WHILE '(' expression ')'
    {
        Trace("In while\n");
        // only boolean can compare
        if($3->get_type() != bOOL) Wrong_Data_Type();
    } 
    block_or_simple
    | FOR '(' ID '<' '-' INT_VAL TO INT_VAL ')'
    {
        Trace("In for\n");
        Symbol* temp = tables->lookup($3);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        if(temp->get_syn() != VARIABLE) Assign_Error(temp->get_name()); // Variable
        if(temp->get_type() != iNT) Assign_Error(temp->get_name()); // integer
        // left should be smaller than right
        if($6 > $8) Assign_Error(temp->get_name());
    }
    block_or_simple;
%%

int main(int argc, char* argv[])
{
    if(argc != 2) exit(1);
    yyin = fopen(argv[1], "r");
    if(yyparse() == 1)
    {
        yyerror("Parsing error !\n"); /* syntax error */
    }
	return 0;
}
