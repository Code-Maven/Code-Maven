use strict;
use warnings;

use Log::Log4perl        ();
use Log::Log4perl::Level ();

use lib 'lib';
use Code::Maven::MetaCPAN;

Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority('DEBUG') );
Code::Maven::MetaCPAN->new->run;
