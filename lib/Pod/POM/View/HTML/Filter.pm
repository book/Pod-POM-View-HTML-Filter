package Pod::POM::View::HTML::Filter;
use base 'Pod::POM::View::HTML';

use warnings;
use strict;

our $VERSION = '0.01';

my %filter;
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
    $filter{$lang} = \&{"${lang}_filter"} unless $nok;
}

#
# Specific methods
#
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_)
        || return;

    # initalise stack for maintaining info for filters
    $self->{ FILTER } = [];

    return $self;
}

sub add {
    my ($class, %args) = @_;
    $filter{$_} = $args{$_} for keys %args;
}

sub know {
    my ($class, $lang) = @_;
    return exists $filter{$lang};
}

sub filters { keys %filter; }

#
# overridden Pod::POM::View::HTML methods
#
sub view_for {
    my ($self, $for)    = @_;
    my $format = $for->format;

    return $for->text() . "\n\n" if $format =~ /\bhtml\b/;
    if ( $format =~ /^filter\b/ ) {
        my $lang = (split '=', $format)[1];
        if( exists $filter{$lang} ) {
            return $filter{$lang}->( $for->text ) . "\n\n";
        }
        else { warn "$lang not supported in =for filter"; }
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
    elsif( $format eq 'filter' ) {
        my $lang = shift @args;
        if( exists $filter{$lang} ) {
            push @{$self->{FILTER}}, $lang;
            my $output = $begin->content->present($self);
            pop @{$self->{FILTER}};
            return $output;
        }
        else { warn "$lang not supported in =begin filter"; }
    }
    # fall-through
    return '';
}

sub view_textblock {
    my ($self, $text) = @_;
    if( $self->{FILTER}[-1] ) {
        $text = $filter{$self->{FILTER}[-1]}->($text);
    }
    return "<p>$text</p>\n";
}

sub view_verbatim {
    my ($self, $text) = @_;
    
    if( $self->{FILTER}[-1] ) {
        $text = $filter{$self->{FILTER}[-1]}->($text);
    }
    else { # default
        return $self->SUPER::view_verbatim( $text );
    }
    return "<pre>$text</pre>\n\n";
}

# perl highlighting, thanks to Perl::Tidy
sub perl_filter {
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
    $output =~ s!\A<pre>\n?!!;    # Perl::Tidy adds "<pre>\n"
    $output =~ s!\n</pre>\n\z!!m; #             and "\n</pre>\n"
    $output =~ s/^/$ws/gm;        # put the indentation back

    return $output;
}

1;

__END__

=head1 NAME

Pod::POM::View::HTML::Filter - Use filters on sections of your pod documents

=cut

=head1 SYNOPSIS

In your Pod:

    Some colored Perl code:

    =begin filter perl

        # now in full colour!
        $A++;

    =end filter

    =for filter=perl $A++; # this works too

    This should read C<bar bar bar>:

    =begin filter foo

    bar foo bar

    =end filter

In your code:

    my $view = Pod::POM::View::HTML::Filter->new;
    $view->add( foo => sub { my $s = shift; $s =~ s/foo/bar/gm; $s } );

    my $pom = Pod::POM->parse_file( '/my/pod/file' );
    $pom->present($view);

=head1 DESCRIPTION

This module is a subclass of Pod::POM::View::HTML that support the
C<filter> extension. This can be used in C<=begin> / C<=end> and
C<=for> pod blocks.

Please note that since the view maintains an internal state, only
an instance of the view can be used to present the POM object.
Either use:

    my $view = Pod::POM::View::HTML::Filter->new;
    $pom->present( $view );

or

    $Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;
    $pom->present;

Please note that even though the module was specifically designed
for use with Perl::Tidy, you can write your own filters quite
easily.

=head2 Methods

The following methods are available:

=over 4

=item add( lang => $coderef, ... )

Add support for one or more languages.

The code reference must take a string as its only argument and return
the formatted HTML string (coloured accordingly to the language grammar,
hopefully).

Note that C<add()> is a class method.

=item filters()

Return the list of languages supported.

=item know( I<$lang> )

Return true if the view knows how to handle language C<$lang>.

=back

=head2 Overloaded methods

The following Pod::POM::View::HTML methods are overridden in
Pod::POM::View::HTML::Filter:

=over 4

=item new()

The overloaded constructor initialises some internal structures.

=item view_for

To be used as:

    =for filter=lang
    # some code in language lang

=item view_begin

To be used as:

    =begin filter lang

    # some code in language lang

    =end filter

=item view_textblock
=item view_verbatim

Since C<=begin>/C<=end> and C<=for> blocks contain C<verbatim> and C<text>,
only these methods are overloaded.

=back

=head2 Built-in filters

Pod::POM::View::HTML::Filter is shipped with a few built-in filters.
They are all functions named I<lang>_filter.

=over 4

=item perl_filter

This filter does Perl syntax highlighting with a lot of help from
Perl::Tidy.

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
ensure that all your syntax-highlighted sections have a consistent look.

=head1 AUTHOR

Philippe "BooK" Bruhat, C<< <book@cpan.org> >>

=head1 Bugs

Please report any bugs or feature requests to
C<bug-pod-pom-view-html-filter@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Philippe "BooK" Bruhat, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
