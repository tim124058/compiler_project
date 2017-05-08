%{
#include <iostream>
#include <stdio.h>
using namespace std;
extern int yylex(void);
void yyerror(const char *);
%}
/* type */
%union {
	int val;
	double dval;
	bool bval; 
	string* sval;
}

/* tokens */

/* Operator : length > one char */
%token LT GT EQ NEQ ADDA SUBA MULA DIVA

/* keywords */
%token BREAK CASE CONTINUE DEFAULT ELSE FOR FUNC GO IF IMPORT NIL PRINT PRINTLN RETURN STRUCT SWITCH TYPE VAR WHILE
%token BOOL CONST INT REAL STRING VOID 

%token <sval> ID 
%token <val> INT_CONST 
%token <bval> BOOL_CONST 
%token <dval> REAL_CONST 
%token <sval> STR_CONST

/* type declare for non-terminal symbols */
%type <val> expression

%%
statement: ID '=' expression { printf("%s = %d\n", (*$1).c_str(), $3); }
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
