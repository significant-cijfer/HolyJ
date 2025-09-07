#define TYPE_NONE	0
#define TYPE_VOID	1
#define TYPE_CLASS	2
#define TYPE_FUNCTION	3
#define TYPE_STRING	4

#define BUILTIN_NONE	0
#define BUILTIN_PRINTLN	1

class Typx {
	U32 main;
	U32 arrays;
};

//NOTE, horrendous last-minute decisions
//      this code was written while my laptop was activly dying and erasing files TvT
class Typd {
	U32 type;

	//NOTE, class stuff
	U8 **names;
	Typd *types;
	U32 len;

	//NOTE, function stuff
	U32 builtin;

	//NOTE, curr-val stuff
	union {
		I32 int;
		U8 *str;
	};
};

U0 TypdFree(Typd *typd) {
	//NOTE, see CtxFree
	U64 i;
	for (i = 0; i < typd->len; i++)
		TypdFree(&typd->types[i]);

	switch (typd->type) {
		case TYPE_CLASS:
			Free(typd->names);
			Free(typd->types);
			break;
		default:
			break;
	}
}

Typd *TypdMember(Typd *typd, U8 *name) {
	U64 i;
	for (i = 0; i < typd->len; i++)
		if (!StrCmp(name, typd->names[i]))
			return &typd->types[i];

	return NULL;
}