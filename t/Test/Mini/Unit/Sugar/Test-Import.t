use Test::Mini::Unit;

{
    package ImportTest;
    use Test::Mini::Unit::Sugar::Test;
    
    test everything { return 42 }
    test self       { return $self }
}

{
    package X;

    package Y;
    use Test::Mini::Unit::Sugar::Test into => 'X';
}

case t::Test::Mini::Unit::Sugar::Test::Import {
    test keyword_creates_new_method {
        assert_can(ImportTest => 'test_everything');
        assert_equal(ImportTest->test_everything(), 42);
    }

    test methods_automatically_assign_self_variable {
        assert_equal(ImportTest::test_self('FIRST') => 'FIRST');
    }

    test into_option_imports_keyword_into_specified_class {
        assert_can(X => 'test');
    }

    test into_option_does_not_import_keyword_into_current_class {
        refute_can(Y => 'test');
    }
}
