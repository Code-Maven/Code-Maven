use strict;
use warnings;

use Test::More tests => 1;

my $out = qx{$^X bin/metacpan.pl};
is $out, '';
