# PN Sequence Generator

The PN sequence generator module built using this project is used in both noc_block_spec_spreader and noc_block_correlator. The c++ code here builds an LFSR based programmable PN sequence generator as shown below. It can take a generator polynomial up to an order of 10, i.e., the longest sequence that it can generate is of length 1023. For a polynomial of order N, output is taken from the Nth bit.

![pnseqgen](https://user-images.githubusercontent.com/9439021/27982375-251f4e6c-636e-11e7-9cb2-7e1f0d9df33a.jpg)

