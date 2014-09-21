use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Getopt::Long qw(GetOptions);
use Log::Log4perl        ();
use Log::Log4perl::Level ();

use lib 'lib';
use Code::Maven::Config;
use Code::Maven::Source;

my $root = dirname( dirname( abs_path($0) ) );
my $source;
GetOptions( 'root=s' => \$root, 'source=s' => \$source ) or die;
die "--source cpan|pypi    is required\n" if not $source;

Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority('DEBUG') );
Code::Maven::Config->initialize( root => $root );
Code::Maven::Source->new($source)->run;
