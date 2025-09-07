#define KW_NONE		0
#define KW_CLASS	1
#define KW_PUBLIC	2
#define KW_STATIC	3

#define KW_CLASS_STR	"class"
#define KW_CLASS_LEN	5

#define KW_PUBLIC_STR	"public"
#define KW_PUBLIC_LEN	6

#define KW_STATIC_STR	"static"
#define KW_STATIC_LEN	6

U32 GetKeyword(Tokens *tokens, U8 *source, U32 idx) {
	Token *token = &tokens->list[idx];

	if (!StrNCmp(&source[token->main], KW_CLASS_STR, KW_CLASS_LEN)) {
		return KW_CLASS;
	}

	if (!StrNCmp(&source[token->main], KW_PUBLIC_STR, KW_PUBLIC_LEN)) {
		return KW_PUBLIC;
	}

	if (!StrNCmp(&source[token->main], KW_STATIC_STR, KW_STATIC_LEN)) {
		return KW_STATIC;
	}

	return KW_NONE;
}