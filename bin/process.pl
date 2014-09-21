use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Getopt::Long qw(GetOptions);

use lib 'lib';
use Code::Maven::Config;
use Code::Maven::Source;

my $root = dirname( dirname( abs_path($0) ) );
my $source;
GetOptions( 'root=s' => \$root, 'source=s' => \$source ) or die;
my $sources = join '|', sort( Code::Maven::Source::sources() );
die "--source $sources    is required\n" if not $source;

Code::Maven::Config->initialize( root => $root );
Code::Maven::Source->new($source)->run;
