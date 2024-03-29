unit module Gzz::Text::Utils:ver<0.1.23>:auth<Francis Grizzly Smit (grizzlysmit@smit.id.au)>;

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
=item L<C<UnhighlightBase> & C<UnhighlightBaseActions> and C<Unhighlight> & C<UnhighlightActions>|#unhighlightbase--unhighlightbaseactions-and-unhighlight--unhighlightactions>
=item L<The Functions Provided|#the-functions-provided>

=begin item2
L<Here are 4 functions provided  to B<C<centre>>, B<C<left>> and B<C<right>> justify text even when it is ANSI formatted|#here-are-4-functions-provided-to-centre-left-and-right-justify-text-even-when-it-is-ansi-formatted>
=end item2

=item3 L<centre(…)|#centre>
=item3 L<left(…)|#left>
=item3 L<right(…)|#right>
=item4 L<crop-field(…)|#crop-field>

=item2 L<Sprintf|#sprintf>
=item2 L<Printf|#printf>


=item2 L<MultiT|#multit>

=item2 L<menu(…)|#menu>
=item2 L<input-menu(…)|#input-menu>
=item2 L<dropdown(…)|#dropdown>
=item2 L<lead-dots(…)|#lead-dots>
=item2 L<trailing-dots(…)|#trailing-dots>
=item2 L<dots(…)|#dots>

=NAME Gzz::Text::Utils 
=AUTHOR Francis Grizzly Smit (grizzly@smit.id.au)
=VERSION v0.1.23
=TITLE Gzz::Text::Utils
=SUBTITLE A Raku module to provide text formatting services to Raku programs.

=COPYRIGHT
LGPL V3.0+ L<LICENSE|https://github.com/grizzlysmit/Gzz-Text-Utils/blob/main/LICENSE>

=head1 Introduction

A Raku module to provide text formatting services to Raku programs.

Including a sprintf front-end Sprintf that copes better with Ansi highlighted
text and implements B<C<%U>> and does octal as B<C<0o123>> or B<C<0O123>> if
you choose B<C<%O>> as I hate ambiguity like B<C<0123>> is it an int with
leading zeros or an octal number.
Also there is B<C<%N>> for a new line and B<C<%T>> for a tab helpful when
you want to use single quotes to stop the B«<num> C«$»» specs needing back slashes.

And a B<C<printf>> alike B<C<Printf>>.

Also it does centring and there is a B<C<max-width>> field in the B<C<%>> spec i.e. B<C<%*.*.*E>>, 
and more.

L<Top of Document|#table-of-contents>

=head2 Motivations

When you embed formatting information into your text such as B<bold>, I<italics>, etc ... and B<colours>
standard text formatting will not work e.g. printf, sprintf etc also those functions don't do centring.

Another important thing to note is that even these functions will fail if you include such formatting
in the B<text> field unless you supply a copy of the text with out the formatting characters in it 
in the B<:ref> field i.e. B<C<left($formatted-text, $width, :ref($unformatted-text))>> or 
B<C<text($formatted-text, $width, :$ref)>> if the reference text is in a variable called B<C<$ref>>
or you can write it as B«C«left($formatted-text, $width, ref => $unformatted-text)»»

L<Top of Document|#able-of-contents>

=head3 Update

Fixed the proto type of B<C<left>> etc is now 

=begin code :lang<raku>
sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
            :&number-of-chars:(Int:D, Int:D --> Bool:D) = &left-global-number-of-chars,
               Str:D :$ref = strip-ansi($text), Int:D
                                :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export 
=end code

Where B«C«sub strip-ansi(Str:D $text --> Str:D) is export»» is my new function for striping out ANSI escape sequences so we don't need to supply 
B<C<:$ref>> unless it contains codes that B«C«sub strip-ansi(Str:D $text --> Str:D) is export»» cannot strip out, if so I would like to know so
I can update it to cope with these new codes.

L<Top of Document|#table-of-contents>

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

use Terminal::ANSI::OO :t;
use Term::termios;
use Terminal::Width;
use Terminal::WCWidth;
use Gzz::Prompt;

my @signal; # stuff to run on a interupt/signal #

=begin pod

=head1 Exceptions

=head2 BadArg

 
=begin code :lang<raku>
 
class BadArg is Exception is export
 
=end code
 
BadArg is a exception type that Sprintf will throw in case of badly specified arguments.

L<Top of Document|#table-of-contents>
 

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

L<Top of Document|#table-of-contents>

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

L<Top of Document|#table-of-contents>

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
    token fmt-spec          { [ <false-flags>? <dollar-directive> '$' ]? <flags>?  <width>? 
                             [ [ '.' <precision>? || ',' <false-percn>? ] [ '.' <max-width> || ',' <false-max> ]? ]? <modifier>? <spec-char> }
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
    token false-percn       { [ '*' [ \d+ '$' ]? || \d+ ] }
    token false-max         { [ '*' [ \d+ '$' ]? || \d+ ] }
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
        FormatSpecError.new(:msg('bad $ spec for width: cannot be less than 1 ')).throw if $width-dollar < 0;
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
        FormatSpecError.new(:msg('bad $ spec for precision: cannot be less than 1 ')).throw if $prec-dollar < 0;
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
    #token false-percn       { [ '*' [ \d+ '$' ]? || \d+ ] }
    method false-percn($/) {
        my Str:D $false-percn = ~$/;
        FormatSpecError.new(:msg("Error: found comma (',') instead of dot ('.') before precision in '%' spec.")).throw;
        dd $false-percn if $debug;
        make $false-percn;
    }
    #token false-max         { [ '*' [ \d+ '$' ]? || \d+ ] }
    method false-max($/) {
        my Str:D $false-max = ~$/;
        FormatSpecError.new(:msg("Error: found comma (',') instead of dot ('.') before max-width in '%' spec.")).throw;
        dd $false-max if $debug;
        make $false-max;
    }
    #token max-dollar        { \d+ <?before '$'> }
    method max-dollar($/) {
        my Int:D $max-dollar = +$/ - 1;
        FormatSpecError.new(:msg('bad $ spec for max-width: cannot be less than 1 ')).throw if $max-dollar < 0;
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

L<Top of Document|#table-of-contents>

=head1 C<UnhighlightBase> & C<UnhighlightBaseActions> and C<Unhighlight> & C<UnhighlightActions>

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

L<Top of Document|#table-of-contents>

=head1 The Functions Provided

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

L<Top of Document|#table-of-contents>

=begin head3

Here are 4 functions provided  to B<C<centre>>, B<C<left>> and B<C<right>> justify text even when
it is ANSI formatted.

=end head3

=head3 centre

=item ⋄

=begin item2

Centring text in a field.

=begin code :lang<raku>

sub centre(Str:D $text,
           Int:D $width is copy,
           Str:D $fill = ' ',
           :&number-of-chars:(Int:D, Int:D --> Bool:D) =
                               &centre-global-number-of-chars,
           Str:D :$ref = strip-ansi($text),
           Int:D :$max-width = 0,
           Str:D :$ellipsis = '' --> Str) is export {

=end code

=end item2

=begin item4

Centres the text B<C<$text>> in a field of width B<C<$width>> padding either side with B<C<$fill>>

=end item4

=begin item4

B<Where:>

=end item4

=begin item5

B<C<$fill>>      is the fill char by default B<C<$fill>> is set to a single white space.

=end item5

=begin item6

If  it requires an odd number of padding then the right hand side will get one more char/codepoint.

=end item6

=begin item5

B<C<&number-of-chars>> takes a function which takes 2 B<C<Int:D>>'s and returns a B<C<Bool:D>>.

=end item5

=begin item6

By default this is equal to the closure B<C<centre-global-number-of-chars>> which looks like:

=begin code :lang<raku>

our $centre-total-number-of-chars is export = 0;
our $centre-total-number-of-visible-chars
                                  is export = 0;

sub centre-global-number-of-chars(
      Int:D $number-of-chars,
      Int:D $number-of-visible-chars --> Bool:D) {
    $centre-total-number-of-chars         =
                         $number-of-chars;
    $centre-total-number-of-visible-chars =
                         $number-of-visible-chars;
    return True;
}

=end code

=end item6

=begin item7 

Which is a closure around the variables: B<C<$centre-total-number-of-chars>> and B<C<$centre-total-number-of-visible-chars>>, 
these are global B<C<our>> variables that B<C<Gzz::Text::Utils>> exports.
But you can just use B<C<my>> variables from with a scope, just as well. And make the B<C<sub>> local to the same scope.

L<Top of Document|#table-of-contents>

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

=end item7

=begin item5

The parameter B<C<:$ref>> is by default set to the value of B<C<strip-ansi($text)>>
=end item5

=begin item6

This is used to obtain the length of the of the text using B<I<C<wcswidth(Str)>>> from module B<"C<Terminal::WCWidth>">
which is used to obtain the width the text if printed on the current terminal:

=end item6

=begin item7

B<NB: C<wcswidth> will return -1 if you pass it text with colours etc embedded in them>.

=end item7

=begin item7

B<"C<Terminal::WCWidth>"> is witten by B<bluebear94> L<github:bluebear94|https://raku.land/github:bluebear94> get it with B<zef> or whatever

=end item7

=begin item5

B<C<:$max-width>> sets the maximum width of the field but if set to B<C<0>> (The default), will effectively be infinite (∞).

=end item5

=begin item5

B<C<:$ellipsis>> is used to elide the text if it's too big I recommend either B<C<''>> the default or B<C<'…'>>.

=end item5

L<Top of Document|#table-of-contents>

=head3 left

=item ⋄

=begin item2

Left Justifying text.

=begin code :lang<raku>

sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
        :&number-of-chars:(Int:D, Int:D --> Bool:D) = &left-global-number-of-chars,
                    Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0,
                                        Str:D :$ellipsis = '' --> Str) is export

=end code

=end item2

=item3       B<C<left>> is the same except that except that it puts all the  padding on the right of the field.

L<Top of Document|#table-of-contents>

=head3 right

=item ⋄

=begin item2

Right justifying text.

=begin code :lang<raku>

sub right(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
          :&number-of-chars:(Int:D, Int:D --> Bool:D) = &right-global-number-of-chars,
                    Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0,
                                             Str:D :$ellipsis = '' --> Str) is export

=end code

=end item2





=item3       B<C<right>> is again the same except it puts all the padding on the left and the text to the right.

=begin item3
L<Top of Document|#table-of-contents>

=head4 crop-field

=end item3
=item2 text

=begin item3 

Cropping Text in a field.

=begin code :lang<raku>

sub crop-field(Str:D $text,
               Int:D $w is rw,
               Int:D $width is rw,
               Bool:D $cropped is rw,
               Int:D $max-width,
               Str:D :$ellipsis = '' --> Str:D) is export {

=end code

=end item3

=begin item4

B<C<crop-field>> used by B<C<centre>>, B<C<left>> and B<C<right>> to crop their input if necessary. Copes with
ANSI escape codes.

=end item4

=begin item5

B<Where>

=end item5

=begin item6 

B<C<$text>> is the text to be cropped possibly, wit ANSI escapes embedded. 

=end item6

=begin item6

B<C<$w>> is used to hold the width of B<C<$text>> is read-write so will return that value.

=end item6

=begin item6 

B<C<$width>> is the desired width. Will be used to return the updated width.

=end item6

=begin item6 

B<C<$cropped>> is used to return the status of whether or not B<C<$text>> was truncated.

=end item6

=begin item6 

B<C<$max-width>> is the maximum width we are allowing.

=end item6

=begin item6 

B<C<$ellipsis>> is used to supply a eliding . Empty string by default.

=end item6

=end pod




sub crop-field(Str:D $text,
               Int:D $w is rw,
               Int:D $width is rw,
               Bool:D $cropped is rw,
               Int:D $max-width,
               Str:D :$ellipsis = '' --> Str:D) is export {
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
} #`««« sub crop-field(Str:D $text,
               Int:D $w is rw,
               Int:D $width is rw,
               Bool:D $cropped is rw,
               Int:D $max-width,
               Str:D :$ellipsis = '' --> Str:D) is export »»»

our $centre-total-number-of-chars is export = 0;
our $centre-total-number-of-visible-chars is export = 0;

sub centre-global-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) {
    $centre-total-number-of-chars         = $number-of-chars;
    $centre-total-number-of-visible-chars = $number-of-visible-chars;
    return True;
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


sub centre(Str:D $text,
           Int:D $width is copy,
           Str:D $fill = ' ',
           :&number-of-chars:(Int:D, Int:D --> Bool:D) =
                               &centre-global-number-of-chars,
           Str:D :$ref = strip-ansi($text),
           Int:D :$max-width = 0,
           Str:D :$ellipsis = '' --> Str) is export {
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
    my Int:D $extra-width = $width % $fill-width;
    my Int:D $left-extra-width = $extra-width div 2;
    $extra-width -= $left-extra-width;
    $width div= $fill-width;
    my Int:D $l  = $width div 2;
    $result = $fill x $l ~ $fill.substr(0, $left-extra-width) ~ $result ~ $fill x ($width - $l) ~ $fill.substr(0, $extra-width);
    return $result;
    KEEP {
        &number-of-chars($result.chars, strip-ansi($result).chars);
    }
} #`««« sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                    :&number-of-chars:(Int:D, Int:D --> Bool:D) = &centre-global-number-of-chars,
                        Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export »»»

sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &left-global-number-of-chars,
                    Str:D :$ref = strip-ansi($text),
                    Int:D :$max-width = 0,
                    Str:D :$ellipsis = '' --> Str) is export {
    my Int:D $w  = wcswidth($ref);
    dd $w, $width, $max-width, $text, $ref if $debug;
    my Bool:D $cropped = False;
    my Str $result = crop-field($text, $w, $width,  $cropped, $max-width, :$ellipsis);
    return $result if $cropped;
    return $result if $w < 0;
    return $result if $width <= 0;
    return $result if $width <= $w;
    my Int:D $l  = ($width - $w).abs;
    my Int:D $fill-width = wcswidth($fill);
    $fill-width = 1 unless $fill-width > 0;
    my Int:D $extra-width = $l % $fill-width;
    $l div= $fill-width;
    $result ~= $fill x $l ~ $fill.substr(0, $extra-width);
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
    my Int:D $fill-width = wcswidth($fill);
    $fill-width = 1 unless $fill-width > 0;
    my Int:D $extra-width = $l % $fill-width;
    $l div= $fill-width;
    dd $l, $result if $debug;
    dd $w, $width, $max-width, $result, $ref, $fill if $debug;
    $result = ($fill x $l) ~ $fill.substr(0, $extra-width) ~ $result;
    return $result;
    KEEP {
        &number-of-chars($result.chars, strip-ansi($result).chars);
    }
} #`««« sub right(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                    :&number-of-chars:(Int:D, Int:D --> Bool:D) = &right-global-number-of-chars, Str:D
                        :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export »»»

=begin pod

L<Top of Document|#table-of-contents>

=head2 Sprintf

=begin item

Sprintf like sprintf only it can deal with ANSI highlighted text. And has lots of other options, including the ability
to specify a B<C<$max-width>> using B<C<width.precision.max-width>>, which can be B<C<.*>>, B«C«*<num>$»», B«C«.*»»,  or B«C«<num>»»

=begin code :lang<raku>

sub Sprintf(Str:D $format-str,
           :&number-of-chars:(Int:D, Int:D --> Bool:D) =
                                             &Sprintf-global-number-of-chars,
                                             Str:D :$ellipsis = '',
                                             *@args --> Str) is export 

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
                        || 'n' #`« not implemented and will not be, throws an exception if matched »
                        || 't' #`« not implemented and will not be, throws an exception if matched »
                    ]
                  }
token fmt-spec   { [ <dollar-directive> '$' ]? <flags>?  <width>? [ '.' <precision> [ '.' <max-width> ]? ]? <modifier>? <spec-char> }


=end code


=end item4

=item4 L<Top of Document|#table-of-contents>


=begin item5

Where

=end item5

=begin item6

B<C<dollar-directive>> is a integer >= 1

=end item6                        

=begin item6

B<C<flags>> is any zero or more of:

=end item6                        

=begin item7

B<C<+>> put a plus in front of positive values.

=end item7                        


=begin item7

B<C<->> left justify, right is the default

=end item7                        


=begin item7

B<C<^>>  centre justify.

=end item7                        


=begin item7

B<C<#>> ensure the leading B<C<0>> for any octal, prefix non-zero hexadecimal
with B<C<0x>> or B<C<0X>>, prefix non-zero binary with B<C<0b>> or B<C<0B>>

=end item7                        


=begin item7

B<C<v>> vector flag (used only with d directive)

=end item7                        


=begin item7

B<C<' '>> pad with spaces.

=end item7                        


=begin item7

B<C<0>> pad with zeros.

=end item7                        


=begin item7

B«C«[ <char> ]»» pad with character char where char matches:

=end item7                        

=begin item8

B«C«<-[ <cntrl> \s \[ \] ]> || ' '»» i.e. anything except control characters, white
space (apart from the basic white space (i.e. \x20 or the one with ord 32)),
and B<C<[>> and finally B<C<]>>.

=end item8

=item7 L<Top of Document|#table-of-contents>

=begin item6

B<C<width>> is either an integer or a B<C<*>> or a B<C<*>> followed by an integer >= 1 and a '$'.

=end item6                        


=begin item6

B<C<precision>> is a B<C<.>> followed by either an positive integer or a B<C<*>> or a B<C<*>>
followed by an integer >= 1 and a '$'.

=end item6                        


=begin item6

B<C<max-width>> is a B<C<.>> followed by either an positive integer or a B<C<*>> or a B<C<*>>
followed by an integer >= 1 and a '$'.

=end item6                        

=begin item6

B<C<modifier>> These are not implemented but is one of:

=end item6                        

=begin item7

B<C<hh>> interpret integer as a type B<C<char>> or B<C<unsigned char>>.

=end item7

=begin item7

B<C<h>> interpret integer as a type B<C<short>> or B<C<unsigned short>>.

=end item7

=begin item7

B<C<j>> interpret integer as a type B<C<intmax_t>>, only with a C99 compiler (unportable).

=end item7

=begin item7

B<C<l>> interpret integer as a type B<C<long>> or B<C<unsigned long>>.

=end item7

=begin item7

B<C<ll>> interpret integer as a type B<C<long long>>, B<C<unsigned long long>>, or B<C<quad>> (typically 64-bit integers).

=end item7

=begin item7

B<C<q>> interpret integer as a type B<C<long long>>, B<C<unsigned long long>>, or B<C<quad>> (typically 64-bit integers).

=end item7

=begin item7

B<C<L>> interpret integer as a type B<C<long long>>, B<C<unsigned long long>>, or B<C<quad>> (typically 64-bit integers).

=end item7

=begin item7

B<C<t>> interpret integer as a type B<C<ptrdiff_t>>.

=end item7

=begin item7

B<C<z>> interpret integer as a type B<C<size_t>>.

=end item7

=item6 L<Top of Document|#table-of-contents>

=begin item6

B<C<spec-char>> or the conversion character is one of:

=end item6                        

=begin item7

B<C<c>> a character with the given codepoint.

=end item7                        


=begin item7

B<C<s>> a string.

=end item7                        


=begin item7

B<C<d>> a signed integer, in decimal.

=end item7                        


=begin item7

B<C<u>> an unsigned integer, in decimal.

=end item7                        


=begin item7

B<C<o>> an unsigned integer, in octal, with a B<C<0o>> prepended if the B<C<#>> flag is present.

=end item7                        


=begin item7

B<C<x>> an unsigned integer, in hexadecimal, with a B<C<0x>> prepended if the B<C<#>> flag is present.

=end item7                        


=begin item7

B<C<e>> a floating-point number, in scientific notation.

=end item7                        


=begin item7

B<C<f>> a floating-point number, in fixed decimal notation.

=end item7                        


=begin item7

B<C<g>> a floating-point number, in %e or %f notation.

=end item7                        


=begin item7

B<C<X>> like B<C<x>>, but using uppercase letters, with a B<C<0X>> prepended if the B<C<#>> flag is present.

=end item7                        


=begin item7

B<C<E>> like B<C<e>>, but using an uppercase B<C<E>>.

=end item7                        


=begin item7

B<C<G>> like B<C<g>>, but with an uppercase B<C<E>> (if applicable).

=end item7                        


=begin item7

B<C<b>> an unsigned integer, in binary, with a B<C<0b>> prepended if the B<C<#>> flag is present.

=end item7                        

=begin item7

B<C<B>> an unsigned integer, in binary, with a B<C<0B>> prepended if the B<C<#>> flag is present.

=end item7                        

=begin item7

B<C<i>> a synonym for B<C<%d>>.

=end item7                        

=begin item7

B<C<D>> a synonym for B<C<%ld>>.

=end item7                        

=begin item7

B<C<U>> a synonym for B<C<%lu>>.

=end item7                        

=begin item7

B<C<O>> a synonym for B<C<%lo>>.

=end item7                        

=begin item7

B<C<F>> a synonym for B<C<%f>>.

=end item7                        

=item4 L<Top of Document|#table-of-contents>

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

=item4 L<Top of Document|#table-of-contents>

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
    FormatSpecError.new(:msg("Error bad format-str arg did not parse!")).throw if !@format-str || @format-str[0] === Any;
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
                my $tmp;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp = @args[$cnt]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp = @args[$cnt][0];
                } else {
                    $tmp = @args[$cnt]; # @args[$cnt] is a scalar and should be an Int #
                }
                BadArg.new(:msg("bad star argument width not an Int:D >= -1\nNB: -1 is the same as not being there.")).throw
                                                                                                                    if $tmp !~~ FUInt:D;
                $width   = $tmp;
                $cnt++;
            }elsif %width-spec«kind» eq 'dollar' {
                my Int:D $i = %width-spec«val»;
                dd $i, %width-spec if $debug;
                BadArg.new(:msg("\$ spec for width out of range")).throw unless $i ~~ 0..^@args.elems;
                my Str:D $name = @args[$i].WHAT.^name;
                dd $name if $debug;
                my $tmp;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp = @args[$i]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp = @args[$i][0];
                } else {
                    $tmp = @args[$i]; # @args[$i] is a scalar and should be an Int #
                }
                BadArg.new(:msg("bad star argument width not an Int:D >= -1\nNB: -1 is the same as not being there.")).throw
                                                                                                                    if $tmp !~~ FUInt:D;
                $width   = $tmp;
            } elsif %width-spec«kind» eq 'int' {
                my $tmp  = %width-spec«val»;
                BadArg.new(:msg("bad star argument width not an Int:D >= -1\nNB: -1 is the same as not being there.")).throw
                                                                                                                    if $tmp !~~ FUInt:D;
                $width   = $tmp;
            }
            if %precision-spec«kind» eq 'star' {
                BadArg.new(:msg("arg count out of range not enough args")).throw unless $cnt < @args.elems;
                my Str:D $name = @args[$cnt].WHAT.^name;
                my $tmp;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp   = @args[$cnt]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp   = @args[$cnt][0];
                } else {
                    $tmp   = @args[$cnt]; # @args[$cnt] is a scalar and should be an Int #
                }
                BadArg.new(:msg("bad star argument precision not an Int:D >= -1\nNB: -1 is the same as not being there.")).throw
                                                                                                                    if $tmp !~~ FUInt:D;
                $precision = $tmp;
                $cnt++;
            }elsif %precision-spec«kind» eq 'dollar' {
                my Int:D $i = %precision-spec«val»;
                BadArg.new(:msg("\$ spec for precision out of range")).throw unless $i ~~ 0..^@args.elems;
                my Str:D $name = @args[$i].WHAT.^name;
                my $tmp;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp   = @args[$i]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp   = @args[$i][0];
                } else {
                    $tmp   = @args[$i]; # @args[$i] is a scalar and should be an Int #
                }
                BadArg.new(:msg("bad star argument precision not an Int:D >= -1\nNB: -1 is the same as not being there.")).throw
                                                                                                                    if $tmp !~~ FUInt:D;
                $precision = $tmp;
            } elsif %precision-spec«kind» eq 'int' {
                my $tmp    = %precision-spec«val»;
                BadArg.new(:msg("bad star argument precision not an Int:D >= -1\nNB: -1 is the same as not being there.")).throw
                                                                                                                    if $tmp !~~ FUInt:D;
                $precision = $tmp;
            }
            if %max-width-spec«kind» eq 'star' {
                BadArg.new(:msg("arg count out of range not enough args")).throw unless $cnt < @args.elems;
                my $tmp;
                my Str:D $name = @args[$cnt].WHAT.^name;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp   = @args[$cnt]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp   = @args[$cnt][0];
                } else {
                    $tmp   = @args[$cnt]; # @args[$cnt] is a scalar and should be an Int #
                }
                BadArg.new(:msg("bad star argument max-width not an UInt:D")).throw if $tmp !~~ UInt:D;
                $max-width = $tmp;
                $cnt++;
            }elsif %max-width-spec«kind» eq 'dollar' {
                my Int:D $i = %max-width-spec«val»;
                BadArg.new(:msg("\$ spec for max-width out of range")).throw unless $i ~~ 0..^@args.elems;
                my Str:D $name = @args[$i].WHAT.^name;
                my $tmp;
                if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp   = @args[$i]«arg»;
                } elsif $name eq 'Array' || $name ~~ rx/ ^ 'Array[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                    $tmp   = @args[$i][0];
                } else {
                    $tmp   = @args[$i]; # @args[$i] is a scalar and should be an Int #
                }
                BadArg.new(:msg("bad dollar argument max-width not an UInt:D")).throw if $tmp !~~ UInt:D;
                $max-width = $tmp;
            } elsif %max-width-spec«kind» eq 'int' {
                my $tmp    = %max-width-spec«val»;
                BadArg.new(:msg("bad dollar argument max-width not an UInt:D")).throw if $tmp !~~ UInt:D;
                $max-width = $tmp;
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

L<Top of Document|#table-of-contents>

=head2 Printf

=begin item

Same as B<C<Sprintf>> but writes it's output to B<C<$*OUT>> or an arbitrary filehandle if you choose.

=end item                                                

=begin item2

defined as

=begin code :lang<raku>

multi sub Printf(Str:D $format-str,
        :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                      Str:D :$ellipsis = '', *@args --> True) is export {
    Sprintf($format-str, :&number-of-chars, :$ellipsis, |@args).print;
} #`««« sub Printf(Str:D $format-str,
         :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                      Str:D :$ellipsis = '', *@args --> True) is export »»»

multi sub Printf(IO::Handle:D $fp, Str:D $format-str,
         :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                      Str:D :$ellipsis = '', *@args --> True) is export {
    $fp.print: Sprintf($format-str, :&number-of-chars, :$ellipsis, |@args);
} #`««« sub Printf(my IO::Handle:D $fp, Str:D $format-str,
         :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                      Str:D :$ellipsis = '', *@args --> True) is export »»»

=end code

=end item2

L<Top of Document|#table-of-contents>

=end pod

multi sub Printf(Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> True) is export {
    Sprintf($format-str, :&number-of-chars, :$ellipsis, |@args).print;
} #`««« sub Printf(Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> True) is export »»»

multi sub Printf(IO::Handle:D $fp, Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> True) is export {
    $fp.print: Sprintf($format-str, :&number-of-chars, :$ellipsis, |@args);
} #`««« sub Printf(my IO::Handle:D $fp, Str:D $format-str,
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                        Str:D :$ellipsis = '', *@args --> True) is export »»»

=begin pod

=head3 MultiT

A lot of types but not Any.

=begin code :lang<raku>

subset MultiT is export of Any where * ~~  Str | Int | Rat | Num | Bool | Array;

=end code

=end pod

subset MultiT is export of Any where * ~~  Str | Int | Rat | Num | Bool | Array;

=begin pod

=head3 menu

Display a text based menu.

=begin code :lang<raku>

sub menu(@candidates is copy, Str:D $message = "",
                              :&row:(Int:D $c, Int:D $p, @a,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$highlight-bg-colour = '',
                                     Str:D :$highlight-fg-colour = '',
                                     Str:D :$bg-colour0 = '',
                                     Str:D :$fg-colour0 = '', 
                                     Str:D :$bg-colour1 = '',
                                     Str:D :$fg-colour1 = '' --> Str:D) = &default-row, 
                              :&value:(Int:D $c, @a --> MultiT) = &default-value, 
                              Bool:D :c(:color(:$colour)) is copy = False,
                              Bool:D :s(:$syntax) = False, 
                              Str:D :$highlight-bg-colour = t.bg-color(0, 0, 127) ~ t.bold, 
                              Str:D :$highlight-fg-colour = t.bright-yellow, 
                              Str:D :$bg-colour0 = t.bg-yellow ~ t.bold, 
                              Str:D :$fg-colour0 = t.bright-blue, 
                              Str:D :$bg-colour1 = t.bg-color(0, 127, 0) ~ t.bold, 
                              Str:D :$fg-colour1 = t.bright-blue,  
                              Str:D :$bg-prompt = t.bg-green ~ t.bold, 
                              Str:D :$fg-prompt = t.bright-blue, 
                              Bool:D :$wrap-around = False --> MultiT) is export 

=end code

=item1 Where:
=item2 B<C<@candidates>> is an array of hashes to make up the rows of the menu.
=item2 B<C<$message>> is a message to be displayed at the top of the ascii text form of things (i.e. no colourising).
=item2 B<C<&row>> is is a callback to deal with the rows of the menu.
=item3 Where
=item4 B<C<$c>> is the current row count.
=item4 B<C<$p>> is the current position in the @candidates array.
=item4 B<C<@a>> is the array @candidates itself.
=item4 B<C<$highlight-bg-colour>> is the background colour of the current row (i.e. $c == $p).
=item4 B<C<$highlight-fg-colour>> is the foreground colour of the current row (i.e. $c == $p).
=item4 B<C<$bg-colour0>> is the background colour of the row (i.e. $c %% 2).
=item4 B<C<$fg-colour0>> is the foreground colour of the row (i.e. $c %% 2).
=item4 B<C<$bg-colour1>> is the background colour of the row (i.e. $c % 2 != 0 or not $c %% 2).
=item4 B<C<$fg-colour1>> is the foreground colour of the row (i.e. $c % 2 != 0).
=item2 B<C<&value>> is a callback to get the return value for the function.
=item4 B<C<$c>> is the row selected.
=item4 B<C<$c>> is the array @candidates.
=item2 B<C<:c(:color(:$colour))>> defines a boolean flag to tell whether to use colours or not.
=item3 you can use B<C<:c>>, B<C<:color>> or B<C<:colour>> for this they are all exactly the same.
=item2 B<C<:s(:$syntax)>> same as B<C<$colour>> except it could result in some sort of syntax highlighting. 
=item2 B<C<$highlight-bg-colour>>  the background colour to use to highlight the current line.
=item2 B<C<$highlight-fg-colour>>  the foreground colour to use to highlight the current line.
=item2 B<C<$bg-colour0>> the background colour to use if the line count is divisible by 2.
=item2 B<C<$fg-colour0>> the foreground colour to use if the line count is divisible by 2.
=item2 B<C<$bg-colour1>> the background colour to use if the line count is not divisible by 2.
=item2 B<C<$fg-colour1>> the foreground colour to use if the line count is not divisible by 2.
=item2 B<C<$bg-prompt>>  the background colour to use on the prompt line below the selection area.
=item2 B<C<$fg-prompt>>  the foreground colour to use on the prompt line below the selection area.
=item2 B<C<$wrap-around>> if true then the selection area wraps around, (i.e going past the end wraps around, instead of refusing to go there).
=item3 B<C<$highlight-bg-colour>> to B<C<$wrap-around>> are all just used for the dropdown case (i.e. B<C<$colour>> or B<C<$syntax>> are True)
=item3 B<C<$syntax>> is no different from B<C<$colour>> unless the user defines it using the B<C<:&row>> parameter.
=item4 calls L<dropdown|#dropdown> to do the colour work.

L<Top of Document|#table-of-contents>

=end pod

sub default-row(Int:D $cnt, Int:D $pos, @array,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$highlight-bg-colour = '',
                                     Str:D :$highlight-fg-colour = '',
                                     Str:D :$bg-colour0 = '',
                                     Str:D :$fg-colour0 = '', 
                                     Str:D :$bg-colour1 = '',
                                     Str:D :$fg-colour1 = ''  --> Str:D) is export {
    if $colour || $syntax {
        if $cnt == $pos {
            return $highlight-bg-colour ~ $highlight-fg-colour ~ @array[$pos]«name»;
        } elsif $cnt %% 2 {
            return $bg-colour0 ~ $fg-colour0 ~ @array[$pos]«name»;
        } else {
            return $bg-colour1 ~ $fg-colour1 ~ @array[$pos]«name»;
        }
    } else {
        return @array[$pos]«name»;
    }
} #`««« sub default-row(Int:D $cnt, Int:D $pos, @array,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$highlight-bg-colour = '',
                                     Str:D :$highlight-fg-colour = '',
                                     Str:D :$bg-colour0 = '',
                                     Str:D :$fg-colour0 = '', 
                                     Str:D :$bg-colour1 = '',
                                     Str:D :$fg-colour1 = ''  --> Str:D) is export »»»

sub default-value(Int:D $choice, @array --> MultiT) is export {
    return @array[$choice]«value»;
} # sub default-value(Int:D $choice, @array --> MultiT) is export #

sub menu(@candidates is copy, Str:D $message = "",
                              :&row:(Int:D $c, Int:D $p, @a,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$highlight-bg-colour = '', Str:D :$highlight-fg-colour = '',
                                     Str:D :$bg-colour0 = '', Str:D :$fg-colour0 = '', 
                                     Str:D :$bg-colour1 = '', Str:D :$fg-colour1 = '' --> Str:D) = &default-row, 
                              :&value:(Int:D $c, @a --> MultiT) = &default-value, 
                              Bool:D :c(:color(:$colour)) is copy = False,
                              Bool:D :s(:$syntax) = False, 
                              Str:D :$highlight-bg-colour = t.bg-color(0, 0, 127) ~ t.bold, 
                              Str:D :$highlight-fg-colour = t.bright-yellow, 
                              Str:D :$bg-colour0 = t.bg-yellow ~ t.bold, 
                              Str:D :$fg-colour0 = t.bright-blue, 
                              Str:D :$bg-colour1 = t.bg-color(0, 127, 0) ~ t.bold, 
                              Str:D :$fg-colour1 = t.bright-blue,  
                              Str:D :$bg-prompt = t.bg-green ~ t.bold, 
                              Str:D :$fg-prompt = t.bright-blue, 
                              Bool:D :$wrap-around = False --> MultiT) is export {
    $colour = True if $syntax;
    my %cancel = value => 'cancel', name => 'cancel';
    @candidates.push(%cancel);
    if $colour {
        # insure that the screen is reset on error #
        my &stack = sub ( --> Nil) {
            while @signal {
                my &elt = @signal.pop;
                &elt();
            }
        };
        signal(SIGINT, SIGHUP, SIGQUIT, SIGTERM, SIGQUIT).tap( { &stack(); put t.restore-screen; say "$_ Caught"; exit 0 } );
        my &setup-option-str = sub (Int:D $cnt, Int:D $pos, @array --> Str:D ) {
            return &row($cnt, $pos, @array, :$colour, :$syntax, 
                        :$highlight-bg-colour, :$highlight-fg-colour,
                        :$bg-colour0, :$fg-colour0, 
                        :$bg-colour1, :$bg-colour1);
        };
        my &get-result = sub (MultiT:D $result, Int:D $pos, Int:D $length, @array --> MultiT:D ) {
            my $res = $result;
            if $pos ~~ 0..^$length {
                $res = @array[$pos]«value»;
            }
            return $res
        };
        my &find-pos = sub (MultiT $result, Int:D $pos is copy, @array --> Int:D) {
            for @array.kv -> $idx, %r {
                if %r«value» eq $result {
                    $pos = $idx;
                    last; # found so don't waste resources #
                }
            }
            return $pos;
        }
        my Str:D $result = dropdown(@candidates[@candidates.elems - 1]«value», 40, 'backup',
                                                    &setup-option-str, &find-pos, &get-result,
                                                    @candidates, 
                                                    :$highlight-bg-colour,
                                                    :$highlight-fg-colour,
                                                    :$bg-colour0,
                                                    :$fg-colour0,
                                                    :$bg-colour1,
                                                    :$fg-colour1,
                                                    :$bg-prompt,
                                                    :$fg-prompt,
                                                    :$wrap-around);
        return $result;
    }
    $message.say if $message;
    for @candidates.kv -> $indx, %row {
        my Str:D $candidate = &row($indx, $indx, @candidates);
        "%10d\t%-20s\n".printf($indx, $candidate)
    }
    "use cancel, bye, bye bye, quit, q, or {+@candidates - 1} to quit".say;
    my $choice = -1;
    loop {
        $choice = prompt("choose a candiate 0..{+@candidates - 1} =:> ");
        $choice = +@candidates - 1 if $choice ~~ rx:i/ ^^ \s* [ 'cancel' || 'bye' [ \s* 'bye' ] ? || 'quit' || 'q' ] \s* $$ /;
        if $choice !~~ rx/ ^^ \s* \d* \s* $$ / {
            "$choice: is not a valid option".say;
            redo
        }
        unless 0 <= $choice < +@candidates {
            "$choice: is not a valid option".say;
            redo;
        }
        last;
    }
    my Str $Dir;
    $Dir = &value($choice, @candidates) unless &row($choice,  $choice, @candidates) eq 'cancel';
    #$Dir.say;
    return $Dir;
} #`««« sub menu(@candidates is copy, Str:D $message = "",
                              :&row:(Int:D $c, Int:D $p, @a,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$highlight-bg-colour = '', Str:D :$highlight-fg-colour = '',
                                     Str:D :$bg-colour0 = '', Str:D :$fg-colour0 = '', 
                                     Str:D :$bg-colour1 = '', Str:D :$fg-colour1 = '' --> Str:D) = &default-row, 
                              :&value:(Int:D $c, @a --> MultiT) = &default-value, 
                              Bool:D :c(:color(:$colour)) is copy = False,
                              Bool:D :s(:$syntax) = False, 
                              Str:D :$highlight-bg-colour = t.bg-color(0, 0, 127) ~ t.bold, 
                              Str:D :$highlight-fg-colour = t.bright-yellow, 
                              Str:D :$bg-colour0 = t.bg-yellow ~ t.bold, 
                              Str:D :$fg-colour0 = t.bright-blue, 
                              Str:D :$bg-colour1 = t.bg-color(0, 127, 0) ~ t.bold, 
                              Str:D :$fg-colour1 = t.bright-blue,  
                              Str:D :$bg-prompt = t.bg-green ~ t.bold, 
                              Str:D :$fg-prompt = t.bright-blue, 
                              Bool:D :$wrap-around = False --> MultiT) is export »»»

sub gzzreadline_call(Str:D $prompt, Str:D $prefill, Gzz_readline:D $gzzreadline --> Str ) is export {
    my Str $result;
    try {
        my $original-flags := Term::termios.new(:fd($*IN.native-descriptor)).getattr;
        @signal.push: {
            $original-flags.setattr(:NOW);
        }; # insure that we call the reset command if it dies on a signal #
        $result = $gzzreadline.gzzreadline($prompt, $prefill);
        $original-flags.setattr(:NOW);
        @signal.pop if @signal; # done without signal so remove our handler #
        CATCH {
            default {
                $original-flags.setattr(:NOW);
                @signal.pop if @signal;
                .backtrace;
                .Str.say; .rethrow 
            }
        }
    } # try #
    return $result;
} # sub gzzreadline_call(Str:D $prompt, Str:D $prefill, Gzz_readline:D $gzzreadline --> Str ) #

sub default-row-input-menu(Int:D $cnt, Int:D $pos, @array,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$highlight-bg-colour = '',
                                     Str:D :$highlight-fg-colour = '',
                                     Str:D :$bg-colour0 = '',
                                     Str:D :$fg-colour0 = '', 
                                     Str:D :$bg-colour1 = '',
                                     Str:D :$fg-colour1 = ''  --> Str:D) is export {
    my %row = @array[$pos];
    my Str:D $value = '';
    given %row«type».tclc {
        when 'Int'   {
            my Int:D $val = %row«value».Int;
            $value = ~$val;
        }
        when 'Num'   {
            my Num:D $val = %row«value».Num;
            $value = ~$val;
        }
        when 'Rat'   {
            my Rat:D $val = %row«value».Rat;
            $value = ~$val;
        }
        when 'Bool'  {
            my Str:D $val = %row«value» ?? 'True' !! 'False';
            $value = $val;
        }
        when 'Str'   {
            $value = %row«value».Str;
        }
        when 'Array' {
            my @val = |%row«value»;
            $value = @val.join: ', ';
        }
        when 'Read-only' {
            $value = %row«value».Str;
        }
    }
    if $colour || $syntax {
        if $cnt == $pos {
            return $highlight-bg-colour ~ $highlight-fg-colour ~ $value;
        } elsif $cnt %% 2 {
            return $bg-colour0 ~ $fg-colour0 ~ $value;
        } else {
            return $bg-colour1 ~ $fg-colour1 ~ $value;
        }
    } else {
        return $value;
    }
} #`««« sub default-row-input-menu(Int:D $cnt, Int:D $pos, @array,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$highlight-bg-colour = '',
                                     Str:D :$highlight-fg-colour = '',
                                     Str:D :$bg-colour0 = '',
                                     Str:D :$fg-colour0 = '', 
                                     Str:D :$bg-colour1 = '',
                                     Str:D :$fg-colour1 = ''  --> Str:D) is export »»»

sub default-prompt(Int:D $choice, @candidates,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$bg-prompt = '', Str:D :$fg-prompt = '' --> Str:D) {
    my %candidate = @candidates[$choice];
    if $syntax {
        return $bg-prompt ~ $fg-prompt ~ %candidate«name» ~ ' > ';
    } elsif $colour {
        return $bg-prompt ~ $fg-prompt ~ %candidate«name» ~ ' > ';
    } else {
        return %candidate«name» ~ ' > ';
    }
} #`««« sub default-prompt(Int:D $choice, @candidates --> Str:D) »»»

sub default-edit(Int:D $choice, @candidates is copy, Str:D $edit --> Bool:D) {
    my %candidate = @candidates[$choice];
    given %candidate«type».tclc {
        when 'Int'   {
            my Int:D $val = +$edit;
            @candidates[$choice]«value» = $val;
            return True;
        }
        when 'Num'   {
            my Num:D $val = $edit.Num;
            @candidates[$choice]«value» = $val;
            return True;
        }
        when 'Rat'   {
            my Rat:D $val = $edit.Rat;
            @candidates[$choice]«value» = $val;
            return True;
        }
        when 'Bool'  {
            my Bool:D $val = ! %candidate«value»; # toggle it #
            @candidates[$choice]«value» = $val;
            return True;
        }
        when 'Str'   {
            @candidates[$choice]«value» = $edit;
            return True;
        }
        when 'Array' {
            my @edit = $edit.split(rx/ ',' \s* /);
            @candidates[$choice]«value» = @edit;
            return True;
        }
    }
    return False;
} #`««« sub default-edit(Int:D $choice, @candidates is copy, Str:D $edit --> Bool:D) »»»

=begin pod

=head3 input-menu(…)

=begin code :lang<raku>

sub input-menu(@candidates is copy, Str:D $message = "",
                              :&row:(Int:D $c, Int:D $p, @a,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$highlight-bg-colour = '', Str:D :$highlight-fg-colour = '',
                                     Str:D :$bg-colour0 = '', Str:D :$fg-colour0 = '', 
                                     Str:D :$bg-colour1 = '', Str:D :$fg-colour1 = '' --> Str:D) = &default-row-input-menu, 
                              :&value:(Int:D $c, @a --> MultiT) = &default-value, 
                              :&elt-prompt:(Int:D $c, @a,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$bg-prompt = '', Str:D :$fg-prompt = '' --> Str:D)  = &default-prompt,
                              :&edit:(Int:D $c, @a is copy, Str:D $e --> Bool:D) = &default-edit, 
                              Bool:D :c(:color(:$colour)) is copy = False,
                              Bool:D :s(:$syntax) = False, 
                              Str:D :$highlight-bg-colour = t.bg-color(0, 0, 127) ~ t.bold, 
                              Str:D :$highlight-fg-colour = t.bright-yellow, 
                              Str:D :$bg-colour0 = t.bg-yellow ~ t.bold, 
                              Str:D :$fg-colour0 = t.bright-blue, 
                              Str:D :$bg-colour1 = t.bg-color(0, 127, 0) ~ t.bold, 
                              Str:D :$fg-colour1 = t.bright-blue,  
                              Str:D :$bg-prompt = t.bg-green ~ t.bold, 
                              Str:D :$fg-prompt = t.bright-blue, 
                              Bool:D :$wrap-around = False --> MultiT) is export 

=end code

=item1 Where:
=item2 B<C<@candidates>> is an array of hashes to make up the rows of the menu.
=item2 B<C<$message>> is a message to be displayed at the top of the ascii text form of things (i.e. no colourising).
=item2 B<C<&row>> is is a callback to deal with the rows of the menu.
=item3 Where
=item4 B<C<$c>> is the current row count.
=item4 B<C<$p>> is the current position in the @candidates array.
=item4 B<C<@a>> is the array @candidates itself.
=item4 B<C<$highlight-bg-colour>> is the background colour of the current row (i.e. $c == $p).
=item4 B<C<$highlight-fg-colour>> is the foreground colour of the current row (i.e. $c == $p).
=item4 B<C<$bg-colour0>> is the background colour of the row (i.e. $c %% 2).
=item4 B<C<$fg-colour0>> is the foreground colour of the row (i.e. $c %% 2).
=item4 B<C<$bg-colour1>> is the background colour of the row (i.e. $c % 2 != 0 or not $c %% 2).
=item4 B<C<$fg-colour1>> is the foreground colour of the row (i.e. $c % 2 != 0).
=item2 B<C<&value>> is a callback to get the return value for the function.
=item4 B<C<$c>> is the row selected.
=item4 B<C<$c>> is the array @candidates.

=begin item2

B«C«&elt-prompt:(Int:D $c, @a,
                 Bool:D :$colour = False, Bool:D :$syntax = False,
                 Str:D :$bg-prompt = '', Str:D :$fg-prompt = '' --> Str:D)  = &default-prompt»» 

The callback called by the function to get the prompts to let the user edit the value of the row.

=end item2

=item3 B<C<$c>> is the entry choosen by the user.
=item3 B<C<@a>> is the candidates array.
=item3 B<C<:c(:color(:$colour))>> defines a boolean flag to tell whether to use colours or not.
=item4 you can use B<C<:c>>, B<C<:color>> or B<C<:colour>> for this they are all exactly the same.
=item3 B<C<:s(:$syntax)>> same as B<C<$colour>> except it could result in some sort of syntax highlighting. 
=item3 B<C<$bg-prompt>>  the background colour to use on the prompt line below the selection area.
=item3 B<C<$fg-prompt>>  the foreground colour to use on the prompt line below the selection area.

=begin item2

B«C«&edit:(Int:D $c, @a is copy, Str:D $e --> Bool:D)  = &default-edit»»

The callback called by the function to set the new value of the row.

=end item2

=item3 B<C<$c>> is the entry choosen by the user.
=item3 B<C<@a>> is the candidates array.

=item2 B<C<:c(:color(:$colour))>> defines a boolean flag to tell whether to use colours or not.
=item3 you can use B<C<:c>>, B<C<:color>> or B<C<:colour>> for this they are all exactly the same.
=item2 B<C<:s(:$syntax)>> same as B<C<$colour>> except it could result in some sort of syntax highlighting. 
=item2 B<C<$highlight-bg-colour>>  the background colour to use to highlight the current line.
=item2 B<C<$highlight-fg-colour>>  the foreground colour to use to highlight the current line.
=item2 B<C<$bg-colour0>> the background colour to use if the line count is divisible by 2.
=item2 B<C<$fg-colour0>> the foreground colour to use if the line count is divisible by 2.
=item2 B<C<$bg-colour1>> the background colour to use if the line count is not divisible by 2.
=item2 B<C<$fg-colour1>> the foreground colour to use if the line count is not divisible by 2.
=item2 B<C<$bg-prompt>>  the background colour to use on the prompt line below the selection area.
=item2 B<C<$fg-prompt>>  the foreground colour to use on the prompt line below the selection area.
=item2 B<C<$wrap-around>> if true then the selection area wraps around, (i.e going past the end wraps around, instead of refusing to go there).
=item3 B<C<$highlight-bg-colour>> to B<C<$wrap-around>> are all just used for the dropdown case (i.e. B<C<$colour>> or B<C<$syntax>> are True)
=item3 B<C<$syntax>> is no different from B<C<$colour>> unless the user defines it using the B<C<:&row>> parameter.
=item4 calls L<dropdown|#dropdown> to do the colour work.
=item4 B<NB: the colours stuff is not yet implemented>

L<Top of Document|#table-of-contents>

=end pod

sub input-menu(@candidates is copy, Str:D $message = "",
                              :&row:(Int:D $c, Int:D $p, @a,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$highlight-bg-colour = '', Str:D :$highlight-fg-colour = '',
                                     Str:D :$bg-colour0 = '', Str:D :$fg-colour0 = '', 
                                     Str:D :$bg-colour1 = '', Str:D :$fg-colour1 = '' --> Str:D) = &default-row-input-menu, 
                              :&value:(Int:D $c, @a --> MultiT) = &default-value, 
                              :&elt-prompt:(Int:D $c, @a,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$bg-prompt = '', Str:D :$fg-prompt = '' --> Str:D)  = &default-prompt,
                              :&edit:(Int:D $c, @a is copy, Str:D $e --> Bool:D) = &default-edit, 
                              Bool:D :c(:color(:$colour)) is copy = False,
                              Bool:D :s(:$syntax) = False, 
                              Str:D :$highlight-bg-colour = t.bg-color(0, 0, 127) ~ t.bold, 
                              Str:D :$highlight-fg-colour = t.bright-yellow, 
                              Str:D :$bg-colour0 = t.bg-yellow ~ t.bold, 
                              Str:D :$fg-colour0 = t.bright-blue, 
                              Str:D :$bg-colour1 = t.bg-color(0, 127, 0) ~ t.bold, 
                              Str:D :$fg-colour1 = t.bright-blue,  
                              Str:D :$bg-prompt = t.bg-green ~ t.bold, 
                              Str:D :$fg-prompt = t.bright-blue, 
                              Bool:D :$wrap-around = False --> MultiT) is export {
    $colour = True if $syntax;
    my %cancel = type => 'read-only', value => 'cancel', name => 'cancel';
    @candidates.push(%cancel);
    my %ok = type => 'read-only', value => 'OK', name => 'OK';
    @candidates.push(%ok);
    if $colour {
        die "colour stuff not implemented yet!!!";
        # insure that the screen is reset on error #
        my &stack = sub ( --> Nil) {
            while @signal {
                my &elt = @signal.pop;
                &elt();
            }
        };
        signal(SIGINT, SIGHUP, SIGQUIT, SIGTERM, SIGQUIT).tap( { &stack(); put t.restore-screen; say "$_ Caught"; exit 0 } );
        my &setup-option-str = sub (Int:D $cnt, Int:D $pos, @array --> Str:D ) {
            return &row($cnt, $pos, @array, :$colour, :$syntax, 
                        :$highlight-bg-colour, :$highlight-fg-colour,
                        :$bg-colour0, :$fg-colour0, 
                        :$bg-colour1, :$bg-colour1);
        };
        my &get-result = sub (MultiT:D $result, Int:D $pos, Int:D $length, @array --> MultiT:D ) {
            my $res = $result;
            if $pos ~~ 0..^$length {
                $res = @array[$pos]«value»;
            }
            return $res
        };
        my &find-pos = sub (MultiT $result, Int:D $pos is copy, @array --> Int:D) {
            for @array.kv -> $idx, %r {
                if %r«value» eq $result {
                    $pos = $idx;
                    last; # found so don't waste resources #
                }
            }
            return $pos;
        }
        my Str:D $result = dropdown(@candidates[@candidates.elems - 1]«value», 40, 'backup',
                                                    &setup-option-str, &find-pos, &get-result,
                                                    @candidates, 
                                                    :$highlight-bg-colour,
                                                    :$highlight-fg-colour,
                                                    :$bg-colour0,
                                                    :$fg-colour0,
                                                    :$bg-colour1,
                                                    :$fg-colour1,
                                                    :$bg-prompt,
                                                    :$fg-prompt,
                                                    :$wrap-around);
        return $result;
    }
    put t.save-screen;
    my $choice = -1;
    my $gzzreadline        = Gzz_readline.new;
    OUTTER: loop {
        put t.clear-screen;
        $message.say if $message;
        for @candidates.kv -> $indx, %row {
            my Str:D $candidate = &elt-prompt($indx, @candidates) ~ &row($indx, $indx, @candidates);
            "%10d\t%-20s\n".printf($indx, $candidate)
        }
        "use cancel, bye, bye bye, quit, q, or {+@candidates - 1} to quit or enter to accept the values as is".say;
        loop {
            $choice = prompt("choose a candiate 0..{+@candidates - 1} =:> ");
            $choice = +@candidates - 1 if $choice eq ''; # i.e. an  simple enter #
            $choice = +@candidates - 2 if $choice ~~ rx:i/ ^^ \s* [ 'cancel' || 'bye' [ \s* 'bye' ] ? || 'quit' || 'q' ] \s* $$ /;
            if $choice !~~ rx/ ^^ \s* \d* \s* $$ / {
                "$choice: is not a valid option".say;
                redo OUTTER;
            }
            unless 0 <= $choice < +@candidates {
                "$choice: is not a valid option".say;
                redo OUTTER;
            }
            if &row($choice, $choice, @candidates) eq 'cancel' {
                last OUTTER;
            } elsif &row($choice, $choice, @candidates) eq 'OK' {
                last OUTTER;
            } else {
                my %row = @candidates[$choice];
                given %row«type».tclc {
                    when 'Int'   {
                        my Str:D $edit = gzzreadline_call(&elt-prompt($choice, @candidates), ~&value($choice, @candidates), $gzzreadline);
                        &edit($choice, @candidates, $edit);
                        next OUTTER;
                    }
                    when 'Num'   {
                        my Str:D $edit = gzzreadline_call(&elt-prompt($choice, @candidates), ~&value($choice, @candidates), $gzzreadline);
                        &edit($choice, @candidates, $edit);
                        next OUTTER;
                    }
                    when 'Rat'   {
                        my Str:D $edit = gzzreadline_call(&elt-prompt($choice, @candidates), ~&value($choice, @candidates), $gzzreadline);
                        &edit($choice, @candidates, $edit);
                        next OUTTER;
                    }
                    when 'Bool'  {
                        my Str:D $edit = &value($choice, @candidates) ?? 'True' !! 'False';
                        &edit($choice, @candidates, $edit);
                        next OUTTER;
                    }
                    when 'Str'   {
                        my Str:D $edit = gzzreadline_call(&elt-prompt($choice, @candidates), ~&value($choice, @candidates), $gzzreadline);
                        &edit($choice, @candidates, $edit);
                        next OUTTER;
                    }
                    when 'Array' {
                        my Str:D $edit = gzzreadline_call(&elt-prompt($choice, @candidates), ~&value($choice, @candidates), $gzzreadline);
                        &edit($choice, @candidates, $edit);
                        next OUTTER;
                    }
                } # given %row«type».tclc #
            } # if &row($choice, $choice, @candidates) eq 'cancel' ... elsif &row($choice, $choice, @candidates) eq 'OK' ... else ... #
            last;
        } # loop #
    } # OUTTER: loop #
    my @result;
    if &row($choice, $choice, @candidates) eq 'OK' {
        for @candidates -> %row {
            next if %row«name» eq 'OK' || (%row«name» eq 'cancel');
            @result.push: %row;
        }
    }
    put t.restore-screen;
    return @result;
} #`««« sub input-menu(@candidates is copy, Str:D $message = "",
                              :&row:(Int:D $c, Int:D $p, @a,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$highlight-bg-colour = '', Str:D :$highlight-fg-colour = '',
                                     Str:D :$bg-colour0 = '', Str:D :$fg-colour0 = '', 
                                     Str:D :$bg-colour1 = '', Str:D :$fg-colour1 = '' --> Str:D) = &default-row-input-menu, 
                              :&value:(Int:D $c, @a --> MultiT) = &default-value, 
                              :&elt-prompt:(Int:D $c, @a,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$bg-prompt = '', Str:D :$fg-prompt = '' --> Str:D)  = &default-prompt,
                              :&edit:(Int:D $c, @a is copy, Str:D $e --> Bool:D) = &default-edit, 
                              Bool:D :c(:color(:$colour)) is copy = False,
                              Bool:D :s(:$syntax) = False, 
                              Str:D :$highlight-bg-colour = t.bg-color(0, 0, 127) ~ t.bold, 
                              Str:D :$highlight-fg-colour = t.bright-yellow, 
                              Str:D :$bg-colour0 = t.bg-yellow ~ t.bold, 
                              Str:D :$fg-colour0 = t.bright-blue, 
                              Str:D :$bg-colour1 = t.bg-color(0, 127, 0) ~ t.bold, 
                              Str:D :$fg-colour1 = t.bright-blue,  
                              Str:D :$bg-prompt = t.bg-green ~ t.bold, 
                              Str:D :$fg-prompt = t.bright-blue, 
                              Bool:D :$wrap-around = False --> MultiT) is export »»»

=begin pod


=head3 dropdown(…)

A text based dropdown/list or menu with ANSI colours.

=begin code :lang<raku>

sub dropdown(MultiT:D $id, Int:D $window-height is copy, Str:D $id-name,
                        &setup-option-str:(Int:D $c, Int:D $p, @a --> Str:D),
                        &find-pos:(MultiT $r, Int:D $p, @a --> Int:D),
                        &get-result:(MultiT:D $res, Int:D $p, Int:D $l, @a --> MultiT:D),
                        @array,
                        Str:D :$highlight-bg-colour = t.bg-color(0, 0, 127) ~ t.bold, 
                        Str:D :$highlight-fg-colour = t.bright-yellow, 
                        Str:D :$bg-colour0 = t.bg-yellow ~ t.bold, 
                        Str:D :$fg-colour0 = t.bright-blue, 
                        Str:D :$bg-colour1 = t.bg-color(0, 127, 0) ~ t.bold, 
                        Str:D :$fg-colour1 = t.bright-blue,  
                        Str:D :$bg-prompt = t.bg-green ~ t.bold, 
                        Str:D :$fg-prompt = t.bright-blue, 
                        Bool:D :$wrap-around = False --> MultiT) is export  

=end code

=item Where
=item2 B<C<$id>>               is the starting value of our position in the array/choices.
=item2 B<C<$window-height>>    is the number of rows of characters to display at a time.
=item2 B<C<$id-name>>          is the name of the parameter we are scrolling.
=item2 B<C<&setup-option-str>> is a function that returns the current row.
=item3 Where:
=item4 the arg B<C<$c>> will be the count of the row we are drawing.
=item4 the arg B<C<$p>> will be the position in the array we are at. 
=item4 the arg B<C<@a>> will be the B<C<@array>> supplied to B<C<dropdown(…)>> 
=item5 the use of a function for this means you can compute a much more complex field.
=item2 B<C<&find-pos>> is a function that finds the start position in the B<C<dropdown>>.
=item3 Where:
=item4 the arg B<C<$r>> is the value in the array B<C<@array>> to look for.
=item4 the arg B<C<$p>> is the best approximation of where it might be if you are using it in a loop or something it could be where it last was. 
=item4 the arg B<C<@a>> the argument B<C<@array>> that was passed to B<C<dropdown>>.
=item5 you can name these argument anything you like in you function, and because of the computed nature of this function and the other two you have great flexibility.
=item2 B<C<&get-result>>       is a function to work out the value selected.
=item3 Where:
=item4 the arg B<C<$res>> is the default value to return.
=item4 the arg B<C<$p>> is the current position in the array B<C<@array>> supplied to B<C<dropdown>>.
=item4 the arg B<C<$l>> is the length of the array B<C<@array>>.
=item4 the arg B<C<@a>> is the array B<C<@array>> that was supplied to B<C<dropdown>>.
=item2 B<C<@array>> the array of rows to display.
=item2 B<C<$highlight-bg-colour>>  the background colour to use to highlight the current line.
=item2 B<C<$highlight-fg-colour>>  the foreground colour to use to highlight the current line.
=item2 B<C<$bg-colour0>> the background colour to use if the line count is divisible by 2.
=item2 B<C<$fg-colour0>> the foreground colour to use if the line count is divisible by 2.
=item2 B<C<$bg-colour1>> the background colour to use if the line count is not divisible by 2.
=item2 B<C<$fg-colour1>> the foreground colour to use if the line count is not divisible by 2.
=item2 B<C<$bg-prompt>>  the background colour to use on the prompt line below the selection area.
=item2 B<C<$fg-prompt>>  the foreground colour to use on the prompt line below the selection area.
=item2 B<C<$wrap-around>> if true then the selection area wraps around, (i.e going past the end wraps around, instead of refusing to go there).

=begin item3 

Because we use a function we can compute much more complex results; depending on what we have in B<C<@array>>.
The result can be any of Str, Int, Rat or Num see L<MultiT|#multit>.

=end item3

Here is an example of use.

L<Top of Document|#table-of-contents>

=begin code :lang<raku>

my &setup-option-str = sub (Int:D $cnt, Int:D $p, @array --> Str:D ) {
    my Str $name;
    my Str $cc;
    my Str $flag;
    my Str $prefix;
    if $cnt < 0 {
        $name   = "No country selected yet.";
        $cc     = "";
        $flag   = "";
        $prefix = "you must choose one";
    } else {
        my %row = @array[$cnt];
        $name   = %row«_name»;
        $cc     = %row«cc»;
        try {
            CATCH {
                default {
                    my $Name = $name;
                    $Name ~~ s:g/ <wb> 'and' <wb> /\&/;
                    try {
                        CATCH {
                            default { $flag = uniparse 'PENGUIN'}
                        }
                        $flag = uniparse $Name;
                    }
                }
            }
            $flag   = uniparse $name;
        }
        $prefix = %row«prefix»;
    }
    return "$flag $name: $cc ($prefix)"
};
my &find-pos = sub (MultiT $result, Int:D $pos, @array --> Int:D) {
    for @array.kv -> $idx, %r {
        if %r{$id-name} == $result {
            $pos = $idx;
            last; # found so don't waste resources #
        }
    }
    return $pos;
}
my &get-result = sub (MultiT:D $result, Int:D $pos, Int:D $length, @array --> MultiT:D ) {
    my $res = $result;
    if $pos ~~ 0..^$length {
      my %row = |%(@array[$pos]);
      $res = %row«id» if %row«id»:exists;
    }
    return $res
};
my Int:D $cc-id        = dropdown($cc_id, 20, 'id',
                                    &setup-option-str, &find-pos, &get-result, @_country);
while !valid-country-cc-id($cc-id, %countries) {
    $cc-id             = dropdown($cc-id, 20, 'id',
                                    &setup-option-str, &find-pos, &get-result, @_country);
}

=end code

Or using a much simpler array.
B<NB: from C<menu>>

L<Top of Document|#table-of-contents>

=begin code :lang<raku>

my &setup-option-str = sub (Int:D $cnt, Int:D $pos, @array --> Str:D ) {
    return @array[$cnt];
};
my &get-result = sub (MultiT:D $result, Int:D $pos, Int:D $length, @array --> MultiT:D ) {
    my $res = $result;
    if $pos ~~ 0..^$length {
      $res = @array[$pos];
    }
    return $res
};
my &find-pos = sub (MultiT $result, Int:D $pos, @array --> Int:D) {
    for @array.kv -> $idx, $r {
        if $r eq $result {
            $pos = $idx;
            last; # found so don't waste resources #
        }
    }
    return $pos;
}
my Str:D $result = dropdown(@candidates[@candidates.elems - 1], 40, 'backup',
                                    &setup-option-str, &find-pos, &get-result, @candidates);

=end code

L<Top of Document|#table-of-contents>

=end pod

###############################################################################################################
#                                                                                                             #
#       Emulates dropdown/list behaviour as best you can on a terminal. not a real dropdown always down!!!    #
#                                                                                                             #
###############################################################################################################

sub normalise_top(Int:D $top is copy, Int:D $pos, Int:D $window-height, Int:D $length --> Int:D) {
    $top = $pos - $window-height div 2 if $pos < $top;
    $top = $pos - $window-height div 2 if $pos >= $top + $window-height;
    $top = $length - $window-height if $top + $window-height >= $length;
    $top = 0 if $top < 0;
    return $top;
} # sub normalise_top(Int:D $top is copy, Int:D $pos, Int:D $window-height, Int:D $length --> Int:D) #

sub dropdown(MultiT:D $id, Int:D $window-height is copy, Str:D $id-name,
                        &setup-option-str:(Int:D $c, Int:D $p, @a --> Str:D),
                        &find-pos:(MultiT $r, Int:D $p, @a --> Int:D),
                        &get-result:(MultiT:D $res, Int:D $p, Int:D $l, @a --> MultiT:D),
                        @array,
                        Str:D :$highlight-bg-colour = t.bg-color(0, 0, 127) ~ t.bold, 
                        Str:D :$highlight-fg-colour = t.bright-yellow, 
                        Str:D :$bg-colour0 = t.bg-yellow ~ t.bold, 
                        Str:D :$fg-colour0 = t.bright-blue, 
                        Str:D :$bg-colour1 = t.bg-color(0, 127, 0) ~ t.bold, 
                        Str:D :$fg-colour1 = t.bright-blue,  
                        Str:D :$bg-prompt = t.bg-green ~ t.bold, 
                        Str:D :$fg-prompt = t.bright-blue, 
                        Bool:D :$wrap-around = False --> MultiT) is export  {
    put t.save-screen;
    my MultiT $result = $id;
    try {
        my Int:D $pos    = -1;
        my Int:D $top    = -1;
        my Str:D $bgcolour = '';
        my Str:D $fgcolour = '';
        my Int:D $length = @array.elems;
        $window-height = $length if $window-height > $length;
        $pos = &find-pos($result, $pos, @array);
        $top = normalise_top($top, $pos, $window-height, $length);
        my Str $key;
        my $original-flags := Term::termios.new(:fd($*IN.native-descriptor)).getattr;
        @signal.push: {
            $original-flags.setattr(:NOW);
            print t.show-cursor ~ t.restore-screen;
        };
        #«««
        my $flags := Term::termios.new(:fd($*IN.native-descriptor)).getattr;
        $flags.unset_lflags('ICANON');
        $flags.unset_lflags('ECHO');
        $flags.setattr(:NOW);
        #»»»
        my Int $width = terminal-width;
        $width = 80 if $width === Int;
        my Int:D $m = 0;
        loop (my Int $i = 0; $i < $length; $i++) {
            $m = max($m, hwcswidth(&setup-option-str($i, $pos, @array)));
        } # loop (my Int $i = 0; $i < $length; $i++) #
        $m = max($m, hwcswidth('use up and down arrows or page up and down : and enter to select (esc, q or Q to quit)'));
        my Int:D $w = min($width, $m + 2);
        put t.hide-cursor;
        loop {
            put t.clear-screen;
            loop (my Int $cnt = $top; $cnt < $top + $window-height && $cnt < $length; $cnt++) {
                if $cnt == $pos {
                    $bgcolour = $highlight-bg-colour;
                    $fgcolour = $highlight-fg-colour;
                } elsif $cnt % 2 == 0 {
                    $bgcolour = $bg-colour0;
                    $fgcolour = $fg-colour0;
                } else {
                    $bgcolour = $bg-colour1;
                    $fgcolour = $fg-colour1;
                }
                put $bgcolour ~ $fgcolour ~ Sprintf("%-*s", $w, &setup-option-str($cnt, $pos, @array)) ~ t.text-reset;
            } # loop (my Int $cnt = $top; $cnt <= $top + $window-height; $cnt++) #
            $cnt = $top + $window-height;
            my Int:D $wdth = hwcswidth(trailing-dots('use up and down arrows or page up and down', 42));
            put $bg-prompt ~ $fg-prompt ~ Sprintf("%-*s: %-*s", $wdth, trailing-dots('use up and down arrows or page up and down', 42),
                                                          $w - $wdth - hwcswidth(': '), 'and enter to select (esc, q or Q to quit)') ~ t.text-reset;
            $cnt++;
            $key = $*IN.read(10).decode;
            given $key {
                when 'k'          {
                    $pos--;
                    if $wrap-around {
                        $pos = ($length - 1) if $pos < 0;
                    } else {
                        $pos = 0 if $pos < 0;
                    }
                    $top-- if $pos < $top;
                    $top = normalise_top($top, $pos, $window-height, $length);
                } # up #
                when 'j'          {
                    $pos++;
                    if $wrap-around {
                        $pos = 0 if $pos >= $length;
                    } else {
                        $pos = ($length - 1) if $pos >= $length;
                    }
                    $top++ if $pos >= $top + $window-height;
                    $top = normalise_top($top, $pos, $window-height, $length);
                } # down #
                when "\x[1B][A"   {
                    $pos--;
                    if $wrap-around {
                        $pos = ($length - 1) if $pos < 0;
                    } else {
                        $pos = 0 if $pos < 0;
                    }
                    $top-- if $pos < $top;
                    $top = normalise_top($top, $pos, $window-height, $length);
                } # up #
                when "\x[1B][B"   {
                    $pos++;
                    if $wrap-around {
                        $pos = 0 if $pos >= $length;
                    } else {
                        $pos = ($length - 1) if $pos >= $length;
                    }
                    $top++ if $pos >= $top + $window-height;
                    $top = normalise_top($top, $pos, $window-height, $length);
                } # down #
                when "\x[1B][5~"  {
                    $pos -= ($window-height - 1);
                    if $wrap-around {
                        $pos = ($length - 1) if $pos < 0;
                    } else {
                        $pos = 0 if $pos < 0;
                    }
                    $top -= ($window-height - 1) if $pos < $top;
                    $top = normalise_top($top, $pos, $window-height, $length);
                } # page up #
                when "\x[1B][6~"  {
                    $pos += ($window-height - 1);
                    if $wrap-around {
                        $pos = 0 if $pos >= $length;
                    } else {
                        $pos = ($length - 1) if $pos >= $length;
                    }
                    $top = normalise_top($top, $pos, $window-height, $length);
                } # page down #
                when "\x[1B][H"   {
                    $pos = 0;
                    $top = 0;
                    $top = normalise_top($top, $pos, $window-height, $length);
                } # home #
                when "\x[1B][F"   {
                    $pos = ($length - 1);
                    $top = $length - $window-height;
                    $top = normalise_top($top, $pos, $window-height, $length);
                } # end #
                when "\x[1B]"     { last; } # esc #
                when "\n"         {   # enter #
                                      #`«««
                                      if $pos ~~ 0..^$length {
                                          my %row = |%(@array[$pos]);
                                          $result = %row{$id-name} if %row{$id-name}:exists;
                                      }
                                      # »»»
                                      $result = &get-result($result, $pos, $length, @array);
                                      last;
                                  }
                when "q"         { last; } # quit #
                when "Q"         { last; } # quit #
            }
            $*ERR.say: '=' x 80;
            $*ERR.flush;
        } # loop #
        $original-flags.setattr(:NOW);
        @signal.pop if @signal;
        CATCH {
            default {
                .backtrace;
                .Str.say;
                $original-flags.setattr(:NOW);
                @signal.pop if @signal;
                print t.show-cursor ~ t.restore-screen;
                .rethrow;
            }
        }
    } # try #
    print t.show-cursor ~ t.restore-screen;
    return $result;
} #`««« sub dropdown(MultiT:D $id, Int:D $window-height, Str:D $id-name,
                        &setup-option-str:(Int:D $c, Int:D $p, @a --> Str:D),
                        &find-pos:(MultiT $r, Int:D $p, @a --> Int:D),
                        &get-result:(MultiT:D $res, Int:D $p, Int:D $l, @a --> MultiT:D),
                        @array,
                        Str:D :$highlight-bg-colour = t.bg-color(0, 0, 127) ~ t.bold, 
                        Str:D :$highlight-fg-colour = t.bright-yellow, 
                        Str:D :$bg-colour0 = t.bg-yellow ~ t.bold, 
                        Str:D :$fg-colour0 = t.bright-blue, 
                        Str:D :$bg-colour1 = t.bg-color(0, 127, 0) ~ t.bold, 
                        Str:D :$fg-colour1 = t.bright-blue,  
                        Str:D :$bg-prompt = t.bg-green ~ t.bold, 
                        Str:D :$fg-prompt = t.bright-blue --> MultiT) is export »»»

=begin pod

=head3 lead-dots(…)

Returns B<C<$text>> in a field of B<C<$width>> with a line of dots preceding it.
Sort of like B<C<left>> with B<C<$fill>> defaulting to B<C<.>> but with a single
space between the text and the padding.

=begin code :lang<raku>

sub lead-dots(Str:D $text, Int:D $width is copy, Str:D $fill = '.' --> Str) is export

=end code

=item Where:
=item2 B<C<$text>> the text to be preceded by the dots.
=item2 B<C<$width>> the width of the total field.
=item2 B<C<$fill>> the fill char or string.

L<Top of Document|#table-of-contents>

=end pod

sub lead-dots(Str:D $text, Int:D $width is copy, Str:D $fill = '.' --> Str) is export {
    my Str $result = " $text";
    $width -= hwcswidth($result);
    $width = $width div hwcswidth($fill);
    $result = $fill x $width ~ $result;
    return $result;
} # sub lead-dots(Str:D $text, Int:D $width is copy, Str:D $fill = '.' --> Str) is export #

=begin pod

=head3 trailing-dots(…)

Returns B<C<$text>> in a field of B<C<$width>> with a line of dots trailing after it.
Sort of like B<C<right>> with B<C<$fill>> defaulting to B<C<.>> but with a single
space between the text and the padding.

=begin code :lang<raku>

sub trailing-dots(Str:D $text, Int:D $width is copy, Str:D $fill = '.' --> Str) is export

=end code

=item Where:
=item2 B<C<$text>> the text to be trailed by the dots.
=item2 B<C<$width>> the width of the total field.
=item2 B<C<$fill>> the fill char or string.

L<Top of Document|#table-of-contents>

=end pod

sub trailing-dots(Str:D $text, Int:D $width is copy, Str:D $fill = '.' --> Str) is export {
    my Str $result = $text;
    $width -= hwcswidth($result);
    $width = $width div hwcswidth($fill);
    $result ~= $fill x $width;
    return $result;
} # sub trailing-dots(Str:D $text, Int:D $width is copy, Str:D $fill = '.' --> Str) is export #

=begin pod

=head3 dots(…)

Returns B<C<$text>> in a field of B<C<$width>> with a line of dots preceding it.
Sort of like B<C<left>> with B<C<$fill>> defaulting to B<C<.>>.

=begin code :lang<raku>

sub dots(Str:D $text, Int:D $width is copy, Str:D $fill = '.' --> Str) is export

=end code

=item Where:
=item2 B<C<$text>> the text to be preceded by the dots.
=item2 B<C<$width>> the width of the total field.
=item2 B<C<$fill>> the fill char or string.

L<Top of Document|#table-of-contents>

=end pod

sub dots(Str:D $text, Int:D $width is copy, Str:D $fill = '.' --> Str) is export {
    my Str $result = $text;
    $width -= hwcswidth($result);
    $width = $width div hwcswidth($fill);
    $result ~= $fill x $width;
    return $result;
} # sub dots(Str:D $text, Int:D $width is copy, Str:D $fill = '.' --> Str) is export #
