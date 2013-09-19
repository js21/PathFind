package Path::Find::Linker;

# ABSTRACT:

=head1 SYNOPSIS

Logic to create symlinks or archives for a list of lanes

   use Path::Find::Linker;
   my $obj = Path::Find::Linker->new(
     lanes => \@lanes,
     name => <symlink_destination|archive_name>,
	 use_default_type => <1|0>
   );
   
   $obj->sym_links;
   $obj->archive;

use_default_type option should be switched on when a filetype has not been
specified by the user.
   
=method create_links

Creates symlinks to each given lane in the defined destination directory

=method _check_destination

Checks whether the defined destination exists. If not, it creates the
directory.

=cut

use Moose;
use File::Temp;
use Cwd;

has 'lanes' => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has '_tmp_dir' => ( is => 'rw', isa => 'Str', builder  => '_build__tmp_dir' );
has 'name'     => ( is => 'ro', isa => 'Str', required => 1 );
has '_checked_name' =>
  ( is => 'rw', isa => 'Str', lazy => 1, builder => '_build__checked_name' );
has 'destination' =>
  ( is => 'ro', isa => 'Str', required => 0, writer => '_set_destination' );
has '_default_type' => (is => 'ro', isa => 'Str', required => 0, lazy => 1, builder => '_build__default_type');
has 'use_default_type' => (is => 'ro', isa => 'Bool', required => 1);

sub _build__checked_name {
    my ($self) = @_;
    my $name = $self->name;
    $name =~ s/\s+/_/;
    return $name;
}

sub _build__tmp_dir {
    my $tmp_dir_obj = File::Temp->newdir( CLEANUP => 0 );
    return $tmp_dir_obj->dirname;
}

sub _build__default_type {
    my ($self) = @_;
    my %default_ft = (
        pathfind       => '/*.fastq.gz',
        assemblyfind   => 'contigs',
        annotationfind => 'gff',
        mapfind        => 'bam',
        snpfind        => 'vcf',
        rnaseqfind     => 'spreadsheet',
        tradisfind     => 'spreadsheet',
    );

    #my $script = $self->scriptname;
	$0 =~ /([^\/]+$)/;
    return $default_ft{$1};
}

sub archive {
    my ($self) = @_;
    my @lanes = @{ $self->lanes };

    #set destination for symlinks
    my $tmp_dir = $self->_tmp_dir;
    $self->_set_destination("$tmp_dir");

    #create symlinks
    $self->_create_symlinks;

    #tar and move to CWD
    print "Archiving lanes:\n";
    $self->_tar;

    File::Temp::cleanup();
}

sub sym_links {
    my ($self) = @_;

    #set destination for symlinks
    my $current_cwd = getcwd;
    $self->_set_destination("$current_cwd");

    #create symlinks
    $self->_create_symlinks;
}

sub _create_symlinks {
    my ($self)      = @_;
    my @lanes       = @{ $self->lanes };
    my $destination = $self->destination;
    my $name        = $self->_checked_name;

    #check destination exists and create if not
    $self->_check_dest("$destination/$name");

	#set default filetype if not already specified
	my $default_type = "";
	$default_type = $self->_default_type if($self->use_default_type);

    #create symlink
    foreach my $lane (@lanes) {
        my $cmd = "ln -s $lane$default_type $destination/$name";
        system($cmd) == 0
          or die
"Could not create symlink for $lane in $destination/$name: error code $?\n";
    }
    return 1;
}

sub _check_dest {
    my ( $self, $destination ) = @_;

    if ( !-e $destination ) {
        system("mkdir $destination") == 0
          or die "Could not create $destination: error code $?\n";
    }
    return 1;
}

sub _tar {
    my ($self)   = @_;
    my $tmp_dir  = $self->_tmp_dir;
    my $arc_name = $self->_checked_name;
    my $error    = 0;

    my $current_cwd = getcwd;
    system("cd $tmp_dir; tar cvhfz archive.tar.gz $arc_name") == 0
      or $error = 1;

    if ($error) {
        print "An error occurred while creating the archive: $arc_name\n";
        print "No output written to $arc_name.tar.gz\n";
        File::Temp::cleanup();
        return 0;
    }
    else {
        system("mv $tmp_dir/archive.tar.gz $current_cwd/$arc_name.tar.gz") == 0
          or die
          "An error occurred while writing archive $arc_name: error code $?\n";
        File::Temp::cleanup();
        return $error;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;