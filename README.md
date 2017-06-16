# opts
Small perl library for reading command line options and arguments

## Documentation
Can be found in [opts.pm](../blob/master/opts.pm) as normal comments. A quick overview is provided here.

### Parsing
Options can be parsed from an array, or a string directly, returning an instance of an `opts` object.
```perl
my $opt = opts::opts(@ARGV); # parse the options we were given on the command line
```
```perl
my $opt = opts::opts($source); # parse from some other source
```

Alternatively, the stages can be done separately. The constructor only accepts a single string
```perl
my $opts = opts->new($source);
$opts->parse();
```

The string or array passed should not include anything that's not part of the argument string. For example, it'd be incorrect to do:
```perl
my $command = "./someScript.sh --option 1 -x";
my $opts = opts::opts($command);
```
`./someScript.sh` would be treated as an argument and would come out as such.

### Arguments
A list of arguments received, that is, values without a flag can be obtained using the `arguments` function.
Arguments are stored in the order they're received.
```
my $opts = opts::opts("foo.txt bar.txt -v");
my @a = $opts->arguments();
print "@a\n"; # prints "foo.txt bar.txt"
```
### Options (flags)
A list of options, that is, a flag followed by an optional value can be obtained using the `options` function.
Options are stored in the order they're received, making multiple entries for entries received multiple times.
Each flag is stored as a hashref of it's name and value, if no value was specified then the value shall be `undef`.
```perl
my $opts = opts::opts("-ab -c 55");
print Dumper(\@{$opts->options()});
# prints
# VAR1 = [
#  {
#    'name' => 'a',
#    'value' => undef
#  },
#  {
#    'name' => 'b',
#    'value' => undef
#  },
#  {
#    'name' => 'c',
#    'value' => 55
#  }
#]
```
Flag grouping is allowed, when grouped with a value, only the last flag in the group gets the value specified.
e.g., `-ab 22` would give
```perl
(
  {
    'name' => 'a',
    'value' => undef
  },
  {
    'name' => 'b',
    'value' => 22
  }
)
```
Receiving values for options is greedy, if you want to specify a flag without a value, the value needs to come before the flag.

#### Long options
Long options are also supported. Long options must begin with two dashes, otherwise it'll be treated as a series of grouped short options. Long options must also be at least 2 characters long.
```perl
... = opts::opts("--long-opt -s"); # valid
... = opts::opts("-long"); # parses to 4 short flags, `l`, `o`, `n`, `g`
... = opts::opts("--a"); # croaks
```
