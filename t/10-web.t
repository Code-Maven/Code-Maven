use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET);
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Code::Maven::Config;
use Code::Maven::Web;

my $cfg = Code::Maven::Config->initialize( root => 't/files' );
$cfg->root( dirname( dirname( abs_path($0) ) ) );

my $app = Code::Maven::Web->run;
is( ref $app, 'CODE', 'Got app' );

test_psgi $app, sub {
	my $cb = shift;
	like(
		$cb->( GET '/' )->content,
		qr{<title>Analyzing and displaying source code</title>},
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
	like( $res->content, qr{<title>Code::Maven blog</title>},  '/blog' );
	like( $res->content, qr{<h1[^>]*>Code::Maven blog.*</h1>}, 'Page title' );
};

test_psgi $app, sub {
	my $cb  = shift;
	my $res = $cb->( GET '/blog/getting-started' );
	like( $res->content, qr{<title>Getting Started</title>},
		'/blog/getting-starter' );
	like( $res->content, qr{<h1[^>]*>Getting Started</h1>}, 'Page title' );
};

test_psgi $app, sub {
	my $cb  = shift;
	my $res = $cb->( GET '/robots.txt' );
	is( $res->content, '', '/robots.txt' );
};

test_psgi $app, sub {
	my $cb = shift;
	like( $cb->( GET '/plans' )->content,
		qr{<title>Plans</title>}, 'root route' );
};

done_testing;

