package Code::Maven::Web;
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use DateTime;
use Cwd qw(abs_path);
use Carp ();
use File::Basename qw(dirname);
use Path::Tiny qw(path);
use Plack::Builder;
use Plack::Request;
use Template;
use Web::Feed;

use Code::Maven::Blog;
use Code::Maven::DB;

my $root;
my $google_analytics = '';

my %ROUTING = (
	'/'            => \&serve_root,
	'/blog'        => \&serve_blog,
	'/blog/atom'   => \&serve_blog_atom,
	'/plans'       => \&serve_plans,
	'/robots.txt'  => \&serve_robots,
	'/favicon.ico' => \&serve_favicon,
	'/cpan'        => sub { _serve_source('cpan') },
	'/pypi'        => sub { _serve_source('pypi') },
	'/pear'        => sub { _serve_source('pear') },
	'/gems'        => sub { _serve_source('gems') },
	'/npm'         => sub { _serve_source('npm') },
	'/events'      => \&serve_events,
);
my @ROUTING_REGEX = (
	{
		regex  => qr{^/blog/[^/]*$},
		handle => \&serve_blog_entry,
	},
	{
		regex  => qr{^/cpan/[^/]*$},
		handle => sub { serve_distribution( $_[0], 'cpan' ) },
	},
	{
		regex  => qr{^/pypi/[^/]*$},
		handle => sub { serve_distribution( $_[0], 'pypi' ) },
	},
	{
		regex  => qr{^/pear/[^/]*$},
		handle => sub { serve_distribution( $_[0], 'pear' ) },
	},
	{
		regex  => qr{^/gems/[^/]*$},
		handle => sub { serve_distribution( $_[0], 'gems' ) },
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

sub _convert_events {
	my ($events) = @_;
	my @events;
	while ( my $e = $events->next ) {
		$e->{timestamp}
			= DateTime->from_epoch( epoch => $e->{_id}->get_time );

		push @events, $e;
	}
	return \@events;
}

sub serve_events {
	my $db        = Code::Maven::DB->new;
	my $event_log = $db->get_eventlog;
	my $events    = $event_log->find()->sort( { _id => -1 } )->limit(100);

	my $display_events = _convert_events($events);

	return template(
		'events',
		{
			events => $display_events,
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

sub serve_distribution {
	my ( $env, $source ) = @_;

	my $request   = Plack::Request->new($env);
	my $path      = $request->path_info;
	my $dist_name = substr( $path, 6 );

	my $db   = Code::Maven::DB->new;
	my $col  = $db->get_collection($source);
	my $dist = $col->find_one( { 'meta.distribution' => $dist_name } );

	my $event_log = $db->get_eventlog;
	my $events    = $event_log->find(
		{
			source       => $source,
			distribution => $dist_name,
		}
	)->sort( { _id => -1 } )->limit(100);

	my $display_events = _convert_events($events);

	#die Dumper $dist;

	return template(
		$source . '_distribution',
		{
			title        => $dist_name,
			distribution => $dist,
			events       => $display_events,
		}
	);
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
		$source,
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

sub serve_blog_atom {
	my ($env) = @_;

	my $xml = '';

	my $request = Plack::Request->new($env);
	my $url     = $request->base;
	$url =~ s{/$}{};

	my $blog = Code::Maven::Blog->new( dir => $root . '/blog' );
	$blog->collect;
	my @posts
		= reverse sort { $a->{timestamp} cmp $b->{timestamp} }
		@{ $blog->posts };

	my $ts = DateTime->now;
	my @entries;
	foreach my $p (@posts) {
		my %e;
		$e{title}   = $p->{title};
		$e{summary} = qq{<![CDATA[$p->{content}]]>};
		$e{updated} = $p->{timestamp};

		$e{link} = qq{$url/blog/$p->{path}};

		$e{id} = $p->{link};

		#		$e{content} = qq{<![CDATA[$p->{abstract}]]>};
		push @entries, \%e;
	}

	my $pmf = Web::Feed->new(
		url         => $url,
		path        => 'atom',
		title       => 'Code::Maven blog',
		updated     => $ts,
		entries     => \@entries,
		description => 'Code::Maven - analyzing and displaying source code',
	);

	return [
		'200',
		[ 'Content-Type' => 'application/atom+xml' ],
		[ $pmf->atom ],
	];
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

