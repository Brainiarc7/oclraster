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

#include "oclr_simple.h"

// global vars, don't change these!
static bool done { false };
static event* evt { nullptr };
static camera* cam { nullptr };
static constexpr float3 cam_speeds { 0.01f, 0.1f, 0.001f };
static atomic<unsigned int> update_model { false };
static atomic<unsigned int> update_light { true };
static atomic<unsigned int> update_light_color { false };
static transform_program* transform_prog { nullptr };
static rasterization_program* rasterization_prog { nullptr };
static pipeline* p { nullptr };
static atomic<unsigned int> selected_material { 0 };
static constexpr size_t material_count { 5 };

int main(int argc floor_unused, char* argv[]) {
	// initialize oclraster
	oclraster::init(argv[0],
#if !defined(OCLRASTER_IOS)
					(const char*)"../data/"
#else
					(const char*)"/var/mobile/Documents/oclraster/"
#endif
					);
	floor::set_caption(APPLICATION_NAME);
	floor::acquire_context();
	
	// init class pointers
	evt = floor::get_event();
	//ocl->set_active_device(opencl_base::DEVICE_TYPE::FASTEST_CPU);
	ocl->set_active_device(opencl_base::DEVICE_TYPE::FASTEST_GPU);
	//ocl->set_active_device(opencl_base::DEVICE_TYPE::GPU0);
	
	//
	cam = new camera();
#if 0
	cam->set_position(0.0f, 0.1f, -0.3f);
	//cam->set_position(1.12157e-12f, 0.1f, -2.22f);
	cam->set_rotation(0.0f, 0.0f, 0.0f);
#elif 1
	cam->set_position(0.8f, 0.28f, 3.2f);
	cam->set_rotation(-5.2f, 196.0f, 0.0f);
#else
	cam->set_position(10.0f, 5.0f, -10.0f);
	cam->set_rotation(-20.0f, -45.0f, 0.0f);
#endif
	cam->set_speed(cam_speeds.x);
	cam->set_rotation_speed(cam->get_rotation_speed() * 1.5f);
	cam->set_wasd_input(true);
	
	// create the pipeline, set the active camera and
	// notify oclraster that this is the active pipeline
	p = new pipeline();
	p->set_camera(cam);
	oclraster::set_active_pipeline(p);
	
	// load the model (blender monkey with uv coordinates)
	a2m* model = new a2m(floor::data_path("monkey_uv.a2m"));
	//a2m* model = new a2m(floor::data_path("blend_test.a2m"));
	//model->flip_faces();
	
	// add event handlers
	event::handler key_handler_fnctr(&key_handler);
	evt->add_event_handler(key_handler_fnctr, EVENT_TYPE::KEY_DOWN, EVENT_TYPE::KEY_UP);
	event::handler mouse_handler_fnctr(&mouse_handler);
	evt->add_internal_event_handler(mouse_handler_fnctr, EVENT_TYPE::MOUSE_RIGHT_CLICK, EVENT_TYPE::MOUSE_MOVE);
	event::handler quit_handler_fnctr(&quit_handler);
	evt->add_event_handler(quit_handler_fnctr, EVENT_TYPE::QUIT);
	event::handler kernel_reload_handler_fnctr(&kernel_reload_handler);
	evt->add_internal_event_handler(kernel_reload_handler_fnctr, EVENT_TYPE::KERNEL_RELOAD);
#if defined(OCLRASTER_IOS)
	event::handler touch_handler_fnctr(&touch_handler);
	evt->add_event_handler(touch_handler_fnctr, EVENT_TYPE::FINGER_UP, EVENT_TYPE::FINGER_DOWN, EVENT_TYPE::FINGER_MOVE);
#endif
	
	// load, compile and bind user shaders
	if(!load_programs()) return -1;
	
	// create / ref buffers
	const opencl::buffer_object& index_buffer = model->get_index_buffer(0);
	const opencl::buffer_object& input_attributes = model->get_vertex_buffer();
	
	oclraster_struct tp_uniforms {
		matrix4f modelview;
		matrix4f rotation_matrix;
	} transform_uniforms {
		matrix4f(),
		matrix4f()
	};
	opencl::buffer_object* tp_uniforms_buffer = ocl->create_buffer(opencl::BUFFER_FLAG::READ |
																   opencl::BUFFER_FLAG::INITIAL_COPY |
																   opencl::BUFFER_FLAG::BLOCK_ON_WRITE,
																   sizeof(tp_uniforms),
																   (void*)&transform_uniforms);
	
	float light_pos = PI, light_dist = 10.0f, light_intensity = 32.0f;
	oclraster_struct rp_uniforms {
		float4 camera_position;
		float4 light_position; // .w = light radius ^ 2
		float4 light_color;
	} rasterize_uniforms {
		float4(cam->get_position(), 1.0f),
		float4(sinf(light_pos)*light_dist, 0.0f, cosf(light_pos)*light_dist, light_intensity*light_intensity),
		//float4(1.0f, 1.0f, 1.0f, 1.0f)
		float4(0.0f, 0.3f, 0.7f, 1.0f)
	};
	opencl::buffer_object* rp_uniforms_buffer = ocl->create_buffer(opencl::BUFFER_FLAG::READ |
																   opencl::BUFFER_FLAG::INITIAL_COPY |
																   opencl::BUFFER_FLAG::BLOCK_ON_WRITE,
																   sizeof(rp_uniforms),
																   (void*)&rasterize_uniforms);
	
	// textures
	static constexpr size_t textures_per_material = 3;
	static const array<string, material_count * textures_per_material> texture_names {
		{
			"light_512",
			"light_normal_512",
			"light_height_512",
			"planks_512",
			"planks_normal_512",
			"planks_height_512",
			"rockwall_512",
			"rockwall_normal_512",
			"rockwall_height_512",
			"acid_512",
			"acid_normal_512",
			"acid_height_512",
			"blend_test_512",
			"light_normal_512",
			"scale_gray",
		}
	};
	
	static constexpr auto image_backing = image::BACKING::BUFFER; // or image::BACKING::IMAGE
	array<array<shared_ptr<image>, textures_per_material>, material_count> materials;
	for(size_t i = 0; i < material_count; i++) {
		for(size_t j = 0; j < textures_per_material; j++) {
			materials[i][j] = make_shared<image>(image::from_file(floor::data_path(texture_names[(i * textures_per_material) + j]+".png"),
																  image_backing, IMAGE_TYPE::UINT_8, IMAGE_CHANNEL::RGBA));
		}
	}
	
	//
	float* fp_noise_data = new float[512*512];
	for(size_t i = 0; i < (512*512); i++) {
		fp_noise_data[i] = core::rand(0.0f, 1.0f);
	}
	image* fp_noise = new image(512, 512, image_backing, IMAGE_TYPE::FLOAT_32, IMAGE_CHANNEL::R, fp_noise_data);
	delete [] fp_noise_data;
	
#if 0
	// enable this if you want the framebuffer clear color to be white
	p->get_default_framebuffer()->set_clear_color(ulong4 { ~0 });
#endif
	
	// init done
	floor::release_context();
	
	// main loop
	float model_rotation = 0.0f;
	float3 model_scale { 1.0f, 1.0f, 1.0f };
	float3 target_scale { model_scale };
	static constexpr float model_scale_range = 0.4f, model_scale_step = 0.01f;
	while(!done) {
		// event handling
		evt->handle_events();
		
#if 0 // enable this to disable rendering when the window is inactive
		// stop drawing if window is inactive
		if(!(SDL_GetWindowFlags(floor::get_window()) & SDL_WINDOW_INPUT_FOCUS)) {
			SDL_Delay(20);
			continue;
		}
#endif
		
		// set caption (app name and fps count)
		if(floor::is_new_fps_count()) {
			const unsigned int fps = floor::get_fps();
			//oclr_log("fps: %u", fps);
			stringstream caption;
			caption << APPLICATION_NAME;
			caption << " | " << fps << " FPS";
			caption << " | ~" << floor::get_frame_time() << "ms ";
			caption << " | Cam: " << cam->get_position();
			caption << " " << cam->get_rotation();
			floor::set_caption(caption.str());
		}
		
		floor::start_draw();
		cam->run();
		p->set_camera(cam); // update pipeline camera
#if 0 // enable this to test a custom depth test function
		p->set_depth_function(DEPTH_FUNCTION::CUSTOM,
							  "bool depth_test(float incoming, float current) {" \
							  "	const float depth = fmod(incoming, 0.1f);" \
							  "	return (depth > 0.05f && incoming < current);" \
							  "}");
#endif
		
		// update uniforms
		if(update_model) {
			transform_uniforms.modelview = matrix4f().rotate_y(model_rotation);
			transform_uniforms.rotation_matrix = transform_uniforms.modelview;
			model_rotation += 1.0f;
			if(model_rotation >= 360.0f) {
				selected_material = (selected_material + 1) % material_count;
				model_rotation = core::wrap(model_rotation, 360.0f);
			}
			
			const float3 scale_diff = (model_scale - target_scale).abs();
			if((scale_diff <= float3(model_scale_step * 2.0f)).all()) {
				target_scale.x = 1.0f + core::rand(-model_scale_range, model_scale_range);
				target_scale.y = 1.0f + core::rand(-model_scale_range, model_scale_range);
				target_scale.z = 1.0f + core::rand(-model_scale_range, model_scale_range);
			}
			else {
				for(unsigned int i = 0; i < 3; i++) {
					if(scale_diff[i] <= (model_scale_step * 2.0f)) continue;
					model_scale[i] += model_scale_step * (model_scale[i] <= target_scale[i] ? 1.0f : -1.0f);
				}
			}
			transform_uniforms.modelview.scale(model_scale.x, model_scale.y, model_scale.z);
			ocl->write_buffer(tp_uniforms_buffer, &transform_uniforms);
		}
			
		if(update_light) {
			light_pos -= 0.125f;
			rasterize_uniforms.light_position.set(sinf(light_pos)*light_dist,
												  0.0f,
												  cosf(light_pos)*light_dist,
												  light_intensity * light_intensity);
		}
		if(update_light_color) {
			static constexpr float color_step_range = 0.05f;
			rasterize_uniforms.light_color.x += core::rand(-color_step_range, color_step_range);
			rasterize_uniforms.light_color.y += core::rand(-color_step_range, color_step_range);
			rasterize_uniforms.light_color.z += core::rand(-color_step_range, color_step_range);
			rasterize_uniforms.light_color.clamp(0.0f, 1.0f);
		}
		
		rasterize_uniforms.camera_position.vector3<float>::set(cam->get_position());
		ocl->write_buffer(rp_uniforms_buffer, &rasterize_uniforms);
		
		// draw something
		p->bind_buffer("index_buffer", index_buffer);
		p->bind_buffer("input_attributes", input_attributes);
		p->bind_buffer("tp_uniforms", *tp_uniforms_buffer);
		p->bind_buffer("rp_uniforms", *rp_uniforms_buffer);
		p->bind_image("diffuse_texture", *materials[selected_material][0]);
		p->bind_image("normal_texture", *materials[selected_material][1]);
		p->bind_image("height_texture", *materials[selected_material][2]);
		p->bind_image("fp_noise", *fp_noise);
		p->draw(PRIMITIVE_TYPE::TRIANGLE, model->get_vertex_count(), { 0, model->get_index_count(0) });
		
		floor::stop_draw();
	}
	
	// cleanup
	for(auto& mat : materials) {
		for(auto& tex : mat) {
			tex = nullptr; // clear
		}
	}
	delete fp_noise;
	delete model;
	delete cam;
	
	ocl->delete_buffer(tp_uniforms_buffer);
	ocl->delete_buffer(rp_uniforms_buffer);
	
	evt->remove_event_handler(key_handler_fnctr);
	evt->remove_event_handler(mouse_handler_fnctr);
	evt->remove_event_handler(quit_handler_fnctr);
	delete p;
	oclraster::destroy();
	
	return 0;
}

bool load_programs() {
	if(transform_prog != nullptr) {
		delete transform_prog;
		transform_prog = nullptr;
	}
	if(rasterization_prog != nullptr) {
		delete rasterization_prog;
		rasterization_prog = nullptr;
	}
	
	string vs_str, fs_str;
	static const array<string, 2> shader_filenames {
#if 0
		{ "simple_texturing.cl", "simple_texturing.cl" }
#elif 1
		{ "simple_parallax_vs.cl", "simple_parallax_fs.cl" }
#elif 1
		{ "debug_vs.cl", "debug_fs.cl" }
#else
		{ "simple_shader_vs.cl", "simple_shader_fs.cl" }
#endif
	};
	
	if(!file_io::file_to_string(floor::kernel_path("user/"+shader_filenames[0]), vs_str)) {
		log_error("couldn't open vs program!");
		return false;
	}
	if(!file_io::file_to_string(floor::kernel_path("user/"+shader_filenames[1]), fs_str)) {
		log_error("couldn't open fs program!");
		return false;
	}
	transform_prog = new transform_program(vs_str, "transform_main");
	rasterization_prog = new rasterization_program(fs_str, "rasterize_main");
	p->bind_program(*transform_prog);
	p->bind_program(*rasterization_prog);
	return true;
}

bool kernel_reload_handler(EVENT_TYPE type, shared_ptr<event_object> obj floor_unused) {
	if(type == EVENT_TYPE::KERNEL_RELOAD) {
		load_programs();
		return true;
	}
	return false;
}

bool key_handler(EVENT_TYPE type, shared_ptr<event_object> obj) {
	if(type == EVENT_TYPE::KEY_DOWN) {
		const shared_ptr<key_down_event>& key_evt = (shared_ptr<key_down_event>&)obj;
		switch(key_evt->key) {
			case SDLK_LCTRL:
				cam->set_speed(cam_speeds.z);
				break;
			case SDLK_LSHIFT:
				cam->set_speed(cam_speeds.y);
				break;
			default: return false;
		}
	}
	else if(type == EVENT_TYPE::KEY_UP) {
		const shared_ptr<key_up_event>& key_evt = (shared_ptr<key_up_event>&)obj;
		switch(key_evt->key) {
			case SDLK_ESCAPE:
				done = true;
				break;
			case SDLK_LCTRL:
			case SDLK_LSHIFT:
				cam->set_speed(cam_speeds.x);
				break;
			case SDLK_F19:
			case SDLK_0:
				floor::reload_kernels();
				break;
			case SDLK_m:
				update_model ^= true;
				break;
			case SDLK_l:
				update_light ^= true;
				break;
			case SDLK_c:
				update_light_color ^= true;
				break;
			case SDLK_f:
				p->_set_fxaa_state(p->_get_fxaa_state() ^ true);
				break;
			case SDLK_1:
				selected_material = 0;
				break;
			case SDLK_2:
				selected_material = 1;
				break;
			case SDLK_3:
				selected_material = 2;
				break;
			case SDLK_4:
				selected_material = 3;
				break;
			case SDLK_5:
				selected_material = 4;
				break;
			default: return false;
		}
	}
	return true;
}

bool mouse_handler(EVENT_TYPE type, shared_ptr<event_object> obj floor_unused) {
	if(type == EVENT_TYPE::MOUSE_RIGHT_CLICK) {
		cam->set_mouse_input(cam->get_mouse_input() ^ true);
		// TODO: switch cam input
		//oclraster::set_cursor_visible(oclraster::get_cursor_visible() ^ true);
	}
	return true;
}

bool quit_handler(EVENT_TYPE type floor_unused, shared_ptr<event_object> obj floor_unused) {
	done = true;
	return true;
}

#if defined(OCLRASTER_IOS)
bool touch_handler(EVENT_TYPE type, shared_ptr<event_object> obj floor_unused) {
	if(type == EVENT_TYPE::FINGER_UP) {
		//const shared_ptr<finger_up_event>& touch_evt = (shared_ptr<finger_up_event>&)obj;
		//oclr_msg("finger up: %v, %u, #%u", touch_evt->position, touch_evt->pressure, touch_evt->id);
		selected_material = (selected_material + 1) % material_count;
	}
	/*else if(type == EVENT_TYPE::FINGER_DOWN) {
		const shared_ptr<finger_down_event>& touch_evt = (shared_ptr<finger_down_event>&)obj;
		oclr_msg("finger down: %v, %u, #%u", touch_evt->position, touch_evt->pressure, touch_evt->id);
	}
	else if(type == EVENT_TYPE::FINGER_MOVE) {
		const shared_ptr<finger_move_event>& touch_evt = (shared_ptr<finger_move_event>&)obj;
		oclr_msg("finger move: %v -> %v, %u, #%u", touch_evt->position, touch_evt->move, touch_evt->pressure, touch_evt->id);
	}*/
	return true;
}
#endif
