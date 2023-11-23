unit module Gzz::Text::Utils:ver<0.1.0>:auth<Francis Grizzly Smit (grizzlysmit@smit.id.au)>;

=begin pod

=NAME Gzz::Text::Utils 
=AUTHOR Francis Grizzly Smit (grizzly@smit.id.au)
=VERSION 0.1.0
=TITLE Gzz::Text::Utils
=SUBTITLE A Raku module to provide text formating services to Raku progarms.

=COPYRIGHT
GPL V3.0+ L<LICENSE|https://github.com/grizzlysmit/Gzz-Text-Utils/blob/main/LICENSE>

=head2 Introduction

A Raku module to provide text formatting services to Raku programs.

=head3 Motivations

When you in-bed formatting information into your text such as B<bold>, I<italics>, etc ... and B<colours>
standard text formatting will not work e.g. printf, sprintf etc also those functions don't do centring.

Another important thing to note is that even these functions will fail if you include such formatting
in the B<text> field unless you supply a copy of the text with out the formatting characters in it 
in the B<:ref> field i.e. B<C<left($formatted-text, $width, :ref($unformatted-text))>> or 
B<C<text($formatted-text, $width, :$ref)>> if the reference text is in a variable called B<C<$ref>>
or you can write it as B«C«left($formatted-text, $width, ref => $unformatted-text)»»

=head2 The functions Provided.

Currently there are 3 functions provided 

=item B«C«sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = $text --> Str)»»

=item B«C«sub left(Str:D $text, Int:D $width, Str:D $fill = ' ', Str:D :$ref = $text --> Str)»»

=item B«C«sub right(Str:D $text, Int:D $width, Str:D $fill = ' ', Str:D :$ref = $text --> Str)»»

=item B<C<centre>> centres the text B<C<$text>> in a field of width B<C<$width>> padding either side with B<C<$fill>>
by default B<C<$fill>> is set to a single white space; do not set it to any string that is longer than 1 
code point,  or it will fail to behave correctly. If  it requires an on number padding then the right hand
side will get one more char/codepoint. The parameter B<C<:$ref>> is by default set to the value of B<C<$text>>
this is used to obtain the length of the of the text using B<I<C<wcswidth(Str)>>> which is used to obtain the 
width the text if printed on the current terminal: B<NB: C<wcswidth> will return -1 if you pass it text with
colours etc in-bedded in them>.

=item B<C<left>> is the same except that except that it puts all the  padding on the right of the field.

=item B<C<right>> is again the same except it puts all the padding on the left and the text to the right.

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

