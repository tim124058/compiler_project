#include <iostream>
#include <map>
#include <vector>
#include <stdio.h>
using namespace std;

enum type{
	Int_type,
	Bool_type,
	Real_type,
	Str_type,
	Array_type,
	Void_type
};
enum idflag{
	ConstVal_flag,				// const value (123)
	ConstVar_flag,				// const variable (const a=123)
	Var_flag,					// variable
	Func_flag					// function
};

struct idInfo;
struct idValue{
	int val;					// integer
	bool bval; 					// boolean
	double dval;				// real
	string sval;				// string
	vector<idInfo> aval;		// array and function parameters
	idValue();
};

/* store constant or variable or function information */
struct idInfo{
	int index;
	string name;	// id name
	int type;		// enum type
	idValue value;	// value depend on type
	int flag;		// enum idflag
	idInfo();
};

/* symbol table */
class SymbolTable{
private:
	vector<string> i_symbol;			// use index to get variable name
	map<string,idInfo> symbol_i;		// use variable name get ifInfo
	int index;
public:
	SymbolTable();
	bool isExist(string);				// check variable in the SymbolTable
	idInfo* lookup(string);				// return Copied idInfo if variable in the SymbolTable (else return NULL)
	idInfo* getIdInfoPtr(string);		// return idInfo pointer if variable in the SymbolTable (else return NULL)
	int insert(string var_name, int type, idValue value, int flag);		// insert var into the SymbolTable
	int dump();							// dump the SymbolTable
};

/* 	symbol table list
 *  use a stack to implement variable scope
 */
class SymbolTableList{
private:
	int top;						// top of stack
	vector<SymbolTable> list;		// SymbolTable list
	string funcname;				// current function name
public:
	SymbolTableList();
	void pushTable();				// push a SymbolTable into list
	bool popTable();				// pop a SymbolTable from list
	idInfo* lookup(string);			// lookup all SymbolTable from list (from top to 0)
	
	/* insert a variable into the SymbolTable(current scope) */
	int insertNoInit(string var_name, int type);
	int insertArray(string var_name, int type, int size);
	int insertFunc(string var_name, int type);		// insert a function and start to set function parameter
	int insert(string var_name, idInfo idinfo);		// use name and idInfo

	bool setFuncParam(string,int);	// set function parameters

	int dump();						// dump all SymbolTable (from top to 0)
};

// Build const value
idInfo* intConst(int);
idInfo* boolConst(bool);
idInfo* realConst(double);
idInfo* strConst(string*);

// check the idInfo is a const
bool isConst(idInfo);

// transfar type enum to type name
string getTypeStr(int type);
// use type to get idValue value
string getValue(idValue value, int type);
// get function format string(declartion format)
string getFuncStr(idInfo);
// return idInfo format string(declartion format)
string getIdInfoStr(idInfo);
