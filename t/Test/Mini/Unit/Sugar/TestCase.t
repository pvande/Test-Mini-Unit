use Test::More tests => 70;
use strict;
use warnings;

BEGIN {
    require_ok 'Test::Mini::Unit::Sugar::TestCase';
    Test::Mini::Unit::Sugar::TestCase->import();
}

can_ok __PACKAGE__, 'case';
ok !__PACKAGE__->can('test');
ok !__PACKAGE__->can('setup');
ok !__PACKAGE__->can('teardown');

is(__PACKAGE__, 'main');

case TestCase {
    main::is(__PACKAGE__, 'TestCase');
    main::isa_ok(__PACKAGE__, 'Test::Mini::TestCase');
    main::can_ok(__PACKAGE__, qw/ case test setup teardown assert /);

    our $setup_calls = 0;
    our $test_calls  = 0;

    setup {
        main::isa_ok $self, __PACKAGE__;
        main::note 'first #setup called for ' . $self->{name};
        main::is $setup_calls, 0, 'first #setup called first';
        $setup_calls++;
    }

    setup {
        main::isa_ok $self, __PACKAGE__;
        main::note 'second #setup called for ' . $self->{name};
        main::is $setup_calls, 1, 'second #setup called second';
        $setup_calls++;
    }

    test something {
        main::note 'test_something called';
        main::isa_ok $self, __PACKAGE__;
        main::is $setup_calls, 2;
        main::is $test_calls, 0;

        $setup_calls -= 2;
        $test_calls +=2;
    }

    test something_else {
        main::note 'test_something_else called';
        main::isa_ok $self, __PACKAGE__;
        main::is $setup_calls, 2;
        main::is $test_calls, 0;

        $setup_calls -= 2;
        $test_calls += 2;
    }

    teardown {
        main::isa_ok $self, __PACKAGE__;
        main::note 'first #teardown called for ' . $self->{name};
        main::is $test_calls, 1, 'first #teardown called last';
        $test_calls--;
    }

    teardown {
        main::isa_ok $self, __PACKAGE__;
        main::note 'second #teardown called for ' . $self->{name};
        main::is $test_calls, 2, 'second #teardown called before first';
        $test_calls--;
    }

    case Inner {
        main::is(__PACKAGE__, 'TestCase::Inner');
        main::isa_ok(__PACKAGE__, 'TestCase');
        main::can_ok(__PACKAGE__, qw/ case test setup teardown assert /);

        setup {
            main::isa_ok $self, __PACKAGE__;
            main::note 'inner #setup called for ' . $self->{name};
            main::is $TestCase::setup_calls, 2, 'inner #setup called third';
            $TestCase::setup_calls++;
        }

        test in_nested_scope {
            main::note 'test_in_nested_scope called';
            main::isa_ok $self, __PACKAGE__;
            main::is $TestCase::setup_calls, 3;
            main::is $TestCase::test_calls, 0;

            $TestCase::setup_calls -= 3;
            $TestCase::test_calls += 3;
        }

        teardown {
            main::isa_ok $self, __PACKAGE__;
            main::note 'inner #teardown called for ' . $self->{name};
            main::is $TestCase::test_calls, 3, 'inner #teardown called before others';
            $TestCase::test_calls--;
        }
    }

    case Qualified::Inner {
        main::is(__PACKAGE__, 'Qualified::Inner');
        main::isa_ok(__PACKAGE__, 'TestCase');
        main::can_ok(__PACKAGE__, qw/ case test setup teardown assert /);

        setup {
            main::isa_ok $self, __PACKAGE__;
            main::note 'inner #setup called for ' . $self->{name};
            main::is $TestCase::setup_calls, 2, 'inner #setup called third';
            $TestCase::setup_calls++;
        }

        test in_nested_scope {
            main::note 'test_in_nested_scope called';
            main::isa_ok $self, __PACKAGE__;
            main::is $TestCase::setup_calls, 3;
            main::is $TestCase::test_calls, 0;

            $TestCase::setup_calls -= 3;
            $TestCase::test_calls += 3;
        }

        teardown {
            main::isa_ok $self, __PACKAGE__;
            main::note 'inner #teardown called for ' . $self->{name};
            main::is $TestCase::test_calls, 3, 'inner #teardown called before others';
            $TestCase::test_calls--;
        }
    }

    END { main::is $TestCase::test_calls, 0 }
};
is(__PACKAGE__, 'main');

use Test::Mini::Runner;
Test::Mini::Runner->new(logger => 'Test::Mini::Logger')->run();

END {
    # Cleanup, so that others aren't polluted if run in the same process.
    @TestCase::ISA = ();
    @Test::Case::ISA = ();
}

BEGIN {
    # This is a work-aroudn for the fact that requiring Test::Mini::TestCase
    # wll automatically set up a runner, which we don't want right now.
    use Test::Mini;
    use List::Util qw/ first /;
    use B qw/ end_av /;

    my $index = first {
        my $cv = end_av->ARRAYelt($_);
        ref $cv eq 'B::CV' && $cv->STASH->NAME eq 'Test::Mini';
    } 0..(end_av->MAX);

    ok defined($index), 'END hook installed';

    splice(@{ end_av()->object_2svref() }, $index, 1);
}
