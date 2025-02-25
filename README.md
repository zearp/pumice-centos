# Pumice CentOS Stream 10

See the main repo for more informaton and background [here](https://github.com/zearp/pumice-fedora).

## Quick build instructions

### Getting ready
```
sudo dnf install -y podman git
sudo setenforce permissive
```
### Clone the repo and edit/check default packages/files
```
git clone https://github.com/zearp/pumice-centos && cd pumice-centos
sudo nano config.xml && ls -lha root/
```

### Entering container
```
sudo podman run --privileged --rm -it --network=host -v /dev:/dev -v $PWD:/code:z -w /code quay.io/centos/centos:stream10 /bin/bash
```

### Download and set workers
```
rpm -i https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
dnf -y install epel-release && dnf -y install kiwi policycoreutils dosfstools erofs-utils isomd5sum qemu-img xorriso nano && dnf -y --refresh update
sed -i "s/NPROC_PLACEHOLDER/$(nproc)/" config.xml
```

### Build the iso and deduplicate iso files
```
kiwi-ng --type=iso --profile="Pumice" --color-output system build --description="." --target-dir ./build-tmp && kiwi-ng result bundle --target-dir ./build-tmp --bundle-dir ./outdir --id build
rm -rf ./build-tmp
```
If you want to build another delete the output folder with ```rm -rf output``` and don't exit here. Then make config or file changes in another shell for faster rebuilds. If you are don't just exit the container with the ```exit``` command. To rebuild just run the ```kiwi-ng``` commands again.

### Final clean up
```
sudo rm -rf /replace/with/path/to/pumice-centos
sudo podman system prune --all --volumes --force
```
