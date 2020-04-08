# GNU Toolchain for Docker

Docker image with some of the GNU toolchain tools.

## Synopsis

This script will create a Docker image with some of the GNU toolchain tools
and libraries like:

- Autoconf
- Automake
- Binutils
- Bison
- C Library (glibc)
- Gettext
- GCC
- Libtool
- M4
- Make
- Ncurses
- Patch

The Docker image resulting from this script can either be used to run any of
those tools or as a "source" to include those tools on another Docker image.

## Getting Started

There are a couple of things needed for the script to work.

### Prerequisites

Docker, either the Community Edition (CE) or Enterprise Edition (EE), needs to
be installed on your local computer.

#### Docker

Docker installation instructions can be found
[here](https://docs.docker.com/install/).

### Usage

In order to create a Docker image using this Dockerfile you need to run the
`docker` command with a few options.

```
docker image build --force-rm --no-cache --quiet --tag <USER>/<IMAGE>:<TAG> <PATH>
```

* `<USER>` - *[required]* The user that will own the container image (e.g.: "johndoe").
* `<IMAGE>` - *[required]* The container name (e.g.: "unbound").
* `<TAG>` - *[required]* The container tag (e.g.: "latest").
* `<PATH>` - *[required]* The location of the Dockerfile folder.

A build example:

```
docker image build --force-rm --no-cache --quiet --tag johndoe/my_toolchain:latest .
```

To clean any _<none>_ image(s) left by the build process the following
command can be used:

```
docker image rm `docker image ls --filter "dangling=true" --quiet`
```

You can also use the following command to achieve the same result:

```
docker image prune -f
```

#### Instantiate a Container

The toolchain can be used directly from the image by instantiating a container
and executing the desired tool(s) on the container shell.

To start a container with this image - and have a shell - use the following
command (the container will be deleted after exiting the shell):

```
docker container run --rm --interactive --tty fscm/toolchain sh
```

This will allow you to run any of the tools inside the this image. To take the
most out of this method you can add you project code to the running container
by defining your project folder as a working folder inside the container.

To start a container with this image and your project folder available inside
use the following command:

```
docker container run --volume LOCAL_PROJECT_PATH:/work:rw --rm --interactive --tty fscm/toolchain sh
```

#### Copy the Toolchain

The toolchain can also be used with your favorite image. The toolchain can be
copied over to another image when using a `Dockerfile`.
To use the toolchain in another image when building your own image use the
following code in your `Dockerfile`:

```
ENV PATH="/usr/local/toolchain/bin:${PATH}"
COPY --from=fscm/toolchain "/usr/local/toolchain" "/usr/local/"
```

An example of a `Dockerfile` that copies the toolchain:

```
FROM fscm/centos

ENV PATH="/usr/local/toolchain/bin:${PATH}"

COPY --from=fscm/toolchain "/usr/local/toolchain" "/usr/local/toolchain"

RUN gcc --version
```

### Add Tags to the Docker Image

Additional tags can be added to the image using the following command:

```
docker image tag <image_id> <user>/<image>:<extra_tag>
```

### Push the image to Docker Hub

After adding an image to Docker, that image can be pushed to a Docker
registry... Like Docker Hub.

Make sure that you are logged in to the service.

```
docker login
```

When logged in, an image can be pushed using the following command:

```
docker image push <user>/<image>:<tag>
```

Extra tags can also be pushed.

```
docker image push <user>/<image>:<extra_tag>
```

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request

Please read the [CONTRIBUTING.md](CONTRIBUTING.md) file for more details on how
to contribute to this project.

## Versioning

This project uses [SemVer](http://semver.org/) for versioning. For the versions
available, see the [tags on this repository](https://github.com/fscm/docker-toolchain/tags).

## Authors

* **Frederico Martins** - [fscm](https://github.com/fscm)

See also the list of [contributors](https://github.com/fscm/docker-toolchain/contributors)
who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE)
file for details

## Credits

Based on the following projects:
* [Linux From Scratch (LFS)](http://linuxfromscratch.org)
* [Linuxbrew Core](https://github.com/Homebrew/linuxbrew-core)
