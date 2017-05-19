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
	ConstVal_flag,
	ConstVar_flag,
	Var_flag,
	Func_flag
};

struct idInfo;
struct idValue{
	int val;
	bool bval; 
	double dval;
	string sval;
	vector<idInfo> aval;
	idValue();
};

/*
 * flag : 0->const value, 1->const variable, 2->variable
 */
struct idInfo{
	int index;
	int type;
	idValue value;
	int flag;
	idInfo();
};

class SymbolTable{
private:
	vector<string> i_symbol;
	map<string,idInfo> symbol_i;
	int index;
public:
	SymbolTable();
	bool isExist(string);
	idInfo* lookup(string);
	int insert(string var_name, int type, idValue value, int flag);
	int dump();
};

class SymbolTableList{
private:
	int top;
	vector<SymbolTable> list;
public:
	SymbolTableList();
	void pushTable();
	bool popTable();
	idInfo* lookup(string);
	int insertNoInit(string var_name, int type);
	int insertArray(string var_name, int type, int size);
	int insertFunc(string var_name, int type);
	int insert(string var_name, int type, int value, int flag);
	int insert(string var_name, int type, bool value, int flag);
	int insert(string var_name, int type, double value, int flag);
	int insert(string var_name, int type, string value, int flag);
	int insert(string var_name, idInfo idinfo);
	int dump();
};

// Build const value
idInfo* intConst(int);
idInfo* boolConst(bool);
idInfo* realConst(double);
idInfo* strConst(string*);

bool isConst(idInfo);
