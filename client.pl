use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use IO::Socket::INET;

my $autoflush;
GetOptions(
    'autoflush' => \$autoflush,
);

my $crlf = "\x0d\x0a";

my $sock = IO::Socket::INET->new(
    PeerAddr => 'localhost',
    PeerPort => '5000',
    Proto    => 'tcp',
);

# disable flushing
my $oldfh = select $sock;
$| = $autoflush ? 1 : 0;
select $oldfh;

my $data = <<END_OF_DATA;
hoge
fuga
foo
bar
END_OF_DATA
my $len = length $data;

my $count = 0;

for (1 .. 10_000) {
    print $sock "ECHO ${len}${crlf}";
    print $sock "${data}${crlf}";
    $sock->flush;

    my $resp = <$sock>;
    my $exp_len = substr($resp, 1, -2);

    my $buffer = '';
    my $tmp = '';
    my $cur_len = 0;

    while ($cur_len < $exp_len) {
        my $n = $sock->read($tmp, $exp_len, $cur_len);
        $buffer .= $tmp;
        $cur_len += $n;

        if ($cur_len >= $exp_len) {
            $buffer = substr($buffer, 0, $exp_len);
            $sock->read($tmp, 2 - ($cur_len - $exp_len));
            last;
        }
    }

    $count++;
    print "count: ${count}\n";
}
