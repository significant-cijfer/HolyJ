U0 ExtraListInit(ExtraList *list) {
	list->extras = MAlloc(sizeof(U32));
	list->len = 0;
	list->cap = 1;
}

U0 ExtraListFree(ExtraList *list) {
	Free(list->extras);
}

U0 ExtraListPush(ExtraList *list, U32 ex) {
	if (list->cap <= list->len) {
		list->extras = ReAlloc(
			list->extras,
			1*list->cap*sizeof(U32),
			2*list->cap*sizeof(U32));
		list->cap *= 2;
	}

	U32 idx = list->len++;
	list->extras[idx] = ex;
}

U0 AstInit(Ast *tree) {
	tree->nodes = MAlloc(sizeof(Node));
	tree->nlen = 0;
	tree->ncap = 1;

	tree->extra = MAlloc(sizeof(U32));
	tree->elen = 0;
	tree->ecap = 1;

	//NOTE, node function can never be 0 due to the root node
	//      this emulates the behaviour for types
	tree->types = MAlloc(2*sizeof(Typx));
	tree->tlen = 1;
	tree->tcap = 2;
}

U0 AstFree(Ast *tree) {
	Free(tree->nodes);
	Free(tree->extra);
	Free(tree->types);
}

U32 AstPushNode(Ast *tree, Node *node) {
	if (tree->ncap <= tree->nlen) {
		tree->nodes = ReAlloc(
			tree->nodes,
			1*tree->ncap*sizeof(Node),
			2*tree->ncap*sizeof(Node));
		tree->ncap *= 2;
	}

	U32 idx = tree->nlen++;
	tree->nodes[idx].kind = node->kind;
	tree->nodes[idx].main = node->main;
	tree->nodes[idx].lhs = node->lhs;
	tree->nodes[idx].rhs = node->rhs;
	return idx;
}

U32 AstPushExtra(Ast *tree, U32 ex) {
	if (tree->ecap <= tree->elen) {
		tree->extra = ReAlloc(
			tree->extra,
			1*tree->ecap*sizeof(U32),
			2*tree->ecap*sizeof(U32));
		tree->ecap *= 2;
	}

	U32 idx = tree->elen++;
	tree->extra[idx] = ex;
	return idx;
}

U32 AstPushExtraList(Ast *tree, ExtraList *list) {
	U32 len = list->len + 1;

	if (tree->ecap < tree->elen + len) {
		tree->extra = ReAlloc(
			tree->extra,
			tree->ecap*sizeof(U32),
			(tree->ecap+len)*sizeof(U32));
		tree->ecap += len;
	}

	U32 idx = tree->elen;
	tree->elen += len;

	tree->extra[idx] = list->len;
	MemCpy(&tree->extra[idx+1], list->extras, list->len*sizeof(U32));
	return idx;
}

U32 AstPushType(Ast *tree, Typx *type) {
	if (tree->tcap <= tree->tlen) {
		tree->types = ReAlloc(
			tree->types,
			1*tree->tcap*sizeof(Typx),
			2*tree->tcap*sizeof(Typx));
		tree->tcap *= 2;
	}

	U32 idx = tree->tlen++;
	tree->types[idx].main = type->main;
	tree->types[idx].arrays = type->arrays;
	return idx;
}

U0 AstDebug(Ast *tree, U32 idx = 0, U32 depth = 0) {
	if (depth && !idx) {
		"[error] something sus happenin\n";
		return;
	}

	U32 i;
	U32 len;

	"[debug] {%d}", idx;
	for (i = 0; i < depth; i++) {
		"  ";
	}

	Node *node = &tree->nodes[idx];
	"Node{%d}\n", node->kind;

	switch (node->kind) {
		case NODE_ROOT:
		case NODE_BLOCK:
			len = tree->extra[node->lhs];
			for (i = 1; i <=len; i++)
				AstDebug(tree, tree->extra[node->lhs+i], depth+1);

			break;
		case NODE_IDENT:
		case NODE_STRING:
			break;
		case NODE_CLASS:
			AstDebug(tree, node->lhs, depth+1);
			break;
		case NODE_FUNCTION:
			AstDebug(tree, node->rhs, depth+1);
			break;
		case NODE_FNCALL:
			AstDebug(tree, node->lhs, depth+1);

			len = tree->extra[node->rhs];
			for (i = 1; i <=len; i++)
				AstDebug(tree, tree->extra[node->rhs+i], depth+1);

			break;
		case NODE_ADD:
		case NODE_SUB:
		case NODE_MUL:
		case NODE_DIV:
			AstDebug(tree, node->lhs, depth+1);
			AstDebug(tree, node->rhs, depth+1);
			break;
		case NODE_DOT:
			AstDebug(tree, node->lhs, depth+1);
			break;
		case NODE_ASS:
			AstDebug(tree, node->rhs, depth+1);
			break;
		default:
			"[error] Unhandled debug{%d}\n", node->kind;
			return;
	}
}

Bool TokenExpect(Tokens *tokens, U32 *idx, U32 kind, Bool opt=FALSE) {
	if (tokens->list[*idx].kind != kind) {
		if (!opt) "[error] Unexpected token: {%d} => {%d}\n", kind, tokens->list[*idx].kind;
		return FALSE;
	}

	*idx += 1;
	return TRUE;
}

U32 ParseExpr(Ast *tree, Tokens *tokens, U32 *idx, U8 bp = 0) {
	Node node;
	U32 lhs;

	switch (tokens->list[*idx].kind) {
		case TOKEN_IDENT:
			node.kind = NODE_IDENT;
			node.main = *idx;

			lhs = AstPushNode(tree, &node);
			*idx += 1;
			break;
		case TOKEN_STRING:
			node.kind = NODE_STRING;
			node.main = *idx;

			lhs = AstPushNode(tree, &node);
			*idx += 1;
			break;
		default:
			"[error] Unhandled expr lhs:%d\n", tokens->list[*idx].kind;
			return 0;
	}

	while (TRUE) {
		U32 odx = *idx;
		U32 op;

		switch (tokens->list[*idx].kind) {
			case TOKEN_ADD:
				op = OP_ADD;
				break;
			case TOKEN_LPAR:
				*idx += 1;

				ExtraList *args = MAlloc(sizeof(ExtraList));
				ExtraListInit(args);

				while (TRUE) {
					if (tokens->list[*idx].kind == TOKEN_RPAR) {
						*idx += 1;
						break;
					}
			
					U32 ex = ParseExpr(tree, tokens, idx);
					if (!ex) return 0;
					ExtraListPush(args, ex);

					if (tokens->list[*idx].kind == TOKEN_RPAR) {
						*idx += 1;
						break;
					}

					if (tokens->list[*idx].kind != TOKEN_COMMA) {
						"[error] Unexpected token";
						return 0;
					}

					*idx += 1;
				}

				node.kind = NODE_FNCALL;
				node.main = odx;
				node.lhs = lhs;
				node.rhs = AstPushExtraList(tree, args);
				ExtraListFree(args);

				lhs = AstPushNode(tree, &node);
				break;
			case TOKEN_DOT:
				*idx += 1;
				if (!TokenExpect(tokens, idx, TOKEN_IDENT)) return 0;

				node.kind = NODE_DOT;
				node.main = odx;
				node.lhs = lhs;

				lhs = AstPushNode(tree, &node);
				break;
			default:
				return lhs;
		}

		switch (op) {
			case OP_ADD:
				if (OP_ADD_LBP < bp)
					break;

				*idx += 1;
				U32 rhs = ParseExpr(tree, tokens, idx, OP_ADD_RBP);

				node.kind = NODE_ADD;
				node.main = odx;
				node.lhs = lhs;
				node.rhs = rhs;

				lhs = AstPushNode(tree, &node);
				break;
		}
	}
}

U32 ParseType(Ast *tree, Tokens *tokens, U32 *idx) {
	switch (tokens->list[*idx].kind) {
		case TOKEN_IDENT:
			U32 arrays = 0;
			U32 odx = *idx;
			*idx += 1;

			while (TokenExpect(tokens, idx, TOKEN_LSQR, TRUE)) {
				if (!TokenExpect(tokens, idx, TOKEN_RSQR)) return 0;
				arrays += 1;
			}

			Typx typx;
			typx.main = odx;
			typx.arrays = arrays;

			return AstPushType(tree, &typx);
		default:
			"[error] found non-ident for type";
			return 0;
	}
}

U32 ParseStatement(Ast *tree, Tokens *tokens, U32 *idx) {
	U32 old = *idx;
	U32 type = ParseType(tree, tokens, idx);
	if (!type) { *idx = old; return 0; }

	if (!TokenExpect(tokens, idx, TOKEN_IDENT, TRUE)) { *idx = old; return 0; }
	if (!TokenExpect(tokens, idx, TOKEN_ASS, TRUE)) { *idx = old; return 0; }
	
	U32 adx = *idx - 1;
	U32 body = ParseExpr(tree, tokens, idx);
	if (!body) { *idx = old; return 0; }

	Node node;
	node.kind = NODE_ASS;
	node.main = adx;
	node.lhs = type;
	node.rhs = body;

	return AstPushNode(tree, &node);
}

U32 ParseFunction(Ast *tree, Tokens *tokens, U32 *idx) {
	ExtraList *extras = MAlloc(sizeof(ExtraList));
	ExtraListInit(extras);

	U32 type = ParseType(tree, tokens, idx);

	U32 odx = *idx;
	if (!TokenExpect(tokens, idx, TOKEN_IDENT)) return 0;

	if (!TokenExpect(tokens, idx, TOKEN_LPAR)) return 0;
	while (TRUE) {
		if (tokens->list[*idx].kind == TOKEN_RPAR) {
			*idx += 1;
			break;
		}

		U32 prm = ParseType(tree, tokens, idx);
		if (!prm) return 0;
		//TODO, add prm somewhere

		if (!TokenExpect(tokens, idx, TOKEN_IDENT)) return 0;


		if (tokens->list[*idx].kind == TOKEN_RPAR) {
			*idx += 1;
			break;
		}

		if (tokens->list[*idx].kind != TOKEN_COMMA) {
			"[error] Unexpected token";
			return 0;
		}

		*idx += 1;
	}

	U32 bdx = *idx;
	if (!TokenExpect(tokens, idx, TOKEN_LBRAC)) return 0;
	while (TRUE) {
		if (tokens->list[*idx].kind == TOKEN_RBRAC) {
			*idx += 1;
			break;
		}

		U32 body;
		if (body = ParseStatement(tree, tokens, idx)) {
		} else if (body = ParseExpr(tree, tokens, idx)) {
		} else {
			return 0;
		}

		if (!TokenExpect(tokens, idx, TOKEN_SEMIC)) return 0;
		ExtraListPush(extras, body);
	}

	Node block;
	block.kind = NODE_BLOCK;
	block.main = bdx;
	block.lhs = AstPushExtraList(tree, extras);
	ExtraListFree(extras);

	Node node;
	node.kind = NODE_FUNCTION;
	node.main = odx;
	node.lhs = type;
	node.rhs = AstPushNode(tree, &block);

	return AstPushNode(tree, &node);
}

Ast *Parse(Tokens *tokens, U8 *source) {
	Ast *tree = MAlloc(sizeof(Ast));
	AstInit(tree);

	ExtraList *extras = MAlloc(sizeof(ExtraList));
	ExtraListInit(extras);

	Node root;
	root.kind = NODE_ROOT;
	root.main = tokens->len-1;
	AstPushNode(tree, &root);

	Node node;

	U32 idx = 0;
	U32 ex;

	while (TRUE) {
		switch (tokens->list[idx].kind) {
			case TOKEN_EOF:
				ex = AstPushExtraList(tree, extras);
				tree->nodes[0].lhs = ex;

				ExtraListFree(extras);
				return tree;

			case TOKEN_IDENT:
				U32 kw = GetKeyword(tokens, source, idx);

				switch (kw) {
					case KW_CLASS:
						U32 odx = idx++;
						if (!TokenExpect(tokens, &idx, TOKEN_IDENT)) return NULL;
						if (!TokenExpect(tokens, &idx, TOKEN_LBRAC)) return NULL;
						U32 fun = ParseFunction(tree, tokens, &idx);
						if (!fun) return NULL;
						if (!TokenExpect(tokens, &idx, TOKEN_RBRAC)) return NULL;

						node.kind = NODE_CLASS;
						node.main = odx;
						node.lhs = fun;

						ex = AstPushNode(tree, &node);
						ExtraListPush(extras, ex);
						break;
	
					default:
						"[error] Unhandled keyword:{%d}\n", kw;
						return NULL;
				}

				break;

			default:
				"[error] Unhandled token\n";
				return NULL;
		}
	}
}