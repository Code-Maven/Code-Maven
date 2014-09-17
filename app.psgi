#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use lib 'lib';
use Code::Maven::Config;
use Code::Maven::Web;

Code::Maven::Config->initialize( root => dirname( abs_path($0) ) );
my $app = Code::Maven::Web->run;
