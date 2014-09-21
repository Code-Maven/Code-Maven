package Code::Maven::Source;
use strict;
use warnings;

my %sources = (
	cpan => 'Code::Maven::MetaCPAN',
	pypi => 'Code::Maven::PyPi',
);

sub new {
	my ($class, $source) = @_;
	die if not $source or not $sources{$source};

	eval "use $sources{$source}";
	return $sources{$source}->new;
}


1;

