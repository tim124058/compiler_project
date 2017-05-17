#include <iostream>
#include <map>
#include <vector>
#include <stdio.h>
using namespace std;

enum type{
	Int_type,
	Bool_type,
	Real_type,
	Str_type
};
enum idflag{
	ConstVal_flag,
	ConstVar_flag,
	VarInit_flag,
	VarNoInit_flag
};

struct idValue{
	int val;
	bool bval; 
	double dval;
	string sval;
	idValue();
};

/*
 * flag : 0->const value, 1->const variable, 2->variable with init value , 3-> variable without init value
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
	int insert(string id, int type, idValue value, int flag);
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
	int insertNoInit(string id, int type);
	int insert(string id, int type, int value, int flag);
	int insert(string id, int type, bool value, int flag);
	int insert(string id, int type, double value, int flag);
	int insert(string id, int type, string value, int flag);
	int insert(string id, idInfo idinfo);
};

// Build const value
idInfo* intConst(int);
idInfo* boolConst(bool);
idInfo* realConst(double);
idInfo* strConst(string*);
