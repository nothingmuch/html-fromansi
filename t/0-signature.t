#!/usr/bin/perl
# $File: //member/autrijus/HTML-FromANSI/t/0-signature.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 7868 $ $DateTime: 2003/09/04 17:24:14 $

use strict;
use Test::More tests => 1;

SKIP: {
    if (!eval { require Module::Signature; 1 }) {
	skip("Next time around, consider install Module::Signature, ".
	     "so you can verify the integrity of this distribution.", 1);
    }
    elsif (!eval { require Socket; Socket::inet_aton('pgp.mit.edu') }) {
	skip("Cannot connect to the keyserver", 1);
    }
    else {
	ok(Module::Signature::verify() == Module::Signature::SIGNATURE_OK()
	    => "Valid signature" );
    }
}

__END__
