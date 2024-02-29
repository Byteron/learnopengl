
key_pressed :: (code: SDL_Scancode) -> bool {
	return KEYS_PRESSED[code];
}

key_up :: (code: SDL_Scancode) -> bool {
	return KEYS_UP[code];
}

key_down :: (code: SDL_Scancode) -> bool {
	return KEYS_DOWN[code];
}

press_key :: (code: SDL_Scancode) {
    KEYS_DOWN[code] = true;
	KEYS_PRESSED[code] = true;
}

release_key :: (code: SDL_Scancode) {
    KEYS_DOWN[code] = true;
	KEYS_PRESSED[code] = false;
}

reset_keys :: () {
    for KEYS_DOWN it = false;
    for KEYS_UP it = false;
}

#scope_file

KEYS_PRESSED: [512]bool;
KEYS_DOWN: [512]bool;
KEYS_UP: [512]bool;