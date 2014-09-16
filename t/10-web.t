
use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Code::Maven::Web;

# Pretend to have a version number while still in development
$Dancer::VERSION //= 0;

my $app = Code::Maven::Web->run;
is( ref $app, 'CODE', 'Got app' );

test_psgi $app, sub {
	my $cb = shift;
	like(
		$cb->( GET '/' )->content,
		qr{<title>Code::Maven - analyzing and displaying source code</title>},
		'root route'
	);
};

test_psgi $app, sub {
	my $cb  = shift;
	my $res = $cb->( GET '/abc' );

	#diag explain $res;
	is $res->code, 404;
	is( $res->content, '404 Not Found', 'invalid route' );
};

done_testing;

