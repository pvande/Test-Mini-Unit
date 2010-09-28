use Test::Mini::Unit;

our @calls;
{
    package TestPreorder;

    sub up { push @main::calls, 'first' }

    use Test::Mini::Unit::Sugar::Advice name => 'up', order => 'pre';

    up { push @main::calls, 'second' }
    up { push @main::calls, 'third' }
}

{
    package TestPostorder;

    sub down { push @main::calls, 'first' }

    use Test::Mini::Unit::Sugar::Advice name => 'down', order => 'post';

    down { push @main::calls, 'second' }
    down { push @main::calls, 'third' }
}

{
    package TestSelf;
    use Test::Mini::Unit::Sugar::Advice name => 'self', order => 'pre';
    
    self { push @main::calls, $self }
}

{
    package X;

    package Y;
    use Test::Mini::Unit::Sugar::Advice name => 'test', into => 'X';
}

case t::Test::Mini::Unit::Sugar::Advice::Import {
    setup { @main::calls = () }

    case WithOrder {
        case Pre {
            setup { TestPreorder->up() }
            test calls_are_in_declaration_order {
                assert_equal(\@main::calls, [qw/ first second third /]);
            }
        }
        
        case Post {
            setup { TestPostorder->down() }
            test calls_are_in_reverse_declaration_order {
                assert_equal(\@main::calls, [qw/ third second first /]);
            }
        }
    }

    test advice_automatically_assigns_self_variable {
        TestSelf::self('FIRST');
        assert_equal(shift(@main::calls) => 'FIRST');
    }

    test into_option_imports_keyword_into_specified_class {
        assert_can(X => 'test');
    }

    test into_option_does_not_import_keyword_into_current_class {
        refute_can(Y => 'test');
    }
}
