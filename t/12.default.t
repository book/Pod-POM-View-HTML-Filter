use Test::More tests => 3;
use strict;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

my $view = $Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;

# no foo built-in
my @foo_filters = grep { /^foo$/ } $view->filters;
is( @foo_filters, 0, "No foo filter");
ok( ! $view->know( 'foo' ), "Don't know foo" );

# test some foo filter anyway
my $parser = Pod::POM->new;
my $pom = $parser->parse_text( <<'EOT' ) || diag $parser->error;
=head1 Foo

The foo filter at work:

=begin filter foo

    $A++;

=end filter
EOT
is( "$pom", << 'EOH', "Default is simply <pre>");
<html><body bgcolor="#ffffff">
<h1>Foo</h1>

<p>The foo filter at work:</p>
<pre>    $A++;</pre></body></html>
EOH


