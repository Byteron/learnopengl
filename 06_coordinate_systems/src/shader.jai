// given jai is a procedural language, not an object oriented one, 
// we will take a different approach to handling the "shader class"

create_shader_program :: (vertex_source: string, fragment_source: string) -> GLuint, bool {

	check_compile_errors :: (shader: GLuint) -> bool, string {
		success: s32;
		glGetShaderiv(shader, GL_COMPILE_STATUS, *success);
		if !success {
			info_len: s32;
			glGetShaderiv(shader, GL_INFO_LOG_LENGTH, *info_len);
			info_data := cast(*u8) alloc(info_len, temp);
			glGetShaderInfoLog(shader, xx info_len, xx *info_len, info_data);
			result: string;
			result.data = info_data;
			result.count = info_len;

			return false, result;
		}

		return true, "";
	}

	check_link_errors :: (program: GLuint) -> bool, string {
		success: s32;
		glGetProgramiv(program, GL_LINK_STATUS, *success);
		if !success {
			info_len: s32;
			glGetProgramiv(program, GL_INFO_LOG_LENGTH, *info_len);
			info_data := cast(*u8) alloc(info_len, temp);
			glGetProgramInfoLog(program, xx info_len, xx *info_len, info_data);
			result: string;
			result.data = info_data;
			result.count = info_len;

			return false, result;
		}

		return true, "";
	}

	vs := glCreateShader(GL_VERTEX_SHADER);
	defer glDeleteShader(vs);
	glShaderSource(vs, 1, *vertex_source.data, null);
	glCompileShader(vs);
	ok, info_log := check_compile_errors(vs);
	if !ok {
		log_error("Could not compile vertex shader %", info_log);
		return 0, false;
	}

	fs := glCreateShader(GL_FRAGMENT_SHADER);
	defer glDeleteShader(fs);
	glShaderSource(fs, 1, *fragment_source.data, null);
	glCompileShader(fs);
	ok, info_log = check_compile_errors(fs);
	if !ok {
		log_error("Could not compile fragment shader %", info_log);
		return 0, false;
	}

	result := glCreateProgram();
	glAttachShader(result, vs);
	glAttachShader(result, fs);
	glLinkProgram(result);
	ok, info_log = check_link_errors(result);
	if !ok {
		log_error("Could not link shader program %", info_log);
		glDeleteProgram(result);
		return 0, false;
	}

	return result, true;
}

set_int :: (shader: GLuint, name: string, value: s32) {
    glUniform1i(glGetUniformLocation(shader, to_c_string(name)), value);
}

set_mat4 :: (shader: GLuint, name: string, value: Matrix4) {
    glUniformMatrix4fv(glGetUniformLocation(shader, to_c_string(name)), 1, GL_TRUE, *value.coef[0][0]);
}