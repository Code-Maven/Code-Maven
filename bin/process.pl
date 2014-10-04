use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Getopt::Long qw(GetOptions);

use lib 'lib';
use Code::Maven::Config;
use Code::Maven::Source;

my %cfg = (
	root => dirname( dirname( abs_path($0) ) ),
);
GetOptions( \%cfg, 'root=s', 'source=s' ) or die;
my $sources = join '|', sort( Code::Maven::Source::sources() );
die "--source $sources    is required\n" if not $cfg{source};

Code::Maven::Config->initialize( root => delete $cfg{root} );
Code::Maven::Source->new(%cfg)->run;
