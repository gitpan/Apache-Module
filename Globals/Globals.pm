package Apache::Globals;

use strict;
use vars qw($VERSION @ISA);

use DynaLoader ();

@ISA = qw(DynaLoader);

$VERSION = '0.01';

bootstrap Apache::Globals $VERSION;

sub new { bless {}, shift }

1;

__END__


=head1 NAME

Apache::Globals - Perl interface to Apache global variables

=head1 SYNOPSIS

  use Apache::Globals ();
  my $g = Apache::Globals->new;

=head1 DESCRIPTION

Check out Apache::Info for examples.

=head1 AUTHOR

Doug MacEachern

=head1 SEE ALSO

Apache::Info(3), Apache::Module(3), Apache(3), mod_perl(3).

=cut
