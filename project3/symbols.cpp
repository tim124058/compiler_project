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

idInfo* SymbolTable::getIdInfoPtr(string s){
	if(isExist(s))
		return &symbol_i[s];
	else
		return NULL;
}

int SymbolTable::insert(string var_name, int type, idValue value, int flag){
	if(symbol_i.find(var_name) != symbol_i.end()){
		return -1;		// find it in SymbolTable
	}
	i_symbol.push_back(var_name);
	symbol_i[var_name].index = index;
	symbol_i[var_name].name = var_name;
	symbol_i[var_name].type = type;
	symbol_i[var_name].value = value;
	symbol_i[var_name].flag = flag;
	index++;
	return index-1;
}

/* dump */
int SymbolTable::dump(){
	for(int i=0;i<index;i++){
		idInfo tmp = symbol_i[i_symbol[i]];
		cout << i << ". " << getIdInfoStr(tmp) << endl;
	}
	return i_symbol.size();
}

int SymbolTable::size(){
	return i_symbol.size();
}
int SymbolTable::getIndex(string s){
	if(isExist(s))
		return symbol_i[s].index;
	else
		return 0;
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

// get s idInfo from SymbolTableList
// search s from top to 0
idInfo* SymbolTableList::lookup(string s){
	for(int i=top;i>=0;i--){
		if(list[i].isExist(s)){
			return list[i].lookup(s);
		}
	}
	return NULL;		// not found
}


/* INSERT */
int SymbolTableList::insertNoInit(string var_name, int type){
	return list[top].insert(var_name,type,idValue(), Var_flag);
}
int SymbolTableList::insertArray(string var_name, int type, int size){
	idValue tmp;
	tmp.aval = vector<idInfo>(size);
	for(int i = 0;i<size;i++){
		tmp.aval[i].index=-1;
		tmp.aval[i].type=type;
		tmp.aval[i].flag=Var_flag;
	}
	return list[top].insert(var_name,Array_type,tmp, Var_flag);
}
int SymbolTableList::insertFunc(string var_name, int type){
	funcname = var_name;
	return list[top].insert(var_name,type,idValue(), Func_flag);
}

int SymbolTableList::insert(string var_name, idInfo idinfo){
	return list[top].insert(var_name,idinfo.type,idinfo.value,idinfo.flag);
}

// set function parameters
bool SymbolTableList::setFuncParam(string name,int type){
	idInfo *f = list[top-1].getIdInfoPtr(funcname);
	if(f == NULL) return false;
	idInfo tmp;
	tmp.name = name;
	tmp.type = type;
	tmp.flag = Var_flag;
	f->value.aval.push_back(tmp);
	return true;
}

// get variable index ,-2,not found -1=>global , >0 =>local
int SymbolTableList::getIndex(string s){
	for(int i=top;i>=0;i--){
		if(list[i].isExist(s)){
			if(i==0){		// global
				return -1;
			}else{			// local
				int index = 0;
				for(int j = 1; j < i; j++) {
					index += list[j].size();
				}
				index += list[i].getIndex(s);
				return index;
			}
		}
	}
	return -2;		// not found

}
// current scope is Global
bool SymbolTableList::isGlobal(){
	if(top == 0){
		return true;
	}else{
		return false;
	}
}

/* dump */
int SymbolTableList::dump(){
	cout << "-------------- dump start --------------" << endl;
	for(int i=top;i>=0;i--){
		cout << "stack frame : " << i << endl;
		list[i].dump();
	}
	cout << "--------------  dump end  --------------" << endl;
	return list.size();
}


/* Build const value */
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

// transfar type enum into type name
string getTypeStr(int type){
		switch(type){
			case Int_type:
				return "int";
			case Bool_type:
				return "bool";
			case Real_type:
				return "real";
			case Str_type:
				return "string";
			case Array_type:
				return "array";
			case Void_type:
				return "void";
			default:
				return "ERROR!!!\n";
		}
}

// use type to get idValue value
string getValue(idValue value, int type){
		switch(type){
			case Int_type:
				return to_string(value.val);
			case Bool_type:
				return (value.bval?"true":"false");
			case Real_type:
				return to_string(value.dval);
			case Str_type:
				return "\"" + value.sval + "\"";
			case Array_type:
				return to_string(value.aval.size());
			default:
				return "ERROR!!!\n";
		}
}

// get function parameter string
string getParamStr(vector<idInfo> param){
	string s = "";
	for(int i = 0;i<param.size();i++){
		if(i!=0) s+=", ";
		s+= param[i].name + " " + getTypeStr(param[i].type);
	}
	return s;
}
// get function format string(declartion format)
string getFuncStr(idInfo tmp){
	if(tmp.flag != Func_flag) return "ERROR";
	return "func "+ getTypeStr(tmp.type) + " " + tmp.name + "(" + getParamStr(tmp.value.aval) + ")";
}

// return idInfo format string(declartion format)
string getIdInfoStr(idInfo tmp){
	string s = "";
	switch (tmp.flag) {
		case ConstVar_flag:
			s += "const";break;
		case Var_flag:
			s += "var";break;
		case Func_flag:
			s += getFuncStr(tmp);return s;
		default:
			return "ERROR!!!";
	}
	s+= " " + tmp.name + " ";
	if(tmp.type==Array_type){
		s +=  "[" + getValue(tmp.value,tmp.type)  + "]" + getTypeStr(tmp.value.aval[0].type);
	}else
		s += getTypeStr(tmp.type) + " = " + getValue(tmp.value,tmp.type);
	return s;
}

int getIntBoolValue(idInfo info){
	if(info.type == Bool_type){
		return info.value.bval;
	}
	return info.value.val;
}
