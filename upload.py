#!/usr/bin/env python3
import argparse
import asyncio
import time
import binascii
import re
import sys
import serial
import socket
RE_COMMENT = '^\s*--.*'

class EspConn:
    def __init__(self):
        self.debug = False

    def onrecv(self, res):
        if self.debug:
            print("recv prompt: " + res)
        else:
            sys.stdout.write('.')
            sys.stdout.flush()

class TcpConn(EspConn):
    def __init__(self, host, port):
        self.reader = None
        self.writer = None

    async def open(self, host, port):
        self.reader, self.writer = await asyncio.open_connection(host, port)

    def send(cmd):
        asyncio.run(main())

    async def _send(cmd):
        writer.write((cmd+'\n').encode())
        if args.debug:
            print(cmd)
        await writer.drain()
        res = await reader.readuntil(b">")
        # give 1ms to send extra > or ' ', '\n' if any
        time.sleep(0.01)
        res += await reader.read(1024)
        self.onrecv(res.decode())

    def close(self):
        self.writer.close()
        asyncio.run(self.writer.wait_closed())

class SerialConn(EspConn):
    def __init__(self, port, baud):
        self.ser = serial.Serial(port, baud, timeout=1)
        print(self.ser)

    def send(self, cmd):
        self.ser.write((cmd+'\n').encode())
        if self.debug:
            print(cmd)
        # sending too fast will cause buffer overflow?
        mirror_command = self.ser.readline().decode()
        self.onrecv(mirror_command)
        while True:
            res = self.ser.readline().decode()
            self.onrecv(res)
            if res == "" or '>' in res:
                break

    def close(self):
        self.ser.close()


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
        esp = SerialConn(args.serial, args.baud)
    elif args.host:
        esp = TcpConn(args.host, args.port)
    else:
        print("specify --host or --serial")
        exit(1)
    esp.debug = args.debug

    for fn in args.file:
        print("sending " + fn)
        # make sure term is ready
        esp.send('=65535\n')
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
    esp.close()

main()

