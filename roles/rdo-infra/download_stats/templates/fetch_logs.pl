#!/usr/bin/perl
use strict;
use warnings;

use DateTime;
use File::chdir;

my $yesterday = DateTime->now()->subtract( 'days' => 1 );
my $dt = $yesterday->ymd('-');
$CWD = "{{ download_dir }}";
`wget http://fedorapeople.org/accesslogs/rdo/$dt.log`;

open STATS, '>>stats.csv';
print STATS $dt . ',';
close STATS;

`grep "rdo-release" $dt.log | grep -c ' 200 ' >> stats.csv`;
`./logresolve.pl < $dt.log > resolved/$dt.log.resolved`;

`cat resolved/$dt.log.resolved | awk '{print \$1}' | sort | uniq --count --repeated | sort -n > resolved/hosts_$dt.log`;

`gzip -9 $dt.log`;

