namespace Vapi.Builtins {
	[CCode(cname = "__builtin_bswap32")]
	public uint32 bswap32(uint32 x);
	
	[CCode(cname = "__builtin_bswap16")]
	public uint16 bswap16(uint16 x);
}