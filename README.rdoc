# RubyFCA

Command line tool for Formal Concept Analysis (FCA) written in Ruby.

## Features

* Convert a [Conexp](https://github.com/fcatools/conexp-ng/wiki)'s CXT or CSV file and generate a Graphviz DOT file, or a PNG/JPG/EPS image file.
* Adopt the Ganter algorithm (through its Perl implementation of Fcastone by Uta Priss).

## Installation

Install the gem:

    $gem install rubyfca

## How to Use

    rubyfca [options] <source file> <output file>

    where:
    <source file>
           "foo.cxt", "foo.csv"
    <output file>
           "bar.dot", "bar.png", "bar.jpg", or "bar.eps"
    [options]:
           --box, -b:   Use box shaped concept nodes
          --full, -f:   Do not contract concept labels
        --legend, -l:   Print the legend of concept nodes (disabled when using circle node shape) (default: true)
      --coloring, -c:   Color concept nodes (default: true)
      --straight, -s:   Straighten edges (available when output format is either png, jpg, or eps)
          --help, -h:   Show this message


## Example

Sample CSV

            , Ostrich , Sparrow , Eagle , Lion , Bonobo , Human being
    bird    , X       , X       , X     , .    , .      , .
    mammal  , .       , .       , .     , X    , X      , X
    ape     , .       , .       , .     , .    , X      , X
    flying  , .       , X       , X     , .    , .      , .
    preying , .       , .       , X     , X    , .      , .
    talking , .       , .       , .     , .    , .      , X

Resulting FCA

![rubyfca.png](https://github.com/yohasebe/rubyfca/blob/master/rubyfca.png)

## Copyright

Copyright (c) 2009-2017 Yoichiro Hasebe and Kow Kuroda. See LICENSE for details.
