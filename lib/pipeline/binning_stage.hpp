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

#ifndef __OCLRASTER_BINNING_STAGE_HPP__
#define __OCLRASTER_BINNING_STAGE_HPP__

#include "oclraster/global.hpp"
#include "cl/opencl.hpp"

struct draw_state;
class binning_stage {
public:
	binning_stage();
	~binning_stage();
	
	const opencl::buffer_object* bin(draw_state& state);

protected:
	opencl::buffer_object* bin_distribution_counter = nullptr;
	opencl::buffer_object* queue_buffer = nullptr;

};

#endif
