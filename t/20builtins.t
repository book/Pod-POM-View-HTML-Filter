use Test::More;
use strict;
use warnings;

use File::Spec::Functions;
use Pod::POM;
use Pod::POM::View::HTML::Filter;

my %avail = map { $_ => 1 }
    grep { $_ ne 'default' } Pod::POM::View::HTML::Filter->filters();

# all available files
my @pods = glob( catfile( 't', 'pod', '*.src' ) );

# compute the test data
my %result;
my %pod;
for my $file (@pods) {

    # read the file
    my $content;
    {
        local $/;
        open my $fh, $file or diag "Can't open $file: $!";
        $content = <$fh>;
        close $fh;
    }

    # process the file content
    my ( $pod, @results ) = split /__RESULT__\n/, $content;
    for my $result (@results) {
        my ( $filters, $output ) = split /\n/, $result, 2;
        $result{$file}{$filters} = $output;
    }

    # create the pod
    $pod{$file} = $pod;
}

# compute the total number of tests
my $tests;
$tests += scalar keys %$_ for values %result;
plan tests => $tests;

# run the tests for all files
for my $file ( sort keys %result ) {

    for my $format ( sort keys %{ $result{$file} } ) {

    SKIP: {

            # create the view
            my $view = Pod::POM::View::HTML::Filter->new();

            # format is for example: +html-perl
            while ( $format =~ /([+-])(\w+)/g ) {

                # skip if required filter not here
                skip "$file <$format> [$2 not available]", 1
                    if $1 eq '+' && !$avail{$2};

                # remove unwanted filter
                $view->delete($2) if $1 eq '-';
            }

            # create the POM
            my $pom = Pod::POM->new()->parse_text($pod{$file});

            # compare the results
            is( $view->print( $pom ),
                $result{$file}{$format},
                "$file <$format>"
            );
        }
    }
}

