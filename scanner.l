%{
#include <iostream>
using namespace std;
#include "y.tab.hpp"

#define LIST     strcat(buf,yytext)
#define token(t) {LIST; printf("<%s>\n",#t);}
#define tokenInteger(t,i) {LIST; printf("<%s:%d>\n",t,i);}
#define tokenString(t,s) {LIST; printf("<%s:%s>\n",t,s);}

#define MAX_LINE_LENG 256

int linenum = 1;				// line number
char buf[MAX_LINE_LENG];		// line buffer
char strbuf[MAX_LINE_LENG];		// string buffer

%}

whitespace [ \t]+
digit [0-9]
letter [a-zA-Z]
identifier {letter}({digit}|{letter})*
integer {digit}+


/* states */
%x COMMENT
%x STR

%%
"(" {token('('); return yytext[0];}
")" {token(')'); return yytext[0];}
"," {token(','); return yytext[0];}
":" {token(':'); return yytext[0];}
";" {token(';'); return yytext[0];}
"[" {token('['); return yytext[0];}
"]" {token(']'); return yytext[0];}
"{" {token('{'); return yytext[0];}
"}" {token('}'); return yytext[0];}

"+" {token('+'); return yytext[0];}
"-" {token('-'); return yytext[0];}
"*" {token('*'); return yytext[0];}
"/" {token('/'); return yytext[0];}

"^" {token('^'); return yytext[0];}
"%" {token('%'); return yytext[0];}

"<" {token('<'); return yytext[0];}
">" {token('>'); return yytext[0];}
"<=" {token('<='); return LT;}
">=" {token('>='); return GT;}
"==" {token('=='); return EQ;}
"!=" {token('!='); return NEQ;}

"&" {token('&'); return yytext[0];}
"|" {token('|'); return yytext[0];}
"!" {token('!'); return yytext[0];}
"=" {token('='); return yytext[0];}

"+=" {token('+='); return ADDA;}
"-=" {token('-='); return SUBA;}
"*=" {token('*='); return MULA;}
"/=" {token('/='); return DIVA;}

"bool" {token(BOOL); return BOOL;}
"break" {token(BREAK); return BREAK;}
"case" {token(CASE); return CASE;}
"const" {token(CONST); return CONST;}
"continue" {token(CONTINUE); return CONTINUE;}
"default" {token(DEFAULT); return DEFAULT; }
"else" {token(ELSE); return ELSE;}
"for" {token(FOR); return FOR;}
"func" {token(FUNC); return FUNC;}
"go" {token(GO); return GO;}
"if" {token(IF); return IF;}
"import" {token(IMPORT); return IMPORT;}
"int" {token(INT); return INT;}
"nil" {token(NIL); return NIL;}
"print" {token(PRINT); return PRINT;}
"println" {token(PRINTLN); return PRINTLN;}
"real" {token(REAL); return REAL;}
"return" {token(RETURN); return RETURN;}
"string" {token(STRING); return STRING;}
"struct" {token(STRUCT); return STRUCT;}
"switch" {token(SWITCH); return SWITCH;}
"type" {token(TYPE); return TYPE;}
"var" {token(VAR); return VAR;}
"void" {token(VOID); return VOID;}
"while" {token(WHILE); return WHILE;}

"false" {tokenString("boolean","FALSE"); return BOOL_CONST;}
"true" {tokenString("boolean","TRUE"); return BOOL_CONST;}


{identifier} {
	tokenString("id",yytext);
	yylval.sval = new string(yytext);
	return ID;
}

{integer} {
	tokenInteger("integer",atoi(yytext));
	yylval.val = atoi(yytext);
	return INT_CONST;
}

{integer}"."{integer}([Ee][+-]{integer})? {
	tokenString("real",yytext);
	return REAL_CONST;
}



"\"" {
	LIST;
	strbuf[0]='\0';
	BEGIN STR;
}

<STR>"\"" {
	char c = yyinput();
	if(c != '"'){
		strcat(buf,"\"");
		printf("<%s: %s>\n", "string", strbuf);
		unput(c);
		BEGIN INITIAL;
		return STR_CONST;
	}else{
		strcat(buf,"\"\"");
		strcat(strbuf,"\"");
	}
}

<STR>[^"\n]* {
	LIST;
	strcat(strbuf,yytext);
}

<STR>"\n" {
	fprintf(stderr, "[ERROR] at line %d, double quote not closed\n", linenum);
	exit(-1);
}



"//"[^\n]* {LIST;}
"/*" {
	LIST;
	BEGIN COMMENT;
}

<COMMENT>\n {
	LIST;
	printf("%d: %s", linenum++, buf);
	buf[0] = '\0';
}
<COMMENT>. {
	LIST;
}

<COMMENT>"*/" {
	LIST;
	BEGIN INITIAL;
}
"*/" {LIST;}



\n {
	LIST;
	printf("%d: %s", linenum++, buf);
	buf[0] = '\0';
}

{whitespace} {LIST;}

. {
	LIST;
	fprintf(stderr, "%d:%s\n", linenum+1, buf);
	fprintf(stderr, "bad character:'%s'\n",yytext);
	exit(-1);
}
%%
