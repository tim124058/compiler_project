# 編譯器 projet1


### 編譯指令

	$ make
	
or 

	$ flex project1.lex
	$ mv lex.yy.c lex.yy.cpp
	$ g++ -ll lex.yy.cpp -o scanner
	


### 執行

直接執行(`ctrl+d`結束輸入)：

	$ ./scanner


輸入檔案：

	$ cat HelloWorld.go | ./scanner	
	

### 輸出說明
1. Lexical Definitions  
輸入的每一行，會先輸出那一行的所有token，在輸出那行的行號和內容，  
token會用< >刮起來，代表它會被傳到parser，  
如果那行沒有輸出任何token(只輸出那行的內容)，代表那行是註解或是空白。  

2. Symbol Table  
dump出所有在symbol table中的id，  
輸出的格式為：`x : id`，  
x代表此id被加進symbol table中的順序(從0開始)。


