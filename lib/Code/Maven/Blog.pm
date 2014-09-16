package Code::Maven::Blog;
use Moose;
use Path::Tiny qw(path);

has dir => ( is => 'ro', required => 1 );

sub collect {
	my ($self) = @_;

	my $dir = $self->dir;
	die $dir;
	my @files = glob "$dir/*.txt";
	foreach my $f (@files) {
		path($f);
	}
}

1;

