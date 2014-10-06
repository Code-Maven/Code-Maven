use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Getopt::Long qw(GetOptions);

use lib 'lib';
use Code::Maven::Config;
use Code::Maven::DB;

my $root = dirname( dirname( abs_path($0) ) );
my $name;
my $all;
GetOptions( 'root=s' => \$root, 'name=s' => \$name, 'all' => \$all ) or die;

Code::Maven::Config->initialize( root => $root );
my $db = Code::Maven::DB->new;
if ($name) {
	$db->clean_collection($name);
} elsif ($all) {
	$db->get_db->drop;
} else {
	die "Missing --name COLLECTION_NAME or --all\n";
}

