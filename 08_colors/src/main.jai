#import "Basic";
#import "System";
#import "SDL";
#import "GL";
#import "Math";
#import "stb_image";

#load "shader.jai";
#load "camera.jai";
#load "input.jai";

UP :: Vector3.{0, 1, 0};

window_width: s32 = 1280;
window_height: s32 = 800;

camera_speed := 2.5;
camera_position := Vector3.{0, 0, 3};
camera_front := Vector3.{0, 0, -1};

mouse_x := 0;
mouse_y := 0;
mouse_scroll := 0;

camera: Camera;

time: float64;
delta: float;

light_position :: Vector3.{1.2, 1, 2};

main :: () {
	print("%\n", light_position);

	time = seconds_since_init();
    SDL_Init(SDL_INIT_VIDEO);
	defer SDL_Quit();

	window := SDL_CreateWindow(
		"LearnOpenGL",
		SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
		xx window_width, xx window_height, 
		SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE
	);

	if !window {
		log_error("Could not create Window: %\n", to_string(SDL_GetError()));
		return;
	}
	
	defer SDL_DestroyWindow(window);

	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
	gl_context := SDL_GL_CreateContext(window);
	if !gl_context {
		log_error("Could not create OpenGL context: %\n", to_string(SDL_GetError()));
		return;
	}

	gl_load(*gl, SDL_GL_GetProcAddress);
	using gl;

	print("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
	print("GL Version = %\n", to_string(glGetString(GL_VERSION)));

	glEnable(GL_DEPTH_TEST);
	
	SDL_ShowCursor(0);

	light_shader, success1 := create_shader_program(LIGHT_VERTEX_SHADER, LIGHT_FRAGMENT_SHADER);
	lighting_shader, success2 := create_shader_program(LIGHTING_VERTEX_SHADER, LIGHTING_FRAGMENT_SHADER);

	if !(success1 || success2) {
		return;
	}
	
	
	defer glDeleteProgram(light_shader);
	defer glDeleteProgram(lighting_shader);
	
	vertices := float.[
		-0.5, -0.5, -0.5,  0.0, 0.0,
         0.5, -0.5, -0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 0.0,

        -0.5, -0.5,  0.5,  0.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,

        -0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5,  0.5,  1.0, 0.0,

         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5,  0.5,  0.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  1.0, 1.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,

        -0.5,  0.5, -0.5,  0.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0
	];

	cubes := Vector3.[
        .{0.0,  0.0,  0.0},
        .{2.0,  5.0, -15.0},
        .{-1.5, -2.2, -2.5},
        .{-3.8, -2.0, -12.3},
        .{2.4, -0.4, -3.5},
        .{-1.7,  3.0, -7.5},
        .{1.3, -2.0, -2.5},
        .{1.5,  2.0, -2.5},
        .{1.5,  0.2, -1.5},
        .{-1.3,  1.0, -1.5},
    ];

	cube_VAO, VBO: GLuint;
	
	glGenVertexArrays(1, *cube_VAO);
	defer glDeleteVertexArrays(1, *cube_VAO);
	
	glGenBuffers(1, *VBO);
	defer glDeleteBuffers(1, *VBO);

	glBindVertexArray(cube_VAO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, size_of(type_of(vertices)), xx vertices.data, GL_STATIC_DRAW);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * size_of(float), null);
	glEnableVertexAttribArray(0);

	cube_light_VAO: GLuint;

	glGenVertexArrays(1, *cube_light_VAO);
	defer glDeleteVertexArrays(1, *cube_light_VAO);
	
	glBindVertexArray(cube_light_VAO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * size_of(float), null);
	glEnableVertexAttribArray(0);

	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);

	texture1, texture2: GLuint;

	glGenTextures(1, *texture1);
	glBindTexture(GL_TEXTURE_2D, texture1);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	path := path_strip_filename(get_path_of_running_executable());

	width, height, nr_channels : s32 = 0;
	// jai bindings do not have the flip function, so we will have to deal with upside down images for now
    data := stbi_load(to_c_string(tprint("%/%", path, "assets/images/container.jpg")), *width, *height, *nr_channels, 0);
    
	if data == null {
        log_error("Failed to load texture\n");
		return;
    }

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, xx width, xx height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
	glGenerateMipmap(GL_TEXTURE_2D);

	stbi_image_free(data);

	glGenTextures(1, *texture2);
	glBindTexture(GL_TEXTURE_2D, texture2);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    data = stbi_load(to_c_string(tprint("%/%", path, "assets/images/awesomeface.png")), *width, *height, *nr_channels, 0);
    
	if data == null {
        log_error("Failed to load texture\n");
		return;
    }

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, xx width, xx height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
	glGenerateMipmap(GL_TEXTURE_2D);

	stbi_image_free(data);

	// glUseProgram(shader_program);

	quit: bool;
	while !quit {
		mouse_x, mouse_y, mouse_scroll = 0;
		is_warping_mouse := false;
		
		reset_keys();

		event: SDL_Event;
		while SDL_PollEvent(*event) {
			if event.type == {
				case SDL_QUIT;
					quit = true;
				case SDL_KEYDOWN;
					press_key(event.key.keysym.scancode);
				case SDL_KEYUP;
					release_key(event.key.keysym.scancode);
				case SDL_WINDOWEVENT;
					if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
						window_width = event.window.data1;
						window_height = event.window.data2;
					}
					SDL_WarpMouseInWindow(window, window_width / 2, window_height / 2);
					is_warping_mouse = true;
				case SDL_MOUSEMOTION;
					if is_warping_mouse {
						is_warping_mouse = false;
					} else {
						mouse_x = event.motion.xrel;
						mouse_y = event.motion.yrel;
					}
			
				case SDL_MOUSEWHEEL;
					mouse_scroll = event.wheel.y;
			}
		}
		
		if key_down(SDL_SCANCODE_ESCAPE) quit = true;

		new_time := seconds_since_init();
        delta = xx (new_time - time);
        time = new_time;

		update_flying_camera(*camera);
			
		glViewport(0, 0, xx window_width, xx window_height);

		glClearColor(0.2, 0.3, 0.3, 1.0);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		glUseProgram(lighting_shader);
		set_vec3(lighting_shader, "objectColor", xyz(1, 0.5, 0.31));
		set_vec3(lighting_shader, "lightColor", xyz(1, 1, 1));

		//set_mat4(shader_program, "projection", camera.projection_matrix);
        //set_mat4(shader_program, "view", camera.view_matrix);

		glBindVertexArray(cube_VAO);

        for i: 0..9 {
            model := Matrix4_Identity;
            model = translate(model, cubes[i]);
            angle := 20.0 * i;
            model = rotate(model, radians(angle), Vector3.{1.0, 0.3, 0.5});

            //set_mat4(shader_program, "model", model);
            
            glDrawArrays(GL_TRIANGLES, 0, 36);
        }

		SDL_GL_SwapWindow(window);
	}
}

radians :: (angle: float) -> float {
	return angle * (PI / 180);
}

rotate :: (transform: Matrix4, angle: float, axis: Vector3) -> Matrix4 {
    rotation: Quaternion;
	set_from_axis_and_angle(*rotation, axis, angle);
    return rotate(transform, rotation);
}

LIGHT_VERTEX_SHADER :: #string GLSL
#version 330 core
layout (location = 0) in vec3 aPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);
} 
GLSL

LIGHT_FRAGMENT_SHADER :: #string GLSL
#version 330 core
out vec4 FragColor;
  
uniform vec3 objectColor;
uniform vec3 lightColor;

void main()
{
    FragColor = vec4(lightColor * objectColor, 1.0);
}
GLSL

LIGHTING_VERTEX_SHADER :: #string GLSL
#version 330 core
layout (location = 0) in vec3 aPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);
} 
GLSL

LIGHTING_FRAGMENT_SHADER :: #string GLSL
#version 330 core
out vec4 FragColor;
  
uniform vec3 objectColor;
uniform vec3 lightColor;

void main()
{
    FragColor = vec4(lightColor * objectColor, 1.0);
}
GLSL