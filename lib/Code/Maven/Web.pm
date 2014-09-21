package Code::Maven::Web;
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Cwd qw(abs_path);
use Carp ();
use File::Basename qw(dirname);
use Path::Tiny qw(path);
use Plack::Builder;
use Plack::Request;
use Template;

use Code::Maven::Blog;
use Code::Maven::DB;

my $root;
my $google_analytics = '';

my %ROUTING = (
	'/'            => \&serve_root,
	'/blog'        => \&serve_blog,
	'/plans'       => \&serve_plans,
	'/robots.txt'  => \&serve_robots,
	'/favicon.ico' => \&serve_favicon,
	'/cpan'        => sub { _serve_source('cpan') },
	'/pypi'        => sub { _serve_source('pypi') },
	'/events'      => \&serve_events,
);
my @ROUTING_REGEX = (
	{
		regex  => qr{^/blog/[^/]*$},
		handle => \&serve_blog_entry,
	},
	{
		regex  => qr{^/cpan/[^/]*$},
		handle => \&serve_cpan_distribution,
	},
);

sub run {
	my ($self) = @_;

	my $cfg = Code::Maven::Config->instance;
	$root = $cfg->root;

	my $app = sub {
		my $env = shift;

		my $request = Plack::Request->new($env);
		my $route   = $ROUTING{ $request->path_info };
		if ($route) {
			return $route->($env);
		}
		foreach my $route (@ROUTING_REGEX) {
			if ( $request->path_info =~ $route->{regex} ) {
				return $route->{handle}->($env);
			}
		}

		return serve_404();
	};

	builder {
		enable 'Plack::Middleware::Static',
			path => qr{^/(images|js|css|fonts)/},
			root => "$root/static/";
		$app;
	};
}

sub serve_events {
	my $db        = Code::Maven::DB->new;
	my $event_log = $db->get_eventlog;
	my $events = $event_log->find()->sort( { cm_update => -1 } )->limit(100);

	my @events;
	while ( my $e = $events->next ) {
		$e->{timestamp}
			= DateTime->from_epoch( epoch => $e->{_id}->get_time );

		push @events, $e;
	}
	return template(
		'events',
		{
			events => \@events,
		}
	);
}

sub serve_404 {
	[ '404', [ 'Content-Type' => 'text/html' ], ['404 Not Found'], ];
}

sub serve_root {
	return template('index');
}

sub serve_plans {
	return template('plans');
}

sub serve_blog {

	my $blog = Code::Maven::Blog->new( dir => $root . '/blog' );
	$blog->collect;
	my @posts
		= reverse sort { $a->{timestamp} cmp $b->{timestamp} }
		@{ $blog->posts };
	return template( 'blog', { posts => \@posts } );
}

sub serve_cpan_distribution {
	my ($env) = @_;

	my $request   = Plack::Request->new($env);
	my $path      = $request->path_info;
	my $dist_name = substr( $path, 6 );

	my $db   = Code::Maven::DB->new;
	my $col  = $db->get_collection('cpan');
	my $dist = $col->find_one( { 'metacpan.distribution' => $dist_name } );

	#die Dumper $dist;

	return template( 'cpan_distribution',
		{ title => "CPAN: $dist_name", distribution => $dist } );
}

sub serve_blog_entry {
	my ($env) = @_;

	my $request = Plack::Request->new($env);
	my $path    = $request->path_info;
	my $blog    = Code::Maven::Blog->new( dir => $root . '/blog' );
	my $post    = $blog->read_file( substr( $path, 5 ) );
	return template( 'blog_page',
		{ post => $post, title => $post->{title} } );
}

sub _serve_source {
	my ($source) = @_;

	my $db    = Code::Maven::DB->new;
	my $col   = $db->get_collection($source);
	my $dists = $col->find()->sort( { cm_update => -1 } )->limit(3);

	my @distributions;
	while ( my $d = $dists->next ) {
		push @distributions, $d;
	}
	return template(
		'cpan',
		{
			distributions => \@distributions,
			dir           => $source,
		}
	);
}

sub serve_robots {
	return [ '200', [ 'Content-Type' => 'text/plain' ], [''], ];
}

sub serve_favicon {
	open my $fh, '<:raw', "$root/static/favicon.ico" or return serve_404();

	return [ '200', [ 'Content-Type' => 'image/x-icon' ], $fh, ];
}

sub template {
	my ( $file, $vars ) = @_;
	$vars //= {};
	Carp::confess 'Need to pass HASH-ref to template()'
		if ref $vars ne 'HASH';

	my $ga_file = "$root/config/google_analytics.txt";
	if ( not $google_analytics and -e $ga_file ) {
		$google_analytics = path($ga_file)->slurp_utf8;
	}

	$vars->{google_analytics} = $google_analytics;

	my $tt = Template->new(
		INCLUDE_PATH => "$root/tt",
		INTERPOLATE  => 0,
		POST_CHOMP   => 1,
		EVAL_PERL    => 1,
		START_TAG    => '<%',
		END_TAG      => '%>',
		PRE_PROCESS  => 'incl/header.tt',
		POST_PROCESS => 'incl/footer.tt',
	);
	my $out;
	$tt->process( "$file.tt", $vars, \$out )
		|| die $tt->error();
	return [ '200', [ 'Content-Type' => 'text/html' ], [$out], ];
}

1;

