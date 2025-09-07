//NOTE, naive impl
U8 *ReAlloc(U8 *old_ptr, U64 old_len, U64 new_len) {
	//"old_len: %d => new_len: %d\n", old_len, new_len;
	U8 *new_ptr = MAlloc(new_len);
	MemCpy(new_ptr, old_ptr, old_len);
	Free(old_ptr);
	return new_ptr;
}