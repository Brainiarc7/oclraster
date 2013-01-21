/*
 *  Flexible OpenCL Rasterizer (oclraster)
 *  Copyright (C) 2012 - 2013 Florian Ziesche
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; version 2 of the License only.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef __OCLRASTER_PIPELINE_H__
#define __OCLRASTER_PIPELINE_H__

#include "cl/opencl.h"
#include "pipeline/transform_stage.h"
#include "pipeline/binning_stage.h"
#include "pipeline/rasterization_stage.h"
#include "core/rtt.h"
#include "core/event.h"
#include "program/oclraster_program.h"
#include "program/transform_program.h"
#include "program/rasterize_program.h"

struct draw_state {
	// TODO: store actual flags/data
	union {
		struct {
			unsigned int blending : 1;
			unsigned int depth_test : 1;
			unsigned int scissor_test : 1;
			unsigned int backface_culling : 1;
			
			//
			unsigned int _unused : 28;
		};
		unsigned int flags;
	};
	
	// set this to the required size (transformed primitive + attribute data)
	unsigned int transformed_primitive_size = 3 * sizeof(float3);
	
	// framebuffers
	uint2 framebuffer_size { 1280, 720 };
	opencl::buffer_object* color_framebuffer = nullptr;
	opencl::buffer_object* depth_framebuffer = nullptr;
	
	//
	opencl_base::buffer_object* transformed_buffer = nullptr;
	opencl_base::buffer_object* transformed_user_buffer = nullptr;
	opencl_base::buffer_object* index_buffer = nullptr;
	//unordered_map<string, opencl_base::buffer_object*> user_buffers;
	
	//
	const transform_program* transform_prog = nullptr;
	const rasterize_program* rasterize_prog = nullptr;
	
	//
	const uint2 tile_size { 32, 32 };
	opencl_base::buffer_object* triangle_queues_buffer = nullptr;
	opencl_base::buffer_object* queue_sizes_buffer = nullptr;
	unsigned int* triangle_queues_buffer_zero = nullptr; // TODO: better method?
	unsigned int* queue_sizes_buffer_zero = nullptr;
	unsigned int reserved_triangle_count = 512;
	uint2 bin_count_xy { 0, 0 };
	unsigned int bin_count = 0;
};

class pipeline {
public:
	pipeline();
	~pipeline();
	
	//
	void start();
	void stop();
	
	//
	template <class program_type> void bind_program(const program_type& program);
	
	// TODO: buffer binding
	
	// "draw calls" (for now, these always draw triangles)
	void draw(const transform_stage::vertex_buffer& vb,
			  const transform_stage::index_buffer& ib,
			  // default element range: draw all
			  const pair<unsigned int, unsigned int> element_range = { ~0u, ~0u });
	
	// for debugging and initial development purposes:
	void _reserve_memory(const unsigned int triangle_count);
	
protected:
	draw_state state;
	transform_stage transform;
	binning_stage binning;
	rasterization_stage rasterization;
	
	//
	void create_framebuffers(const uint2& size);
	void destroy_framebuffers();
	uint2 framebuffer_size { 1280, 720 };
	rtt::fbo* color_framebuffer = nullptr;
	opencl::buffer_object* color_framebuffer_cl = nullptr;
	rtt::fbo* depth_framebuffer = nullptr;
	opencl::buffer_object* depth_framebuffer_cl = nullptr;
	
	// slow map/copy framebuffer fallback (requires no opengl sharing)
	bool cl_framebuffer_fallback = false;
	GLuint copy_fbo_id = 0, copy_fbo_tex_id = 0;
	
	//
	const uint2 tile_size { 16, 16 };
	opencl_base::buffer_object* triangle_queues_buffer = nullptr;
	opencl_base::buffer_object* queue_sizes_buffer = nullptr;
	unsigned int* triangle_queues_buffer_zero = nullptr;
	unsigned int* queue_sizes_buffer_zero = nullptr;
	unsigned int reserved_triangle_count = 512;
	
	// window event handlers
	event::handler window_handler;
	bool window_event_handler(EVENT_TYPE type, shared_ptr<event_object> obj);
	
};

//
template <class program_type> void pipeline::bind_program(const program_type& program) {
	static_assert(is_base_of<oclraster_program, program_type>::value,
				  "invalid program type (must derive from oclraster_program)!");
	static_assert(is_base_of<transform_program, program_type>::value ||
				  is_base_of<rasterize_program, program_type>::value,
				  "invalid program type (must be a transform_program or rasterize_program or a derived class)!");
	// static_if would be nice
	if(is_base_of<transform_program, program_type>::value) {
		state.transform_prog = (transform_program*)&program;
	}
	else if(is_base_of<rasterize_program, program_type>::value) {
		state.rasterize_prog = (rasterize_program*)&program;
	}
}

#endif
