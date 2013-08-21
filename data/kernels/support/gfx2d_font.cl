
oclraster_out simple_output {
	float4 tex_coord;
} output_attributes;

#if defined(OCLRASTER_TRANSFORM_PROGRAM)
//////////////////////////////////////////////////////////////////
// transform program
oclraster_uniforms transform_uniforms {
	mat4 modelview_matrix;
	uint2 glyph_count; // (glyphs per row, glyphs per column)
	float2 glyph_size; // "font size"
	float2 page_size; // "texture size"
} tp_uniforms;

oclraster_in simple_input {
	float4 vertex;
} input_attributes;

oclraster_buffers {
	const unsigned int* text_data;
};

float4 gfx2d_transform() {
	uint index = text_data[instance_index * 2];
	const uint pos = text_data[(instance_index * 2) + 1];
	const uint2 upos = (uint2)(pos & 0xFFFFu, (pos >> 16u) & 0xFFFFu);
	
	float2 vertex = input_attributes->vertex.xy * tp_uniforms->glyph_size;
	// kinda sick, but it does it's job (there is no other way to emulate a packed short int)
	vertex.x += (float)(upos.x >= 0x8000u ? -(int)((~upos.x & 0xFFFFu) + 1u) : (int)(upos.x));
	vertex.y += (float)(upos.y >= 0x8000u ? -(int)((~upos.y & 0xFFFFu) + 1u) : (int)(upos.y));
	
	uint glyphs_per_page = tp_uniforms->glyph_count.x * tp_uniforms->glyph_count.y;
	uint page = index / glyphs_per_page;
	index -= page * glyphs_per_page;
	output_attributes->tex_coord.z = page; // TODO: "flat" interpolation
	output_attributes->tex_coord.x = index % tp_uniforms->glyph_count.x;
	output_attributes->tex_coord.y = index / tp_uniforms->glyph_count.x;
	output_attributes->tex_coord.xy *= tp_uniforms->glyph_size;
	output_attributes->tex_coord.xy += input_attributes->vertex.xy * tp_uniforms->glyph_size;
	output_attributes->tex_coord.xy -= input_attributes->vertex.xy / tp_uniforms->page_size; // - 1 texel
	output_attributes->tex_coord.xy /= tp_uniforms->page_size;
	output_attributes->tex_coord.w = 0.0f;
	
	return mat4_mul_vec4(tp_uniforms->modelview_matrix,
						 (float4)(vertex, 0.0f, 1.0f));
}

#elif defined(OCLRASTER_RASTERIZATION_PROGRAM)
//////////////////////////////////////////////////////////////////
// rasterization program

oclraster_uniforms rasterize_uniforms {
	float4 font_color;
} rp_uniforms;

oclraster_images {
	read_only image2d<UINT_8, RGB> font_texture;
};

oclraster_framebuffer {
	image2d color;
	depth_image depth;
};

bool gfx2d_rasterization() {
	const oclr_sampler_t point_sampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_REPEAT | CLK_FILTER_NEAREST;
	const float3 color = image_read(font_texture, point_sampler, output_attributes->tex_coord.xy).xyz * rp_uniforms->font_color.w;
	const float3 color_sign = sign(color); // sign = 0 if color = 0, otherwise 1
	const float max_alpha = (color_sign.x * color_sign.y * color_sign.z) * rp_uniforms->font_color.w; // 0 or font color alpha
	if(max_alpha > 0.0f) {
		framebuffer->color.xyz = (framebuffer->color.xyz * (1.0f - color)) + (color * rp_uniforms->font_color.xyz);
		framebuffer->color.w = max_alpha + (framebuffer->color.w * (1.0f - max_alpha));
	}
	return true;
}

#endif
