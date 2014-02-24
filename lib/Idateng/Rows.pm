package Idateng::Rows;
use 5.008005;
use strict;
use warnings;

use Idateng::Row;

use Moo;

has idateng => (
    is => 'rw',
    required => 1
);

has table => (
    is => 'ro',
    required => 1
);

has rows => (
    is => 'rw',
    required => 1
);

has pointer => (
    is => 'rw',
    default => sub { 0 }
);

no Moo;

sub next {
    my $self = shift;

    return if $self->pointer >= scalar(@{$self->rows});

    my $row = Idateng::Row->new(
        column_names => $self->idateng->tables->{$self->table},
        row => $self->rows->[$self->pointer],
        idateng => $self->idateng
    );

    $self->pointer($self->pointer + 1);

    return $row;
}

sub all {
    my $self = shift;

    my @rows = map {
        Idateng::Row->new(
            column_names => $self->idateng->tables->{$self->table},
            row => $_,
            idateng => $self->idateng
        )
    } @{$self->rows};

    return wantarray ? @rows : [@rows];
}

sub first {
    my $self = shift;

    return Idateng::Row->new(
        column_names => $self->idateng->tables->{$self->table},
        row => $self->rows->[0],
        idateng => $self->idateng
    );
}

1;
