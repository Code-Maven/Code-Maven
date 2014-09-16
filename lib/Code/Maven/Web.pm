package Code::Maven::Web;
use strict;
use warnings;

use Plack::Request;

my %ROUTING = (
	'/'     => \&serve_root,
	'/blog' => \&serve_echo,
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

1;

