use Test::More;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Syntax;

plan skip_all => "Perl::Tidy not installed"
  unless Pod::POM::View::HTML::Syntax->know( 'perl' );

$Pod::POM::DEFAULT_VIEW = 'Pod::POM::View::HTML::Syntax';

my @tests = map { [ split /^---.*?^/ms ] } split /^===.*?^/ms, << 'TESTS';
=begin syntax perl

    # now in full colour!
    $A++;

=end syntax
---
foo
===
=for syntax=perl $A++; # this works too
---
bar
TESTS

plan tests => scalar @tests;

my $parser = Pod::POM->new;
for ( @tests ) {
    my $pom = $parser->parse_text( $_->[0] ) || diag $parser->error;
    is( "$pom", $_->[1], "Correct output" );
}

