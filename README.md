# Nagios Core on Ubuntu 18.04 LTS

Unofficial docker images for Nagios Core based on Ubuntu 18.04

## Supported Nagios Core versions (tags)

- `4.4.5`, `latest`
- `4.4.4`
- `4.4.3`
- `4.4.2`
- `4.4.1`
- `4.4.0`
- `4.3.4`
- `4.3.3`
- `4.3.2`
- `4.3.1`
- `4.3.0`

## Image Variants

### `remie/docker-nagios:<version>`

This is an alias for `remie/docker-nagios:<version>-core-web-plugins`.

### `remie/docker-nagios:<version>-core`

This image contains the most minimal working version of Nagios Core, without example configuration,
Apache integration, web interface and plugins.

You will be required to ensure that the configuration is mounted to `/config` prior to starting
the image.

### `remie/docker-nagios:<version>-core-web`

This image contains Nagios Core, with Apache integration and web interface,
but without the example configuration and plugins.

You will be required to ensure that the configuration is mounted to `/config` prior to starting
the image. In addition, the default Apache configuration expects a `htpasswd.users` file in `/config`.

The image exposes port `80` for the web interface.

### `remie/docker-nagios:<version>-core-web-plugins`

This image contains Nagios Core, with Apache integration, web interface and Nagios Plugins.

You will be required to ensure that the configuration is mounted to `/config` prior to starting
the image. In addition, the default Apache configuration expects a `htpasswd.users` file in `/config`.

The image exposes port `80` for the web interface.

## Volumes

### `/config`

The location of the Nagios configuration files, normally located in `/usr/local/nagios/etc`

### `/data`

The location of the Nagios data files, normally located in `/usr/local/nagios/var`



