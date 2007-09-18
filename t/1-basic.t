#!/usr/bin/perl -w
# $File: //member/autrijus/HTML-FromANSI/t/1-basic.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 7866 $ $DateTime: 2003/09/04 17:10:17 $

use strict;
use Test::More tests => 2;

use_ok('HTML::FromANSI', show_cursor => 1);

my $text = ansi2html("\x1b[1;34m", "This text is bold blue.");
open FH, '>', '/home/autrijus/test.html';
print FH $text;
close FH;

is($text, join('', split("\n", << '.')), 'basic conversion');
<tt><font
 face='fixedsys, lucida console, terminal, vga, monospace'
 style='line-height: 1; letter-spacing: 0; font-size: 12pt'
><span style='color: blue; background: black; '>
This&nbsp;text&nbsp;is&nbsp;bold&nbsp;blue.</span>
<span style='color: black; background: gray; '>&nbsp;</span>
<span style='color: black; background: black; '><br></span>
</font></tt>
.
