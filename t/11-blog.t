use strict;
use warnings;

use Test::More;
use Cwd qw(getcwd abs_path);
use File::Basename qw(dirname);

plan tests => 1;

use Code::Maven::Blog;
my $blog = Code::Maven::Blog->new( dir => dirname( abs_path( getcwd() ) ) );
isa_ok $blog, 'Code::Maven::Blog';

