use Test::More tests => 1;

diag "Printing versions of relevant modules";

for my $module ( qw(
    Test::More
    Pod::POM
    Perl::Tidy
    Syntax::Highlight::HTML
    Syntax::Highlight::Shell
) ) {
    eval "require $module;";
    diag $@ ? "$module not installed"
            : "$module " . UNIVERSAL::VERSION($module);
}

ok(1, "Dummy test" );
