package Apache::Module;

use strict;
use vars qw($VERSION @ISA);

use Apache::Constants ();
use DynaLoader ();

@ISA = qw(DynaLoader);

$VERSION = '0.02';

if($ENV{MOD_PERL}) {
    bootstrap Apache::Module $VERSION;
}

my(@override)    = qw(
		      OR_NONE
		      OR_LIMIT
		      OR_OPTIONS
		      OR_FILEINFO
		      OR_AUTHCFG
		      OR_INDEXES
		      OR_UNSET
		      OR_ALL
		      ACCESS_CONF
		      RSRC_CONF);

my(@args_how)    = qw(
		      RAW_ARGS
		      TAKE1
		      TAKE2
		      ITERATE
		      ITERATE2
		      FLAG
		      NO_ARGS
		      TAKE12
		      TAKE3
		      TAKE23
		      TAKE123);

$Apache::Constants::EXPORT_TAGS{args_how} = \@args_how;
$Apache::Constants::EXPORT_TAGS{override} = \@override;
push @Apache::Constants::EXPORT_OK, @args_how, @override;

sub find {
    my($self,$name) = @_;
    my $top_module = $self->top_module;

    for (my $modp = $top_module; $modp; $modp = $modp->next) {
	return $modp if $modp->name =~ /$name/;
    }
    
    return undef;
}

sub commands {
    my $modp = shift;
    my @retval = ();
    for (my $cmd = $modp->cmds; $cmd; $cmd = $cmd->next) {
	push @retval, $cmd->name;
    }
    \@retval;
}

sub content_handlers {
    my $modp = shift;
    my @handlers = ();
    for (my $hand = $modp->handlers; $hand; $hand = $hand->next) {
	push @handlers, $hand->content_type;
    }
    return @handlers;
}

my @request_methods = qw{
 post_read_request
 translate_handler
 header_parser
 access_checker
 check_user_id
 auth_checker
 type_checker
 fixer_upper
 logger
};

my %request_method_desc = (
 translate_handler => "Translate Path",
 post_read_request => "Post-Read Request",
 header_parser => "Header Parse",
 check_user_id => "Check Access",
 auth_checker => "Verify User ID",
 access_checker => "Verify User Access",
 type_checker => "Check Type",
 fixer_upper => "Fixups",
 logger => "Logging",
);

my @config_methods = qw{
 init
 child_init
 create_dir_config
 merge_dir_config
 create_server_config
 merge_server_config
 child_exit
};

my %config_method_desc = (
 child_init => "Child Init",
 child_exit => "Child Exit",
 init => "Module Init",
 create_dir_config => "Create Directory Config",
 merge_dir_config => "Merge Directory Configs",
 create_server_config => "Create Server Config",
 merge_server_config => "Merge Server Configs",
);

sub request_methods { @request_methods }
sub config_methods { @config_methods }
sub methods { @request_methods, @config_methods }
sub method_desc {
    my($self, $method) = @_;
    $request_method_desc{$method} || $config_method_desc{$method};
}

1;
__END__


=head1 NAME

Apache::Module - Interface to Apache C module structures

=head1 SYNOPSIS

  use Apache::Module ();

  #below is the same as
  #<IfModule mod_proxy>
  #...
  #</IfModule>

  if(Apache::Module->find("mod_proxy")) {
      ...;
  }

=head1 DESCRIPTION

This module provides an interface to the list of apache modules configured
with your httpd and their C<module *> structures.

=head1 METHODS

=over 4

=item top_module

This method returns a pointer the first module in Apache's internal list
of modules.

   Example:

   my $top_module = Apache::Module->top_module;

   print "Configured modules: \n";

   for (my $modp = $top_module; $modp; $modp = $modp->next) {
	print $modp->name, "\n";
   }

=item find($module_name)

This method returns a pointer to the module structure if found, under
otherwise.

  Example:

 for (qw(proxy perl include cgi)) {
     if(my $modp = Apache::Module->find($_)) {
	 print "$_ module is configured\n";
         print "with enabled commands: \n";

	 for (my $cmd = $modp->cmds; $cmd; $cmd = $cmd->next) {
	     print "   ", $cmd->name, "\n";
	 }
     }
     else {
	 print "$_ module is not configured\n";
     }
 }

=item handlers

Returns a pointer to the list of content types the module will handle.

Example:

    print "module ", $modp->name, " handles:\n";

    for (my $hand = $modp->handlers; $hand; $hand = $hand->next) {
	print $hand->content_type, "\n";
    }

=item Other Stuff

There's more you can do with this module, I will document it later.

=back

=head1 AUTHOR

Doug MacEachern

=head1 SEE ALSO

Apache::ModuleDoc(3), Apache::Info(3), Apache(3), mod_perl(3).

=cut
