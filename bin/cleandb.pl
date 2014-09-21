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
GetOptions( 'root=s' => \$root, 'name=s' => \$name ) or die;
die "Missing --name COLLECTION_NAME\n" if not $name;

Code::Maven::Config->initialize( root => $root );
my $db = Code::Maven::DB->new;
$db->clean_collection($name);

