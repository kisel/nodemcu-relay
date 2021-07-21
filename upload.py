#!/usr/bin/env python3
import argparse
import asyncio
import time
import binascii

async def main():
    parser = argparse.ArgumentParser(description='Uploads script to nodemcu via telnet connection')
    parser.add_argument('host', help='nodemcu hostname/ip')
    parser.add_argument('--port', default=23, help='telnet port')
    parser.add_argument('--debug', action='store_true')
    parser.add_argument('file', type=str, nargs="+", help='files to upload')

    args = parser.parse_args()

    reader, writer = await asyncio.open_connection(args.host, args.port)
    def wait_prompt():
        time.sleep(0.1)

    async def send(cmd):
        writer.write(cmd.encode())
        if args.debug:
            print(cmd)
        await writer.drain()
        res = await reader.readuntil(b">")
        time.sleep(0.01)
        b = await reader.read(1024)
        res += b
        if args.debug:
            print("recv prompt: " + res.decode())
        else:
            print('.', end='')

    for fn in args.file:
        print("sending " + fn)
        # make sure term is ready
        await send('=65535\n')
        await send("f=file.open('{}', 'w')".format(fn))
        await send("function unhex(str) return (str:gsub('..', function (cc) return string.char(tonumber(cc, 16)) end)) end")

        for l in open(fn):
            if args.debug:
                print('sending: ' + l.strip())
            await send("f:write(unhex('{}'))\n".format(binascii.hexlify(l.encode()).decode('ascii')))
            await writer.drain()
            wait_prompt()

        await send("f:close()")
        print("\nsent " + fn)
    # ensure we're done
    await send("print('done', 333+555)")
    writer.close()
    await writer.wait_closed()

asyncio.run(main())

