use Test::More;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

plan skip_all => "Perl::Tidy not installed"
  unless Pod::POM::View::HTML::Filter->know( 'perl' );

$Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;

my @tests = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=for filter=perl $A++; # this works too
---
<html><body bgcolor="#ffffff">
<pre><span class="i">$A</span>++<span class="sc">;</span> <span class="c"># this works too</span></pre>


</body></html>
===
=begin filter perl

# now in full colour!
$A++;

=end filter
---
<html><body bgcolor="#ffffff">
<pre><span class="c"># now in full colour!</span>
<span class="i">$A</span>++<span class="sc">;</span></pre>
</body></html>
===
=begin filter perl

    # now in verbatim
    $A++;

=end filter
---
<html><body bgcolor="#ffffff">
<pre>    <span class="c"># now in verbatim</span>
    <span class="i">$A</span>++<span class="sc">;</span></pre>
</body></html>
===
=begin filter perl -nnn

    # now in verbatim
    $A++;

=end filter
---
<html><body bgcolor="#ffffff">
<pre>       1 <span class="c"># now in verbatim</span>
       2 <span class="i">$A</span>++<span class="sc">;</span></pre>
</body></html>
===
=begin filter perl

    # a longer piece of code
    use strict;

    my $A; # must declare

    $A++;

=end filter
---
<html><body bgcolor="#ffffff">
<pre>    <span class="c"># a longer piece of code</span>
    <span class="k">use</span> <span class="w">strict</span><span class="sc">;</span>
    
    <span class="k">my</span> <span class="i">$A</span><span class="sc">;</span> <span class="c"># must declare</span>
    
    <span class="i">$A</span>++<span class="sc">;</span></pre>
</body></html>
TESTS

my @tests2 = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=begin filter perl

    $A++;

=end 
---
<html><body bgcolor="#ffffff">
<pre>    <span class="i">$A</span>++<span class="sc">;</span></pre>
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
  TODO: {
    local $TODO = "BUG: the content of the Pod::POM structure disappears";
    is( "$pom", $_->[1], "Correct output the second time around" );
  }
}

