package Pod::POM::View::HTML::Syntax;
use base 'Pod::POM::View::HTML';

use warnings;
use strict;

our $VERSION = '0.01';

my %syntax;
my %prereq = (
    perl => [ qw( Perl::Tidy ) ],
);

# automatically register built-in handlers
for my $lang ( keys %prereq ) {
    my $nok = 0;
    for ( @{ $prereq{$lang} } ) {
        eval "require $_;";
        $nok++ if $@;
    }
    no strict 'refs';
    $syntax{$lang} = \&{"${lang}_syntax"} unless $nok;
}

#
# Specific methods
#
sub add {
    my ($class, %args) = @_;
    $syntax{$_} = $args{$_} for keys %args;
}

sub know {
    my ($class, $lang) = @_;
    return exists $syntax{$lang};
}

sub langs { keys %syntax; }

#
# overridden Pod::POM::View::HTML methods
#
sub view_for {
    my ($self, $for)    = @_;
    my $format = $for->format;

    return $for->text() . "\n\n" if $format =~ /\bhtml\b/;
    if ( $format =~ /^syntax\b/ ) {
        my $lang = (split '=', $format)[1];
        return $syntax{$lang}->( $for->text )
          if exists $syntax{$lang};
        warn "$lang not supported in =for syntax";
    }
    # fall-through
    return '';
}

sub view_begin {
    my ($self, $begin)  = @_;
    my ($format, @args) = split ' ', $begin->format();

    if ( $format eq 'html' ) {
        return $self->SUPER::view_begin( $begin );
    }
    elsif( $format eq 'syntax' ) {
        my $lang = shift @args;
        return $syntax{$lang}->( join('', $begin->content) )
          if exists $syntax{$lang};
    }
    # fall-through
    return '';
}

# perl highlighting, thanks to Perl::Tidy
sub perl_syntax {
    my ($code, $output) = ( shift, "" );
    my ($ws) = $code =~ /^(\s*)/; # count the blanks on the first line
    $code =~ s/^$ws//gm;          # remove them

    Perl::Tidy::perltidy(
        source      => \$code,
        destination => \$output,
        argv        => '-html -pre -nopod2html',
        stderr      => '-',
        errorfile   => '-',
    );
    $output =~ s/^/$ws/gm;        # put the indentation back
    return $output;
}

1;

__END__

=head1 NAME

Pod::POM::View::HTML::Syntax - Add syntax highlighting to your pod documents

=cut

=head1 SYNOPSIS

    =begin syntax perl

        # now in full colour!
        $A++;

    =end syntax

    =for syntax=perl $A++; # this works too

=head1 DESCRIPTION

This module is a subclass of Pod::POM::View::HTML that support the
C<syntax> extension. This can be used in C<=begin> / C<=end> and
C<=for> pod blocks.

=head2 Methods

The following methods are available:

=over 4

=item add( lang => $coderef, ... )

Add support for one or more languages.

The code reference must take a string as its only argument and return
the formatted HTML string (coloured accordingly to the language grammar,
hopefully).

Note that C<add()> is a class method.

=item langs()

Return the list of languages supported.

=item know( I<$lang> )

Return true if the view knows how to handle language C<$lang>.

=back

=head2 Overridden methods

The following Pod::POM::View::HTML methods are overridden in
Pod::POM::View::HTML::Syntax:

=over 4

=item view_for

To be used as:

    =for syntax lang
    # some code in language lang

=item view_begin

To be used as:

    =begin syntax lang

    # some code in language lang

    =end syntax

=back

=head1 DEFAULT CSS STYLES

Since the first motivation for this module was to colour Perl code
with Perl::Tidy, the colour-coded HTML is meant to use a CSS file
based on Perl::Tidy's stylesheet.

Perl::Tidy's HTML code looks like:

    <span class="i">$A</span>++<span class="sc">;</span>

Here are the styles used by Perl::Tidy:

    n       numeric
    p       paren
    q       quote
    s       structure
    c       comment
    v       v-string
    cm      comma
    w       bareword
    co      colon
    pu      punctuation
    i       identifier
    j       label
    h       here-doc-target
    hh      here-doc-text
    k       keyword
    sc      semicolon
    m       subroutine
    pd      pod-text

You can use your own style names, but extending Perl::Tidy's scheme will
ensure that all your syntax-highlighted section have a consistent look.

=head1 AUTHOR

Philippe "BooK" Bruhat, C<< <book@cpan.org> >>

=head1 Bugs

Please report any bugs or feature requests to
C<bug-pod-pom-view-html-syntax@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Philippe "BooK" Bruhat, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
