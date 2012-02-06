Cassandra` ruby tests in different environments
============================

creating necessary Keyspace and ColumnFamily:

	rake db:setup

running 10mln records populating task:

    rake db:populate


Interactive Console
-------------------

You can fire up an interactive console with `rake console` that will have the `TestColumnFamily` model preloaded.

The model has a fairly simple API: `insert`, `get`, and `delete`.

`insert`:

	>> TestColumnFamily.insert "some_key", 0 => "content"
	 => nil

`get`:

	>> a = TestColumnFamily.get "some_key"
	=> #<TestColumnFamily:0x1018ff0f0 @attributes=#<OrderedHash {<Cassandra::Long#2160580140 time: Thu Jan 01 00:00:00 UTC 1970, usecs: 0, jitter: 0, guid: 00000000-0000-0000>=>"content"}>, @key="some_key">
	>> a[0]
	 => "content"

`remove`:

	>> TestColumnFamily.remove "some_key"
	=> nil


