//TODO

class Ctx {
	Ctx *parent;
	U8 **names;
	Typd *types;
	U32 len;
	U32 cap;
};

U0 CtxInit(Ctx *ctx, Ctx *parent = NULL) {
	ctx->parent = parent;
	ctx->names = MAlloc(sizeof(U8 *));
	ctx->types = MAlloc(sizeof(Typd));
	ctx->len = 0;
 	ctx->cap = 1;
}

U0 CtxFree(Ctx *ctx) {
	//NOTE, idc abt internal strings, for now
	//      they may be in .data/.rodata
	U64 i;
	for (i = 0; i < ctx->len; i++)
		TypdFree(&ctx->types[i]);

	Free(ctx->names);
	Free(ctx->types);
}

Ctx *CtxChild(Ctx *ctx) {
	Ctx *child = MAlloc(sizeof(Ctx));
	CtxInit(child, ctx);
	return child;
}

Ctx *CtxPut(Ctx *ctx, U8 *name, Typd *typd) {
	if (ctx->cap <= ctx->len) {
		ctx->names = ReAlloc(
			ctx->names,
			1*ctx->cap*sizeof(U8 *),
			2*ctx->cap*sizeof(U8 *));
		ctx->types = ReAlloc(
			ctx->types,
			1*ctx->cap*sizeof(Typd),
			2*ctx->cap*sizeof(Typd));
		ctx->cap *= 2;
	}

	U64 idx = ctx->len++;
	ctx->names[idx] = name;
	MemCpy(&ctx->types[idx], typd, sizeof(Typd));
	return &ctx->types[idx];
}

Typd *CtxGet(Ctx *ctx, U8 *name) {
	U64 i;

	for (i = 0; i <ctx->len; i++) {
		if (!StrCmp(name, ctx->names[i]))
			return &ctx->types[i];
	}

	if (ctx->parent != NULL)
		return CtxGet(ctx->parent, name);

	return NULL;
}

U0 CtxRoot(Ctx *ctx) {
	Typd typd;
	typd.len = 0;
	typd.builtin = BUILTIN_NONE;

	typd.type = TYPE_VOID;
	CtxPut(ctx, "void", &typd);

	typd.type = TYPE_STRING;
	CtxPut(ctx, "String", &typd);

	Typd println;
	println.type = TYPE_FUNCTION;
	println.len = 0;
	println.builtin = BUILTIN_PRINTLN;

	Typd out;
	out.type = TYPE_CLASS;
	out.names = MAlloc(1*sizeof(U8 *));
	out.types = MAlloc(1*sizeof(Typd));
	out.names[0] = "println";
	MemCpy(&out.types[0], &println, sizeof(Typd));
	out.len = 1;

	typd.type = TYPE_CLASS;
	typd.names = MAlloc(1*sizeof(U8 *));
	typd.types = MAlloc(1*sizeof(Typd));
	typd.names[0] = "out";
	MemCpy(&typd.types[0], &out, sizeof(Typd));
	typd.len = 1;
	CtxPut(ctx, "System", &typd);
}

Typd *Interp(Ast *tree, Ctx *ctx, Tokens *tokens, U8 *source, U32 idx=0) {
	U32 i;
	U32 len;
	U8 *name;
	Typd *typd;

	Ctx *child;
	Node *node = &tree->nodes[idx];

	switch (node->kind) {
		case NODE_ROOT:
			len = tree->extra[node->lhs];
			for (i = 1; i <= len; i++)
				Interp(tree, ctx, tokens, source, tree->extra[node->lhs+i]);
			return 0;
		case NODE_CLASS:
			child = CtxChild(ctx);
			Interp(tree, child, tokens, source, node->lhs);

			CtxFree(child);
			return 0;
		case NODE_FUNCTION:
			//TODO, add prms
			child = CtxChild(ctx);
			Interp(tree, child, tokens, source, node->rhs);

			CtxFree(child);
			return 0;
		case NODE_FNCALL:
			Typd **args = MAlloc(len*sizeof(Typd*));
			Typd *arg;

			len = tree->extra[node->rhs];

			for (i = 0; i < len; i++) {
				arg = Interp(tree, ctx, tokens, source, tree->extra[node->rhs+i+1]);
				args[i] = arg;
			}

			typd = Interp(tree, ctx, tokens, source, node->lhs);

			switch (typd->builtin) {
				case BUILTIN_NONE:
					return 0;
				case BUILTIN_PRINTLN:
					//NOTE, unsafe for now
					"[out] %s\n", args[0]->str;
					return 0; //TODO$IV,0$
			}
		case NODE_BLOCK:
			child = CtxChild(ctx);
			len = tree->extra[node->lhs];
			for (i = 1; i <= len; i++)
				Interp(tree, child, tokens, source, tree->extra[node->lhs+i]);

			CtxFree(child);
			return 0; //TODO, maybe
		case NODE_IDENT:
			name = TokenIdent(&tokens->list[node->main], source);
			typd = CtxGet(ctx, name);

			Free(name);
			return typd;
		case NODE_STRING:
			U8 *str = TokenString(&tokens->list[node->main], source);
			typd = MAlloc(sizeof(Typd));
			typd->type = TYPE_STRING;
			typd->len = 0;
			typd->builtin = BUILTIN_NONE;
			typd->str = str;

			return typd;
		case NODE_ADD:
			Typd *lhs = Interp(tree, ctx, tokens, source, node->lhs);
			Typd *rhs = Interp(tree, ctx, tokens, source, node->rhs);
			typd = MAlloc(sizeof(Typd));

			switch (lhs->type) {
				case TYPE_STRING:
					switch (rhs->type) {
						case TYPE_STRING:
							len = StrLen(lhs->str)+StrLen(rhs->str);
							U8 *buf = MAlloc(len+1);
							MemCpy(buf, lhs->str, StrLen(lhs->str));
							MemCpy(&buf[StrLen(lhs->str)], rhs->str, StrLen(rhs->str));
							buf[len] = 0;

							typd->type = TYPE_STRING;
							typd->len = 0;
							typd->builtin = BUILTIN_NONE;
							typd->str = buf;
							break;
						default:
							"[error] Unhandled rhs for add:{%d} + {%d}", lhs->type, rhs->type;
							return 0;
					}
					break;
				default:
					"[error] Unhandled lhs for add:{%d}", lhs->type;
					return 0;
			}

			return typd;
		case NODE_DOT:
			typd = Interp(tree, ctx, tokens, source, node->lhs);

			if (!typd || typd->type != TYPE_CLASS) {
				"[error] Cant access member on non-class\n";
				return 0;
			}

			name = TokenIdent(&tokens->list[node->main+1], source);
			typd = TypdMember(typd, name);

			Free(name);
			return typd;
		case NODE_ASS:
			name = TokenIdent(&tokens->list[node->main-1], source);
			typd = Interp(tree, ctx, tokens, source, node->rhs);
			typd = CtxPut(ctx, name, typd);

			return typd;
		default:
			"[error] Unhandled interp node: {%d}\n", node->kind;
			return 0;
	}
$WW,1$}