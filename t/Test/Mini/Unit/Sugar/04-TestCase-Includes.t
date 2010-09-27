{
    package ExtraAssertions;
    BEGIN { $INC{'ExtraAssertions.pm'} = __FILE__ }

    use Test::Mini::Assertions;

    sub import {
        no strict 'refs';
        my $caller = caller;
        *{"$caller\::assert_not_appearing_in_the_standard_assertions"} = sub {
            assert(1);
        };
    }
}

use Test::Mini::Unit
    with => 'ExtraAssertions';

case TestWithSingle {
    test it {
        assert_not_appearing_in_the_standard_assertions();
    }

    case Nested {
        test it {
            assert_not_appearing_in_the_standard_assertions();
        }
    }
}


use Test::Mini::Unit
    with => [ 'ExtraAssertions' ];

case TestWithList {
    test it {
        assert_not_appearing_in_the_standard_assertions();
    }

    case Nested {
        test it {
            assert_not_appearing_in_the_standard_assertions();
        }
    }
}
