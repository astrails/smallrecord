# TODO:
# - proper exceptions instead of 'raise'
# - stringify_proxy for ordered_hash
# - only save dirty attributes!

require 'cassandra'
require 'uuidtools'

module SmallRecord
  class SmallRecordError < StandardError;end
  class InvalidAttribute < SmallRecordError;end

  require 'small_record/connection'
  require 'small_record/naming'
  require 'small_record/callbacks'
  require 'small_record/identity'
  require 'small_record/identity/uuid'
  require 'small_record/attributes'
  require 'small_record/logger'
  require 'small_record/driver'
  require 'small_record/persistence'
  require 'small_record/iteration'
  require 'small_record/finders'
  require 'small_record/dump'
  require 'small_record/dirty'
  require 'small_record/migrations'
  require 'small_record/validation'
  require 'small_record/associations'

  class Base
    include Connection
    include Naming
    include Callbacks
    include Identity
    include Attributes
    include Logger
    include Driver
    include Persistence
    include Iteration
    include Finders
    include Dump
    include Dirty
    include Migrations
    include Validation
    include Associations

    def to_s
      inspect
    end
  end
end