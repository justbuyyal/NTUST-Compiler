%{
#include "SymbolTable.h"
#include "lex.yy.cpp"

#define Trace(t)    if(false) {printf(t)}

// Java file and stack
fstream fp;
int local_var_stacks = 0;
int label_stack = 0;
int list_deep = 0;
vector<vector<int>>label_list;
istream::streampos position;
// -------------------------------------------------------- //
// yacc initialization
Symbol_list* tables = new Symbol_list();
int object_count = 0;
string Class_name; // For object name
// -------------------------------------------------------- //
// method initialization
vector<Symbol*>current_method;
bool main_method_flag = false;
// -------------------------------------------------------- //
// yacc debug function
void yyerror(string msg) { cout << msg << endl; }
void DiffDataType() { yyerror("Different Data Type !"); } // Two of entity type different
void Symbol_Not_Found() { yyerror("Symbol in symboltable not found !"); }
void Assign_Error(string id_name) {
    string temp = id_name + "\'s syntactic is not corresponded, can not assign !";
    yyerror(temp);
}
void Wrong_Data_Type() { yyerror("Error data type !"); } // Data type not for current entity
// -------------------------------------------------------- //
// Symbol Table function
void addSymbol(Symbol* s) {
    // Search current symbol table
    if(tables->insert(s) == -1) yyerror("Symbol already exist in this scope !");
    else 
    {
        // Trace("Insert Symbol Successful\n");
    }
}
// -------------------------------------------------------- //
// Java code file input
void build_object(Symbol* temp) {
    fp << "class " << temp->get_name() << endl;
    fp << "{" << endl;
}
void build_method(FuncSymbol* temp) {
    fp << "method public static ";
    switch(temp->get_type()) {
        case 0: fp << "int "; break;
        case 2: fp << "bool "; break;
        case 3: fp << "char "; break;
        case 4: fp << "java.lang.String "; break;
        case 5: fp << "void "; break;
    }
    fp << temp->get_name() << "(";
    if(temp->input_data.size() > 0) {
        temp->func_arg(fp);
    }
    else {
        fp << "java.lang.String[]";
    }
    fp << ")" << endl << "max_stack 15" << endl << "max_locals 15" << endl << "{" << endl;
}
void build_variable(VarSymbol* temp, sValue* exp) {
    if(temp->global()) { // global variable
        fp << "field static ";
        switch(temp->get_type()) {
            case 0:
            case 2:
            case 5:
                    fp << "int "; break;
            case 3: fp << "char "; break;
            case 4: fp << "java.lang.String "; break;
            case 1: break;
        }
        fp << temp->get_name();
        if(exp != NULL) {
            switch(exp->get_type()) {
                case 0:
                case 2:
                case 5:
                        fp << " = " << exp->ival << endl;
                        break;
                case 3:
                        fp << " = " << exp->cval << endl;
                        break;
                case 4:
                        // string
                        break;
            }
        }
        else
        {
            fp << endl;
        }
    }
    else { // local variable
        temp->set_stack(local_var_stacks);
        if(exp != NULL) {
            fp << "istore " << temp->get_stack() << endl;
        }
        ++local_var_stacks;
    }
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
    VarSymbol* single_arg;
    vector<VarSymbol*>* args_data;
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
%type <type> data_type optional_type return_type func_invocation
%type <symbol_value> const_val expression
%type <exp_list> comma_separated_exp comma_separated_exps
%type <single_arg> arg
%type <args_data> args optional_args
%%
program:
    OBJECT ID
    {
        // object count
        if(object_count < 1) 
        {
            ++object_count; // object count plus one
            Symbol* temp = new Symbol($2, _OBJECT);
            addSymbol(temp);
            Class_name = temp->get_name(); // Set object name as class name
            // java object code --------------------------------------------------------- //
            label_list.push_back(vector<int>());
            build_object(temp);
            // -------------------------------------------------------------------------- //
        }
        else
        {
            yyerror("Can only have one object !");
        }
        tables->AddTable(); // create a new table for next scope
    }
    '{' dec_and_methods '}'
    {
        tables->DumpTable(); // Show the Symbols of current table
        tables->PopTable();
        // Main method detection
        if(!main_method_flag)
        {
            yyerror("There is no 'main' method !");
        }
        // java object code --------------------------------------------------------- //
        fp << "}" << endl;
        // -------------------------------------------------------------------------- //
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
        // Function initialization
        FuncSymbol* temp;
        // Check same name method
        if(tables->lookup($2, 0) != NULL)
        {
            yyerror("There is a same name method !");
            string s_method = "1_" + *$2;
            temp = new FuncSymbol(&s_method, $6, FUNCTION);
        }
        else
        {
            temp = new FuncSymbol($2, $6, FUNCTION);
        }
        // Check main method exist
        if(temp->get_name() == "main")
        {
            main_method_flag = true;
        }
        // Load function arguments
        for(int i = 0; i < $4->size(); i++)
        {
            temp->load_data((*$4)[i]);
        }
        // method stack plus one
        current_method.push_back(temp);
        // Add function symbol to table
        addSymbol(temp);
        tables->AddTable(); // create a new tables for next scope
        // Insert arguments to symbol table
        for(int i = 0; i < $4->size(); i++)
        {
            // Variable Symbol
            (*$4)[i]->set_stack(local_var_stacks);
            local_var_stacks++;
            addSymbol((*$4)[i]);
        }
        // java method code --------------------------------------------------------- //
        build_method(temp);
        // -------------------------------------------------------------------------- //
    }
    '{' dec_and_stmts '}'
    {
        // pop current method stack
        current_method.pop_back();
        tables->DumpTable();
        tables->PopTable();
        // java method code --------------------------------------------------------- //
        if($6 == NONE) fp << "return" << endl;
        fp << "}" << endl;
        local_var_stacks = 0;
        // -------------------------------------------------------------------------- //
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
        temp->set_const();
        $$ = temp;
    }|
    FLOAT_VAL
    {
        sValue* temp = new sValue(fLOAT);
        temp->assign_float($1);
        temp->set_const();
        $$ = temp;
    }|
    BOOL_VAL
    {
        sValue* temp = new sValue(bOOL);
        temp->assign_bool($1);
        temp->set_const();
        $$ = temp;
    }|
    CHAR_VAL
    {
        sValue* temp = new sValue(cHAR);
        temp->assign_char($1);
        temp->set_const();
        $$ = temp;
    }|
    STR_VAL
    {
        sValue* temp = new sValue(sTRING);
        string s_t;
        for(int i = 0; i < $1->size(); i++)
        {
            if((*$1)[i] == '\"')
            {
                s_t += "\\";
            }
            s_t += (*$1)[i];
        }
        *$1 = s_t;
        temp->assign_str($1);
        temp->set_const();
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
    VAL ID optional_type '=' 
    {
        position = fp.tellg();
    }
    expression
    {
        // const variable initialization
        Symbol* s_temp = tables->lookup($2, 1); // Search for current table
        if(s_temp != NULL)
        {
            yyerror("Symbol already exist !");
        }
        else
        {
            if($3 != NONE)
            {
                if($3 != $6->get_type())
                {
                    cout << "Debug: Const dec with assign" << endl;
                    DiffDataType();
                }
            }
            VarSymbol* temp = new VarSymbol($2, *$6, CONST);
            addSymbol(temp);
            // java const dec code ---------------------------------------------------- //
            fp.seekg(position);
            // ------------------------------------------------------------------------ //
        }
    };
var_dec:
    VAR ID optional_type
    {
        // Variable initialization
        Symbol* s_temp = tables->lookup($2, 1);
        if(s_temp != NULL)
        {
            yyerror("Symbol already exist !");
        }
        else
        {
            VarSymbol* temp = new VarSymbol($2, $3, VARIABLE);
            // Check global
            if(tables->get_size() == 1)
            {
                temp->set_global();
            }
            addSymbol(temp);
            // java variable code --------------------------------------------------------- //
            build_variable(temp, NULL);
            // ---------------------------------------------------------------------------- //
        }
    }|
    VAR ID optional_type '='
    {
        position = fp.tellg();
    }
    expression
    {
        // Variable initialization
        Symbol* s_temp = tables->lookup($2, 1);
        if(s_temp != NULL)
        {
            yyerror("Symbol already exist !");
        }
        else
        {
            if($3 != NONE)
            {
                if($3 != $6->type)
                {
                    cout << "Variable dec with assign" << endl;
                    DiffDataType();
                }
            }
            VarSymbol* temp = new VarSymbol($2, *$6, VARIABLE);
            // Check global
            if(tables->get_size() == 1)
            {
                temp->set_global();
            }
            addSymbol(temp);
            // java variable code --------------------------------------------------------- //
            fp.seekg(position);
            build_variable(temp, $6);
            // ---------------------------------------------------------------------------- //
        }
    };
optional_args:
    args
    {
        $$ = $1;
    }| /* zero */
    {
        // No arguments
        vector<VarSymbol*>* temp = new vector<VarSymbol*>();
        $$ = temp;
    };
args:
    arg
    {
        // First argument
        vector<VarSymbol*>* temp = new vector<VarSymbol*>();
        temp->push_back($1);
        $$ = temp;
    }
    | args ',' arg
    {
        $1->push_back($3);
        $$ = $1;
    };
arg:
    ID ':' data_type
    {
        VarSymbol* temp = new VarSymbol($1, $3, VARIABLE);
        $$ = temp;
    };
return_type:
    ':' data_type
    {
        $$ = $2;
    }
    | /* zero */
    {
        // No return type
        $$ = NONE;
    };
comma_separated_exps:
    comma_separated_exp
    {
        $$ = $1;
    }
    | /* zero */
    {
        // No comma_separated expressions
        vector<sValue>* temp = new vector<sValue>();
        $$ = temp;
    };
comma_separated_exp:
    expression
    {
        // First expression
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
    | block
    | conditional
    | loop;
simple:
    ID '=' expression
    {
        // table lookup check
        Symbol* s_temp = tables->lookup($1, 0);
        if(s_temp == NULL)
        {
            // No declaration before
            Symbol_Not_Found();
        }
        else
        {
            if(s_temp->get_type() != $3->type)
            {
                cout << "Function assign error" << endl;
                DiffDataType();
            }
            else
            {
                if(s_temp->get_syn() != VARIABLE)
                {
                    // Variable Error
                    Assign_Error(s_temp->get_name());
                }
                else
                {
                    // java variable assign code -------------------------------------------- //
                    if(s_temp->global())
                    {
                        switch(s_temp->get_type())
                        {
                            case 0:
                            case 2:
                            case 5:
                                    fp << "putstatic int ";
                                    break;
                            case 3: break; // char
                            case 4: fp << "putstatic java.lang.String "; break;
                        }
                        fp  << Class_name << "." << s_temp->get_name() << endl;
                    }
                    else // local
                    {
                        fp << "istore " << s_temp->get_stack() << endl;
                    }
                    // ---------------------------------------------------------------------- //
                }
            }
        }
    }|
    PRINT
    {
        fp << "getstatic java.io.PrintStream java.lang.System.out" << endl;
    } 
    expression
    {
        fp << "invokevirtual void java.io.PrintStream.print(";
        switch($3->type)
        {
            case 0:
            case 2:
            case 5:
                    fp << "int"; break;
            case 3: break;
            case 4: fp << "java.lang.String"; break;
        }
        fp << ")" << endl;
    }|
    PRINTLN
    {
        fp << "getstatic java.io.PrintStream java.lang.System.out" << endl;
    }
    expression
    {
        fp << "invokevirtual void java.io.PrintStream.println(";
        switch($3->type)
        {
            case 0:
            case 2:
            case 5:
                    fp << "int"; break;
            case 3: break;
            case 4: fp << "java.lang.String"; break;
        }
        fp << ")" << endl;
    }|
    RETURN
    {
        // method return type check
        int temp = current_method.size();
        /* check the current method declared before and check return type */
        if(temp > 0 && current_method[temp - 1]->get_type() == NONE)
        {
            // java return code --------------------------------------------------------- //
            fp << "return" << endl;
            // -------------------------------------------------------------------------- //
        }
        else
        {
            yyerror("None functional return !"); /* there is no function */
        }
    }|
    RETURN expression
    {
        int temp = current_method.size();
        /* check the current method declared before and check return type */
        if(temp <= 0) yyerror("None functional return !"); /* there is no function */
        else
        {
            // java return code --------------------------------------------------------- //
            fp << "ireturn" << endl;
            // -------------------------------------------------------------------------- //
        }
    };
expression:
    const_val
    {
        $$ = $1;
        // java const code --------------------------------------------------------- //
        switch($1->type)
        {
            case 0: fp << "sipush " << $1->ival << endl; break;
            case 2: fp << "iconst_" << (int)($1->bval) << endl; break;
            case 3: break;
            case 4: fp << "ldc \"" << *($1->strval) << "\""<< endl; break;
        }
        // ------------------------------------------------------------------------- //
    }|
    ID
    {
        // table lookup check
        Symbol* s_temp = tables->lookup($1, 0);
        if(s_temp == NULL)
        {
            // No declaration before
            Symbol_Not_Found();
        }
        else
        {
            $$ = s_temp->get_data();
            // java id code --------------------------------------------------------- //
            if(s_temp->get_syn() == CONST)
            {
                sValue* temp = s_temp->get_data();
                switch(s_temp->get_type())
                {
                    case 0: fp << "sipush " << temp->ival << endl; break;
                    case 2: fp << "iconst_" << (int)(temp->bval) << endl; break;
                    case 3: break;
                    case 4: fp << "ldc \"" << *(temp->strval) << "\"" << endl; break;
                }
            }
            else // Variable
            {
                if(s_temp->global())
                {
                    switch(s_temp->get_type())
                    {
                        case 0:
                        case 2:
                        case 5:
                                fp << "getstatic int "; break;
                        case 3: break;
                        case 4: fp << "getstatic java.lang.String "; break;
                    }
                    fp << Class_name << "." << s_temp->get_name() << endl;
                }
                else // Local variable
                {
                    fp << "iload " << s_temp->get_stack() << endl;
                }
            }
            // ---------------------------------------------------------------------- //
        }
    }|
    '(' expression ')'
    {
        $$ = $2;
    }|
    '-' expression %prec UMINUS
    {
        // available check
        variable v_temp = $2->type; // only int can be calculated
        if(v_temp != iNT)
        {
            Wrong_Data_Type();
        }
        else
        {
            sValue* temp = new sValue(iNT);
            temp->assign_int(($2->ival) * -1);
            $$ = temp;
            // java UMINUS code --------------------------------------------------------- //
            fp << "ineg" << endl;
            // ---------------------------------------------------------------------- //
        }
    }|
    expression '*' expression
    {
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp *\n";
            DiffDataType();
        }
        else
        {
            variable v_temp = $1->type;
            if(v_temp != iNT)
            {
                Wrong_Data_Type();
            }
            else
            {
                sValue* temp = new sValue(iNT);
                temp->assign_int($1->ival * $3->ival);
                $$ = temp;
                // java multiple code --------------------------------------------------------- //
                fp << "imul" << endl;
                // ---------------------------------------------------------------------------- //
            }
        }
    }|
    expression '/' expression
    {
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp /\n";
            DiffDataType();
        }
        else
        {
            variable v_temp = $1->type;
            if(v_temp != iNT)
            {
                Wrong_Data_Type();
            }
            else
            {
                sValue* temp = new sValue(iNT);
                temp->assign_int($1->ival / $3->ival);
                $$ = temp;
                // java divide code --------------------------------------------------------- //
                fp << "idiv" << endl;
                // ---------------------------------------------------------------------------- //
            }
        }
    }|
    expression '%' expression
    {
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp %\n";
            DiffDataType();
        }
        else
        {
            variable v_temp = $1->type;
            if(v_temp != iNT)
            {
                Wrong_Data_Type();
            }
            else
            {
                sValue* temp = new sValue(iNT);
                temp->assign_int($1->ival % $3->ival);
                $$ = temp;
                // java reminder code --------------------------------------------------------- //
                fp << "irem" << endl;
                // ---------------------------------------------------------------------------- //
            }
        }
    }|
    expression '+' expression
    {
        // available check
        if($1->get_type() != $3->get_type())
        {
            cout << "Exp +\n";
            DiffDataType();
        }
        else
        {
            variable v_temp = $1->type;
            if(v_temp != iNT)
            {
                Wrong_Data_Type();
            }
            else
            {
                sValue* temp = new sValue(iNT);
                temp->assign_int($1->ival + $3->ival);
                $$ = temp;
                // java add code -------------------------------------------------------------- //
                fp << "iadd" << endl;
                // ---------------------------------------------------------------------------- //
            }
        }
    }|
    expression '-' expression
    {
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp -\n";
            DiffDataType();
        }
        else
        {
            variable v_temp = $1->type;
            if(v_temp != iNT)
            {
                Wrong_Data_Type();
            }
            else
            {
                sValue* temp = new sValue(iNT);
                temp->assign_int($1->ival - $3->ival);
                $$ = temp;
                // java sub code --------------------------------------------------------- //
                fp << "isub" << endl;
                // ---------------------------------------------------------------------------- //
            }
        }
    }|
    expression '<' expression
    {
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp <\n";
            DiffDataType();
        }
        else
        {
            sValue* temp = new sValue(bOOL);
            switch($1->type)
            {
                case 0: temp->assign_bool($1->ival < $3->ival); break;
                case 2: temp->assign_bool($1->bval < $3->bval); break;
                case 3: temp->assign_bool($1->cval < $3->cval); break;
                case 4: temp->assign_bool($1->strval < $3->strval); break;
            }
            $$ = temp;
            // java boolean code --------------------------------------------------------- //
            fp << "isub" << endl << "iflt L" << label_stack << endl;
            int label_temp = label_stack;
            ++label_stack;
            fp << "iconst_0" << endl << "goto L" << label_stack << endl;
            fp << "L" << label_temp << ":" << "iconst_1" << endl;
            fp << "L" << label_stack << ":" << endl;
            ++label_stack;
            // ---------------------------------------------------------------------------- //
        }
    }|
    expression '>' expression
    {
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp >\n";
            DiffDataType();
        }
        else
        {
            sValue* temp = new sValue(bOOL);
            switch($1->type)
            {
                case 0: temp->assign_bool($1->ival > $3->ival); break;
                case 2: temp->assign_bool($1->bval > $3->bval); break;
                case 3: temp->assign_bool($1->cval > $3->cval); break;
                case 4: temp->assign_bool($1->strval > $3->strval); break;
            }
            $$ = temp;
            // java boolean code --------------------------------------------------------- //
            fp << "isub" << endl << "ifgt L" << label_stack << endl;
            int label_temp = label_stack;
            ++label_stack;
            fp << "iconst_0" << endl << "goto L" << label_stack << endl;
            fp << "L" << label_temp << ":" << "iconst_1" << endl;
            fp << "L" << label_stack << ":" << endl;
            ++label_stack;
            // ---------------------------------------------------------------------------- //
        }
    }|
    expression LE expression
    {
        // <=
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp <=\n";
            DiffDataType();
        }
        else
        {
            sValue* temp = new sValue(bOOL);
            switch($1->type)
            {
                case 0: temp->assign_bool($1->ival <= $3->ival); break;
                case 2: temp->assign_bool($1->bval <= $3->bval); break;
                case 3: temp->assign_bool($1->cval <= $3->cval); break;
                case 4: temp->assign_bool($1->strval <= $3->strval); break;
            }
            $$ = temp;
            // java boolean code --------------------------------------------------------- //
            fp << "isub" << endl << "ifle L" << label_stack << endl;
            int label_temp = label_stack;
            ++label_stack;
            fp << "iconst_0" << endl << "goto L" << label_stack << endl;
            fp << "L" << label_temp << ":" << "iconst_1" << endl;
            fp << "L" << label_stack << ":" << endl;
            ++label_stack;
            // ---------------------------------------------------------------------------- //
        }
    }|
    expression BE expression
    {
        // >=
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp >=\n";
            DiffDataType();
        }
        else
        {
            sValue* temp = new sValue(bOOL);
            switch($1->type)
            {
                case 0: temp->assign_bool($1->ival >= $3->ival); break;
                case 2: temp->assign_bool($1->bval >= $3->bval); break;
                case 3: temp->assign_bool($1->cval >= $3->cval); break;
                case 4: temp->assign_bool($1->strval >= $3->strval); break;
            }
            $$ = temp;
            // java boolean code --------------------------------------------------------- //
            fp << "isub" << endl << "ifge L" << label_stack << endl;
            int label_temp = label_stack;
            ++label_stack;
            fp << "iconst_0" << endl << "goto L" << label_stack << endl;
            fp << "L" << label_temp << ":" << "iconst_1" << endl;
            fp << "L" << label_stack << ":" << endl;
            ++label_stack;
            // ---------------------------------------------------------------------------- //
        }
    }|
    expression DE expression
    {
        // ==
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp ==\n";
            DiffDataType();
        }
        else
        {
            sValue* temp = new sValue(bOOL);
            switch($1->type)
            {
                case 0: temp->assign_bool($1->ival == $3->ival); break;
                case 2: temp->assign_bool($1->bval == $3->bval); break;
                case 3: temp->assign_bool($1->cval == $3->cval); break;
                case 4: temp->assign_bool($1->strval == $3->strval); break;
            }
            $$ = temp;
            // java boolean code --------------------------------------------------------- //
            fp << "isub" << endl << "ifeq L" << label_stack << endl;
            int label_temp = label_stack;
            ++label_stack;
            fp << "iconst_0" << endl << "goto L" << label_stack << endl;
            fp << "L" << label_temp << ":" << "iconst_1" << endl;
            fp << "L" << label_stack << ":" << endl;
            ++label_stack;
            // ---------------------------------------------------------------------------- //
        }
    }|
    expression NE expression
    {
        // !=
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp !=\n";
            DiffDataType();
        }
        else
        {
            sValue* temp = new sValue(bOOL);
            switch($1->type)
            {
                case 0: temp->assign_bool($1->ival != $3->ival); break;
                case 2: temp->assign_bool($1->bval != $3->bval); break;
                case 3: temp->assign_bool($1->cval != $3->cval); break;
                case 4: temp->assign_bool($1->strval != $3->strval); break;
            }
            $$ = temp;
            // java boolean code --------------------------------------------------------- //
            fp << "isub" << endl << "ifne L" << label_stack << endl;
            int label_temp = label_stack;
            ++label_stack;
            fp << "iconst_0" << endl << "goto L" << label_stack << endl;
            fp << "L" << label_temp << ":" << "iconst_1" << endl;
            fp << "L" << label_stack << ":" << endl;
            ++label_stack;
            // --------------------------------------------------------------------------- //
        }
    }|
    '!' expression
    {
        // available check
        if($2->type != bOOL)
        {
            cout << "Exp !\n";
            Wrong_Data_Type();
        }
        else
        {
            sValue* temp = new sValue(bOOL);
            temp->assign_bool(!($2->bval));
            $$ = temp;
            // java XOR code --------------------------------------------------------- //
            fp << "iconst_1" << endl << "ixor" << endl;
            // ----------------------------------------------------------------------- //
        }
    }|
    expression AND_OP expression
    {
        // &&
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp AND\n";
            DiffDataType();
        }
        else
        {
            variable v_temp = $1->type;
            if(v_temp != bOOL)
            {
                Wrong_Data_Type();
            }
            else
            {
                sValue* temp = new sValue(bOOL);
                temp->assign_bool(($1->bval && $3->bval));
                $$ = temp;
                // java AND code --------------------------------------------------------- //
                fp << "iand" << endl;
                // ----------------------------------------------------------------------- //
            }
        }
    } |
    expression OR_OP expression
    {
        // ||
        // available check
        if($1->type != $3->type)
        {
            cout << "Exp OR\n";
            DiffDataType();
        }
        else
        {
            variable v_temp = $1->type;
            if(v_temp != bOOL)
            {
                Wrong_Data_Type();
            }
            else
            {
                sValue* temp = new sValue(bOOL);
                temp->assign_bool(($1->bval || $3->bval));
                $$ = temp;
                // java OR code --------------------------------------------------------- //
                fp << "ior" << endl;
                // ----------------------------------------------------------------------- //
            }
        }
    }|
    func_invocation
    {
        // function call
        sValue* s_temp = new sValue($1);
        $$ = s_temp;
    };
func_invocation:
    ID '(' comma_separated_exps ')'
    {
        // table lookup
        Symbol* s_temp = tables->lookup($1, 0);
        if(s_temp == NULL)
        {
            // No declaration before
            Symbol_Not_Found();
        }
        if(s_temp->get_syn() != FUNCTION)
        {
            // Function Error
            Assign_Error(s_temp->get_name());
        }
        else
        {
            if(!(s_temp->verified($3)))
            {
                // Function input data inconsistance
                yyerror("Func_invocation: Function input data correspondence error !");
            }
            else
            {
                // return function return_type
                $$ = s_temp->get_type();
                // java func_invocation code --------------------------------------------------------- //
                fp << "invokestatic ";
                switch(s_temp->get_type())
                {
                    case 0:
                    case 2:
                    case 5:
                            fp << "int "; break;
                    case 3: break;
                    case 4: fp << "java.lang.String "; break;
                }
                fp << Class_name << "." << s_temp->get_name() << "(";
                s_temp->func_arg(fp);
                fp << ")" << endl;
                // ----------------------------------------------------------------------------------- //
            }
        }
    };
block:
    '{'
    {
        // create a new table for next scope
        tables->AddTable();
    }
    dec_and_stmts '}'
    {
        tables->DumpTable();
        tables->PopTable();
    };
block_or_simple:
    block
    | simple;
conditional:
    IF '(' expression ')'
    {
        // Only boolean can be compared
        if($3->type != bOOL)
        {
            cout << $3->type << endl;
            Wrong_Data_Type();
        }
        else
        {
            // java IF code --------------------------------------------------------- //
            fp << "ifeq L" << label_stack << endl;
            label_list[list_deep].push_back(label_stack); // False
            ++label_stack;
            ++list_deep;
            label_list.push_back(vector<int>());
            // ---------------------------------------------------------------------- //
        }
    }
    block_or_simple
    {
        // java IF code --------------------------------------------------------- //
        label_list.pop_back();
        --list_deep;
        fp << "goto L" << label_stack << endl; // Exit
        label_list[list_deep].push_back(label_stack);
        ++label_stack;
        // ---------------------------------------------------------------------- //
    }
    else_stmt
    {
        // java IF code --------------------------------------------------------- //
        fp << "L" << label_list[list_deep].back() << ":" << endl; // Exit statement
        if(list_deep == 0) label_list[list_deep].clear();
        // ---------------------------------------------------------------------- //
    };
else_stmt:
    ELSE
    {
        // java ELSE code --------------------------------------------------------- //
        fp << "L" << label_list[list_deep][0] << ":" << endl;
        ++list_deep;
        label_list.push_back(vector<int>());
        // ------------------------------------------------------------------------ //
    }
    block_or_simple
    {
        label_list.pop_back();
        --list_deep;
    }
    | /* zero */
    {
        // java ELSE code --------------------------------------------------------- //
        fp << "L" << label_list[list_deep][0] << ":" << endl;
        // ------------------------------------------------------------------------ //
    };
loop:
    WHILE
    {
        // java While code --------------------------------------------------------- //
        fp << "L" << label_stack << ":" << endl;
        label_list[list_deep].push_back(label_stack); // LBegin
        ++label_stack;
        // ------------------------------------------------------------------------- //
    }
    '(' expression ')'
    {
        // Only boolean can be compared
        if($4->type != bOOL)
        {
            Wrong_Data_Type();
        }
        else
        {
            // java While code --------------------------------------------------------- //
            fp << "ifeq L" << label_stack << endl;
            label_list[list_deep].push_back(label_stack); // LExit
            ++label_stack;
            ++list_deep;
            label_list.push_back(vector<int>());
            // ------------------------------------------------------------------------- //
        }
    }
    block_or_simple
    {
        // java While code --------------------------------------------------------- //
        label_list.pop_back();
        --list_deep;
        fp << "goto L" << label_list[list_deep][0] << endl;
        fp << "L" << label_list[list_deep].back() << ":" << endl; // LExit:
        if(list_deep == 0) label_list[list_deep].clear();
        // ------------------------------------------------------------------------- //
    }
    | FOR '(' ID '<' '-' expression
    {
        // table lookup
        Symbol* s_temp = tables->lookup($3, 0);
        if(s_temp == NULL)
        {
            // No declaration before
            Symbol_Not_Found();
        }
        else
        {
            if(s_temp->get_syn() != VARIABLE)
            {
                // For Variable Error
                Assign_Error(s_temp->get_name());
            }
            else
            {
                if(s_temp->get_type() != iNT)
                {
                    // For argument INT Error
                    Assign_Error(s_temp->get_name());
                }
                else
                {
                    if($6->type == iNT)
                    {
                        // java For code --------------------------------------------------------- //
                        if(s_temp->global()) // Assign first variable to identifier
                        {
                            fp << "putstatic int " << Class_name << "." << s_temp->get_name() << endl;
                            fp << "L" << label_stack << ":" << endl; // Begin statement
                            fp << "getstatic int " << Class_name << "." << s_temp->get_name() << endl;
                        }
                        else
                        { // Local variable
                            fp << "istore " << s_temp->get_stack() << endl;
                            fp << "L" << label_stack << ":" << endl; // Begin statement
                            fp << "iload " << s_temp->get_stack() << endl;
                        }
                        label_list[list_deep].push_back(label_stack);
                        ++label_stack;
                        // ----------------------------------------------------------------------- //
                    }
                }
            }
        }
    } 
    TO expression ')'
    {
        Symbol* s_temp = tables->lookup($3, 0);
        if(s_temp == NULL)
        {
            // No declaration before
            Symbol_Not_Found();
        }
        else
        {
            if(s_temp->get_syn() != VARIABLE)
            {
                // For Variable Error
                Assign_Error(s_temp->get_name());
            }
            else
            {
                if(s_temp->get_type() != iNT)
                {
                    // For argument INT Error
                    Assign_Error(s_temp->get_name());
                }
                else
                {
                    if($9->type == iNT)
                    {
                        // java For code --------------------------------------------------------- //
                        fp << "isub" << endl << "ifle L" << label_stack << endl; // True statement
                        label_list[list_deep].push_back(label_stack);
                        ++label_stack;
                        fp << "iconst_0" << endl;
                        fp << "goto L" << label_stack << endl; // False statement
                        label_list[list_deep].push_back(label_stack);
                        ++label_stack;
                        fp << "L" << label_list[list_deep][1] << ":" << endl; // True statement
                        fp << "iconst_1" << endl;
                        fp << "L" << label_list[list_deep].back() << ":" << endl;
                        fp << "ifeq L" << label_stack << endl; // Exit statement
                        label_list[list_deep].push_back(label_stack);
                        ++label_stack;
                        ++list_deep;
                        label_list.push_back(vector<int>());
                        // ----------------------------------------------------------------------- //
                    }
                }
            }
        }
    }
    block_or_simple
    {
        // java For code --------------------------------------------------------- //
        label_list.pop_back();
        --list_deep;
        // id ++
        Symbol* s_temp = tables->lookup($3, 0);
        if(s_temp->global())
        {
            fp << "getstatic int " << Class_name << "." << s_temp->get_name() << endl;
        }
        else
        {
            fp << "iload " << s_temp->get_stack() << endl;
        }
        fp << "sipush 1" << endl << "iadd" << endl;
        if(s_temp->global())
        {
            fp << "putstatic int " << Class_name << "." << s_temp->get_name() << endl;
        }
        else
        {
            fp << "istore " << s_temp->get_stack() << endl;
        }
        fp << "goto L" << label_list[list_deep][0] << endl;
        fp << "L" << label_list[list_deep].back() << ":" << endl;
        if(list_deep == 0) label_list[list_deep].clear();
        // ----------------------------------------------------------------------- //
    };
%%
int main(int argc, char* argv[])
{
    if(argc != 2) exit(1);
    yyin = fopen(argv[1], "r");
    fp.open("scala.txt", ios::out);
    if(yyparse() == 1)
    {
        yyerror("Parsing Error !\n"); /* syntax error */
    }
    fp.close();
    fstream output;
    output.open("scala.jasm", ios::out);
    fp.open("scala.txt", ios::in);
    string line;
    int tab_stack = 0;
    while(getline(fp, line))
    {
        if(line == "{")
        {
            for(int i = 0; i < tab_stack; i++)
            {
                output << "\t";
            }
            output << "{" << endl;
            tab_stack++;
        }
        else if(line == "}")
        {
            --tab_stack;
            for(int i = 0; i < tab_stack; i++)
            {
                output << "\t";
            }
            output << "}" << endl;
        }
        else
        {
            for(int i = 0; i < tab_stack; i++)
            {
                output << "\t";
            }
            output << line << endl;
        }
    }
    fp.close();
    output.close();
    return 0;
}