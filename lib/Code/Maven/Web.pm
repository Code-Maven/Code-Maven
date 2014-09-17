package Code::Maven::Web;
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Path::Tiny qw(path);
use Plack::Builder;
use Plack::Request;
use Template;

use Code::Maven::Blog;

my $root;
my $google_analytics = '';

my %ROUTING = (
	'/'           => \&serve_root,
	'/blog'       => \&serve_blog,
	'/robots.txt' => \&serve_robots,
);
my @ROUTING_REGEX = (
	{
		regex  => qr{^/blog/[^/]*$},
		handle => \&serve_blog_entry,
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

		return [ '404', [ 'Content-Type' => 'text/html' ],
			['404 Not Found'], ];
	};

	builder {
		enable 'Plack::Middleware::Static',
			path => qr{^/(images|js|css|fonts)/},
			root => "$root/static/";
		$app;
	};
}

sub serve_root {
	my $html = template('index');

	return [ '200', [ 'Content-Type' => 'text/html' ], [$html], ];
}

sub serve_blog {

	my $blog = Code::Maven::Blog->new( dir => $root . '/blog' );
	$blog->collect;
	my @posts
		= reverse sort { $a->{timestamp} cmp $b->{timestamp} }
		@{ $blog->posts };
	my $html = template( 'blog', { posts => \@posts } );

	return [ '200', [ 'Content-Type' => 'text/html' ], [$html], ];
}

sub serve_blog_entry {
	my ($env) = @_;

	my $request = Plack::Request->new($env);
	my $path    = $request->path_info;
	my $blog    = Code::Maven::Blog->new( dir => $root . '/blog' );
	my $post    = $blog->read_file( substr( $path, 5 ) );
	my $html
		= template( 'blog_page', { post => $post, title => $post->{title} } );

	return [ '200', [ 'Content-Type' => 'text/html' ], [$html], ];
}

sub serve_robots {
	return [ '200', [ 'Content-Type' => 'text/plain' ], [''], ];
}

sub template {
	my ( $file, $vars ) = @_;

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
	return $out;
}

1;

