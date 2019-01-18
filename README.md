# AWS PDS benchmarking

```
$ git clone http://github.com/vincentsarago/awspds-benchmark

# Test with free/open source drivers
$ test-pds-open

# Test with proprietary drivers (KDU, ECW)
$ make test-pds-evil
```


## COG and GET calls

If a dataset has internal tiling has defined in COG specs it means we do partial reading of the dataset and just get the part of the data we need. In theory when reading a file over THE internet you'll need at least 2 GET calls (range requests):
1. Get the metadata (GDAL fetch the first 16kb of the dataset)
2. Get tile data (one GET per internal tile)

You can have additional GET calls:
- if you try to read a part covered by more than one internal tile
- if you have external overviews (e.g Landsat-8)
- if you have an internal mask
- if your file is not a COG (e.g sentinel-2)


## Benchmark

For this tests we performed partial reading of Landsat, CBERS and Sentinel-2 dataset for:
- mercator tile at zoom 12
- mercator tile at zoom 10
- first internal tile (reading the top left 256x256px) - `Bytes transfered` results are not relevant because of the different internal tile sizes for datasets

We also tested 3 drivers to read Sentinel-2 Jpeg2000 dataset:
- JP2OpenJPEG (defualt with gdal 2.3)
- JP2KAK 💰
- JP2ECW 💰


pds | CBERS | LANDSAT | S2 (JP2OpenJPEG) | S2 (JP2KAK) | S2 (JP2ECW)
--- | --- | ---    | ---              | ---         | ---        
**HTTP call** (Z12) | 5 | 5 | 118 | 64 | 115
**Bytes transfered** (Z12) | 53 035 | 1 722 986 | 3 920 804 | 1 310 720 | 2 741 156
| | | | |
**HTTP call** (Z10) | 6 | 5 | 128 | 74 | 121
**Bytes transfered** (Z10) | 57 992 | 934 156 | 14 390 180 | 1 196 032 | 2 053 028
| | | | |
**HTTP call** (tile) | 3 | 3 | 113 | 13 | 105
**Bytes transfered** (tile) | 49 236 | 16 915 | 1 889 188 | 16 384 | 1 725 348

## Details

#### CBERS Dataset

Info:

```bash
$ gdalinfo /vsis3/remotepixel-pub/cbers/CBERS_4_MUX_20160416_217_063_L2_BAND5.tif
Driver: GTiff/GeoTIFF
Files: /vsis3/remotepixel-pub/cbers/CBERS_4_MUX_20160416_217_063_L2_BAND5.tif
Size is 7407, 7125
Coordinate System is:
PROJCS["WGS 84 / UTM zone 15N",
    GEOGCS["WGS 84",
        DATUM["WGS_1984",
            SPHEROID["WGS 84",6378137,298.257223563,
                AUTHORITY["EPSG","7030"]],
            AUTHORITY["EPSG","6326"]],
        PRIMEM["Greenwich",0,
            AUTHORITY["EPSG","8901"]],
        UNIT["degree",0.0174532925199433,
            AUTHORITY["EPSG","9122"]],
        AUTHORITY["EPSG","4326"]],
    PROJECTION["Transverse_Mercator"],
    PARAMETER["latitude_of_origin",0],
    PARAMETER["central_meridian",-93],
    PARAMETER["scale_factor",0.9996],
    PARAMETER["false_easting",500000],
    PARAMETER["false_northing",0],
    UNIT["metre",1,
        AUTHORITY["EPSG","9001"]],
    AXIS["Easting",EAST],
    AXIS["Northing",NORTH],
    AUTHORITY["EPSG","32615"]]
Origin = (361320.000000000000000,3731360.000000000000000)
Pixel Size = (20.000000000000000,-20.000000000000000)
Metadata:
  AREA_OR_POINT=Area
  TIFFTAG_COPYRIGHT=INPE
  TIFFTAG_DATETIME=2016:05:23 11:14:38
  TIFFTAG_HOSTCOMPUTER=CP
  TIFFTAG_IMAGEDESCRIPTION=Band 5 Level 2 P217 R063 Acquisition Date 2016-04-16T17:11:02.739899 Elevation 89.516691 Azimuth 10.597063 Gain 2 Integration Time 50.00
  TIFFTAG_RESOLUTIONUNIT=2 (pixels/inch)
  TIFFTAG_SOFTWARE=G2T V6.5.1
  TIFFTAG_XRESOLUTION=300
  TIFFTAG_YRESOLUTION=300
Image Structure Metadata:
  COMPRESSION=DEFLATE
  INTERLEAVE=BAND
Corner Coordinates:
Upper Left  (  361320.000, 3731360.000) ( 94d29'47.89"W, 33d42'47.44"N)
Lower Left  (  361320.000, 3588860.000) ( 94d28'30.12"W, 32d25'41.60"N)
Upper Right (  509460.000, 3731360.000) ( 92d53'52.41"W, 33d43'19.94"N)
Lower Right (  509460.000, 3588860.000) ( 92d53'57.72"W, 32d26'12.55"N)
Center      (  435390.000, 3660110.000) ( 93d41'32.06"W, 33d 4'39.59"N)
Band 1 Block=256x256 Type=Byte, ColorInterp=Gray
  NoData Value=0
  Overviews: 3704x3563, 1852x1782, 926x891, 463x446
```

Results:

```bash
$ ./main.sh s3://${bucket}/cbers/CBERS_4_MUX_20160416_217_063_L2_BAND5.tif 12-981-1648
Read mercator tile zoom=12
Bytes transfered: 53 035
Nb Http calls: 5
------
Read mercator tile zoom=10
Bytes transfered: 57 992
Nb Http calls: 6
------

Read internal tile
Bytes transfered: 49 236
Nb Http calls: 3
```

#### L8 Dataset

Info:
```bash
$ CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".TIF,.ovr" GDAL_DISABLE_READDIR_ON_OPEN=FALSE gdalinfo /vsis3/remotepixel-pub/l8/LC80080682015340LGN00_B3.TIF
Driver: GTiff/GeoTIFF
Files: /vsis3/remotepixel-pub/l8/LC80080682015340LGN00_B3.TIF
       /vsis3/remotepixel-pub/l8/LC80080682015340LGN00_B3.TIF.ovr
Size is 7571, 7721
Coordinate System is:
PROJCS["WGS 84 / UTM zone 18N",
    GEOGCS["WGS 84",
        DATUM["WGS_1984",
            SPHEROID["WGS 84",6378137,298.257223563,
                AUTHORITY["EPSG","7030"]],
            AUTHORITY["EPSG","6326"]],
        PRIMEM["Greenwich",0,
            AUTHORITY["EPSG","8901"]],
        UNIT["degree",0.0174532925199433,
            AUTHORITY["EPSG","9122"]],
        AUTHORITY["EPSG","4326"]],
    PROJECTION["Transverse_Mercator"],
    PARAMETER["latitude_of_origin",0],
    PARAMETER["central_meridian",-75],
    PARAMETER["scale_factor",0.9996],
    PARAMETER["false_easting",500000],
    PARAMETER["false_northing",0],
    UNIT["metre",1,
        AUTHORITY["EPSG","9001"]],
    AXIS["Easting",EAST],
    AXIS["Northing",NORTH],
    AUTHORITY["EPSG","32618"]]
Origin = (73485.000000000000000,-1164885.000000000000000)
Pixel Size = (30.000000000000000,-30.000000000000000)
Metadata:
  AREA_OR_POINT=Point
Image Structure Metadata:
  COMPRESSION=DEFLATE
  INTERLEAVE=BAND
Corner Coordinates:
Upper Left  (   73485.000,-1164885.000) ( 78d53'42.64"W, 10d30'50.19"S)
Lower Left  (   73485.000,-1396515.000) ( 78d55'27.14"W, 12d36'13.75"S)
Upper Right (  300615.000,-1164885.000) ( 76d49'19.34"W, 10d31'57.55"S)
Lower Right (  300615.000,-1396515.000) ( 76d50' 8.34"W, 12d37'34.89"S)
Center      (  187050.000,-1280700.000) ( 77d52' 9.30"W, 11d34'15.95"S)
Band 1 Block=512x512 Type=UInt16, ColorInterp=Gray
  Overviews: 2524x2574, 842x858, 281x286, 94x96
```

Results:
```bash
$ CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".TIF,.ovr" GDAL_DISABLE_READDIR_ON_OPEN=FALSE ./main.sh s3://${bucket}/l8/LC80080682015340LGN00_B3.TIF 12-1161-2181
Read mercator tile zoom=12
Bytes transfered: 1 722 986
Nb Http calls: 5
------
Read mercator tile zoom=10
Bytes transfered: 934 156
Nb Http calls: 5
------

Read internal tile
Bytes transfered: 16 915
Nb Http calls: 3
```

#### Sentinel-2 Dataset

Info:

```bash
$ gdalinfo /vsis3/remotepixel-pub/s2/S2A_tile_20180904_13UEQ_0.jp2
Driver: JP2OpenJPEG/JPEG-2000 driver based on OpenJPEG library
Files: /vsis3/remotepixel-pub/s2/S2A_tile_20180904_13UEQ_0.jp2
Size is 10980, 10980
Coordinate System is:
PROJCS["WGS 84 / UTM zone 13N",
    GEOGCS["WGS 84",
        DATUM["WGS_1984",
            SPHEROID["WGS 84",6378137,298.257223563,
                AUTHORITY["EPSG","7030"]],
            AUTHORITY["EPSG","6326"]],
        PRIMEM["Greenwich",0,
            AUTHORITY["EPSG","8901"]],
        UNIT["degree",0.0174532925199433,
            AUTHORITY["EPSG","9122"]],
        AXIS["Latitude",NORTH],
        AXIS["Longitude",EAST],
        AUTHORITY["EPSG","4326"]],
    PROJECTION["Transverse_Mercator"],
    PARAMETER["latitude_of_origin",0],
    PARAMETER["central_meridian",-105],
    PARAMETER["scale_factor",0.9996],
    PARAMETER["false_easting",500000],
    PARAMETER["false_northing",0],
    UNIT["metre",1,
        AUTHORITY["EPSG","9001"]],
    AXIS["Easting",EAST],
    AXIS["Northing",NORTH],
    AUTHORITY["EPSG","32613"]]
Origin = (499980.000000000000000,5500020.000000000000000)
Pixel Size = (10.000000000000000,-10.000000000000000)
Corner Coordinates:
Upper Left  (  499980.000, 5500020.000) (105d 0' 1.00"W, 49d39' 9.80"N)
Lower Left  (  499980.000, 5390220.000) (105d 0' 0.98"W, 48d39'54.11"N)
Upper Right (  609780.000, 5500020.000) (103d28'45.86"W, 49d38'33.85"N)
Lower Right (  609780.000, 5390220.000) (103d30'33.59"W, 48d39'19.39"N)
Center      (  554880.000, 5445120.000) (104d14'50.35"W, 49d 9'23.20"N)
Band 1 Block=1024x1024 Type=UInt16, ColorInterp=Gray
  Overviews: 5490x5490, 2745x2745, 1372x1372, 686x686
  Overviews: arbitrary
  Image Structure Metadata:
    COMPRESSION=JPEG2000
    NBITS=15
```

Results:

###### JP2OpenJPEG
```bash
$ ./main.sh s3://${bucket}/s2/S2A_tile_20180904_13UEQ_0.jp2 12-862-1402
Read mercator tile zoom=12
Bytes transfered: 3 920 804
Nb Http calls: 118
------
Read mercator tile zoom=10
Bytes transfered: 14 390 180
Nb Http calls: 128
------

Read internal tile
Bytes transfered: 1 889 188
Nb Http calls: 113
```

###### JP2KAK
```bash
$ ./main.sh s3://${bucket}/s2/S2A_tile_20180904_13UEQ_0.jp2 12-862-1402
Read mercator tile zoom=12
Bytes transfered: 1 310 720
Nb Http calls: 64
------
Read mercator tile zoom=10
Bytes transfered: 1 196 032
Nb Http calls: 74
------

Read internal tile
Bytes transfered: 16 384
Nb Http calls: 13
```

###### JP2ECW
```bash
$ GDAL_SKIP="JP2KAK" ./main.sh s3://${bucket}/s2/S2A_tile_20180904_13UEQ_0.jp2 12-862-1402
Read mercator tile zoom=12
Bytes transfered: 2 741 156
Nb Http calls: 115
------
Read mercator tile zoom=10
Bytes transfered: 2 053 028
Nb Http calls: 121
------

Read internal tile
Bytes transfered: 1 725 348
Nb Http calls: 105
```

## What about COGs

pds | CBERS | LANDSAT | S2
--- | ---   | ---  | ---      
**HTTP call** (COG) | 5 | 5 | 3
**Bytes transfered** (COG) | 34 527 | 706 810 | 801 176
| | |
**HTTP call** (WEB) | 3 | 3 | 3
**Bytes transfered** (WEB) | 18 733 | 513 583 | 412 451


We created COG using [rio-cogeo](https://github.com/mapbox/rio-cogeo)

e.g.
`rio cogeo LC80080682015340LGN00_B3.TIF LC80080682015340LGN00_B3_cog.tif --cog-profile deflate --nodata 0 --overview-level 4 --co "PREDICTOR=2" --co "ZLEVEL=9"`

```bash

$ ./main.sh s3://${bucket}/cog/CBERS_4_MUX_20160416_217_063_L2_BAND5_cog.tif 12-981-1648
Read mercator tile zoom=12
Bytes transfered: 34 527
Nb Http calls: 5

$ ./main.sh s3://${bucket}/cog/LC80080682015340LGN00_B3_cog.tif 12-1161-2181
Read mercator tile zoom=12
Bytes transfered: 1 706 810
Nb Http calls: 5

$ ./main.sh s3://${bucket}/cog/S2A_tile_20180904_13UEQ_0_cog.tif 12-862-1402
Read mercator tile zoom=12
Bytes transfered: 801 176
Nb Http calls: 3
```

#### Web-Optimized COG ?

Using https://github.com/mapbox/rio-cogeo/pull/22 we can also create COG aligned with web-mercator grid which should reduce the number off http calls and data transfer

```
$ ./main.sh s3://${bucket}/cog/CBERS_4_MUX_20160416_217_063_L2_BAND5_web.tif 12-981-1648
Read mercator tile zoom=12
Bytes transfered: 18 733
Nb Http calls: 3

$ ./main.sh s3://${bucket}/cog/LC80080682015340LGN00_B3_web.tif 12-1161-2181
Read mercator tile zoom=12
Bytes transfered: 513 583
Nb Http calls: 3

$ ./main.sh s3://${bucket}/cog/S2A_tile_20180904_13UEQ_0_web.tif 12-862-1402
Read mercator tile zoom=12
Bytes transfered: 412 451
Nb Http calls: 3
```

Note:
- Rio-cogeo has no option to copy nodata value from input to output, but creates an internal mask.
- Internal mask, require one additional GET call (per tile) because mask are stored at the end of the GeoTIFF structure. This should be fix in near future.
- COG/Raw sizes:
```
  10M CBERS_4_MUX_20160416_217_063_L2_BAND5.tif
 8.9M CBERS_4_MUX_20160416_217_063_L2_BAND5_cog.tif

  65M LC80080682015340LGN00_B3.TIF
 8.6M LC80080682015340LGN00_B3.TIF.ovr
  88M LC80080682015340LGN00_B3_cog.tif

  95M S2A_tile_20180904_13UEQ_0.jp2
 180M S2A_tile_20180904_13UEQ_0_cog.tif

 # Web optimized files are lighter because of resolution difference (closest mercator zoom level)
 3.9M CBERS_4_MUX_20160416_217_063_L2_BAND5_web.tif
 64M LC80080682015340LGN00_B3_web.tif
 116M S2A_tile_20180904_13UEQ_0_web.tif
```
