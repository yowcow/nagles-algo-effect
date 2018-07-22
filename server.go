package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"log"
	"net"
	"strconv"
)

var addr = ":5000"
var crlf = "\x0d\x0a"

func main() {
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		panic(err)
	}

	log.Println("server started at", ln.Addr())

	for {
		conn, err := ln.Accept()
		if err != nil {
			panic(err)
		}
		go handle(conn)
	}
}

func handle(conn net.Conn) {
	defer conn.Close()

	r := bufio.NewReader(conn)
	w := bufio.NewWriter(conn)
	sp := []byte(" ")

	for {
		line, _, err := r.ReadLine()
		if err != nil {
			if err != io.EOF {
				log.Println("read failed:", err)
			}
			return
		}

		args := bytes.Split(line, sp)
		comm := string(args[0])

		switch comm {
		case "ECHO":
			if err := doEcho(args, w, r); err != nil {
				log.Println("ECHO failed:", err)
				w.WriteString(fmt.Sprintf("-ERR ECHO failed: %s", err))
				w.WriteString(crlf)
			}
		default:
			w.WriteString(fmt.Sprintf("-ERR command not found: %s", comm))
			w.WriteString(crlf)
		}

		if _, err := r.Discard(r.Buffered()); err != nil {
			log.Println("discard failed:", err)
			return
		}

		if err := w.Flush(); err != nil {
			log.Println("write failed:", err)
			return
		}
	}
}

func doEcho(args [][]byte, w io.Writer, r io.Reader) error {
	expLen, err := strconv.Atoi(string(args[1]))
	if err != nil {
		return err
	}

	buffer := make([]byte, 0, expLen)
	tmp := make([]byte, 4)
	var curLen int

	for {
		n, err := r.Read(tmp)
		if err != nil {
			return err
		}
		buffer = append(buffer, tmp[0:n]...)
		curLen += n

		if curLen > expLen {
			buffer = buffer[0:expLen]
			break
		}
	}

	io.WriteString(w, fmt.Sprintf("$%d", expLen))
	io.WriteString(w, crlf)
	w.Write(buffer)
	io.WriteString(w, crlf)

	return nil
}
