use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

use lib 'lib';
use Code::Maven::Config;
use Code::Maven::Source;

my %cfg = ( root => dirname( dirname( abs_path($0) ) ), );
GetOptions( \%cfg, 'help', 'root=s', 'source=s', 'fetch', 'zip' ) or die;
pod2usage() if delete $cfg{help};
pod2usage() if not $cfg{source};

Code::Maven::Config->initialize( root => delete $cfg{root} );
Code::Maven::Source->new(%cfg)->run;

=head1 SYNOPSIS

  --root path/to/root  (defaults to relative path)

  --source [cpan|pypi|pear|gems]      required

           One or more of the actions are required:
  --fetch
  --zip

=cut
