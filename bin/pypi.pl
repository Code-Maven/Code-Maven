use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Getopt::Long qw(GetOptions);
use Log::Log4perl        ();
use Log::Log4perl::Level ();

use lib 'lib';
use Code::Maven::Config;
use Code::Maven::PyPi;

my $root = dirname( dirname( abs_path($0) ) );
GetOptions( 'root=s' => \$root ) or die;

Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority('DEBUG') );
Code::Maven::Config->initialize( root => $root );
Code::Maven::PyPi->new->get_recent;

