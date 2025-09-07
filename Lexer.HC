U8 *TokenIdent(Token *token, U8 *source) {
	if (token->kind != TOKEN_IDENT)
		return NULL;

	U32 idx = token->main;

	while (TRUE) {
		switch (source[idx]) {
			case 'a'...'z':
			case 'A'...'Z':
				idx += 1;
				break;
			default:
				U32 len = idx-token->main;
				U8 *buf = MAlloc(len+1);
				MemCpy(buf, &source[token->main], len);
				buf[len] = 0;
				return buf;
		}
	}
}

U8 *TokenString(Token *token, U8 *source) {
	if (token->kind != TOKEN_STRING)
		return NULL;

	U32 idx = token->main;

	while (TRUE) {
		switch (source[idx]) {
			case '"':
				U32 len = idx-token->main;
				U8 *buf = MAlloc(len+1);
				MemCpy(buf, &source[token->main], len);
				buf[len] = 0;
				return buf;
			default:
				idx += 1;
				break;
		}
	}
}

U0 TokensInit(Tokens *tokens) {
	tokens->list = MAlloc(sizeof(Token));
	tokens->len = 0;
	tokens->cap = 1;
	//"[debug] init: tokens->cap: %d\n", tokens->cap;
}

U0 TokensFree(Tokens *tokens) {
	Free(tokens->list);
}

U0 TokensPush(Tokens *tokens, Token token) {
	if (tokens->cap <= tokens->len) {
		//"[debug] tokens->cap:%d\n", tokens->cap;
		tokens->list = ReAlloc(
			tokens->list,
			1*tokens->cap*sizeof(Token),
			2*tokens->cap*sizeof(Token));
		tokens->cap *= 2;
	}

	U64 idx = tokens->len++;
	tokens->list[idx].kind = token.kind;
	tokens->list[idx].main = token.main;
}

U0 TokensDebug(Tokens *tokens) {
	U64 i;
	for (i = 0; i <tokens->len; i++) {
		Token *token = &tokens->list[i];
		"[debug] Token{%d}: ...\n", token->kind;
	}
}

Tokens *Lex(U8 *source) {
	Tokens *tokens = MAlloc(sizeof(Tokens));
	TokensInit(tokens);

	Token token;
	U32 state = STATE_INIT;
	U32 idx = 0;

	while (TRUE) {
		//"handling char: '%c' => %d\n", source[idx], source[idx];

		switch (state) {
			case STATE_INIT:
	 			switch (source[idx]) {
					case '\n':
					case '\r':
					case '\t':
					case ' ':
					case 5:
						idx += 1;
						break;
					case 0:
						token.kind = TOKEN_EOF;
						token.main = idx;

						TokensPush(tokens, token);
						return tokens;
					case '(':
						token.kind = TOKEN_LPAR;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case ')':
						token.kind = TOKEN_RPAR;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case '{':
						token.kind = TOKEN_LBRAC;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case '}':
						token.kind = TOKEN_RBRAC;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case '[':
						token.kind = TOKEN_LSQR;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case ']':
						token.kind = TOKEN_RSQR;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case '.':
						token.kind = TOKEN_DOT;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case ',':
						token.kind = TOKEN_COMMA;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case ';':
						token.kind = TOKEN_SEMIC;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case '+':
						token.kind = TOKEN_ADD;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case '-':
						token.kind = TOKEN_SUB;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case '*':
						token.kind = TOKEN_MUL;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case '/':
						token.kind = TOKEN_DIV;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case '=':
						token.kind = TOKEN_ASS;
						token.main = idx;

						TokensPush(tokens, token);
						idx += 1;
						break;
					case 'a'...'z':
					case 'A'...'Z':
						token.kind = TOKEN_IDENT;
						token.main = idx;

						TokensPush(tokens, token);
						state = STATE_IDENT;
						idx += 1;
						break;
					case '"':
						token.kind = TOKEN_STRING;
						token.main = idx+1;

						TokensPush(tokens, token);
						state = STATE_STRING;
						idx += 1;
						break;
					default:
						"[error] Unrecognized char: '%c'\n", source[idx];
						return NULL;
				}
				break;
			case STATE_IDENT:
				switch (source[idx]) {
					case 'a'...'z':
					case 'A'...'Z':
						idx += 1;
						break;
					default:
						//TODO, add identifier checks
						state = STATE_INIT;
						break;
				}
				break;
			case STATE_STRING:
				switch (source[idx]) {
					case '"':
						state = STATE_INIT;
						idx += 1;
						break;
					default:
						idx += 1;
						break;
				}
				break;
		}
	}
}