use strict;
use warnings;

use Test::More tests => 2;
use Capture::Tiny qw(capture);

my ( $stdout, $stderr, $exit ) = capture { system qq{$^X bin/metacpan.pl}; };
is $stdout,   '';
like $stderr, qr/DIST:/;
