package Apache::Info;

use strict;
use mod_perl 1.08;
use Apache::Constants qw(:server OK);
use Apache::Globals ();
use Apache::Module ();
use HTML::Entities ();

my %phases = (
    config_methods => "Configuration Phase Participation",
    request_methods => "Request Phase Participation",
);

sub splain {
    my($desc, $thing, $s) = @_;
    print <<EOF;
<strong>$desc:</strong>
<font size=+$s><tt>$thing</tt></a></font><br>
EOF
}

sub splain_list {
    my(@list) = @_;
    print @list > 0 ?
	join(", ", map "<tt>$_</tt>", @list):
	    "<tt> <em>none</em></tt>";
    print "<br>";
}

sub handler {
    my $r = shift;
    my $g = Apache::Globals->new;
    my $srv = $r->server;
    my $top_module = Apache::Module->top_module;
    my $nb = "&nbsp;&nbsp;";

    $r->send_http_header("text/html");

    print <<EOF;
<html>
<head><title>Server Information</title></head>
<body>
<h1 align=center>Apache Server Information</h1>
<hr>
<tt><a href="#server">Server Settings</a>, 
EOF
    for (my $modp = $top_module; $modp; $modp = $modp->next) {
	my $name = $modp->name;
	print qq(<a href="#$name">$name</a>);
	print ", " if $modp->next;
    }

    print "</tt><hr><a name=server>";
    splain "Server Version</a>", SERVER_VERSION, 1;
    splain "Server Built",       SERVER_BUILT, 1;
    splain "API Version",        MODULE_MAGIC_NUMBER;

    splain "Run Mode", $g->standalone ? "standalone" : "inetd";

    splain "User/Group",
       sprintf "%s(%d)/%d", $g->user_name, $g->user_id, $g->group_id;

    splain "Hostname/port",
       join ":", $srv->server_hostname, $srv->port;

    splain "Daemons",
       sprintf "start: %d $nb min idle: %d $nb max idle: %d $nb max: %d", 
       $g->daemons_to_start, $g->daemons_min_free,
       $g->daemons_max_free, $g->daemons_limit;
    
    splain "Max Requests",
       sprintf "per child: %d $nb keep alive: %s $nb max per connection: %d",
       $g->max_requests_per_child,
       $srv->keep_alive ? "on" : "off",
       $srv->keep_alive_max;

    splain "Threads",         "per child ".$g->threads_per_child;
    splain "Excess Requests", "per child ".$g->excess_requests_per_child;

    splain "Timeouts",
       sprintf "connection: %d $nb keep-alive: %d",
       $srv->timeout, $srv->keep_alive_timeout;

    splain "Server Root",     $g->server_root;
    splain "Config File",     $g->server_confname;
    splain "PID File",        $g->pid_fname;
    splain "Scoreboard File", $g->scoreboard_fname;

    for (my $modp = $top_module; $modp; $modp = $modp->next) {
	print "<hr>";
	my $name = $modp->name;
	print <<EOF;
<dt><a name="$name"><strong>Module Name:</strong></a>
<font size=+1><tt>$name</tt></font><br>
<dt><strong>Content handlers:</strong>
EOF
        splain_list $modp->content_handlers;

	for my $phase (sort keys %phases) {
	    my @list = ();
	    print "<strong>$phases{$phase}: </strong>";

	    for my $method ($modp->$phase()) {
		push @list, $modp->method_desc($method) if $modp->$method();
	    }
	    splain_list @list;
	}

	print "<dt><strong>Module Directives</strong>: ";

	for (my $cmd = $modp->cmds; $cmd; $cmd = $cmd->next) {
	     my($name, $msg) = 
		 (HTML::Entities::encode($cmd->name), $cmd->errmsg);
	     print "<dd><tt>$name - <i>$msg</i></tt>\n";
	 }

	print splain_list unless $modp->cmds;
    }
    print "</body></html>";

    return OK;
}

1;

__END__

=head1 NAME

Apache::Info - Perl version of mod_info

=head1 SYNOPSIS

 <Location /server-info>
 PerlHandler Apache::Info
 SetHandler perl-script
 </Location>

=head1 DESCRIPTION

This module is meant as an example for using the B<Apache::Module> and
B<Apache::Globals> modules.

=head1 AUTHOR

Doug MacEachern

=head1 SEE ALSO 

Apache::Module(3), Apache::Globals(3), Apache(3), mod_perl(3)

