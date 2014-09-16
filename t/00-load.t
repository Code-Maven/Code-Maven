use strict;
use warnings;

use Test::More tests => 2;

use Code::Maven;

ok 1;

my $cm = Code::Maven->new;

isa_ok $cm, 'Code::Maven';
