unit module Gzz::Text::Utils:ver<0.1.0>:auth<Francis Grizzly Smit (grizzlysmit@smit.id.au)>;

=begin pod

=NAME Gzz::Text::Utils 
=AUTHOR Francis Grizzly Smit (grizzly@smit.id.au)
=VERSION 0.1.4
=TITLE Gzz::Text::Utils
=SUBTITLE A Raku module to provide text formating services to Raku progarms.

=COPYRIGHT
GPL V3.0+ L<LICENSE|https://github.com/grizzlysmit/Gzz-Text-Utils/blob/main/LICENSE>

=head2 Introduction

A Raku module to provide text formating services to Raku progarms.

Including a sprintf frontend Sprintf that copes better with Ansi highlighted
text and implements B<C<%U>> and does octal as B<C<0o123>> or B<C<0O123>> if
you choose B<C<%O>> as I hate ambiguity like B<C<0123>> is it an int with
leading zeros or an octal number.
Also there is B<C<%n>> for a new line and B<C<%t>> for a tab helpful when
you want to use single quotes to stop the B<numC<$>> specs needing back slashes.

=head3 Motivations

When you embed formatting information into your text such as B<bold>, I<italics>, etc ... and B<colours>
standard text formatting will not work e.g. printf, sprintf etc also those functions don't do centring.

Another important thing to note is that even these functions will fail if you include such formatting
in the B<text> field unless you supply a copy of the text with out the formatting characters in it 
in the B<:ref> field i.e. B<C<left($formatted-text, $width, :ref($unformatted-text))>> or 
B<C<text($formatted-text, $width, :$ref)>> if the reference text is in a variable called B<C<$ref>>
or you can write it as B«C«left($formatted-text, $width, ref => $unformatted-text)»»

=head4 Update

Fixed the proto type of B<C<left>> etc is now 

=begin code :lang<raku>
sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$precision = 0, Str:D :$ellipsis = '' --> Str) is export
=end code

Where B«C«sub strip-ansi(Str:D $text --> Str:D) is export»» is my new function for striping out ANSI escape sequences so we don't need to supply 
B<C<:$ref>> unless it contains codes that B«C«sub strip-ansi(Str:D $text --> Str:D) is export»» cannot strip out, if so I would like to know so
I can update it to cope with these new codes.

=end pod

INIT my $debug = False;
####################################
#                                  #
#  To turn On or Off debuggging    #
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

=head1 BadArg

 
=begin code :lang<raku>
 
class BadArg is Exception is export
 
=end code
 
BadArg is a exception type that Sprintf will throw in case of badly specified arguments.
 

=end pod

class BadArg is Exception is export {
    has Str:D $.msg = 'Error: bad argument found';
    method message( --> Str:D) {
        $!msg;
    }
}

=begin pod

=head1 ArgParityMissMatch

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

=head1 Format and FormatActions

Format & FormatActions are a grammar and Actions pair that parse out the B<%> spec and normal text chunks of a format string.

For use by Sprintf a sprintf alternative that copes with ANSI highlighted text.

=end pod

grammar FormatBase {
    token format           { <chunks>+ }
    token chunks           { [ <chunk> || '%' <format-spec> ] }
    token chunk            { <-[%]>+ }
    token format-spec      { [ <fmt-esc> || <fmt-spec> ] }
    token fmt-esc          { [      '%' #`« a literal % »
                                 || 'n' #`« a nl i.e. \n char but does not require interpolation so no double quotes required »
                                 || 't' #`« a tab i.e. \t char but does not require interpolation so no double quotes required »
                             ]
                           }
    token fmt-spec         { [ <dollar-directive> '$' ]? <flags>?  <width>? [ '.' <precision> ]? <modifier>? <spec-char> }
    token dollar-directive { \d+ <?before '$'> }
    token flags            { <flag> ** {1 .. 7} }
    token flag             { [      ' '  #`« pad with spaces »
                                 || '+' #`« put a plus in front of positive values » 
                                 || '-'  #`« left justify right is the default »
                                 || '0'  #`« pad with zeros as opposed to spaces »
                                 || '#'  #`« ensure the leading "0" for any octal,
                                             prefix non-zero hexadecimal with "0x"
                                             or "0X", prefix non-zero binary with
                                             "0b" or "0B" »
                                 || 'v'  #`« vector flag (used only with d directive) »
                                 || '^'  #`« centre justify »
                             ] 
                           }
    token width            { [ '*' [ <width-dollar> '$' ]? || <width-int> ] }
    token width-dollar     { \d+ <?before '$'> }
    token width-int        { \d+ }
    token precision        { [ '*' [ <prec-dollar> '$' ]?  || <prec-int>  ] }
    token prec-dollar      { \d+ <?before '$'> }
    token prec-int         { \d+ }
    token modifier         { [           #`« (Note: None of the following have been implemented.) »
                                    'hh' #`« interpret integer as C type "char" or "unsigned char" »
                                 || 'h'  #`« interpret integer as C type "short" or "unsigned short" »
                                 || 'j'  #`« interpret integer as C type "intmax_t", only with a C99 compiler (unportable) »
                                 || 'l'  #`« interpret integer as C type "long" or "unsigned long" »
                                 || 'll' #`« interpret integer as C type "long long", "unsigned long long", or "quad" (typically 64-bit integers) »
                                 || 'q'  #`« interpret integer as C type "long long", "unsigned long long", or "quad" (typically 64-bit integers) »
                                 || 'L'  #`« interpret integer as C type "long long", "unsigned long long", or "quad" (typically 64-bit integers) »
                                 || 't'  #`« interpret integer as C type "ptrdiff_t" »
                                 || 'z'  #`« interpret integer as C type "size_t" »
                             ]
                           }
    token spec-char        { [      'c' #`« a character with the given codepoint »
                                 || 's' #`« a string »
                                 || 'd' #`« a signed integer, in decimal »
                                 || 'u' #`« an unsigned integer, in decimal »
                                 || 'o' #`« an unsigned integer, in octal »
                                 || 'x' #`«	an unsigned integer, in hexadecimal »
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
    method dollar-directive($/) {
        my Int $dollar-directive = +$/ - 1;
        BadArg.new(:msg("bad \$ spec for arg: cannot be less than 1 ")).throw if $dollar-directive < 0;
        dd $dollar-directive if $debug;
        make $dollar-directive;
    }
    method flags($/) {
        my @_flags = $/<flag>».made;
        my $flags = @_flags.join();
        dd $flags if $debug;
        make $flags;
    }
    method flag($/) {
        my $flag = ~$/;
        dd $flag if $debug;
        make $flag;
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
    #token precision        { [ '*' [ <prec-dollar> '$' ]?  || <prec-int>  ] }
    #token prec-dollar      { \d+ }
    #token prec-int         { \d+ }
    method prec-dollar($/) {
        my Int:D $prec-dollar = +$/ - 1;
        BadArg.new(:msg("bad \$ spec for precision: cannot be less than 1 ")).throw if $prec-dollar < 0;
        dd $prec-dollar if $debug;
        make $prec-dollar;
    }
    method prec-int($/) {
        my Int:D $prec-int = +$/;
        dd $prec-int if $debug;
        make $prec-int;
    }
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
    #token fmt-esc          { [ '%' || 'n' ] }
    method fmt-esc($/) {
        my %fmt-esc = type => 'literal', val => ~$/;
        %fmt-esc«val» = "\n" if %fmt-esc«val» eq 'n'; # %n gives us an newline saves on needing double quotes #
        dd %fmt-esc if $debug;
        make %fmt-esc;
    }
    #token fmt-spec         { [ <dollar-directive> '$' ]? <flags>?  <width>? [ '.' <precision> ]? <modifier>? <spec-char> }
    method fmt-spec($/) {
        my %fmt-spec = type => 'fmt-spec', dollar-directive => -1, flags => '', width => { kind => 'empty', val => 0, },
                                        precision => { kind => 'empty', val => 0, }, modifier => '', spec-char => $/<spec-char>.made;
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

=head2 The functions Provided.

=begin item 

strip-ansi

=begin code :lang<raku>

sub strip-ansi(Str:D $text --> Str:D) is export

=end code

Strips out all the ANSI escapes, at the moment just those provided by the B<C<Terminal::ANSI>> 
or B<C<Terminal::ANSI::OO>> modules both available as B<C<Terminal::ANSI>> from zef etc I am not sure
how exhastive that is,  but I will implement any more escapes as I become aware of them. 

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

=head3 here are 3 functions provided  to B<C<centre>>, B<C<left>> and B<C<right>> justify text even when it is ANSI 
formatted.

=begin item

centre

=begin code :lang<raku>

sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$precision = 0, Str:D :$ellipsis = '' --> Str) is export 

=end code

=end item

=begin item2

B<C<centre>> centres the text B<C<$text>> in a field of width B<C<$width>> padding either side with B<C<$fill>>

=end item2

=begin item2

Where:

=end item2

=begin item3

B<C<$fill>>      is the fill char by default B<C<$fill>> is set to a single white space; if you set it to any string that is longer than 1 
code point, it may fail to behave correctly.

=end item3

=begin item4

If  it requires an odd number of padding then the right hand side will get one more char/codepoint.

=end item4

=begin item3

The parameter B<C<:$ref>> is by default set to the value of B<C<strip-ansi($text)>>
this is used to obtain the length of the of the text using B<I<C<wcswidth(Str)>>> which is used to obtain the 
width the text if printed on the current terminal:

B<NB: C<wcswidth> will return -1 if you pass it text with colours etc in-bedded in them>.

=end item3

=begin item

left

=begin code :lang<raku>

sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$precision = 0, Str:D :$ellipsis = '' --> Str) is export 

=end code

=end item

=item2       B<C<left>> is the same except that except that it puts all the  padding on the right of the field.

=begin item

right

=begin code :lang<raku>

sub right(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$precision = 0, Str:D :$ellipsis = '' --> Str) is export 

=end code

=end item





=item2       B<C<right>> is again the same except it puts all the padding on the left and the text to the right.

=end pod


sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$precision = 0, Str:D :$ellipsis = '' --> Str) is export {
    my Int:D $w  = wcswidth($ref);
    if $precision > 0 {
        if $w > $precision {
            my $actions = UnhighlightActions;
            my @chunks = Unhighlight.parse($text, :enc('UTF-8'), :$actions).made;
            my Str:D $tmp = '';
            if $debug {
                my Str:D $line = "$?FILE\[$?LINE] {$?MODULE.gist} {&?ROUTINE.signature.gist}";
                dd @chunks, $w, $precision, $tmp, $line;
            }
            $w = 0;
            my %chunk;
            my Int:D $i = -1;
            loop ($i = 0; $i < @chunks.elems; $i++) {
                %chunk = @chunks[$i];
                $w = hwcswidth($tmp ~ %chunk«val» ~ $ellipsis);
                if $w > $precision {
                    last;
                }
                $tmp ~= %chunk«val»;
                if $debug {
                    my Str:D $line = "\[$?LINE]";
                    dd @chunks, $w, $precision, $tmp, $line;
                }
            }
            if $debug {
                my $line = "$?FILE\[$?LINE] {$?MODULE.gist} {&?ROUTINE.signature.gist}";
                dd @chunks, $w, $precision, $tmp, $line;
            }
            $tmp ~= $ellipsis if $i + 1 < @chunks.elems;
            return $tmp;
        }
        $width = $precision if $width > $precision;
    }
    return $text if $w < 0;
    return $text if $width <= $w;
    my Str $result = $text;
    $width -= $w;
    return $text if $width <= 0;
    my Int:D $fill-width = wcswidth($fill);
    $fill-width = 1 unless $fill-width > 0;
    $width = $width div $fill-width;
    my Int:D $l  = $width div 2;
    $result = $fill x $l ~ $result ~ $fill x ($width - $l);
    return $result;
} # sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$precision = 0, Str:D :$ellipsis = '' --> Str) is export #

sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$precision = 0, Str:D :$ellipsis = '' --> Str) is export {
    my Int:D $w  = wcswidth($ref);
    if $precision > 0 {
        if $w > $precision {
            my $actions = UnhighlightActions;
            my @chunks = Unhighlight.parse($text, :enc('UTF-8'), :$actions).made;
            my Str:D $tmp = '';
            if $debug {
                my Str:D $line = "$?FILE\[$?LINE] {$?MODULE.gist} {&?ROUTINE.signature.gist}";
                dd @chunks, $w, $precision, $tmp, $line;
            }
            $w = 0;
            my %chunk;
            my Int:D $i = -1;
            loop ($i = 0; $i < @chunks.elems; $i++) {
                %chunk = @chunks[$i];
                $w = hwcswidth($tmp ~ %chunk«val» ~ $ellipsis);
                if $w > $precision {
                    last;
                }
                $tmp ~= %chunk«val»;
                if $debug {
                    my Str:D $line = "\[$?LINE]";
                    dd @chunks, $w, $precision, $tmp, $line;
                }
            }
            if $debug {
                my $line = "$?FILE\[$?LINE] {$?MODULE.gist} {&?ROUTINE.signature.gist}";
                dd @chunks, $w, $precision, $tmp, $line;
            }
            $tmp ~= $ellipsis if $i + 1 < @chunks.elems;
            return $tmp;
        }
        $width = $precision if $width > $precision;
    }
    return $text if $w < 0;
    return $text if $width <= 0;
    return $text if $width <= $w;
    my Int:D $l  = ($width - $w).abs;
    my Str:D $result = $text ~ ($fill x $l);
    return $result;
} # sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$precision = 0, Str:D :$ellipsis = '' --> Str) is export #

sub right(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$precision = 0, Str:D :$ellipsis = '' --> Str) is export {
    my Int:D $w  = wcswidth($ref);
    if $precision > 0 {
        dd $precision, $width, $w if $debug;
        if $w > $precision {
            my $actions = UnhighlightActions;
            my @chunks = Unhighlight.parse($text, :enc('UTF-8'), :$actions).made;
            my Str:D $tmp = '';
            if $debug {
                my Str:D $line = "$?FILE\[$?LINE] {$?MODULE.gist} {&?ROUTINE.signature.gist}";
                dd @chunks, $w, $precision, $tmp, $line;
            }
            $w = 0;
            my %chunk;
            my Int:D $i = -1;
            loop ($i = 0; $i < @chunks.elems; $i++) {
                %chunk = @chunks[$i];
                $w = hwcswidth($tmp ~ %chunk«val» ~ $ellipsis);
                if $w > $precision {
                    last;
                }
                $tmp ~= %chunk«val»;
                if $debug {
                    my Str:D $line = "\[$?LINE]";
                    dd @chunks, %chunk, $w, $precision, $tmp, $line;
                }
            }
            if $debug {
                my $line = "$?FILE\[$?LINE] {$?MODULE.gist} {&?ROUTINE.signature.gist}";
                dd @chunks, $w, $precision, $tmp, $line if $debug;
            }
            $tmp ~= $ellipsis if $i + 1 < @chunks.elems;
            return $tmp;
        }
        $width = $precision if $width > $precision;
    }
    return $text if $w < 0;
    return $text if $width <= 0;
    return $text if $width <= $w;
    my Int:D $l  = $width - $w;
    dd $l, $text if $debug;
    my Str:D $result = ($fill x $l) ~ $text;
    return $result;
} # sub right(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$precision = 0, Str:D :$ellipsis = '' --> Str) is export #

=begin pod

=head2 sub Sprintf(Str:D $format-str, *@args --> Str) is export 

=end pod

sub Sprintf(Str:D $format-str, *@args --> Str) is export {
    my $actions = FormatActions;
    my @format-str = Format.parse($format-str, :enc('UTF-8'), :$actions).made;
    dd @format-str if $debug;
    my Int:D $specs = [+] (@format-str.grep( -> %elt { %elt«type» eq 'fmt-spec' }).map( -> %e {
                                                                                                 my Int:D $n = 1;
                                                                                                 $n-- if %e«dollar-directive» > 0;
                                                                                                 $n++ if %e«width»«kind» eq 'star';
                                                                                                 $n++ if %e«precision»«kind» eq 'star';
                                                                                                 $n;
                                                                                             }));
    ArgParityMissMatch.new(:msg("Error: argument parity error; expected $specs args got {@args.elems}")).throw if $specs != @args.elems;
    my Str:D $result = '';
    my Int:D $cnt = 0;
    dd @format-str if $debug;
    for @format-str -> %elt {
        my Str:D $type = %elt«type»;
        if $type eq 'literal' {
            $result ~= %elt«val»;
        } elsif $type eq 'fmt-spec' {
            #my %fmt-spec = type => 'fmt-spec', dollar-directive => -1, flags => '',
            #                   width => { kind => 'empty', val => 0, }
            #                   precision => { kind => 'empty', val => 0, },
            #                   modifier => '', spec-char => $/<spec-char>.made;
            my         %width-spec = %elt«width»;
            my     %precision-spec = %elt«precision»;
            my Int:D $width        = -1;
            my Int:D $precision    = -1;
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
                BadArg.new(:msg("\$ spec for width out of range")).throw unless $i ~~ 0..^@args.elems;
                my Str:D $name = @args[$i].WHAT.^name;
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
            my $arg;
            my $ref;
            my Int:D $dollar-directive = %elt«dollar-directive»;
            my Int:D $i = $dollar-directive;
            BadArg.new(:msg("\$ spec for arg out of range")).throw unless $i < @args.elems;
            if $dollar-directive < 1 {
                $i = $cnt;
                $cnt++;
            }
            my Str:D $name = @args[$i].WHAT.^name;
            if $name eq 'Hash' || $name ~~ rx/ ^ 'Hash[' [ \w+ [ [ '-' || '::' || ':' ] \w+ ]* ] ']' $ / {
                $arg = @args[$i]«arg»;
                $ref = @args[$i]«ref»;
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
            my Str:D  $flags       = %elt«flags»;
            my Str:D  $padding     = '';
            my Bool:D $force-sign  = False;
            my Str:D  $justify     = '';
            my Bool:D $type-prefix = False;
            my Bool:D $vector      = False;
            $padding               = ' '  if $flags.contains(' ');
            $force-sign            = True if $flags.contains('+');
            $padding               = '0'  if $flags.contains('0');
            $justify               = '^'  if $flags.contains('^');
            $justify               = '-'  if $flags.contains('-');
            $type-prefix           = True if $flags.contains('#');
            $vector                = True if $flags.contains('v');
            my Str:D $modifier     = %elt«modifier»; # ignore these for now #
            my Str:D $spec-char    = %elt«spec-char»;
            $name = $arg.WHAT.^name;
            given $spec-char {
                when 'c' {
                             $arg .=Str;
                             BadArg.new(:msg("arg should be one codepoint: {$arg.codes} found")).throw if $arg.codes != 1;
                             if $justify eq '' {
                                 $result ~=  right($arg, $width, $padding, :$ref, :$precision);
                             } elsif $justify eq '-' {
                                 $result ~=  left($arg, $width, $padding, :$ref, :$precision);
                             } elsif $justify eq '^' {
                                 $result ~=  centre($arg, $width, $padding, :$ref, :$precision);
                             }
                         }
                when 's' {
                             $arg .=Str;
                             if $justify eq '' {
                                 $result ~=  right($arg, $width, $padding, :$ref, :$precision, :ellipsis('…'));
                             } elsif $justify eq '-' {
                                 $result ~=  left($arg, $width, $padding, :$ref, :$precision, :ellipsis('…'));
                             } elsif $justify eq '^' {
                                 $result ~=  centre($arg, $width, $padding, :$ref, :$precision, :ellipsis('…'));
                             }
                         }
                when 'd'|'i'|'D' {
                                       $arg .=Int;
                                       my Str:D $fmt = '%';
                                       $fmt ~= '+' if $force-sign;
                                       $fmt ~= '-' if $justify eq '-';
                                       $fmt ~= $padding;
                                       $fmt ~= '#' if $type-prefix;
                                       $fmt ~= 'v' if $vector;
                                       if $padding eq '0' {
                                           if $width >= 0 { # centre etc make no sense here #
                                               if $precision >= 0 {
                                                   $fmt ~= '*.*';
                                                   $fmt ~= $spec-char;
                                                   $result ~= sprintf($fmt, $width, $precision, $arg);
                                               } else {
                                                   $fmt ~= '*';
                                                   $fmt ~= $spec-char;
                                                   $result ~= sprintf($fmt, $width, $arg);
                                               }
                                           } else {
                                               if $precision >= 0 {
                                                   $fmt ~= '.*';
                                                   $fmt ~= $spec-char;
                                                   $result ~= sprintf($fmt, $precision, $arg);
                                               } else {
                                                   $fmt ~= $spec-char;
                                                   $result ~= sprintf($fmt, $arg);
                                               }
                                           }
                                       } elsif $padding eq ' ' {
                                           if $justify eq '^' {
                                               if $width >= 0 {
                                                   if $precision >= 0 {
                                                       $fmt ~= '.*';
                                                       $fmt ~= $spec-char;
                                                       $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding);
                                                   } else {
                                                       $fmt ~= $spec-char;
                                                       $result ~= centre(sprintf($fmt, $arg), $width, $padding);
                                                   }
                                               } else { # $width < 0 #
                                                   if $precision >= 0 {
                                                       $fmt ~= '.*';
                                                       $fmt ~= $spec-char;
                                                       $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding);
                                                   } else {
                                                       $fmt ~= $spec-char;
                                                       $result ~= centre(sprintf($fmt, $arg), $width, $padding);
                                                   }
                                               } # $width < 0 #
                                           } else { # justify is either '-' or '' i.e. left or right #
                                               if $precision >= 0 {
                                                   $fmt ~= '.*';
                                                   $fmt ~= $spec-char;
                                                   $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding);
                                               } else {
                                                   $fmt ~= $spec-char;
                                                   $result ~= centre(sprintf($fmt, $arg), $width, $padding);
                                               }
                                           } # justify is either '-' or '' i.e. left or right #
                                       } else { # $padding eq '' #
                                           if $justify eq '^' {
                                               if $width >= 0 {
                                                   if $precision >= 0 {
                                                       $fmt ~= '.*';
                                                       $fmt ~= $spec-char;
                                                       $result ~= centre(sprintf($fmt, $precision, $arg), $width);
                                                   } else {
                                                       $fmt ~= $spec-char;
                                                       $result ~= centre(sprintf($fmt, $arg), $width);
                                                   }
                                               } else { # $width < 0 #
                                                   if $precision >= 0 {
                                                       $fmt ~= '.*';
                                                       $fmt ~= $spec-char;
                                                       $result ~= sprintf($fmt, $precision, $arg);
                                                   } else {
                                                       $fmt ~= $spec-char;
                                                       $result ~= sprintf($fmt, $arg);
                                                   }
                                               } # $width < 0 #
                                           } else { # justify is either '-' or '' i.e. left or right #
                                               if $precision >= 0 {
                                                   $fmt ~= '.*';
                                                   $fmt ~= $spec-char;
                                                   $result ~= centre(sprintf($fmt, $precision, $arg), $width);
                                               } else {
                                                   $fmt ~= $spec-char;
                                                   $result ~= centre(sprintf($fmt, $arg), $width);
                                               }
                                           } # justify is either '-' or '' i.e. left or right #
                                       } # $padding eq '' #
                                 } # when 'd', 'i', 'D' #
                when 'u'|'U' {
                                 $arg .=Int;
                                 BadArg.new(:msg("argument cannot be negative for char spec: $spec-char")).throw if $arg < 0;
                                 my Str:D $fmt = '%';
                                 $fmt ~= '+' if $force-sign;
                                 $fmt ~= '-' if $justify eq '-';
                                 $fmt ~= $padding;
                                 $fmt ~= '#' if $type-prefix;
                                 $fmt ~= 'v' if $vector;
                                 if $padding eq '0' {
                                     if $width >= 0 { # centre etc make no sense here #
                                         if $precision >= 0 {
                                             $fmt ~= $padding;
                                             #$fmt ~= '*';
                                             $fmt ~= $spec-char.lc;
                                             dd $arg if $debug;
                                             $result ~= right(sprintf($fmt, $arg), $width, $padding, :$precision, :ellipsis('…'));
                                         } else {
                                             $fmt ~= $padding;
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char.lc;
                                             $result ~= sprintf($fmt, $width, $arg);
                                         }
                                     } else {
                                         if $precision >= 0 {
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char.lc;
                                             $result ~= sprintf($fmt, $precision, $arg);
                                         } else {
                                             $fmt ~= $spec-char.lc;
                                             $result ~= sprintf($fmt, $arg);
                                         }
                                     }
                                 } elsif $padding eq ' ' {
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '*';
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding, :$precision);
                                             } else {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= $padding;
                                                 $fmt ~= '*';
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding);
                                             } else {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char.lc;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding);
                                             }
                                         } else {
                                             $fmt ~= $spec-char.lc;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width, $padding);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } else { # $padding eq '' #
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '*';
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width);
                                             } else {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= centre(sprintf($fmt, $arg), $width);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '*';
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= sprintf($fmt, $precision, $arg);
                                             } else {
                                                 $fmt ~= $spec-char.lc;
                                                 $result ~= sprintf($fmt, $arg);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char.lc;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width);
                                             }
                                         } else {
                                             $fmt ~= $spec-char.lc;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } # $padding eq '' #
                             } # when 'u', 'U' #
                when 'o'|'O' {
                                  $arg .=Int;
                                  my Str:D $fmt = '%';
                                  $fmt ~= '+' if $force-sign;
                                  $fmt ~= '-' if $justify eq '-';
                                  $fmt ~= $padding;
                                  $fmt ~= 'v' if $vector;
                                  if $padding eq '0' {
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char.lc;
                                              if $type-prefix {
                                                  $result ~= '0'~ $spec-char ~ sprintf($fmt, $width - 2, $precision - 2, $arg);
                                              } else {
                                                  $result ~= sprintf($fmt, $width, $precision, $arg);
                                              }
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char.lc;
                                              if $type-prefix {
                                                  $result ~= '0'~ $spec-char ~ sprintf($fmt, $width - 2, $arg);
                                              } else {
                                                  $result ~= sprintf($fmt, $width, $arg);
                                              }
                                          }
                                      } else {
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char.lc;
                                              if $type-prefix {
                                                  $result ~= '0'~ $spec-char ~ sprintf($fmt, $precision - 2, $arg);
                                              } else {
                                                  $result ~= sprintf($fmt, $precision, $arg);
                                              }
                                          } else {
                                              $fmt ~= $spec-char.lc;
                                              $result ~= sprintf($fmt, $arg);
                                              if $type-prefix {
                                                  $result ~= '0'~ $spec-char ~ sprintf($fmt, $arg);
                                              } else {
                                                  $result ~= sprintf($fmt, $arg);
                                              }
                                          }
                                      }
                                  } elsif $padding eq ' ' {
                                      if $justify eq '^' {
                                          if $width >= 0 {
                                              if $precision >= 0 {
                                                  $fmt ~= '.*';
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $precision - 2, $arg), $width, $padding);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding);
                                                  }
                                              } else {
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $arg), $width, $padding);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding);
                                                  }
                                              }
                                          } else { # $width < 0 #
                                              if $precision >= 0 {
                                                  $fmt ~= '.*';
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= '0' ~ $spec-char ~ sprintf($fmt, $precision - 2, $arg);
                                                  } else {
                                                      $result ~= sprintf($fmt, $precision, $arg);
                                                  }
                                              } else {
                                                  $fmt ~= $spec-char.lc;
                                                  $result ~= centre(sprintf($fmt, $arg), $width, $padding);
                                                  if $type-prefix {
                                                      $result ~= '0' ~ $spec-char ~ sprintf($fmt, $arg);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding);
                                                  }
                                              }
                                          } # $width < 0 #
                                      } else { # justify is either '-' or '' i.e. left or right #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char.lc;
                                              if $justify eq '-' {
                                                  if $type-prefix {
                                                      $result ~= left('0' ~ $spec-char ~ sprintf($fmt, $precision, $arg), $width, $padding);
                                                  } else {
                                                      $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding);
                                                  }
                                              } else {
                                                  if $type-prefix {
                                                      $result ~= right('0' ~ $spec-char ~ sprintf($fmt, $precision - 2, $arg), $width, $padding);
                                                  } else {
                                                      $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding);
                                                  }
                                              }
                                          } else {
                                              $fmt ~= $spec-char.lc;
                                              if $justify eq '-' {
                                                  $result ~= left(sprintf($fmt, $arg), $width, $padding);
                                                  if $type-prefix {
                                                      $result ~= left('0' ~ $spec-char ~ sprintf($fmt, $arg), $width, $padding);
                                                  } else {
                                                      $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding);
                                                  }
                                              } else {
                                                  if $type-prefix {
                                                      $result ~= right('0' ~ $spec-char ~ sprintf($fmt, $arg), $width, $padding);
                                                  } else {
                                                      $result ~= right(sprintf($fmt, $arg), $width, $padding);
                                                  }
                                              }
                                          }
                                      } # justify is either '-' or '' i.e. left or right #
                                  } else { # $padding eq '' #
                                      if $justify eq '^' {
                                          if $width >= 0 {
                                              if $precision >= 0 {
                                                  $fmt ~= '.*';
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $precision, $arg), $width);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $precision, $arg), $width);
                                                  }
                                              } else {
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= centre('0' ~ $spec-char ~ sprintf($fmt, $arg), $width);
                                                  } else {
                                                      $result ~= centre(sprintf($fmt, $arg), $width);
                                                  }
                                              }
                                          } else { # $width < 0 #
                                              if $precision >= 0 {
                                                  $fmt ~= '.*';
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= '0' ~ $spec-char ~ sprintf($fmt, $precision, $arg);
                                                  } else {
                                                      $result ~= sprintf($fmt, $precision, $arg);
                                                  }
                                              } else {
                                                  $fmt ~= $spec-char.lc;
                                                  if $type-prefix {
                                                      $result ~= '0' ~ $spec-char ~ sprintf($fmt, $arg);
                                                  } else {
                                                      $result ~= sprintf($fmt, $arg);
                                                  }
                                              }
                                          } # $width < 0 #
                                      } else { # justify is either '-' or '' i.e. left or right #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char.lc;
                                              if $justify eq '-' {
                                                  if $type-prefix {
                                                      $result ~= left('0' ~ $spec-char ~ sprintf($fmt, $precision - 2, $arg), $width);
                                                  } else {
                                                      $result ~= left(sprintf($fmt, $precision, $arg), $width);
                                                  }
                                              } else {
                                                  if $type-prefix {
                                                      $result ~= right('0' ~ $spec-char ~ sprintf($fmt, $precision, $arg), $width);
                                                  } else {
                                                      $result ~= right(sprintf($fmt, $precision, $arg), $width);
                                                  }
                                              }
                                          } else {
                                              $fmt ~= $spec-char.lc;
                                              if $justify eq '-' {
                                                  if $type-prefix {
                                                      $result ~= left('0' ~ $spec-char ~ sprintf($fmt, $arg), $width);
                                                  } else {
                                                      $result ~= left(sprintf($fmt, $arg), $width);
                                                  }
                                              } else {
                                                  if $type-prefix {
                                                      $result ~= right('0' ~ $spec-char ~ sprintf($fmt, $arg), $width);
                                                  } else {
                                                      $result ~= right(sprintf($fmt, $arg), $width);
                                                  }
                                              }
                                          }
                                      } # justify is either '-' or '' i.e. left or right #
                                  } # $padding eq '' #
                             } # when 'o', 'O' #
                when 'x'|'X' {
                                 $arg .=Int;
                                 my Str:D $fmt = '%';
                                 $fmt ~= '+' if $force-sign;
                                 $fmt ~= '-' if $justify eq '-';
                                 $fmt ~= $padding;
                                 $fmt ~= 'v' if $vector;
                                 if $padding eq '0' {
                                     if $width >= 0 { # centre etc make no sense here #
                                         if $precision >= 0 {
                                             $fmt ~= '*.*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= '0'~ $spec-char ~ sprintf($fmt, $width - 2, $precision - 2, $arg);
                                             } else {
                                                 $result ~= sprintf($fmt, $width, $precision, $arg);
                                             }
                                         } else {
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= '0'~ $spec-char ~ sprintf($fmt, $width - 2, $arg);
                                             } else {
                                                 $result ~= sprintf($fmt, $width, $arg);
                                             }
                                         }
                                     } else {
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= '0'~ $spec-char ~ sprintf($fmt, $precision - 2, $arg);
                                             } else {
                                                 $result ~= sprintf($fmt, $precision, $arg);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             $result ~= sprintf($fmt, $arg);
                                             if $type-prefix {
                                                 $result ~= '0'~ $spec-char ~ sprintf($fmt, $arg);
                                             } else {
                                                 $result ~= sprintf($fmt, $arg);
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
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width, $padding);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } else { # $padding eq '' #
                                     $fmt ~= '#' if $type-prefix;
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= sprintf($fmt, $precision, $arg);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= sprintf($fmt, $arg);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } # $padding eq '' #
                             } # when 'x', 'X' #
                when 'e'|'E' {
                                  $arg .=Int;
                                  my Str:D $fmt = '%';
                                  $fmt ~= '+' if $force-sign;
                                  $fmt ~= '-' if $justify eq '-';
                                  $fmt ~= $padding;
                                  $fmt ~= 'v' if $vector;
                                  $fmt ~= '#' if $type-prefix;
                                  ##########################################################
                                  #                                                        #
                                  #   centring makes no sense here  so we will not do it   #
                                  #                                                        #
                                  ##########################################################
                                  if $padding eq '0' {
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $precision, $arg);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $arg);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $precision, $arg);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $arg);
                                          }
                                      }
                                  } elsif $padding eq ' ' || $padding eq '' {
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $precision, $arg);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $arg);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $precision, $arg);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $arg);
                                          }
                                      }
                                  }
                             } # when 'e', 'E' #
                when 'f'|'F' {
                                  $arg .=Int;
                                  my Str:D $fmt = '%';
                                  $fmt ~= '+' if $force-sign;
                                  $fmt ~= '-' if $justify eq '-';
                                  $fmt ~= $padding;
                                  $fmt ~= 'v' if $vector;
                                  $fmt ~= '#' if $type-prefix;
                                  ##########################################################
                                  #                                                        #
                                  #   centring makes no sense here  so we will not do it   #
                                  #                                                        #
                                  ##########################################################
                                  if $padding eq '0' {
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $precision, $arg);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $arg);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $precision, $arg);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $arg);
                                          }
                                      }
                                  } elsif $padding eq ' ' || $padding eq '' {
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $precision, $arg);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $arg);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $precision, $arg);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $arg);
                                          }
                                      }
                                  }
                             } # when 'f', 'F' #
                when 'g'|'G' {
                                  $arg .=Int;
                                  my Str:D $fmt = '%';
                                  $fmt ~= '+' if $force-sign;
                                  $fmt ~= '-' if $justify eq '-';
                                  $fmt ~= $padding;
                                  $fmt ~= 'v' if $vector;
                                  $fmt ~= '#' if $type-prefix;
                                  ##########################################################
                                  #                                                        #
                                  #   centring makes no sense here  so we will not do it   #
                                  #                                                        #
                                  ##########################################################
                                  if $padding eq '0' {
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $precision, $arg);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $arg);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $precision, $arg);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $arg);
                                          }
                                      }
                                  } elsif $padding eq ' ' || $padding eq '' {
                                      if $width >= 0 { # centre etc make no sense here #
                                          if $precision >= 0 {
                                              $fmt ~= '*.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $precision, $arg);
                                          } else {
                                              $fmt ~= '*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $width, $arg);
                                          }
                                      } else { # $width < 0 #
                                          if $precision >= 0 {
                                              $fmt ~= '.*';
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $precision, $arg);
                                          } else {
                                              $fmt ~= $spec-char;
                                              $result ~= sprintf($fmt, $arg);
                                          }
                                      }
                                  }
                             } # when 'g', 'G' #
                when 'b'|'B' {
                                 $arg .=Int;
                                 my Str:D $fmt = '%';
                                 $fmt ~= '+' if $force-sign;
                                 $fmt ~= '-' if $justify eq '-';
                                 $fmt ~= $padding;
                                 $fmt ~= 'v' if $vector;
                                 if $padding eq '0' {
                                     if $width >= 0 { # centre etc make no sense here #
                                         if $precision >= 0 {
                                             $fmt ~= '*.*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= '0'~ $spec-char ~ sprintf($fmt, $width - 2, $precision - 2, $arg);
                                             } else {
                                                 $result ~= sprintf($fmt, $width, $precision, $arg);
                                             }
                                         } else {
                                             $fmt ~= '*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= '0'~ $spec-char ~ sprintf($fmt, $width - 2, $arg);
                                             } else {
                                                 $result ~= sprintf($fmt, $width, $arg);
                                             }
                                         }
                                     } else {
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $type-prefix {
                                                 $result ~= '0'~ $spec-char ~ sprintf($fmt, $precision - 2, $arg);
                                             } else {
                                                 $result ~= sprintf($fmt, $precision, $arg);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             $result ~= sprintf($fmt, $arg);
                                             if $type-prefix {
                                                 $result ~= '0'~ $spec-char ~ sprintf($fmt, $arg);
                                             } else {
                                                 $result ~= sprintf($fmt, $arg);
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
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width, $padding);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width, $padding);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width, $padding);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width, $padding);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width, $padding);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width, $padding);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } else { # $padding eq '' #
                                     $fmt ~= '#' if $type-prefix;
                                     if $justify eq '^' {
                                         if $width >= 0 {
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $precision, $arg), $width);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= centre(sprintf($fmt, $arg), $width);
                                             }
                                         } else { # $width < 0 #
                                             if $precision >= 0 {
                                                 $fmt ~= '.*';
                                                 $fmt ~= $spec-char;
                                                 $result ~= sprintf($fmt, $precision, $arg);
                                             } else {
                                                 $fmt ~= $spec-char;
                                                 $result ~= sprintf($fmt, $arg);
                                             }
                                         } # $width < 0 #
                                     } else { # justify is either '-' or '' i.e. left or right #
                                         if $precision >= 0 {
                                             $fmt ~= '.*';
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $precision, $arg), $width);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $precision, $arg), $width);
                                             }
                                         } else {
                                             $fmt ~= $spec-char;
                                             if $justify eq '-' {
                                                 $result ~= left(sprintf($fmt, $arg), $width);
                                             } else {
                                                 $result ~= right(sprintf($fmt, $arg), $width);
                                             }
                                         }
                                     } # justify is either '-' or '' i.e. left or right #
                                 } # $padding eq '' #
                             } # when 'b' #
            } # given $spec-char #
        } else {
            BadArg.new(:msg("Error: $?FILE line: $?LINE corrupted arg {@args[$cnt].WHAT.^name}")).throw;
        }
    } # for @format-str -> $arg #
    return $result;
} # sub Sprintf(Str:D $format-str, *@args --> Str) is export #
