# trust-store-comparison

No makefile, nothing to compile.  Just some bash, perl, and python3 scripts.

*Right now this work on Akamai, and will need some tuning to make it
work elsewhere.  PR's accepted.*

If you run this script on, say, a Linux host, but want to view the
generated files somewhere else, make sure to copy `*.html` and `*.js`
to the other machine.

Also, in Perforce //docs/esp/eng/stability/tools/cacheck has a script
to check for global_server.xml expirations, etc. That script (which I
wrote) is the basis for the split-* scripts.

Here's a list of the scripts.

## fetch-certs

Fetches certs from Apple, Google/Android OpenSource, Google Chromium trust
store, Microsoft, Mozilla, and Akamai perissive-set and global-server
contents.  It actually uses a public GitHub repo to get the external certs.
Each trust store has its own directory.  Environment variable LSG can
be set to point to which LSG host to use.

## make-page

Generates an HTML page, called `index.html`, that contains the comparisons.
That page includes `jquery.min.js` and `jquery.tablesorter.min.js` to do the
table/column cleverness.  Put all three files in the same directory and point
your browser there.

## make-github-page

Makes a listing of the Akamai permissive-set (a/k/a our global Trust Store)
in markdown format.  If you have the ../akamai-certificate-store repository
exists, it will copy the file over, check it in, and push it to GitHub.

## check-ski

A script to check all the certs, in each directory, and see if there
are any that share the same Subject Key Identifier


## make-ski-page

Generates an HTML page called `dup-ski.html` (with links to show the certs)
of certificates that have dupplicate Subject Key Identifier. Prettier output
than `check-ski`

## akamai-missing

A list of what Akamai permissive-set is missing that the all the other
trust stores have. It outputs a list of the SHA256 digests, which isn't
friendly, but you can do things like this, to see
which certs we're missing that Apple trusts:

```
for F in $(cat ./akamai-missing) ; do
    cat certs.apple/$F
done
```

Note that will generate a LOT of output

## make-missing-page

Create stand-alone `missing-certs.html` that lists what certs are missing,
in a format similar to `make-page`.

## akamai-deleted

A list of certs in the Akamai permissive-set that are not present in the
major trust stores. It outputs a list of the SH256 digest. A handful of
CAs are "grandfathered" in, and are not output.

## make-deleted-page

Createa a stand-alone `deleted-certs.html` page that lists the certs we
should remove, in a format similar to `make-page`.
