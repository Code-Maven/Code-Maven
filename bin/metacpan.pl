use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Log::Log4perl        ();
use Log::Log4perl::Level ();

use lib 'lib';
use Code::Maven::Config;
use Code::Maven::MetaCPAN;

Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority('DEBUG') );
Code::Maven::Config->initialize( root => dirname( abs_path($0) ) );
Code::Maven::MetaCPAN->new->run;
