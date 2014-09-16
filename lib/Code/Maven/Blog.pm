package Code::Maven::Blog;
use Moose;
use Path::Tiny qw(path);

has dir => ( is => 'ro', required => 1 );
has posts => ( is => 'rw' );

sub collect {
	my ($self) = @_;

	my @posts;

	my $dir   = $self->dir;
	my @files = glob "$dir/*.txt";
	foreach my $f (@files) {
		my @lines = path($f)->lines_utf8;
		my %post = ( content => '' );
		for my $line (@lines) {
			if ( $line =~ /^=(\w+)\s+(.*?)\s*$/ ) {
				$post{$1} = $2;
				next;
			}
			$post{content} .= $line;
		}
		push @posts, \%post;
	}
	$self->posts( \@posts );
	return scalar @posts;
}

1;

