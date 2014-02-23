package Idateng;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use Moo;
use AnyEvent::DBI;
use AnyEvent;
use SQL::Maker;
use Idateng::Query;
use DBIx::Inspector;
use DBI;

has namespace => (
    is => 'ro',
    default => sub {
        'Idateng::Result'
    },
);

has connect_info => (
    is => 'ro',
    required => 1
);

has dbh => (
    is => 'rw',
    default => sub {
        my $self = shift;
        
        my $connect_info = $self->connect_info;
        return AnyEvent::DBI->new(@$connect_info);
    },
    lazy => 1
);

has cv => (
    is => 'rw',
    default => sub {
        AnyEvent->condvar;
    }
);

has sql_builder => (
    is => 'rw',
    default => sub {
        my $self = shift;
        return SQL::Maker->new(driver => $self->_driver_name);
    },
    lazy => 1,
);

has tables => (
    is => 'rw',
);

sub BUILD {
    my $self = shift;

    $self->inspect_tables;
}

sub query {
    my $self = shift;

    return Idateng::Query->new(
        @_,
        @_ > 2 ? () : ( {} ),
        idateng => $self
    );
}

sub inspect_tables {
    my $self = shift;

    my $dbh = DBI->connect(@{$self->connect_info});
    my $inspector = DBIx::Inspector->new(dbh => $dbh);

    my %tables;
    for my $table ($inspector->tables) {
        $tables{$table->name} = [map { $_->name } $table->columns];
    }

    $self->tables(\%tables);

    $dbh->disconnect;
}

sub _driver_name {
    my $self = shift;
    my ($driver_name) = $self->connect_info->[0] =~ /dbi:(\w+):/i;
    return $driver_name;
}

1;
__END__

=encoding utf-8

=head1 NAME

Idateng - ORMapper for Asynchronous Application

=head1 SYNOPSIS

    use Idateng;

    my $idateng = Idateng->new(
        connect_info => ['dbi:mysql:dbname=test;host=localhost']
    );

    # simple select with callback from 't1' table
    $idateng->search('t1', {
        id => 1
    })->cb(sub {
        my $rs = shift;
        my $row = $rs->single;
        return $row->name;
    });

    # select with result_set
    $idateng->search('t1', {
        id => [1..5] # SELECT * FROM `t1` WHERE `id` IN (1,2,3,4,5)
    })->cb(sub {
        my $rs = shift;
        my @names;
        while (my $row = $rs->next) {
            push @names, $row->name;
        }

        return join(',', @names);
    });

    # insert
    $idateng->fast_insert('t1', {
        name => 'foofoo'
    })->cb(sub {
        my $last_insert_id = shift;
        return $last_insert_id;
    });

    # update with transaction and row lock
    $idateng->txn_begin->single('t1', {
        id => $target_id
    }, {
        for_update => 1
    })->update({
        name => 'barbar'
    })->txn_commit;

    # error handling
    $idateng->on_error(sub {
        my ($idateng, $error) = @_;
        $idateng->txn_rollback;
        return $error;
    })->txn_begin->fast_insert('t1', {
        id => 1, # duplicate key
    })->txn_commit;
    

=head1 DESCRIPTION

Idateng is ...

=head1 LICENSE

Copyright (C) mackee.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mackee E<lt>macopy123@gmail.comE<gt>

=cut

