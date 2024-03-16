# xtrabackup build

This repo builds xtrabackup-8.0 for arm64 machine. It's used by
ddev/mysql-arm64-images and [ddev](https://github.com/ddev/ddev).

Current version: `8.0.35-30`

To build,

* Lookup the latest version at <https://www.percona.com/software/mysql-database/percona-xtrabackup>
* Change the version above and commit and push it. This extra commit is essential, because otherwise the tag won't be unique.
* Create a release with the desired tag, for example `8.0.35-30`. It will build
  and push the arm64 version to the release.

## Problems

The xtrabackup build doesn't seem to be well-maintained, so there are
complexities that seem to change ever time.

* See [build instructions](https://www.percona.com/doc/percona-xtrabackup/8.0/installation/compiling_xtrabackup.html).
* It requires [boost](https://www.boost.org/) and says it prefers to download,
  but that doesn't work in 8.0.27-19 - it downloads a version... but then tries
  to untar a different file. In 8.0.27-19 I added a bogus symlink from the file
  they download to the file they want, so tar can work (they use the right tar
  command but wrong file). More info about [boost build](https://dev.mysql.com/doc/mysql-sourcebuild-excerpt/8.0/en/source-configuration-options.html#option_cmake_with_boost)
  in the *mysql* build instructions.
