package Code::Maven::Source;
use strict;
use warnings;

my %sources = (
	cpan => 'Code::Maven::MetaCPAN',
	pypi => 'Code::Maven::PyPi',
	pear => 'Code::Maven::Pear',
	gems => 'Code::Maven::RubyGems',
);

sub sources {
	return keys %sources;
}

sub new {
	my ( $class, %cfg ) = @_;
	my $source = delete $cfg{source};
	die if not $source or not $sources{$source};

	## no critic
	eval "use $sources{$source}";
	die $@ if $@;
	## use critic
	return $sources{$source}->new(%cfg);
}

1;

