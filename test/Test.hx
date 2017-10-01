package test;

class Test extends hxd.App {

	static function main(){
		new Test();
	}

	override function init(){
		var face = new freetype.Library().loadFace(sys.io.File.getBytes("NotoSans-Regular.ttf"));
		trace(face.familyName+" "+face.styleName);
		face.setSize( 32 );
		
		var s = hxd.Charset.DEFAULT_CHARS;
		var m = new freetype.Library.GlyphMetrics();
		var bmp = new freetype.Library.Bitmap();
		for( i in 0...s.length ){
			var c = s.charCodeAt(i);
			var g = face.charIndex(c);
			face.loadGlyph(g,Default,m);
			face.renderGlyph(Normal, bmp);
			trace( 'char=${s.charAt(i)} c=$c g=$g width=${m.width} height=${m.height} horiBearingX=${m.horiBearingX} bmp.width=${bmp.width} bmp.rows=${bmp.rows}' );
		}
	}


}