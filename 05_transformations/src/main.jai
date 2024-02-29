#import "Basic";
#import "System";
#import "SDL";
#import "GL";
#import "Math";
#import "stb_image";

#load "shader.jai";

VERTEX_SHADER :: #string GLSL
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;

out vec2 TexCoord;

uniform mat4 transform;

void main()
{
	gl_Position = transform * vec4(aPos, 1.0);
	TexCoord = vec2(aTexCoord.x, aTexCoord.y);
}
GLSL

FRAGMENT_SHADER :: #string GLSL
#version 330 core
out vec4 FragColor;

in vec2 TexCoord;

// texture samplers
uniform sampler2D texture1;
uniform sampler2D texture2;

void main()
{
	// linearly interpolate between both textures (80% container, 20% awesomeface)
	FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2);
}
GLSL

window_width := 1280;
window_height := 800;

main :: () {
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

	shader_program, success := create_shader_program(VERTEX_SHADER, FRAGMENT_SHADER);
	
	if !success {
		return;
	}
	
	defer glDeleteProgram(shader_program);
	
	vertices := float.[
        // positions          // texture coords
         0.5,  0.5, 0.0,   1.0, 1.0, // top right
         0.5, -0.5, 0.0,   1.0, 0.0, // bottom right
        -0.5, -0.5, 0.0,   0.0, 0.0, // bottom left
        -0.5,  0.5, 0.0,   0.0, 1.0  // top left 
	];

    indices := u32.[
        0, 1, 3, // first triangle
        1, 2, 3  // second triangle
	];

	VAO, VBO, EBO: GLuint;
	
	glGenVertexArrays(1, *VAO);
	defer glDeleteVertexArrays(1, *VAO);
	
	glGenBuffers(1, *VBO);
	defer glDeleteBuffers(1, *VBO);
	
	glGenBuffers(1, *EBO);
	defer glDeleteBuffers(1, *EBO);

	glBindVertexArray(VAO);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(type_of(indices)), xx indices.data, GL_STATIC_DRAW);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, size_of(type_of(vertices)), xx vertices.data, GL_STATIC_DRAW);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * size_of(float), null);
	glEnableVertexAttribArray(0);

	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * size_of(float), xx (3 * size_of(float)));
	glEnableVertexAttribArray(1);

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

	glUseProgram(shader_program);

	glUniform1i(glGetUniformLocation(shader_program, "texture1"), 0);
	glUniform1i(glGetUniformLocation(shader_program, "texture2"), 1);

	time := seconds_since_init();
    delta := 0.0;

	quit: bool;
	while !quit {
		event: SDL_Event;
		while SDL_PollEvent(*event) {
			if event.type == {
				case SDL_QUIT;
					quit = true;
				case SDL_KEYUP;
					if event.key.keysym.sym == SDLK_ESCAPE quit = true;
				case SDL_WINDOWEVENT;
					if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
						window_width = event.window.data1;
						window_height = event.window.data2;
					}
			}
		}

		new_time := seconds_since_init();
        delta = xx (new_time - time);
        time = new_time;

		glViewport(0, 0, xx window_width, xx window_height);
		glClearColor(0.2, 0.3, 0.3, 1.0);
		glClear(GL_COLOR_BUFFER_BIT);
		
		glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture1);
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, texture2);

		transform := Matrix4_Identity;
		transform = translate(transform, .{0.5, -0.5, 0});
		transform = rotate(transform, xx time, .{0, 0, 1});

		glUseProgram(shader_program);
		
		transform_loc := glGetUniformLocation(shader_program, "transform");
        glUniformMatrix4fv(transform_loc, 1, GL_TRUE, *transform.coef[0][0]);

		glBindVertexArray(VAO);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);

		SDL_GL_SwapWindow(window);
	}
}

rotate :: (transform: Matrix4, angle: float, axis: Vector3) -> Matrix4 {
    rotation: Quaternion;
	set_from_axis_and_angle(*rotation, axis, angle);
    return rotate(transform, rotation);
}