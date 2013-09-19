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

#ifndef __OCLRASTER_A2M_HPP__
#define __OCLRASTER_A2M_HPP__

#include "oclraster/global.hpp"
#include "core/vector2.hpp"
#include "core/vector3.hpp"
#include "cl/opencl.hpp"
#include "pipeline/transform_stage.hpp"

class a2m {
public:
	a2m(const string& filename);
	~a2m();
	
	oclraster_struct vertex_data {
		float4 vertex;
		float4 normal;
		float4 binormal;
		float4 tangent;
		float2 tex_coord;
	};
	
	const opencl::buffer_object& get_vertex_buffer() const;
	const opencl::buffer_object& get_index_buffer(const size_t& sub_object) const;
	
	unsigned int get_vertex_count() const;
	unsigned int get_index_count(const unsigned int& sub_object) const;
	
	void flip_faces();
	
protected:
	unsigned int object_count = 0;
	unsigned int vertex_count = 0;
	unsigned int tex_coord_count = 0;
	unsigned int* index_count = nullptr;
	
	float3* vertices = nullptr;
	float3* normals = nullptr;
	float3* binormals = nullptr;
	float3* tangents = nullptr;
	float2* tex_coords = nullptr;
	
	vector<string> object_names;
	index3** indices = nullptr;
	index3** tex_indices = nullptr;
	
	//
	opencl::buffer_object* cl_vertex_buffer;
	vector<opencl::buffer_object*> cl_index_buffers;
	
	//
	void load(const string& filename);
	void reorganize_model_data();
	void generate_normals();

};

#endif
