use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use IO::File ();
use Apache::src ();

writexs("global.xsubs");

WriteMakefile(
    'NAME'	=> 'Apache::Globals',
    'VERSION_FROM' => 'Globals.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'       => Apache::src->new->inc,	
);


sub writexs {
    my $file = shift;
    my $fh = IO::File->new(">$file");
    for (split /\n/, $DATA) {
	next unless s/^extern\s+//;
	s/\s*;$//;
	my($type,$name) = split;
	if($name =~ s/^(\W)//) {
	    $type .= " $1";
	}
	   
	print $fh <<EOF;
$type
$name(self)
     SV *self

     CODE:
     RETVAL = $name;

     OUTPUT:
     RETVAL

EOF
    }
}

BEGIN {
    $DATA = <<EOF;
extern int standalone;
extern uid_t user_id;
extern char *user_name;
extern gid_t group_id;
extern int max_requests_per_child;
extern int threads_per_child;
extern int excess_requests_per_child;
extern int daemons_to_start;
extern int daemons_min_free;
extern int daemons_max_free;
extern int daemons_limit;
extern int suexec_enabled;
extern int listenbacklog;
extern char *pid_fname;
extern char *scoreboard_fname;
extern char *lock_fname;
extern char *server_root;
extern char *server_confname;
EOF
}
