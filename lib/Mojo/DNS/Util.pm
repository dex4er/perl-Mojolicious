package Mojo::DNS::Util;

use Mojo::Base -strict;

use Exporter 'import';

our @EXPORT_OK = (
    qw(parse_address parse_ipv4 parse_ipv6 format_ipv4 format_ipv6),
);

sub parse_address {
    my $text = shift;
    if (my $addr = parse_ipv6($text)) {
        $addr =~ s/^\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff//;
        return $addr;
    } else {
        return parse_ipv4($text);
    }
}

sub parse_ipv4 {
    $_[0] =~ /^      (?: 0x[0-9a-fA-F]+ | 0[0-7]* | [1-9][0-9]* )
              (?:\. (?: 0x[0-9a-fA-F]+ | 0[0-7]* | [1-9][0-9]* ) ){0,3}$/x
                  or return undef;

    @_ = map /^0/ ? oct : $_, split /\./, $_[0];

    # check leading parts against range
    return undef if grep $_ >= 256, @_[0 .. @_ - 2];

    # check trailing part against range
    return undef if $_[-1] >= 2 ** (8 * (4 - $#_));

    pack "N", (pop)
        + ($_[0] << 24)
        + ($_[1] << 16)
        + ($_[2] <<  8);
}

sub parse_ipv6 {
    # quick test to avoid longer processing
    my $n = $_[0] =~ y/://;
    return undef if $n < 2 || $n > 8;

    my ($h, $t) = split /::/, $_[0], 2;

    unless (defined $t) {
        ($h, $t) = (undef, $h);
    }

    my @h = defined $h ? (split /:/, $h) : ();
    my @t = split /:/, $t;

    # check for ipv4 tail
    if (@t && $t[-1]=~ /\./) {
        return undef if $n > 6;

        my $ipn = parse_ipv4(pop @t)
            or return undef;

        push @t, map +(sprintf "%x", $_), unpack "nn", $ipn;
    }

    # no :: then we need to have exactly 8 components
    return undef unless @h + @t == 8 || $_[0] =~ /::/;

    # now check all parts for validity
    return undef if grep !/^[0-9a-fA-F]{1,4}$/, @h, @t;

    # now pad...
    push @h, 0 while @h + @t < 8;

    # and done
    pack "n*", map hex, @h, @t
}

sub format_ipv4($) {
   join ".", unpack "C4", $_[0]
}

sub format_ipv6($) {
   if ($_[0] =~ /^\x00\x00\x00\x00\x00\x00\x00\x00/) {
      if (v0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0 eq $_[0]) {
         return "::";
      } elsif (v0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1 eq $_[0]) {
         return "::1";
      } elsif (v0.0.0.0.0.0.0.0.0.0.0.0 eq substr $_[0], 0, 12) {
         # v4compatible
         return "::" . format_ipv4 substr $_[0], 12;
      } elsif (v0.0.0.0.0.0.0.0.0.0.255.255 eq substr $_[0], 0, 12) {
         # v4mapped
         return "::ffff:" . format_ipv4 substr $_[0], 12;
      } elsif (v0.0.0.0.0.0.0.0.255.255.0.0 eq substr $_[0], 0, 12) {
         # v4translated
         return "::ffff:0:" . format_ipv4 substr $_[0], 12;
      }
   }

   my $ip = sprintf "%x:%x:%x:%x:%x:%x:%x:%x", unpack "n8", $_[0];

   # this is admittedly rather sucky
      $ip =~ s/(?:^|:) 0:0:0:0:0:0:0 (?:$|:)/::/x
   or $ip =~ s/(?:^|:)   0:0:0:0:0:0 (?:$|:)/::/x
   or $ip =~ s/(?:^|:)     0:0:0:0:0 (?:$|:)/::/x
   or $ip =~ s/(?:^|:)       0:0:0:0 (?:$|:)/::/x
   or $ip =~ s/(?:^|:)         0:0:0 (?:$|:)/::/x
   or $ip =~ s/(?:^|:)           0:0 (?:$|:)/::/x
   or $ip =~ s/(?:^|:)             0 (?:$|:)/::/x;

   $ip
}

1;

=encoding utf8

=head1 NAME

Mojo::DNS::Util - functions related to DNS

=head1 SYNOPSIS

    use Mojo::DNS::Util qw(parse_address);

    my $addr = parse_address 'mojolicio.us';

=head1 DESCRIPTION

XXX

=head1 FUNCTIONS

L<Mojo::Util> implements the following functions, which can be imported
individually.

=head2 parse_address

XXX

=head1 SEE ALSO

L<Mojo::DNS>.

=cut
