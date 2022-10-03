#! /usr/bin/env perl
# Split a file containing multiple PEM certs into multiple files, one
# cert per file. Files will be tmpXX, tmqXX, etc.
use strict;
use warnings;

my $writing = 0;
my $F;
my $fname = "tmp00";

while ( <> ) {
    if ( /BEGIN CERTIFICATE/ ) {
	$fname++;
	open $F, ">", $fname || die "Can't open $fname, $!";
	$writing = 1;
    }
    print $F $_ if $writing;
    if ( /END CERTIFICATE/ ) {
	close $F || warn "Can't close $fname, $!";
	$writing = 0;
    }
}

if ( $writing ) {
    close $F || die "Input truncated? Can't close $fname, $!";
}

exit 0;
