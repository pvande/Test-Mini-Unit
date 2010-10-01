# Defines the behavior of the +reuse+ keyword.
# @api private
package Test::Mini::Unit::Sugar::Reuse;
use base 'Devel::Declare::Context::Simple';
use strict;
use warnings;

use Devel::Declare ();
use Carp qw/confess/;

sub import {
    my ($class, %args) = @_;
    my $caller = $args{into} || caller;

    {
        no strict 'refs';
        *{"$caller\::reuse"} = sub ($) {};
    }

    Devel::Declare->setup_for(
        $caller => { reuse => { const => sub { $class->new()->parser(@_) } } }
    );
}

sub parser {
    my $self = shift;
    $self->init(@_);

    $self->skip_declarator();

    my $name = $self->strip_name();
    $self->inject(qq'"$name"; ');
    my $fullname = $self->qualify_name($name);
    $self->inject("$fullname->import();");
}

sub qualify_name {
    my ($self, $name) = @_;
    my $file;
    my $mod = $self->get_curstash_name();

    if ($name =~ s/^::// || $self->get_curstash_name() eq 'main') {
        ($file = $name) =~ s/::/\//g;
        die "Cannot find module '$name' to reuse..."
            unless exists $INC{"$file.pm"};
    } else {
        my $pkg = $self->get_curstash_name();
        my @pkg_parts  = split('::', $pkg);
        my @name_parts = split('::', $name);

        unshift @pkg_parts, '';

        while (@pkg_parts) {
            $file = join('/', @pkg_parts[1..@pkg_parts-1], @name_parts);
            last if exists $INC{"$file.pm"};
            pop(@pkg_parts);
            $file = undef;
        }

        die "Cannot resolve module '$name' relative to '$pkg'..." unless $file;

        ($name = $file) =~ s/\//::/g;
    }

    return $name;
}

sub rewrite_declarator {
    my ($self, $name) = @_;

    # Parse the length of the next word.
    my $declarator = $self->declarator;
    my $length = Devel::Declare::toke_scan_word($self->offset, 0);
    confess "Couldn't find declarator '$declarator'" unless $length;

    # Verify that the next word is what we expect it to be.
    my $linestr = $self->get_linestr();
    my $found = substr($linestr, $self->offset, $length);
    confess "Expected declarator '${declarator}', got '${found}'"
        unless $found eq $declarator;

    # Replace the declarator with the given name.
    substr($linestr, $self->offset, $length) = $name;
    $self->set_linestr($linestr);
    $self->inc_offset(length($name));
}

sub inject {
  my ($self, $inject) = @_;

  my $linestr = $self->get_linestr();
  substr($linestr, $self->offset, 0) = $inject;
  $self->set_linestr($linestr);
  $self->inc_offset(length($inject));
}

1;
