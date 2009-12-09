$: <<
File.expand_path("../../vendor/activesupport/lib", __FILE__) <<
File.expand_path("../../vendor/activemodel/lib", __FILE__)
require 'i18n'
require 'activesupport'
require 'activemodel'
require 'active_support/concern'
require 'active_support/core_ext/array/wrap'

module SmallRecord
end

require 'small_record/base'