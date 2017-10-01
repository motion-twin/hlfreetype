package test;
import freetype.Library;

class Test extends hxd.App {

	static function main(){
		hxd.Res.initLocal();
		new Test();
	}

	override function init(){
		var face = new freetype.Library().loadFace(hxd.Res.NotoSans_Regular.entry.getBytes());
		trace(face.familyName+" "+face.styleName);
		face.setSize( 12 );
		
		var s = hxd.Charset.DEFAULT_CHARS;
		var map = new Map<Int, {glyph: GlyphIndex, metrics: GlyphMetrics, bmp: Bitmap}>();
		for( i in 0...s.length ){
			var c = s.charCodeAt(i);
			var g = face.charIndex(c);
			var m = new GlyphMetrics();
			face.loadGlyph(g,Default|ForceAutohint,m);
			var bmp = face.renderGlyph(Normal);
			map.set(c, {glyph: g, metrics: m, bmp: bmp});
		}

		var pix = hxd.Pixels.alloc(256, 256, h3d.mat.Texture.nativeFormat);


		var x = 2;

		var obj = map.get("A".code);
		trace( obj.bmp.width +" * "+obj.bmp.rows+" ["+obj.bmp.pitch+"]" );
		obj.bmp.writePixels(pix, x, 2);
		x += Std.int( obj.metrics.width/64 + 2 );

		var obj = map.get("B".code);
		obj.bmp.writePixels(pix, x, 2);


		var bmp = new h2d.Bitmap(h2d.Tile.fromPixels(pix), s2d);
		bmp.setScale( 1 );


	}


}