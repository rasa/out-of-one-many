Out of one, many (ex uno, plures)
=================================

Out-of-one-many (ooom) moves directories to different partitions, via a single fstab-like configuration file.

For example, with an `ooom.fstab` file containing:

<pre>
/dev/sdb1 /boot ext2 ro
/dev/sdc1 none swap sw 0 0
/dev/sdd1 /home
/dev/sde1 /var
/dev/sdf1 /tmp
/dev/sdg1 /mnt/sdg xfs rw,noatime
</pre>

Ooom will partition, and format the new disks (`/dev/sdb`-`/dev/sdg`), and then copy the following directories:

<pre>
/boot      to /dev/sdb1 (formatted as ext2)
/home      to /dev/sdd1
/usr/local to /dev/sde1
/var       to /dev/sdf1
/tmp       to /dev/sdg1
</pre>

Ooom will also create swapspace and mount it on `/dev/sdc1`.

Additionally, it will partition `/dev/sdg`, and format `/dev/sdg1` as `xfs`, and mount it at `/mnt/sdg` (creating the directory, if it does not exist).

Lastly, it will reboot the system, and for each directory that mounts successfully on the new partition,
it will delete the original directory, and zero the free space recovered on the partition that `/` is mounted on.
Finally, it will shutdown (power off) the system.

## Usage

To download, run:

<pre>
$ git clone git@github.com:rasa/out-of-one-many.git
</pre>

Alternatively, you may download ooom via:

<pre>
$ wget https://raw.github.com/rasa/out-of-one-many/master/ooom.run
$ sh ./ooom.run
</pre>

or the equivalent, but shorter:

<pre>
$ wget -O - http://goo.gl/qse72 | sh
</pre>

To install, run:

<pre>
$ cd out-of-one-many
$ vi ooom.fstab
$ vi ooom-config.sh # optional
$ sudo ./install.sh
$ sudo shutdown -r now
</pre>

Your system will reboot, and ooom will run automatically, and will shutwon (power off) the system when done.

## Limitations

If the `/boot` directory is not already on a separate partition,
attempting to move the folder to new parition will keep your system from booting.
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

Ooom works with the following filesystems:

  * btrfs
  * exfat: using PPA package ppa:relan/exfat
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

## Automated testing

To download and automatically run ooom, with the default `ooom.fstab, run:

<pre>
$ wget -O - http://goo.gl/9sZgS | sh
</pre>

## License

Ooom is covered by the [The MIT License][1]

## Download

Get the latest official distribution [here][2] (version 0.1).

The latest development version can be grabbed from [GitHub][2]. Feel free to
submit any patches there through the fork and pull request process.

## Version History

  * **v0.1:** Initial public release

## Links

  * [Makeself][3] was used to create the self extracting ooom.run file.

## Contact

This script was written by [Ross Smith II][4] (ross at smithii.com). Any enhancements and suggestions are welcome.

This project is now hosted on GitHub. Feel free to submit patches and bug reports on the [project page][5].

   [1]: http://opensource.org/licenses/MIT
   [2]: https://raw.github.com/rasa/out-of-one-many/master/ooom.run
   [3]: http://github.com/megastep/makeself
   [4]: mailto:ross@smithii.com
   [5]: https://github.com/rasa/out-of-one-many
