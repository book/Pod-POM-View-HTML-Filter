use Test::More;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

plan skip_all => "Don't know html"
  unless Pod::POM::View::HTML::Filter->know( 'html' );

$Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;

my @tests = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=for filter=html <b>bold</b>
---
<html><body bgcolor="#ffffff">
<pre>
<span class="h-ab">&lt;</span><span class="h-tag">b</span><span class="h-ab">&gt;</span>bold<span class="h-ab">&lt;/</span><span class="h-tag">b</span><span class="h-ab">&gt;</span>
</pre>


</body></html>
===
=begin filter html

<!-- now in full colour! -->
<b>bold</b><i>italics</i>

=end filter
---
<html><body bgcolor="#ffffff">
<pre>
<span class="h-com">&lt;!-- now in full colour! --&gt;</span>
<span class="h-ab">&lt;</span><span class="h-tag">b</span><span class="h-ab">&gt;</span>bold<span class="h-ab">&lt;/</span><span class="h-tag">b</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">i</span><span class="h-ab">&gt;</span>italics<span class="h-ab">&lt;/</span><span class="h-tag">i</span><span class="h-ab">&gt;</span></pre>
</body></html>
===
=begin filter html

    <!-- now in verbatim -->
    <b>bold</b><i>italics</i>

=end filter
---
<html><body bgcolor="#ffffff">
<pre>
    <span class="h-com">&lt;!-- now in verbatim --&gt;</span>
    <span class="h-ab">&lt;</span><span class="h-tag">b</span><span class="h-ab">&gt;</span>bold<span class="h-ab">&lt;/</span><span class="h-tag">b</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">i</span><span class="h-ab">&gt;</span>italics<span class="h-ab">&lt;/</span><span class="h-tag">i</span><span class="h-ab">&gt;</span></pre>
</body></html>
===
=begin filter html

    <!-- a longer piece of HTML -->
    <p>First paragraph</p>

    <p>another para</p>

    <p>End</p>

=end filter
---
<html><body bgcolor="#ffffff">
<pre>
    <span class="h-com">&lt;!-- a longer piece of HTML --&gt;</span>
    <span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>First paragraph<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>

    <span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>another para<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>

    <span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>End<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span></pre>
</body></html>
===
=begin filter html

<p>This is a list:</p>

<ul>
  <li>first item</li>
  <li>second
      item</li>
</ul>

=end filter
---
<html><body bgcolor="#ffffff">
<pre>
<span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>This is a list:<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>

<span class="h-ab">&lt;</span><span class="h-tag">ul</span><span class="h-ab">&gt;</span>
  <span class="h-ab">&lt;</span><span class="h-tag">li</span><span class="h-ab">&gt;</span>first item<span class="h-ab">&lt;/</span><span class="h-tag">li</span><span class="h-ab">&gt;</span>
  <span class="h-ab">&lt;</span><span class="h-tag">li</span><span class="h-ab">&gt;</span>second
      item<span class="h-ab">&lt;/</span><span class="h-tag">li</span><span class="h-ab">&gt;</span>
<span class="h-ab">&lt;/</span><span class="h-tag">ul</span><span class="h-ab">&gt;</span></pre>
</body></html>
TESTS

my @tests2 = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=begin filter html

    <!-- a longer piece of HTML -->
    <p>First paragraph</p>

<p>another para</p>

    <p>End</p>

=end filter
---
<html><body bgcolor="#ffffff">
<pre>
    <span class="h-com">&lt;!-- a longer piece of HTML --&gt;</span>
    <span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>First paragraph<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>

<span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>another para<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>

    <span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>End<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span></pre>
</body></html>
TESTS
my @tests3 = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=begin filter html nnn=1

<p>line 1</p>
    <p>line 2</p>

    <p>line 4</p>

=end filter
---
<html><body bgcolor="#ffffff">
<pre>
<span class="h-lno">  1</span> <span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>line 1<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>
<span class="h-lno">  2</span>     <span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>line 2<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>
<span class="h-lno">  3</span> 
<span class="h-lno">  4</span>     <span class="h-ab">&lt;</span><span class="h-tag">p</span><span class="h-ab">&gt;</span>line 4<span class="h-ab">&lt;/</span><span class="h-tag">p</span><span class="h-ab">&gt;</span></pre>
</body></html>
TESTS

plan tests => @tests + 2 * @tests2 + @tests3;

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

# test the numbering option
SKIP: {
    skip "Syntax::Highlight::HTML version 0.02 required", scalar @tests3
        unless $Syntax::Highlight::HTML::VERSION >= '0.02';
    for ( @tests3 ) {
        my $pom = $parser->parse_text( $_->[0] ) || diag $parser->error;
        is( "$pom", $_->[1], "Correct output" );
    }
}

