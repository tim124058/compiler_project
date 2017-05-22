%{
#include <iostream>
#include <map>
#include <vector>
using namespace std;
#define LIST     strcat(buf,yytext)
#define token(t) {LIST; printf("<%s>\n",#t);}
#define tokenInteger(t,i) {LIST; printf("<%s:%d>\n",t,i);}
#define tokenString(t,s) {LIST; printf("<%s:%s>\n",t,s);}

#define MAX_LINE_LENG 256

int linenum = 1;
char buf[MAX_LINE_LENG];
char strbuf[MAX_LINE_LENG];

class SymbolTable{
private:
	vector<string> i_symbol;
	map<string,int> symbol_i;
	int index;
public:
	SymbolTable();
	int lookup(string s);
	int insert(string s);
	int dump();
};
SymbolTable *stb;

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
"(" {token('(');}
")" {token(')');}
"," {token(',');}
":" {token(':');}
";" {token(';');}
"[" {token('[');}
"]" {token(']');}
"{" {token('{');}
"}" {token('}');}

"+" {token('+');}
"-" {token('-');}
"*" {token('*');}
"/" {token('/');}

"^" {token('^');}
"%" {token('%');}

"<" {token('<');}
"<=" {token('<=');}
">" {token('>');}
">=" {token('>=');}
"==" {token('==');}
"!=" {token('!=');}

"&" {token('&');}
"|" {token('|');}
"!" {token('!');}
"=" {token('=');}

"+=" {token('+=');}
"-=" {token('-=');}
"*=" {token('*=');}
"/=" {token('/=');}

"bool" {token(BOOL);}
"break" {token(BREAK);}
"case" {token(CASE);}
"const" {token(CONST);}
"continue" {token(CONTINUE);}
"default" {token(DEFAULT);}
"else" {token(ELSE);}
"for" {token(FOR);}
"func" {token(FUNC);}
"go" {token(GO);}
"if" {token(IF);}
"import" {token(IMPORT);}
"int" {token(INT);}
"nil" {token(NIL);}
"print" {token(PRINT);}
"println" {token(PRINTLN);}
"real" {token(REAL);}
"return" {token(RETURN);}
"string" {token(STRING);}
"struct" {token(STRUCT);}
"switch" {token(SWITCH);}
"type" {token(TYPE);}
"var" {token(VAR);}
"void" {token(VOID);}
"while" {token(WHILE);}

"false" {tokenString("boolean","FALSE");}
"true" {tokenString("boolean","TRUE");}


{identifier} {
	tokenString("id",yytext);
	stb->insert(yytext);
}

{integer} {
	tokenInteger("integer",atoi(yytext));
}

{integer}"."{integer}([Ee][+-]{integer})? {
	tokenString("real",yytext);
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
	printf("[ERROR] at line %d, double quote not closed\n", linenum);
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
	printf("%d:%s\n", linenum+1, buf);
	printf("bad character:'%s'\n",yytext);
	exit(-1);
}
%%

SymbolTable::SymbolTable(){
	index = 0;
}
int SymbolTable::lookup(string s){
	if(symbol_i.find(s) != symbol_i.end()){
		return symbol_i[s];
	}else{
		return -1;		// not found
	}
}
int SymbolTable::insert(string s){
	if(symbol_i.find(s) != symbol_i.end()){
		return -1;		// find it in SymbolTable
	}
	i_symbol.push_back(s);
	symbol_i[s] = index;
	index++;
	return index-1;
}
int SymbolTable::dump(){
	for(int i=0;i<index;i++){
		printf("%d : %s\n",i,i_symbol[i].c_str());
	}
	return i_symbol.size();
}

void create(){
	stb = new SymbolTable();
}

int main(int argc, char *argv[]){
	create();
	yylex();
	cout << "\n\nSYMBOL TABLE : \n";
	stb->dump();
	fflush(yyout);
	exit(0);
}
