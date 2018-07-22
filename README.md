Nagle's Algorithm Effect
========================

See how [Nagle's Algorithm](https://en.wikipedia.org/wiki/Nagle%27s_algorithm) impacts sequence of small-chunk write-write-read on socket.

HOW TO USE
----------

1. Start server by `go run server.go`
2. Run client with write-read on socket by `perl client.pl`
3. Run client with write-write-read on socket by `perl client.pl --autoflush`

Write-write-read client should run super slower than write-read client.
