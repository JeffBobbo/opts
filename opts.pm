#!/usr/bin/perl

use warnings;
use strict;

package opts;

use Carp;

# constructor
# shouldn't really be directly used, instead using opts(), but can be
# when used directly, pass the string you want to pass as the only argument
sub new
{
  my $class = shift();

  my $source = shift();
  my $self = {
    source => $source,
    parser => {
      position => 0,
      length => length($source)
    },

    arguments => [],
    options => []
  };
  bless($self, $class);
  return $self;
}

# returns an array of arguments
sub arguments
{
  my $self = shift();
  return @{$self->{arguments}};
}

# returns an array of options
# each option is represented as a hash ref of name and value
# e.g., {name => 'f', value => 'x'}
# if an option has been specified with no value (e.g., `-a`) then value is undef
sub options
{
  my $self = shift();
  return @{$self->{options}};
}

# returns the number of times a specific option was received
# useful for testing things like if required options were given
sub option_count
{
  my $self = shift();
  my $f = shift();
  my $count = 0;
  foreach my $option (@{$self->{options}})
  {
    ++$count if ($option->{name} eq $f);
  }
  return $count;
}

=grammar
SETTING_SHORT = -[\w]
SETTING_LONG  = --[\w]{2,}
VALUE = (?:(['"]?).*\1?)|(?:[\w\\\\.\-]+)
OPTION = VALUE
FLAG = SETTING_SHORT(?: VALUE)?
     = SETTING_LONG(?: VALUE)?
MULTIFLAG = SETTING_SHORT[\w]+
ARGUMENTS = (?:OPTION )?[MULTIFLAG|FLAG]*
=cut

# returns the current character to parse, or undef if end of string
sub current
{
  my $self = shift();
  return $self->{parser}{position} < $self->{parser}{length} ?
    substr($self->{source}, $self->{parser}{position}, 1) :
    undef;
}

# peeks at the next character to parse, or undef if end of string
sub peek
{
  my $self = shift();
  return $self->{parser}{position}+1 < $self->{parser}{length} ?
    substr($self->{source}, $self->{parser}{position}+1, 1) :
    undef;
}

# advances to the next character to parse, returning the new character
sub advance
{
  my $self = shift();
  ++$self->{parser}{position};
  return $self->current();
}

# extracts a value, which can be a quoted string or a single block
sub value
{
  my $self = shift();

  my $value = '';
  my $c = $self->current();
  my $quote = ($c eq '"' || $c eq "'") ? $c : '';
  if ($quote)
  {
    $c = $self->advance();
    while (defined $c && $c ne $quote)
    {
      $value .= $c;
      $c = $self->advance();
    }
    croak "Unterminated string" if ($c ne $quote);
    $self->advance();
  }
  while (defined $c && $c =~ /[\w\\]/)
  {
    if ($c eq '\\')
    {
      $c = $self->advance();
      if ($c eq 'n')
      {
        $c = "\n";
      }
      elsif ($c eq 't')
      {
        $c = "\t";
      }
    }
    $value .= $c;
    $c = $self->advance();
  }
  return $value;
}

# parses a single argument, made up of a value.
# an argument is specified text without a flag
# e.g., in `bar -a`, foo is an argument
sub argument
{
  my $self = shift();
  push(@{$self->{arguments}}, $self->value());
}

# parses a short option, a single letter flag with an optional value
# e.g., `-a b`
# also flag grouping is supported, if grouped then the option sides with the
# last flag
# e.g., `-abc xyz` sets a and b, and sets c to 'xyz'
sub opt
{
  my $self = shift();

  my $f = $self->current();
  while (defined $self->peek() && $self->peek() =~ /\w/)
  {
    $f = $self->advance();
    push(@{$self->{options}}, {name => $f, value => undef});
  }

  my $c = $self->advance();
  if (!defined $c) # if there's nothing there
  {
    # then just return, we're done
    return;
  }
  # if there's something, then it should be a space to separate the value
  elsif ($c ne ' ')
  {
    croak "Invalid short opt value";
  }
  # consume the space
  $self->advance();

  # attempt to read a value out
  my $v = $self->value();
  $self->{options}->[-1]->{value} = $v if (defined $v && length($v))
}

# parses a long option, a multiletter flag
# must have two dashes, must have more than 1 letter
# a value is optional
# e.g., `--im-a-long-option "with a value"`
sub longopt
{
  my $self = shift();

  $self->advance(); # consume first -
  $self->advance(); # consume second -

  my $c = $self->current();
  croak "Invalid longopt name" if ($c !~ /\w/);
  my $name = $c;
  while (($c = $self->advance()) && $c =~ /[\w-]/)
  {
    $name .= $c;
  }
  croak "Short option name given for a long option" if (length($name) < 2);


  # if there's nothing left, we're done
  if (!defined $c)
  {
    push(@{$self->{options}}, {name => $name, value => undef});
    return;
  }
  croak "Invalid long opt value" if ($c ne ' ');

  # consume the space
  $self->advance();

  my $v = $self->value();
  push(@{$self->{options}}, {name => $name, value => (defined $v && length($v) ? $v : undef)});
}

sub parse
{
  my $self = shift();

  while ($self->{parser}{position} < $self->{parser}{length})
  {
    my $c = $self->current();
    if (!defined $c)
    {
      die "Unexpected end of input at char $self->{parser}{position} in `$self->{source}`";
    }

    # skip any unneeded whitespace
    elsif ($c =~ /\s/)
    {
      $self->advance();
      next;
    }

    elsif ($c =~ /[\w\\"']/)
    {
      $self->argument();
    }

    elsif ($c eq '-')
    {
      if ($self->peek() eq '-')
      {
        $self->longopt();
      }
      else
      {
        $self->opt();
      }
    }

    else
    {
      croak "Unexpected input: `$c`";
    }
  }
}

# static method
# this is the one to call to parse an argument string
# supports strings and arrays
# thus, program options can be passed as:
# my $opt = opts::opts(@ARGV);
# and options from a string can be passed as:
# my $opt = opts::opts("target --recursive");
sub opts
{
  my $src = join(' ', @_);

  my $o = opts->new($src);
  $o->parse();
  return $o;
}

1;
