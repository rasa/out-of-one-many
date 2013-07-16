Out of one, many (ex uno, plures)
=================================

Out-of-one-many (ooom) moves one or more directories to different partitions, via a single fstab-like configuration file.

For example, with an `ooom.fstab` file containing:

<pre>
/dev/sdb1 none swap
/dev/sdc1 /home
/dev/sdd1 /usr/local ext2
/dev/sde1 /var
/dev/sdf1 /tmp
/dev/sdg1 /mnt/sdg xfs rw,noatime
</pre>

Ooom will partition, and format the new disks (sdb-sdg), and then copy the following directories:

<pre>
/home      to /dev/sdc1
/usr/local to /dev/sdd1 (formatted as ext2)
/var       to /dev/sde1
/tmp       to /dev/sdf1 (/tmp is created on /dev/sdf1, but the contents are not copied)
</pre>

Ooom will also create swapspace and mount it on `dev/sdb`.

Additionally, it will partition `/dev/sdg`, and format `/dev/sdg1` as `xfs`, and mount it at `/mnt/sdg` (creating the directory, if it does not exist).

Lastly, it will reboot the system, and for each directory that mounts successfully on the new partition,
it will delete the original directory, and zero the free space recovered on the partition that `/` is mounted on.
Finally, it will shutdown (power off) the system.

## Usage

To download, run:

<pre>
$ git clone https://github.com/rasa/out-of-one-many.git
</pre>

Alternatively, you may download ooom via:

<pre>
$ wget https://raw.github.com/rasa/out-of-one-many/master/ooom.run
$ sh ./ooom.run
</pre>

or the equivalent, but shorter:

<pre>
$ wget http://goo.gl/7FEJe | sh
</pre>

To install, run:

<pre>
$ cd out-of-one-many
$ vi ooom.fstab
$ vi ooom-config.sh #optional
$ sudo ./install.sh
$ sudo shutdown -r now
</pre>

Your system will reboot, and ooom will run automatically, and will shutwon (power off) the system when done.

## Dependencies

	* apt-get (Debian, Ubuntu, Mint, etc.)
	* sudo access
	* Internet access (only to install packages needed by file systems)
	* parted
	* perl
	* util-linux (provides mkswap)
	* wget

Ooom will install any packages needed for any specific file system.

## Notes

Tested with the following filesystems:

<pre>
btrfs:   works
exfat:   works
ext2:    works
ext3:    works
ext4:    works
jfs:     works
ntfs:    works
reiser4: fails: Warn : Linux 3.8.0-26-generic is detected. Reiser4 does not support such a platform. Use -f to force over.
swap:    works
vfat:    works
xfs:     works
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

  * Makeself[3] was used to create the self extracting ooom.run file.

## Contact

This script was written by [Ross Smith II][4] (ross at smithii.com). Any enhancements and suggestions are welcome.

This project is now hosted on GitHub. Feel free to submit patches and bug reports on the [project page][5].

   [1]: http://opensource.org/licenses/MIT
   [2]: https://raw.github.com/rasa/out-of-one-many/master/ooom.run
   [3]: http://github.com/megastep/makeself
   [4]: mailto:ross@smithii.com
   [5]: https://github.com/rasa/out-of-one-many
