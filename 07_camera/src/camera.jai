Camera :: struct {
	FLY_SPEED :: 1.0;
	ROTATION_SPEED :: 0.3;
	ROTATION_SMOOTHING :: 0.3;

	position : Vector3;
	euler_angles : Vector3;
	rotation : Quaternion;
	rotation_input : Vector2;
	fov := 60.0;
	transform := Matrix4_Identity;
	view_matrix := Matrix4_Identity;
	projection_matrix := Matrix4_Identity;
}

update_flying_camera :: (using camera : *Camera) {
	move_input  : Vector3;

    move_input.x += cast (float) key_pressed(SDL_SCANCODE_D) - cast (float) key_pressed(SDL_SCANCODE_A);
    move_input.y += cast (float) key_pressed(SDL_SCANCODE_E) - cast (float) key_pressed(SDL_SCANCODE_Q);
    move_input.z += cast (float) key_pressed(SDL_SCANCODE_S) - cast (float) key_pressed(SDL_SCANCODE_W);

    move_input = rotate(unit_vector(move_input), rotation);

	position += move_input * camera_speed * delta;

	mouse_delta : Vector2;
    mouse_delta = xy (xx mouse_x, xx mouse_y);
	rotation_input = lerp (rotation_input, mouse_delta, ROTATION_SMOOTHING);
	rotation_delta := rotation_input * ROTATION_SPEED;
	euler_angles.x += rotation_delta.x * PI / 180.0;
	euler_angles.y += rotation_delta.y * PI / 180.0;
	euler_angles.y = clamp (euler_angles.y, -80.0  * PI / 180.0, 80.0 * PI / 180.0);
	yaw : Quaternion;
	// I am not sure why I need to invert the axis of rotation...
	set_from_axis_and_angle (*yaw, 0, -1, 0, euler_angles.x);
	pitch : Quaternion;
	set_from_axis_and_angle (*pitch, -1, 0, 0, euler_angles.y);
	rotation = yaw * pitch;

	transform = make_translation_matrix4(position) * rotation_matrix(Matrix4, rotation);
	view_matrix = inverse (transform);
	projection_matrix = make_projection_matrix(radians(fov), window_width / cast (float) window_height, 0.1, 1000.0);;
}
