%{
#include <iostream>
#include <stdio.h>
using namespace std;
extern int yylex(void);
extern int yylineno;
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
%token BREAK CASE CONTINUE DEFAULT ELSE FOR FUNC GO IF IMPORT NIL PRINT PRINTLN RETURN STRUCT SWITCH TYPE VAR WHILE READ
%token BOOL CONST INT REAL STRING VOID 

%token <sval> ID 
%token <val> INT_CONST 
%token <bval> BOOL_CONST 
%token <dval> REAL_CONST 
%token <sval> STR_CONST

/* type declare for non-terminal symbols */
/* %type <val> expression */

/* precedence */
%left '|'
%left '&'
%left '!'
%left '<' '>' LT GT EQ NEQ
%left '+' '-'
%left '*' '/' '%'
%left '^'
%nonassoc UMINUS

%%
/* program form */
program: opt_var_dec opt_func_dec ;

/* optional variable and constant declarations */
opt_var_dec: var_dec opt_var_dec
		   | const_dec opt_var_dec
		   | /* zero or more */
		   ;

/* declaration constant */
const_dec: CONST ID '=' const_exp
		 ;

/* declaration variable */
var_dec: VAR ID var_type opt_assign
	   | VAR ID '[' const_exp ']' var_type
	   ;

opt_assign: '=' const_exp
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

func_dec : FUNC func_type ID '(' opt_params ')' '{'
			   opt_var_dec
			   opt_statement
		   '}'

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
		 | ID ADDA expression
		 | ID SUBA expression
		 | ID MULA expression
		 | ID DIVA expression
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


compound: '{'
		   		opt_var_dec
		   		opt_statement
		  '}'
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

const_value: INT_CONST
		   | BOOL_CONST
		   | REAL_CONST
		   | STR_CONST
		   ;


const_exp: const_value
		 | const_exp '+' const_exp
		 | const_exp '-' const_exp
		 | const_exp '*' const_exp
		 | const_exp '/' const_exp
		 | const_exp '%' const_exp
		 | const_exp '^' const_exp
		 | const_exp '<' const_exp
		 | const_exp '>' const_exp
		 | const_exp LT const_exp
		 | const_exp GT const_exp
		 | const_exp EQ const_exp
		 | const_exp NEQ const_exp
		 | '!' const_exp
		 | const_exp '&' const_exp
		 | const_exp '|' const_exp
		 | '-' const_exp %prec UMINUS
		 | '(' const_exp ')'
	 	 ;

expression : ID
		   | const_exp
		   | ID '[' expression ']'
		   | func_invocation
		   | expression '+' expression
		   | expression '-' expression
		   | expression '*' expression
		   | expression '/' expression
		   | expression '%' expression
		   | expression '^' expression
		   | expression '<' expression
		   | expression '>' expression
		   | expression LT expression
		   | expression GT expression
		   | expression EQ expression
		   | expression NEQ expression
		   | '!' expression
		   | expression '&' expression
		   | expression '|' expression
		   | '-' expression %prec UMINUS
		   | '(' expression ')'
		   ;


/*statement: ID '=' expression { printf("%s = %d\n", (*$1).c_str(), $3); }*/
		 /*| expression 	{ printf("= %d\n", $1); }*/
		 /*;*/
/*expression: expression '+' INT_CONST { $$ = $1 + $3; } */
		  /*| expression '-' INT_CONST { $$ = $1 - $3; }*/
		  /*| INT_CONST {$$=$1;}*/
		  /*; */
%%
void yyerror(const char *s) {
	fprintf(stderr, "line %d: %s\n", yylineno, s);
	exit(1);
}

int main(void) {
	yyparse();
	return 0; 
}
