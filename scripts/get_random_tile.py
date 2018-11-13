"""cli."""

import math
import click
import random

import rasterio
from rasterio.rio import options
from rasterio.warp import transform_bounds, calculate_default_transform

import mercantile


# From rio_glui.raster
def _meters_per_pixel(zoom, lat):
    return (math.cos(lat * math.pi / 180.0) * 2 * math.pi * 6378137) / (256 * 2 ** zoom)


class RasterObject(object):
    def __init__(self, src_path):
        """Initialize RasterObject object."""
        self.path = src_path
        with rasterio.open(src_path) as src:
            self.bounds = list(
                transform_bounds(
                    *[src.crs, "epsg:4326"] + list(src.bounds), densify_pts=0
                )
            )
            self.crs = src.crs
            self.crs_bounds = src.bounds
            self.meta = src.meta
            self.overiew_levels = src.overviews(1)

    def get_max_zoom(self, snap=0.5, max_z=23):
        """Calculate raster max zoom level."""
        dst_affine, w, h = calculate_default_transform(
            self.crs,
            "epsg:3857",
            self.meta["width"],
            self.meta["height"],
            *self.crs_bounds
        )

        res_max = max(abs(dst_affine[0]), abs(dst_affine[4]))

        tgt_z = max_z
        mpp = 0.0

        # loop through the pyramid to file the closest z level
        for z in range(1, max_z):
            mpp = _meters_per_pixel(z, 0)

            if (mpp - ((mpp / 2) * snap)) < res_max:
                tgt_z = z
                break

        return tgt_z

    def get_min_zoom(self, snap=0.5, max_z=23):
        """Calculate raster min zoom level."""
        dst_affine, w, h = calculate_default_transform(
            self.crs,
            "epsg:3857",
            self.meta["width"],
            self.meta["height"],
            *self.crs_bounds
        )

        res_max = max(abs(dst_affine[0]), abs(dst_affine[4]))
        max_decim = self.overiew_levels[-1]
        resolution = max_decim * res_max

        tgt_z = 0
        mpp = 0.0

        # loop through the pyramid to file the closest z level
        for z in list(range(0, 24))[::-1]:
            mpp = _meters_per_pixel(z, 0)
            tgt_z = z

            if (mpp - ((mpp / 2) * snap)) > resolution:
                break

        return tgt_z


@click.command()
@options.file_in_arg
def main(input):
    """Get random tile bounds."""
    raster = RasterObject(input)
    bounds = raster.bounds

    max_zoom = raster.get_max_zoom()
    min_zoom = raster.get_min_zoom()

    zoom = random.randint(min_zoom, max_zoom)
    tiles = list(mercantile.tiles(*bounds + [[zoom]]))

    nb_tiles = len(tiles)
    tile_number = int(random.random() * nb_tiles)
    tile = tiles[tile_number]
    print("{}-{}-{}".format(tile.z, tile.x, tile.y))


if __name__ == '__main__':
    main()
