#run {
	#import "Compiler";

	copy_directory("../data/", "bin/");

	set_build_options_dc(.{
		output_path="bin/",
		output_executable_name="LOGL"
	});
}

#import "File";
#import "File_Utilities";
#import "String";

#load "src/main.jai";