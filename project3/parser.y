%{
#include <iostream>
#include <fstream>
#include <stdio.h>
#include <cmath>
#include "symbols.hpp"
#include "codegen.hpp"
#include "lex.yy.cpp"
#define Trace(t) if (Opt_P) cout<<"TRACE => "<<t<<endl;
using namespace std;
void yyerror(string s);
int Opt_P = 0;		// print trace message
int Opt_DS = 0;		// dump symboltable when function or compound parse finished
SymbolTableList stl;
vector<vector<idInfo>> fpstack;
int mainFunc = 0;

string outName;		// output filename
ofstream out;		// output stream
%}
/* type */
%union {
	int val;
	double dval;
	bool bval; 
	string* sval;
	idInfo* idinfo;
	int type;
}

/* tokens */

/* Operator : length > one char */
%token LE GE EQ NEQ ADDA SUBA MULA DIVA AND OR

/* keywords */
%token BREAK CASE CONTINUE DEFAULT ELSE FOR FUNC GO IF IMPORT NIL PRINT PRINTLN RETURN STRUCT SWITCH TYPE VAR WHILE READ
%token BOOL CONST INT REAL STRING VOID 

%token <sval> ID 
%token <val> INT_CONST 
%token <bval> BOOL_CONST 
%token <dval> REAL_CONST 
%token <sval> STR_CONST

/* type declare for non-terminal symbols */
%type <idinfo> const_value expression func_invocation
%type <type> var_type func_type

/* precedence */
%left OR
%left AND
%left '!'
%left '<' '>' LE GE EQ NEQ
%left '+' '-' '|'
%left '*' '/' '%' '&'
%left '^'
%nonassoc UMINUS UPLUS
%%
/* program */
program:
	   	{
			genProgramStart();
		} 
	   	opt_var_dec opt_func_dec
		{
			if(mainFunc==0) {
				cerr << "WARRING : main function not found"<< endl;
				genMainStart();
				genVoidFuncEnd();
			}
			genCompoundEnd();
		}
	   ;

/* optional variable and constant declarations */
opt_var_dec: var_dec opt_var_dec
		   | const_dec opt_var_dec
		   | /* zero or more */
		   ;

/* declare constant */
const_dec: CONST ID '=' expression
		{
			Trace("declare constant");
			if(!isConst(*$4)) yyerror("ERROR : assign value not constant");
			$4->flag = ConstVar_flag;
			if(stl.insert(*$2,*$4) == -1) yyerror("ERROR : variable redefinition");
		}
		 ;

/* declare variable */
var_dec: VAR ID var_type
		{
			Trace("declare variable");
			if(stl.insertNoInit(*$2,$3) == -1) yyerror("ERROR : variable redefinition");
			if($3 == Int_type || $3 == Bool_type){
				int index = stl.getIndex(*$2);
				if(index == -1){		// global
					genGlobalVarNoInit(*$2);
				}
			}
		}
	   | VAR ID var_type '=' expression
		{
			Trace("declare variable with initial value");
			if(!isConst(*$5)) yyerror("ERROR : assign value not constant");
			if($3 != $5->type) yyerror("ERROR : type not match");
			$5->flag = Var_flag;
			if(stl.insert(*$2,*$5) == -1) yyerror("ERROR : variable redefinition");
			if($3 == Int_type || $3 == Bool_type){
				int index = stl.getIndex(*$2);
				int value = getIntBoolValue(*$5);
				if(index == -1){		// global
					genGlobalVar(*$2,value);
				}else if(index >= 0){	// local
					genLocalVar(index, value);
				}
			}
		}
	   | VAR ID '[' expression ']' var_type
		{
			Trace("declare array variable");
			if(!isConst(*$4)) yyerror("ERROR : array size not constant");
			if($4->type != Int_type) yyerror("ERROR : array size not integer");
			if($4->value.val < 1) yyerror("ERROR : array size < 1");
			if(stl.insertArray(*$2,$6,$4->value.val) == -1) yyerror("ERROR : variable redefinition");
		}
	   ;


var_type: INT 		{ $$ = Int_type;  }
		| BOOL 		{ $$ = Bool_type; }
		| REAL 		{ $$ = Real_type; }
		| STRING	{ $$ = Str_type;  }
		;





/* optional declare function */
opt_func_dec : func_dec opt_func_dec 
			 |	/* zero or more */
			 ;

/* declare function */
func_dec : FUNC func_type ID 
			{
				Trace("declare function");
				if(stl.insertFunc(*$3,$2) == -1) yyerror("ERROR : function name conflict");
				stl.pushTable();
			}
		   '(' opt_params ')' '{'
			{
				if(*$3 == "main"){
					mainFunc = 1;
					genMainStart();
				}else{
					genFuncStart(*stl.lookup(*$3));
				}
			}
			   opt_var_dec
			   opt_statement
		   '}' 
			{
				if($2 == Void_type){
					genVoidFuncEnd();
				}else{
					genCompoundEnd();
				}
				if(Opt_DS)stl.dump();
				if(!stl.popTable()) yyerror("pop symbol table error");
			}
			;

/* type of function*/
func_type: INT 		{ $$ = Int_type;  }
		 | BOOL 	{ $$ = Bool_type; }
		 | REAL 	{ $$ = Real_type; }
		 | STRING	{ $$ = Str_type;  }
		 | VOID 	{ $$ = Void_type; }
		 ;

/* formal parameter */
opt_params : params
			|
			;

/* param <,param,...>*/
params: params ',' param
	  | param
	  ;

param: ID var_type
		{
			if(stl.insertNoInit(*$1,$2) == -1) yyerror("ERROR : variable redefinition");
			if(!stl.setFuncParam(*$1,$2)) yyerror("ERROR : set function parameter error");
		}
	 ;

opt_statement: statement opt_statement
			 |
			 ;

/* statement */
statement: ID '=' expression
		{
			Trace("statement: variable assign");
			idInfo *tmp = stl.lookup(*$1);
			if(tmp == NULL) yyerror("undeclared identifier " + *$1);
			if(tmp->flag != Var_flag) yyerror("ERROR : " + *$1 + " not var");
			if(tmp->type != $3->type) yyerror("ERROR : type not match");

			if(tmp->type == Int_type || tmp->type == Bool_type){
				int index = stl.getIndex(*$1);
				if(index == -1){		// global
					genSetGlobalVar(*$1);
				}else if(index >= 0){	// local
					genSetLocalVar(index);
				}
			}
		}
		 | ID '[' expression ']' '=' expression
		{
			Trace("statement: array variable assign");
			idInfo *tmp = stl.lookup(*$1);
			if(tmp == NULL) yyerror("undeclared identifier " + *$1);
			if(tmp->flag != Var_flag) yyerror("ERROR : " + *$1 + " not var");
			if(tmp->type != Array_type) yyerror("ERROR : " + *$1 + " not array");
			if($3->type != Int_type) yyerror("ERROR : index not integer");
			if($3->value.val >= tmp->value.aval.size()) yyerror("ERROR : array index out of range");
			if(tmp->value.aval[0].type != $6->type) yyerror("ERROR : type not match");
		}
		 | {genPrintStart();} PRINT expression 
		{ 
			if($3->type == Str_type) genPrintStr();
			else genPrintInt();
			Trace("statement: print expression"); 
		}
		 | {genPrintStart();} PRINTLN expression 
		{ 
			if($3->type == Str_type) genPrintlnStr();
			else genPrintlnInt();
			Trace("statement: print expression with new line"); 
		}
		 | READ ID
		{
			Trace("statement: read user input into " + *$2);
			idInfo *tmp = stl.lookup(*$2);
			if(tmp == NULL) yyerror("undeclared identifier " + *$2);
			if(tmp->flag != Var_flag) yyerror("ERROR : " + *$2 + " not var, cannot be set value");
		}
		 | RETURN { Trace("statement: return"); genReturn();}
		 | RETURN expression { Trace("statement: return expression"); geniReturn();}
		 | GO func_invocation
		 | compound { Trace("statement: compound"); }
		 | conditional
		 | loop
		 ;

/* function invocation */
func_invocation: ID
				{
					fpstack.push_back(vector<idInfo>());
				}
				 '(' opt_comma_separated_expression ')'
				{
					Trace("call function");
					idInfo *tmp = stl.lookup(*$1);
					if(tmp == NULL) yyerror("undeclared identifier " + *$1);
					if(tmp->flag != Func_flag) yyerror("ERROR : " + *$1 + " not function");
					vector<idInfo> tmpArr = tmp->value.aval;
					if(tmpArr.size() != fpstack[fpstack.size()-1].size()) yyerror("ERROR : function parameter size not match");
					for(int i= 0;i<tmpArr.size();i++){
						if(tmpArr[i].type != fpstack[fpstack.size()-1].at(i).type) yyerror("ERROR : function parameter type not match");
					}
					genCallFunc(*tmp);
					$$ = tmp;
					fpstack.pop_back();
				}
			   ;

/* actual parameter */
opt_comma_separated_expression: comma_separated_expression
							  |
							  ;

/* expression <,expression,...,expression>*/
comma_separated_expression: comma_separated_expression ',' func_expression
						  | func_expression
						  ;

func_expression: expression
				{
					fpstack[fpstack.size()-1].push_back(*$1);
				}
			   ;

/* compound */
compound: '{' {stl.pushTable();}
		   		opt_var_dec
		   		opt_statement
		  '}' {if(Opt_DS)stl.dump();if(!stl.popTable()) yyerror("ERROR : pop symbol table error");}
		;

conditional: IF '(' expression ')' ifStart statement
		    {
				Trace("if");
				if($3->type!=Bool_type) yyerror("ERROR : condition not boolean");
				genIfEnd();
			}
		   | IF '(' expression ')' ifStart statement ELSE { genElse(); } statement
		    {
				Trace("if else");
				if($3->type!=Bool_type) yyerror("ERROR : condition not boolean");
				genIfElseEnd();
			}
		   ;

ifStart: { genIfStart(); };

loop: FOR '(' forStart for_left_exp { genForCond(); } for_right ')' { genForBody(); } statement
	{
		Trace("for");
		genForEnd();
	}
	;

for_left_exp: statement ';' forStart for_exp
		| ';' for_exp
		| for_exp
		;
for_exp : expression
		{
			if($1->type!=Bool_type) yyerror("ERROR : for condition not boolean");
		}
		;
forStart:{ genForStart(); };

for_right: ';' statement
		 | ';'
		 |
		 ;

/* get const value, ex:123 */
const_value: INT_CONST { $$=intConst($1); }
		   | BOOL_CONST { $$=boolConst($1); }
		   | REAL_CONST { $$=realConst($1); }
		   | STR_CONST { $$=strConst($1); }
		   ;


expression : ID 
		   	{
				idInfo *tmp = stl.lookup(*$1);
				if(tmp == NULL) yyerror("undeclared identifier " + *$1);
				// transfer ConstVar_flag into ConstVal_flag
				if(tmp->flag == ConstVar_flag) tmp->flag = ConstVal_flag;
				$$ = tmp;
				if(!stl.isGlobal() && isConst(*tmp)){
					if(tmp->type == Str_type){
						genConstStr(tmp->value.sval);
					}else if (tmp->type == Int_type || tmp->type == Bool_type){
						genConstInt(getIntBoolValue(*tmp));
					}
				}else if(tmp->type == Int_type || tmp->type == Bool_type){
					int index = stl.getIndex(*$1);
					if(index == -1) genGetGlobalVar(*$1);
					else genGetLocalVar(index);
				}
			}
		   | const_value
			{
				if(!stl.isGlobal()){
					if($1->type == Str_type){
						genConstStr($1->value.sval);
					}else if ($1->type == Int_type || $1->type == Bool_type){
						genConstInt(getIntBoolValue(*$1));
					}
				}
			}
		   | ID '[' expression ']'
			{
				idInfo *tmp = stl.lookup(*$1);
				if(tmp == NULL) yyerror("undeclared identifier " + *$1);
				if(tmp->flag != Var_flag) yyerror("ERROR : " + *$1 + " not var");
				if(tmp->type != Array_type) yyerror("ERROR : " + *$1 + " not array");
				if($3->type != Int_type) yyerror("ERROR : index not integer");
				if($3->value.val >= tmp->value.aval.size()) yyerror("ERROR : array index out of range");
				$$ = new idInfo(tmp->value.aval[$3->value.val]);
			}
		   | func_invocation
		   | expression '+' expression
			{
				Trace("expression + expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type && $1->type != Real_type && $1->type != Str_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val + $3->value.val);
					}else if($1->type == Real_type){
						$$ = realConst($1->value.dval + $3->value.dval);
					}else if($1->type == Str_type){
						$$ = strConst(new string($1->value.sval + $3->value.sval));
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= $1->type;
					$$ = tmp;
				}
				if($1->type == Int_type) genOperator('+');
			}
		   | expression '-' expression
			{
				Trace("expression - expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type && $1->type != Real_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val - $3->value.val);
					}else if($1->type == Real_type){
						$$ = realConst($1->value.dval - $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= $1->type;
					$$ = tmp;
				}
				if($1->type == Int_type) genOperator('-');
			}
		   | expression '*' expression
			{
				Trace("expression * expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type && $1->type != Real_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val * $3->value.val);
					}else if($1->type == Real_type){
						$$ = realConst($1->value.dval * $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= $1->type;
					$$ = tmp;
				}
				if($1->type == Int_type) genOperator('*');
			}
		   | expression '/' expression
			{
				Trace("expression / expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type && $1->type != Real_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val / $3->value.val);
					}else if($1->type == Real_type){
						$$ = realConst($1->value.dval / $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= $1->type;
					$$ = tmp;
				}
				if($1->type == Int_type) genOperator('/');
			}
		   | expression '%' expression
			{
				Trace("expression \% expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val % $3->value.val);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= $1->type;
					$$ = tmp;
				}
				if($1->type == Int_type) genOperator('%');
			}
		   | expression '^' expression
			{
				Trace("expression ^ expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type && $1->type != Real_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst(pow($1->value.val, $3->value.val));
					}else if($1->type == Real_type){
						$$ = realConst(pow($1->value.dval, $3->value.dval));
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= $1->type;
					$$ = tmp;
				}
			}
		   | expression '<' expression
			{
				Trace("expression < expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type && $1->type != Real_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val < $3->value.val);
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval < $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type = Bool_type;
					$$ = tmp;
				}
				if($1->type == Int_type) genCondOp(IFLT);
			}
		   | expression '>' expression
			{
				Trace("expression > expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type && $1->type != Real_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val > $3->value.val);
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval > $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type = Bool_type;
					$$ = tmp;
				}
				if($1->type == Int_type) genCondOp(IFGT);
			}
		   | expression LE expression
			{
				Trace("expression <= expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type && $1->type != Real_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val <= $3->value.val);
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval <= $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= Bool_type;
					$$ = tmp;
				}
				if($1->type == Int_type) genCondOp(IFLE);
			}
		   | expression GE expression
			{
				Trace("expression >= expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type && $1->type != Real_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val >= $3->value.val);
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval >= $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= Bool_type;
					$$ = tmp;
				}
				if($1->type == Int_type) genCondOp(IFGE);
			}
		   | expression EQ expression
			{
				Trace("expression == expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type && $1->type != Real_type && $1->type != Bool_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val == $3->value.val);
					}else if($1->type == Bool_type){
						$$ = boolConst($1->value.bval == $3->value.bval);
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval == $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= Bool_type;
					$$ = tmp;
				}
				if($1->type == Int_type || $1->type == Bool_type) genCondOp(IFEQ);
			}
		   | expression NEQ expression
			{
				Trace("expression != expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type && $1->type != Real_type && $1->type != Bool_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val != $3->value.val);
					}else if($1->type == Bool_type){
						$$ = boolConst($1->value.bval != $3->value.bval);
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval != $3->value.dval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= Bool_type;
					$$ = tmp;
				}
				if($1->type == Int_type || $1->type == Bool_type) genCondOp(IFNE);
			}
		   | expression AND expression
			{
				Trace("expression && expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Bool_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Bool_type){
						$$ = boolConst($1->value.bval && $3->value.bval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= Bool_type;
					$$ = tmp;
				}
				if($1->type == Bool_type) genOperator('&');
			}
		   | expression OR expression
			{
				Trace("expression || expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Bool_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Bool_type){
						$$ = boolConst($1->value.bval || $3->value.bval);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= Bool_type;
					$$ = tmp;
				}
				if($1->type == Bool_type) genOperator('|');
			}
		   | '!' expression
			{
				Trace("!expression")
				if($2->type != Bool_type) yyerror("operator error");
				if($2->flag == ConstVal_flag){
					$$ = boolConst(!$2->value.bval);
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= Bool_type;
					$$ = tmp;
				}
				if($2->type == Bool_type) genOperator('!');
			}
		   | expression '&' expression
			{
				Trace("expression & expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val & $3->value.val);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= $1->type;
					$$ = tmp;
				}
				if($1->type == Int_type) genOperator('&');
			}
		   | expression '|' expression
			{
				Trace("expression | expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val | $3->value.val);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= $1->type;
					$$ = tmp;
				}
			}
		   | '-' expression %prec UMINUS
			{
				Trace("-expression")
				if($2->type != Int_type && $2->type != Real_type) yyerror("operator error");
				if($2->flag == ConstVal_flag){
					if($2->type == Int_type){
						$$ = intConst(-$2->value.val);
					}else if($2->type == Real_type){
						$$ = realConst(-$2->value.val);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= $2->type;
					$$ = tmp;
				}
				if($2->type == Int_type) genOperator('_');
			}
		   | '+' expression %prec UPLUS
			{
				Trace("+expression")
				if($2->type != Int_type && $2->type != Real_type) yyerror("operator error");
				if($2->flag == ConstVal_flag){
					if($2->type == Int_type){
						$$ = intConst($2->value.val);
					}else if($2->type == Real_type){
						$$ = realConst($2->value.val);
					}
				}else{
					idInfo *tmp = new idInfo();
					tmp->flag = Var_flag; tmp->type= $2->type;
					$$ = tmp;
				}
			}
		   | '(' expression ')'
			{
				Trace("(expression)")
				$$ = $2;
			}
		   ;


%%
void yyerror(string s) {
	cerr << "line " << linenum << ": " << s << endl;
	exit(1);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf ("Usage: %s filename\n", argv[0]);
        exit(1);
    }
	
	// open input file and check exist
    yyin = fopen(argv[1], "r");
	if(!yyin){
		cerr << "File not found !" << endl;
		exit(1);	
	}


	// open output file and check file extension
	string source = string(argv[1]);
	size_t found = source.find(".");
	if (found!=std::string::npos && source.substr(found,source.size()) == ".go"){
		outName = source.substr(0,found);
		out.open(outName + ".jasm");
	}else{
		cerr << "file extension error" << endl;
		exit(1);
	}
	
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error !");     /* syntax error */
	return 0; 
}
