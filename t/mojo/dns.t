use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use Mojo::DNS qw(inet_aton);
use Mojo::DNS::Util qw(format_ipv4);
use Mojo::IOLoop;
use Mojo::IOLoop::Delay;

my $delay = Mojo::IOLoop::Delay->new;

my $end = $delay->begin;

my $addr;

inet_aton 'mojolicio.us', sub { $addr = format_ipv4 shift; $end->() };

$delay->wait;

is $addr, '88.198.24.70', 'mojolicio.us is 88.198.24.70';

done_testing();
