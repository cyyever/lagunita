/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed"); \


char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

static int comment_level;
static int string_has_null;
static int nested_lineno;

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
DIGIT		[0-9]
ID		[0-9a-zA-Z_]

%x COMMENT
%x STRING

%%

 /*
  *  comments
  */

"--".*			;

 /*
  *  Nested comments
  */

<INITIAL,COMMENT>"(*"	{ BEGIN(COMMENT); 
			  if (comment_level == 0) nested_lineno = curr_lineno;
	 		  comment_level++; }

<COMMENT>\n		{ nested_lineno++; }


<COMMENT>"*)"		{ comment_level--;
			  if (comment_level == 0) {
				  BEGIN(INITIAL);
				  curr_lineno = nested_lineno;
			  }
			}

<COMMENT>.		;

<COMMENT><<EOF>>	{ BEGIN(INITIAL);
			  cool_yylval.error_msg = "EOF in comment";
			  return (ERROR); }

"*)"			{ cool_yylval.error_msg = "Unmatched *)";
			  return (ERROR); }

 /*
  *  The multiple-character operators.
  */

{DARROW}		{ return (DARROW); }

"<-"			{ return (ASSIGN); }
"<="			{ return (LE); }

 /*
  *  The special notation.
  */

";"			|
"{"			|
"}"			|
","			|
":"			|
"@"			|
"."			|
"+"			|
"-"			|
"*"			|
"/"			|
"~"			|
"<"			|
"="			|
"("			|
")"			{ return yytext[0];} 


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

(?i:class)		{ return (CLASS); }

(?i:else)		{ return (ELSE); }

(?i:fi)			{ return (FI); }

(?i:if)			{ return (IF); }

(?i:in)			{ return (IN); }

(?i:inherits)		{ return (INHERITS); }

(?i:isvoid)		{ return (ISVOID); }

(?i:let)		{ return (LET); }

(?i:loop)		{ return (LOOP); }

(?i:pool)		{ return (POOL); }

(?i:then)		{ return (THEN); }

(?i:while)		{ return (WHILE); }

(?i:case)		{ return (CASE); }

(?i:esac)		{ return (ESAC); }

(?i:new)		{ return (NEW); }

(?i:of)			{ return (OF); }

(?i:not)		{ return (NOT); }

t(?i:rue)		{ cool_yylval.boolean = 1;
        		  return (BOOL_CONST); }

f(?i:alse)		{ cool_yylval.boolean = 0;
       		  	  return (BOOL_CONST); }

 /*
  *  Integer constants
  */

{DIGIT}+		{ cool_yylval.symbol = inttable.add_string(yytext);
			  return (INT_CONST); }

 /*
  *  Identifiers
  */

"self"			|
[a-z]{ID}*		{ cool_yylval.symbol = idtable.add_string(yytext);
			  return (OBJECTID); }

"SELF_TYPE"		|
[A-Z]{ID}*		{ cool_yylval.symbol = idtable.add_string(yytext);
			  return (TYPEID); }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\"			{ BEGIN(STRING);
			  nested_lineno = curr_lineno;
			  string_has_null = 0;
			  string_buf_ptr = string_buf;
			  *string_buf_ptr = '\0'; }


<STRING>[^\n\0\\\"]+	{ int cnt = yyleng;
			  if (string_buf_ptr + cnt - string_buf > MAX_STR_CONST -1 ) string_buf_ptr = string_buf + MAX_STR_CONST;	// too long string
			  else {
				  memcpy(string_buf_ptr,yytext,cnt);
				  string_buf_ptr += cnt;
				  *string_buf_ptr = '\0'; }
			}

<STRING>\\(.|\n)	{ if (string_buf_ptr - string_buf < MAX_STR_CONST -1 ) {
				switch (yytext[1]) {
				case 'b':
					*string_buf_ptr++ = '\b';
					break;
				case 't':
					*string_buf_ptr++ = '\t';
					break;
				case 'n':
					*string_buf_ptr++ = '\n';
					break;
				case 'f':
					*string_buf_ptr++ = '\f';
					break;
				case '\0':
					string_has_null = 1;
					break;
				case '\n':
					nested_lineno++;
				default:
					*string_buf_ptr++ = yytext[1];
				}
				*string_buf_ptr = '\0';
 			  }
			  else if (string_buf_ptr - string_buf == MAX_STR_CONST - 1) string_buf_ptr++; } // too long string

<STRING>\0		{ string_has_null = 1; }

<STRING>\n		|
<STRING>\"		{ BEGIN(INITIAL);
			  int succ = 0;
			  if (yytext[yyleng-1] == '\n') {
				  nested_lineno++;
				  cool_yylval.error_msg = "Unterminated string constant";
			  } else if (string_has_null == 1) {
				  cool_yylval.error_msg = "String contains null character";
			  } else if (string_buf_ptr - string_buf == MAX_STR_CONST) {
				  cool_yylval.error_msg = "String constant too long";
			  } else {
				  cool_yylval.symbol = stringtable.add_string(string_buf);
				  succ = 1;
			  }
			  curr_lineno = nested_lineno;
			  if (succ == 1) return (STR_CONST);
			  else return (ERROR); 
			}

<STRING><<EOF>>		{ BEGIN(INITIAL);
			  cool_yylval.error_msg = "EOF in string constant";
			  return (ERROR); }

 /*
  *  White Space
  */

\n+			{ curr_lineno+=yyleng; }
[ \f\r\t\v]+		;

 /*
  *  Error
  */
.			{ cool_yylval.error_msg = yytext;
			  return (ERROR); }

%%
