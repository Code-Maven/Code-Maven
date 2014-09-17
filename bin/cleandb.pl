use strict;
use warnings;

use lib 'lib';

use Code::Maven::DB;

my $db = Code::Maven::DB->new( dbname => 'foo' );
$db->clean_collection;

