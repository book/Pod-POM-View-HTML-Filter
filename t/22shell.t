use Test::More;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

plan skip_all => "Don't know shell"
  unless Pod::POM::View::HTML::Filter->know( 'shell' );

$Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;

my @tests = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=for filter=shell echo "foo"
---
<html><body bgcolor="#ffffff">
<pre>echo <span class="s-quo">"</span><span class="s-val">foo</span><span class="s-quo">"</span></pre>
</body></html>
===
=begin filter shell

    #!/bin/sh
    ps | /usr/lib/sendmail -t
    exit 0

=end filter
---
<html><body bgcolor="#ffffff">
<pre>    <span class="s-cmt">#!/bin/sh
    </span>ps | /usr/lib/sendmail -t
    exit 0</pre>
</body></html>
TESTS

my @tests2 = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=begin filter shell

    #!/bin/sh
    FOO=bar
    echo $foo

=end filter
---
<html><body bgcolor="#ffffff">
<pre>    <span class="s-cmt">#!/bin/sh
    </span><span class="s-avr">FOO</span>=<span class="s-val">bar
    </span>echo <span class="s-var">$foo</span></pre>
</body></html>
TESTS

plan tests => @tests + 2 * @tests2;

my $parser = Pod::POM->new;
for ( @tests ) {
    my $pom = $parser->parse_text( $_->[0] ) || diag $parser->error;
    is( "$pom", $_->[1], "Correct output" );
}

# check what happens if $pom->present is called twice in a row
for ( @tests2 ) {
    my $pom = $parser->parse_text( $_->[0] ) || diag $parser->error;
    is( "$pom", $_->[1], "Correct output the first time" );
    is( "$pom", $_->[1], "Correct output the second time around" );
}

