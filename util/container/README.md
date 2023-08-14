# SNAX Docker Test Container
The dockerfile contains the build instructions for the container. It is compatible for cocotb and Verilator. 

## Alternative Docker Download
You can download an uploaded build by running: 
``` bash
docker pull rgantonio/snax-cocotb
```

## Using the Container
Run interactive container:

``` bash
docker run -it -v $REPO_TOP:/repo -w /repo rgantonio/snax-cocotb
```
**Note:** the `$REPO_TOP` is the cloned `snax-dev` top. For example, `$REPO_TOP=$HOME/snax-dev`.

## TODO: Update the source of docker file later. Needs to be in ghcr.io