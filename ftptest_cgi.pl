#!/usr/bin/env perl

use strict;
use warnings;
use CGI qw/:standard/;


print header;

system("/home/jctong/scripts/ftptester/run_ftptest");

my $output = `/home/jctong/scripts/ftptester/parse_log.pl`;

print $output;
