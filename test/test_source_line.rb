require "test_helper"

class SourceLineTest < Test::Unit::TestCase
  def test_line_that_begins_with_double_slash_should_be_a_comment
    assert source_line("//").comment?
    assert source_line("//test").comment?
    assert source_line("//= require").comment?
    assert source_line("//= require <foo>").comment?
    assert source_line(" //").comment?
    assert source_line("\t//").comment?
  end

  def test_line_that_begins_a_multiline_comment
    assert source_line(" /*").begins_multiline_comment?
    assert source_line(" /**").begins_multiline_comment?
  end

  def test_line_that_begins_a_pdoc_comment
    assert !source_line(" /*").begins_pdoc_comment?
    assert source_line(" /**").begins_pdoc_comment?
  end

  def test_line_that_ends_a_multiline_comment
    assert source_line(" */").ends_multiline_comment?
    assert source_line(" **/").ends_multiline_comment?
  end

  def test_line_that_ends_a_pdoc_comment
    assert !source_line(" */").ends_pdoc_comment?
    assert source_line(" **/").ends_pdoc_comment?
  end

  def test_line_that_contains_but_does_not_begin_with_double_slash_should_not_be_a_comment
    assert !source_line("f //").comment?
    assert !source_line("f //= require <foo>").comment?
  end

  def test_comment_should_be_extracted_from_comment_lines
    assert_equal "test", source_line("//test").comment
    assert_equal " test", source_line("// test").comment
    assert_equal nil, source_line("f //test").comment
  end
  
  def test_line_that_contains_require_comment_should_be_a_require
    assert source_line("//= require <foo>").require?
    assert !source_line("//= require<foo>").require?
    assert source_line("//= require \"foo\"").require?
    assert source_line("//= require \'foo\'").require?
    assert !source_line("//= require <foo> f").require?
  end
  
  def test_require_should_be_extracted_from_require_lines
    assert_nil source_line("//= require").require
    assert_equal "<foo>", source_line("//= require <foo>").require
    assert_equal "<foo>", source_line("//= require   <foo> ").require
    assert_equal "\"foo\"", source_line("//= require \"foo\"").require
  end

  def test_line_that_contains_a_provide_comment_should_be_a_provide
    provide = [
      "//= provide \"../assets\"",
      "//= provide \'../assets\'",
      "//= provide <../assets>",
      "//= provide \"../assets/stylesheets\" as \"stylesheets\"",
      "//= provide \"../assets/stylesheets\" as \'stylesheets\'"
    ]
    do_not_provide = [
      "//= provide",
      "//= provide \"../assets\" as ",
      "//= provide \"../assets\" as <stylesheets>"
    ]
    
    provide.all? do |p|
      assert source_line(p).provide?
    end
    do_not_provide.all? do |p|
      assert !source_line(p).provide?
    end
  end
  
  def test_line_that_contains_an_alias_should_be_an_alias
    aliased = [
      "//= provide \"../assets/stylesheets\" as \"stylesheets\"",
      "//= provide \"../assets/stylesheets\" as \'stylesheets\'"
    ]
    not_aliased = [
      "//= provide \"../assets\"",
      "//= provide \"../assets\" as ",
      "//= provide \"../assets\" as <stylesheets>"
    ]
    
    aliased.all? do |p|
      assert source_line(p).alias?
    end
    not_aliased.all? do |p|
      assert !source_line(p).alias?
    end
  end
  
  def test_provide_should_be_extracted_from_provide_lines
    assert_nil source_line("//= provide").provide
    assert_equal "../assets", source_line("//= provide \"../assets\"").provide
  end
  
  def test_provide_alias_should_be_extracted_from_provide_lines
    assert_nil source_line("//= provide \"../assets\"").alias
    assert_equal "stylesheets", source_line("//= provide \"../assets/stylesheets\" as \"stylesheets\"").alias
  end

  def test_inspect_should_include_source_file_location_and_line_number
    environment = environment_for_fixtures
    pathname    = Sprockets::Pathname.new(environment, "/a/b/c.js")
    source_file = Sprockets::SourceFile.new(environment, pathname)
    assert_equal "line 25 of #{File.expand_path("/a/b/c.js")}", source_line("hello", source_file, 25).inspect
  end
  
  def test_interpolation_of_constants
    assert_equal %(var VERSION = "1.0";\n), source_line('var VERSION = "<%= VERSION %>";').to_s("VERSION" => "1.0")
  end
  
  def test_evaluation_of_constants
    assert_equal %(var VERSION = 1;\n),
      source_line('var VERSION = <%= VERSION.to_i %>;').to_s("VERSION" => "1.0")
    assert_equal %(var VERSION = \"1\";\n),
      source_line('var VERSION = <%= VERSION.to_i.to_s.inspect %>;').to_s("VERSION" => "1.0")
  end
  
  def test_interpolation_of_missing_constant_raises_undefined_constant_error
    assert_raises(Sprockets::UndefinedConstantError) do
      source_line('<%= NONEXISTENT %>').to_s("VERSION" => "1.0")
    end
  end
  
  def test_to_s_should_strip_trailing_whitespace_before_adding_line_ending
    assert_equal "hello();\n", source_line("hello();     \t  \r\n").to_s({})
  end
end
