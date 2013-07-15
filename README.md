Out of one, many (ex uno, plures)
==========

Move directories to different disks.

This script will move one or more directories from one disk to another, via a single `ooom.fstab` configuration file.

For example, a `ooom.fstab` of

/dev/sdb none swap
/dev/sdc1 /home
/dev/sdd1 /usr/local ext2
/dev/sde1 /var
/dev/sdf1 /tmp
/dev/sdg1 /mnt/sdg xfs rw,noatime

Will partition, format, and copy the following directories from `/dev/sda`, to:

<pre>
/home      to /dev/sdc1
/usr/local to /dev/sdd1 (formatted as ext2)
/var       to /dev/sde1
/tmp       to /dev/sdf1
</pre>

It will also create a swapspace on `dev/sdb`.

Additionally, it will partition `/dev/sdg`, and format `dev/sdg1` as `xfs`, and mount it at `/mnt/sdg` (creating it, if it doesn't exist).

Lastly, it will delete the original directories, that were mounted on `/dev/sda`, and zero the free space recovered.

## Usage

To download, run:

<pre>
$ git clone https://github.com/rasa/out-of-one-many.git
</pre>

Alternatively, you may download ooom via:

<pre>
wget https://raw.github.com/rasa/out-of-one-many/master/ooom.run
sh ./ooom.run
</pre>

or the equivalent, but shorter:

<pre>
wget http://goo.gl/7FEJe
sh ./7FEJe
</pre>

To install, run:

<pre>
$ cd out-of-one-many
$ vi ooom.fstab
$ vi ooom-config.sh #optional
$ sudo ./install.sh
$ sudo shutdown -r now
</pre>

Your system will reboot, and ooom will run.

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
