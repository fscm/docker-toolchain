# GNU Toolchain for Docker

An image with some of the GNU toolchain tools and libraries.

## Supported tags

- `0.0.1`, `latest`

## What is a Toolchain?

> In software, a toolchain is a set of programming tools that is used to perform a complex software development task or to create a software product, which is typically another computer program or a set of related programs.

*from* [wikipedia.org](https://en.wikipedia.org/wiki/Toolchain)

## What is included?

The image contains some of the GNU toolchain tools and libraries like:

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

## Getting Started

There are a couple of things needed for the script to work.

### Prerequisites

Docker, either the Community Edition (CE) or Enterprise Edition (EE), needs to
be installed on your local computer.

#### Docker

Docker installation instructions can be found
[here](https://docs.docker.com/install/).

### Usage

The toolchain can be used in two different ways...

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

## Build

Build instructions can be found
[here](https://github.com/fscm/docker-toolchain/blob/master/README.build.md).

## Versioning

This project uses [SemVer](http://semver.org/) for versioning. For the versions
available, see the [tags on this repository](https://github.com/fscm/docker-toolchain/tags).

## Authors

* **Frederico Martins** - [fscm](https://github.com/fscm)

See also the list of [contributors](https://github.com/fscm/docker-toolchain/contributors)
who participated in this project.
