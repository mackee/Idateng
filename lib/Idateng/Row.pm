package Idateng::Row;
use 5.008005;
use strict;
use warnings;

use Moo;
use Carp qw/croak/;

has idateng => (
    is => 'rw',
    required => 1
);

has column_names => (
    is => 'rw',
    required => 1,
);

has row => (
    is => 'rw',
    required => 1,
);

no Moo;

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my ($method) = ($AUTOLOAD =~ /([^:']+$)/);

    $self->get_column($method);
}

sub get_column {
    my ($self, $column_name) = @_;

    return $self->row->[$self->_get_column_number($column_name)];
}

sub _get_column_number {
    my ($self, $column_name) = @_;

    my $column_number;
    for my $i (0..scalar(@{$self->column_names}) - 1) {
        if ($column_name eq $self->column_names->[$i]) {
            $column_number = $i;
            last;
        }
    }

    croak 'invalid column name' unless defined $column_number;

    return $column_number;
}

1;
