%{

int lineNum = 1;
int columnNum = 0;
#include <string.h>
#include "miniL-parser.hpp"
%}

   /* some common rules */
digit [0-9]
%%
   /* specific lexer rules in regex */
"function" {return FUNCTION; columnNum++;}
"beginparams" {return BEGIN_PARAMS; columnNum++;}
"endparams" {return END_PARAMS; columnNum++;}
"beginlocals" {return BEGIN_LOCALS; columnNum++;}
"endlocals" {return END_LOCALS; columnNum++;}
"beginbody" {return BEGIN_BODY; columnNum++;}
"endbody" {return END_BODY; columnNum++;}
"integer" {return INTEGER;columnNum++;}
"array" {return ARRAY; columnNum++;}
"of" {return OF; columnNum++;}
"if" {return IF;columnNum++;}
"then" {return THEN; columnNum++;}
"endif" {return ENDIF; columnNum++;}
"else" {return ELSE; columnNum++;}
"while" {return WHILE; columnNum++;}
"do" {return DO; columnNum++;}
"beginloop" {return BEGINLOOP; columnNum++;}
"endloop" {return ENDLOOP; columnNum++;}
"continue" {return CONTINUE; columnNum++;}
"break" { return BREAK; columnNum++;}
"read" { return READ; columnNum++;}
"write" {return WRITE; columnNum++;}
"not" {return NOT; columnNum++;}
"true" {return TRUE; columnNum++;}
"false" {return FALSE; columnNum++;}
"return" {return RETURN; columnNum++;}
"+" {return ADD; columnNum++;}
{digit}+ {
  columnNum++;
  yylval.numberToken = atoi(yytext);
  return NUMBER;
}
"-" {return SUB; columnNum++;}
"*" {return MULT; columnNum++;}
"/" {return DIV; columnNum++;}
"%" {return MOD; columnNum++;}
"==" {return EQ; columnNum++;}
"<>" {return NEQ; columnNum++;}
"<" {return LT; columnNum++;}
">" {return GT; columnNum++;}
"<=" {return LTE; columnNum++;}
">=" {return GTE; columnNum++;}
";" {return SEMICOLON; columnNum++;}
":" {return COLON; columnNum++;}
"," {return COMMA; columnNum++;}
"(" {return L_PAREN; columnNum++;}
")" {return R_PAREN; columnNum++;}
"[" {return L_SQUARE_BRACKET; columnNum++;}
"]" {return R_SQUARE_BRACKET; columnNum++;}
":=" {return ASSIGN; columnNum++;}
##.+ {columnNum++;}
[a-zA-Z]+([_a-zA-Z0-9]*[a-zA-Z0-9]+)?  {
   columnNum++;
   yylval.identToken = yytext; 
   return IDENT;
}
[0-9][a-zA-Z]+[_a-zA-Z0-9]+[a-zA-Z0-9]+ {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", lineNum, columnNum, yytext); exit(1);} 
[0-9][a-zA-Z]+[a-zA-Z0-9]* {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", lineNum, columnNum, yytext); exit(1);} 
_[a-zA-Z]+[_a-zA-Z0-9]+[a-zA-Z0-9]+  { printf("Error at line %d, column %d: identifier \"%s\" cannot begin with an underscore\n", lineNum, columnNum, yytext); exit(1);}
_[a-zA-Z]+[a-zA-Z0-9]*  { printf("Error at line %d, column %d: identifier \"%s\" cannot begin with an underscore\n", lineNum, columnNum, yytext); exit(1);}
[a-zA-Z]+[_a-zA-Z0-9]+[a-zA-Z0-9]+_  { printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", lineNum, columnNum, yytext); exit(1);}
[a-zA-Z]+[a-zA-Z0-9]*_  { printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", lineNum, columnNum, yytext); exit(1);}
"\n" {lineNum += 1; columnNum = 0; printf("");} 
[!$^&_|~=`?./] {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", lineNum, columnNum, yytext); exit(1);} 
[ \t] { }

%%
	/* C functions used in lexer */

