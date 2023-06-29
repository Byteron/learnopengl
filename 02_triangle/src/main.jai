#import "Basic";
#import "SDL";
#import "GL";

VERTEX_SHADER :: #string GLSL
#version 330 core
layout (location = 0) in vec3 aPos;

void main()
{
    gl_Position = vec4(aPos, 1.0);
}
GLSL

FRAGMENT_SHADER :: #string GLSL
#version 330 core
out vec4 FragColor;

void main()
{
    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
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

	vertex_shader := glCreateShader(GL_VERTEX_SHADER);
	defer glDeleteShader(vertex_shader);
	glShaderSource(vertex_shader, 1, *to_c_string(VERTEX_SHADER), null);
	glCompileShader(vertex_shader);

	success: GLint;
    info_log: [512]u8;
	glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, *success);
	if !success {
		glGetShaderInfoLog(vertex_shader, 512, null, info_log.data);
        log_error("Error: %\n", to_string(info_log));
		return;
	}

	fragment_shader := glCreateShader(GL_FRAGMENT_SHADER);
	defer glDeleteShader(vertex_shader);
	glShaderSource(fragment_shader, 1, *to_c_string(FRAGMENT_SHADER), null);
	glCompileShader(fragment_shader);

	glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, *success);
	if !success {
		glGetShaderInfoLog(fragment_shader, 512, null, info_log.data);
        log_error("Error: %\n", to_string(info_log));
		return;
	}

	shader_program := glCreateProgram();
	defer glDeleteProgram(shader_program);
	glAttachShader(shader_program, vertex_shader);
	glAttachShader(shader_program, fragment_shader);
	glLinkProgram(shader_program);

	glGetProgramiv(shader_program, GL_LINK_STATUS, *success);
    if !success {
        glGetProgramInfoLog(shader_program, 512, null, info_log.data);
        log_error("Error: %\n", to_string(info_log));
		return;
    }

	VERTICES :: float.[
		0.5,  0.5, 0.0,  // top right
         0.5, -0.5, 0.0,  // bottom right
        -0.5, -0.5, 0.0,  // bottom left
        -0.5,  0.5, 0.0   // top left
	];

	INDICES :: u32.[
		0, 1, 3,  // first Triangle
        1, 2, 3,  // second Triangle
	];

	VAO, VBO, EBO: GLuint;
	glGenVertexArrays(1, *VAO);
	defer glDeleteVertexArrays(1, *VAO);
	glGenBuffers(1, *VBO);
	defer glDeleteBuffers(1, *VBO);
	glGenBuffers(1, *EBO);
	defer glDeleteBuffers(1, *EBO);

	glBindVertexArray(VAO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, size_of(type_of(VERTICES)), xx VERTICES.data, GL_STATIC_DRAW);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(type_of(INDICES)), xx INDICES.data, GL_STATIC_DRAW);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * size_of(float), null);
	glEnableVertexAttribArray(0);

	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);

	// glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

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

		glViewport(0, 0, xx window_width, xx window_height);
		glClearColor(0.2, 0.3, 0.3, 1.0);
		glClear(GL_COLOR_BUFFER_BIT);
		
		glUseProgram(shader_program);
		glBindVertexArray(VAO);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);

		SDL_GL_SwapWindow(window);
	}
}

