#include <iostream>
#include <map>
#include <vector>
#include <stdio.h>
using namespace std;

struct idInfo{
	int index;
	string type;
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
	int insert(string);
	int dump();
};

class SymbolTableList{
private:
	int top;
	vector<SymbolTable> list;
public:
	SymbolTableList();
	void pushTable(SymbolTable);
	SymbolTable* popTable(SymbolTable);
	idInfo* lookup(string);
};
