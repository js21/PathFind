#!/usr/bin/env perl
use Moose;
use Data::Dumper;
use File::Slurp;
use File::Path qw( remove_tree);
use Cwd;
use File::Temp;
no warnings qw{qw};

sub run_object {
	my $ro = shift;
	$ro->run;
}

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
	use Test::Output;
}

use_ok('Path::Find::CommandLine::Path');

my $script_name = 'pathfind';
my $cwd = getcwd();

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my (@args, $arg_str, $exp_out, $path_obj);

# test basic output
@args = qw(-t lane -i 10071_7#53);
$exp_out = "/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines/Mycobacterium/abscessus/TRACKING/2047/2047STDY5531443/SLX/7458518/10071_7#53\n";

$path_obj = Path::Find::CommandLine::Path->new(args => \@args, script_name => $script_name);
$arg_str = join(" ", @args);
stdout_is { $path_obj->run } $exp_out, "Correct results for '$arg_str'";

# test file type & file parse
@args = qw(-t file -i t/data/path_lanes.txt -f fastq);
$exp_out = "/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines/Streptococcus/pneumoniae/TRACKING/664/M01_0087/SLX/M01_0087_1373899/5477_6#7/5477_6#7_1.fastq.gz
/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines/Streptococcus/pneumoniae/TRACKING/664/M01_0087/SLX/M01_0087_1373899/5477_6#7/5477_6#7_2.fastq.gz
/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines/Shigella/flexneri/TRACKING/1817/MS0020/SLX/MS0020_2882317/6578_4#8/6578_4#8_1.fastq.gz
/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines/Shigella/flexneri/TRACKING/1817/MS0020/SLX/MS0020_2882317/6578_4#8/6578_4#8_2.fastq.gz
/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines/Streptococcus/pneumoniae/TRACKING/1714/SMRU587/SLX/SMRU587_3100065/6730_1#11/6730_1#11_1.fastq.gz
/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines/Streptococcus/pneumoniae/TRACKING/1714/SMRU587/SLX/SMRU587_3100065/6730_1#11/6730_1#11_2.fastq.gz\n";

$path_obj = Path::Find::CommandLine::Path->new(args => \@args, script_name => $script_name);
$arg_str = join(" ", @args);
stdout_is { $path_obj->run } $exp_out, "Correct results for '$arg_str'";

# test symlink
@args = ("-t", "study", "-i", "310", "-l", "$destination_directory/symlink_test");
$exp_out = "/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines/Citrobacter/rodentium_EX_33/TRACKING/310/EX33/SLX/EX33_1/3996_1
/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines/Citrobacter/rodentium/TRACKING/310/TL124/SLX/TL124_1/3996_2\n";

$path_obj = Path::Find::CommandLine::Path->new(args => \@args, script_name => $script_name);
$arg_str = join(" ", @args);
stdout_is { $path_obj->run } $exp_out, "Correct results for '$arg_str'";
ok( -d "$destination_directory/symlink_test", 'symlink directory exists' );
ok( -e "$destination_directory/symlink_test/3996_1_1.fastq.gz", 'symlink exists');
ok( -e "$destination_directory/symlink_test/3996_1_2.fastq.gz", 'symlink exists');
ok( -e "$destination_directory/symlink_test/3996_2_1.fastq.gz", 'symlink exists');
ok( -e "$destination_directory/symlink_test/3996_2_2.fastq.gz", 'symlink exists');
remove_tree("$destination_directory/symlink_test");

# test archive
@args = ("-t", "study", "-i", "2460", "-a", "$destination_directory/archive_test");
$exp_out = "/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines/Burkholderia/pseudomallei/TRACKING/2460/BP1_bc/SLX/BP1_bc_6310549/9003_1#1
/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines/Burkholderia/pseudomallei/TRACKING/2460/BP2_ab/SLX/BP2_ab_6310550/9003_1#2\n";

$path_obj = Path::Find::CommandLine::Path->new(args => \@args, script_name => $script_name);
$arg_str = join(" ", @args);
stdout_is { $path_obj->run } $exp_out, "Correct results for '$arg_str'";

ok( -e "$destination_directory/archive_test.tar.gz", 'archive exists');
system("cd $destination_directory; tar xvfz archive_test.tar.gz");
ok( -d "$destination_directory/archive_test", 'decompressed archive directory exists' );
ok( -e "$destination_directory/archive_test/9003_1#1_1.fastq.gz", 'archived file exists');
ok( -e "$destination_directory/archive_test/9003_1#1_2.fastq.gz", 'archived file exists');
ok( -e "$destination_directory/archive_test/9003_1#2_1.fastq.gz", 'archived file exists');
ok( -e "$destination_directory/archive_test/9003_1#2_2.fastq.gz", 'archived file exists');
remove_tree("$destination_directory/archive_test");
unlink("$destination_directory/archive_test.tar.gz");

# test stats file
@args = ("-t", "file", "-i", "t/data/path_lanes.txt", "-s", "$destination_directory/pathfind_test.stats");
$path_obj = Path::Find::CommandLine::Path->new(args => \@args, script_name => $script_name);
$path_obj->run;
ok( -e "$destination_directory/pathfind_test.stats", 'stats file exists');
is(
	read_file("$destination_directory/pathfind_test.stats"),
	read_file("t/data/pathfind_stats.exp"),
	'stats are correct'
);

done_testing();