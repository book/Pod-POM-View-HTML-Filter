use Test::More;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Syntax;

$Pod::POM::DEFAULT_VIEW = 'Pod::POM::View::HTML::Syntax';

my @tests = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=begin syntax foo

    foo bar baz

=end syntax foo
---
<html><body bgcolor="#ffffff">
<pre>    bar bar baz</pre>

</body></html>
===
this line is considered code by Pod::POM

=for syntax=foo
bar foo bar

para
---
<html><body bgcolor="#ffffff">
bar bar bar<p>para</p>
</body></html>
===
=pod

para

=for syntax=foo
bar bar foo
foo bar bar

para
---
<html><body bgcolor="#ffffff">
<p>para</p>
bar bar bar
bar bar bar<p>para</p>
</body></html>
TESTS

plan tests => scalar @tests;

# add a new language
Pod::POM::View::HTML::Syntax->add(
    foo => sub { my $s = shift; $s =~ s/foo/bar/g; $s },
);

my $parser = Pod::POM->new;
for ( @tests ) {
    my $pom = $parser->parse_text( $_->[0] ) || diag $parser->error;
    is( "$pom", $_->[1], "Correct output" );
}

