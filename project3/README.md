# 編譯器 projet2


### 編譯指令

	$ make


### 執行

輸入檔案：

	$ cat test.go | ./parser

直接執行(`ctrl+d`結束輸入)：

	$ ./parser



### 輸出說明

預設會印出每一行，且遇到`}`時，印出當時scope的所有symbol table(由近到遠顯示)。  
如果parser.y中的Opt_P=1時會印出parse時的詳細資訊。  


### scanner變動
	1. #include "y.tab.hpp"
	2. 新增prtT、prtS，代表是否輸出token和source code的flag
	3. 將SymbolTable獨立出來，變成symbols.hpp和symbols.cpp
	4. 將用到SymbolTable的部分移除
	5. 設定token的回傳值
	6. 在id,bool,int,str的token部分，設定要傳給parser的值
	7. 移除main function

