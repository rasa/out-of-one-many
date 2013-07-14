Out of one, many (ex uno, plures)
==========

Move directories to different disks.

This script will move one or more directories from one disk to another.

For example, you could move:

/boot      to /dev/sdb (not yet implemented/working)
swap       to /dev/sdc
/home      to /dev/sdd
/usr/local to /dev/sde
/var       to /dev/sdf
/var/log   to /dev/sdg
/tmp       to /dev/sdh

You can define the file system and mount options, as well.

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
$ vi ooom-config.sh
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
