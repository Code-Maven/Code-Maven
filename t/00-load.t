use strict;
use warnings;

use Test::More tests => 2;

use Code::Maven;
use Code::Maven::Config;

my $cm = Code::Maven->new;

isa_ok $cm, 'Code::Maven';

my $cfg = Code::Maven::Config->initialize( root => 't/files' );
is_deeply $cfg,
	{
	'root' => 't/files',
	'cfg'  => {
		'db' => {
			'dbname' => 'code-maven-test',
			'host'   => 'localhost',
			'port'   => '27017'
		}
	}
	},
	'cfg';

#diag explain $cfg;

