Table of Contents
-----------------

  * [NAME](#name)

  * [AUTHOR](#author)

  * [VERSION](#version)

  * [TITLE](#title)

  * [SUBTITLE](#subtitle)

  * [COPYRIGHT](#copyright)

  * [Introduction](#introduction)

    * [Motivations](#motivations)

      * [Update](#update)

  * [Exceptions](#exceptions)

    * [BadArg](#badarg)

    * [ArgParityMissMatch](#argparitymissmatch)

    * [FormatSpecError](#formatspecerror)

    * [`UnhighlightBase` & `UnhighlightBaseActions` and `Unhighlight` & `UnhighlightActions`](#unhighlightbase--unhighlightbaseactions-and-unhighlight--unhighlightactions)

    * [The Functions Provided](#the-functions-provided)

    * [Here are 4 functions provided to **`centre`**, **`left`** and **`right`** justify text even when it is ANSI formatted](#here-are-4-functions-provided-to-centre-left-and-right-justify-text-even-when-it-is-ansi-formatted)

    * [Sprintf](#sprintf)

    * [Printf](#printf)

NAME
====

Gzz::Text::Utils 

AUTHOR
======

Francis Grizzly Smit (grizzly@smit.id.au)

VERSION
=======

0.1.4

TITLE
=====

Gzz::Text::Utils

SUBTITLE
========

A Raku module to provide text formatting services to Raku programs.

COPYRIGHT
=========

GPL V3.0+ [LICENSE](https://github.com/grizzlysmit/Gzz-Text-Utils/blob/main/LICENSE)

Introduction
============

A Raku module to provide text formatting services to Raku programs.

Including a sprintf front-end Sprintf that copes better with Ansi highlighted text and implements **`%U`** and does octal as **`0o123`** or **`0O123`** if you choose **`%O`** as I hate ambiguity like **`0123`** is it an int with leading zeros or an octal number. Also there is **`%N`** for a new line and **`%T`** for a tab helpful when you want to use single quotes to stop the **num`$`** specs needing back slashes.

[Top of Document](#)

Motivations
-----------

When you embed formatting information into your text such as **bold**, *italics*, etc ... and **colours** standard text formatting will not work e.g. printf, sprintf etc also those functions don't do centring.

Another important thing to note is that even these functions will fail if you include such formatting in the **text** field unless you supply a copy of the text with out the formatting characters in it in the **:ref** field i.e. **`left($formatted-text, $width, :ref($unformatted-text))`** or **`text($formatted-text, $width, :$ref)`** if the reference text is in a variable called **`$ref`** or you can write it as **`left($formatted-text, $width, ref => $unformatted-text)`**

[Top of Document](#)

### Update

Fixed the proto type of **`left`** etc is now 

```raku
sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &left-global-number-of-chars,
                    Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export
```

Where **`sub strip-ansi(Str:D $text --> Str:D) is export`** is my new function for striping out ANSI escape sequences so we don't need to supply **`:$ref`** unless it contains codes that **`sub strip-ansi(Str:D $text --> Str:D) is export`** cannot strip out, if so I would like to know so I can update it to cope with these new codes.

[Top of Document](#)

Exceptions
==========

BadArg
------

```raku
class BadArg is Exception is export
```

BadArg is a exception type that Sprintf will throw in case of badly specified arguments.

[Top of Document](#)

ArgParityMissMatch
------------------

```raku
class ArgParityMissMatch is Exception is export
```

ArgParityMissMatch is an exception class that Sprintf throws if the number of arguments does not match what the number the format string says there should be.

**NB: if you use *`num$`* argument specs these will not count as they grab from the args add hoc, *`*`* width and precision spec however do count as they consume argument.**

[Top of Document](#)

FormatSpecError
---------------

```raku
class FormatSpecError is Exception is export
```

FormatSpecError is an exception class that Format (used by Sprintf) throws if there is an error in the Format specification (i.e. **`%n`** instead of **`%N`** as **`%n`** is already taken, the same with using **`%t`** instead of **`%T`**).

Or anything else wrong with the Format specifier.

**NB: *`%N`* introduces a *`\n`* character and *`%T`* a tab (i.e. *`\t`*).**

[Top of Document](#)

Format and FormatActions
========================

Format & FormatActions are a grammar and Actions pair that parse out the **%** spec and normal text chunks of a format string.

For use by Sprintf a sprintf alternative that copes with ANSI highlighted text.

[Top of Document](#)

`UnhighlightBase` & `UnhighlightBaseActions` and `Unhighlight` & `UnhighlightActions`
-------------------------------------------------------------------------------------

**`UnhighlightBase`** & **`UnhighlightBaseActions`** are a grammar & role pair that does the work required to to parse apart ansi highlighted text into ANSI highlighted and plain text. 

**`Unhighlight`** & **`UnhighlightActions`** are a grammar & class pair which provide a simple TOP for applying an application of **`UnhighlightBase`** & **`UnhighlightBaseActions`** for use by **`sub strip-ansi(Str:D $text --` Str:D) is export**> to strip out the plain text from a ANSI formatted string

[Top of Document](#)

The Functions Provided
----------------------

  * strip-ansi

    ```raku
    sub strip-ansi(Str:D $text --> Str:D) is export
    ```

    Strips out all the ANSI escapes, at the moment just those provided by the **`Terminal::ANSI`** or **`Terminal::ANSI::OO`** modules both available as **`Terminal::ANSI`** from zef etc I am not sure how exhaustive that is, but I will implement any more escapes as I become aware of them.

  * hwcswidth

    ```raku
    sub hwcswidth(Str:D $text --> Int:D) is export
    ```

    Same as **`wcswidth`** but it copes with ANSI escape sequences unlike **`wcswidth`**.

    * The secret sauce is that it is defined as:

      ```raku
      sub hwcswidth(Str:D $text --> Int:D) is export {
          return wcswidth(strip-ansi($text));
      } #  sub hwcswidth(Str:D $text --> Int:D) is export #
      ```

[Top of Document](#)

### Here are 4 functions provided to **`centre`**, **`left`** and **`right`** justify text even when it is ANSI formatted.

  * **centre**

    ```raku
    sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                :&number-of-chars:(Int:D, Int:D --> Bool:D) = &centre-global-number-of-chars,
                    Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export {
    ```

    * **`centre`** centres the text **`$text`** in a field of width **`$width`** padding either side with **`$fill`**

    * **Where:**

      * **`$fill`** is the fill char by default **`$fill`** is set to a single white space.

        * If it requires an odd number of padding then the right hand side will get one more char/codepoint.

      * **`&number-of-chars`** takes a function which takes 2 **`Int:D`**'s and returns a **`Bool:D`**.

        * By default this is equal to the closure **`centre-global-number-of-chars`** which looks like:

          ```raku
          our $centre-total-number-of-chars is export = 0;
          our $centre-total-number-of-visible-chars is export = 0;

          sub centre-global-number-of-chars(Int:D $number-of-chars,
                                          Int:D $number-of-visible-chars --> Bool:D) {
              $centre-total-number-of-chars         = $number-of-chars;
              $centre-total-number-of-visible-chars = $number-of-visible-chars;
              return True
          }
          ```

          * Which is a closure around the variables: **`$centre-total-number-of-chars`** and **`$centre-total-number-of-visible-chars`**, these are global **`our`** variables that **`Gzz::Text::Utils`** exports. But you can just use **`my`** variables from with a scope, just as well. And make the **`sub`** local to the same scope.

            i.e.

            ```raku
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
            ```

      * The parameter **`:$ref`** is by default set to the value of **`strip-ansi($text)`**

        * This is used to obtain the length of the of the text using ***`wcswidth(Str)`*** from module **"`Terminal::WCWidth`"** which is used to obtain the width the text if printed on the current terminal:

          * **NB: `wcswidth` will return -1 if you pass it text with colours etc embedded in them**.

          * **"`Terminal::WCWidth`"** is witten by **bluebear94** [github:bluebear94](https://raku.land/github:bluebear94) get it with **zef** or whatever

      * **`:$max-width`** sets the maximum width of the field but if set to **`0`** (The default), will effectively be infinite (∞).

      * **`:$ellipsis`** is used to elide the text if it's too big I recommend either **`''`** the default or **`'…'`**.

  * **left**

    ```raku
    sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                    :&number-of-chars:(Int:D, Int:D --> Bool:D) = &left-global-number-of-chars,
                        Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export {
    ```

    * **`left`** is the same except that except that it puts all the padding on the right of the field.

  * **right**

    ```raku
    sub right(Str:D $text, Int:D $width is copy, Str:D $fill = ' ',
                        :&number-of-chars:(Int:D, Int:D --> Bool:D) = &right-global-number-of-chars,
                            Str:D :$ref = strip-ansi($text), Int:D :$max-width = 0, Str:D :$ellipsis = '' --> Str) is export {
    ```

    * **`right`** is again the same except it puts all the padding on the left and the text to the right.

  * **crop-field**

    ```raku
    sub crop-field(Str:D $text, Int:D $w is rw, Int:D $width is rw, Bool:D $cropped is rw,
                                                    Int:D $max-width, Str:D :$ellipsis = '' --> Str:D) is export {
    ```

    * **`crop-field`** used by **`centre`**, **`left`** and **`right`** to crop their input if necessary. Copes with ANSI escape codes.

      * **Where**

        * **`$text`** is the text to be cropped possibly, wit ANSI escapes embedded. 

        * **`$w`** is used to hold the width of **`$text`** is read-write so will return that value.

        * **`$width`** is the desired width. Will be used to return the updated width.

        * **`$cropped`** is used to return the status of whether or not **`$text`** was truncated.

        * **`$max-width`** is the maximum width we are allowing.

        * **`$ellipsis`** is used to supply a eliding . Empty string by default.

[Top of Document](#)

### Sprintf

  * Sprintf like sprintf only it can deal with ANSI highlighted text. And has lots of other options, including the ability to specify a **`$max-width`** using **`width.precision.max-width`**, which can be **`.*`**, **C*<<num>$**>, **`.*`**, or **C<<num>**>

    ```raku
    sub Sprintf(Str:D $format-str,
                    :&number-of-chars:(Int:D, Int:D --> Bool:D) = &Sprintf-global-number-of-chars,
                                                            Str:D :$ellipsis = '', *@args --> Str) is export
    ```

    * Where:

      * **`format-str`** is is a superset of the **`sprintf`** format string, but it has extra features: like the flag **`[ <char> ]`** where <char> can be almost anything except **`[`**, **`]`** **control characters**, **white space other than the normal space**, and **`max-width`** after the precision.

        * The format string looks like this: 

          ```raku
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
          ```

          * Where

          * **`dollar-directive`** is a integer >= 1

          * **`flags`** is any zero or more of:

            * **`+`** put a plus in front of positive values.

            * **`-`** left justify, right is the default

            * **`^`** centre justify.

            * **`#`** ensure the leading **`0`** for any octal, prefix non-zero hexadecimal with **`0x`** or **`0X`**, prefix non-zero binary with **`0b`** or **`0B`**

            * **`v`** vector flag (used only with d directive)

            * **`' '`** pad with spaces.

            * **`0`** pad with zeros.

            * **`[ <char> ]`** pad with character char where char matches:

              * **`<-[ <cntrl> \s \[ \] ]> || ' '`** i.e. anything except control characters, white space (apart from the basic white space (i.e. \x20 or the one with ord 32)), and **`[`** and finally **`]`**.

          * **`width`** is either an integer or a **`*`** or a **`*`** followed by an integer >= 1 and a '$'.

          * **`precision`** is a **`.`** followed by either an positive integer or a **`*`** or a **`*`** followed by an integer >= 1 and a '$'.

          * **`max-width`** is a **`.`** followed by either an positive integer or a **`*`** or a **`*`** followed by an integer >= 1 and a '$'.

          * **`modifier`** These are not implemented but is one of:

            * **`hh`** interpret integer as a type **`char`** or **`unsigned char`**.

            * **`h`** interpret integer as a type **`short`** or **`unsigned short`**.

            * **`j`** interpret integer as a type **`intmax_t`**, only with a C99 compiler (unportable).

            * **`l`** interpret integer as a type **`long`** or **`unsigned long`**.

            * **`ll`** interpret integer as a type **`long long`**, **`unsigned long long`**, or **`quad`** (typically 64-bit integers).

            * **`q`** interpret integer as a type **`long long`**, **`unsigned long long`**, or **`quad`** (typically 64-bit integers).

            * **`L`** interpret integer as a type **`long long`**, **`unsigned long long`**, or **`quad`** (typically 64-bit integers).

            * **`t`** interpret integer as a type **`ptrdiff_t`**.

            * **`z`** interpret integer as a type **`size_t`**.

          * **`spec-char`** or the conversion character is one of:

            * **`c`** a character with the given codepoint.

            * **`s`** a string.

            * **`d`** a signed integer, in decimal.

            * **`u`** an unsigned integer, in decimal.

            * **`o`** an unsigned integer, in octal, with a **`0o`** prepended if the **`#`** flag is present.

            * **`x`** an unsigned integer, in hexadecimal, with a **`0x`** prepended if the **`#`** flag is present.

            * **`e`** a floating-point number, in scientific notation.

            * **`f`** a floating-point number, in fixed decimal notation.

            * **`g`** a floating-point number, in %e or %f notation.

            * **`X`** like **`x`**, but using uppercase letters, with a **`0X`** prepended if the **`#`** flag is present.

            * **`E`** like **`e`**, but using an uppercase **`E`**.

            * **`G`** like **`g`**, but with an uppercase **`E`** (if applicable).

            * **`b`** an unsigned integer, in binary, with a **`0b`** prepended if the **`#`** flag is present.

            * **`B`** an unsigned integer, in binary, with a **`0B`** prepended if the **`#`** flag is present.

            * **`i`** a synonym for **`%d`**.

            * **`D`** a synonym for **`%ld`**.

            * **`U`** a synonym for **`%lu`**.

            * **`O`** a synonym for **`%lo`**.

            * **`F`** a synonym for **`%f`**.

      * **`:&number-of-chars`** is an optional named argument which takes a function with a signature **`:(Int:D, Int:D --` Bool:D)**> if not specified it will have the value of **`&Sprintf-global-number-of-chars`** which is defined as:

        ```raku
        our $Sprintf-total-number-of-chars is export = 0;
        our $Sprintf-total-number-of-visible-chars is export = 0;

        sub Sprintf-global-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) {
            $Sprintf-total-number-of-chars         = $number-of-chars;
            $Sprintf-total-number-of-visible-chars = $number-of-visible-chars;
            return True
        }
        ```

        * This is exactly the same as the argument by the same name in **`centre`**, **`left`** and **`right`** above.

          i.e. 

          ```raku
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
          ```

          * **Note: This is a closure we should always use a closure if we want to get the number of characters printed.** 

      * **`:$ellipsis`** this is an optional argument of type **`Str:D`** which defaults to **`''`**, if set will be used to mark elided text, if the argument is truncated due to exceeding the value of **`max-width`** (note **`max-width`** defaults to **`0`** which means infinity). The recommended value would be something like **`…`**.

      * **`*@args`** is an arbitrary long list of values each argument can be either a scalar value to be printed or a Hash or an Array

        * If a Hash then it should contain two pairs with keys: **`arg`** and **`ref`**; denoting the actual argument and a reference argument respectively, the ref argument should be the same as **`arg`** but with no ANSI formatting etc to mess up the counting. As this ruins formatting spacing. If not present will be set to **`strip-ansi($arg)`**, only bother with all this if **`strip-ansi($arg)`** isn't good enough.

        * If a Array then it should contain two values. The first being **`arg`** and the other being **`ref`**; everything else is the same as above.

        * **`arg`** the actual argument.

        * **`@args[$i][]`** the actual argument. Where **`$i`** is the current index into the array of args.

        * **`@args[$i][1]`** the reference argument, as in the **`:$ref`** arg of the **left**, **right** and **centre** functions which it uses. It only makes sense if your talking strings possibly formatted if not present will be set to **`strip-ansi($arg)`** if $arg is a Str or just $arg otherwise.

        * If it's a scalar then it's the argument itself. And **`$ref`** is **`strip-ansi($arg)`** if $arg is a string type i.e. Str or just **C**$arg>> otherwise.

          * **`ref`** the reference argument, as in the **`:$ref`** arg of the **left**, **right** and **centre** functions which it uses. It only makes sense if your talking strings possibly formatted if not present will be set to **`strip-ansi($arg)`** if $arg is a Str or just $arg otherwise.

            i.e.

            ```raku
            put Sprintf('%30.14.14s, %30.14.13s%N%%%N%^*.*s%3$*4$.*3$.*6$d%N%2$^[&]*3$.*4$.*6$s%T%1$[*]^100.*4$.99s',
                                        ${ arg => $highlighted, ref => $text }, $text, 30, 14, $highlighted, 13,
                                                                                    :number-of-chars(&test-number-of-chars), :ellipsis('…'));
            dd $test-number-of-chars,  $test-number-of-visible-chars;
            put Sprintf('%30.14.14s,  testing %30.14.13s%N%%%N%^*.*s%3$*4$.*3$.*6$d%N%2$^[&]*3$.*4$.*6$s%T%1$[*]^100.*4$.99s',
                                        $[ $highlighted, $text ], $text, 30, 14, $highlighted, 13, 13,
                                                                                    :number-of-chars(&test-number-of-chars), :ellipsis('…'));
            dd $test-number-of-chars,  $test-number-of-visible-chars;
            ```

[Top of Document](#)

### Printf

  * Same as **`Sprintf`** but writes it's output to **`$*OUT`** or an arbitary filehandle if you choose.

    * defined as

      ```raku
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
      ```

[Top of Document](#)

