use ExtUtils::MakeMaker;

use strict;
use 5.004_04;
use IO::File ();
use Apache::src ();

handlers2xsubs("handlers.xsubs");

WriteMakefile(
    'NAME'	=> 'Apache::Module',
    'VERSION' => '0.01', 
    'INC'       => Apache::src->new->inc,	      
    'dist'    => {
	COMPRESS=> 'gzip -9f', SUFFIX=>'gz',
	CI => qq(ci -u -m\\"See Changes file\\"),
        PREOP => 'co -l README && pod2text Module.pm > README && ci -u README',
    },
);

my %not_imp;
BEGIN {
%not_imp = map {$_,1} qw{
 child_init
 child_exit
 init
 create_dir_config
 merge_dir_config
 create_server_config
 merge_server_config
};
}
sub handlers2xsubs {
    my $file = shift;
    require './Module.pm';
    my $fh = IO::File->new(">$file") or 
	die "can't open $file $!";

    for my $handler (Apache::Module->methods) {
	my($type, $trans);
	if ($not_imp{$handler}) {
	    $type = "int";
	    $trans = "member_boolean";
	}
	else {
	    $type = "SV *";
	    $trans = "handler2cvrv";
	}

	print $fh <<EOF;
$type
$handler(modp)
    Apache::Module modp

    CODE:
    $trans(modp->$handler);

    OUTPUT:
    RETVAL

EOF
     }
}
