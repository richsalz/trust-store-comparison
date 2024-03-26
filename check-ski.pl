#! /usr/bin/env perl -w
use strict;
use warnings;

## Open the file, and if a Subject Key Identifier is there, return
## the next line, else return undef.
sub
get_ski()
{
    my ( $file ) = pop;
    open my $fh, '<', $file || die "Can't parse $file, $!";
    my @lines = <$fh>;
    close $fh;

    foreach my $idx (0 .. $#lines) {
	if ( $lines[$idx] =~ /X509v3 Subject Key/ ) {
	    my $ret = $lines[$idx + 1];
	    $ret =~ s/[ \t\r\n]//g;
	    return $ret;
	}
    }
    return undef

}

# Loop over all cert directories, scanning every file in each dir
foreach my $dir ( <certs.*> ) {
    print "# $dir\n";
    chdir $dir || die "Can't chdir $dir, $!";

    my %seen = ();
    foreach my $file ( <*> ) {
	my $ski = &get_ski($file);
	next if not defined $ski;
	if ( defined $seen{$ski} ) {
	    print "Duplicate\n  " . $seen{$ski} . "\n  $dir/$file\n\n";
	} else {
	    $seen{$ski} = "$dir/$file";
	}
    }

    chdir ".." || die "Can't chdir from $dir, $!";
}

exit 0;
