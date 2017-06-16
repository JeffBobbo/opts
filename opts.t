#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;
use Test::More 'no_plan';

use opts;

{
  my $opt = opts::opts("foo");
  my @a = $opt->arguments();
  is(scalar(@a), 1, "argsimple: quant");
  is($a[0], "foo", "argsimple: value");
}

{
  my $opt = opts::opts("foo bar");
  my @a = $opt->arguments();
  is(scalar(@a), 2, "argmulti: quant");
  is($a[0], "foo", "argmulti: value 1");
  is($a[1], "bar", "argmulti: value 2");
}

{
  my $opt = opts::opts("foo\\ bar");
  my @a = $opt->arguments();
  is(scalar(@a), 1, "argescape: quant");
  is($a[0], "foo bar", "argescape: values");
}

{
  my $opt = opts::opts("-a -b -a");
  my @o = $opt->options();
  is(scalar(@o), 3, "optsimple: quant");
  is($o[0]->{name}, "a", "optsimple: name");
  is($opt->option_count($o[0]->{name}), 2, "optsimple: count");
  is($o[0]->{value}, undef, "optsimple: value");
}

{
  my $opt = opts::opts("-a foo -b");
  my @o = $opt->options();
  is(scalar(@o), 2, "optvalue: quant");
  is($o[0]->{name}, "a", "optvalue: name");
  is($o[0]->{value}, "foo", "optvalue: value");
}

{
  my $opt = opts::opts("--long --with-value boop");
  my @o = $opt->options();
  is(scalar(@o), 2, "longopt: quant");
  is($o[0]->{name}, "long", "longopt: name");
  is($o[1]->{name}, "with-value", "longopt: name");
  is($o[0]->{value}, undef, "longopt: value");
  is($o[1]->{value}, "boop", "longopt: value");
}

{
  my $opt = opts::opts("\"can't touch this\" or\\ that --abc foo");
  my @a = $opt->arguments();
  is(scalar(@a), 2, "fulltest: argument quant");
  is($a[0], "can't touch this", "fulltest: argument value");
  is($a[1], "or that", "fulltest: argument value");
  my @o = $opt->options();
  is(scalar(@o), 1, "fulltest: option quant");
  is($o[0]->{name}, "abc", "fulltest: option name");
  is($o[0]->{value}, "foo", "fulltest: option value");
}
