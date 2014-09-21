use strict;
use warnings;

use Test::More tests => 1 + 5 * 2 + 4 * 2 + 1;
use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Code::Maven::Source;
use Code::Maven::Config;
use Code::Maven::DB;

diag "We are going to access various web sites. This might take a while";
is scalar Code::Maven::Source::sources(), 4, 'number of sources';

foreach my $name ( Code::Maven::Source::sources(), 'events' ) {
	my ( $stdout, $stderr, $exit )
		= capture { system qq{$^X bin/cleandb.pl --root t/files --name $name}; };
	is $stdout, '', "cleandb stdout $name";
	is $stderr, '', "cleandb stderr $name";
}

foreach my $name ( Code::Maven::Source::sources() ) {
	my ( $stdout, $stderr, $exit ) = capture {
		system qq{$^X bin/process.pl --root t/files --source $name};
	};
	is $stdout, '', "stdout $name";
	is $stderr, '', "stderr $name";
}

# TODO check if the database has now data in it as expected!
my $cfg = Code::Maven::Config->initialize( root => 't/files' );
$cfg->root( dirname( dirname( abs_path($0) ) ) );
my $db = Code::Maven::DB->new;

subtest real => sub {
	foreach my $name ( Code::Maven::Source::sources(), 'events' ) {
		$db->clean_collection($name);
	}
	foreach my $name ( Code::Maven::Source::sources() ) {
		Code::Maven::Source->new($name)->run;
	}
	diag $db->get_collection('events')->find->count;
	ok 1;
};

