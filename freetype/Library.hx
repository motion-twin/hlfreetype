package freetype;

typedef LibraryPtr = hl.Abstract<"hl_ftlib">;
typedef FacePtr = hl.Abstract<"hl_ftface">;

@:keep
class Vector {
	public var x : Int;
	public var y : Int;
	public function new(){}
}

@:keep
class GlyphMetrics {
	public var width : Int;
	public var height : Int;

	public var horiBearingX : Int;
	public var horiBearingY : Int;
	public var horiAdvance : Int;

	public var vertBearingX : Int;
	public var vertBearingY : Int;
	public var vertAdvance : Int;
	public function new(){}
}

@:keep
class FaceMetrics {
	public var x_ppem : hl.UI16;
	public var y_ppem : hl.UI16;
	public var scaleX : Int;
	public var scaleY : Int;
	public var ascender : Int;
	public var descender : Int;
	public var height : Int;
	public var maxAdvance : Int;
	public function new(){}
}

@:keep
class Bitmap {
	public var rows : UInt;
	public var width : UInt;
	public var pitch : Int;
	public var buffer : hl.Bytes;
	public var num_grays : hl.UI16;
	var pixel_mode : hl.UI8;
	public function new(){}

	public var pixelMode(get,never) : PixelMode;
	inline function get_pixelMode() : PixelMode{
		return @:privateAccess new PixelMode(pixel_mode);
	}

	public var height(get,never) : UInt;
	inline function get_height() return rows;

	#if heaps
	public function writePixels( dest : hxd.Pixels, tx : Int = 0, ty : Int = 0 ){
		switch( [pixelMode, dest.format] ){
			case [Gray, BGRA], [Gray, RGBA], [Gray, ARGB] if( num_grays == 256 ):
				for( y in 0...rows )
				for( x in 0...width ){
					dest.setPixel(tx+x, ty+y, buffer.getUI8(y*pitch+x)<<24 | 0xFFFFFF );
				}
			// case [Gray, ALPHA8] if( num_grays == 256 ):
			// 	for( y in 0...rows )
			// 		@:privateAccess dest.bytes.b.blit((ty+y)*dest.width + tx, buffer, y*pitch, width);
			default: throw "Not implemented "+pixelMode+" to "+dest.format;
		}
	}
	#end
}

@:enum abstract PixelMode(Int) {
	function new(v:Int){
		this = v;
	}

	var None = 0;
	var Mono = 1;
	var Gray = 2;
	var Gray2 = 3;
	var Gray4 = 4;
	var LCD = 5;
	var LCDV = 6;
	var BGRA = 7;
}

@:enum abstract FaceFlags(Int) to Int {
	var Scalable        = 0x1;
	var FixedSizes      = 0x2;
	var FixedWidth      = 0x4;
	var Sfnt            = 0x8;
	var Horizontal      = 0x10;
	var Vertical        = 0x20;
	var Kerning         = 0x40;
	var FastGlyphs      = 0x80;
	var MultipleMasters = 0x100;
	var GlyphNames      = 0x200;
	var ExternalStream  = 0x400;
	var Hinter          = 0x800;
	var CIDKeyed        = 0x1000;
	var Tricky          = 0x2000;
	var Color           = 0x4000;
	@:op(a | b) static function or(a:FaceFlags, b:FaceFlags) : FaceFlags;

	function new( i : Int ){
		this = i;
	}

	public function has( f : FaceFlags ) : Bool {
		return this & f != 0;
	}
}

@:enum abstract RenderMode(Int) to Int {
	var Normal = 0;
	var Light  = 1;
	var Mono   = 2;
	var LCD    = 3;
	var LCDV   = 4;
}

@:enum abstract LoadFlags(Int) {
	var Default                  = 0x0;
	var NoScale                  = 1 << 0;
	var NoHinting                = 1 << 1;
	var Render                   = 1 << 2;
	var NoBitmap                 = 1 << 3;
	var VerticalLayout           = 1 << 4;
	var ForceAutohint            = 1 << 5;
	var CropBitmap               = 1 << 6;
	var Pedantic                 = 1 << 7;
	var IgnoreGlobalAdvanceWidth = 1 << 9;
	var NoRecurse                = 1 << 10;
	var IgnoreTransform          = 1 << 11;
	var Monochrome               = 1 << 12;
	var LinearDesign             = 1 << 13;
	var NoAutohint               = 1 << 15;

	var TargetNormal             = RenderMode.Normal << 16;
	var TargetLight              = RenderMode.Light  << 16;
	var TargetMono               = RenderMode.Mono   << 16;
	var TargetLCD                = RenderMode.LCD    << 16;
	var TargetLCDV               = RenderMode.LCDV   << 16;

	var Color                    = 1 << 20;
	var ComputeMetrics           = 1 << 21;
	var MetricsOnly              = 1 << 22;
	@:op(a | b) static function or(a:LoadFlags, b:LoadFlags) : LoadFlags;
}

@:enum abstract KerningMode(Int) {
	var Default = 0;
	var Unfitted = 1;
	var Unscaled = 2;    
}

abstract GlyphIndex(Int) to Int {
	function new( v : Int ){
		this = v;
	}
}

@:hlNative("freetype")
class Library {

	var lib : LibraryPtr;

	public function new(){
		lib = init();
	}

	public function loadFace( data : haxe.io.Bytes, index = 0 ) : Face {
		return @:privateAccess new Face( this, newMemoryFace(lib, @:privateAccess data.b, data.length, index ) );
	}

	//

	static function init() : LibraryPtr {
		return null;
	}

	static function newMemoryFace( lib : LibraryPtr, bytes : hl.Bytes, size : Int, index : Int ) : FacePtr {
		return null;
	}

}

class Face {

	public var library(default,null) : Library;
	var face : FacePtr;

	function new( lib : Library, face : FacePtr ){
		this.library = lib;
		this.face = face;
	}

	public var flags(get,never) : FaceFlags;
	inline function get_flags() return getFlags(face);

	public var height(get,never) : Int;
	inline function get_height() return getHeight(face);

	public var unitsPerEM(get,never) : Int;
	inline function get_unitsPerEM() return getUnitsPerEM(face);	

	public var familyName(get,never) : String;
	inline function get_familyName(){
		var n = getFamilyName(face);
		return n == null ? null : @:privateAccess String.fromUTF8(n);
	};

	public var styleName(get,never) : String;
	inline function get_styleName(){
		var n = getStyleName(face);
		return n == null ? null : @:privateAccess String.fromUTF8(n);
	};

	public function getMetrics(){
		var m = new FaceMetrics();
		ftGetFaceMetrics(face, m);
		return m;
	}

	public inline function charIndex( char : Int ) : GlyphIndex {
		return getCharIndex(face, char);
	}

	public inline function setSize( size : Int, dpi = 72 ){
		ftSetCharSize(face, 0, size*64, dpi, dpi);
	}

	public inline function getKerning( left : GlyphIndex, right : GlyphIndex, mode : KerningMode, ?vect : Vector ) : Vector {
		if( vect == null ) vect = new Vector();
		ftGetKerning(face, left, right, mode, vect );
		return vect;
	}

	public inline function loadGlyph( index : GlyphIndex, flags : LoadFlags = Default, ?metrics : GlyphMetrics ){
		ftLoadGlyph(face, index, flags, metrics);
	}

	public inline function renderGlyph( mode : RenderMode, ?bmp : Bitmap ) : Bitmap {
		if( bmp == null ) bmp = new Bitmap();
		ftRenderGlyph(face, mode, bmp);
		return bmp;
	}

	//

	@:hlNative("freetype", "get_flags")
	static function getFlags( face : FacePtr ) : FaceFlags {
		return @:privateAccess new FaceFlags(0);
	}

	@:hlNative("freetype", "get_height")
	static function getHeight( face : FacePtr ) : Int {
		return 0;
	}

	@:hlNative("freetype", "get_units_per_em")
	static function getUnitsPerEM( face : FacePtr ) : Int {
		return 0;
	}

	@:hlNative("freetype", "get_face_metrics")
	static function ftGetFaceMetrics( face : FacePtr, metrics : Dynamic ) : Void {
	}

	@:hlNative("freetype", "get_family_name")
	static function getFamilyName( face : FacePtr ) : hl.Bytes {
		return null;
	}

	@:hlNative("freetype", "get_style_name")
	static function getStyleName( face : FacePtr ) : hl.Bytes {
		return null;
	}

	@:hlNative("freetype", "get_char_index")
	static function getCharIndex( face : FacePtr, char : Int ) : GlyphIndex {
		return @:privateAccess new GlyphIndex(-1);
	}

	@:hlNative("freetype", "set_char_size")
	static function ftSetCharSize( face : FacePtr, w : Int, h : Int, hres : Int, vres : Int ) : Void {
	}

	@:hlNative("freetype", "get_kerning")
	static function ftGetKerning( face : FacePtr, left : GlyphIndex, right : GlyphIndex, mode : KerningMode, vect : Dynamic ) : Void {
	}

	@:hlNative("freetype", "load_glyph")
	static function ftLoadGlyph( face : FacePtr, index : GlyphIndex, flags : LoadFlags, metrics : Dynamic ) : Void {
	}

	@:hlNative("freetype", "render_glyph")
	static function ftRenderGlyph( face : FacePtr, mode : RenderMode, bmp : Dynamic ) : Void {
	}


}