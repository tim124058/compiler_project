%{
#include <iostream>
#include <stdio.h>
using namespace std;
extern int yylex(void);
void yyerror(const char *);
%}
%union {
	int val;
	double dval;
	bool bval; 
	string* sval;
}


%token LT GT EQ NEQ ADDA SUBA MULA DIVA
%token BOOL BREAK CASE CONST CONTINUE DEFAULT ELSE FOR FUNC GO IF IMPORT INT NIL PRINT PRINTLN REAL RETURN STRING STRUCT SWITCH TYPE VAR VOID WHILE

%token NAME BOOL_CONST ID REAL_CONST STR_CONST
%token <val> INT_CONST 

%type <val> expression
%%
statement: NAME '=' expression 
		 | expression 	{ printf("= %d\n", $1); }
		 ;
expression: expression '+' INT_CONST { $$ = $1 + $3; } 
		  | expression '-' INT_CONST { $$ = $1 - $3; }
		  | INT_CONST {$$=$1;}
		  ; 
%%
void yyerror(const char *s) {
	fprintf(stderr, "%s\n", s);
	exit(1);
}

int main(void) {
	yyparse();
	return 0; 
}
