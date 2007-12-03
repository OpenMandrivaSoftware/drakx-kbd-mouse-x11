use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'main',
    'MAKEFILE'  => 'Makefile_c',
    'OPTIMIZE'  => '-Os',
    'VERSION_FROM' => 'main.pm', # finds $VERSION
    'LIBS'	=> ["-lX11 -lXext -lXxf86misc"],
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
);
