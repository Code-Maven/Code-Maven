use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Code::Maven::Web;

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

test_psgi $app, sub {
	my $cb  = shift;
	my $res = $cb->( GET '/blog' );
	like(
		$res->content,
		qr{<title>Code::Maven - analyzing and displaying source code</title>},
		'/blog'
	);
	like( $res->content, qr{<h1>Code::Maven blog</h1>}, 'Page title' );
};

done_testing;

