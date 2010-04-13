require 'cases/helper'
require 'models/contact'

class Contact
  include ActiveModel::Serializers::Xml

  def attributes
    instance_values
  end
end

module Admin
  class Contact < ::Contact
  end
end

class XmlSerializationTest < ActiveModel::TestCase
  def setup
    @contact = Contact.new
    @contact.name = 'aaron stack'
    @contact.age = 25
    @contact.created_at = Time.utc(2006, 8, 1)
    @contact.awesome = false
    @contact.preferences = { :gem => 'ruby' }
  end

  test "should serialize default root" do
    @xml = @contact.to_xml
    assert_match %r{^<contact>},  @xml
    assert_match %r{</contact>$}, @xml
  end

  test "should serialize namespaced root" do
    @xml = Admin::Contact.new(@contact.attributes).to_xml
    assert_match %r{^<admin-contact>},  @xml
    assert_match %r{</admin-contact>$}, @xml
  end

  test "should serialize default root with namespace" do
    @xml = @contact.to_xml :namespace => "http://xml.rubyonrails.org/contact"
    assert_match %r{^<contact xmlns="http://xml.rubyonrails.org/contact">}, @xml
    assert_match %r{</contact>$}, @xml
  end

  test "should serialize custom root" do
    @xml = @contact.to_xml :root => 'xml_contact'
    assert_match %r{^<xml-contact>},  @xml
    assert_match %r{</xml-contact>$}, @xml
  end

  test "should allow undasherized tags" do
    @xml = @contact.to_xml :root => 'xml_contact', :dasherize => false
    assert_match %r{^<xml_contact>},  @xml
    assert_match %r{</xml_contact>$}, @xml
    assert_match %r{<created_at},     @xml
  end

  test "should allow camelized tags" do
    @xml = @contact.to_xml :root => 'xml_contact', :camelize => true
    assert_match %r{^<XmlContact>},  @xml
    assert_match %r{</XmlContact>$}, @xml
    assert_match %r{<CreatedAt},     @xml
  end

  test "should allow skipped types" do
    @xml = @contact.to_xml :skip_types => true
    assert %r{<age>25</age>}.match(@xml)
  end

  test "should include yielded additions" do
    @xml = @contact.to_xml do |xml|
      xml.creator "David"
    end
    assert_match %r{<creator>David</creator>}, @xml
  end

  test "should serialize string" do
    assert_match %r{<name>aaron stack</name>}, @contact.to_xml
  end

  test "should serialize integer" do
    assert_match %r{<age type="integer">25</age>}, @contact.to_xml
  end

  test "should serialize datetime" do
    assert_match %r{<created-at type=\"datetime\">2006-08-01T00:00:00Z</created-at>}, @contact.to_xml
  end

  test "should serialize boolean" do
    assert_match %r{<awesome type=\"boolean\">false</awesome>}, @contact.to_xml
  end

  test "should serialize yaml" do
    assert_match %r{<preferences type=\"yaml\">--- \n:gem: ruby\n</preferences>}, @contact.to_xml
  end

  test "should call proc on object" do
    proc = Proc.new { |options| options[:builder].tag!('nationality', 'unknown') }
    xml = @contact.to_xml(:procs => [ proc ])
    assert_match %r{<nationality>unknown</nationality>}, xml
  end

  test 'should supply serializable to second proc argument' do
    proc = Proc.new { |options, record| options[:builder].tag!('name-reverse', record.name.reverse) }
    xml = @contact.to_xml(:procs => [ proc ])
    assert_match %r{<name-reverse>kcats noraa</name-reverse>}, xml
  end
end
