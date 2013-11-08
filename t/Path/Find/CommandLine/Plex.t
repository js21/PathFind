#!/usr/bin/env perl
use Moose;
use Cwd;
use File::Temp;

sub run_object {
	my $ro = shift;
	$ro->run;
}

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most tests => 3;
	use Test::Output;
}

use_ok('Path::Find::CommandLine::Plex');

my $script_name = 'Path::Find::CommandLine::Plex';
my $cwd = getcwd();

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my (@args, $arg_str, $exp_out, $plex_obj);

# test basic output
@args = qw(-t lane -i 11233_1);
$exp_out = "C2_Bp, 11233_1, 28, pass, not defined\n
D50_Bt, 11233_1, 29, pass, not defined\n
Gabon_Bp, 11233_1, 30, pass, not defined\n";

$plex_obj = Path::Find::CommandLine::Plex->new(args => \@args, script_name => $script_name);
$arg_str = join(" ", @args);
stdout_is(\&run_object($plex_obj), $exp_out, "Correct results for '$arg_str'");

# test file parse and file type
@args = qw(-t study -i 1707);
$exp_out = "46082A21, 5749_8, 5, pass, passed\n
46082E21, 5749_8, 6, pass, passed\n
straina, 5749_8, 4, pass, passed\n
2950, 5749_8, 2, pass, passed\n
TL266, 5749_8, 1, pass, passed\n
3507, 5749_8, 3, pass, passed\n";

$plex_obj = Path::Find::CommandLine::Plex->new(args => \@args, script_name => $script_name);
$arg_str = join(" ", @args);
stdout_is(\&run_object($plex_obj), $exp_out, "Correct results for '$arg_str'");

done_testing();