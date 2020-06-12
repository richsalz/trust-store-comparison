#! /usr/bin/env python
"""
python split-permissive.py file...

Read files, find contents of security:calist/server-set@akamai-permissive
and write out all certs.

Looks for common syntax errors, bad XML, and expired certificates.
"""

import sys
from xml.dom.minidom import parse as xmlparse

certsbysha = dict()

def kids(node, nodetype):
    """Return all child nodes that are of the specified type."""
    return [n for n in node.childNodes if n.nodeType == nodetype]

def get_text(n):
    '''Glue all the text children of |n| together, strip leading and
    trailing whitespace, return a single text string.'''
    text = "".join([tn.wholeText for tn in kids(n, n.TEXT_NODE)])
    return "\n".join([str(l).lstrip() for l in text.split("\n")])

def writeout(n):
    """Take the server-set starting at node |n| and write out all
    certs in that set."""
    # Get all non-blank lines.
    members = [m for m in get_text(n).split("\n") if len(m) > 0]
    for m in members:
        s = m.find("/")
        # Write cert to file
        sha = m[4:s].lower()
        sha = sha[1:]
        open(sha.replace(":", ""), "w").write(certsbysha[sha])

def parse(fname):
    """Read |fname|, store all the certificates, and explode the contents
    of akamai-permissive set."""

    # Walk the tree, want /configs/edge-config/security:calist (xpath)
    dom = xmlparse(open(fname))
    c = dom.getElementsByTagName(u"configs")
    if len(c) != 1:
        raise SystemError, "Wrong root element (not configs)"
    c = c[0].getElementsByTagName(u"edge-config")
    if len(c) != 1:
        raise SystemError, "Wrong child element (not edge-config)"

    # Walk over all calist nodes
    for calist in c[0].getElementsByTagName(u"security:calist"):
        for n in kids(calist, c[0].ELEMENT_NODE):
            if n.tagName == u"server-set":
                if n.getAttribute("name") == u"akamai-permissive":
                    writeout(n)
                continue
            if n.tagName != u"server":
                continue
            name = n.getAttribute("name")
            cert = get_text(n)
            # Look for a sha1: or sha1= line.
            start = cert.find("sha1:")
            if start == -1:
                start = cert.find("sha1=")
                if start == -1:
                    raise SystemError, "No sha1 line"
            # Skip the sha1, chop the newline and any /foo comment
            sha1 = cert[start + 5:]
            sha1 = sha1[:sha1.find("\n")]
            slash = sha1.find("/")
            if slash != -1:
                sha1 = sha1[:slash]
            certsbysha[sha1.lower()] = cert

for fname in sys.argv[1:]:
    parse(fname)
