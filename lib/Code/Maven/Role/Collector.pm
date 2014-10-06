package Code::Maven::Role::Collector;
use Moose::Role;

use Carp;
use Archive::Any;

has fetch => ( is => 'ro' );
has zip   => ( is => 'ro' );

has source       => ( is => 'rw' );
has distribution => ( is => 'rw' );
has version      => ( is => 'rw' );

use Code::Maven::DB;

sub run {
	my ($self) = @_;

	die "None of the actions (fetch, zip) were given.\nRun $0 --help\n"
		if not $self->fetch and not $self->zip;

	$self->get_recent        if $self->fetch;
	$self->download_zipfiles if $self->zip;
}

sub add_event {
	my ( $self, $data ) = @_;

	$data->{distribution} = $self->distribution;
	$data->{version}      = $self->version;
	$data->{source}       = $self->source;
	my $db  = Code::Maven::DB->new;
	my $col = $db->get_eventlog;
	$col->insert($data);

	return;
}

sub unzip {
	my ( $self, $zip_file, ) = @_;

	if ( $zip_file !~ m/\.(tar\.bz2|tar\.gz|tgz|zip)$/ ) {
		return ('invalid_extension');
	}

	my $archive;
	eval {
		local $SIG{__WARN__} = sub { die shift };
		$archive = Archive::Any->new($zip_file);
		die 'Could not unzip' if not $archive;
		1;
	} or do {
		my $err = $@ // 'Unknown error';
		return ( 'exception', $err );
	};

	my $is_naughty;
	eval { $is_naughty = $archive->is_naughty; };
	if ($is_naughty) {
		return ('naughty_archive');
	}

	my $dir = 'temp';
	eval {
		if ( $archive->is_impolite ) {
			mkdir $dir;
			$archive->extract($dir);
		}
		else {
			$archive->extract();
		}
		1;
	} or do {
		my $err = $@;
		return ( 'exception', $err );
	};

	# TODO check if this was really successful?
	# TODO check what were the permission bits
	#_chmod('.');

	opendir my ($dh), '.';
	my @content = eval {
		map { _untaint_path($_) }
		grep { $_ ne '.' and $_ ne '..' } readdir $dh;
		1;
	} or do {
		my $err = $@;
		return ( 'tainted_directory', $err );
	};

	return;
}

sub _untaint_path {
	my $p = shift;

	if ( $p =~ m{^([\w/:\\.-]+)$}x ) {
		$p = $1;
	}
	else {
		Carp::confess("Untaint failed for '$p'\n");
	}
	if ( index( $p, '..' ) > -1 ) {
		Carp::confess("Found .. in '$p'\n");
	}
	return $p;
}

sub _chmod {
	my $dir = shift;
	opendir my ($dh), $dir;
	my @content = eval {
		map { _untaint_path($_) }
		grep { $_ ne '.' and $_ ne '..' } readdir $dh;
	};
	if ($@) {
		say("Could not untaint: $@");
	}
	foreach my $thing (@content) {
		my $path = File::Spec->catfile( $dir, $thing );
		if ( -l $path ) {
			say("Symlink found '$path'");
			unlink $path;
		}
		elsif ( -d $path ) {
			chmod 0755, $path;
			_chmod($path);
		}
		elsif ( -f $path ) {
			chmod 0644, $path;
		}
		else {
			say("Unknown thing '$path'");
		}
	}
	return;
}

1;

