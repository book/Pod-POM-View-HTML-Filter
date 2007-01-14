use Test::More;
use Pod::POM::View::HTML::Filter;

my @text = (
    [ << 'EOT', '', << 'EOT' ],
clank_est z_zwap glurpp
 blurp
  swoosh
kapow
  ooooff
 urkkk
zlopp klonk
EOT
clank_est z_zwap glurpp
 blurp
  swoosh
kapow
  ooooff
 urkkk
zlopp klonk
EOT
    [ << 'EOT', '    ', << 'EOT' ],

    zapeth

    zgruppp kapow
      bap rip

    glipp crraack aiieee
    zap
    thwape
EOT

zapeth

zgruppp kapow
  bap rip

glipp crraack aiieee
zap
thwape
EOT
);

plan tests => scalar @text;

for (@text) {
use Data::Dumper;print Dumper 
    is_deeply(
        [ Pod::POM::View::HTML::Filter::_unindent( $_->[0] ) ],
        [ @{$_}[ 1, 2 ] ],
        "Found indent: '$_->[1]'"
    );
}
