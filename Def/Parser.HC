#define NODE_ROOT	0
#define NODE_CLASS	1
#define NODE_FUNCTION	2
#define NODE_FNCALL	3
#define NODE_BLOCK	4
#define NODE_IDENT	5
#define NODE_STRING	6
#define NODE_ADD	7
#define NODE_SUB	8
#define NODE_MUL	9
#define NODE_DIV	10
#define NODE_DOT	11
#define NODE_ASS	12

#define OP_ADD		0

#define OP_ADD_LBP	6
#define OP_ADD_RBP	7

class Node {
	U32 kind;
	U32 main;
	U32 lhs;
	U32 rhs;
};


class ExtraList {
	U32 *extras;
	U32 len;
	U32 cap;
};

class Ast {
	Node *nodes;
	U32 nlen;
	U32 ncap;

	U32 *extra;
	U32 elen;
	U32 ecap;

	Typx *types;
	U32 tlen;
	U32 tcap;
};