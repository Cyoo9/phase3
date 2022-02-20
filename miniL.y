%{
#include <stdio.h>
#include "lib.h"
#include <map>
#include <vector>
#include<string.h>
extern int yylex(); 
void yyerror(const char *msg);


std::string create_temp();
std::string create_label();
struct CodeNode {
	std::string name;
	std::string code;
	bool array; 
};
extern char *identToken;
extern int  numberToken;
extern int currLine;

int  count_names = 0;
bool isArray = false;
int temp_counter = 0;
int label_counter = 0;

enum Type { Integer, Array };
struct Symbol {
  std::string name;
  Type type;
};
struct Function {
  std::string name;
  std::vector<Symbol> declarations;
};

std::vector <Function> symbol_table;


Function *get_function() {
  int last = symbol_table.size()-1;
  return &symbol_table[last];
}

bool find(std::string &value) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      return true;
    }
  }
  return false;
}

void add_function_to_symbol_table(std::string &value) {
  Function f; 
  f.name = value; 
  symbol_table.push_back(f);
}

void add_variable_to_symbol_table(std::string &value, Type t) {
  Symbol s;
  s.name = value;
  s.type = t;
  Function *f = get_function();
  f->declarations.push_back(s);
}

void print_symbol_table(void) {
  printf("symbol table:\n");
  printf("--------------------\n");
  for(int i=0; i<symbol_table.size(); i++) {
    printf("function: %s\n", symbol_table[i].name.c_str());
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      printf("  locals: %s\n", symbol_table[i].declarations[j].name.c_str());
    }
  }
  printf("--------------------\n");
}


%}


%union{
  /* put your types here */
char *identToken;
int  numberToken;
struct CodeNode* code_node;
}
%error-verbose
%locations
%start prog_start
%token FUNCTION 
%token BEGIN_PARAMS
%token BEGIN_LOCALS
%token END_LOCALS
%token END_PARAMS
%token BEGIN_BODY 
%token END_BODY
%token INTEGER
%token ARRAY 
%token OF 
%token IF
%token THEN
%token ENDIF
%token ELSE 
%token WHILE 
%token DO 
%token BEGINLOOP
%token ENDLOOP
%token CONTINUE
%token WRITE
%token NOT
%token TRUE
%token FALSE
%token RETURN 
%token ADD 
%token SUB
%token MULT
%token DIV
%token MOD
%token READ
%left EQ
%left NEQ
%left LT
%left GT
%left LTE
%left GTE
%token SEMICOLON
%token COLON
%token COMMA
%token L_PAREN
%token R_PAREN
%token L_SQUARE_BRACKET
%token R_SQUARE_BRACKET
%token BREAK
%left ASSIGN
%token <identToken> IDENT
%token <numberToken> NUMBER
%type <code_node> function
%type <code_node> identifiers
%type <code_node> declaration declarations
%type <code_node> Ident 
%type <code_node> functions
%type <code_node> Var Vars
%type <code_node> Statement Statements ElseStatement
%type <code_node> Expression Expressions MultExp Term BoolExp RExp1 Comp
/* %start program */

%% 

  /* write your rules here */
prog_start: functions {};

functions: %empty {} | function functions {};


function: FUNCTION IDENT {
        std::string func_name = $2;
        add_function_to_symbol_table(func_name);
        CodeNode* node = new CodeNode;
        node->code += "func " + func_name + "\n";
        printf(node->code.c_str());

} SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY Statements END_BODY
{ 
	/* CodeNode* node = new CodeNode; 
	node->code += "endfunc\n"; 
	printf(node->code.c_str()); */

CodeNode* node = new CodeNode;
node->code = $6->code;

std::string init_params = $6->code;
int param_number = 0;
while(init_params.find(".") != std::string::npos) {
        size_t pos = init_params.find(".");
        init_params.replace(pos, 1, "=");
        std::string param = ", $";
        param.append(std::to_string(param_number++));
        param.append("\n");
        init_params.replace(init_params.find("\n", pos), 1, param);
}

node->code += init_params + $9->code;

std::string statements($12->code);
if(statements.find("continue") != std::string::npos) {
        printf("ERROR: Continue outside loop in function");
}
node->code += statements + "endfunc\n\n";

printf(node->code.c_str()); 
};  

declaration: identifiers COLON INTEGER {  
	CodeNode *node = new CodeNode;
	node->code = ". " + $1->name + "\n";
	node->name = $1->name;
	add_variable_to_symbol_table(node->name, Integer);
	/*print_symbol_table();*/
	$$ = node;
 }
| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
{ 
   if($5 <= 0) {
	char temp[128];
	snprintf(temp, 128, "Array size can't be less than 1!");
   }

   CodeNode* node = new CodeNode;
   node->code += ".[] " + $1->name + ", " + std::to_string($5) + "\n";
   add_variable_to_symbol_table($1->name, Array); 
   $$ = node; 
 };

declarations: %empty
{ 
CodeNode* node = new CodeNode;
$$ = node;
 } 
| declaration SEMICOLON declarations 
{ 
CodeNode* node = new CodeNode;
node->code = $1->code;
node->code += $3->code;
$$ = node; 
};

	
identifiers: Ident {
CodeNode* node = new CodeNode;
node->name = $1->name;
$$ = node;
 };


Statements: 
Statement SEMICOLON
{
CodeNode* node = new CodeNode;
node->code = $1->code;
$$ = node;
}
| Statement SEMICOLON Statements
{
CodeNode* node = new CodeNode;
node->code = $1->code;
node->code += $3->code;
$$ = node; 
};

Statement: READ Term { 
CodeNode* node = new CodeNode; 
node->code = $2->code + ".< " +  $2->name + "\n";
$$ = node;
} | 
BREAK
{
CodeNode* node = new CodeNode;
$$ = node;  
}  | Var ASSIGN Expression
{ 
	std::string var_name = $1->name;
	if (!find(var_name)){
		printf("ERRRRORRRR \n");
	}
	CodeNode *node = new CodeNode;
	node->code += $1->code + $3->code;
	std::string middle = $3->name; 
	if($1->array && $3->array) {
		middle = create_temp(); 
		node->code += ". " + middle + "\n" + "=[] " + middle + ", " + $3->name + "\n" + "[]= ";
	} else if($1->array) {
		node->code += "[]= ";
	} else if($3->array) {
		node->code += "=[] ";
	} else {
		node->code += "= ";
	}
	node->code += $1->name;
	node->code += ", " + middle + "\n";
	$$ = node;

}
                 | IF BoolExp THEN Statements ElseStatement ENDIF
		 {
			std::string then_begin = create_label();
			std::string after = create_label(); 
			CodeNode* node = new CodeNode;
			node->code += $2->code + "?:= " + then_begin + ", " + $2->name + "\n" + $5->code + ":= " + after + "\n" + ": " + then_begin + "\n" + $4->code + ": " + after + "\n"; 
			$$ = node;

		  }		 
                 | WHILE BoolExp BEGINLOOP Statements ENDLOOP
		 { 
			CodeNode* node = new CodeNode; 
			std::string beginWhile = create_label();
			std::string beginLoop = create_label();
			std::string endLoop = create_label();
			std::string statement = $4->code;
			std::string jump;
			jump.append(":= ");
			jump.append(beginWhile);
			while(statement.find("continue") != std::string::npos) {
				statement.replace(statement.find("continue"), 8, jump);
			}
			
			node->code += ": " + beginWhile + "\n" + $2->code + "?:= " + beginLoop + ", " + $2->name + "\n" + ":= " + endLoop + "\n" + ": " + beginLoop + "\n" + ": " + beginLoop + "\n" + statement + ":= " + beginWhile + "\n" + ": " + endLoop + "\n";
			$$ = node; 
		 }
                 | DO BEGINLOOP Statements ENDLOOP WHILE BoolExp
		 {
			CodeNode* node = new CodeNode;
			std::string beginLoop = create_label();
			std::string beginWhile = create_label();
			std::string statement = $3->code;
			std::string jump;
			jump.append(":=");
			jump.append(beginWhile);
			while(statement.find("continue") != std::string::npos) {
				statement.replace(statement.find("continue"), 8, jump); 
			}
			
			node->code+= ": " + beginLoop + "\n" + statement + ": " + beginWhile + "\n" + $6->code + "?:= " + beginLoop + ", " + $6->name + "\n";

			$$ = node; 
		 }
                 | WRITE Term
		 { 
			CodeNode* node = new CodeNode;
			node->code += $2->code + ".> " + $2->name + "\n";
			$$ = node;

		 }
                 | CONTINUE
		 { 
			CodeNode* node = new CodeNode;
			node->code = "continue\n";
			$$ = node; 
		  }
                 | RETURN Expression
		 { 
			CodeNode* node = new CodeNode;
			node->code += $2->code + "ret " + $2->name + "\n";
			$$ = node; 
		  }
;
ElseStatement:   %empty
{  
	CodeNode* node = new CodeNode;
	$$ = node; 
}
| ELSE Statements
{
	CodeNode* node = new CodeNode;
	node->code = $2->code;
	$$ = node;     
}
;

Var:             Ident L_SQUARE_BRACKET Expression R_SQUARE_BRACKET
{ 
	CodeNode* node = new CodeNode;
	node->name += $1->name + ", " + $3->name; 
	node->code += $3->code;
	add_variable_to_symbol_table(node->name, Array);
	$$ = node;
	$$->array = true;
}
                 | Ident
		 {
		CodeNode *node = new CodeNode;
		node->code = "";
		node->name = $1->name;
		
		if(!find(node->name)){
			printf("ERRORRRRRRRRRR\n");
		}	
		$$ = node;
		};

Vars:            Var
		{ 
			CodeNode* node = new CodeNode;
			node->code = $1->code + $1->name + "\n"; 
			$$ = node;
		
		}
                 | Var COMMA Vars
		 {  
			CodeNode* node = new CodeNode; 
			node->code += $1->code + $1->name + "\n" + $3->code;
			$$ = node; 
		 };

Expression:      MultExp
{ 
	CodeNode* node = new CodeNode;
	node->code = $1->code;
	node->name = $1->name;
	$$ = node; 
	$$->array = false;
}
                 | MultExp ADD Expression
		 { 
			CodeNode* node = new CodeNode; 
			node->name = strdup(create_temp().c_str());
			node->code += $1->code + $3->code + ". " + node->name + "\n" + "+ " + node->name + ", " + $1->name + ", " + $3->name + "\n";
			$$ = node;
		  }
                 | MultExp SUB Expression
		 {
			CodeNode* node = new CodeNode;
                        node->name = strdup(create_temp().c_str());
                        node->code += $1->code + $3->code + ". " + node->name + "\n" + "- " + node->name + ", " + $1->name + ", " + $3->name + "\n";
                        $$ = node;
 
		 }
;
Expressions:     %empty
{   
	CodeNode* node = new CodeNode;
	$$ = node;
 }
                 | Expression COMMA Expressions
		 { 
			CodeNode* node = new CodeNode;
			node->code += $1->code + "param " + $1->name + "\n" + $3->code;
			$$ = node; 
		 }
                 | Expression
		 { 
			CodeNode* node = new CodeNode;
			node->code += $1->code + "param " + $1->name + "\n";
			$$ = node; 
		 }
;

MultExp:         Term
{ 
	CodeNode* node = new CodeNode;
	node->code = $1->code;
	node->name = $1->name;
	$$ = node;	
}
                 | Term MULT MultExp
		 { 
			CodeNode* node = new CodeNode;
			node->name = strdup(create_temp().c_str());
			node->code += ". " + node->name + "\n" + $1->code + $3->code + "* " + node->name + ", " + $1->name + ", " + $3->name + "\n";
			$$ = node;  
		 }
                 | Term DIV MultExp
		 {
			CodeNode* node = new CodeNode;
                        node->name = strdup(create_temp().c_str());
                        node->code += ". " + node->name + "\n" + $1->code + $3->code + "/ " + node->name + ", " + $1->name + ", " + $3->name + "\n";
                        $$ = node;
			
 		 }
                 | Term MOD MultExp
		 {
			CodeNode* node = new CodeNode;
                        node->name = strdup(create_temp().c_str());
                        node->code += ". " + node->name + "\n" + $1->code + $3->code + "% " + node->name + ", " + $1->name + ", " + $3->name + "\n";
                        $$ = node;
  
		 }
;

Term:            Var
{ 
	CodeNode* node = new CodeNode;
	if($$->array) {
		std::string middle = create_temp();
		node->code += $1->code + ". " + middle + "\n" + "=[] " + middle + ", " + $1->name + "\n";
		$$->array  = false;
		node->name = middle;
	} else {
		node->code = $1->code;
		node->name = $1->name;
	}
	$$ = node;
}
                 | SUB Var
		{ 
			CodeNode* node = new CodeNode;
			node->name = strdup(create_temp().c_str());
			node->code += $2->code + ". " + node->name + "\n";
			if($2->array) {
				node->code += ("=[] ") + node->name + ", " + $2->name + "\n";
			} else {
				node->code += "= " + node->name + ", " + $2->name + "\n";
			}
			node->code += "* " + node->name + ", " + node->name + ", -1\n";
			$$ = node; 
			$$->array  = false; 
		}	
                 | NUMBER
		 {
				
			CodeNode *node = new CodeNode;
			node->name = std::to_string($1);
			$$ = node;
			
		}
                 | SUB NUMBER	 
		 {
			CodeNode* node = new CodeNode;
			node->code += "-" + std::to_string($2);
			$$ = node; 	 
		 }
                 | L_PAREN Expression R_PAREN
		 {
			CodeNode* node = new CodeNode;
			node->code += $2->code; 
			node->name = $2->name;
			$$ = node;
		 }
                 | SUB L_PAREN Expression R_PAREN
		 {   
			CodeNode* node = new CodeNode;
			node->name = $3->name;
			node->code += $3->code + "* " + $3->name + ", " + $3->name + ", -1\n";
			$$ = node;	
	 	 }
                 | Ident L_PAREN Expressions R_PAREN
		 {
			CodeNode* node = new CodeNode;
			node->name = strdup(create_temp().c_str());
			node->code += $3->code + ". " + node->name + "\n" + "call " + $1->name + ", " + node->name + "\n";
			$$ = node; 
		 }
;



BoolExp:            NOT RExp1 
{
	std::string dest = create_temp();
	CodeNode* node = new CodeNode;
	node->code += $2->code + ". " + dest + "\n" + "! " + dest + ", " + $2->name + "\n";
	$$ = node;  
}
                 | RExp1
                 {
			CodeNode* node = new CodeNode;
			node->code = $1->code;
			node->name = $1->name; 
			$$ = node;  
		 }

;
RExp1:           Expression Comp Expression
{ 

std::string dest = create_temp();
CodeNode* node = new CodeNode;
node->code += $1->code + $3->code + ". " + dest + "\n" + $2->name + dest + ", " + $1->name + ", " + $3->name + "\n";
$$ = node; 
}
                 | TRUE
		     { 
			CodeNode* node = new CodeNode;
		      	node->name = "1";
			$$ = node;
		     }
                 | FALSE
		     {
			CodeNode*  node = new CodeNode;
			node->name = "0";
			$$ = node;  
		     }
                 | L_PAREN BoolExp R_PAREN
		   {
			CodeNode* node = new CodeNode;
			node->code = $2->code;
			node->name = $2->name;
			$$ = node; 
		   }
;

Comp:            EQ
{
	CodeNode*  node = new CodeNode;
	node->name = "== ";
	$$ = node;		  
}

                 | NEQ
                 {
			    	CodeNode*  node = new CodeNode;
        			node->name = "!= ";
        			$$ = node;
   
		 }
                 | LT
                 { 
		        CodeNode*  node = new CodeNode;
        		node->name = "< ";
        		$$ = node;

		 }
                 | GT
                 {  
		        CodeNode*  node = new CodeNode;
       			node->name = "> ";
        		$$ = node;

		 }
                 | LTE
                 {   
        		CodeNode*  node = new CodeNode;
        		node->name = "<= ";
        		$$ = node;

		 }
                 | GTE
                 {
		        CodeNode*  node = new CodeNode;
        		node->name = ">= ";
        		$$ = node;
 
		 }
;



Ident: IDENT
{
CodeNode *node = new CodeNode;
node->code = "";
node->name = $1;
/*printf("there\n");
printf("Ident -> IDENT %s \n", $1);
CodeNode *node = new CodeNode;
printf("past node making \n");
node->code = "";
node->name = $1;
std::string error;
printf("here/n");
if(!find(node->name)){
	yyerror(error.c_str());
}
/*
if(!find(node->name, Integer, error)){
	yyerror(error.c_str());
}

add_variable_to_symbol_table(node->name, Integer);
print_symbol_table();
*/
$$ = node;

 };


%% 

int main(int argc, char **argv) {
   yyparse();
   return 0;
}

void yyerror(const char *msg) {
    /* implement your error handling */
extern int lineNum;
extern char* yytext; 

printf("ERROR %s at symbol \"%s\" on line %d\n", msg, yytext, lineNum); 
}

std::string create_temp() {
	std::string temp = "_temp" + std::to_string(temp_counter++);
	return temp;
}

std::string create_label() {
	std::string temp = "_label" + std::to_string(label_counter++);
	return temp;
}

