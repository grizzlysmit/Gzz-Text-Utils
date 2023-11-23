NAME
====

Gzz::Text::Utils 

AUTHOR
======

Francis Grizzly Smit (grizzly@smit.id.au)

VERSION
=======

0.1.0

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

A Raku module to provide text formatting services to Raku programs.

### Motivations

When you in-bed formatting information into your text such as **bold**, *italics*, etc ... and **colours** standard text formatting will not work e.g. printf, sprintf etc also those functions don't do centring.

Another important thing to note is that even these functions will fail if you include such formatting in the **text** field unless you supply a copy of the text with out the formatting characters in it in the **:ref** field i.e. **`left($formatted-text, $width, :ref($unformatted-text))`** or **`text($formatted-text, $width, :$ref)`** if the reference text is in a variable called **`$ref`** or you can write it as **`left($formatted-text, $width, ref => $unformatted-text)`**

The functions Provided.
-----------------------

Currently there are 3 functions provided 

  * **`sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = $text --> Str)`**

  * **`sub left(Str:D $text, Int:D $width, Str:D $fill = ' ', Str:D :$ref = $text --> Str)`**

  * **`sub right(Str:D $text, Int:D $width, Str:D $fill = ' ', Str:D :$ref = $text --> Str)`**

  * **`centre`** centres the text **`$text`** in a field of width **`$width`** padding either side with **`$fill`** by default **`$fill`** is set to a single white space; do not set it to any string that is longer than 1 code point, or it will fail to behave correctly. If it requires an on number padding then the right hand side will get one more char/codepoint. The parameter **`:$ref`** is by default set to the value of **`$text`** this is used to obtain the length of the of the text using ***`wcswidth(Str)`*** which is used to obtain the width the text if printed on the current terminal: **NB: `wcswidth` will return -1 if you pass it text with colours etc in-bedded in them**.

  * **`left`** is the same except that except that it puts all the padding on the right of the field.

  * **`right`** is again the same except it puts all the padding on the left and the text to the right.

