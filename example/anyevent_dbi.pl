#!/usr/bin/env perl
use strict;
use warnings;
use 5.18.2;

use lib 'lib';
use Idateng;
use DBI;
use AnyEvent;

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

my $cv = AnyEvent->condvar;

$idateng->query('t1', {
    id => 1
})->search->do(sub {
    my ($query, $rows, $rv) = @_;
    while (my $row = $rows->next) {
        for my $column (@{$row->column_names}) {
            warn $column.' -> '.$row->$column; 
        }
    }
    return $query;
})->update({
    name => 'barbar'
})->do->search->do(sub {
    my ($query, $rows, $rv) = @_;
    $cv->send($rows->first->name);
});

my $result = $cv->recv;
warn $result; # barbar
