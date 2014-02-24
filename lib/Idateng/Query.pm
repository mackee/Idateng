package Idateng::Query;
use 5.008005;
use strict;
use warnings;

use Moo;
use Hash::Merge;
use Idateng::Rows;
use Carp qw/croak confess/;

has table => (
    is => 'rw',
    required => 1
);

has where => (
    is => 'rw',
    default => sub { +{} },
);

has opt => (
    is => 'rw',
    default => sub { +{} },
);

has set => (
    is => 'rw',
    default => sub { +{} },
);

has phrase => (
    is => 'rw',
    default => sub { return; },
);

has idateng => (
    is => 'rw',
    required => 1,
);

no Moo;

sub BUILDARGS {
    my ($class, $table, $where, $opt, %args) = @_;

    return {
        table => $table,
        where => $where,
        opt => $opt,
        %args
    };
}

sub query {
    my ($self, $table, $where, $opt, %args) = @_;

    return __PACKAGE__->new(
        $table,
        $self->_merge('where', $where),
        $self->_merge('opt', $opt),
        idateng => $self->idateng,
        set => $self->set,
        %args,
    );
}

sub search {
    my $self = shift;

    croak 'duplicate statement phrase' if $self->phrase;

    return $self->query(
        $self->table, $self->where, $self->opt,
        phrase => 'search',
    );
}

sub update {
    my ($self, $set) = @_;

    croak 'duplicate statement phrase' if $self->phrase;

    return $self->query(
        $self->table, $self->where, $self->opt,
        phrase => 'update',
        set => $self->_merge('set', $set),
    );
}

sub do {
    my ($self, $cb) = @_;
    my $cv = AnyEvent->condvar;

    if ($self->phrase eq 'search') {
        my ($stmt, @binds) =
            $self->idateng->sql_builder->select(
                $self->table, $self->build_colmuns, $self->where, $self->opt
            );
        $self->phrase('');

        $self->idateng->dbh->exec($stmt, @binds, sub {
            my ($dbh, $rows, $rv) = @_;
            my $idateng_rows = Idateng::Rows->new(
                idateng => $self->idateng,
                table => $self->table,
                rows => $rows,
            );
            $cv->send($cb->($self, $idateng_rows, $rv));
        });
    }
    elsif ($self->phrase eq 'update') {
        my ($stmt, @binds) =
            $self->idateng->sql_builder->update(
                $self->table, $self->set, $self->where
            );
        $self->phrase('');

        $self->idateng->dbh->exec($stmt, @binds, sub {
            my ($dbh, $rows, $rv) = @_;
            if (!$cb) {
                $cv->send($self);
            }
            else {
                my $idateng_rows = Idateng::Rows->new(
                    idateng => $self->idateng,
                    table => $self->table,
                    rows => $rows,
                );
                $cv->send($cb->($self, $idateng_rows, $rv));
            }
        });
    }
    else {
        croak 'sql phrase is empty';
    }

    $cv->recv;
}

sub build_colmuns {
    my $self = shift;

    return $self->idateng->tables->{$self->table};
}

sub _merge {
    my ($self, $attr, $hashref) = @_;

    return Hash::Merge::merge($self->$attr, $hashref);
}

1;
