use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Pod::POM::View::HTML::Filter',
    dist_author        => 'Philippe "BooK" Bruhat <book@cpan.org>',
    dist_version_from  => 'lib/Pod/POM/View/HTML/Filter.pm',
    requires           => {
        'Test::More' => 0,
        'Pod::POM'   => '0.17'
    },
    recommends         => {
        'Perl::Tidy'              => '20031021',
        'Syntax::Highlight::HTML' => 0,
    },
    license            => 'perl',
    add_to_cleanup     => ['Pod-POM-View-HTML-Filter-*'],
);

$builder->create_build_script();
