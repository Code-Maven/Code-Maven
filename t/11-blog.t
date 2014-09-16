use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

plan tests => 2;

use Code::Maven::Blog;
my $blog = Code::Maven::Blog->new(
	dir => dirname( dirname( abs_path($0) ) ) . '/blog' );
isa_ok $blog, 'Code::Maven::Blog';

ok $blog->collect, 'collected more than one post';

#diag explain $blog->posts;

