package Pod::POM::View::HTML::Filter;
use Pod::POM::View::HTML;
our @ISA = qw( Pod::POM::View::HTML );

use warnings;
use strict;
use Carp;

our $VERSION = '0.05';
our $default = { code     => sub { $_[0] } };

my %filter;
my %builtin = (
    default => $default,
    perl => {
        code     => \&perl_filter,
        requires => [qw( Perl::Tidy )],
        verbatim => 1,
    },
    html => {
        code     => \&html_filter,
        requires => [qw( Syntax::Highlight::HTML )],
        verbatim => 1,
    },
    shell => {
        code     => \&shell_filter,
        requires => [qw( Syntax::Highlight::Shell )],
        verbatim => 1,
    },
);

my $HTML_PROTECT = 0;

# automatically register built-in handlers
my $INIT = 1;
add( "PPVHF", %builtin );
$INIT = 0;

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
    for my $lang ( keys %args ) {
        my $nok = 0;
        if( exists $args{$lang}{requires} ) {
            for ( @{ $args{$lang}{requires} } ) {
                eval "require $_;";
                if ($@) {
                    $nok++;
                    carp "$lang: pre-requisite $_ could not be loaded"
                      unless $INIT;    # don't warn for built-ins
                }
            }
        }
        croak "$lang: no code parameter given"
          unless exists $args{$lang}{code};

        $filter{$lang} = $args{$lang} unless $nok;
    }
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

    return $for->text() . "\n\n" if $format =~ /^html\b/;

    if ( $format =~ /^filter\b/ ) {
        my $lang = (split '=', $format)[1];
        $lang = exists $filter{$lang} ? $lang : 'default';
        return $filter{$lang}{code}->( $for->text, "" ) . "(for)\n\n";
    }
    # fall-through
    return '';
}

sub view_begin {
    my ($self, $begin)  = @_;
    my ($format, $args) = split(' ', $begin->format(), 2);

    if ( $format eq 'html' ) {
        return $self->SUPER::view_begin( $begin );
    }
    elsif( $format eq 'filter' ) {
        my @filters = split /\|/, $args;

        # fetch the text and verbatim blocks in the begin section
        # and remember the type of each block
        my $prev = '';
        my @blocks;
        for( @{ $begin->content } ) {
            my $type = $_->type;

            # catenate verbatim blocks together
            push @blocks, [
              ( $type eq $prev ? (pop @blocks)->[0] . "\n\n" : '' )
                . $_->text(),
              $type
            ] if $type eq 'verbatim';

            # quotes force Pod::POM to present the $_ data in html
            push @blocks, [
              (s{\A<p>|</p>[\n\r]*\z}{}g, $_)[1],
              $type
            ] if $type eq 'text'; 

            # remember what we just saw
            $prev = $type;
        }

        # now pass the block list through the filter list
        for my $block (@blocks) {
            my $verbatim;
            for my $f (@filters) {
                my ( $lang, $opts ) = split( ' ', $f, 2 );
                $lang = exists $filter{$lang} ? $lang : 'default';

                $block->[0] = $filter{$lang}{code}->( $block->[0], $opts );
                $verbatim   = $filter{lang}{verbatim};
            }

            # the enclosing tags depend on the block and the last filter
            $block = sprintf(
                ( $verbatim || $block->[1] eq 'verbatim'
                  ? "<pre>%s</pre>\n"
                  : "<p>%s</p>\n"     ),
                $block->[0]
            );
        }

        # the tags depend on the last filter only
        return join $/, @blocks;
    }

    # fall-through
    return '';
}

# perl highlighting, thanks to Perl::Tidy
sub perl_filter {
    my ($code, $opts) = ( shift, shift || "" );
    my $output = "";
    my ($ws) = $code =~ /^(\s*)/; # count the blanks on the first line
    $code =~ s/^$ws//gm;          # remove them

    # Perl::Tidy 20031021 uses Getopt::Long and expects the default config
    # this is a workaround (a patch was sent to Perl::Tidy's author)
    my $glc = Getopt::Long::Configure();
    Getopt::Long::ConfigDefaults();

    Perl::Tidy::perltidy(
        source      => \$code,
        destination => \$output,
        argv        => "-html -pre -nopod2html " . $opts,
        stderr      => '-',
        errorfile   => '-',
    );
    $output =~ s!\A<pre>\n?!!;    # Perl::Tidy adds "<pre>\n"
    $output =~ s!\n</pre>\n\z!!m; #             and "\n</pre>\n"
    $output =~ s/^/$ws/gm;        # put the indentation back

    # put back Getopt::Long previous configuration, if needed
    Getopt::Long::Configure( $glc );

    return "<pre>$output</pre>\n";
}

# a cache for multiple parsers with the same options
my %filter_parser;

# HTML highlighting thanks to Syntax::Highlight::HTML
sub html_filter {
    my ($code, $opts) = ( shift, shift || "" );

    my $parser = $filter_parser{html}{$opts}
      ||= Syntax::Highlight::HTML->new( map { (split /=/) } split ' ', $opts );
    return $parser->parse($code);
}

# Shell highlighting thanks to Syntax::Highlight::Shell
sub shell_filter {
    my ($code, $opts) = ( shift, shift || "" );

    my $parser = $filter_parser{shell}{$opts}
      ||= Syntax::Highlight::Shell->new( map { (split /=/) } split ' ', $opts );
    return $parser->parse($code);
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
    $view->add(
        foo => {
            code => sub { my $s = shift; $s =~ s/foo/bar/gm; $s },
            # other options are available
        }
    );

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

=item add( lang => { options }, ... )

Add support for one or more languages. Options are passed in a hash
reference.

The required C<code> option is a reference to the filter routine. The
filter must take a string as its only argument and return the formatted
HTML string (coloured accordingly to the language grammar, hopefully).

Available options are:

    Name       Type       Content
    ----       ----       -------

    code       CODEREF    filter implementation

    verbatim   BOOLEAN    if true, force the full content of the
                          =begin/=end block to be passed verbatim
                          to the filter

    requires   ARRAYREF   list of required modules for this filter

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
This means that you'll have to use a instance of the class as a
view for your Pod::POM object. Therefore you must use C<new>.

    $Pod::POM::DEFAULT_VIEW = 'Pod::POM::View::HTML::Filter'; # WRONG
    $pom->present( 'Pod::POM::View::HTML::Filter' );          # WRONG

    # this is CORRECT
    $Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;

    # this is also CORRECT
    my $view = Pod::POM::View::HTML::Filter->new;
    $pom->present( $view );

=item view_begin

To be used as:

    =begin filter lang options

    # some code in language lang

    =end filter

The options are passed as a single string to the filter routine which
must do its own parsing.

=item view_for

To be used as:

    =for filter=lang
    # some code in language lang

The C<=for> construct does not support filter options.

=item view_textblock
=item view_verbatim

Since C<=begin>/C<=end> and C<=for> blocks contain C<verbatim> and C<text>,
only these methods are overloaded.

=item view_seq_text

This method was copied verbatim from Pod::POM::View::HTML.
This is an ugly hack and should disappear in future releases.

=back

=head2 Built-in filters

Pod::POM::View::HTML::Filter is shipped with a few built-in filters.
They are all functions named I<lang>_filter.

=over 4

=item default

This filter is called when the required filter is not known by
Pod::POM::View::HTML::Filter. It simply wraps the content of the 
=begin / =end section between C<< <pre> >>/C<< </pre> >>.

The default filter is available from
C<$Pod::POM::View::HTML::Filter::default>. This allows one to do:

    Pod::POM::View::HTML::Filter->add(
        $_ => $Pod::POM::View::HTML::Filter::default
    ) for Pod::POM::View::HTML::Filter->filters;

and set all existing filters back to default.

=item perl_filter

This filter does Perl syntax highlighting with a lot of help from
Perl::Tidy.

It accepts options to Perl::Tidy, such as C<-nnn> to number lines of
code. Check Perl::Tidy's documentation for more information about
those options.

=item html_filter

This filter does HTML syntax highlighting with the help of
Syntax::Highlight::HTML.

The filter supports Syntax::Highlight::HTML options:

    =begin filter html nnn=1

    <p>The lines of the HTML code will be numbered.</p>
    <p>This is line 2.</p>

    =end filter

See Syntax::Highlight::HTML for the list of supported options.

=item shell_filter

This filter does shell script syntax highlighting with the help of
Syntax::Highlight::Shell.

The filter supports Syntax::Highlight::Shell options:

    =begin filter shell nnn=1

        #!/bin/sh
        echo "This is a foo test" | sed -e 's/foo/shell/'

    =end filter

See Syntax::Highlight::Shell for the list of supported options.

=back

=head1 WRITING YOUR OWN FILTERS

Write a filter is quite easy: a filter is a subroutine that takes two
arguments (text to parse and option string) and returns the filtered
string.

The filter is then added to Pod::POM::View::HTML::Filter with the
add() method:

    $view->add( foo => {
        code     => \&foo_filter,
        requires => [],
    );

When presenting the following piece of pod,

    =begin filter foo bar baz

    Some text to filter.

    =end filter

the foo_filter() routine will be called with two arguments, like this:

    foo_filter( "Some text to filter.", "bar baz" );

If you have a complex set of options, your routine will have to parse 
the option string itself.

Please note that when called in a C<=for> construct, no option string
is passed to the filter.

=head1 BUILT-IN FILTERS CSS STYLES

Each filter defines its own CSS styles, so that one can define their
favourite colours in a custom CSS file.

=head2 C<perl> filter

Perl::Tidy's HTML code looks like:

    <span class="i">$A</span>++<span class="sc">;</span>

Here are the styles used by Perl::Tidy:

    n        numeric
    p        paren
    q        quote
    s        structure
    c        comment
    v        v-string
    cm       comma
    w        bareword
    co       colon
    pu       punctuation
    i        identifier
    j        label
    h        here-doc-target
    hh       here-doc-text
    k        keyword
    sc       semicolon
    m        subroutine
    pd       pod-text

=head2 C<html> filter

Syntax::Highlight::HTML defines the following styles:

    h-decl   declaration    # declaration <!DOCTYPE ...>
    h-pi     process        # process instruction <?xml ...?>
    h-com    comment        # comment <!-- ... -->
    h-ab     angle_bracket  # the characters '<' and '>' as tag delimiters
    h-tag    tag_name       # the tag name of an element
    h-attr   attr_name      # the attribute name
    h-attv   attr_value     # the attribute value
    h-ent    entity         # any entities: &eacute; &#171;

=head2 C<shell> filter

Syntax::Highlight::Shell defines the following styles:

    s-key                   # shell keywords (like if, for, while, do...)
    s-blt                   # the builtins commands
    s-cmd                   # the external commands
    s-arg                   # the command arguments
    s-mta                   # shell metacharacters (|, >, \, &)
    s-quo                   # the single (') and double (") quotes
    s-var                   # expanded variables: $VARIABLE
    s-avr                   # assigned variables: VARIABLE=value
    s-val                   # shell values (inside quotes)
    s-cmt                   # shell comments

=head1 AUTHOR

Philippe "BooK" Bruhat, C<< <book@cpan.org> >>

=head1 THANKS

Many thanks to Sébastien Aperghis-Tramoni (Maddingue), who helped
debugging the module and wrote Syntax::Highlight::HTML so that I
could ship the C<html> filter.

=head1 BUGS

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
