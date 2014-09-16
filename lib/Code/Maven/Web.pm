package Code::Maven::Web;
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Plack::Request;

use Code::Maven::Blog;

my $root = dirname( dirname( dirname( dirname( abs_path(__FILE__) ) ) ) );

my %ROUTING = (
	'/'     => \&serve_root,
	'/blog' => \&serve_blog,
);

sub run {
	sub {
		my $env = shift;

		my $request = Plack::Request->new($env);
		my $route   = $ROUTING{ $request->path_info };
		if ($route) {
			return $route->($env);
		}
		return [ '404', [ 'Content-Type' => 'text/html' ],
			['404 Not Found'], ];
		}
}

sub serve_root {
	my $html = <<'END_HTML';
<html>
<head>
<title>Code::Maven - analyzing and displaying source code</title>
</head>
<body>
<h1>Code::Maven - analyzing and displaying source code</h1>
<p><a href="https://github.com/szabgab/Code-Maven">GitHub</a></p>
<p><a href="/blog">Blog</a></p>
</body>
</html>
END_HTML

	return [ '200', [ 'Content-Type' => 'text/html' ], [$html], ];

}

sub serve_blog {

	my $blog
		= Code::Maven::Blog->new(
		dir => $root . '/blog' );
	$blog->collect;
	my $posts   = $blog->posts;
	my $content = '<ul>';
	for my $p ( sort { $a->{timestamp} cmp $b->{timestamp} } @$posts ) {
		$content
			.= "<li><b>$p->{title}</b> ($p->{timestamp})<br>$p->{content}</li>";
	}
	$content .= '</ul>';

	my $html = <<"END_HTML";
<html>
<head>
<title>Code::Maven - analyzing and displaying source code</title>
</head>
<body>
<h1>Code::Maven blog</h1>
$content
</body>
</html>
END_HTML

	return [ '200', [ 'Content-Type' => 'text/html' ], [$html], ];
}

1;

