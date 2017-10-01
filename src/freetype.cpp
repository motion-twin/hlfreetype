#define HL_NAME(n) freetype_##n
#include <hl.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_BITMAP_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include FT_GLYPH_H
#include FT_OUTLINE_H

template <typename T> class ft_struct {
	hl_type *t;
public:
	T value;
};

typedef struct _hl_ftlib hl_ftlib;
struct _hl_ftlib {
	void(*finalize)(hl_ftlib *);
	FT_Library lib;
};

static void ftlib_finalize(hl_ftlib *l) {
	if( l->lib ) FT_Done_FreeType(l->lib);
}

typedef struct _hl_ftface hl_ftface;
struct _hl_ftface {
	FT_Face face;
};

typedef struct _hl_ftbmp hl_ftbmp;
struct _hl_ftbmp {
	hl_type *t;
	unsigned int rows;
	unsigned int width;
	int pitch;
	char *buffer;
	unsigned short num_grays;
	char pixel_mode;
};


#define FTERR(cmd) { FT_Error __ret = cmd; if( __ret ) hl_error_msg(USTR("Freetype error %#02x line %d"), __ret, __LINE__); }

HL_PRIM hl_ftlib *HL_NAME(init) () {
	hl_ftlib *l = (hl_ftlib*)hl_gc_alloc_finalizer(sizeof(hl_ftlib));
	l->finalize = ftlib_finalize;
	l->lib = NULL;
	FTERR(FT_Init_FreeType(&l->lib));
	return l;
}

HL_PRIM hl_ftface *HL_NAME(new_memory_face)(hl_ftlib *l, vbyte *data, int size, int index) {
	hl_ftface *f = (hl_ftface*)hl_gc_alloc_noptr(sizeof(hl_ftface));
	FTERR(FT_New_Memory_Face(l->lib, data, size, index, &f->face));
	FTERR(FT_Select_Charmap(f->face, FT_ENCODING_UNICODE));
	return f;
}

HL_PRIM int HL_NAME(get_flags)(hl_ftface *f) {
	return f->face->face_flags;
}

HL_PRIM int HL_NAME(get_height)(hl_ftface *f) {
	return f->face->height;
}

HL_PRIM int HL_NAME(get_units_per_em)(hl_ftface *f) {
	return f->face->units_per_EM;
}

HL_PRIM char *HL_NAME(get_family_name)(hl_ftface *f) {
	return f->face->family_name;
}

HL_PRIM char *HL_NAME(get_style_name)(hl_ftface *f) {
	return f->face->style_name;
}

HL_PRIM int HL_NAME(get_char_index)( hl_ftface *f, int charcode ) {
	return FT_Get_Char_Index(f->face, charcode);
}

HL_PRIM void HL_NAME(set_char_size)(hl_ftface *f, int w, int h, int hres, int vres) {
	FTERR(FT_Set_Char_Size(f->face, w, h, hres, vres));
}

HL_PRIM void HL_NAME(get_kerning)(hl_ftface *f, int lglyph, int rglyph, int mode, ft_struct<FT_Vector> *v) {
	FTERR(FT_Get_Kerning(f->face, lglyph, rglyph, mode, &v->value));
}

HL_PRIM void HL_NAME(load_glyph)(hl_ftface *f, int index, int flags, ft_struct<FT_Glyph_Metrics> *metrics ) {
	FTERR(FT_Load_Glyph(f->face, index, flags));
	if( metrics )
		memcpy(&metrics->value, &f->face->glyph->metrics, sizeof(FT_Glyph_Metrics));
}

HL_PRIM void HL_NAME(render_glyph)(hl_ftface *f, int mode, hl_ftbmp *bmp) {
	FT_Bitmap *b;
	FTERR(FT_Render_Glyph(f->face->glyph, (FT_Render_Mode)mode));
	b = &f->face->glyph->bitmap;
	bmp->rows = b->rows;
	bmp->width = b->width;
	bmp->pitch = b->pitch;
	bmp->num_grays = b->num_grays;
	bmp->pixel_mode = b->pixel_mode;
	bmp->buffer = (char*)hl_gc_alloc_noptr(b->rows*b->pitch);
	memcpy(bmp->buffer, b->buffer, b->rows*b->pitch);
}

#define _LIBRARY _ABSTRACT(hl_ftlib)
#define _FACE _ABSTRACT(hl_ftface)

DEFINE_PRIM(_LIBRARY, init, _NO_ARG);
DEFINE_PRIM(_FACE, new_memory_face, _LIBRARY _BYTES _I32 _I32);
DEFINE_PRIM(_I32, get_flags, _FACE);
DEFINE_PRIM(_I32, get_height, _FACE);
DEFINE_PRIM(_I32, get_units_per_em, _FACE);
DEFINE_PRIM(_BYTES, get_family_name, _FACE);
DEFINE_PRIM(_BYTES, get_style_name, _FACE);
DEFINE_PRIM(_I32, get_char_index, _FACE _I32);
DEFINE_PRIM(_VOID, set_char_size, _FACE _I32 _I32 _I32 _I32);
DEFINE_PRIM(_VOID, get_kerning, _FACE _I32 _I32 _I32 _DYN);
DEFINE_PRIM(_VOID, load_glyph, _FACE _I32 _I32 _DYN);
DEFINE_PRIM(_VOID, render_glyph, _FACE _I32 _DYN);

// TODO manual dispose font