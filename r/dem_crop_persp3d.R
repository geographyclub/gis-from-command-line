library("cptcity")
library("plot3Drgl")
library("raster")
library("rpostgis")
library("sf")

# import
countries <- st_read('/home/steve/maps/naturalearth/packages/natural_earth_vector.gpkg', layer='ne_10m_admin_0_countries', promote_to_multi=TRUE)
dem <- raster('/home/steve/maps/srtm/topo15_4320.tif')
dem <- setMinMax(dem)

# mask
mask <- countries[countries$NAME == "Brazil",]
#dem <- mask(dem, mask)
dem <- crop(dem, mask)

# resample
#nx=400; ny=400
#dem <- resample(dem, raster(dem@extent, nrow=nx/2, ncol=ny/2), method='bilinear')
#dem <- resample(dem, raster(dem@extent, nrow=nx, ncol=ny), method='ngb')
# to vector
#x <- seq(dem@extent@xmin, dem@extent@xmax, length.out=dem@nrows)
#y <- seq(dem@extent@ymin, dem@extent@ymax, length.out=dem@ncols)
#z <- matrix(dem, nrow=dem@nrows, ncol=dem@ncols, byrow=TRUE)

# to grid
n=50
x <- seq(dem@extent@xmin, dem@extent@xmax, length.out=n)
y <- seq(dem@extent@ymin, dem@extent@ymax, length.out=n)
z <- st_sf(st_make_grid(dem, n=n, what="centers"))
z <- matrix(extract(dem, z), nrow=n, ncol=n)

# colors
col <- colorRampPalette(cpt(n=100, pal='ncl_topo_15lev'))

# plot
r3dDefaults$windowRect <- c(50,50, 700, 700)
expand = 0.005
resfac = 1

#file = paste("topo_brazil_persp3d_", system('date +%Y%m%d%H%M%S', intern=TRUE) ,".png", sep="")
#png(file, bg='transparent')
persp3D(x, y, z, bty='n', colkey=FALSE, resfac=resfac, expand=expand, scale=FALSE, facets=FALSE, curtain=FALSE, lighting=TRUE, smooth=FALSE, inttype=2, breaks=NULL, colvar=z, NAcol=NA, col=col(100), border='black', lwd=0.1, alpha=1, shade=1, lphi=0, ltheta=0, add=FALSE, plot=TRUE)
plotdev(theta=-20, phi=70)
#dev.off()
