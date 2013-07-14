Out of one, many (ex uno, plures)
==========

Move and mount directories to different disks.

## Usage

To download, run:

<pre>
$ apt-get install -y git
$ git clone git@github.com:rasa/ooom.git
</pre>

Alternatively, you may download ooom via:

<pre>
wget -O - https://raw.github.com/rasa/out-of-one-many/master/ooom.run | sh
</pre>

To install, run:

<pre>
$ cd ooom
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
