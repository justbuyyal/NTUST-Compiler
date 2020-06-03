%{
#include "SymbolTable.h"
#include "lex.yy.cpp"
#define Trace(t)    printf(t)

Symbol_list tables;
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
    if(tables.insert(s) == -1) yyerror("Symbol already exist !");
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
%type <type> data_type optional_type arg return_type func_invocation
%type <symbol_value> const_val expression
%type <exp_list> comma_separated_exp comma_separated_exps
%type <args_data> args optional_args
%%
const_var_dec:
    const_dec const_var_dec
    | var_dec const_var_dec
    | /* zero */;
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
    }|
    STRING
    {
        $$ = sTRING;
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
        // array declaration
        if($6 < 1) Array_Error(1);
        ArrSymbol* temp = new ArrSymbol($2, $4, ARRAY, $6);
        addSymbol(temp);
    };
arg:
    ID ':' data_type
    {
        $$ = $3;
    };
args:
    arg
    {
        vector<variable>* temp = new vector<variable>();
        temp->push_back($1);
        $$ = temp;
    }
    | args ',' arg
    {
        $1->push_back($3);
        $$ = $1;
    };
optional_args:
    args
    {
        $$ = $1;
    }| /* zero */
    {
        vector<variable>* temp = new vector<variable>();
        $$ = temp;
    };
return_type:
    ':' data_type
    {
        $$ = $2;
    }
    | /* zero */
    {
        $$ = NONE;
    };
simple:
    ID '=' expression
    {
        Symbol* temp = tables.lookup($1);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        if(temp->get_type() != $3->get_type()) DiffDataType();
        if(temp->get_syn() != VARIABLE) Assign_Error(temp->get_name()); // Variable
        // set data
        temp->set_data(*$3); // variable
    }|
    ID '[' expression ']' '=' expression
    {
        Symbol* temp = tables.lookup($1);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        if(temp->get_type() != $6->get_type()) DiffDataType();
        if(temp->get_syn() != ARRAY) Assign_Error(temp->get_name()); // Array
        // array index error
        if($3->get_type() != iNT) Array_Error(0);
        // array index error(unset)
        if(!$3->flag) yyerror("Unchecked value !");
        // assign a new value
        temp->new_data(*$6, $3->ival);
    }|
    PRINT '(' expression ')'
    | PRINTLN '(' expression ')'
    | READ ID
    {
        Symbol* temp = tables.lookup($2);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        // $$ = temp;
    }
    | RETURN
    | RETURN expression;
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
func_invocation:
    ID '(' comma_separated_exps ')'
    {
        Symbol* f_temp  = tables.lookup($1);
        if(f_temp == NULL) Symbol_Not_Found(); // no declaration before
        if(f_temp->get_syn() != FUNCTION) Assign_Error(f_temp->get_name()); // Function
        if(!f_temp->verified($3)) yyerror("func_invocation: Function input data correspondence error !");
        $$ = f_temp->get_type(); // return function return type
    };
expression:
    const_val
    {
        $$ = $1;
    }
    | ID
    {
        Symbol* temp = tables.lookup($1);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        if(temp->get_syn() != VARIABLE) Assign_Error(temp->get_name()); // Variable
        $$ = temp->get_data(); // return data
    }
    | func_invocation
    {
        // function call
        sValue* temp = new sValue($1);
        $$ = temp;
    }
    | ID '[' expression ']'
    {
        if($3->get_type() != iNT) Array_Error(0); // array index error
        Symbol* temp = tables.lookup($1);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        if(temp->get_syn() != ARRAY) Assign_Error(temp->get_name()); // Array
        // return array value[ival]
        $$ = temp->get_data($3->ival);
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
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp != bOOL) Wrong_Data_Type(); // only boolean can compare
        $1->bval = ($1->bval < $3->bval);
        $$ = $1;
    }
    | expression '>' expression
    {
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp != bOOL) Wrong_Data_Type(); // only boolean can compare
        $1->bval = ($1->bval > $3->bval);
        $$ = $1;
    }
    | expression LE expression
    {
        // <=
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp != bOOL) Wrong_Data_Type(); // only boolean can compare
        $1->bval = ($1->bval <= $3->bval);
        $$ = $1;
    }
    | expression BE expression
    {
        // >=
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp != bOOL) Wrong_Data_Type(); // only boolean can compare
        $1->bval = ($1->bval >= $3->bval);
        $$ = $1;
    }
    | expression DE expression
    {
        // ==
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp != bOOL) Wrong_Data_Type(); // only boolean can compare
        $1->bval = ($1->bval == $3->bval);
        $$ = $1;
    }
    | expression NE expression
    {
        // !=
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp != bOOL) Wrong_Data_Type(); // only boolean can compare
        $1->bval = ($1->bval != $3->bval);
        $$ = $1;
    }
    | '!' expression
    {
        // only boolean can compare
        if($2->get_type() != bOOL) Wrong_Data_Type();
        $2->bval = !($2->bval);
        $$ = $2;
    }
    | expression AND_OP expression
    {
        // &&
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp != bOOL) Wrong_Data_Type(); // only boolean can compare
        $1->bval = ($1->bval && $3->bval);
        $$ = $1;
    }
    | expression OR_OP expression
    {
        // ||
        if($1->get_type() != $3->get_type()) DiffDataType();
        variable temp = $1->get_type();
        if(temp != bOOL) Wrong_Data_Type(); // only boolean can compare
        $1->bval = ($1->bval || $3->bval);
        $$ = $1;
    };
block:
    '{'
    {
        tables.AddTable();  // create a new table for current scope
    }
    const_var_dec stmts '}'
    {
        // show the Symbols of top table
        tables.DumpTable();
        tables.PopTable();
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
    block_or_simple ELSE block_or_simple
    | IF '(' expression ')' 
    {
        // only boolean can compare
        if($3->get_type() != bOOL) Wrong_Data_Type();
    }
    block_or_simple;
loop:
    WHILE '(' expression ')'
    {
        // only boolean can compare
        if($3->get_type() != bOOL) Wrong_Data_Type();
    } 
    block_or_simple
    | FOR '(' ID '<' '-' INT_VAL TO INT_VAL ')'
    {
        Symbol* temp = tables.lookup($3);
        if(temp == NULL) Symbol_Not_Found(); // no declaration before
        if(temp->get_syn() != VARIABLE) Assign_Error(temp->get_name()); // Variable
        if(temp->get_type() != iNT) Assign_Error(temp->get_name()); // integer
        // left should be smaller than right
        if($6 > $8) Assign_Error(temp->get_name());
    }
    block_or_simple;
stmt:
    simple
    | expression
    | func_invocation
    | block
    | conditional
    | loop;
stmts:
    stmt
    | stmt stmts
    | /* zero */;
method:
    DEF ID '(' optional_args ')' return_type
    {
        FuncSymbol* temp = new FuncSymbol($2, $6, FUNCTION);
        // input data assign to function symbol
        if($4->size() > 0){
            for(int i = 0; i < $4->size(); i++){
                // load args data type
                temp->load_data($4[i]);
            }
        }
        addSymbol(temp); // add function symbol to table
        tables.AddTable(); // create a new table for current scope
    }
    '{' const_var_dec stmts '}'
    {
        // show the Symbols of top table
        tables.DumpTable();
        tables.PopTable();
    };
methods:
    method
    | methods method;
program:
    OBJECT ID
    {
        Symbol* temp = new Symbol($2, OBJECT);
        addSymbol(temp); // add object symbol to table
        tables.AddTable(); // create a new table for current scope
    }
    '{' const_var_dec methods '}'
    {
        // show the Symbols of top table
        tables.DumpTable();
        tables.PopTable();
    };
%%

int main(int argc, char* argv[])
{
	yyparse();
	return 0;
}
