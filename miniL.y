%{
#include <stdio.h>
#include "lib.h"
#include <map>
#include <vector>
#include<string>
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
%type <code_node>identifiers
%type <code_node> declaration declarations
%type <code_node> Ident
%type <code_node> functions
%type <code_node> Var Vars
%type <code_node> Statement Statements ElseStatement
%type <code_node> Expression Expressions MultExp Term BoolExp RExp1 Comp
/* %start program */

%% 

  /* write your rules here */
prog_start: %empty { }| function prog_start {  };


function: FUNCTION IDENT {
printf("passed\n");

	std::string func_name = $2;
  	add_function_to_symbol_table(func_name);
	printf("added func name to symbol table\n");
 } 
SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY Statements END_BODY
{
/*
std::string temp = "func ";
CodeNode* node = new CodeNode;
node->name = $2;
node->code += std::string("\n") + node->name + $5->code;

std::string init_params = $5->code;
int param_number = 0;
while(init_params.find(".") != std::string::npos) {
        size_t pos = init_params.find(".");
        init_params.replace(pos, 1, "=");
        std::string param = ", $";
        param.append(std::to_string(param_number++));
        param.append("\n");
        init_params.replace(init_params.find("\n", pos), 1, param);
}

node->code += init_params + $8->code;

std::string statements($11->code);
if(statements.find("continue") != std::string::npos) {
        printf("ERROR: Continue outside loop in function");
}
node->code += statements + std::string("endfunc\n");

printf(node->code.c_str()); */
};

declaration: identifiers COLON INTEGER {  
	CodeNode *node = new CodeNode;
	node->code = ". " + $1->name + "\n";
	node->name = $1->name;
	add_variable_to_symbol_table(node->name, Integer);
	/*print_symbol_table();*/
	$$ = node;
	printf(node->code.c_str());
 }
| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
{ 
   if($5 <= 0) {
	char temp[128];
	snprintf(temp, 128, "Array size can't be less than 1!");
   }
   std::string vars($1->name);
   std::string temp;
   std::string variable;
   bool cont = true;

   size_t oldpos = 0;
   size_t pos = 0;

   CodeNode* node = new CodeNode;
   while(cont) {
 	pos = vars.find("|", oldpos);
	if(pos == std::string::npos) {
		node->code = ".[] ";
		variable = vars.substr(oldpos, pos);
		node->code += variable + ", " + std::to_string($5) + "\n";
		cont = false;
	} 
	else {
		size_t len = pos - oldpos;
      		node->code = ".[] ";
		
     		variable = vars.substr(oldpos, len);
     		node->code += variable + ", " + std::to_string($5) + "\n";
		
	}
	if(find(variable)) { 
		char temp[128];
		snprintf(temp, 128, "Redeclaration of variable %s", variable.c_str());
		yyerror(temp);
	} else {
		add_variable_to_symbol_table(variable, Array);
	}

	oldpos = pos + 1;
   }
   $$ = node;
   printf(node->code.c_str());
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

Statement: READ Vars { 
CodeNode* node = new CodeNode; 
node->code = ".< " +  $2->code + "\n";
$$ = node;
printf(node->code.c_str());
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
	printf(node->code.c_str());
	$$ = node;

}
                 | IF BoolExp THEN Statements ElseStatement ENDIF
		 {
			std::string then_begin = create_label();
			std::string after = create_label(); 
			CodeNode* node = new CodeNode;
			node->code += $2->code + "?:= " + then_begin + ", " + $2->name + "\n" + $5->code + ":= " + after + "\n" + ": " + then_begin + "\n" + $4->code + ": " + after + "\n"; 
			$$ = node;
			printf(node->code.c_str());

		  }		 
                 | WHILE BoolExp BEGINLOOP Statements ENDLOOP
		 {  }
                 | DO BEGINLOOP Statements ENDLOOP WHILE BoolExp
		 { }
                 | WRITE Vars
		 { 
			CodeNode* node = new CodeNode;
			node->code += ".> " + $2->code + "\n";
			$$ = node;
			printf(node->code.c_str());
		 }
                 | CONTINUE
		 {   }
                 | RETURN Expression
		 {   }
;
ElseStatement:   %empty
{    }
                 | ELSE Statements
		 {    }
;

Var:             Ident L_SQUARE_BRACKET Expression R_SQUARE_BRACKET
{ $$->array = true;  }
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
			node->code = $1->code; 
			node->code = $1->name; 
			$$ = node;
		
		}
                 | Var COMMA Vars
		 {  };

Expression:      MultExp
{   }
                 | MultExp ADD Expression
		 { 
			CodeNode* node = new CodeNode; 
			node->name = create_temp().c_str();
			node->code += $1->code + $3->code + ". " + node->name + "\n" + "+ " + node->name + ", " + $1->name + ", " + $3->name + "\n";
			$$ = node;
		  }
                 | MultExp SUB Expression
		 {  }
;
Expressions:     %empty
{    }
                 | Expression COMMA Expressions
		 {  }
                 | Expression
		 {  }
;

MultExp:         Term
{  }
                 | Term MULT MultExp
		 {   }
                 | Term DIV MultExp
		 {  }
                 | Term MOD MultExp
		 {  }
;

Term:            Var
{   }
                 | SUB Var
		 {  }
                 | NUMBER
		 {
				
			CodeNode *node = new CodeNode;
			node->name = std::to_string($1);
			$$ = node;
			
		}
                 | SUB NUMBER
		 {  }
                 | L_PAREN Expression R_PAREN
		 { }
                 | SUB L_PAREN Expression R_PAREN
		 {   }
                 | Ident L_PAREN Expressions R_PAREN
		 {  }
;



BoolExp:            NOT RExp1 
{  }
                 | RExp1
                 { }

;
RExp1:           Expression Comp Expression
{  }
                 | TRUE
		     {  }
                 | FALSE
		     {  }
                 | L_PAREN BoolExp R_PAREN
		   { }
;

Comp:            EQ
{  }
                 | NEQ
                 {   }
                 | LT
                 {  }
                 | GT
                 {  }
                 | LTE
                 {   }
                 | GTE
                 { }
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

 }

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
	int num = 0;
	std::string temp = "_temp" + std::to_string(num++);
	return temp;
}

std::string create_label() {
	int num = 0;
	std::string temp = "_label" + std::to_string(num++);
	return temp;
}
