use Test::More tests => 5;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

my $view = Pod::POM::View::HTML::Filter->new;

# no foo built-in
my @foo_filters = grep { /^foo$/ } $view->filters;
is( @foo_filters, 0, "No foo filter");
ok( ! $view->know( 'foo' ), "Don't know foo" );

# add a new language
Pod::POM::View::HTML::Filter->add(
    foo  => sub { my $s = shift; $s =~ s/foo/bar/g; $s },
);

# foo is here
@foo_filters = grep { /^foo$/ } $view->filters;
is( @foo_filters, 1, "There's a foo filter now");
ok( $view->know( 'foo' ), "Hey, I know foo now" );
ok( ! $view->know( 'bar' ), "Don't know bar" );

