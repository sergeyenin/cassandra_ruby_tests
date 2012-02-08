Cassandra` ruby tests in different environments
============================
cleaning database(delete keyspace):

   rake db:clean

creating necessary Keyspace and ColumnFamily:

	rake db:setup

running writing and reading test:

    rake db:test


Interactive Console
-------------------

You can fire up an interactive console with `rake console` that will have the default models preloaded

The model has a fairly simple API: `insert`, `get`, and `delete`.