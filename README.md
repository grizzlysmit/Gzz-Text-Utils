Gzz::Text::Utils
================


**AUTHOR: Francis Grizzly Smit (grizzly@smit.id.au)**

**VERSION: 0.1.0**



## Introduction

A Raku module to provide text formating services to Raku progarms.

### Motivations

When you in-bed formatting information into your text such as **bold**, *italics*, etc ... and **colours** standard text formatting will not work e.g. printf, sprintf etc also those functions don't do centring.

Another important thing to note is that even these functions will fail if you include such formatting in the **text** field unless you supply a copy of the text with out the formatting characters in it in the **:ref** field i.e. **`left($formatted-text, $width, :ref($unformatted-text))`** or **`text($formatted-text, $width, :$ref)`** if the reference text is in a variable called **`$ref`** or you can write it as **`left($formatted-text, $width, ref => $unformatted-text)`**

