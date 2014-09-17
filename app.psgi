#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use lib 'lib';
use Code::Maven::Web;
my $app = Code::Maven::Web->run( dirname( abs_path($0) ) );
