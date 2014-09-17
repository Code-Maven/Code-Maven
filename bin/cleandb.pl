use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);

use lib 'lib';
use Code::Maven::DB;

Code::Maven::Config->initialize( root => dirname( abs_path($0) ) );
my $db = Code::Maven::DB->new( dbname => 'foo' );
$db->clean_collection;

