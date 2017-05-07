#include <iostream>
#include <map>
#include <vector>
#include <stdio.h>
using namespace std;

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
