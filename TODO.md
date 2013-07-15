todo list
=========

* Move from
<pre>
/dev/sdd /home
</pre>
to
<pre>
/dev/sdd1 /home
</pre>
to be more in keeping with `/etc/fstab`.
Then, if `/dev/sdd1` doesn't exist, but `/dev/sdd` does, then
automatically partition `/dev/sdd`.

* Test other file systems: jfs, reiser, zfs, exfat, ntfs, etc.

* Add shorthand install method:
<pre>
wget -O - http://goo.gl/lsdjf | sh
</pre>