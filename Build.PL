use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::POM::View::HTML::Syntax',
    license             => '',
    dist_author         => 'Philippe "BooK" Bruhat <book@cpan.org>',
    dist_version_from   => 'lib/Pod/POM/View/HTML/Syntax.pm',
    requires => {
        'Test::More' => 0,
    },
    recommends => {
        'Perl::Tidy' => '20031021',
    },
    add_to_cleanup      => [ 'Pod-POM-View-HTML-Syntax-*' ],
);

$builder->create_build_script();
