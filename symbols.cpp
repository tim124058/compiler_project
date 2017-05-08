#include "symbols.hpp"


/*
 *	SymbolTable
 */
SymbolTable::SymbolTable(){
	index = 0;
}

bool SymbolTable::isExist(string s){
	if(symbol_i.find(s) != symbol_i.end()){
		return true;
	}else{
		return false;
	}
}

idInfo* SymbolTable::lookup(string s){
	if(isExist(s))
		return new idInfo(symbol_i[s]);
	else
		return NULL;
}

int SymbolTable::insert(string s){
	if(symbol_i.find(s) != symbol_i.end()){
		return -1;		// find it in SymbolTable
	}
	i_symbol.push_back(s);
	symbol_i[s].index = index;
	index++;
	return index-1;
}

int SymbolTable::dump(){
	for(int i=0;i<index;i++){
		printf("%d : %s\n",i,i_symbol[i].c_str());
	}
	return i_symbol.size();
}



/*
 *	SymbolTableList
 */
SymbolTableList::SymbolTableList(){
	top = -1;
}

// push SymbolTable into SymbolTableList
void SymbolTableList::pushTable(SymbolTable stb){
	list.push_back(stb);
	top++;
}

// pop last SymbolTable in SymbolTableList
SymbolTable* SymbolTableList::popTable(SymbolTable){
	if(list.size() <=0)
		return NULL;

	SymbolTable *tmp = new SymbolTable(list.back());
	list.pop_back();
	return tmp;
}

// get s info from SymbolTableList
// search s from top to 0
idInfo* SymbolTableList::lookup(string s){
	for(int i=top;i>=0;i--){
		if(list[i].isExist(s)){
			return list[i].lookup(s);
		}
	}
	return NULL;		// not found
}
