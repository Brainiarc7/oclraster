
#define IMG_READ_FUNC_FILTER_CONCAT(return_type, filter) image_read_##return_type##_##filter
#define IMG_READ_FUNC_FILTER_EVAL(return_type, filter) IMG_READ_FUNC_FILTER_CONCAT(return_type, filter)
#define IMG_READ_FUNC_FILTER_NAME(filter) IMG_READ_FUNC_FILTER_EVAL(RETURN_TYPE, filter)
#define IMG_READ_FUNC_CONCAT(return_name) image_read##return_name
#define IMG_READ_FUNC_EVAL(return_name) IMG_READ_FUNC_CONCAT(return_name)
#define IMG_READ_FUNC_NAME() IMG_READ_FUNC_EVAL(FUNC_RETURN_NAME)
#define IMG_WRITE_FUNC_CONCAT(return_name) image_write##return_name
#define IMG_WRITE_FUNC_EVAL(return_name) IMG_WRITE_FUNC_CONCAT(return_name)
#define IMG_WRITE_FUNC_NAME() IMG_WRITE_FUNC_EVAL(FUNC_RETURN_NAME)

/////////////////
// read functions
RETURN_TYPE_VEC4 FUNC_OVERLOAD OCLRASTER_FUNC IMG_READ_FUNC_FILTER_NAME(nearest)(global const IMG_TYPE* img, const uint offset) {
	global const IMG_TYPE* img_data_ptr = (global const IMG_TYPE*)((global const uchar*)img + OCLRASTER_IMAGE_HEADER_SIZE);
	const IMG_TYPE texel = img_data_ptr[offset];
	// double "(" is intended to make things easier with more complex normalization
	return (RETURN_TYPE_VEC4)( ((IMG_CONVERT_FUNC(texel)IMG_NORMALIZATION VEC4_FILL);
}

RETURN_TYPE_VEC4 FUNC_OVERLOAD OCLRASTER_FUNC IMG_READ_FUNC_FILTER_NAME(nearest)(global const IMG_TYPE* img, const float2 coord) {
	const uint2 img_size = oclr_get_image_size((image_header_ptr)img);
	const float2 fimg_size = convert_float2(img_size) - 1.0f;
	
	// normalize input texture coordinate to [0, 1]
	const float2 norm_coord = fmod(coord + fabs(floor(coord)), (float2)(1.0f, 1.0f));
	const uint2 ui_tc = clamp(convert_uint2(norm_coord * fimg_size), (uint2)(0u, 0u), img_size - 1u);
	return IMG_READ_FUNC_FILTER_NAME(nearest)(img, ui_tc.y * img_size.x + ui_tc.x);
}

RETURN_TYPE_VEC4 FUNC_OVERLOAD OCLRASTER_FUNC IMG_READ_FUNC_FILTER_NAME(nearest)(global const IMG_TYPE* img, const uint2 coord) {
	const uint2 img_size = oclr_get_image_size((image_header_ptr)img);
	return IMG_READ_FUNC_FILTER_NAME(nearest)(img, coord.y * img_size.x + coord.x);
}

RETURN_TYPE_VEC4 FUNC_OVERLOAD OCLRASTER_FUNC IMG_READ_FUNC_FILTER_NAME(linear)(global const IMG_TYPE* img, const float2 coord) {
	const uint2 img_size = oclr_get_image_size((image_header_ptr)img);
	global const IMG_TYPE* img_data_ptr = (global const IMG_TYPE*)((global const uchar*)img + OCLRASTER_IMAGE_HEADER_SIZE);
	const float2 fimg_size = convert_float2(img_size) - 1.0f;
	
	// normalize input texture coordinate to [0, 1]
	const float2 norm_coord = fmod(coord + fabs(floor(coord)), (float2)(1.0f, 1.0f));
	
	// compute texel coordinates for the 4 samples
	const float2 scaled_coord = norm_coord * fimg_size + 0.5f;
	float4 fcoords = (float4)(trunc(scaled_coord), ceil(scaled_coord));
	const float2 weights = scaled_coord - fcoords.xy;
	fcoords = fmod(fcoords, (float4)(fimg_size.x, fimg_size.y,
									 fimg_size.x, fimg_size.y));
	
	const uint4 coords = (uint4)((uint)fcoords.x,
								 img_size.x * (uint)fcoords.y,
								 (uint)fcoords.z,
								 img_size.x * (uint)fcoords.w);
	
	// finally: read texels and interpolate according to weights
	const IMG_TYPE native_texels[4] = {
		img_data_ptr[coords.y + coords.x], // bilinear coords
		img_data_ptr[coords.y + coords.z],
		img_data_ptr[coords.w + coords.x],
		img_data_ptr[coords.w + coords.z]
	};
	const RETURN_TYPE_VEC texels[4] = {
		IMG_CONVERT_FUNC(native_texels[0]),
		IMG_CONVERT_FUNC(native_texels[1]),
		IMG_CONVERT_FUNC(native_texels[2]),
		IMG_CONVERT_FUNC(native_texels[3]),
	};
	return (RETURN_TYPE_VEC4)(
		((texel_mix(texel_mix(texels[0], texels[1], weights.x),
					texel_mix(texels[2], texels[3], weights.x),
					weights.y)IMG_NORMALIZATION VEC4_FILL);
}

RETURN_TYPE_VEC4 FUNC_OVERLOAD OCLRASTER_FUNC IMG_READ_FUNC_NAME()(global const IMG_TYPE* img, const oclr_sampler_t sampler, const float2 coord) {
	// need to check linear first (CLK_FILTER_NEAREST might be 0)
	if((sampler & CLK_FILTER_LINEAR) == CLK_FILTER_LINEAR) return IMG_READ_FUNC_FILTER_NAME(linear)(img, coord);
	else if((sampler & CLK_FILTER_NEAREST) == CLK_FILTER_NEAREST) return IMG_READ_FUNC_FILTER_NAME(nearest)(img, coord);
	return (RETURN_TYPE_VEC4)(IMG_ZERO, IMG_ZERO, IMG_ZERO, IMG_ONE);
}

RETURN_TYPE_VEC4 FUNC_OVERLOAD OCLRASTER_FUNC IMG_READ_FUNC_NAME()(global const IMG_TYPE* img, const oclr_sampler_t sampler, const uint2 coord) {
	// filter must be set to CLK_FILTER_NEAREST
	if((sampler & CLK_FILTER_NEAREST) == CLK_FILTER_NEAREST) return IMG_READ_FUNC_FILTER_NAME(nearest)(img, coord);
	return (RETURN_TYPE_VEC4)(IMG_ZERO, IMG_ZERO, IMG_ZERO, IMG_ONE);
}

//////////////////
// write functions
void FUNC_OVERLOAD OCLRASTER_FUNC IMG_WRITE_FUNC_NAME()(global IMG_TYPE* img, const uint2 coord, const RETURN_TYPE_VEC4 color) {
	const uint2 img_size = oclr_get_image_size((image_header_ptr)img);
	const uint offset = coord.y * img_size.x + coord.x;
	global IMG_TYPE* img_data_ptr = (global IMG_TYPE*)((global uchar*)img + OCLRASTER_IMAGE_HEADER_SIZE);
#if (NEEDS_CONVERT == 1)
#define IMG_OUTPUT_CONVERT_CONCAT(convert_type) convert_##convert_type##_sat
#define IMG_OUTPUT_CONVERT_EVAL(convert_type) IMG_OUTPUT_CONVERT_CONCAT(convert_type)
#define IMG_OUTPUT_CONVERT IMG_OUTPUT_CONVERT_EVAL(IMG_TYPE)

#if (IS_FLOAT_TYPE == 1)
#define IMG_PRE_CONVERT_DENORM IMG_DENORMALIZATION
#elif (IS_HALF_TYPE == 0) && (IS_DOUBLE_TYPE == 0)
#define IMG_PRE_CONVERT_DENORM )))
#endif

#else
#define IMG_OUTPUT_CONVERT
#define IMG_PRE_CONVERT_DENORM )))
#endif

#if (CHANNEL_COUNT == 1)
#define IMG_COLOR color.x
#elif (CHANNEL_COUNT == 2)
#define IMG_COLOR color.xy
#elif (CHANNEL_COUNT == 3)
#define IMG_COLOR color.xyz
#elif (CHANNEL_COUNT == 4)
#define IMG_COLOR color.xyzw
#endif
	img_data_ptr[offset] = IMG_OUTPUT_CONVERT( (((IMG_COLOR IMG_PRE_CONVERT_DENORM );
}
