#!/usr/bin/env bash
# gotta apt-get some dictionary thing first bruh
# maybe apt-get install british-english-huge or smth idk

grep -P '^[a-z]{1,9}$' /usr/share/dict/british-english-huge > data/dictionary-en_GB.txt
grep -P '^.{9}$' data/dictionary-en_GB.txt > data/nineograms-en_GB.txt
