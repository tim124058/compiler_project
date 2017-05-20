%{
#include <iostream>
#include <stdio.h>
#include "symbols.hpp"
#include "lex.yy.cpp"
#define Trace(t) if (Opt_P) cout<<"TRACE => "<<t<<endl;
using namespace std;
void yyerror(string s);
int Opt_P = 0;		// print trace message
int Opt_DS = 1;		// dump symboltable when function or compound parse finished
SymbolTableList stl;
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
%left '+' '-' '|' '^'
%left '*' '/' '%' '&'
/*%left '^'*/
%nonassoc UMINUS UPLUS
%nonassoc A
%nonassoc B
%%
/* program */
program: opt_var_dec opt_func_dec ;

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
		}
	   | VAR ID var_type '=' expression
		{
			Trace("declare variable with initial value");
			if(!isConst(*$5)) yyerror("ERROR : assign value not constant");
			if($3 != $5->type) yyerror("ERROR : type not match");
			$5->flag = Var_flag;
			if(stl.insert(*$2,*$5) == -1) yyerror("ERROR : variable redefinition");
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
			   opt_var_dec
			   opt_statement
		   '}' {if(Opt_DS)stl.dump();if(!stl.popTable()) yyerror("pop symbol table error");}

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
		 | PRINT expression { Trace("statement: print expression"); }
		 | PRINTLN expression { Trace("statement: print expression with new line"); }
		 | READ ID
		{
			Trace("statement: read user input to " + *$2);
			idInfo *tmp = stl.lookup(*$2);
			if(tmp == NULL) yyerror("undeclared identifier " + *$2);
			if(tmp->flag != Var_flag) yyerror("ERROR : " + *$2 + " not var, cannot be set value");
		}
		 | RETURN { Trace("statement: return"); }
		 | RETURN expression { Trace("statement: return expression"); }
		 | GO func_invocation
		 | compound { Trace("statement: compound"); }
		 | conditional
		 | loop
		 ;

/* function invocation */
func_invocation: ID '(' opt_comma_separated_expression ')'
				{
					Trace("call function");
					idInfo *tmp = stl.lookup(*$1);
					if(tmp == NULL) yyerror("undeclared identifier " + *$1);
					if(tmp->flag != Func_flag) yyerror("ERROR : " + *$1 + " not function");
					$$ = tmp;
				}
			   ;

/* actual parameter */
opt_comma_separated_expression: comma_separated_expression
							  |
							  ;

/* expression <,expression,...,expression>*/
comma_separated_expression: comma_separated_expression ',' expression
						  | expression
						  ;


/* compound */
compound: '{' {stl.pushTable();}
		   		opt_var_dec
		   		opt_statement
		  '}' {if(Opt_DS)stl.dump();if(!stl.popTable()) yyerror("ERROR : pop symbol table error");}
		;

conditional: IF '(' expression ')' statement
		    {
				Trace("if");
				if($3->type!=Bool_type) yyerror("ERROR : condition not boolean");
			}
		   | IF '(' expression ')' statement ELSE statement
		    {
				Trace("if else");
				if($3->type!=Bool_type) yyerror("ERROR : condition not boolean");
			}
		   ;

loop: FOR '(' for_left_exp for_right ')' statement
	{
		Trace("for");
	}
	;

for_left_exp: statement ';' for_exp
		| ';' for_exp
		| for_exp
		;
for_exp : expression
		{
			if($1->type!=Bool_type) yyerror("ERROR : for condition not boolean");
		}
		;

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
				//transfar ConstVar_flag to ConstVal_flag
				if(tmp->flag == ConstVar_flag) tmp->flag = ConstVal_flag;
				$$ = tmp;
			}
		   | const_value
		   | ID '[' expression ']'
			{
				idInfo *tmp = stl.lookup(*$1);
				if(tmp == NULL) yyerror("undeclared identifier " + *$1);
				if(tmp->flag != Var_flag) yyerror("ERROR : " + *$1 + " not var");
				if(tmp->type != Array_type) yyerror("ERROR : " + *$1 + " not array");
				if($3->type != Int_type) yyerror("ERROR : index not integer");
				if($3->value.val >= tmp->value.aval.size()) yyerror("ERROR : array index out of range");
				$$ = tmp;
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
			}
		   | expression '^' expression
			{
				Trace("expression ^ expression")
				if($1->type != $3->type) yyerror("ERROR : type not match");
				if($1->type != Int_type) yyerror("operator error");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val ^ $3->value.val);
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

int main(void) {
	yyparse();
	return 0; 
}
