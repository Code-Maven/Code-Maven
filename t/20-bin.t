use strict;
use warnings;

use Test::More tests => 6;
use Capture::Tiny qw(capture);

{
	my ( $stdout, $stderr, $exit )
		= capture { system qq{$^X bin/cleandb.pl --root t/files --name cpan}; };
	is $stdout, '';
	is $stderr, '';
}

{
	my ( $stdout, $stderr, $exit ) = capture {
		system qq{$^X bin/process.pl --root t/files --source cpan};
	};
	is $stdout, '';
	is $stderr, '';
}

{
	my ( $stdout, $stderr, $exit ) = capture {
		system qq{$^X bin/process.pl --root t/files --source pypi};
	};
	is $stdout, '';
	is $stderr, '';
}

