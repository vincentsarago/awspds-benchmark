FROM remotepixel/amazonlinux-gdal:master

RUN pip3 install cython numpy --no-binary numpy
RUN pip3 install rasterio --no-binary rasterio

RUN pip3 install rio-tiler~=1.0rc2 mercantile xt

RUN yum install -y jq

ENV PATH=/tmp/app/local/bin:$PATH
