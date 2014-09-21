use strict;
use warnings;

use Test::More tests => 6;
use Capture::Tiny qw(capture);

{
	my ( $stdout, $stderr, $exit )
		= capture { system qq{$^X bin/cleandb.pl --root t/files}; };
	is $stdout, '';
	is $stderr, '';
}

{
	my ( $stdout, $stderr, $exit )
		= capture { system qq{$^X bin/cpan.pl --root t/files}; };
	is $stdout,   '';
	like $stderr, qr/DIST:/;
}

{
	my ( $stdout, $stderr, $exit )
		= capture { system qq{$^X bin/pypi.pl --root t/files}; };
	is $stdout, '';
	is $stderr, '';
}

