#!/usr/bin/env bash


function run() {
    [ "$#" -lt 2 ] && echo "Usage: main <file> <tile>" && exit 1
    file=$1
    tile=$2
    tile_size=256
    file=$(echo $file | sed 's/s3:\//\/vsis3/g')
    bounds=$(echo $tile | xt | mercantile shapes | jq -r '"\(.bbox[0]) \(.bbox[3]) \(.bbox[2]) \(.bbox[1])"')
    ############################################################################
    zoom=$(echo $tile | cut -d'-' -f1)
    echo "Read mercator tile zoom=$zoom"
    nbytes=$(gdal_translate -q -projwin $bounds -projwin_srs EPSG:4326 -outsize $tile_size $tile_size $file /tmp/out.tif 2>&1 >/dev/null | grep "Content-Length:" | awk '{print $3}' | awk '{n += $1}; END {print n}')
    nget=$(gdal_translate -q -projwin $bounds -projwin_srs EPSG:4326 -outsize $tile_size $tile_size $file /tmp/out.tif 2>&1 >/dev/null | grep "> GET" | wc -l)
    echo "Bytes transfered: "$nbytes
    echo "Nb Http calls: "$nget
    echo "------"
    ############################################################################
    tile=$(echo $tile | xt | mercantile parent --depth 2 | xt -d'-')
    bounds=$(echo $tile | xt | mercantile shapes | jq -r '"\(.bbox[0]) \(.bbox[3]) \(.bbox[2]) \(.bbox[1])"')
    zoom=$(echo $tile | cut -d'-' -f1)
    echo "Read mercator tile zoom=$zoom"
    nbytes=$(gdal_translate -q -projwin $bounds -projwin_srs EPSG:4326 -outsize $tile_size $tile_size $file /tmp/out.tif 2>&1 >/dev/null | grep "Content-Length:" | awk '{print $3}' | awk '{n += $1}; END {print n}')
    nget=$(gdal_translate -q -projwin $bounds -projwin_srs EPSG:4326 -outsize $tile_size $tile_size $file /tmp/out.tif 2>&1 >/dev/null | grep "> GET" | wc -l)
    echo "Bytes transfered: "$nbytes
    echo "Nb Http calls: "$nget
    echo "------"
    echo
    ############################################################################
    echo "Read internal tile"
    nbytes=$(gdal_translate -q -srcwin 0 0 256 256 -outsize $tile_size $tile_size $file /tmp/out.tif 2>&1 >/dev/null | grep "Content-Length:" | awk '{print $3}' | awk '{n += $1}; END {print n}')
    nget=$(gdal_translate -q -srcwin 0 0 256 256 -outsize $tile_size $tile_size $file /tmp/out.tif 2>&1 >/dev/null | grep "> GET" | wc -l)
    echo "Bytes transfered: "$nbytes
    echo "Nb Http calls: "$nget
    echo
    exit 0
}

[ "$0" = "$BASH_SOURCE" ] && run "$@"
