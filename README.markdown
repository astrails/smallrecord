SmallRecord
===========

Simple Object persistency library for Cassandra

Home: [http://astrails.com/smallrecord](http://astrails.com/smallrecord)

Status
------

This is work in progress. It is currently used in a client project and works
well, but it still has rough edges and might have problems in your specific
environment.  The code base is quite small and modular though, so you should
have no problems jumping in and fixing or extending it for your use case.

Motivation & History (you can skip it :)
----------------------------------------

I was developing an multiplayer online game for a client (TBD: link when
released :) and we decided to use [Cassandra](http://incubator.apache.org/cassandra/)
for performance and scaling benefits. Also the game's internal data structures
mapped very well to key-value semantics.

I did some research but couldn't find anything that was **Ready at the time**
to be used for development.

I did find the [BigRecord](http://www.bigrecord.org/) project which somewhat
kind of supported Cassandra, but I got an impression that Cassandra support was
'bolted on' after the fact, and their way of running a java Cassandra driver
talking to some JRuby and interfacing with it through DRB was ... can't quite
find the word for it, lets call it 'awkward' :).

So I started to work on my own library, "steaing" liberally from BigObject,
which at least at the time was very close to ActiveRecord with just some
parts of the code commented out or replaced.

Somewhere midway through the implementation I found the
[CassandraObject](http://github.com/NZKoz/cassandra_object) project by
[NZKoz](http://github.com/NZKoz).  Now that was a much better one. So much
better that for some time I just considered dumping all I did and using it
as-is. After some thinking I decided against it though.  The primary reason was
that its data model was quite different from what I intended to use for the
game. In CassandraObject all attributes are stored as columns in a simple
[ColumnFamily](http://wiki.apache.org/cassandra/DataModel), and indexes and
associations stored in separate ColumnFamilies. This has a benefit of not
having restrictions on the number of associated object, but it does require
additional DB queries to access associated objects.

I wanted to use
[Supercolumns](http://arin.me/blog/wtf-is-a-supercolumn-cassandra-data-model)
instead, and store attributes and associations in different supercolumns for
the given key.  This has the benefit of being able to fetch all the data at
once, but does restrict the number of associated objects. Since in my intended
use-case the number of associations was rather small I decided to continue the
development.

But, this doesn't mean I didn't use CassandraObject to "steal" some code from  it too :).
There were too many good ideas to pass by. I ended up copying a lot
of code from it and throwing all of the BigRecord heritage. May be someday I'll find
a way to 'combine' SmallRecord back into CassandraObject. Meanwhile though I'm going
to work on this one.

(Ugh, that ended up being rather long explanation :)

Data Model
----------

This library is intended to be used with Supercolumns Families only (for now :).

Model's attributes are stored inside "attributes" supercolumn, with attributes themselves
being columns inside it. Associations are stored as separate supercolumns, with each association
id being a column inside.

Example (json notation):

    users: {
      "1": {
        "attributes": {
          "name": "Vitaly Kushner",
          "company": "Astrails"
        },
        "account_ids": {
          "123": "1",
          "456": "1"
        }
    }

    accounts: {
      "123": {
        "url": "http://astrails.com",
        "username": "vitaly",
        "password": "234987234509827345"
      },
      "456": {
        "url": "http://rubyonrails.org",
        "username": "vitaly",
        "password": "3084573945873945"
      }
    }

As you can see we have a one-to-many association here. but contrary to how it is handled
in ActiveRecord we don't store the user\_id in the account 'record', instead we store all the
account\_ids in the user record. This is because otherwise we would have no way of querying user.accounts
except for the full accounts 'table' scan.

Implementation
--------------

### Connecting to the DB

SmallRecord will look for the file config/small\_record.yml :

    production:
      adapter: cassandra
      host: 127.0.0.1
      port: 9160
      keyspace: astrails 

    development:
      adapter: mock

    test:
      adapter: mock

Notice the :mock adapter. This is just a simple
Cassandra emulation using in-memory ruby hash. This is what I'm using
for development and testing. It doesn't require cassandra running.
The emulation is not 100% off course but it does the job. And I didn't
yet have any bugs related to the difference b/w the mock and the real thing.
Just remember that if you run develoment server with mock all the data will be gone
once you restart. But that is probably not such a bad thing for development. Or
it is. You decide.


### Basics

You define your models the usual way:


    class User < SmallRecord::Base
      ...
    end

    user = User.new :foo => "bar"
    user.save
    User.find(user.id)
    User.first

### Attributes

What is different from the ActiveRecord is that you have to tell SmallRecord
about all your attributes since it can't infer it from the database schema like
ActiveModel does. There is no database schema duh!  The attributes support
mostly came form CassandraObject but changed quite a bit since then. One day
I'll document the differences :)

    class User < SmallRecord::Base
      attribute :name
      attribute :age, :type => :integer
      attribute :create_at, :type => :time
    end

### ActiveModel

This library is built upon Rails's ActiveModel pulling in many of the familiar features of
the ActiveRecord. The following is supported:

#### Callbacks

    before_save :do_something

The following callbacks are supported:

        :before_init,    :after_init,
        :before_find,    :after_find,
        :before_save,    :after_save,
        :before_create,  :after_create,
        :before_update,  :after_update,
        :before_destroy, :after_destroy,
        :before_validation,
        :before_validation_on_create,
        :before_validation_on_update

You can also define your own callbacks:

    class User < SmallRecord::Base
      define_callbacks :after_activation

      after_activation :send_confirmation

      def activate!
        ...
        run_callbacks(:after_activation)
      end
    end

#### Dirty attributes

    >> user.changed
    => []
    >> user.name = "foo"
    => "foo"
    >> user.changed
    => ["name"]
    >> user.name_changed?
    => true

When saving an object it will only save changed attributes:

    >> user.save
    => true
    >> user.name = "qwe"
    => "qwe"
    >> user.save
      User Insert (0.000043)   insert(aa421ea0-c407-46fe-986f-09b2d749b1be, {"attributes"=>{"name"=>"\"qwe\"", "schema_version"=>"0"}}, {})
    => true
 
#### Validations

    class User < SmallRecord::Base
      validates_presence_of :name
    end

#### Associations

Association support in SmallRecord is rather basic. Only has\_many is supported at the moment (feel free to add more :).

    class User < SmallRecord::Base
      has_many :accounts
    end

    user.accounts
    user.accounts.create
    user.create_account
    user.account_ids
    user.accounts.first

SmallRecord tries hard to do the minimal required amount of work. the association is
lazily loaded and only when really needed.

#### Migrations

Migrations are very different then what you are used to with ActiveRecord (this is too comes from CassandraObject).

You see, there might be a LOT of records in a Cassandra DB. To the point of it being quite impractical to run
a full migration. Instead each 'record' contains its schema-version and we migrate it on read if its outdated.
i.e. if we load a record into memory with schema\_version that is less then the currently defined in the code
we will migrate **this record**. If you save the record after that it will be saved with the updated version.

migrations are defined using blocks:

    class User
      migrate 1 do |attrs|
        attrs[:foo] = attrs.delete(:bar)
      end
      ...
    end

#### More

Read the code :)

#### TODO

There are a couple of things that I want to fix first:

* The elephant in the room is the total lack of testing! Well, in the project I'm
  extracting this from the test coverage is quite high, so all the code was implicitly
  tested, but now that this is a separate project I need to add some specs.

* There is this ugly read/write\_data business. Apart from the bad naming
  (I still can't think of a good one) all the supercolumns except for the
  'attributes' are not managed.  They are currently written directly into db on
  every change. Need to unify the 'dirty' handling in attributes with the rest
  of supercolumns. For that I think I'll need to drop the Dirty mixin from the
  ActiveModel and just roll my own.

* Documentation. This is also lacking at the moment and you will need to look at the code.

* Need to research the possibility of merging with CassandraObject. Thought I'm not sure this
  is practical.

