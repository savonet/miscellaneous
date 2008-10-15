#!/usr/bin/perl -w

use strict;

my $sum = 0;

open STATUS, "wget http://localhost:8000/status.xsl -O - -o /dev/null |" || die "Status not found.";
while (<STATUS>)
{
	$sum += $1 if /Current Listeners:<\/td><td class=\"streamdata\">(\d+)/
}
close STATUS;
print $sum."\n";
