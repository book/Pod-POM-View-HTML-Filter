use Test::More;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

$Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;

my @tests = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=begin filter foo

bar foo bar
baz

=end
---
<html><body bgcolor="#ffffff">
<p>bar bar bar
baz</p>
</body></html>
===
=begin filter foo

    foo bar baz

=end filter foo
---
<html><body bgcolor="#ffffff">
<pre>    bar bar baz</pre>

</body></html>
===
this line is considered code by Pod::POM

=for filter=foo
bar foo bar

para
---
<html><body bgcolor="#ffffff">
bar bar bar

<p>para</p>
</body></html>
===
=pod

para

=for filter=foo
bar bar foo
foo bar bar

para
---
<html><body bgcolor="#ffffff">
<p>para</p>
bar bar bar
bar bar bar

<p>para</p>
</body></html>
TESTS

plan tests => scalar @tests;

# add a new language
Pod::POM::View::HTML::Filter->add(
    foo  => sub { my $s = shift; $s =~ s/foo/bar/g; $s },
);

my $parser = Pod::POM->new;
for ( @tests ) {
    my $pom = $parser->parse_text( $_->[0] ) || diag $parser->error;
    is( "$pom", $_->[1], "Correct output" );
}

