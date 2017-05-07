#include "symbols.hpp"
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
