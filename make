#! /usr/bin/env perl
use strict;
use warnings;

use File::Path qw( rmtree );
use File::Slurp;

my $now = `date`;
my $link = "https://git.source.akamai.com/users/rsalz/repos/trust-store-comparison/browse";
my $CRTSH = "https://crt.sh?q=";

# HTTP <head> field for sortable tables.
my $head = <<EOF;
  <head>
    <title>Trust store comparison</title>
    <script src="jquery.min.js"></script>
    <script src="jquery.tablesorter.min.js"></script>
    <script>\$(function() { \$("#myTable").tablesorter();})</script>
    <style>
      table {
        text-align: left;
        position: relative;
        border-collapse: collapse;
      }
      th, td {
        padding: 0.25rem;
      }
      tr.heading th {
        background: grey;
        color: white;
      }
      th {
        background: white;
        position: sticky;
        top: 0; /* Don't forget this, required for the stickiness */
        box-shadow: 0 2px 2px -1px rgba(0, 0, 0, 0.4);
      }
    </style>
  </head>
EOF

# Table cells for cert (not)present columns.
my $CW = '4%';
my $PRESENT = "<td width=\"$CW\" bgcolor=\"green\">Y</td>";
my $NOTPRESENT = "<td width=\"$CW\" bgcolor=\"grey\">-</td>";

# Entries for various special status values.
my $MISSING = "&nbsp;&nbsp;<B>missing</B>";
my $LEGACY = "&nbsp;&nbsp;<B>grandfathered</B>";
my $WRONG = "&nbsp;&nbsp;<B>incorrect</B>";

# List of certs that out of policy, but grandfathered.
my %grandfathered = (
    '0C2CD63DF7806FA399EDE809116B575BF87989F06518F9808C860503178BAF66' => 1,
    '2399561127A57125DE8CEFEA610DDF2FA078B5C8067F4E828290BFB860E84B3C' => 1,
    '349DFA4058C5E263123B398AE795573C4E1313C83FE68F93556CD5E8031B3C7D' => 1,
    '34D8A73EE208D9BCDB0D956520934B4E40E69482596E8B6F73C8426B010A6F48' => 1,
    '37D51006C512EAAB626421F1EC8C92013FC5F82AE98EE533EB4619B8DEB4D06C' => 1,
    '4B03F45807AD70F21BFC2CAE71C9FDE4604C064CF5FFB686BAE5DBAAD7FDD34C' => 1,
    '5EDB7AC43B82A06A8761E8D7BE4979EBF2611F7DD79BF91C1C6B566A219ED766' => 1,
    '69DDD7EA90BB57C93E135DC85EA6FCD5480B603239BDC454FC758B2A26CF7F79' => 1,
    '8D25CD97229DBF70356BDA4EB3CC734031E24CF00FAFCFD32DC76EB5841C7EA8' => 1,
    '8D722F81A9C113C0791DF136A2966DB26C950A971DB46B4199F4EA54B78BFB9F' => 1,
    '9ACFAB7E43C8D880D06B262A94DEEEE4B4659989C3D0CAF19BAF6405E41AB7DF' => 1,
    'A22DBA681E97376E2D397D728AAE3A9B6296B9FDBA60BC2E11F647F2C675FB37' => 1,
    'A4310D50AF18A6447190372A86AFAF8B951FFB431D837F1E5688B45971ED1557' => 1,
    'B478B812250DF878635C2AA7EC7D155EAA625EE82916E2CD294361886CD1FBD4' => 1,
    'BEC94911C2955676DB6C0A550986D76E3BA005667C442C9762B4FBB773DE228C' => 1,
    'D8E0FEBC1DB2E38D00940F37D27D41344D993E734B99D5656D9778D4D8143624' => 1,
    'D947432ABDE7B7FA90FC2E6B59101B1280E0E1C7E4E40FA3C6887FFF57A7F4CF' => 1,
    'DB3517D1F6732A2D5AB97C533EC70779EE3270A62FB4AC4238372460E6F01E88' => 1,
    'EB04CF5EB1F39AFA762F2BB120F296CBA520C1B97DB1589565B81CB9A17B7244' => 1,
);

# Get the certificate issuer from a file.
my %cache = ();
sub get_issuer {
    my $file = pop;

    return $cache{$file} if defined $cache{$file};
    open my $fh, '<', $file or die "Can't open $file to find issuer, $!";
    while ( <$fh> ) {
	next unless s/.*Issuer: (.*)/$1/;
	close $fh;
	return $cache{$file} = $1;
    }
    close $fh;
    return $file;
}

# Make a single list of all certs
rmtree("all") or die "Can't rmdir all, $!"
    if -d "all";
my %counts = ();
mkdir "all" or die "Can't mkdir, $!";
foreach my $DIR ( <certs.*> ) {
    chdir $DIR || die "Can't chdir $DIR, $!";
    my @files = <*>;
    my $who = $DIR;
    $who =~ s/^certs.//;
    $counts{$who} = scalar @files;
    foreach my $FILE ( @files ) {
	link $FILE, "../all/${FILE}" or die "Can't link $FILE, $!"
	    if ! -f "../all/${FILE}";
    }
    chdir ".." ||die "Can't chdir $DIR/.., $!";
}
chdir 'all' or die "Can't chdir all, $!";
my @all = <*>;
chdir '..' || die "Can'tchdir up, $!";
$counts{'all'} = scalar @all;

# Make a list of our certs.
chdir "certs.akamai" or die "Can't chdir certs.akamai, $!";
my @akamai = <*>;
chdir ".." or die "Can't chdir .., $!";

# Make list of certs that should be in our trust-store but aren't.
my %missing = ();
foreach my $cert (
    grep {
	-f "certs.apple/$_"
	&& -f "certs.google/$_"
	&& -f "certs.microsoft/$_"
	&& -f "certs.mozilla/$_"
	&& ! -f "certs.akamai/$_" } @all ) {
    $missing{$cert} = 1;
}

# Make list of our certs that were don't follow policy.
my %wrong = ();
foreach my $cert (
    grep {
	! -f "certs.apple/$_" or
	! -f "certs.google/$_" or
	! -f "certs.microsoft/$_" or
	! -f "certs.mozilla/$_" } @akamai ) {
    $wrong{$cert} = 1 if not defined $grandfathered{$cert};
}

open my $FH, '>', 'unified.html' or die "Can't open output, $!";
select $FH;

print <<EOF;
<!DOCTYPE html>
<html lang="en">
  $head

  <body>
    <h1>Trust Store Comparison</h1>
    <p>This page generated at $now from scripts at <a href="$link">$link</a>.
    </p>
    <p>
    Contents
      <ul>
	<li><a href='#complete'>Complete Table</a></li>
	<li><a href='#missing'>Missing Summary</a></li>
	<li><a href='#grandfathered'>Grandfathered Summary</a></li>
	<li><a href='#wrong'>Wrongly-added Summary</a></li>
    </p>
    <p>Click on a column header to sort by that column.
    Double-Click to reverse-sort. Column headings:</p>
    <ul>
      <li>akamai - The "permissive set"</li>
      <li>apple - Apple's trust store</li>
      <li>google - the Chrome trust store</li>
      <li>microsoft - Microsoft's trust store</li>
      <li>mozilla - Firefox's trust store</li>
    </ul>

    <h2 id='complete'>Complete Table</h2>
    <table id="myTable" class="tablesorter" border='1'>
      <thead>
        <tr class="heading">
          <th>Issuer<br>&#8597; ($counts{'all'})</th>
EOF

# Print column headers.
foreach my $DIR ( <certs.*> ) {
    my $who = $DIR;
    $who =~ s/^certs.//;
    print "          <th>$who<br>&#8597;", $counts{$who}, "</th>\n";
}

print <<EOF;
          <th>#<br>&#8597; </th>
        </tr>
      </thead>

      <tbody>
EOF

foreach my $FILE ( @all ) {
    my $ISS =  get_issuer("all/$FILE");
    my $VAL;
    my $COUNT = 0;
    print "        <tr>\n";
    print "          <td><a target=\"_blank\" href=\"${CRTSH}${FILE}\">$ISS</a></br>\n";
    print "              ${MISSING}" if defined $missing{$FILE};
    print "              ${LEGACY}" if defined $grandfathered{$FILE};
    print "              ${WRONG}" if defined $wrong{$FILE};
    print "          </td>\n";
    foreach my $C ( <certs.*> ) {
	if ( -f "$C/$FILE" ) {
	    $VAL = $PRESENT;
	    $COUNT++;
	} else {
	    $VAL = $NOTPRESENT;
	}
        print "          $VAL</td>\n";
    }
    print "          <td width=\"$CW\">$COUNT</td>\n";
    print "        </tr>\n";
}

print <<EOF;
      </tbody>
    </table>
EOF

sub format_line {
    my $cert = pop;
    my $iss = get_issuer("all/$cert");
    return "<li><a target=\"_blank\" href=\"${CRTSH}${cert}\">${iss}</a></br>\n";
}

print "<h2 id='missing'>Missing Summary</h2>\n";
print "<p>Number of certs = ", scalar keys %missing, "</p>\n";
print "<ul>\n";
foreach my $cert ( sort keys %missing ) {
    print format_line($cert);
}
print "</ul>\n";

print "<h2 id='grandfathered'>Grandfathered Summary</h2>\n";
print "<p>Number of certs = ", scalar keys %grandfathered, "</p>\n";
print "<ul>\n";
foreach my $cert ( sort keys %grandfathered ) {
    print format_line($cert);
}
print "</ul>\n";

print "<h2 id='wrong'>Wrongly-added Summary</h2>\n";
print "<p>Number of certs = ", scalar keys %wrong, "</p>\n";
print "<ul>\n";
foreach my $cert ( sort keys %wrong ) {
    print format_line($cert);
}
print "</ul>\n";

print <<EOF;
  </body>
</html>
EOF

rmtree("all") or die "Can't rmdir all, $!"
    if -d "all";

select STDOUT;
close $FH;
