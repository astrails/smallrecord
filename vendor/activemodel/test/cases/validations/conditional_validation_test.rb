# encoding: utf-8
require 'cases/helper'
require 'cases/tests_database'

require 'models/topic'

class ConditionalValidationTest < ActiveModel::TestCase
 include ActiveModel::TestsDatabase
 include ActiveModel::ValidationsRepairHelper

 repair_validations(Topic)
  
  def test_if_validation_using_method_true
    # When the method returns true
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}", :if => :condition_is_true )
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert !t.valid?
    assert t.errors[:title].any?
    assert_equal ["hoo 5"], t.errors["title"]
  end

  def test_unless_validation_using_method_true
    # When the method returns true
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}", :unless => :condition_is_true )
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert t.valid?
    assert !t.errors[:title].any?
  end

  def test_if_validation_using_method_false
    # When the method returns false
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}", :if => :condition_is_true_but_its_not )
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert t.valid?
    assert t.errors[:title].empty?
  end

  def test_unless_validation_using_method_false
    # When the method returns false
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}", :unless => :condition_is_true_but_its_not )
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert !t.valid?
    assert t.errors[:title].any?
    assert_equal ["hoo 5"], t.errors["title"]
  end

  def test_if_validation_using_string_true
    # When the evaluated string returns true
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}", :if => "a = 1; a == 1" )
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert !t.valid?
    assert t.errors[:title].any?
    assert_equal ["hoo 5"], t.errors["title"]
  end

  def test_unless_validation_using_string_true
    # When the evaluated string returns true
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}", :unless => "a = 1; a == 1" )
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert t.valid?
    assert t.errors[:title].empty?
  end

  def test_if_validation_using_string_false
    # When the evaluated string returns false
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}", :if => "false")
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert t.valid?
    assert t.errors[:title].empty?
  end

  def test_unless_validation_using_string_false
    # When the evaluated string returns false
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}", :unless => "false")
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert !t.valid?
    assert t.errors[:title].any?
    assert_equal ["hoo 5"], t.errors["title"]
  end

  def test_if_validation_using_block_true
    # When the block returns true
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}",
      :if => Proc.new { |r| r.content.size > 4 } )
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert !t.valid?
    assert t.errors[:title].any?
    assert_equal ["hoo 5"], t.errors["title"]
  end

  def test_unless_validation_using_block_true
    # When the block returns true
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}",
      :unless => Proc.new { |r| r.content.size > 4 } )
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert t.valid?
    assert t.errors[:title].empty?
  end

  def test_if_validation_using_block_false
    # When the block returns false
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}",
      :if => Proc.new { |r| r.title != "uhohuhoh"} )
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert t.valid?
    assert t.errors[:title].empty?
  end

  def test_unless_validation_using_block_false
    # When the block returns false
    Topic.validates_length_of( :title, :maximum=>5, :too_long=>"hoo {{count}}",
      :unless => Proc.new { |r| r.title != "uhohuhoh"} )
    t = Topic.create("title" => "uhohuhoh", "content" => "whatever")
    assert !t.valid?
    assert t.errors[:title].any?
    assert_equal ["hoo 5"], t.errors["title"]
  end

  # previous implementation of validates_presence_of eval'd the
  # string with the wrong binding, this regression test is to
  # ensure that it works correctly
  def test_validation_with_if_as_string
    Topic.validates_presence_of(:title)
    Topic.validates_presence_of(:author_name, :if => "title.to_s.match('important')")

    t = Topic.new
    assert t.invalid?, "A topic without a title should not be valid"
    assert t.errors[:author_name].empty?, "A topic without an 'important' title should not require an author"

    t.title = "Just a title"
    assert t.valid?, "A topic with a basic title should be valid"

    t.title = "A very important title"
    assert !t.valid?, "A topic with an important title, but without an author, should not be valid"
    assert t.errors[:author_name].any?, "A topic with an 'important' title should require an author"

    t.author_name = "Hubert J. Farnsworth"
    assert t.valid?, "A topic with an important title and author should be valid"
  end
end
