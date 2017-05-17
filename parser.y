%{
#include <iostream>
#include <stdio.h>
#include "symbols.hpp"
#include "lex.yy.cpp"
#define Trace(t) if (Opt_P) printf(t)
using namespace std;
void yyerror(string s);
int Opt_P = 1;
SymbolTableList stl;
%}
/* type */
%union {
	int val;
	double dval;
	bool bval; 
	string* sval;
	idInfo* idinfo;
}

/* tokens */

/* Operator : length > one char */
%token LE GE EQ NEQ ADDA SUBA MULA DIVA

/* keywords */
%token BREAK CASE CONTINUE DEFAULT ELSE FOR FUNC GO IF IMPORT NIL PRINT PRINTLN RETURN STRUCT SWITCH TYPE VAR WHILE READ
%token BOOL CONST INT REAL STRING VOID 

%token <sval> ID 
%token <val> INT_CONST 
%token <bval> BOOL_CONST 
%token <dval> REAL_CONST 
%token <sval> STR_CONST

/* type declare for non-terminal symbols */
 %type <idinfo> const_value expression

/* precedence */
%left '|'
%left '&'
%left '!'
%left '<' '>' LE GE EQ NEQ
%left '+' '-'
%left '*' '/' '%'
%left '^'
%nonassoc UMINUS UPLUS

%%
/* program form */
program: opt_var_dec opt_func_dec ;

/* optional variable and constant declarations */
opt_var_dec: var_dec opt_var_dec
		   | const_dec opt_var_dec
		   | /* zero or more */
		   ;

/* declaration constant */
const_dec: CONST ID '=' expression
		 {
			if($4->flag != ConstVal_flag && $4->flag != ConstVar_flag) yyerror("const assign error");
			$4->flag = ConstVar_flag;
			if(stl.insert(*$2,*$4) == -1) yyerror("variable redefinition");
		 }
		 ;

/* declaration variable */
var_dec: VAR ID var_type opt_assign
	   | VAR ID '[' expression ']' var_type
	   ;

opt_assign: '=' expression
		  |
		  ;

var_type: INT
		| REAL
		| STRING
		| BOOL
		;





opt_func_dec : func_dec opt_func_dec 
			 |	/* zero or more */
			 ;

func_dec : FUNC func_type ID {stl.pushTable();} '(' opt_params ')' '{'
			   opt_var_dec
			   opt_statement
		   '}' {if(!stl.popTable()) yyerror("pop symbol table error");}

func_type: INT
		 | REAL
		 | STRING
		 | BOOL
		 | VOID
		 ;

opt_params : params
			|
			;

/* param <,param,...>*/
params: params ',' param
	  | param
	  ;

param: ID var_type
	 ;

opt_statement: statement opt_statement
			 |
			 ;

statement: ID '=' expression
		 | ID '[' expression ']' '=' expression
		 | PRINT expression
		 | PRINTLN expression
		 | READ ID
		 | RETURN
		 | RETURN expression
		 | func_invocation
		 | GO func_invocation
		 | compound
		 | conditional
		 | loop
		 | expression
		 ;

func_invocation: ID '(' comma_separated_expression ')'
			   ;

/* expression <,expression,...,expression>*/
comma_separated_expression: comma_separated_expression ',' expression
						  | expression
						  ;


compound: '{' {stl.pushTable();}
		   		opt_var_dec
		   		opt_statement
		  '}' {if(!stl.popTable()) yyerror("pop symbol table error");}
		;

conditional: IF '(' expression ')' statement
		   | IF '(' expression ')' statement ELSE statement
		   ;

loop: FOR '(' for_exp  ')'
		statement
	;

for_exp: statement ';' expression ';' statement
	   | statement ';' expression
	   | expression ';' statement
	   | expression
	   ;

const_value: INT_CONST { $$=intConst($1); }
		   | BOOL_CONST { $$=boolConst($1); }
		   | REAL_CONST { $$=realConst($1); }
		   | STR_CONST { $$=strConst($1); }
		   ;


expression : ID 
		   	{
				idInfo *tmp;
				tmp = stl.lookup(*$1);
				if(tmp == NULL) yyerror("undeclared identifier " + *$1);
				if(tmp->flag == ConstVal_flag || tmp->flag == ConstVar_flag){
					tmp->flag = ConstVal_flag;
				}
				$$ = tmp;
			}
		   | const_value
		   | ID '[' expression ']'
		   | func_invocation
		   | expression '+' expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val + $3->value.val);
						cout << "# " << $$->value.val << " = " << $1->value.val << "+" << $3->value.val<<endl;
					}else if($1->type == Real_type){
						$$ = realConst($1->value.dval + $3->value.dval);
						cout << "# " << $$->value.dval << " = " << $1->value.dval << "+" << $3->value.dval<<endl;
					}else if($1->type == Str_type){
						$$ = strConst(new string($1->value.sval + $3->value.sval));
						cout << "# " << $$->value.sval << " = " << $1->value.sval << "+" << $3->value.sval<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression '-' expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val - $3->value.val);
						cout << "# " << $$->value.val << " = " << $1->value.val << "-" << $3->value.val<<endl;
					}else if($1->type == Real_type){
						$$ = realConst($1->value.dval - $3->value.dval);
						cout << "# " << $$->value.dval << " = " << $1->value.dval << "-" << $3->value.dval<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression '*' expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val * $3->value.val);
						cout << "# " << $$->value.val << " = " << $1->value.val << "*" << $3->value.val<<endl;
					}else if($1->type == Real_type){
						$$ = realConst($1->value.dval * $3->value.dval);
						cout << "# " << $$->value.dval << " = " << $1->value.dval << "*" << $3->value.dval<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression '/' expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val / $3->value.val);
						cout << "# " << $$->value.val << " = " << $1->value.val << "/" << $3->value.val<<endl;
					}else if($1->type == Real_type){
						$$ = realConst($1->value.dval / $3->value.dval);
						cout << "# " << $$->value.dval << " = " << $1->value.dval << "/" << $3->value.dval<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression '%' expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val % $3->value.val);
						cout << "# " << $$->value.val << " = " << $1->value.val << "%" << $3->value.val<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression '^' expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val ^ $3->value.val);
						cout << "# " << $$->value.val << " = " << $1->value.val << "^" << $3->value.val<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression '<' expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val < $3->value.val);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.val << "<" << $3->value.val<<endl;
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval < $3->value.dval);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.dval << "<" << $3->value.dval<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression '>' expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val > $3->value.val);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.val << ">" << $3->value.val<<endl;
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval > $3->value.dval);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.dval << ">" << $3->value.dval<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression LE expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val <= $3->value.val);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.val << "<=" << $3->value.val<<endl;
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval <= $3->value.dval);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.dval << "<=" << $3->value.dval<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression GE expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val >= $3->value.val);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.val << ">=" << $3->value.val<<endl;
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval >= $3->value.dval);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.dval << ">=" << $3->value.dval<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression EQ expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val == $3->value.val);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.val << "==" << $3->value.val<<endl;
					}else if($1->type == Bool_type){
						$$ = boolConst($1->value.bval == $3->value.bval);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.bval << "==" << $3->value.bval<<endl;
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval == $3->value.dval);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.dval << "==" << $3->value.dval<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression NEQ expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = boolConst($1->value.val != $3->value.val);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.val << "!=" << $3->value.val<<endl;
					}else if($1->type == Bool_type){
						$$ = boolConst($1->value.bval != $3->value.bval);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.bval << "!=" << $3->value.bval<<endl;
					}else if($1->type == Real_type){
						$$ = boolConst($1->value.dval != $3->value.dval);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << $1->value.dval << "!=" << $3->value.dval<<endl;
					}else yyerror("operator error");
				}
			}
		   | '!' expression
			{
				if($2->flag == ConstVal_flag){
					if($2->type == Bool_type){
						$$ = boolConst(!$2->value.bval);
						cout << "# " << (($$->value.bval)?"true":"false") << " = " << "!" << $2->value.bval<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression '&' expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val & $3->value.val);
						cout << "# " << $$->value.val << " = " << $1->value.val << "&" << $3->value.val<<endl;
					}else yyerror("operator error");
				}
			}
		   | expression '|' expression
			{
				if($1->type != $3->type) yyerror("type not match");
				if($1->flag == ConstVal_flag && $1->flag==$3->flag){
					if($1->type == Int_type){
						$$ = intConst($1->value.val | $3->value.val);
						cout << "# " << $$->value.val << " = " << $1->value.val << "|" << $3->value.val<<endl;
					}else yyerror("operator error");
				}
			}
		   | '-' expression %prec UMINUS
			{
				if($2->flag == ConstVal_flag){
					if($2->type == Int_type){
						$$ = intConst(-$2->value.val);
						cout << "# " << $$->value.val << " = " << "-" << $2->value.val<<endl;
					}else if($2->type == Real_type){
						$$ = realConst(-$2->value.val);
						cout << "# " << $$->value.val << " = " << "-" << $2->value.dval<<endl;
					}else yyerror("operator error");
				}
			}
		   | '+' expression %prec UPLUS
			{
				if($2->flag == ConstVal_flag){
					if($2->type == Int_type){
						$$ = intConst($2->value.val);
						cout << "# " << $$->value.val << " = " << "+" << $2->value.val<<endl;
					}else if($2->type == Real_type){
						$$ = realConst($2->value.val);
						cout << "# " << $$->value.val << " = " << "+" << $2->value.dval<<endl;
					}else yyerror("operator error");
				}
			}
		   | '(' expression ')'
			{
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
