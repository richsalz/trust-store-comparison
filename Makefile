
all: fetch page dup

.PHONY: all fetch page dup clean

fetch:
	./fetch-certs

TARF = index.html jquery.min.js jquery.tablesorter.min.js
page:
	./make-page
	tar zcf index.tar.gz $(TARF)


dup:
	./make-ski


clean:
	rm -f index.tar.gz

pristine:
	git clean -dfx .
	git clean -fX .
