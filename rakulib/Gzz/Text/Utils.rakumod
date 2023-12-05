unit module Gzz::Text::Utils:ver<0.1.0>:auth<Francis Grizzly Smit (grizzlysmit@smit.id.au)>;

=begin pod

=begin head2

Table of  Contents

=end head2

=item L<NAME|#name>
=item L<AUTHOR|#author>
=item L<VERSION|#version>
=item L<TITLE|#title>
=item L<SUBTITLE|#subtitle>
=item L<COPYRIGHT|#copyright>
=item L<Introduction|#introduction>
=item2 L<Motivations|#motivations>
=item3 L<Update|#update>
=item L<Exceptions|#exceptions>
=item2 L<BadArg|#badarg>
=item2 L<ArgParityMissMatch|#argparitymissmatch>
=item2 L<FormatSpecError|#formatspecerror>
=item2 L<C<UnhighlightBase> & C<UnhighlightBaseActions> and C<Unhighlight> & C<UnhighlightActions>|#unhighlightbase--unhighlightbaseactions-and-unhighlight--unhighlightactions>
=item2 L<The Functions Provided|#the-functions-provided>

=begin item2
L<Here are 4 functions provided  to B<C<centre>>, B<C<left>> and B<C<right>> justify text even when it is ANSI formatted|#here-are-4-functions-provided-to-centre-left-and-right-justify-text-even-when-it-is-ansi-formatted>
=end item2

=item2 L<Sprintf|#sprintf>
=item2 L<Printf|#printf>

=NAME Gzz::Text::Utils 
=AUTHOR Francis Grizzly Smit (grizzly@smit.id.au)
=VERSION 0.1.4
=TITLE Gzz::Text::Utils
=SUBTITLE A Raku module to provide text formatting services to Raku programs.

=COPYRIGHT
GPL V3.0+ L<LICENSE|https://github.com/grizzlysmit/Gzz-Text-Utils/blob/main/LICENSE>

=head1 Introduction

A Raku module to provide text formatting services to Raku programs.

Including a sprintf front-end Sprintf that copes better with Ansi highlighted
text and implements B<C<%U>> and does octal as B<C<0o123>> or B<C<0O123>> if
you choose B<C<%O>> as I hate ambiguity like B<C<0123>> is it an int with
leading zeros or an octal number.
Also there is B<C<%N>> for a new line and B<C<%T>> for a tab helpful when
you want to use single quotes to stop the B<numC<$>> specs needing back slashes.

L<Top of Document|#>

=head2 Motivations

When you embed formatting information into your text such as B<bold>, I<italics>, etc ... and B<colours>
standard text formatting will not work e.g. printf, sprintf etc also those functions don't do centring.

Another important thing to note is that even these functions will fail if you include such formatting
in the B<text> field unless you supply a copy of the text with out the formatting characters in it 
in the B<:ref> field i.e. B<C<left($formatted-text, $width, :ref($unformatted-text))>> or 
B<C<text($formatted-text, $width, :$ref)>> if the reference text is in a variable called B<C<$ref>>
or you can write it as B«C«left($formatted-text, $width, ref => $unformatted-text)»»

L<Top of Document|#>

=head3 Update

Fixed the proto type of B<C<left>> etc is now 

=begin code :lang<raku>
sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export
=end code

Where B«C«sub strip-ansi(Str:D $text --> Str:D) is export»» is my new function for striping out ANSI escape sequences so we don't need to supply 
B<C<:$ref>> unless it contains codes that B«C«sub strip-ansi(Str:D $text --> Str:D) is export»» cannot strip out, if so I would like to know so
I can update it to cope with these new codes.

L<Top of Document|#>

=end pod

INIT my $debug = False;
####################################
#                                  #
#  To turn On or Off debugging     #
#  Comment or Uncomment this       #
#  following line.                 #
#                                  #
####################################
#INIT $debug = True; use Grammar::Debugger;

#use Grammar::Tracer;
INIT "Grammar::Debugger is on".say if $debug;

use Terminal::Width;
use Terminal::WCWidth;

=begin pod

=head1 Exceptions

=head2 BadArg

 
=begin code :lang<raku>
 
class BadArg is Exception is export
 
=end code
 
BadArg is a exception type that Sprintf will throw in case of badly specified arguments.

L<Top of Document|#>
 

=end pod

class BadArg is Exception is export {
    has Str:D $.msg = 'Error: bad argument found';
    method message( --> Str:D) {
        $!msg;
    }
}

=begin pod

=head2 ArgParityMissMatch

=begin code :lang<raku>

class ArgParityMissMatch is Exception is export

=end code

ArgParityMissMatch is an exception class that Sprintf throws if the number of arguments
does not match what the number the format string says there should be.

B<NB: if you use I<C<num$>> argument specs these will not count as they grab from the
args add hoc, I<C<*>> width and precision spec however do count as they consume argument.>

=end pod

class ArgParityMissMatch is Exception is export {
    has Str:D $.msg = 'Error: argument paraity error found';
    method message( --> Str:D) {
        $!msg;
    }
}

=begin pod

L<Top of Document|#>

=head2 FormatSpecError

=begin code :lang<raku>

class FormatSpecError is Exception is export

=end code

FormatSpecError is an exception class that Format (used by Sprintf) throws if there is an
error in the Format specification (i.e. B<C<%n>> instead of B<C<%N>> as B<C<%n>> is already
taken, the same with using B<C<%t>> instead of B<C<%T>>).

Or anything else wrong with the Format specifier.

B<NB: I<C<%N>> introduces a I<C<\n>> character and I<C<%T>> a tab (i.e. I<C<\t>>).>

=end pod

class FormatSpecError is Exception is export {
    has Str:D $.msg = 'Error: argument paraity error found';
    method message( --> Str:D) {
        $!msg;
    }
}
#`««
if $*RAKU.compiler.name ne 'rakudo' {
    sub dd(*@args) is export {
        say @args».raku.join("\n");
    }
}
#»»

=begin pod

L<Top of Document|#>

=head1 Format and FormatActions

Format & FormatActions are a grammar and Actions pair that parse out the B<%> spec and normal text chunks of a format string.

For use by Sprintf a sprintf alternative that copes with ANSI highlighted text.

=end pod

grammar FormatBase {
    token format            { <chunks>+ }
    token chunks            { [ <chunk> || '%' <format-spec> ] }
    token chunk             { <-[%]>+ }
    token format-spec       { [ <fmt-esc> || <fmt-spec> ] }
    token fmt-esc           { [      '%' #`« a literal % »
                                  || 'N' #`« a nl i.e. \n char but does not require interpolation so no double quotes required »
                                  || 'T' #`« a tab i.e. \t char but does not require interpolation so no double quotes required »
                                  || 'n' #`« not implemented and will not be »
                                  || 't' #`« not implemented and will not be »
                              ]
                            }
    token fmt-spec          { [ <false-flags>? <dollar-directive> '$' ]? <flags>?  <width>? [ '.' <precision> [ '.' <max-width> ]? ]? <modifier>? <spec-char> }
    token false-flags       { [ <false-flag>+ <?before \d+ '$' > ] } #`«« make sure that we don't see flags
                                                                          before the <dollar-directive> '$' »»
    token false-flag        { [ '+' || '^' || '-' || '#' || 'v' || '0' || ' ' || '[' <-[ <cntrl> \s \[ \] ]>+ ']' ] }
    token dollar-directive  { \d+ <?before '$'> }
    token flags             { [ [ <flag> ** {1 .. 20} ] <!before \d+ '$' > ] }
    token flag              { [ <force-sign> || <justify> || <type-prefix> || <vector> || <padding> ] }
    token force-sign        { '+' } #`« put a plus in front of positive values »
    token justify           { [     '-' #`« left justify right is the default »
                                 || '^' #`« centre justify »
                              ]
                            }
    token type-prefix       { '#' #`« ensure the leading "0" for any octal, prefix non-zero hexadecimal with "0x"
                                              or "0X", prefix non-zero binary with "0b" or "0B" »
                            }
    token vector            { 'v' #`« vector flag (used only with d directive) » }
    token padding           { [ <old-padding> || '[' <arbitrary-padding> ']' ] }
    token old-padding       { [ '0' || ' ' ] }
    token arbitrary-padding { [ <-[ <cntrl> \s \[ \] ]>+ || ' '+ ] }
    token width             { [ '*' [ <width-dollar> '$' ]? || <width-int> ] }
    token width-dollar      { \d+ <?before '$'> }
    token width-int         { \d+ }
    token precision         { [ '*' [ <prec-dollar> '$' ]?  || <prec-int>  ] }
    token prec-dollar       { \d+ <?before '$'> }
    token prec-int          { \d+ }
    token max-width         { [ '*' [ <max-dollar> '$' ]?  || <max-int>  ] }
    token max-dollar        { \d+ <?before '$'> }
    token max-int           { \d+ }
    token modifier          { [           #`« (Note: None of the following have been implemented.) »
                                     'hh' #`« interpret integer as a type "char" or "unsigned char" »
                                  || 'h'  #`« interpret integer as a type "short" or "unsigned short" »
                                  || 'j'  #`« interpret integer as a type "intmax_t", only with a C99 compiler (unportable) »
                                  || 'l'  #`« interpret integer as a type "long" or "unsigned long" »
                                  || 'll' #`« interpret integer as a type "long long", "unsigned long long", or "quad" (typically 64-bit integers) »
                                  || 'q'  #`« interpret integer as a type "long long", "unsigned long long", or "quad" (typically 64-bit integers) »
                                  || 'L'  #`« interpret integer as a type "long long", "unsigned long long", or "quad" (typically 64-bit integers) »
                                  || 't'  #`« interpret integer as a type "ptrdiff_t" »
                                  || 'z'  #`« interpret integer as a type "size_t" »
                             ]
                            }
    token spec-char         { [      'c' #`« a character with the given codepoint »
                                  || 's' #`« a string »
                                  || 'd' #`« a signed integer, in decimal »
                                  || 'u' #`« an unsigned integer, in decimal »
                                  || 'o' #`« an unsigned integer, in octal »
                                  || 'x' #`« an unsigned integer, in hexadecimal »
                                  || 'e' #`« a floating-point number, in scientific notation »
                                  || 'f' #`« a floating-point number, in fixed decimal notation »
                                  || 'g' #`« a floating-point number, in %e or %f notation »
                                  || 'X' #`« like x, but using uppercase letters »
                                  || 'E' #`« like e, but using an uppercase "E" »
                                  || 'G' #`« like g, but with an uppercase "E" (if applicable) »
                                  || 'b' #`« an unsigned integer, in binary »
                                  || 'B' #`« an unsigned integer, in binary »
                                         #`« Compatibility: »
                                  || 'i' #`« a synonym for %d »
                                  || 'D' #`« a synonym for %ld »
                                  || 'U' #`« a synonym for %lu »
                                  || 'O' #`« a synonym for %lo »
                                  || 'F' #`« a synonym for %f »
                              ]
                            }
} # grammar FormatBase #

role FormatBaseActions {
    method false-flag($/) {
        my $false-flag = ~$/;
        dd $false-flag if $debug;
        make $false-flag;
    }
    method false-flags($/) {
        my $false-flags = $/<false-flag>».made;
        dd $false-flags if $debug;
        FormatSpecError.new(:msg("Error flags belong after <number> '\$' spec not before.")).throw;
        make $false-flags;
    }
    method dollar-directive($/) {
        my Int $dollar-directive = +$/ - 1;
        FormatSpecError.new(:msg("bad \$ spec for arg: cannot be less than 1 ")).throw if $dollar-directive < 0;
        dd $dollar-directive if $debug;
        make $dollar-directive;
    }
    method flags($/) {
        my @flags = $/<flag>».made;
        dd @flags if $debug;
        make @flags;
    }
    #token force-sign        { '+' } #`« put a plus in front of positive values »
    method force-sign($/) {
        my $force-sign = ~$/;
        dd $force-sign if $debug;
        make $force-sign;
    }
    #token justify           { [     '-' #`« left justify right is the default »
    #                             || '^' #`« centre justify »
    #                          ]
    #                        }
    method justify($/) {
        my $justify = ~$/;
        dd $justify if $debug;
        make $justify;
    }
    #token type-prefix       { '#' #`« ensure the leading "0" for any octal, prefix non-zero hexadecimal with "0x"
    #                                          or "0X", prefix non-zero binary with "0b" or "0B" »
    #                        }
    method type-prefix($/) {
        my $type-prefix = ~$/;
        dd $type-prefix if $debug;
        make $type-prefix;
    }
    #token vector            { 'v' #`« vector flag (used only with d directive) » }
    method vector($/) {
        my $vector = ~$/;
        dd $vector if $debug;
        make $vector;
    }
    #token old-padding       { [ '0' || ' ' ] }
    method old-padding($/) {
        my $old-padding = ~$/;
        dd $old-padding if $debug;
        make $old-padding;
    }
    #token arbitrary-padding { [ <-[ <cntrl> \s \[ \] ]>+ || ' ' ] }
    method arbitrary-padding($/) {
        my $arbitrary-padding = ~$/;
        if $arbitrary-padding.codes != 1 {
            my Str:D $msg = "Error: should only contain one codepoint/character you supplied {$arbitrary-padding.codes}: [$arbitrary-padding]";
            FormatSpecError.new(:$msg).throw;
        }
        dd $arbitrary-padding if $debug;
        make $arbitrary-padding;
    }
    #token padding           { [ <old-padding> || '[' <arbitrary-padding> ']' ] }
    method padding($/) {
        my $padding;
        if $/<old-padding> {
            $padding = $/<old-padding>.made;
        } elsif $/<arbitrary-padding> {
            $padding = $/<arbitrary-padding>.made;
        }
        dd $padding if $debug;
        make $padding;
    }
    #token flag              { [ <force-sign> || <justify> || <type-prefix> || <vector> || <padding> ] }
    method flag($/) {
        my %flag;
        if $/<force-sign> {
            %flag = kind => 'force-sign', val => $/<force-sign>.made;
        } elsif $/<justify> {
            %flag = kind => 'justify', val => $/<justify>.made;
        } elsif $/<type-prefix> {
            %flag = kind => 'type-prefix', val => $/<type-prefix>.made;
        } elsif $/<vector> {
            %flag = kind => 'vector', val => $/<vector>.made;
        } elsif $/<padding> {
            %flag = kind => 'padding', val => $/<padding>.made;
        }
        dd %flag if $debug;
        make %flag;
    }
    #token width            { [ '*' [ <width-dollar> '$' ]? || <width-int> ] }
    #token width-dollar     { \d+ }
    #token width-int        { \d+ }
    method width-dollar($/) {
        my Int:D $width-dollar = +$/ - 1;
        BadArg.new(:msg("bad \$ spec for width: cannot be less than 1 ")).throw if $width-dollar < 0;
        dd $width-dollar if $debug;
        make $width-dollar;
    }
    method width-int($/) {
        my Int:D $width-int = +$/;
        dd $width-int if $debug;
        make $width-int;
    }
    method width($/) {
        my %width = kind => 'star', val => 0;
        if $/<width-dollar> {
            %width = kind => 'dollar', val => $/<width-dollar>.made;
        } elsif $/<width-int> {
            %width = kind => 'int', val => $/<width-int>.made;
        }
        dd %width if $debug;
        make %width;
    }
    #token prec-dollar      { \d+ }
    method prec-dollar($/) {
        my Int:D $prec-dollar = +$/ - 1;
        FormatSpecError.new(:msg("bad \$ spec for precision: cannot be less than 1 ")).throw if $prec-dollar < 0;
        dd $prec-dollar if $debug;
        make $prec-dollar;
    }
    #token prec-int         { \d+ }
    method prec-int($/) {
        my Int:D $prec-int = +$/;
        dd $prec-int if $debug;
        make $prec-int;
    }
    #token precision        { [ '*' [ <prec-dollar> '$' ]?  || <prec-int>  ] }
    method precision($/) {
        my %precision = kind => 'star', val => 0;
        if $/<prec-dollar> {
            %precision = kind => 'dollar', val => $/<prec-dollar>.made;
        } elsif $/<prec-int> {
            %precision = kind => 'int', val => $/<prec-int>.made;
        }
        dd %precision if $debug;
        make %precision;
    }
    #token max-dollar        { \d+ <?before '$'> }
    method max-dollar($/) {
        my Int:D $max-dollar = +$/ - 1;
        FormatSpecError.new(:msg("bad \$ spec for max-width: cannot be less than 1 ")).throw if $max-dollar < 0;
        dd $max-dollar if $debug;
        make $max-dollar;
    }
    #token max-int           { \d+ }
    method max-int($/) {
        my Int:D $max-int = +$/;
        dd $max-int if $debug;
        make $max-int;
    }
    #token max-width         { [ '*' [ <max-dollar> '$' ]?  || <max-int>  ] }
    method max-width($/) {
        my %max-width = kind => 'star', val => 0;
        if $/<max-dollar> {
            %max-width = kind => 'dollar', val => $/<max-dollar>.made;
        } elsif $/<max-int> {
            %max-width = kind => 'int', val => $/<max-int>.made;
        }
        dd %max-width if $debug;
        make %max-width;
    }
    method modifier($/) {
        my Str $modifier = ~$/;
        dd $modifier if $debug;
        make $modifier;
    }
    method spec-char($/) {
        my Str:D $spec-char = ~$/;
        dd $spec-char if $debug;
        make $spec-char;
    }
    #token fmt-esc           { [      '%' #`« a literal % »
    #                              || 'N' #`« a nl i.e. \n char but does not require interpolation so no double quotes required »
    #                              || 'T' #`« a tab i.e. \t char but does not require interpolation so no double quotes required »
    #                              || 'n' #`« not implemented and will not be »
    #                              || 't' #`« not implemented and will not be »
    #                          ]
    #                        }
    method fmt-esc($/) {
        my %fmt-esc = type => 'literal', val => ~$/;
        %fmt-esc«val» = "\n" if %fmt-esc«val» eq 'N'; # %N gives us an newline saves on needing double quotes #
        %fmt-esc«val» = "\t" if %fmt-esc«val» eq 'T'; # %T gives us an tab saves on needing double quotes #
        dd %fmt-esc if $debug;
        FormatSpecError.new(:msg("%n not implemented and will not be; did you mean %N.")).throw if %fmt-esc«val» eq 'n'; # not implemented and will not be. #
        FormatSpecError.new(:msg("%t not implemented and will not be; did you mean %T.")).throw if %fmt-esc«val» eq 't'; # not implemented and will not be. #
        make %fmt-esc;
    }
    #token fmt-spec          { [ <dollar-directive> '$' ]? <flags>?  <width>? [ '.' <precision> [ '.' <max-width> ]? ]? <modifier>? <spec-char> }
    method fmt-spec($/) {
        my %fmt-spec = type => 'fmt-spec', dollar-directive => -1, flags => [],
                                  width => { kind => 'empty', val => 0, },
                                    precision => { kind => 'empty', val => 0, },
                                       max-width => { kind => 'empty', val => 0},
                                         modifier => '', spec-char => $/<spec-char>.made;
        if $/<dollar-directive> {
            %fmt-spec«dollar-directive» = $/<dollar-directive>.made;
        }
        if $/<flags> {
            %fmt-spec«flags» = $/<flags>.made;
        }
        if $/<width> {
            %fmt-spec«width» = $/<width>.made;
        }
        if $/<precision> {
            %fmt-spec«precision» = $/<precision>.made;
        }
        if $/<max-width> {
            %fmt-spec«max-width» = $/<max-width>.made;
        }
        if $/<modifier> {
            %fmt-spec«modifier» = $/<modifier>.made;
        }
        dd %fmt-spec if $debug;
        make %fmt-spec;
    }
    #token format-spec      { [ <fmt-esc> || <fmt-spec> ] }
    method format-spec($/) {
        my %format-spec;
        if $/<fmt-esc> {
            %format-spec = $/<fmt-esc>.made;
        } elsif $/<fmt-spec> {
            %format-spec = $/<fmt-spec>.made;
        }
        dd %format-spec if $debug;
        make %format-spec;
    }
    #token chunk            { <-[%]>+ }
    method chunk($/) {
        my %chunk = type => 'literal', val => ~$/;
        dd %chunk if $debug;
        make %chunk;
    }
    #token chunks           { [ <chunk> || '%' <format-spec> ] }
    method chunks($/) {
        my %chunks;
        if $/<chunk> {
            %chunks = $<chunk>.made;
        } elsif $/<format-spec> {
            %chunks = $/<format-spec>.made;
        }
        dd %chunks if $debug;
        make %chunks;
    }
    #token format           { <chunks>+ }
    method format($/) {
        my @format = $/<chunks>».made;
        dd @format if $debug;
        make @format;
    }
} # role FormatBaseActions #

grammar Format is FormatBase is export {
    token TOP      { ^ <format> $ }
}

class FormatActions does FormatBaseActions is export {
    method TOP($made) {
        my @top = $made<format>.made;
        dd @top if $debug;
        $made.make: @top;
    }
} # class FormatActions does FormatBaseActions is export # 

=begin pod

L<Top of Document|#>

=head2 C<UnhighlightBase> & C<UnhighlightBaseActions> and C<Unhighlight> & C<UnhighlightActions>

B<C<UnhighlightBase>> & B<C<UnhighlightBaseActions>> are a grammar & role pair that does the work required to 
to parse apart ansi highlighted text into ANSI highlighted and plain text. 

B<C<Unhighlight>> & B<C<UnhighlightActions>> are a grammar & class pair which provide a simple TOP for applying
an application of B<C<UnhighlightBase>> & B<C<UnhighlightBaseActions>>  for use by
B<C<sub strip-ansi(Str:D $text --> Str:D) is export>> to strip out the plain text from a ANSI formatted string

=end pod

grammar UnhighlightBase is export {
    token text           { ^ [  <empty> <!before . > || <block> ] $ } #`««« the <!before .+ > is vital here as
                                                                             otherwise empty will match before
                                                                             anything, and the whole match will
                                                                             fail, otherwise one could put
                                                                             <block> before <empty> but then
                                                                             we will need to do more work whereas
                                                                             <empty> <!before . > succeeds or
                                                                             fails much more quickly »»»
    token block          { <chunks>+ }
    token empty          { '' }
    token chunks         { [ <chunk> || <ansi> ] }
    token chunk          { <-[ \x[1B] ]>+ }
    token ansi           { [ <clear-screen> || <home> || <move-to> || <reset-scroll-region>
                             || <set-scroll-region> || <scroll-down> || <scroll-up>
                             || <save-screen> || <hide-cursor> || <restore-screen>
                             || <show-cursor> || <cursor-up> || <cursor-down>
                             || <cursor-right> || <cursor-left> | <cursor-next-line>
                             || <cursor-prev-line> || <print-at> || <set-fg-color>
                             || <set-fg-rgb-color> || <set-bg-color> || <set-bg-rgb-color>
                             || <set-bg-default> || <save-cursor> || <restore-cursor>
                             || <start-of-line> || <erase-to-end-of-line> || <normal-video> 
                             || <bold> || <faint> || <italic> || <underline> || <blink>
                             || <reverse-video> || <strike> || <alt-font>
                           ]
                         }
    token clear-screen         { "\e[H\e[J" }
    token home                 { "\e[H" }
    token move-to              { "\e[" \d+ ';' \d+ 'H' }
    token reset-scroll-region  { "\e[r" }
    token set-scroll-region    { "\e[" \d+ ';' \d+ 'r' }
    token scroll-down          { "\e[M" }
    token scroll-up            { "\e[D" }
    token hide-cursor          { "\e[?25l" }
    token save-screen          { "\e[?1049h" }
    token restore-screen       { "\e[?1049l" }
    token show-cursor          { "\e[25h" }
    token cursor-up            { "\e[" \d+ 'A' }
    token cursor-down          { "\e[" \d+ 'B' }
    token cursor-right         { "\e[" \d+ 'C' }
    token cursor-left          { "\e[" \d+ 'D' }
    token cursor-next-line     { "\e[" \d+ 'E' }
    token cursor-prev-line     { "\e[" \d+ 'F' }
    token print-at             { "\e[" \d+ ';' \d+ 'H' }
    token set-fg-color         { "\e[38;5;" \d+ 'm' }
    token set-fg-rgb-color     { "\e[38;2;" \d+ ';' \d+ ';' \d+ 'm' }
    token set-bg-color         { "\e[48;5;" \d+ 'm' }
    token set-bg-rgb-color     { "\e[48;2;" \d+ ';' \d+ ';' \d+ 'm' }
    token set-bg-default       { "\e[49;m" }
    token save-cursor          { "\e[s" }
    token restore-cursor       { "\e[u" }
    token start-of-line        { "\e[\r" }
    token erase-to-end-of-line { "\e[2J" }
    token normal-video         { "\e[0m" }
    token bold                 { "\e[1m" }
    token faint                { "\e[2m" }
    token italic               { "\e[3m" }
    token underline            { "\e[4m" }
    token blink                { "\e[5m" }
    token reverse-video        { "\e[7m" }
    token strike               { "\e[9m" }
    token alt-font             { [ "\e[11m" || "\e[12m" || "\e[13m" || "\e[14m" || "\e[15m"
                                   "\e[16m" || "\e[17m" || "\e[18m" || "\e[19m" 
                                 ] }
} # grammar UnhighlightBase is export #

role UnhighlightBaseActions is export {
    method clear-screen($/) {
        my %clear-screen = type => 'ansi', sub-type => 'clear-screen', val => ~$/;
        dd %clear-screen if $debug;
        make %clear-screen;
    }
    method home($/) {
        my %home = type => 'ansi', sub-type => 'home', val => ~$/;
        dd %home if $debug;
        make %home;
    }
    method move-to($/) {
        my %move-to = type => 'ansi', sub-type => 'move-to', val => ~$/;
        dd %move-to if $debug;
        make %move-to;
    }
    method reset-scroll-region($/) {
        my %reset-scroll-region = type => 'ansi', sub-type => 'reset-scroll-region', val => ~$/;
        dd %reset-scroll-region if $debug;
        make %reset-scroll-region;
    }
    method set-scroll-region($/) {
        my %set-scroll-region = type => 'ansi', sub-type => 'set-scroll-region', val => ~$/;
        dd %set-scroll-region if $debug;
        make %set-scroll-region;
    }
    method scroll-down($/) {
        my %scroll-down = type => 'ansi', sub-type => 'scroll-down', val => ~$/;
        dd %scroll-down if $debug;
        make %scroll-down;
    }
    method scroll-up($/) {
        my %scroll-up = type => 'ansi', sub-type => 'scroll-up', val => ~$/;
        dd %scroll-up if $debug;
        make %scroll-up;
    }
    method hide-cursor($/) {
        my %hide-cursor = type => 'ansi', sub-type => 'hide-cursor', val => ~$/;
        dd %hide-cursor if $debug;
        make %hide-cursor;
    }
    method save-screen($/) {
        my %save-screen = type => 'ansi', sub-type => 'save-screen', val => ~$/;
        dd %save-screen if $debug;
        make %save-screen;
    }
    method restore-screen($/) {
        my %restore-screen = type => 'ansi', sub-type => 'restore-screen', val => ~$/;
        dd %restore-screen if $debug;
        make %restore-screen;
    }
    method show-cursor($/) {
        my %show-cursor = type => 'ansi', sub-type => 'show-cursor', val => ~$/;
        dd %show-cursor if $debug;
        make %show-cursor;
    }
    method cursor-up($/) {
        my %cursor-up = type => 'ansi', sub-type => 'cursor-up', val => ~$/;
        dd %cursor-up if $debug;
        make %cursor-up;
    }
    method cursor-down($/) {
        my %cursor-down = type => 'ansi', sub-type => 'cursor-down', val => ~$/;
        dd %cursor-down if $debug;
        make %cursor-down;
    }
    method cursor-right($/) {
        my %cursor-right = type => 'ansi', sub-type => 'cursor-right', val => ~$/;
        dd %cursor-right if $debug;
        make %cursor-right;
    }
    method cursor-left($/) {
        my %cursor-left = type => 'ansi', sub-type => 'cursor-left', val => ~$/;
        dd %cursor-left if $debug;
        make %cursor-left;
    }
    method cursor-next-line($/) {
        my %cursor-next-line = type => 'ansi', sub-type => 'cursor-next-line', val => ~$/;
        dd %cursor-next-line if $debug;
        make %cursor-next-line;
    }
    method cursor-prev-line($/) {
        my %cursor-prev-line = type => 'ansi', sub-type => 'cursor-prev-line', val => ~$/;
        dd %cursor-prev-line if $debug;
        make %cursor-prev-line;
    }
    method print-at($/) {
        my %print-at = type => 'ansi', sub-type => 'print-at', val => ~$/;
        dd %print-at if $debug;
        make %print-at;
    }
    method set-fg-color($/) {
        my %set-fg-color = type => 'ansi', sub-type => 'set-fg-color', val => ~$/;
        dd %set-fg-color if $debug;
        make %set-fg-color;
    }
    method set-fg-rgb-color($/) {
        my %set-fg-rgb-color = type => 'ansi', sub-type => 'set-fg-rgb-color', val => ~$/;
        dd %set-fg-rgb-color if $debug;
        make %set-fg-rgb-color;
    }
    method set-bg-color($/) {
        my %set-bg-color = type => 'ansi', sub-type => 'set-bg-color', val => ~$/;
        dd %set-bg-color if $debug;
        make %set-bg-color;
    }
    method set-bg-rgb-color($/) {
        my %set-bg-rgb-color = type => 'ansi', sub-type => 'set-bg-rgb-color', val => ~$/;
        dd %set-bg-rgb-color if $debug;
        make %set-bg-rgb-color;
    }
    method set-bg-default($/) {
        my %set-bg-default = type => 'ansi', sub-type => 'set-bg-default', val => ~$/;
        dd %set-bg-default if $debug;
        make %set-bg-default;
    }
    method save-cursor($/) {
        my %save-cursor = type => 'ansi', sub-type => 'save-cursor', val => ~$/;
        dd %save-cursor if $debug;
        make %save-cursor;
    }
    method restore-cursor($/) {
        my %restore-cursor = type => 'ansi', sub-type => 'restore-cursor', val => ~$/;
        dd %restore-cursor if $debug;
        make %restore-cursor;
    }
    method start-of-line($/) {
        my %start-of-line = type => 'ansi', sub-type => 'start-of-line', val => ~$/;
        dd %start-of-line if $debug;
        make %start-of-line;
    }
    method erase-to-end-of-line($/) {
        my %erase-to-end-of-line = type => 'ansi', sub-type => 'erase-to-end-of-line', val => ~$/;
        dd %erase-to-end-of-line if $debug;
        make %erase-to-end-of-line;
    }
    method normal-video($/) {
        my %normal-video = type => 'ansi', sub-type => 'normal-video', val => ~$/;
        dd %normal-video if $debug;
        make %normal-video;
    }
    method bold($/) {
        my %bold = type => 'ansi', sub-type => 'bold', val => ~$/;
        dd %bold if $debug;
        make %bold;
    }
    method faint($/) {
        my %faint = type => 'ansi', sub-type => 'faint', val => ~$/;
        dd %faint if $debug;
        make %faint;
    }
    method italic($/) {
        my %italic = type => 'ansi', sub-type => 'italic', val => ~$/;
        dd %italic if $debug;
        make %italic;
    }
    method underline($/) {
        my %underline = type => 'ansi', sub-type => 'underline', val => ~$/;
        dd %underline if $debug;
        make %underline;
    }
    method blink($/) {
        my %blink = type => 'ansi', sub-type => 'blink', val => ~$/;
        dd %blink if $debug;
        make %blink;
    }
    method reverse-video($/) {
        my %reverse-video = type => 'ansi', sub-type => 'reverse-video', val => ~$/;
        dd %reverse-video if $debug;
        make %reverse-video;
    }
    method strike($/) {
        my %strike = type => 'ansi', sub-type => 'strike', val => ~$/;
        dd %strike if $debug;
        make %strike;
    }
    method alt-font($/) {
        my %alt-font = type => 'ansi', sub-type => 'alt-font', val => ~$/;
        dd %alt-font if $debug;
        make %alt-font;
    }
    method ansi($/) {
        my %ansi;
        if $/<clear-screen> {
            %ansi = $/<clear-screen>.made;
        } elsif $/<home> {
            %ansi = $/<home>.made;
        } elsif $/<move-to> {
            %ansi = $/<move-to>.made;
        } elsif $/<reset-scroll-region> {
            %ansi = $/<reset-scroll-region>.made;
        } elsif $/<set-scroll-region> {
            %ansi = $/<set-scroll-region>.made;
        } elsif $/<scroll-down> {
            %ansi = $/<scroll-down>.made;
        } elsif $/<scroll-up> {
            %ansi = $/<scroll-up>.made;
        } elsif $/<hide-cursor> {
            %ansi = $/<hide-cursor>.made;
        } elsif $/<save-screen> {
            %ansi = $/<save-screen>.made;
        } elsif $/<restore-screen> {
            %ansi = $/<restore-screen>.made;
        } elsif $/<show-cursor> {
            %ansi = $/<show-cursor>.made;
        } elsif $/<cursor-up> {
            %ansi = $/<cursor-up>.made;
        } elsif $/<cursor-down> {
            %ansi = $/<cursor-down>.made;
        } elsif $/<cursor-right> {
            %ansi = $/<cursor-right>.made;
        } elsif $/<cursor-left> {
            %ansi = $/<cursor-left>.made;
        } elsif $/<cursor-next-line> {
            %ansi = $/<cursor-next-line>.made;
        } elsif $/<cursor-prev-line> {
            %ansi = $/<cursor-prev-line>.made;
        } elsif $/<print-at> {
            %ansi = $/<print-at>.made;
        } elsif $/<set-fg-color> {
            %ansi = $/<set-fg-color>.made;
        } elsif $/<set-fg-rgb-color> {
            %ansi = $/<set-fg-rgb-color>.made;
        } elsif $/<set-bg-color> {
            %ansi = $/<set-bg-color>.made;
        } elsif $/<set-bg-rgb-color> {
            %ansi = $/<set-bg-rgb-color>.made;
        } elsif $/<set-bg-default> {
            %ansi = $/<set-bg-default>.made;
        } elsif $/<save-cursor> {
            %ansi = $/<save-cursor>.made;
        } elsif $/<restore-cursor> {
            %ansi = $/<restore-cursor>.made;
        } elsif $/<start-of-line> {
            %ansi = $/<start-of-line>.made;
        } elsif $/<erase-to-end-of-line> {
            %ansi = $/<erase-to-end-of-line>.made;
        } elsif $/<normal-video> {
            %ansi = $/<normal-video>.made;
        } elsif $/<bold> {
            %ansi = $/<bold>.made;
        } elsif $/<faint> {
            %ansi = $/<faint>.made;
        } elsif $/<italic> {
            %ansi = $/<italic>.made;
        } elsif $/<underline> {
            %ansi = $/<underline>.made;
        } elsif $/<blink> {
            %ansi = $/<blink>.made;
        } elsif $/<reverse-video> {
            %ansi = $/<reverse-video>.made;
        } elsif $/<strike> {
            %ansi = $/<strike>.made;
        } elsif $/<alt-font> {
            %ansi = $/<alt-font>.made;
        }
        dd %ansi if $debug;
        make %ansi;
    }
    method chunk($/) {
        my %chunk = type => 'chunk', sub-type => 'chunk', val => ~$/;
        dd %chunk if $debug;
        make %chunk;
    }
    method chunks($/) {
        my %chunks;
        if $/<chunk> {
            %chunks = $/<chunk>.made;
        } elsif $/<ansi> {
            %chunks = $/<ansi>.made;
        }
        dd %chunks if $debug;
        make %chunks;
    }
    #token empty          { '' }
    method empty($/) {
        my %empty = type => 'chunk', sub-type => 'empty', val => ~$/;
        dd %empty if $debug;
        make %empty;
    }
    #token block          { <chunks>+ }
    method block($/) {
        my @block = $/<chunks>».made;
        dd @block if $debug;
        make @block;
    }
    #token text           { ^ [  <block> || <empty> ] $ }
    method text($/) {
        my @text;
        if $/<block> {
            @text = $/<block>.made;
        } elsif $/<empty> {
            my %empt = $/<empty>.made;
            @text.push(%empt);
        }
        dd @text if $debug;
        make @text;
    }
} # role UnhighlightBaseActions #

grammar Unhighlight is UnhighlightBase {
    token TOP    { <text> }
}

class UnhighlightActions does UnhighlightBaseActions {
    method TOP($made) {
        my @top = $made<text>.made;
        dd @top if $debug;
        $made.make: @top;
    }
} # class UnhighlightActions does UnhighlightBaseActions #

=begin pod

L<Top of Document|#>

=head2 The Functions Provided

=begin item 

strip-ansi

=begin code :lang<raku>

sub strip-ansi(Str:D $text --> Str:D) is export

=end code

Strips out all the ANSI escapes, at the moment just those provided by the B<C<Terminal::ANSI>> 
or B<C<Terminal::ANSI::OO>> modules both available as B<C<Terminal::ANSI>> from zef etc I am not sure
how exhaustive that is,  but I will implement any more escapes as I become aware of them.

=end item

=end pod

sub strip-ansi(Str:D $text --> Str:D) is export {
    dd $text if $debug;
    #return $text if $text.trim eq '';
    my $actions = UnhighlightActions;
    my @stuff = Unhighlight.parse($text, :enc('UTF-8'), :$actions).made;
    my @cleaned = @stuff.grep( -> %chnk { %chnk«type» eq 'chunk' }).map: -> %chk { %chk«val» };
    return @cleaned.join();
} # sub strip-ansi(Str:D $text --> Str:D) is export #

=begin pod

=begin item

hwcswidth
=begin code :lang<raku>

sub hwcswidth(Str:D $text --> Int:D) is export

=end code

Same as B<C<wcswidth>> but it copes with ANSI escape sequences unlike B<C<wcswidth>>.

=end item

=begin item2

The secret sauce is that it is defined as:

=begin code :lang<raku>

sub hwcswidth(Str:D $text --> Int:D) is export {
    return wcswidth(strip-ansi($text));
} #  sub hwcswidth(Str:D $text --> Int:D) is export #


=end code

=end item2

=end pod

sub hwcswidth(Str:D $text --> Int:D) is export {
    return wcswidth(strip-ansi($text));
} #  sub hwcswidth(Str:D $text --> Int:D) is export #

=begin pod

L<Top of Document|#>

=begin head3

Here are 4 functions provided  to B<C<centre>>, B<C<left>> and B<C<right>> justify text even when
it is ANSI formatted.

=end head3

=begin item

B<centre>

=begin code :lang<raku>

sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
            :&number-of-chars:(Int:D, Int:D --> Bool:D) = &centre-global-number-of-chars,
                Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export {

=end code

=end item

=begin item2

B<C<centre>> centres the text B<C<$text>> in a field of width B<C<$width>> padding either side with B<C<$fill>>

=end item2

=begin item2

B<Where:>

=end item2

=begin item3

B<C<$fill>>      is the fill char by default B<C<$fill>> is set to a single white space.

=end item3

=begin item4

If  it requires an odd number of padding then the right hand side will get one more char/codepoint.

=end item4

=begin item3

B<C<&number-of-chars>> takes a function which takes 2 B<C<Int:D>>'s and returns a B<C<Bool:D>>.

=end item3

=begin item4

By default this is equal to the closure B<C<centre-global-number-of-chars>> which looks like:

=begin code :lang<raku>

our $centre-total-number-of-chars is export = 0;
our $centre-total-number-of-visible-chars is export = 0;

sub centre-global-number-of-chars(Int:D $number-of-chars,
                                Int:D $number-of-visible-chars --> Bool:D) {
    $centre-total-number-of-chars         = $number-of-chars;
    $centre-total-number-of-visible-chars = $number-of-visible-chars;
    return True
}

=end code

=end item4

=begin item5 

Which is a closure around the variables: B<C<$centre-total-number-of-chars>> and B<C<$centre-total-number-of-visible-chars>>, 
these are global B<C<our>> variables that B<C<Gzz::Text::Utils>> exports.
But you can just use B<C<my>> variables from with a scope, just as well. And make the B<C<sub>> local to the same scope.

i.e.

=begin code :lang<raku>
    
sub Sprintf(Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> Str) is export {
    ...
    ...
    ...
    my Int:D $total-number-of-chars = 0;
    my Int:D $total-number-of-visible-chars = 0;
    sub internal-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) {
        $total-number-of-chars += $number-of-chars;
        $total-number-of-visible-chars += $number-of-visible-chars;
        return True;
    } # sub internal-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) #
    ...
    ...
    ...
    for @format-str -> %elt {
        my Str:D $type = %elt«type»;
        if $type eq 'literal' {
            my Str:D $lit = %elt«val»;
            $total-number-of-chars += $lit.chars;
            $total-number-of-visible-chars += strip-ansi($lit).chars;
            $result ~= $lit;
        } elsif $type eq 'fmt-spec' {
            ...
            ...
            ...
            given $spec-char {
                when 'c' {
                             $arg .=Str;
                             $ref .=Str;
                             BadArg.new(:msg("arg should be one codepoint: {$arg.codes} found")).throw if $arg.codes != 1;
                             $max-width = max($max-width, $precision, 0) if $max-width > 0; #`« should not really have a both for this
                                                                                                so munge together.
                                                                                                Traditionally sprintf etc treat precision
                                                                                                as max-width for strings. »
                             if $padding eq '' {
                                 if $justify eq '' {
                                     $result ~=  right($arg, $width, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 } elsif $justify eq '-' {
                                     $result ~=  left($arg, $width, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 } elsif $justify eq '^' {
                                     $result ~=  centre($arg, $width, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 }
                             } else {
                                 if $justify eq '' {
                                     $result ~=  right($arg, $width, $padding, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 } elsif $justify eq '-' {
                                     $result ~=  left($arg, $width, $padding, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 } elsif $justify eq '^' {
                                     $result ~=  centre($arg, $width, $padding, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 }
                             }
                         }
                when 's' {
                            ...
                            ...
                            ...
        ...
        ...
        ...
    ...
    ...
    ...
    return $result;
    KEEP {
        &number-of-chars($total-number-of-chars, $total-number-of-visible-chars);
    }
} #`««« sub Sprintf(Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> Str) is export »»»
 
=end code

=end item5

=begin item3

The parameter B<C<:$ref>> is by default set to the value of B<C<strip-ansi($text)>>
=end item3

=begin item4

This is used to obtain the length of the of the text using B<I<C<wcswidth(Str)>>> from module B<"C<Terminal::WCWidth>">
which is used to obtain the width the text if printed on the current terminal:

=end item4

=begin item5

B<NB: C<wcswidth> will return -1 if you pass it text with colours etc embedded in them>.

=end item5

=begin item5

B<"C<Terminal::WCWidth>"> is witten by B<bluebear94> L<github:bluebear94|https://raku.land/github:bluebear94> get it with B<zef> or whatever

=end item5

=begin item3

B<C<:$max-width>> sets the maximum width of the field but if set to B<C<0>> (The default), will effectively be infinite (∞).

=end item3

=begin item3

B<C<:$ellipsis>> is used to elide the text if it's too big I recommend either B<C<''>> the default or B<C<'…'>>.

=end item3

=begin item

B<left>

=begin code :lang<raku>

sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &left-global-number-of-chars,
                    Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export {

=end code

=end item

=item2       B<C<left>> is the same except that except that it puts all the  padding on the right of the field.

=begin item

B<right>

=begin code :lang<raku>

sub right(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                    :&number-of-chars:(Int:D, Int:D --> Bool:D) = &right-global-number-of-chars,
                        Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export {

=end code

=end item





=item2       B<C<right>> is again the same except it puts all the padding on the left and the text to the right.


=begin item 

B<crop-field>

=begin code :lang<raku>

sub crop-field(Str:D $text, Int:D $w is rw, Int:D $width is rw, Bool:D $cropped is rw,
                                                Int:D $max-width, Str:D :$ellipsis = '' --> Str:D) is export {

=end code

=end item

=begin item2

B<C<crop-field>> used by B<C<centre>>, B<C<left>> and B<C<right>> to crop their input if necessary. Copes with
ANSI escape codes.

=end item2

=begin item3

B<Where>

=end item3

=begin item4 

B<C<$text>> is the text to be cropped possibly, wit ANSI escapes embedded. 

=end item4

=begin item4

B<C<$w>> is used to hold the width of B<C<$text>> is read-write so will return that value.

=end item4

=begin item4 

B<C<$width>> is the desired width. Will be used to return the updated width.

=end item4

=begin item4 

B<C<$cropped>> is used to return the status of whether or not B<C<$text>> was truncated.

=end item4

=begin item4 

B<C<$max-width>> is the maximum width we are allowing.

=end item4

=begin item4 

B<C<$ellipsis>> is used to supply a eliding . Empty string by default.

=end item4

=end pod




sub crop-field(Str:D $text, Int:D $w is rw, Int:D $width is rw, Bool:D $cropped is rw,
                                                Int:D $max-width, Str:D :$ellipsis = '' --> Str:D) is export {
    if $debug {
        my $line = "$?FILE\[$?LINE] {$?MODULE.gist} {&?ROUTINE.signature.gist}";
        dd $w, $max-width, $text, $line;
    }
    if $max-width > 0 {
        $w  = hwcswidth($text); # just in case $w wasn't set correctly on call #
        if $w > $max-width {
            my $actions = UnhighlightActions;
            my @chunks = Unhighlight.parse($text, :enc('UTF-8'), :$actions).made;
            my Str:D $tmp = '';
            if $debug {
                my Str:D $line = "$?FILE\[$?LINE] {$?MODULE.gist} {&?ROUTINE.signature.gist}";
                dd @chunks, $w, $max-width, $tmp, $line;
            }
            $w = 0;
            my %chunk;
            my Int:D $i = -1;
            loop ($i = 0; $i < @chunks.elems; $i++) {
                %chunk = @chunks[$i];
                $w = hwcswidth($tmp ~ %chunk«val» ~ $ellipsis);
                if $w > $max-width {
                    last;
                }
                $tmp ~= %chunk«val»;
                if $debug {
                    my Str:D $line = "\[$?LINE]";
                    dd @chunks, $w, $max-width, $tmp, $line;
                }
            }
            if hwcswidth($tmp) < $max-width {
                while %chunk«type» ne 'chunk' && $i < @chunks.elems {
                    if $debug {
                        my $t = @chunks[$i];
                        dd @chunks, $i, $t, %chunk;
                    }
                    %chunk = @chunks[$i];
                    $i++;
                }
                $w = hwcswidth($tmp ~ %chunk«val» ~ $ellipsis);
                my Str:D $val = '';
                if %chunk«type» eq 'chunk' {
                    $val = %chunk«val»;
                } else {
                    $cropped = True;
                    $tmp ~= "\e[0m";
                    return $tmp;
                }
                while hwcswidth($tmp ~ $val ~ $ellipsis) > $max-width {
                    last if $val eq '';
                    $val = $val.substr(0, *-1);
                }
                $tmp ~= $val ~ $ellipsis ~ "\e[0m";
                $cropped = True;
                $width = $max-width if $width > $max-width;
                return $tmp;
            } # if hwcswidth($tmp) < $max-width #
            if $debug {
                my $line = "$?FILE\[$?LINE] {$?MODULE.gist} {&?ROUTINE.signature.gist}";
                dd @chunks, $w, $max-width, $tmp, $line;
            }
            if $i + 1 < @chunks.elems {
                $tmp ~= $ellipsis ~ "\e[0m";
                $cropped = True;
                $width = $max-width if $width > $max-width;
                return $tmp;
            }
        } # if $w > $max-width #
        $width = $max-width if $width > $max-width;
    } # if $max-width > 0 #
    $w  = hwcswidth($text); # insure that $w is set correctly #
    $cropped = False;
    return $text;
} #`««« sub crop-field(Str:D $text, Int:D $w is rw, Int:D $width is rw, Bool:D $cropped is rw,
                                        Int:D $max-width, Str:D :$ellipsis = '' --> Str:D) is export »»»

our $centre-total-number-of-chars is export = 0;
our $centre-total-number-of-visible-chars is export = 0;

sub centre-global-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) {
    $centre-total-number-of-chars         = $number-of-chars;
    $centre-total-number-of-visible-chars = $number-of-visible-chars;
    return True
}

our $left-total-number-of-chars is export = 0;
our $left-total-number-of-visible-chars is export = 0;

sub left-global-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) {
    $left-total-number-of-chars         = $number-of-chars;
    $left-total-number-of-visible-chars = $number-of-visible-chars;
    return True
}

our $right-total-number-of-chars is export = 0;
our $right-total-number-of-visible-chars is export = 0;

sub right-global-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) {
    $right-total-number-of-chars         = $number-of-chars;
    $right-total-number-of-visible-chars = $number-of-visible-chars;
    return True
}


sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
            :&number-of-chars:(Int:D, Int:D --> Bool:D) = &centre-global-number-of-chars,
                Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export {
    my Int:D $w  = wcswidth($ref);
    dd $w, $width, $max-width, $text, $ref if $debug;
    my Bool:D $cropped = False;
    my Str $result = crop-field($text, $w, $width,  $cropped, $max-width, :$ellipsis);
    return $result if $cropped;
    return $result if $w < 0;
    return $result if $width <= $w;
    $width -= $w;
    return $result if $width <= 0;
    my Int:D $fill-width = wcswidth($fill);
    $fill-width = 1 unless $fill-width > 0;
    $width = $width div $fill-width;
    my Int:D $l  = $width div 2;
    $result = $fill x $l ~ $result ~ $fill x ($width - $l);
    return $result;
    KEEP {
        &number-of-chars($result.chars, strip-ansi($result).chars);
    }
} #`««« sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                    :&number-of-chars:(Int:D, Int:D --> Bool:D) = &centre-global-number-of-chars,
                        Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export »»»

sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &left-global-number-of-chars,
                    Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export {
    my Int:D $w  = wcswidth($ref);
    dd $w, $width, $max-width, $text, $ref if $debug;
    my Bool:D $cropped = False;
    my Str $result = crop-field($text, $w, $width,  $cropped, $max-width, :$ellipsis);
    return $result if $cropped;
    return $result if $w < 0;
    return $result if $width <= 0;
    return $result if $width <= $w;
    my Int:D $l  = ($width - $w).abs;
    $result ~= $fill x $l;
    return $result;
    KEEP {
        &number-of-chars($result.chars, strip-ansi($result).chars);
    }
} #`««« sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                    :&number-of-chars:(Int:D, Int:D --> Bool:D) = &left-global-number-of-chars,
                        Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export »»»

sub right(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                    :&number-of-chars:(Int:D, Int:D --> Bool:D) = &right-global-number-of-chars,
                        Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export {
    my Int:D $w  = wcswidth($ref);
    my Bool:D $cropped = False;
    my Str $result = crop-field($text, $w, $width,  $cropped, $max-width, :$ellipsis);
    return $result if $cropped;
    return $result if $w < 0;
    return $result if $width <= 0;
    return $result if $width <= $w;
    my Int:D $l  = $width - $w;
    dd $l, $result if $debug;
    dd $w, $width, $max-width, $result, $ref, $fill if $debug;
    $result = ($fill x $l) ~ $result;
    return $result;
    KEEP {
        &number-of-chars($result.chars, strip-ansi($result).chars);
    }
} #`««« sub right(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                    :&number-of-chars:(Int:D, Int:D --> Bool:D) = &right-global-number-of-chars, Str:D
                        :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export »»»

=begin pod

L<Top of Document|#>

=head3 Sprintf

=begin item

Sprintf like sprintf only it can deal with ANSI highlighted text. And has lots of other options, including the ability
to specify a B<C<$max-width>> using B<C<width.precision.max-width>>, which can be B<C<.*>>, B<C*<<num>$>>, B<C<.*>>,  or B<C<<num>>>

=begin code :lang<raku>

sub Sprintf(Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> Str) is export 

=end code

=end item

=begin item2

Where:

=end item2

=begin item3

B<C<format-str>> is is a superset of the B<C<sprintf>> format string,  but it has extra features: 
like the flag B<C<[ <char> ]>> where <char> can be almost anything except B<C<[>>, B<C<]>> B<control characters>, 
B<white space other than the normal space>, and B<C<max-width>> after the precision.

=end item3

=begin item4

The format string looks like this:                                                        

=begin  code :lang<raku>

token format      { <chunks>+ }
token chunks      { [ <chunk> || '%' <format-spec> ] }
token chunk       { <-[%]>+ }
token format-spec { [ <fmt-esc> || <fmt-spec> ] }
token fmt-esc     { [      '%' #`« a literal % »
                        || 'N' #`« a nl i.e. \n char but does not require interpolation so no double quotes required »
                        || 'T' #`« a tab i.e. \t char but does not require interpolation so no double quotes required »
                        || 'n' #`« not implemented and will not be »
                        || 't' #`« not implemented and will not be »
                    ]
                  }
token fmt-spec   { [ <dollar-directive> '$' ]? <flags>?  <width>? [ '.' <precision> [ '.' <max-width> ]? ]? <modifier>? <spec-char> }


=end code


=end item4


=begin item5

Where

=end item5

=begin item5

B<C<dollar-directive>> is a integer >= 1

=end item5                        

=begin item5

B<C<flags>> is any zero or more of:

=end item5                        

=begin item6

B<C<+>> put a plus in front of positive values.

=end item6                        


=begin item6

B<C<->> left justify, right is the default

=end item6                        


=begin item6

B<C<^>>  centre justify.

=end item6                        


=begin item6

B<C<#>> ensure the leading B<C<0>> for any octal, prefix non-zero hexadecimal
with B<C<0x>> or B<C<0X>>, prefix non-zero binary with B<C<0b>> or B<C<0B>>

=end item6                        


=begin item6

B<C<v>> vector flag (used only with d directive)

=end item6                        


=begin item6

B<C<' '>> pad with spaces.

=end item6                        


=begin item6

B<C<0>> pad with zeros.

=end item6                        


=begin item6

B«C«[ <char> ]»» pad with character char where char matches:

=end item6                        

=begin item7

B«C«<-[ <cntrl> \s \[ \] ]> || ' '»» i.e. anything except control characters, white
space (apart from the basic white space (i.e. \x20 or the one with ord 32)),
and B<C<[>> and finally B<C<]>>.

=end item7

=begin item5

B<C<width>> is either an integer or a B<C<*>> or a B<C<*>> followed by an integer >= 1 and a '$'.

=end item5                        


=begin item5

B<C<precision>> is a B<C<.>> followed by either an positive integer or a B<C<*>> or a B<C<*>>
followed by an integer >= 1 and a '$'.

=end item5                        


=begin item5

B<C<max-width>> is a B<C<.>> followed by either an positive integer or a B<C<*>> or a B<C<*>>
followed by an integer >= 1 and a '$'.

=end item5                        

=begin item5

B<C<modifier>> These are not implemented but is one of:

=end item5                        

=begin item6

B<C<hh>> interpret integer as a type B<C<char>> or B<C<unsigned char>>.

=end item6

=begin item6

B<C<h>> interpret integer as a type B<C<short>> or B<C<unsigned short>>.

=end item6

=begin item6

B<C<j>> interpret integer as a type B<C<intmax_t>>, only with a C99 compiler (unportable).

=end item6

=begin item6

B<C<l>> interpret integer as a type B<C<long>> or B<C<unsigned long>>.

=end item6

=begin item6

B<C<ll>> interpret integer as a type B<C<long long>>, B<C<unsigned long long>>, or B<C<quad>> (typically 64-bit integers).

=end item6

=begin item6

B<C<q>> interpret integer as a type B<C<long long>>, B<C<unsigned long long>>, or B<C<quad>> (typically 64-bit integers).

=end item6

=begin item6

B<C<L>> interpret integer as a type B<C<long long>>, B<C<unsigned long long>>, or B<C<quad>> (typically 64-bit integers).

=end item6

=begin item6

B<C<t>> interpret integer as a type B<C<ptrdiff_t>>.

=end item6

=begin item6

B<C<z>> interpret integer as a type B<C<size_t>>.

=end item6

=begin item5

B<C<spec-char>> or the conversion character is one of:

=end item5                        

=begin item6

B<C<c>> a character with the given codepoint.

=end item6                        


=begin item6

B<C<s>> a string.

=end item6                        


=begin item6

B<C<d>> a signed integer, in decimal.

=end item6                        


=begin item6

B<C<u>> an unsigned integer, in decimal.

=end item6                        


=begin item6

B<C<o>> an unsigned integer, in octal, with a B<C<0o>> prepended if the B<C<#>> flag is present.

=end item6                        


=begin item6

B<C<x>> an unsigned integer, in hexadecimal, with a B<C<0x>> prepended if the B<C<#>> flag is present.

=end item6                        


=begin item6

B<C<e>> a floating-point number, in scientific notation.

=end item6                        


=begin item6

B<C<f>> a floating-point number, in fixed decimal notation.

=end item6                        


=begin item6

B<C<g>> a floating-point number, in %e or %f notation.

=end item6                        


=begin item6

B<C<X>> like B<C<x>>, but using uppercase letters, with a B<C<0X>> prepended if the B<C<#>> flag is present.

=end item6                        


=begin item6

B<C<E>> like B<C<e>>, but using an uppercase B<C<E>>.

=end item6                        


=begin item6

B<C<G>> like B<C<g>>, but with an uppercase B<C<E>> (if applicable).

=end item6                        


=begin item6

B<C<b>> an unsigned integer, in binary, with a B<C<0b>> prepended if the B<C<#>> flag is present.

=end item6                        

=begin item6

B<C<B>> an unsigned integer, in binary, with a B<C<0B>> prepended if the B<C<#>> flag is present.

=end item6                        

=begin item6

B<C<i>> a synonym for B<C<%d>>.

=end item6                        

=begin item6

B<C<D>> a synonym for B<C<%ld>>.

=end item6                        

=begin item6

B<C<U>> a synonym for B<C<%lu>>.

=end item6                        

=begin item6

B<C<O>> a synonym for B<C<%lo>>.

=end item6                        

=begin item6

B<C<F>> a synonym for B<C<%f>>.

=end item6                        

=begin item3

B<C<:&number-of-chars>> is an optional named argument which takes a function with a signature B<C<:(Int:D, Int:D --> Bool:D)>> if not specified it will have the value of B<C<&Sprintf-global-number-of-chars>> which is defined as:

=begin code :lang<raku>

our $Sprintf-total-number-of-chars is export = 0;
our $Sprintf-total-number-of-visible-chars is export = 0;

sub Sprintf-global-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) {
    $Sprintf-total-number-of-chars         = $number-of-chars;
    $Sprintf-total-number-of-visible-chars = $number-of-visible-chars;
    return True
}

=end code

=end item3

=begin item4

This is exactly the same as the argument by the same name in B<C<centre>>, B<C<left>> and B<C<right>> above.

i.e. 

=begin code :lang<raku>
    
sub test( --> True) is export {
    ...
    ...
    ...
    my $test-number-of-chars = 0;
    my $test-number-of-visible-chars = 0;

    sub test-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) {
        $test-number-of-chars         = $number-of-chars;
        $test-number-of-visible-chars = $number-of-visible-chars;
        return True
    }

    put Sprintf('%30.14.14s, %30.14.13s%N%%%N%^*.*s%3$*4$.*3$.*6$d%N%2$^[&]*3$.*4$.*6$s%T%1$[*]^100.*4$.99s',
                                        ${ arg => $highlighted, ref => $text }, $text, 30, 14, $highlighted, 13,
                                                                    :number-of-chars(&test-number-of-chars), :ellipsis('…'));
    dd $test-number-of-chars,  $test-number-of-visible-chars;
    put Sprintf('%30.14.14s,  testing %30.14.13s%N%%%N%^*.*s%3$*4$.*3$.*6$d%N%2$^[&]*3$.*4$.*6$s%T%1$[*]^100.*4$.99s',
                                $[ $highlighted, $text ], $text, 30, 14, $highlighted, 13, 13,
                                                                    :number-of-chars(&test-number-of-chars), :ellipsis('…'));
    dd $test-number-of-chars,  $test-number-of-visible-chars;
    ...
    ...
    ...
}
 
=end code

=end item4

=begin item5

B<Note: This is a closure we should always use a closure if we want to get the number of characters printed.> 

=end item5

=begin item3

B<C<:$ellipsis>> this is an optional argument of type B<C<Str:D>> which defaults to B<C<''>>, if set will be used
to mark elided text, if the argument is truncated due to exceeding the value of B<C<max-width>>
(note B<C<max-width>> defaults to B<C<0>> which means infinity). The recommended value would be something like B<C<…>>.

=end item3

=begin item3

B<C<*@args>> is an arbitrary long list of values each argument can be either a scalar value to be printed or a Hash or an Array

=end item3

=begin item4

If a Hash then it should contain two pairs with keys: B<C<arg>> and B<C<ref>>; denoting the actual argument and a reference
argument respectively, the ref argument should be the same as B<C<arg>> but with no ANSI formatting etc to mess up the counting.
As this ruins formatting spacing. If not present will be set to B<C<strip-ansi($arg)>>, only bother with all this if
B<C<strip-ansi($arg)>> isn't good enough.

=end item4

=begin item4

If a Array then it should contain two values. The first being  B<C<arg>> and the other being B<C<ref>>; everything else is
the same as above.

=end item4

=begin item4

B<C<arg>> the actual argument.

=end item4

=begin item4

B<C<@args[$i][]>> the actual argument. Where B<C<$i>> is the current index into the array of args.

=end item4

=begin item4

B<C<@args[$i][1]>> the reference argument, as in the B<C<:$ref>> arg of the B<left>, B<right> and B<centre> functions which it uses.
It only makes sense if your talking strings possibly formatted if not present will be set to B<C<strip-ansi($arg)>> if $arg
is a Str or just $arg otherwise.

=end item4

=begin item4

If it's a scalar then it's the argument itself. And B<C<$ref>> is B<C<strip-ansi($arg)>> if $arg is a string type i.e. Str or
just B<C>$arg>> otherwise.

=end item4

=begin item5

B<C<ref>> the reference argument, as in the B<C<:$ref>> arg of the B<left>, B<right> and B<centre> functions which it uses.
It only makes sense if your talking strings possibly formatted if not present will be set to B<C<strip-ansi($arg)>> if $arg
is a Str or just $arg otherwise.

i.e.

=begin code :lang<raku>

put Sprintf('%30.14.14s, %30.14.13s%N%%%N%^*.*s%3$*4$.*3$.*6$d%N%2$^[&]*3$.*4$.*6$s%T%1$[*]^100.*4$.99s',
                            ${ arg => $highlighted, ref => $text }, $text, 30, 14, $highlighted, 13,
                                                                        :number-of-chars(&test-number-of-chars), :ellipsis('…'));
dd $test-number-of-chars,  $test-number-of-visible-chars;
put Sprintf('%30.14.14s,  testing %30.14.13s%N%%%N%^*.*s%3$*4$.*3$.*6$d%N%2$^[&]*3$.*4$.*6$s%T%1$[*]^100.*4$.99s',
                            $[ $highlighted, $text ], $text, 30, 14, $highlighted, 13, 13,
                                                                        :number-of-chars(&test-number-of-chars), :ellipsis('…'));
dd $test-number-of-chars,  $test-number-of-visible-chars;
 
=end code

=end item5


=end pod

our $Sprintf-total-number-of-chars is export = 0;
our $Sprintf-total-number-of-visible-chars is export = 0;

my subset FUInt of Int where {not .defined or $_ >= -1};

sub Sprintf-global-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) {
    $Sprintf-total-number-of-chars         = $number-of-chars;
    $Sprintf-total-number-of-visible-chars = $number-of-visible-chars;
    return True
}

sub Sprintf(Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> Str) is export {
    my $actions = FormatActions;
    my @format-str = Format.parse($format-str, :enc('UTF-8'), :$actions).made;
    dd @format-str if $debug;
    my Int:D $positionals = [+] (@format-str.grep( -> %elt { %elt«type» eq 'fmt-spec' }).map( -> %e {
                                                                                                 my Int:D $n = 1;
                                                                                                 $n-- if %e«dollar-directive» > 0;
                                                                                                 $n++ if %e«width»«kind» eq 'star';
                                                                                                 $n++ if %e«precision»«kind» eq 'star';
                                                                                                 $n;
                                                                                             }));
    my %extra-args is SetHash[Int] = (^$positionals).list;
    my Int:D $dollars  = [+] (@format-str.grep( -> %elt { %elt«type» eq 'fmt-spec' }).map( -> %e {
                                                                                          my Int:D $n = 0;
                                                                                          my Int:D $dollar-directive = %e«dollar-directive»;
                                                                                          if $dollar-directive > 0
                                                                                                        && (%extra-args{$dollar-directive}:!exists) {
                                                                                                $n++;
                                                                                                #`««« add to SetHash »»»
                                                                                                %extra-args{$dollar-directive} = True;
                                                                                          }
                                                                                          my Int:D $dollar = ((%e«width»«kind» eq 'dollar') ??
                                                                                                                              %e«width»«val» !! -1);
                                                                                          if $dollar > 0 && (%extra-args{$dollar}:!exists) {
                                                                                                $n++;
                                                                                                #`««« add to SetHash »»»
                                                                                                %extra-args{$dollar} = True;
                                                                                          }
                                                                                          $dollar = ((%e«precision»«kind» eq 'dollar') ??
                                                                                                                          %e«precision»«val» !! -1);
                                                                                          if $dollar > 0 && (%extra-args{$dollar}:!exists) {
                                                                                                $n++;
                                                                                                #`««« add to SetHash »»»
                                                                                                %extra-args{$dollar} = True;
                                                                                          }
                                                                                          $n;
                                                                                      }));
    my Int:D $max = %extra-args.keys.max;
    ArgParityMissMatch.new(:msg("Error: argument parity error; expected $positionals args got {@args.elems}")).throw if %extra-args.elems == 0 &&
                                                                                                                         $positionals != @args.elems;
    ArgParityMissMatch.new(:msg("Error: argument parity error; referenced argument index: {$max + 1} outside the range 1..{@args.elems}")).throw
                                                                                                                            if $max >= @args.elems;
    $positionals += $dollars;
    my Int:D $total-number-of-chars = 0;
    my Int:D $total-number-of-visible-chars = 0;
    sub internal-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) {
        $total-number-of-chars += $number-of-chars;
        $total-number-of-visible-chars += $number-of-visible-chars;
        return True;
    } # sub internal-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) #
    my Str:D $result = '';
    my Int:D $cnt = 0;
    dd @format-str if $debug;
    for @format-str -> %elt {
        my Str:D $type = %elt«type»;
        dd $type, %elt if $debug;
        if $type eq 'literal' {
            my Str:D $lit = %elt«val»;
            $total-number-of-chars += $lit.chars;
            $total-number-of-visible-chars += strip-ansi($lit).chars;
            $result ~= $lit;
        } elsif $type eq 'fmt-spec' {
            #my %fmt-spec = type => 'fmt-spec', dollar-directive => -1, flags => [],
            #                   width => { kind => 'empty', val => 0, }
            #                   precision => { kind => 'empty', val => 0, },
            #                   modifier => '', spec-char => $/<spec-char>.made;
            my         %width-spec = %elt«width»;
            my     %precision-spec = %elt«precision»;
            my     %max-width-spec = %elt«max-width»;
            my FUInt:D $width      = -1; # -1 denotes not present. #
            my FUInt:D $precision  = -1; # -1 denotes not present. #
            my UInt:D $max-width   = 0;
           if %width-spec«kind» eq 'star' {
                BadArg.new(:msg("arg count out of range not enough args")).throw unless $cnt < @args.elems;
                my Str:D $name = @args[$cnt].WHAT.^name;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $width = @args[$cnt]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $width = @args[$cnt][0];
                } else {
                    $width = @args[$cnt]; # @args[$cnt] is a scalar and should be an Int #
                }
                $cnt++;
            }elsif %width-spec«kind» eq 'dollar' {
                my Int:D $i = %width-spec«val»;
                dd $i, %width-spec if $debug;
                BadArg.new(:msg("\$ spec for width out of range")).throw unless $i ~~ 0..^@args.elems;
                my Str:D $name = @args[$i].WHAT.^name;
                dd $name if $debug;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $width = @args[$i]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $width = @args[$i][0];
                } else {
                    $width = @args[$i]; # @args[$i] is a scalar and should be an Int #
                }
            } elsif %width-spec«kind» eq 'int' {
                $width = %width-spec«val»;
            }
            if %precision-spec«kind» eq 'star' {
                BadArg.new(:msg("arg count out of range not enough args")).throw unless $cnt < @args.elems;
                my Str:D $name = @args[$cnt].WHAT.^name;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $precision = @args[$cnt]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $precision = @args[$cnt][0];
                } else {
                    $precision = @args[$cnt]; # @args[$cnt] is a scalar and should be an Int #
                }
                $cnt++;
            }elsif %precision-spec«kind» eq 'dollar' {
                my Int:D $i = %precision-spec«val»;
                BadArg.new(:msg("\$ spec for precision out of range")).throw unless $i ~~ 0..^@args.elems;
                my Str:D $name = @args[$i].WHAT.^name;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $precision = @args[$i]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $precision = @args[$i][0];
                } else {
                    $precision = @args[$i]; # @args[$i] is a scalar and should be an Int #
                }
            } elsif %precision-spec«kind» eq 'int' {
                $precision = %precision-spec«val»;
            }
            if %max-width-spec«kind» eq 'star' {
                BadArg.new(:msg("arg count out of range not enough args")).throw unless $cnt < @args.elems;
                my Str:D $name = @args[$cnt].WHAT.^name;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $max-width = @args[$cnt]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $max-width = @args[$cnt][0];
                } else {
                    $max-width = @args[$cnt]; # @args[$cnt] is a scalar and should be an Int #
                }
                $cnt++;
            }elsif %max-width-spec«kind» eq 'dollar' {
                my Int:D $i = %max-width-spec«val»;
                BadArg.new(:msg("\$ spec for max-width out of range")).throw unless $i ~~ 0..^@args.elems;
                my Str:D $name = @args[$i].WHAT.^name;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $max-width = @args[$i]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $max-width = @args[$i][0];
                } else {
                    $max-width = @args[$i]; # @args[$i] is a scalar and should be an Int #
                }
            } elsif %max-width-spec«kind» eq 'int' {
                $max-width = %max-width-spec«val»;
            }
            my $arg;
            my $ref;
            my Int:D $dollar-directive = %elt«dollar-directive»;
            my Int:D $i = $dollar-directive;
            dd %elt, $dollar-directive, $i, $cnt if $debug;
            BadArg.new(:msg("\$ spec for arg out of range")).throw unless $i < @args.elems;
            if $dollar-directive < 0 {
                $i = $cnt;
                $cnt++;
            }
            my Str:D $name = @args[$i].WHAT.^name;
            if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                $arg = @args[$i]«arg»;
                $ref = ((@args[$i]«ref»:exists) ?? @args[$i]«ref» !! (($arg ~~ Str:D) ?? strip-ansi($arg) !! $arg));
            } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                $arg = @args[$i][0];
                if @args[$i].elems == 1 {
                    $ref = (($arg ~~ Str:D) ?? strip-ansi($arg) !! $arg);
                } elsif @args[$i].elems > 1 {
                    $ref = @args[$i][1];
                }
            } else {
                $arg = @args[$i];
                $ref = (($arg ~~ Str:D) ?? strip-ansi($arg) !! $arg);
            }
            dd $arg, $ref, %elt, $width, $precision, $max-width if $debug;
            my        @flags       = |%elt«flags»;
            dd @flags if $debug;
            my Str:D  $padding     = '';
            my Bool:D $force-sign  = False;
            my Str:D  $justify     = '';
            my Bool:D $type-prefix = False;
            my Bool:D $vector      = False;
            #token flag              { [ <force-sign> || <justify> || <type-prefix> || <vector> || <padding> ] }
            my @force-sign         = @flags.grep: -> %flg { %flg«kind» eq 'force-sign' };
            my @justify            = @flags.grep: -> %flg { %flg«kind» eq 'justify' };
            my @type-prefix        = @flags.grep: -> %flg { %flg«kind» eq 'type-prefix' };
            my @vector             = @flags.grep: -> %flg { %flg«kind» eq 'vector' };
            my @padding            = @flags.grep: -> %flg { %flg«kind» eq 'padding' };
            my %force-sign; 
            %force-sign            = @force-sign[@force-sign.elems - 1] if @force-sign.elems > 0; 
            my %justify; 
            %justify               = @justify[@justify.elems - 1] if @justify.elems > 0; 
            my %type-prefix; 
            %type-prefix           = @type-prefix[@type-prefix.elems - 1] if @type-prefix.elems > 0; 
            my %vector; 
            %vector                = @vector[@vector.elems - 1] if @vector.elems > 0; 
            my %padding; 
            %padding               = @padding[@padding.elems - 1] if @padding.elems > 0; 
            $padding               = %padding«val»  if %padding;
            $force-sign            = True if %force-sign && %force-sign«val» eq '+';
            $justify               = '^'  if %justify && %justify«val» eq '^';
            $justify               = '-'  if %justify && %justify«val» eq '-';
            $type-prefix           = True if %type-prefix && %type-prefix«val» eq '#';
            $vector                = True if %vector && %vector«val» eq 'v';
            #my Str:D $modifier     = %elt«modifier»; # ignore these for now #
            my Str:D $spec-char    = %elt«spec-char»;
            $name = $arg.WHAT.^name;
            dd $arg, $ref, $ellipsis, $width, $precision, $max-width, $padding, $justify, $type-prefix, $spec-char if $debug;
            given $spec-char {
                when 'c' {
                             $arg .=Str;
                             $ref .=Str;
                             BadArg.new(:msg("arg should be one codepoint: {$arg.codes} found")).throw if $arg.codes != 1;
                             $max-width = max($max-width, $precision, 0) if $max-width > 0; #`« should not really have a both for this
                                                                                                so munge together.
                                                                                                Traditionally sprintf etc treat precision
                                                                                                as max-width for strings. »
                             if $padding eq '' {
                                 if $justify eq '' {
                                     $result ~=  right($arg, $width, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 } elsif $justify eq '-' {
                                     $result ~=  left($arg, $width, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 } elsif $justify eq '^' {
                                     $result ~=  centre($arg, $width, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 }
                             } else {
                                 if $justify eq '' {
                                     $result ~=  right($arg, $width, $padding, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 } elsif $justify eq '-' {
                                     $result ~=  left($arg, $width, $padding, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 } elsif $justify eq '^' {
                                     $result ~=  centre($arg, $width, $padding, :$ref, :number-of-chars(&internal-number-of-chars), :$max-width);
                                 }
                             }
                         }
                when 's' {
                             $arg .=Str;
                             $ref .=Str;
                             $max-width = max($max-width, $precision, 1) if $max-width > 0; #`« should not really have a both for this
                                                                                                so munge together.
                                                                                                Traditionally sprintf etc treat precision
                                                                                                as max-width for strings. »
                             dd $arg, $ref, $width, $precision, $max-width, $justify, $padding if $debug;
                             if $padding eq '' {
                                 if $justify eq '' {
                                     $result ~=  right($arg, $width, :number-of-chars(&internal-number-of-chars), :$ref,
                                                                                                             :$max-width, :$ellipsis);
                                 } elsif $justify eq '-' {
                                     $result ~=  left($arg, $width, :number-of-chars(&internal-number-of-chars), :$ref,
                                                                                                             :$max-width, :$ellipsis);
                                 } elsif $justify eq '^' {
                                     $result ~=  centre($arg, $width, :number-of-chars(&internal-number-of-chars), :$ref,
                                                                                                             :$max-width, :$ellipsis);
                                 }
                             } else {
                                 if $justify eq '' {
                                     $result ~=  right($arg, $width, $padding, :number-of-chars(&internal-number-of-chars), :$ref,
                                                                                                             :$max-width, :$ellipsis);
                                 } elsif $justify eq '-' {
                                     $result ~=  left($arg, $width, $padding, :number-of-chars(&internal-number-of-chars), :$ref,
                                                                                                             :$max-width, :$ellipsis);
                                 } elsif $justify eq '^' {
                                     $result ~=  centre($arg, $width, $padding, :number-of-chars(&internal-number-of-chars), :$ref,
                                                                                                             :$max-width, :$ellipsis);
                                 }
                             }
                         }
                when 'd'|'i'|'D' {
                                       $arg .=Int;
                                       $max-width = max($max-width, $precision, 0) if $max-width > 0; #`« should not really have a both for this
                                                                                                          so munge together.
                                                                                                          Traditionally sprintf etc treat precision
                                                                                                          as max-width for Ints. »
                                       my Str:D $fmt = '%';
                                       $fmt ~= '+' if $force-sign;
                                       $fmt ~= '#' if $type-prefix;
                                       $fmt ~= 'v' if $vector;
                                       if $padding eq '0' {
                                           $fmt ~= '-' if $justify eq '-';
                                           $fmt ~= $padding;
                                           if $width >= 0 { # centre etc make no sense here #
                                               if $max-width >= 0 {
                                                   $fmt ~= '*.*';
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= right(sprintf($fmt, $width, $max-width, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                               :$max-width, :$ellipsis);
                                               } else {
                                                   $fmt ~= '*';
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= right(sprintf($fmt, $width, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                               :$max-width, :$ellipsis);
                                               }
                                           } else {
                                               if $max-width >= 0 {
                                                   $fmt ~= '.*';
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= right(sprintf($fmt, $max-width, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                               :$max-width, :$ellipsis);
                                               } else {
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                               :$max-width, :$ellipsis);
                                               }
                                           }
                                       } elsif $padding eq ' ' {
                                           if $justify eq '^' {
                                               if $width >= 0 {
                                                   if $precision >= 0 {
                                                       $fmt ~= '.*';
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                   } else {
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                   }
                                               } else { # $width < 0 #
                                                   if $precision >= 0 {
                                                       $fmt ~= '.*';
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                   } else {
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                   }
                                               } # $width < 0 #
                                           } else { # justify is either '-' or '' i.e. left or right #
                                               if $precision >= 0 {
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                               } else {
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                               }
                                           } # justify is either '-' or '' i.e. left or right #
                                       } elsif $padding eq '' {
                                           if $justify eq '^' {
                                               if $width >= 0 {
                                                   if $precision >= 0 {
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= centre(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                   } else {
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= centre(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                   }
                                               } else { # $width < 0 #
                                                   if $precision >= 0 {
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= centre(sprintf($fmt, $arg), $precision,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                   } else {
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= centre(sprintf($fmt, $arg), $max-width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                   }
                                               } # $width < 0 #
                                           } else { # justify is either '-' or '' i.e. left or right #
                                               $fmt ~= $justify;
                                               if $precision >= 0 {
                                                   $fmt ~= '.*';
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= centre(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                               } else {
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= centre(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars), :$max-width, :$ellipsis);
                                               }
                                           } # justify is either '-' or '' i.e. left or right #
                                       } else { # $padding eq something-else #
                                           if $justify eq '^' {
                                               if $width >= 0 {
                                                   if $precision >= 0 {
                                                       $fmt ~= '.*';
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                   } else {
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                   }
                                               } else { # $width < 0 #
                                                   if $precision >= 0 {
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= centre(sprintf($fmt, $arg), $precision, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                   } else {
                                                       $fmt ~= $spec-char.lc;
                                                       $result ~= sprintf($fmt, $arg);
                                                   }
                                               } # $width < 0 #
                                           } elsif $justify eq '-' {
                                               $fmt ~= $justify;
                                               if $precision >= 0 {
                                                   $fmt ~= '.*';
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                               } else {
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                               }
                                           } else { # justify is '' i.e. right #
                                               if $precision >= 0 {
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                               } else {
                                                   $fmt ~= $spec-char.lc;
                                                   $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                               }
                                           } # justify is either '-' or '' i.e. left or right #
                                       } # $padding eq something-else #
                                 } # when 'd', 'i', 'D' #
                when 'u'|'U' {
                                 $arg .=Int;
                                 BadArg.new(:msg("argument cannot be negative for char spec: $spec-char")).throw if $arg < 0;
                                 $max-width = max($max-width, $precision, 0) if $max-width > 0; #`« should not really have a both for this
                                                                                                    so munge together.
                                                                                                    Traditionally sprintf etc treat precision
                                                                                                    as max-width for Ints. »
                                 my Str:D $fmt = '%';
                                 $fmt ~= '+' if $force-sign;
                                 $fmt ~= '#' if $type-prefix;
                                 $fmt ~= 'v' if $vector;
                                 if $padding eq '0' {
                                     if $width >= 0 { # centre etc make no sense here #
                                         if $precision >= 0 {
                                             $fmt ~= $padding;
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char.lc;
                                             dd $arg if $debug;
                                             $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                         } else {
                                             $fmt ~= $padding;
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char.lc;
                                             $result ~= right(sprintf($fmt, $width, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                         }
                                     } else { # $width < 0 #
                                         if $precision >= 0 {
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char.lc;
                                             $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                         } else {
                                             $fmt ~= $spec-char.lc;
                                             $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                         }
                                     }
                                 } elsif $padding eq ' ' {
                                     $fmt ~= '-' if $justify eq '-';
                                     $fmt ~= $padding;
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '*';
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= $padding;
                                                 $fmt ~= '*';
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char.lc;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= $spec-char.lc;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } elsif $padding eq '' { # $padding eq '' #
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '*';
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '*';
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $precision,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $arg), $max-width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char.lc;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= $spec-char.lc;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } else { # $padding eq something-else #
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= sprintf($fmt, $arg);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= $spec-char.lc;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= $spec-char.lc;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 }
                             } # when 'u', 'U' #
                when 'o'|'O' {
                                  $arg .=Int;
                                  $max-width = max($max-width, $precision, 0) if $max-width > 0; #`« should not really have a both for this
                                                                                                     so munge together.
                                                                                                     Traditionally sprintf etc treat precision
                                                                                                     as max-width for Ints. »
                                  my Str:D $fmt = '%';
                                  $fmt ~= '+' if $force-sign;
                                  $fmt ~= 'v' if $vector;
                                  if $padding eq '0' {
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= $padding;
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char.lc;
                                              if $type-prefix {
                                                  $result ~= right('0'~ $spec-char ~ sprintf($fmt, $width - 2, $precision - 2, $arg),
                                                                          $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $width, $precision, $arg),
                                                                          $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= '-' if $justify eq '-';
                                              $fmt ~= $padding;
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char.lc;
                                              if $type-prefix {
                                                  $result ~= right('0'~ $spec-char ~ sprintf($fmt, $width - 2, $arg),
                                                                          $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $width, $arg),
                                                                          $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      } else { # $width < 0 #
                                          $fmt ~= '-' if $justify eq '-';
                                          $fmt ~= $padding;
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char.lc;
                                              if $type-prefix {
                                                  $result ~= right('0'~ $spec-char ~ sprintf($fmt, $precision - 2, $arg),
                                                                          $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg),
                                                                          $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char.lc;
                                              $result ~= sprintf($fmt, $arg);
                                              if $type-prefix {
                                                  $result ~= right('0'~ $spec-char ~ sprintf($fmt, $arg),
                                                                          $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg),
                                                                          $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      }
                                  } elsif $padding eq ' ' {
                                      $fmt ~= '0';
                                      if $justify eq '^' {
                                          if $width >= 0 {
                                              if $precision >= 0 {
                                                  $fmt ~= '.*';
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $precision - 2, $arg),
                                                                                               $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              }
                                          } else { # $width < 0 #
                                              if $precision >= 0 {
                                                  $fmt ~= '.*';
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $precision - 2, $arg),
                                                                                               $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg),
                                                                                               $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  $fmt ~= $spec-char.lc;
                                                  $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              }
                                          } # $width < 0 #
                                      } else { # justify is either '-' or '' i.e. left or right #
                                          if $precision >= 0 {
                                              $fmt ~= $spec-char.lc;
                                              if $justify eq '-' {
                                                  if $type-prefix {
                                                      $result ~= left('0' ~ $spec-char ~ sprintf($fmt, $arg),
                                                                                                        $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  if $type-prefix {
                                                      $result ~= right('0' ~ $spec-char ~ sprintf($fmt, $precision - 2, $arg),
                                                                                                         $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              }
                                          } else {
                                              if $justify eq '-' {
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= left('0' ~ $spec-char ~ sprintf($fmt, $arg),
                                                                                                       $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= right('0' ~ $spec-char ~ sprintf($fmt, $arg),
                                                                                                       $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              }
                                          }
                                      } # justify is either '-' or '' i.e. left or right #
                                  } elsif $padding eq '' { # $padding eq '' #
                                      if $justify eq '^' {
                                          if $width >= 0 {
                                              if $precision >= 0 {
                                                  $fmt ~= '.*';
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $precision, $arg),
                                                                                                                $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $arg), $width);
                                                  }
                                              }
                                          } else { # $width < 0 #
                                              if $precision >= 0 {
                                                  $fmt ~= '.*';
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $precision, $arg), $max-width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg), $max-width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $arg), $max-width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $arg), $max-width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              }
                                          } # $width < 0 #
                                      } else { # justify is either '-' or '' i.e. left or right #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char.lc;
                                              if $justify eq '-' {
                                                  if $type-prefix {
                                                      $result ~= left('0' ~ $spec-char ~ sprintf($fmt, $precision - 2, $arg),
                                                                                                                   $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= left(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  if $type-prefix {
                                                      $result ~= right('0' ~ $spec-char ~ sprintf($fmt, $precision, $arg),
                                                                                                                   $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= right(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              }
                                          } else {
                                              $fmt ~= $spec-char.lc;
                                              if $justify eq '-' {
                                                  if $type-prefix {
                                                      $result ~= left('0' ~ $spec-char ~ sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= left(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  if $type-prefix {
                                                      $result ~= right('0' ~ $spec-char ~ sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= right(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              }
                                          }
                                      } # justify is either '-' or '' i.e. left or right #
                                  } else { # $padding eq something-else #
                                      if $justify eq '^' {
                                          if $width >= 0 {
                                              if $precision >= 0 {
                                                  $fmt ~= '.*';
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $precision, $arg),
                                                                                                        $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $arg),
                                                                                                        $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              }
                                          } else { # $width < 0 #
                                              if $precision >= 0 {
                                                  $fmt ~= '0';
                                                  $fmt ~= '.*';
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $precision, $arg),
                                                                                                    $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg),
                                                                                                    $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $arg),
                                                                                                    $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              }
                                          } # $width < 0 #
                                      } else { # justify is either '-' or '' i.e. left or right #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char.lc;
                                              if $justify eq '-' {
                                                  if $type-prefix {
                                                      $result ~= left('0' ~ $spec-char ~ sprintf($fmt, $precision - 2, $arg),
                                                                                                       $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  if $type-prefix {
                                                      $result ~= right('0' ~ $spec-char ~ sprintf($fmt, $precision, $arg),
                                                                                                       $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              }
                                          } else {
                                              $fmt ~= $spec-char.lc;
                                              if $justify eq '-' {
                                                  if $type-prefix {
                                                      $result ~= left('0' ~ $spec-char ~ sprintf($fmt, $arg),
                                                                                                        $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              } else {
                                                  if $type-prefix {
                                                      $result ~= right('0' ~ $spec-char ~ sprintf($fmt, $arg),
                                                                                                        $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  } else {
                                                      $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                                  }
                                              }
                                          }
                                      } # justify is either '-' or '' i.e. left or right #
                                  }
                             } # when 'o', 'O' #
                when 'x'|'X' {
                                 $arg .=Int;
                                 $max-width = max($max-width, $precision, 0) if $max-width > 0; #`« should not really have a both for this
                                                                                  so munge together.
                                                                                  Traditionally sprintf etc treat precision
                                                                                  as max-width for Ints. »
                                 my Str:D $fmt = '%';
                                 $fmt ~= '+' if $force-sign;
                                 $fmt ~= 'v' if $vector;
                                 if $padding eq '0' {
                                     $fmt ~= '-' if $justify eq '-';
                                     $fmt ~= $padding;
                                     if $width >= 0 { # centre etc make no sense here #
                                         if $precision >= 0 {
                                             $fmt ~= '*.*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= right('0'~ $spec-char ~ sprintf($fmt, $width - 2, $precision - 2, $arg),
                                                                           $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $width, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= right('0'~ $spec-char ~ sprintf($fmt, $width - 2, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $width, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     } else {
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= right('0'~ $spec-char ~ sprintf($fmt, $precision - 2, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             if $type-prefix {
                                                 $result ~= right('0'~ $spec-char ~ sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     }
                                 } elsif $padding eq ' ' {
                                     $fmt ~= '#' if $type-prefix;
                                     $fmt ~= '0';
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } elsif $padding eq '' { # $padding eq '' #
                                     $fmt ~= '#' if $type-prefix;
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $precision,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $max-width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } else { # $padding eq something-else #
                                     $fmt ~= '#' if $type-prefix;
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 }
                             } # when 'x', 'X' #
                when 'e'|'E' {
                                  $arg .=Num;
                                  $max-width = max($max-width, $width, 0) if $max-width > 0; #`« should not really have a both for this
                                                                                                 so munge together.
                                                                                                 Traditionally sprintf etc treat precision
                                                                                                 as max-width for Ints. »
                                  my Str:D $fmt = '%';
                                  $fmt ~= '+' if $force-sign;
                                  $fmt ~= 'v' if $vector;
                                  $fmt ~= '#' if $type-prefix;
                                  ##########################################################
                                  #                                                        #
                                  #   centring makes no sense here  so we will not do it   #
                                  #                                                        #
                                  ##########################################################
                                  if $padding eq '0' {
                                      $fmt ~= '-' if $justify eq '-';
                                      $fmt ~= $padding;
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      }
                                  } elsif $padding eq ' ' {
                                      if $width >= 0 { 
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      }
                                  } elsif $padding eq '' {
                                      $fmt ~= '-' if $justify eq '-';
                                      $fmt ~= $padding;
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $precision, $arg), $precision,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $arg), $max-width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      }
                                  } else { # $padding eq something-else #
                                      if $width >= 0 { # centre etc make sense  here #
                                          if $precision >= 0 {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else { # right justification #
                                                  $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else { # $precision < 0 #
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else { # right justification #
                                                  $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      }
                                  }
                             } # when 'e', 'E' #
                when 'f'|'F' {
                                  $arg .=Num;
                                  $max-width = max($max-width, $width, 0) if $max-width > 0; #`« should not really have a both for this
                                                                                                 so munge together.
                                                                                                 Traditionally sprintf etc treat precision
                                                                                                 as max-width for Ints. »
                                  my Str:D $fmt = '%';
                                  $fmt ~= '+' if $force-sign;
                                  $fmt ~= 'v' if $vector;
                                  $fmt ~= '#' if $type-prefix;
                                  dd $arg, $fmt, $width, $precision, $max-width, $padding, $justify, $type-prefix if $debug;
                                  ##########################################################
                                  #                                                        #
                                  #   centring makes no sense here  so we will not do it   #
                                  #                                                        #
                                  ##########################################################
                                  if $padding eq '0' {
                                      $fmt ~= '-' if $justify eq '-';
                                      $fmt ~= $padding;
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $precision, $arg), $precision, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      }
                                  } elsif $padding eq ' ' || $padding eq '' {
                                      if $width >= 0 { 
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $precision, $arg), $precision, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $precision, $arg), $precision, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg), $precision, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      }
                                  } elsif $padding eq '' {
                                      $fmt ~= '-' if $justify eq '-';
                                      $fmt ~= $padding;
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $precision, $arg), $precision, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      }
                                  } else { # $padding eq something-else #
                                      if $width >= 0 { 
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      }
                                  }
                             } # when 'f', 'F' #
                when 'g'|'G' {
                                  $arg .=Num;
                                  $max-width = max($max-width, $width, 0) if $max-width > 0; #`« should not really have a both for this
                                                                                                 so munge together.
                                                                                                 Traditionally sprintf etc treat precision
                                                                                                 as max-width for Ints. »
                                  my Str:D $fmt = '%';
                                  $fmt ~= '+' if $force-sign;
                                  $fmt ~= 'v' if $vector;
                                  $fmt ~= '#' if $type-prefix;
                                  ##########################################################
                                  #                                                        #
                                  #   centring makes no sense here  so we will not do it   #
                                  #                                                        #
                                  ##########################################################
                                  if $padding eq '0' {
                                      $fmt ~= '-' if $justify eq '-';
                                      $fmt ~= $padding;
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $precision, $arg), $precision, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      }
                                  } elsif $padding eq ' ' {
                                      if $width >= 0 { 
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      }
                                  } elsif $padding eq '' {
                                      $fmt ~= '-' if $justify eq '-';
                                      $fmt ~= $padding;
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $width, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $precision, $arg), $width, 
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= right(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                          }
                                      }
                                  } else { # $padding eq something-else #
                                      if $width >= 0 { 
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $precision, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          } else {
                                              $fmt ~= $spec-char;
                                              if $justify eq '^' {
                                                  $result ~= centre(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } elsif $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              } else {
                                                  $result ~= right(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                              }
                                          }
                                      }
                                  }
                             } # when 'g', 'G' #
                when 'b'|'B' {
                                 $arg .=Int;
                                 $max-width = max($max-width, $precision, 1) if $max-width > 0; #`« should not really have a both for this
                                                                                                    so munge together.
                                                                                                    Traditionally sprintf etc treat precision
                                                                                                    as max-width for Ints. »
                                 my Str:D $fmt = '%';
                                 $fmt ~= '+' if $force-sign;
                                 $fmt ~= 'v' if $vector;
                                 if $padding eq '0' {
                                     $fmt ~= '-' if $justify eq '-';
                                     $fmt ~= $padding;
                                     if $width >= 0 { # centre etc make no sense here #
                                         if $precision >= 0 {
                                             $fmt ~= '*.*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= right('0'~ $spec-char ~ sprintf($fmt, $width - 2, $precision - 2, $arg),
                                                                          $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $width, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= right('0'~ $spec-char ~ sprintf($fmt, $width - 2, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $width, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     } else {
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= right('0'~ $spec-char ~ sprintf($fmt, $precision - 2, $arg), $precision, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $precision, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= right('0'~ $spec-char ~ sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $max-width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     }
                                 } elsif $padding eq ' ' {
                                     $fmt ~= '#' if $type-prefix;
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } elsif $padding eq '' { # $padding eq '' #
                                     $fmt ~= '#' if $type-prefix;
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $precision,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= right(sprintf($fmt, $arg), $max-width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } else { # $padding eq something-else #
                                     $fmt ~= '#' if $type-prefix;
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding,
                                                                               :number-of-chars(&internal-number-of-chars),
                                                                                                                   :$max-width, :$ellipsis);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 }
                             } # when 'b' #
            } # given $spec-char #
        } else {
            BadArg.new(:msg("Error: $?FILE line: $?LINE corrupted arg {@args[$cnt].WHAT.^name}")).throw;
        }
    } # for @format-str -> $arg #
    return $result;
    KEEP {
        &number-of-chars($total-number-of-chars, $total-number-of-visible-chars);
    }
} #`««« sub Sprintf(Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> Str) is export »»»

=begin pod

L<Top of Document|#>

=head3 Printf

=begin item

Same as B<C<Sprintf>> but writes it's output to B<C<$*OUT>> or an arbitary filehandle if you choose.

=end item                                                

=begin item2

defined as

=begin code :lang<raku>

multi sub Printf(Str:D $format-str,
        :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                       Str:D :$ellipsis = '', *@args --> True) is export {
    Sprintf($format-str, :number-of-chars(&number-of-chars), :$ellipsis, |@args).print;
} #`««« sub Fprintf(Str:D $format-str,
         :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                       Str:D :$ellipsis = '', *@args --> True) is export »»»

multi sub Printf(IO::Handle:D $fp, Str:D $format-str,
         :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                       Str:D :$ellipsis = '', *@args --> True) is export {
    $fp.print: Sprintf($format-str, :&number-of-chars, :$ellipsis, |@args);
} #`««« sub Fprintf(my IO::Handle:D $fp, Str:D $format-str,
         :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                       Str:D :$ellipsis = '', *@args --> True) is export »»»

=end code

=end item2

L<Top of Document|#>

=end pod

multi sub Printf(Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> True) is export {
    Sprintf($format-str, :number-of-chars(&number-of-chars), :$ellipsis, |@args).print;
} #`««« sub Fprintf(Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> True) is export »»»

multi sub Printf(IO::Handle:D $fp, Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> True) is export {
    $fp.print: Sprintf($format-str, :&number-of-chars, :$ellipsis, |@args);
} #`««« sub Fprintf(my IO::Handle:D $fp, Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> True) is export »»»
