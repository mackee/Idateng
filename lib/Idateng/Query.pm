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
        %args,
    );
}

sub search {
    my $self = shift;

    return $self->query(
        $self->table, $self->where, $self->opt,
        phrase => 'search'
    );
}

sub do {
    my ($self, $cb) = @_;

    if ($self->phrase eq 'search') {
        my ($stmt, @binds) =
            $self->idateng->sql_builder->select(
                $self->table, $self->build_colmuns, $self->where, $self->opt
            );
        $self->idateng->dbh->exec($stmt, @binds, sub {
            my ($dbh, $rows, $rv) = @_;
            my $idateng_rows = Idateng::Rows->new(
                idateng => $self->idateng,
                table => $self->table,
                rows => $rows,
            );
            $cb->($self, $idateng_rows, $rv);
        });
    }
    else {
        croak 'sql phrase is empty';
    }
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
