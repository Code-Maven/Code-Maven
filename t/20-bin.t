use strict;
use warnings;

use Test::More tests => 4;
use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Code::Maven::Source;
use Code::Maven::Config;
use Code::Maven::DB;

my $cnt = 4;    # expected number of sources

diag 'We are going to access various web sites. This might take a while';
is scalar Code::Maven::Source::sources(), $cnt, 'number of sources';

my $cfg = Code::Maven::Config->initialize( root => 't/files' );
$cfg->root( dirname( dirname( abs_path($0) ) ) );
my $db = Code::Maven::DB->new;

subtest cleandb => sub {
	plan tests => ( $cnt + 1 ) * 3;
	foreach my $name ( Code::Maven::Source::sources(), 'events' ) {
		my ( $stdout, $stderr, $exit ) = capture {
			system qq{$^X bin/cleandb.pl --root t/files --name $name};
		};
		is $stdout, '', "cleandb stdout $name";
		is $stderr, '', "cleandb stderr $name";
	}
	foreach my $name ( Code::Maven::Source::sources(), 'events' ) {
		is $db->get_collection($name)->find->count, 0, "$name is empty";
	}
};

subtest process => sub {
	plan tests => $cnt * 2 + 1;
	foreach my $name ( Code::Maven::Source::sources() ) {
		my ( $stdout, $stderr, $exit ) = capture {
			system
				qq{$^X bin/process.pl --root t/files --source $name --fetch};
		};
		is $stdout, '', "stdout $name";
		is $stderr, '', "stderr $name";
	}

	# TODO check if the database has now data in it as expected!
	cmp_ok $db->get_collection('events')->find->count, '>', 100,
		'more than 100 events - just an arbitrary number here';
};

subtest real => sub {
	plan tests => 2;

	foreach my $name ( Code::Maven::Source::sources(), 'events' ) {
		$db->clean_collection($name);
	}
	is $db->get_collection('events')->find->count, 0, 'no events';
	foreach my $name ( Code::Maven::Source::sources() ) {
		Code::Maven::Source->new( source => $name, fetch => 1 )->run;
	}
	cmp_ok $db->get_collection('events')->find->count, '>', 100,
		'more than 100 events - just an arbitrary number here';
};

