package Code::Maven::Source;
use strict;
use warnings;

my %sources = (
	cpan => 'Code::Maven::Source::MetaCPAN',
	pypi => 'Code::Maven::Source::PyPi',
	pear => 'Code::Maven::Source::Pear',
	gems => 'Code::Maven::Source::RubyGems',
);

sub sources {
	return keys %sources;
}

sub new {
	my ( $class, %cfg ) = @_;
	my $source = delete $cfg{source};
	die "Source '$source' is not in the list of sources\n"
		if not $source
		or not $sources{$source};

	## no critic
	eval "use $sources{$source}";
	die $@ if $@;
	## use critic
	return $sources{$source}->new(%cfg);
}

1;

