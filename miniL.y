%{
#include <stdio.h>
#include "lib.h"
#include <map>
#include <vector>
#include<string.h>
extern int yylex(); 
void yyerror(const char *msg);



struct CodeNode {
	std::string name;
	std::string code;
};

extern int currLine;

char *identToken;
int numberToken;
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
  printf("get_function completed\n");
  return &symbol_table[last];
}

bool find(std::string &value) {
  Function *f = get_function();
  printf("got the function\n");
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
char * numberToken;
struct CodeNode* code_node;
}
%error-verbose
%locations
%start prog_start
%token FUNCTION 
%token BEGIN_PARAMS
%token BEGIN_LOCALS
%token END_LOCALS
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
%type <code_node> Var
%type <code_node> Statement
%type <code_node> Expression
%type <code_node> Term
/* %start program */

%% 

  /* write your rules here */
prog_start: %empty { printf("program -> epsilon\n"); }| function prog_start {  };


function: FUNCTION IDENT {
printf("passed\n");

	std::string func_name = $2;
  	add_function_to_symbol_table(func_name);
 }
SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY Statements END_BODY
{


std::string temp = "func ";
CodeNode* node = new CodeNode;
node->name = func_name;
node->code += std::string("\n") + func_name + $3->code;

std::string init_params = $3->code;
int param_number = 0;
while(init_params.find(".") != std::string::npos) {
        size_t pos = init_params.find(".");
        init_params.replace(pos, 1, "=");
        std::string param = ", $";
        param.append(std::to_string(param_number++));
        param.append("\n");
        init_params.replace(init_params.find("\n", pos), 1, param);
}

node->code += init_params + $6->code;

std::string statements($9->code);
if(statements.find("continue") != std::string::npos) {
        printf("ERROR: Continue outside loop in function");
}
node->code += statements + std::string("endfunc\n");

printf(node->code.c_str());
};

declaration: identifiers COLON INTEGER {  
	CodeNode *node = new CodeNode;
	node->code = ". " + $1->name + "\n";
	node->name = $1->name;
	add_variable_to_symbol_table(node->name, Integer);
	printf(node->code.c_str());
	print_symbol_table();
	$$ = node;
	printf("declaration -> identifiers COLON INTEGER\n");
 }
| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
{  printf("Declaration -> Identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER %d R_SQUARE_BRACKET OF INTEGER;\n"); };

declarations: %empty
{ printf("declarations -> epsilon\n"); } 
| declaration SEMICOLON declarations 
{ printf("declarations -> declaration SEMICOLON declarations\n"); };


identifiers: Ident {
 printf("identifiers -> Ident\n");
 };


Statements: 
Statement SEMICOLON
{
  printf("statements -> statement SEMICOLON\n");
}
| Statement SEMICOLON Statements
{
  printf("statements -> statement SEMICOLON statements\n");
};

Statement: READ Vars {  printf("Statement -> Read\n");} | BREAK { printf("Statement -> Break\n");}  | Var ASSIGN Expression
{printf("Statement -> Var ASSIGN Expression\n");
	std::string var_name = $1->name;
	if (!find(var_name)){
		printf("ERRRRORRRR \n");
	}
	printf("MADE IT TO HERE\n\n\n");
	CodeNode *node = new CodeNode;
	node->code = $3->code;
	printf("made it to heresasdasdasda\n\n\n");
	node->code += std::string("= ") + var_name + std::string(", ") + $3->name + std::string("\n");
	printf(node->code.c_str());
	$$ = node;

}
                 | IF BoolExp THEN Statements ElseStatement ENDIF
		 {printf("Statement -> IF BoolExp THEN Statements ElseStatement ENDIF\n");}		 
                 | WHILE BoolExp BEGINLOOP Statements ENDLOOP
		 {printf("Statement -> WHILE BoolExp BEGINLOOP Statements ENDLOOP\n");}
                 | DO BEGINLOOP Statements ENDLOOP WHILE BoolExp
		 {printf("Statement -> READ Vars\n");}
                 | WRITE Vars
		 {printf("Statement -> WRITE Vars\n");}
                 | CONTINUE
		 {printf("Statement -> CONTINUE\n");}
                 | RETURN Expression
		 {printf("Statement -> RETURN Expression\n");}
;
ElseStatement:   %empty
{printf("ElseStatement -> epsilon\n");}
                 | ELSE Statements
		 {printf("ElseStatement -> ELSE Statements\n");}
;

Var:             Ident L_SQUARE_BRACKET Expression R_SQUARE_BRACKET
{printf("Var -> Ident  L_SQUARE_BRACKET Expression R_SQUARE_BRACKET\n");}
                 | Ident
		 {
		CodeNode *node = new CodeNode;
		node->code = "";
		node->name = $1->name;
		if(!find(node->name)){
			printf("ERRORRRRRRRRRR\n");
		}	
		$$ = node;
		printf("Var -> Ident \n");}
;
Vars:            Var
{printf("Vars -> Var\n");}
                 | Var COMMA Vars
		 {printf("Vars -> Var COMMA Vars\n");}
;

Expression:      MultExp
{printf("Expression -> MultExp\n");}
                 | MultExp ADD Expression
		 {printf("Expression -> MultExp ADD Expression\n");}
                 | MultExp SUB Expression
		 {printf("Expression -> MultExp SUB Expression\n");}
;
Expressions:     %empty
{printf("Expressions -> epsilon\n");}
                 | Expression COMMA Expressions
		 {printf("Expressions -> Expression COMMA Expressions\n");}
                 | Expression
		 {printf("Expressions -> Expression\n");}
;

MultExp:         Term
{printf("MultExp -> Term\n");}
                 | Term MULT MultExp
		 {printf("MultExp -> Term MULT MultExp\n");}
                 | Term DIV MultExp
		 {printf("MultExp -> Term DIV MultExp\n");}
                 | Term MOD MultExp
		 {printf("MultExp -> Term MOD MultExp\n");}
;

Term:            Var
{printf("Term -> Var\n");}
                 | SUB Var
		 {printf("Term -> SUB Var\n");}
                 | NUMBER
		 {
				
			CodeNode *node = new CodeNode;
			node->code = "";
			node->name = $1;
			$$ = node;
			
			printf("Term -> NUMBER %d\n", $1);}
                 | SUB NUMBER
		 {printf("Term -> SUB NUMBER %d\n", $2);}
                 | L_PAREN Expression R_PAREN
		 {printf("Term -> L_PAREN Expression R_PAREN\n");}
                 | SUB L_PAREN Expression R_PAREN
		 {printf("Term -> SUB L_PAREN Expression R_PAREN\n");}
                 | Ident L_PAREN Expressions R_PAREN
		 {printf("Term -> Ident L_PAREN Expressions R_PAREN\n");}
;



BoolExp:            NOT RExp1 
{printf("relation_exp -> NOT relation_exp1\n");}
                 | RExp1
                 {printf("relation_exp -> relation_exp1\n");}

;
RExp1:           Expression Comp Expression
{printf("relation_exp -> Expression Comp Expression\n");}
                 | TRUE
		     {printf("relation_exp -> TRUE\n");}
                 | FALSE
		     {printf("relation_exp -> FALSE\n");}
                 | L_PAREN BoolExp R_PAREN
		   {printf("relation_exp -> L_PAREN BoolExp R_PAREN\n");}
;

Comp:            EQ
{printf("comp -> EQ\n");}
                 | NEQ
                 {printf("comp -> NEQ\n");}
                 | LT
                 {printf("comp -> LT\n");}
                 | GT
                 {printf("comp -> GT\n");}
                 | LTE
                 {printf("comp -> LTE\n");}
                 | GTE
                 {printf("comp -> GTE\n");}
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

