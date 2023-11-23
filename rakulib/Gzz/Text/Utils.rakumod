unit module Gzz::Text::Utils:ver<0.1.0>:auth<Francis Grizzly Smit (grizzlysmit@smit.id.au)>;

=begin pod

=NAME Gzz::Text::Utils 
=AUTHOR Francis Grizzly Smit (grizzly@smit.id.au)
=VERSION 0.1.0
=TITLE Gzz::Text::Utils
=SUBTITLE A Raku module to provide text formating services to Raku progarms.

=COPYRIGHT
GPL V3+ L<LICENSE>


=head1 Motivations

When you in-bed formatting information into your text such as B<bold>, I<italics>, etc ... and B<colours>
standard text formatting will not work e.g. printf, sprintf etc also those functions don't do centring.

Another important thing to note is that even these functions will fail if you include such formatting
in the B<text> field unless you supply a copy of the text with out the formatting characters in it 
in the B<:ref> field i.e. B<C<left($formatted-text, $width, :ref($unformatted-text))>> or 
B<C<text($formatted-text, $width, :$ref)>> if the reference text is in a variable called B<C<$ref>>
or you can write it as B«C«left($formatted-text, $width, ref => $unformatted-text)»»

=end pod

use Terminal::Width;
use Terminal::WCWidth;

sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = $text --> Str) is export {
    my Str $result = $text;
    $width -= wcswidth($ref);
    $width = $width div wcswidth($fill);
    my Int:D $w  = $width div 2;
    $result = $fill x $w ~ $result ~ $fill x ($width - $w);
    return $result;
} # sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = $text --> Str) is export #

sub left(Str:D $text, Int:D $width, Str:D $fill = ' ', Str:D :$ref = $text --> Str) is export {
    my Int:D $w  = wcswidth($ref);
    my Int:D $l  = ($width - $w).abs;
    my Str:D $result = $text ~ ($fill x $l);
    return $result;
} # sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = $text --> Str) is export #

sub right(Str:D $text, Int:D $width, Str:D $fill = ' ', Str:D :$ref = $text --> Str) is export {
    my Int:D $w  = wcswidth($ref);
    my Int:D $l  = ($width - $w).abs;
    my Str:D $result = ($fill x $l) ~ $text;
    return $result;
} # sub right(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = $text --> Str) is export #

