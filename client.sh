#!/bin/sh
export ROOT=$(cd `dirname $0`; pwd)

$ROOT/3rd/lua/lua $ROOT/myclient/client.lua 127.0.0.1 2013

