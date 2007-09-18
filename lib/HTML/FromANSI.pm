# $File: //member/autrijus/HTML-FromANSI/lib/HTML/FromANSI.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 7867 $ $DateTime: 2003/09/04 17:11:36 $

package HTML::FromANSI;
$HTML::FromANSI::VERSION = '1.01';

use strict;
use base qw/Exporter/;
use vars qw/@EXPORT @EXPORT_OK @Color %Options/;
use Term::VT102;
use HTML::Entities;

=head1 NAME

HTML::FromANSI - Mark up ANSI sequences as HTML

=head1 VERSION

This document describes version 1.01 of HTML::FromANSI, released
September 5, 2003.

=head1 SYNOPSIS

    use HTML::FromANSI;
    use Term::ANSIColor;

    $HTML::FromANSI::Options{fill_cols} = 1; # fill all 80 cols
    print ansi2html(color('bold blue'), "This text is bold blue.");

=head1 DESCRIPTION

This small module converts ANSI text sequences to corresponding HTML
codes, using stylesheets to control color and blinking properties.

It exports C<ansi2html()> by default, which takes an array, joins it
it into a single scalar, and returns its HTML rendering.

From version 0.99 and above, this module has been changed to use the
excellent B<Term::VT102> module, so cursor movement and other terminal
control codes are properly handled.

If you want to generate these movement codes in perl, please take a
look at my B<Term::ANSIScreen> module.

=head1 OPTIONS

There are various options stored in the C<%HTML::FromANSI::Options>
hash; you can also enter them explicitly from the C<use> line. Below
are brief description of each option:

=over 4

=item linewrap

A boolean value to specify whether to wrap lines that exceeds
width specified by C<col>, or simply truncate them. Defaults to C<1>.

=item lf_to_crlf

A boolean value to specify whether to translate all incoming
\n into C<\r\n> or not; you generally wants to use this if your
data is from a file using unix line endings. The default is C<0>
on MSWin32 and MacOS, and C<1> on other platforms.

=item fill_cols

A boolean value to specify whether to fill empty columns with
space; use this if you want to maintain a I<screen-like> appearance
in the resulting HTML, so that each row will be aligned properly.
Defaults to C<0>.

=item html_entity

A boolean value to specify whether to escape all high-bit characters
to HTML entities or not; defaults to C<0>, which means only C<E<lt>>,
C<E<gt>>, C<"> and C<&> will be escaped. (Handy when processing most
ANSI art entries.)

=item cols

A number specifying the width of the virtual terminal; defaults to 80.

=item rows

A number specifying the height of the virtual terminal; rows that exceeds
this number will be truncated. If left unspecified, it will be recalculated
automatically on each C<ansi2html> invocation, which is probably what you
want in most cases.

=item font_face

A string used as the C<face> attribute to the C<font> tag enclosing the
HTML text; defaults to C<fixedsys, lucida console, terminal, vga, monospace>.

If this option and the C<style> option are both set to empty strings, the
C<font> tag will be omitted.

=item style

A string used as the C<style> attribute to the C<font> tag enclosing the
HTML text; defaults to <line-height: 1; letter-spacing: 0; font-size: 12pt>.

If this option and the C<font_face> option are both set to empty strings, the
C<font> tag will be omitted.

=item tt

A boolean value specifying whether the HTML text should be enclosed in a
C<tt> tag or not. Defaults to C<1>.

=item show_cursor

A boolean value to control whether to highlight the character under
the cursor position, by reversing its background and foregroud color.
Defaults to C<0>.

=cut

@EXPORT = '&ansi2html';
@EXPORT_OK = qw|@Color %Options|;

@Color = (qw(
    black   darkred darkgreen),'#8b8b00',qw(darkblue darkmagenta darkcyan gray
    dimgray     red     green    yellow         blue     magenta     cyan white
));

%Options = (
    linewrap	=> 1,		# wrap long lines
    lf_to_crlf	=> (		# translate \n to \r\n on Unix
	$^O !~ /^(?:MSWin32|MacOS)$/
    ),
    fill_cols	=> 0,		# fill all (80) columns with space
    html_entity => 0,		# escape all HTML entities
    cols	=> 80,		# column width
    rows	=> undef,	# let ansi2html figure it out
    font_face	=> 'fixedsys, lucida console, terminal, vga, monospace',
    style	=> 'line-height: 1; letter-spacing: 0; font-size: 12pt',
    tt		=> 1,
    show_cursor	=> 0,
);

sub import {
    my $class = shift;
    while (my ($k, $v) = splice(@_, 0, 2)) {
	$Options{$k} = $v;
    }
    $class->export_to_level(1);
}

sub ansi2html {
    my $vt = Term::VT102->new(
	cols	=> $Options{cols} || 80,
	rows	=> $Options{rows} || count_lines(@_),
    );

    $vt->option_set(LINEWRAP => $Options{linewrap});
    $vt->option_set(LFTOCRLF => $Options{lf_to_crlf});
    $vt->process($_) for @_;

    my $result = parse_vt($vt);

    if (length $Options{font_face} or length $Options{style}) {
	$result = "<font face='$Options{font_face}' style='$Options{style}'>".
	          $result."</font>";
    }

    $result = "<tt>$result</tt>" if $Options{tt};

    return $result;
}

sub count_lines {
    my $lines = 0;

    for (map { split(/\n/) } join('', @_)) {
	s/\x1b\[[^a-zA-Z]*[a-zA-Z]//g;
	$lines += int(length($_) / 80) + 1;
    }

    return $lines;
}

sub parse_vt {
    my $vt = shift;
    my (%prev, %this); # attributes
    my $out;

    my ($x, $y) = ($vt->x, $vt->y);

    for (1 .. $vt->rows) {
	local $SIG{__WARN__} = sub {}; # abandon all hope, ye who enter here

	my $row = $vt->row_text($_);
	my $att = $vt->row_attr($_);
	my $yok = ($_ == $y);

	for (0 .. length($row)) {
	    my $text = substr($row, $_, 1);

	    @this{qw|fg bg bo fo st ul bl rv|} = $vt->attr_unpack(
		substr($att, $_ * 2, 2)
	    );

	    if ($yok and $x == $_ + 1) {
		@this{qw|fg bg bo bl|} = (@this{qw|bg fg bl bo|});
		$text = ' ' if $text eq '\000';
	    }
	    elsif ($text eq "\000") {
		next unless $Options{fill_cols};
	    }

	    $out .= diff_attr(\%prev, \%this) . (
		($text eq ' ' or $text eq "\000") ? '&nbsp;' :
		$Options{html_entity} ? encode_entities($text)
		: encode_entities($text, '<>"&')
	    );

	    %prev = %this;
	}

	$out .= "<br>";
    } 

    return "$out</span>";
}

sub diff_attr {
    my ($prev, $this) = @_;
    my $out = '';

    # skip if the attributes remain unchanged
    return if %{$prev} and not scalar (grep {
	($_->[0] ne $_->[1])
    } map {
	[ $prev->{$_}, $this->{$_} ]
    } keys %{$this});

    # bold, faint, standout, underline, blink and reverse 
    my ($fg, $bg, $bo, $fo, $st, $ul, $bl, $rv)
	= @{$this}{qw|fg bg bo fo st ul bl rv|};

    ($fg, $bg) = ($bg, $fg) if $rv;

    $out .= "</span>" if %{$prev};
    $out .= "<span style='";
    $out .= "color: $Color[$this->{fg} + $this->{bo} * 8]; ";
    $out .= "background: $Color[$this->{bg} + $this->{bl} * 8]; ";
    $out .= "text-decoration: underline; " if $this->{ul};
    $out .= "'>";

    return $out;
}

1;

__END__

=head1 SEE ALSO

L<Term::VT102>, L<HTML::Entities>, L<Term::ANSIScreen>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2001, 2002, 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
