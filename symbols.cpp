#include "symbols.hpp"


// struct constructor
idValue::idValue(){
	val = 0;
	bval = false;
	dval = 0.0;
	sval = "";
}
idInfo::idInfo(){
	index = 0;
	type = Int_type;
	flag = Var_flag;
}

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

int SymbolTable::insert(string var_name, int type, idValue value, int flag){
	if(symbol_i.find(var_name) != symbol_i.end()){
		return -1;		// find it in SymbolTable
	}
	i_symbol.push_back(var_name);
	symbol_i[var_name].index = index;
	symbol_i[var_name].type = type;
	symbol_i[var_name].value = value;
	symbol_i[var_name].flag = flag;
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
	pushTable();
}

// push SymbolTable into SymbolTableList
void SymbolTableList::pushTable(){
	list.push_back(SymbolTable());
	top++;
}

// pop last SymbolTable in SymbolTableList, success->return true
bool SymbolTableList::popTable(){
	if(list.size() <=0)
		return false;

	list.pop_back();
	top--;
	return true;
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


int SymbolTableList::insertNoInit(string var_name, int type){
	return list[top].insert(var_name,type,idValue(), Var_flag);
}
int SymbolTableList::insert(string var_name, int type, int value, int flag){
	idValue tmp;
	tmp.val = value;
	return list[top].insert(var_name,type,tmp,flag);
}
int SymbolTableList::insert(string var_name, int type, bool value, int flag){
	idValue tmp;
	tmp.bval = value;
	return list[top].insert(var_name,type,tmp,flag);
}
int SymbolTableList::insert(string var_name, int type, double value, int flag){
	idValue tmp;
	tmp.dval = value;
	return list[top].insert(var_name,type,tmp,flag);
}
int SymbolTableList::insert(string var_name, int type, string value, int flag){
	idValue tmp;
	tmp.sval = value;
	return list[top].insert(var_name,type,tmp,flag);
}

int SymbolTableList::insert(string var_name, idInfo idinfo){
	return list[top].insert(var_name,idinfo.type,idinfo.value,idinfo.flag);
}

int SymbolTableList::dump(){
	for(int i=top;i>=0;i--){
		list[i].dump();
	}
	return list.size();
}


// Build const value
idInfo* intConst(int val){
	idInfo* tmp = new idInfo();
	tmp->index=0;
	tmp->type=Int_type;
	tmp->value.val=val;
	tmp->flag=ConstVal_flag;
	return tmp;
}
idInfo* boolConst(bool val){
	idInfo* tmp = new idInfo();
	tmp->index=0;
	tmp->type=Bool_type;
	tmp->value.bval=val;
	tmp->flag=ConstVal_flag;
	return tmp;
}
idInfo* realConst(double val){
	idInfo* tmp = new idInfo();
	tmp->index=0;
	tmp->type=Real_type;
	tmp->value.dval=val;
	tmp->flag=ConstVal_flag;
	return tmp;
}
idInfo* strConst(string* val){
	idInfo* tmp = new idInfo();
	tmp->index=0;
	tmp->type=Str_type;
	tmp->value.sval=*val;
	tmp->flag=ConstVal_flag;
	return tmp;
}


bool isConst(idInfo idinfo){
	if(idinfo.flag != ConstVal_flag && idinfo.flag != ConstVar_flag)
		return false;
	else 
		return true;
}
