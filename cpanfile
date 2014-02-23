requires 'perl', '5.010001';
requires 'AnyEvent::DBI';
requires 'Promises::Deferred';
requires 'Moo';
requires 'SQL::Maker';
requires 'DBIx::Inspector';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

