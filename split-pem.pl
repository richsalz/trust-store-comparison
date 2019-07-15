#! /usr/bin/env perl

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
    if ( /CLOSE CERTIFICATE/ ) {
	close $F || warn "Can't close $fname, $!";
    }
}

if ( $writing ) {
    close $F || die "Can't close $fname, $!";
}

exit 0;
