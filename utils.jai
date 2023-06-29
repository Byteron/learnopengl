copy_directory :: (source : string, dest : string) {
	names : [2]string;
	names[0] = source;
	names[1] = dest;

	visitor :: (info : *File_Visit_Info, names : [2]string) {
		dest_name := advance(info.full_name, names[0].count);
		dest_name = join (names[1], dest_name);
		if info.is_directory
			make_directory_if_it_does_not_exist (dest_name);
		else
			copy_file (info.full_name, dest_name);
	}

	make_directory_if_it_does_not_exist (dest);
	visit_files (source, true, names, visitor, visit_directories = true);
}