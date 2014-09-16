package Code::Maven::Web;
use strict;
use warnings;

sub run {
	my $html = <<'END_HTML';
<html>
<head>
<title>Code::Maven - analyzing and displaying source code</title>
</head>
<body>
<h1>Code::Maven - analyzing and displaying source code</h1>
<p><a href="https://github.com/szabgab/Code-Maven">GitHub</a></p>
</body>
</html>
END_HTML

	my $app = sub {
		return [ '200', [ 'Content-Type' => 'text/html' ], [$html], ];
	};

}

1;

