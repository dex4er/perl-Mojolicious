package Mojo::DNS;

use Mojo::Base -strict;

use Mojo::DNS::Resolver;
use Mojo::DNS::Util qw(parse_address parse_ipv4);
use Exporter 'import';

our @EXPORT_OK = (
    qw(inet_aton),
);

our $resolver;

sub RESOLVER () {
    $resolver ||= Mojo::DNS::Resolver->new;
}

sub inet_aton {
    my $name = shift;
    my $cb = pop;
    my $timeout = shift;

    if (my $address = parse_address($name)) {
        return $cb->($address);
    }
    RESOLVER->resolve(
        $name, 'a',
        ($timeout ? (timeout => $timeout) : ()),
        sub {
            my @rr = @_;
            while (@rr) {
                my $idx = int rand @rr;
                my $address = parse_ipv4($rr[$idx][4]);
                return $cb->($address) if defined $address;
                splice @rr, $idx, 1;
            }
            return $cb->(undef);
        },
    );
}

1;

=encoding utf8

=head1 NAME

Mojo::DNS - query DNS

=head1 SYNOPSIS

    use Mojo::DNS;

    # async replacement for Socket::inet_aton
    Mojo::DNS::inet_aton("www.google.com", sub {
        my ($addr) = @_;
        ...
    });

=head1 DESCRIPTION

This module provides a replacement function for L<Socket::inet_aton>, with support for timeouts and asynchronous queries.

=head1 FUNCTIONS

L<Mojo::Util> implements the following functions, which can be imported
individually.

=head2 inet_aton

  my $ip_address = inet_aton $string

Takes a string giving the name of a host, or a textual representation of an IP address and translates that to an packed binary address
structure suitable to pass to pack_sockaddr_in().

=head1 SEE ALSO

L<Mojo::DNS::Resolver>.

=cut
