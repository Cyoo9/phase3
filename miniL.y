    /* cs152-miniL phase2 */
%{
#include <stdio.h>
#include "lib.h"
#include <map>
#include <vector>

extern int yylex(); 
void yyerror(const char *msg);

%}


%union{
  /* put your types here */
char *identToken;
int numberToken;

}
%error-verbose
%locations
%start prog_start
%token FUNCTION 
%token BEGIN_PARAMS
%token END_PARAMS
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

/* %start program */

%% 

  /* write your rules here */
prog_start: %empty { printf("program -> epsilon\n"); }| functions {printf("program -> functions\n"); };

functions: %empty { printf("functions -> epsilon\n"); } 
| function functions { printf("functions -> function functions\n"); };

function: FUNCTION IDENT SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY Statements END_BODY
{ printf("function -> FUNCTION IDENT SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY Statements END_BODY\n"); };

declaration: identifiers COLON INTEGER {  printf("declaration -> identifiers COLON INTEGER\n"); }
| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {  printf("Declaration -> Identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER %d R_SQUARE_BRACKET OF INTEGER;\n"); };

declarations: %empty { printf("declarations -> epsilon\n"); } 
| declaration SEMICOLON declarations { printf("declarations -> declaration SEMICOLON declarations\n"); };


identifiers: Ident { printf("identifiers -> Ident\n"); };


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
{printf("Statement -> Var ASSIGN Expression\n");}
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
		 {printf("Var -> Ident \n");}
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
		 {printf("Term -> NUMBER %d\n", $1);}
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
{printf("Ident -> IDENT %s \n", $1); }

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
