use Test::More tests => 8;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

my $view = Pod::POM::View::HTML::Filter->new;

# no foo built-in
my @foo_filters = grep { /^foo$/ } $view->filters;
is( @foo_filters, 0, "No foo filter");
ok( ! $view->know( 'foo' ), "Don't know foo" );

# test add, know and filters as class methods
Pod::POM::View::HTML::Filter->add(
    foo  => sub { my $s = shift; $s =~ s/foo/bar/g; $s },
);
@foo_filters = grep { /^foo$/ } Pod::POM::View::HTML::Filter->filters;
is( @foo_filters, 1, "There's a foo filter now");
ok( Pod::POM::View::HTML::Filter->know( 'foo' ), "Hey, I know foo now" );
ok( ! Pod::POM::View::HTML::Filter->know( 'bar' ), "Don't know bar" );

# test add, know and filters as instance methods
$view->add( foo2 => sub { "foo" } );
@foo_filters = grep { /^foo/ } $view->filters;
is( @foo_filters, 2, "There are two foo filters");
ok( $view->know( 'foo2' ), "Hey, I know foo2 now" );
ok( ! $view->know( 'bar' ), "Still don't know bar" );

