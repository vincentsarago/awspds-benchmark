
SHELL = /bin/bash

################################################################################
# BUILD
build:
	docker build -f Dockerfiles/Dockerfile --tag img:latest .

build-evil:
	docker build -f Dockerfiles/DockerfileEvil --tag img:latest .

################################################################################
# DEBUG
shell: build
	docker run --name bench  \
		--volume $(shell pwd)/scripts:/scripts \
		--env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		--env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		--env AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
		--env AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
		--env AWS_DEFAULT_REGION=us-east-1 \
		--env GDAL_DISABLE_READDIR_ON_OPEN=EMPTY_DIR \
		--env VSI_CACHE=FALSE \
		--env VSI_CACHE_SIZE=0 \
		--rm -it img:latest /bin/bash


shell-evil: build-evil
	docker run --name bench  \
		-w /scripts/ \
		--volume $(shell pwd)/scripts:/scripts \
		--env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		--env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		--env AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
		--env AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
		--env AWS_DEFAULT_REGION=us-west-2 \
		--env GDAL_DISABLE_READDIR_ON_OPEN=EMPTY_DIR \
		--env VSI_CACHE=FALSE \
		--env VSI_CACHE_SIZE=0 \
		--rm -it img:latest /bin/bash

################################################################################
run:
	docker run -w /scripts/ \
		--name bench \
		--volume $(shell pwd)/scripts:/scripts \
		--env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
		--env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
		--env AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
		--env AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
		--env AWS_DEFAULT_REGION=us-west-2 \
		--env GDAL_DISABLE_READDIR_ON_OPEN=EMPTY_DIR \
		--env VSI_CACHE=FALSE \
		--env VSI_CACHE_SIZE=0 \
		--env GDAL_CACHEMAX=0 \
		--env CPL_CURL_VERBOSE=YES \
		-itd img:latest /bin/bash

bucket=remotepixel-pub

test-pds-open: build run
	docker exec -it bench bash -c './main.sh s3://${bucket}/cbers/CBERS_4_MUX_20160416_217_063_L2_BAND5.tif 12-981-1648'
	docker exec -it bench bash -c 'CPL_VSIL_CURL_ALLOWED_EXTENSIONS=".TIF,.ovr" GDAL_DISABLE_READDIR_ON_OPEN=FALSE ./main.sh s3://${bucket}/l8/LC80080682015340LGN00_B3.TIF 12-1161-2181'
	docker exec -it bench bash -c 'echo "JP2OpenJPEG" && ./main.sh s3://${bucket}/s2/S2A_tile_20180904_13UEQ_0.jp2 12-862-1402'
	docker stop bench
	docker rm bench

# Use evil drivers
test-pds-evil: build-evil run
	docker exec -it bench bash -c 'echo "JP2KAK" && ./main.sh s3://${bucket}/s2/S2A_tile_20180904_13UEQ_0.jp2 12-862-1402'
	docker exec -it bench bash -c 'echo "JP2ECW" && GDAL_SKIP="JP2KAK" ./main.sh s3://${bucket}/s2/S2A_tile_20180904_13UEQ_0.jp2 12-862-1402'
	docker stop bench
	docker rm bench

################################################################################
test-cog: build run
	docker exec -it bench bash -c './main.sh s3://${bucket}/cog/CBERS_4_MUX_20160416_217_063_L2_BAND5_cog.tif 12-981-1648'
	docker exec -it bench bash -c './main.sh s3://${bucket}/cog/LC80080682015340LGN00_B3_cog.tif 12-1161-2181'
	docker exec -it bench bash -c './main.sh s3://${bucket}/cog/S2A_tile_20180904_13UEQ_0_cog.tif 12-862-1402'
	docker stop bench
	docker rm bench

test-web: build run
	docker exec -it bench bash -c './main.sh s3://${bucket}/cog/CBERS_4_MUX_20160416_217_063_L2_BAND5_web.tif 12-981-1648'
	docker exec -it bench bash -c './main.sh s3://${bucket}/cog/LC80080682015340LGN00_B3_web.tif 12-1161-2181'
	docker exec -it bench bash -c './main.sh s3://${bucket}/cog/S2A_tile_20180904_13UEQ_0_web.tif 12-862-1402'
	docker stop bench
	docker rm bench

################################################################################
clean:
	docker stop bench
	docker rm bench
