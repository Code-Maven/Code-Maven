package Code::Maven::Web;
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Path::Tiny qw(path);
use Plack::Request;
use Template;

use Code::Maven::Blog;

my $root = dirname( dirname( dirname( dirname( abs_path(__FILE__) ) ) ) );
my $google_analytics = '';

my %ROUTING = (
	'/'     => \&serve_root,
	'/blog' => \&serve_blog,
);

sub run {
	sub {
		my $env = shift;

		my $ga_file = "$root/config/google_analytics.txt";
		if ( -e $ga_file ) {
			$google_analytics = path($ga_file)->slurp_utf8;
		}

		my $request = Plack::Request->new($env);
		my $route   = $ROUTING{ $request->path_info };
		if ($route) {
			my $ret = $route->($env);
			$ret->[2][0] .= footer();
			return $ret;
		}
		return [ '404', [ 'Content-Type' => 'text/html' ],
			['404 Not Found'], ];
	};
}

sub serve_root {
	my $html = template('index');

	return [ '200', [ 'Content-Type' => 'text/html' ], [$html], ];
}

sub serve_blog {

	my $blog = Code::Maven::Blog->new( dir => $root . '/blog' );
	$blog->collect;
	my @posts  = sort { $a->{timestamp} cmp $b->{timestamp} } @{ $blog->posts };
	my $html = template('blog', { posts => \@posts });

	return [ '200', [ 'Content-Type' => 'text/html' ], [$html], ];
}

sub footer {
	return <<"END_HTML";
<hr>
Code::Maven
$google_analytics
</body>
</html>
END_HTML

}

sub template {
	my ($file, $vars) = @_;

	my $tt = Template->new(
		INCLUDE_PATH => "$root/tt",
		INTERPOLATE  => 0,
		POST_CHOMP   => 1,
		EVAL_PERL    => 1,
		START_TAG    => '<%',
		END_TAG      => '%>',
		#POST_PROCESS => 'incl/footer',
	);
	my $out;
	$tt->process("$file.tt", $vars, \$out)
            || die $tt->error();
	return $out;
}

1;

