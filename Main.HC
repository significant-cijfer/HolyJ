#include "Util"
#include "Type"

#include "Def/Lexer"
#include "Def/Parser"

#include "Keyword"
#include "Lexer"
#include "Parser"
#include "Interpreter"

#define ERR_TOKEN 1
#define ERR_PARSE 2
#define ERR_INTRP 3

U8 Main() {
	"[info]  Reading Source File\n";
	U8* source = FileRead("main.java");
	if (source == NULL) {
		return 255;
	}

	"[info]  Starting Lexer\n";
	Tokens *tokens = Lex(source);
	if (tokens == NULL) {
		return ERR_TOKEN;
	}

	//"[info]  Listing tokens\n";
	//TokensDebug(tokens);

	"[info]  Starting Parser\n";
	Ast *tree = Parse(tokens, source);
	if (tree == NULL) {
		return ERR_PARSE;
	}

//	"[info]  Listing nodes\n";
//	AstDebug(tree);

	"[info] Interpreting nodes\n";
	Ctx *ctx = MAlloc(sizeof(Ctx));
	CtxInit(ctx);
	CtxRoot(ctx);
 
	Interp(tree, ctx, tokens, source);
//	U32 intp = Interp(tree, ctx, tokens, source);
//	if (!intp) {
//		return ERR_INTRP;
//	}

	Free(source);
	TokensFree(tokens);
	AstFree(tree);
	CtxFree(ctx);
	return 0;
}

Main;