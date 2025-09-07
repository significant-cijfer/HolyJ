#define TOKEN_EOF	0
#define TOKEN_IDENT	1
#define TOKEN_STRING	2
#define TOKEN_LBRAC	3
#define TOKEN_RBRAC	4
#define TOKEN_LPAR	5
#define TOKEN_RPAR	6
#define TOKEN_LSQR	7
#define TOKEN_RSQR	8
#define TOKEN_DOT	9
#define TOKEN_COMMA	10
#define TOKEN_SEMIC	11
#define TOKEN_ADD	12
#define TOKEN_SUB	13
#define TOKEN_MUL	14
#define TOKEN_DIV	15
#define TOKEN_ASS	16

#define STATE_INIT	0
#define STATE_IDENT	1
#define STATE_STRING	2

class Token {
	U32 kind;
	U32 main;
};

class Tokens {
	Token *list;
	U64 len;
	U64 cap;
};