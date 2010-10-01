#!/usr/bin/env perl

use strict;
use warnings;

my @deps = @ARGV;

my $j = 0;
my $baddeps = "";

foreach my $dep (@deps) { 
	my $odep = $dep;
	$dep =~ s|::|/|g;
	$dep .= ".pm"; 
	my $i = 0; 
	foreach my $path (@INC) { 
		if (-e "$path/$dep") { 
			$i = 1;
			last; 
		}
	}
	unless ($i) {
		$j++;
		$baddeps .= "    $odep\n";
	}
}

if ($j) {
	print "Required modules not found:\n";
	print $baddeps;
	exit 1;
}

