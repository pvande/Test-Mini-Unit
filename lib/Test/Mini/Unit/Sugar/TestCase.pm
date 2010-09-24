# Defines the behavior of the +case+ keyword.
# @api private
package Test::Mini::Unit::Sugar::TestCase;
use base 'Devel::Declare::Context::Simple';
use strict;
use warnings;

use Devel::Declare ();

sub import {
    my ($class, %args) = @_;
    my $caller = $args{into} || caller;

    {
        no strict 'refs';
        *{"$caller\::case"} = sub (&) {};
    }

    Devel::Declare->setup_for(
        $caller => { case => { const => sub {
            $class->new(%args)->parser(@_);
        } } }
    );
}

sub parser {
    my $self = shift;
    $self->init(@_);

    $self->skip_declarator;

    my $name = $self->strip_name;
    die unless $name;

    my $pkg  = $self->get_curstash_name;
    my $base = $pkg;

    # If our current scope isn't a Test::Mini::TestCase, we inherit from that;
    # otherwise, we inherit from our current scope.
    $base = 'Test::Mini::TestCase' unless $base->isa('Test::Mini::TestCase');

    # Nested packages should be namespaced under their parent, unless the
    # package name is qualified or they're in the top level.
    $name = join('::', $pkg, $name) unless $name =~ /::/ || $pkg eq 'main';

    my $Sugar = 'Test::Mini::Unit::Sugar';
    my @with = ref $self->{with} ? @{$self->{with}} : $self->{with} || ();

    $self->inject_if_block($_) for reverse (
        $self->scope_injector_call(),

        "package $name;",
        "use base '$base';",
        "use Test::Mini::Assertions;",

        # Provide explicit default advice to avoid some order-specific issues.
        'sub setup    { shift->SUPER::setup(@_)    }',
        'sub teardown { shift->SUPER::teardown(@_) }',

        "use ${Sugar}::TestCase;",
        "use ${Sugar}::Test;",
        "use ${Sugar}::Advice (name => 'setup',    order => 'pre');",
        "use ${Sugar}::Advice (name => 'teardown', order => 'post');",
        (map { "use $_;" } reverse @with),
    );

    $self->shadow(sub (&) { shift->(); 1; });
}

1;
