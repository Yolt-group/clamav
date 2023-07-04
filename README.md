# ClamAV Docker Image

This image wraps ClamAV daemon. The daemon listens on port 3310 where it receives commands and data to scan. Thus when running the container, this port needs to be mapped.

## Building
`docker build --no-cache -t registry.yolt.io/clamav:latest .`

Note `--no-cache`. If not specified, the latest software and signature files might not be downloaded (i.e. cached content would be used to build the image).

## Running Locally
`docker run -d -p 3310:3310 --rm --name clamav registry.yolt.io/clamav:latest`

#### Stopping and Removing
`if docker ps | grep -w clamav; then docker stop clamav; fi`

`if docker ps -f "status=exited" | grep -w clamav; then docker rm clamav; fi`

## Testing Locally
The image contains two files with Eicar signature. One file is plain and the other one is a ZIP file. The test script should detect the malware in both files.

`./test/test-docker-image.sh`

## Testing in GitLab CI
The image contains a shell script `self-test.sh` that starts ClamAV daemon and runs the tests. When doing a smoke test in GitLab CI, this script can be invoked as follows:

`docker run --rm --entrypoint "/self-test.sh" --name ${CONTAINER_NAME} ${IMAGE_NAME}`

It returns `1` when test signatures not detected (and other error conditions), which fails the build job.

## Known Issues

The ClamAV versions on `yam` (used in Dockerfile) might be outdated. Therefore manual updates might be needed.
