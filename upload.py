#!/usr/bin/env python3
import argparse
import asyncio
import time
import binascii
import re
import sys
import socket
RE_COMMENT = '^\s*--.*'
NODEMCU_PROMPT = b"> "

# esp8266 has 128byte hardware UART buffer,
# we should not exceed it, otherwise
UART_HW_BUF_SIZE = 128
# lets CPU to process incoming UART pkt
UART_FEED_DELAY = 0.1

class EspConn:
    def __init__(self):
        super().__init__()
        self.debug = False

    def log(self, msg):
        if self.debug:
            print(msg)

    def onrecv(self, buf):
        try:
            s = buf.decode()
        except:
            print("possibly corrupted buffer: ", buf)
            raise
        if self.debug:
            print(f"recv: '{s}'")
        else:
            sys.stdout.write('.')
            sys.stdout.flush()

class TcpConn(EspConn):
    reader = None
    writer = None

    def open(self, host, port):
        aio_run(self._open(host, port))

    async def _open(self, host, port):
        self.log(f"Connecting to {host}:{port}")
        self.reader, self.writer = await asyncio.open_connection(host, port)
        # initialize prompt(we start from unknown term state)
        writer = self.writer
        reader = self.reader
        time.sleep(1)
        self.log("initializing terminal")
        writer.write(("print(244+422)\n").encode())
        await writer.drain()
        await reader.readuntil(f"{244+422}".encode())
        self.log("got lua response")
        await reader.readuntil(NODEMCU_PROMPT)
        self.log("prompt is ready response")

    def send(self, cmd):
        aio_run(self._send(cmd))

    async def _send(self, cmd):
        writer = self.writer
        reader = self.reader
        writer.write((cmd+'\n').encode())
        await writer.drain()
        if self.debug:
            print("sent: " + cmd)
        res = await reader.readuntil(NODEMCU_PROMPT)
        # give 1ms to send extra > or ' ', '\n' if any
        #time.sleep(0.01)
        #res += await reader.read(1024)
        self.onrecv(res)

    def close(self):
        self.writer.close()
        aio_run(self.writer.wait_closed())

class SerialConn(EspConn):
    ser = None

    def open(self, port, baud):
        self.ser = serial.Serial(port, baud, timeout=10)
        print(self.ser)

    def send(self, cmd):
        fifo = (cmd+'\n').encode()
        while len(fifo) > 0:
            self.ser.write(fifo[:UART_HW_BUF_SIZE])
            fifo = fifo[UART_HW_BUF_SIZE:]
            time.sleep(UART_FEED_DELAY)
        if self.debug:
            print("sent: " + cmd)
        # sending too fast will cause buffer overflow?
        mirror_command = self.ser.readline()
        self.onrecv(mirror_command)
        while True:
            res = self.ser.read_until(NODEMCU_PROMPT)
            self.onrecv(res)
            if res == b"" or b'>' in res:
                break

    def close(self):
        self.ser.close()


def aio_run(coroutine):
    loop = asyncio.get_event_loop()
    loop.run_until_complete(coroutine)

def main():
    parser = argparse.ArgumentParser(description='Uploads script to nodemcu via telnet connection')
    parser.add_argument('action', choices=['upload', 'print'])
    parser.add_argument('--serial', help='nodemcu serial port connection')
    parser.add_argument('--baud', type=int, default=115200, help='nodemcu serial port baud')
    parser.add_argument('--host', help='nodemcu hostname/ip')
    parser.add_argument('--port', default=23, help='telnet port')
    parser.add_argument('--debug', action='store_true')
    parser.add_argument('--keep', action='store_true', help='keep formatting, comments')
    parser.add_argument('file', type=str, nargs="+", help='files to upload')

    args = parser.parse_args()

    if args.serial:
        import serial
        esp = SerialConn()
        esp.debug = args.debug
        esp.open(args.serial, args.baud)
    elif args.host:
        esp = TcpConn()
        esp.debug = args.debug
        esp.open(args.host, args.port)
    else:
        print("specify --host or --serial")
        exit(1)
    print(esp.debug)

    for fn in args.file:
        print("sending " + fn)
        # make sure term is ready
        esp.send('=22333+33222')
        esp.send("fdupload=file.open('{}', 'w')".format(fn))
        esp.send("function unhex(str) return (str:gsub('..', function (cc) return string.char(tonumber(cc, 16)) end)) end")

        for l in open(fn):
            if not args.keep and re.match(RE_COMMENT, l):
                next
            if args.debug:
                print('sending: ' + l.strip())
            esp.send("fdupload:write(unhex('{}'))\n".format(binascii.hexlify(l.encode()).decode('ascii')))

        esp.send("fdupload:flush()")
        esp.send("fdupload:close()")
        esp.send("fdupload=nil")
        print("\nsent " + fn)
    # ensure we're done
    esp.send("print('done', 333+555)")
    esp.send("print('exit', 111-111)")
    esp.close()

main()

