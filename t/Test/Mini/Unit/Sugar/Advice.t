use Test::More tests => 20;

BEGIN {
    require_ok Test::Mini::Unit::Sugar::Advice;
    eval {
        package Foo;
        Test::Mini::Unit::Sugar::Advice->import();
    };
    ok $@;
}

{
    note 'Testing pre-advice...';
    {
        package Bar;
        use Test::Mini::Unit::Sugar::Advice name => 'up', order => 'pre';
    }

    can_ok Bar => 'up';

    my $up;

    note '  Single declared advisement...';
    {
        package Foo;

        sub up {
            main::is($up, undef, 'existing advice is called first');
            $up = 0;
        }

        use Test::Mini::Unit::Sugar::Advice name => 'up', order => 'pre';
    }

    {
        package Foo;
        up {
            main::is($up, 0, 'declared advice is called next');
            $up = 1;
        }
    }

    Foo->up();
    main::is($up, 1);

    $up = undef;

    note '  Multiple advisements...';
    {
        package Foo;
        up {
            main::is($up, 1, 'subsequent advice is called afterwards');
            $up = 2;
        }
    }

    Foo->up();
    main::is $up, 2;
}

{
    note 'Testing post-advice...';
    {
        package Bar;
        use Test::Mini::Unit::Sugar::Advice name => 'down', order => 'post';
    }

    can_ok Bar => 'down';

    my $down = 0;

    note '  Single declared advisement...';
    {
        package Foo;

        my $counter = 1;
        sub down {
            main::is($down, 2, 'existing advice is called last');
            $down = 3;
        }

        use Test::Mini::Unit::Sugar::Advice name => 'down', order => 'post';
    }

    my $expect = 0;
    {
        package Foo;

        down {
            main::is($down, $expect, 'declared advice is called before existing');
            $down = 2;
        }
    }

    Foo->down();
    main::is($down, 3);

    ($down, $expect) = (undef, 1);

    note '  Multiple advisements...';
    {
        package Foo;
        down {
            main::is($down, undef, 'subsequent advice is called first');
            $down = 1;
        }
    }

    Foo->down();
    main::is($down, 3);
}

note "Testing 'into' flag...";
{
    package Y;
    use Test::Mini::Unit::Sugar::Advice into => 'X', name => 'advice';
}

ok ! Y->can('advice');
can_ok X => 'advice';

1;
