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

A Raku module to provide text formating services to Raku progarms.

COPYRIGHT
=========

GPL V3.0+ [LICENSE](https://github.com/grizzlysmit/Gzz-Text-Utils/blob/main/LICENSE)

Introduction
------------

A Raku module to provide text formating services to Raku progarms.

Including a sprintf frontend Sprintf that copes better with Ansi highlighted text and implements **`%U`** and does octal as **`0o123`** or **`0O123`** if you choose **`%O`** as I hate ambiguity like **`0123`** is it an int with leading zeros or an octal number. Also there is **`%n`** for a new line and **`%t`** for a tab helpful when you want to use single quotes to stop the **num`$`** specs needing back slashes.

### Motivations

When you embed formatting information into your text such as **bold**, *italics*, etc ... and **colours** standard text formatting will not work e.g. printf, sprintf etc also those functions don't do centring.

Another important thing to note is that even these functions will fail if you include such formatting in the **text** field unless you supply a copy of the text with out the formatting characters in it in the **:ref** field i.e. **`left($formatted-text, $width, :ref($unformatted-text))`** or **`text($formatted-text, $width, :$ref)`** if the reference text is in a variable called **`$ref`** or you can write it as **`left($formatted-text, $width, ref => $unformatted-text)`**

#### Update

Fixed the proto type of **`left`** etc is now 

    B«C«sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = strip-ansi($text), Int:D :$precision = 0, Str:D :$ellipsis = '' --> Str) is export» »

Where **`sub strip-ansi(Str:D $text --> Str:D) is export` ** is my new function for striping out ANSI escape sequences so we don't need to supply **`:$ref`** unless it contains codes that **`sub strip-ansi(Str:D $text --> Str:D) is export` ** cannot strip out, if so I would like to know so I can update it to cope with these new codes.

BadArg
======

  * **`class BadArg is Exception is export`**

BadArg is a exception type that Sprintf will throw in case of badly specified arguments.

Format and FormatActions
========================

Format & FormatActions are a grammar and Actions pair that parse out the **%** spec and normal text chunks of a format string.

For use by Sprintf a sprintf alternative that copes with ANSI highlighted text.

`UnhighlightBase` & `UnhighlightBaseActions` and `Unhighlight` & `UnhighlightActions`
-------------------------------------------------------------------------------------

**`UnhighlightBase`** & **`UnhighlightBaseActions`** are a grammar & role pair that does the work required to to parse apart ansi highlighted text into ANSI highlighted and plain text. 

**`Unhighlight`** & **`UnhighlightActions`** are a grammar & class pair which provide a simple TOP for applying an application of **`UnhighlightBase`** & **`UnhighlightBaseActions`** for use by **`sub strip-ansi(Str:D $text --` Str:D) is export**> to strip out the plain text from a ANSI formatted string

The functions Provided.
-----------------------

  * **`sub strip-ansi(Str:D $text --` Str:D) is export**>

  * Strips out all the ANSI escapes, at the moment just those provided by the **`Terminal::ANSI`** or **`Terminal::ANSI::OO`** modules both available as **`Terminal::ANSI`** from zef etc I am not sure how exhastive that is, but I will implement any more escapes as I become aware of them. 

here are 3 functions provided to **`centre`**, **`left`** and **`right`** justify text even when it is ANSI formatted.

  * **`sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = $text --> Str)`**

  * **`sub left(Str:D $text, Int:D $width, Str:D $fill = ' ', Str:D :$ref = $text --> Str)`**

  * **`sub right(Str:D $text, Int:D $width, Str:D $fill = ' ', Str:D :$ref = $text --> Str)`**

  * **`centre`** centres the text **`$text`** in a field of width **`$width`** padding either side with **`$fill`** by default **`$fill`** is set to a single white space; do not set it to any string that is longer than 1 code point, or it will fail to behave correctly. If it requires an on number padding then the right hand side will get one more char/codepoint. The parameter **`:$ref`** is by default set to the value of **`strip-ansi($text)`** this is used to obtain the length of the of the text using ***`wcswidth(Str)`*** which is used to obtain the width the text if printed on the current terminal: **NB: `wcswidth` will return -1 if you pass it text with colours etc in-bedded in them**.

  * **`left`** is the same except that except that it puts all the padding on the right of the field.

  * **`right`** is again the same except it puts all the padding on the left and the text to the right.

sub Sprintf(Str:D $format-str, *@args --> Str) is export 
---------------------------------------------------------

