#import "Basic";
#import "SDL";
#import "GL";

window_width := 1280;
window_height := 800;

main :: () {
    SDL_Init(SDL_INIT_VIDEO);
	defer SDL_Quit();

	window := SDL_CreateWindow(
		"Window",
		SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
		xx window_width, xx window_height, 
		SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE
	);

	if !window {
		print("Could not create Window: %\n", to_string(SDL_GetError()));
		return;
	}
	
	defer SDL_DestroyWindow(window);

	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

	gl_context := SDL_GL_CreateContext(window);
	if !gl_context {
		print("Could not create OpenGL context: %\n", to_string(SDL_GetError()));
		return;
	}

	gl_load(*gl, SDL_GL_GetProcAddress);
	using gl;

	print("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
	print("GL Version = %\n", to_string(glGetString(GL_VERSION)));

    time: float;
    delta: float;

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

		new_time: float = xx get_time();
        delta := new_time - time;
        time = new_time;

		glViewport(0, 0, xx window_width, xx window_height);
		glClearColor(0.0, 0.0, 0.0, 1.0);
		glClear(GL_COLOR_BUFFER_BIT);
		
		SDL_GL_SwapWindow(window);
	}
}