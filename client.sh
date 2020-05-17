#!/bin/sh
export ROOT=$(cd `dirname $0`; pwd)

$ROOT/3rd/lua/lua $ROOT/myclient/client.lua $ROOT $1

