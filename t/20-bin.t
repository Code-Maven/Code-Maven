use strict;
use warnings;

use Test::More tests => 1 + 5 * 2 + 4 * 2;
use Capture::Tiny qw(capture);

use Code::Maven::Source;
is scalar Code::Maven::Source::sources(), 4, 'number of sources';

foreach my $src ( Code::Maven::Source::sources(), 'events' ) {
	my ( $stdout, $stderr, $exit )
		= capture { system qq{$^X bin/cleandb.pl --root t/files --name $src}; };
	is $stdout, '', "cleandb stdout $src";
	is $stderr, '', "cleandb stderr $src";
}

diag "We are going to access various web sites. This might take a while";
foreach my $src ( Code::Maven::Source::sources() ) {
	my ( $stdout, $stderr, $exit ) = capture {
		system qq{$^X bin/process.pl --root t/files --source $src};
	};
	is $stdout, '', "stdout $src";
	is $stderr, '', "stderr $src";
}

