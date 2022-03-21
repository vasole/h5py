#!/bin/bash

set -e

if [ -z ${HDF5_DIR+x} ]; then
    echo "Using OS HDF5"
else
    echo "Using downloaded HDF5"
    if [ -z ${HDF5_MPI+x} ]; then
        echo "Building serial"
        EXTRA_MPI_FLAGS=''
    else
        echo "Building with MPI"
        EXTRA_MPI_FLAGS="--enable-parallel --enable-shared"
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        lib_name=libhdf5.dylib
    else
        lib_name=libhdf5.so
        # Test with the direct file driver on Linux. This setting does not
        # affect the HDF5 bundled in Linux wheels - that is built into a Docker
        # image from a separate repository.
        ENABLE_DIRECT_VFD="--enable-direct-vfd"
    fi
    if [[ "${HDF5_VERSION%.*}" = "1.12" ]]; then
        ENABLE_BUILD_MODE="--enable-build-mode=production"
    fi
    if [ -f $HDF5_DIR/lib/$lib_name ]; then
        echo "using cached build"
    else
        pushd /tmp
        #                                   Remove trailing .*, to get e.g. '1.12' ↓
        curl -fsSLO "https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION%.*}/hdf5-$HDF5_VERSION/src/hdf5-$HDF5_VERSION.tar.gz"
        tar -xzvf hdf5-$HDF5_VERSION.tar.gz
        pushd hdf5-$HDF5_VERSION
        chmod u+x autogen.sh
        ./configure --prefix $HDF5_DIR \
            --enable-tests=no \
            ${EXTRA_MPI_FLAGS} \
            ${ENABLE_DIRECT_VFD} \
            ${ENABLE_BUILD_MODE}
        make -j $(nproc)
        make install
        popd
        popd
    fi
fi