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
<span class="i">$A</span>++<span class="sc">;</span> <span class="c"># this works too</span>

</body></html>
===
=begin filter perl

# now in full colour!
$A++;

=end filter
---
<html><body bgcolor="#ffffff">
<p><span class="c"># now in full colour!</span>
<span class="i">$A</span>++<span class="sc">;</span></p>
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
TESTS

plan tests => scalar @tests;

my $parser = Pod::POM->new;
for ( @tests ) {
    my $pom = $parser->parse_text( $_->[0] ) || diag $parser->error;
    is( "$pom", $_->[1], "Correct output" );
}

