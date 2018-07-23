use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use IO::Socket::INET;

my $autoflush;
my $count;
GetOptions(
    'autoflush' => \$autoflush,
    'count=i'   => \$count,
);
$count = 1 if not $count;

my $crlf = "\x0d\x0a";

my $sock = IO::Socket::INET->new(
    PeerAddr => 'localhost',
    PeerPort => '5000',
    Proto    => 'tcp',
);

# enable autoflushing only with option `--autoflush`
my $oldfh = select $sock;
$| = $autoflush ? 1 : 0;
select $oldfh;

my $data = <<END_OF_DATA;
hoge
fuga
foo
bar
buz
END_OF_DATA
my $len = length $data;

for (my $i = 0; $i < $count; $i++) {
    print $sock "ECHO ${len}${crlf}";
    print $sock "${data}${crlf}";
    $sock->flush;

    my $resp = <$sock>;
    my $exp_len = substr $resp, 1, -2;
    my $read_len = $exp_len + 2;

    my $buffer;
    my $n = read $sock, $buffer, $read_len, 0;
    die "read ${n} bytes where ${read_len} bytes were expected" if $n != $read_len;

    my $data = substr $buffer, 0, -2;
    my $data_len = length $data;
    print "try ${i}: got ${data_len} bytes${crlf}";
}
