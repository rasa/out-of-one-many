# Out of one, many (ex uno, plures) [![Flattr this][4]][3]

Out-of-one-many (ooom) moves directories to different partitions, via a single fstab-like configuration file.

## Quick Start

For example, with an `ooom.fstab` file containing:

````bash
/dev/sdb1 /boot ext2 ro
/dev/sdc1 none swap sw 0 0
/dev/sdd1 /home
/dev/sde1 /var
/dev/sdf1 /tmp
/dev/sdg1 /mnt/sdg xfs rw,noatime
````

Ooom will partition, and format the new disks (`/dev/sdb`-`/dev/sdg`), and then copy the following directories:

````bash
/boot      to /dev/sdb1 (formatted as ext2)
/home      to /dev/sdd1
/var       to /dev/sde1
/tmp       to /dev/sdf1
````

Ooom will also create swapspace and mount it on `/dev/sdc1`.

Additionally, ooom will partition `/dev/sdg`, and format `/dev/sdg1` as `xfs`, and mount it at `/mnt/sdg` (creating the directory, if it does not exist).

Lastly, ooom will reboot the system, and for each directory that mounts successfully on the new partition,
ooom will delete the original directory, and zero the free space recovered on the partition that `/` is mounted on.
Finally, ooom will shutdown (power off) the system.

## Usage

To download, run:

````bash
$ git clone https://github.com/rasa/out-of-one-many
````

Alternatively, you may download ooom via:

````bash
$ wget https://raw.github.com/rasa/out-of-one-many/master/ooom.run
$ sh ooom.run
````

To install, run:

````bash
$ cd out-of-one-many
$ vi ooom.fstab
$ vi ooom-config.sh # optional
$ ./install.sh
$ sudo shutdown -r now
````

Your system will reboot, and ooom will run automatically, and will shutdown (power off) the system when done.

## Limitations

If the `/boot` directory is not already on a separate partition,
attempting to move the directory to new location will keep your system from booting.
Instead, you'll get a `grub rescue>` prompt.
Hopefully, this issue will be addressed in a future version.

## Dependencies

Ooom depends on the following:

* apt-get (Debian, Ubuntu, Mint, etc.)
* sudo access
* Internet access (only to install packages needed by file systems, that have not previously been installed)
* parted
* perl
* util-linux (provides mkswap)
* wget
* rsync (optional)

Ooom will automatically install any packages needed by a specific file system.

## Supported Filesystems

Ooom has been tested, and works, with the following filesystems:

* btrfs
* exfat: using PPA package [ppa:relan/exfat][]
* ext2
* ext3
* ext4
* jfs
* ntfs
* swap
* vfat
* xfs

Ooom does not yet work with the following file systems:

* reiser4: Linux 3.8.0-26-generic is detected. Reiser4 does not support such a platform.
* zfs: Untested

## Links

  * [Makeself][] was used to create the self extracting ooom.run file.

## Contributing

To contribute to this project, please see [CONTRIBUTING.md](CONTRIBUTING.md).

## Bugs

To view existing bugs, or report a new bug, please see [issues](../../issues).

## Changelog

To view the version history for this project, please see [CHANGELOG.md](CHANGELOG.md).

## License

This project is [MIT licensed](LICENSE).

## Contact

This project was created and is maintained by [Ross Smith II][] [![endorse][endorse_png]][endorse]

Feedback, suggestions, and enhancements are welcome.

[Ross Smith II]: mailto:ross@smithii.com "ross@smithii.com"
[flatter]: https://flattr.com/submit/auto?user_id=rasa&url=https%3A%2F%2Fgithub.com%2Frasa%2Fout-of-one-many
[flatter_png]: http://button.flattr.com/flattr-badge-large.png "Flattr this"
[endorse]: https://coderwall.com/rasa
[endorse_png]: https://api.coderwall.com/rasa/endorsecount.png "endorse"


[Makeself]: http://github.com/megastep/makeself
[ppa:relan/exfat]: https://launchpad.net/~relan/+related-packages
