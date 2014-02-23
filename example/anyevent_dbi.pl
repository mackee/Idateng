#!/usr/bin/env perl
use strict;
use warnings;
use 5.18.2;

use lib 'lib';
use Idateng;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:dbname=test.db', '', '');
$dbh->do('DROP TABLE IF EXISTS t1');
$dbh->do(<<'...');
CREATE TABLE IF NOT EXISTS t1 (
id INTEGER PRIMARY KEY,
name TEXT NOT NULL
);
...

$dbh->do('INSERT INTO t1 (name) VALUES("hogehoge")');

$dbh->disconnect;

my $idateng = Idateng->new(
    connect_info => ['dbi:SQLite:dbname=test.db', '', '']
);

$idateng->query('t1', {
    id => 1
})->search->do(sub {
    my ($query, $rows, $rv) = @_;
    while (my $row = $rows->next) {
        for my $column (@{$row->column_names}) {
            warn $column.' -> '.$row->$column; 
        }
    }
    $idateng->cv->broadcast;
});

$idateng->cv->wait;
