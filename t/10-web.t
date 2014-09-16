
use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Code::Maven::Web;

# Pretend to have a version number while still in development
$Dancer::VERSION //= 0;

my $app = sub { Code::Maven::Web->run };
is( ref $app, 'CODE', 'Got app' );

test_psgi $app, sub {
	my $cb = shift;
	like(
		$cb->( GET '/' )->content,
		qr{<title>Code::Maven - analyzing and displaying source code</title>},
		'root route'
	);
};

done_testing;

