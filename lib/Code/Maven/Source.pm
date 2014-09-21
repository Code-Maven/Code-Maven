package Code::Maven::Source;
use strict;
use warnings;

my %sources = (
	cpan => 'Code::Maven::MetaCPAN',
	pypi => 'Code::Maven::PyPi',
	pear => 'Code::Maven::Pear',
);

sub sources {
	return keys %sources;
}

sub new {
	my ( $class, $source ) = @_;
	die if not $source or not $sources{$source};

	## no critic
	eval "use $sources{$source}";
	die $@ if $@;
	## use critic
	return $sources{$source}->new;
}

1;

