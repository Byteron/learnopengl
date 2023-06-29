#import "Basic";
#import "System";
#import "SDL";
#import "GL";
#import "Math";

#load "shader.jai";

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

	path := path_strip_filename(get_path_of_running_executable());
	vertex_source := read_entire_file(tprint("%/%", path, "assets/shaders/03_shaders/shader.vert"));
	fragment_source := read_entire_file(tprint("%/%", path, "assets/shaders/03_shaders/shader.frag"));

	shader_program, success := create_shader_program(vertex_source, fragment_source);
	
	if !success {
		return;
	}
	
	defer glDeleteProgram(shader_program);

	// we use a Vertex struct, containing a Vector3 for position and a Vector3 for color
	// in memory it is the same layout as if we would use a float array
	VERTICES :: Vertex.[
		.{.{0.5, -0.5, 0},  .{1, 0, 0}},  // bottom right
        .{.{-0.5, -0.5, 0},  .{0, 1, 0}},  // bottom left
         .{.{0,  0.5, 0},  .{0, 0, 1}},   // top
	];

	VAO, VBO: GLuint;
	glGenVertexArrays(1, *VAO);
	defer glDeleteVertexArrays(1, *VAO);
	glGenBuffers(1, *VBO);
	defer glDeleteBuffers(1, *VBO);

	glBindVertexArray(VAO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, size_of(type_of(VERTICES)), xx VERTICES.data, GL_STATIC_DRAW);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), null);
	glEnableVertexAttribArray(0);

	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), xx (size_of(Vector3)));
	glEnableVertexAttribArray(1);

	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);

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
		glDrawArrays(GL_TRIANGLES, 0, 3);

		SDL_GL_SwapWindow(window);
	}
}

Vertex :: struct {
	position: Vector3;
	color: Vector3;
};