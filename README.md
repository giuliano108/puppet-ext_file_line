This is a fork of [m4ce/puppet-ext_file_line](https://github.com/m4ce/puppet-ext_file_line).

Compared to the original I've:

- Added tests
- Rewrote the logic while trying to fix an issue where, with `ensure: absent`, the code was telling Puppet it had to make changes even when unnecessary (no matching line). This was causing Puppet to never "converge".
- Added a `match_only_one_run` parameter that causes the resource to be considered up-to-date once `match` stops matching (typically because a replacement already happened on the previous Puppet run).

Run the tests with:

```shell
bundle install
bundle exec rspec
```

### Logic

If `line` is given but no `match`:
- Ensure the line is either present or absent
- Know when the resource needs updating based on the presence/absence of the line

A `match` without `line` can be given only with `ensure => absent`:
- Removes the matching line(s)
- Know when the resource needs updating if `match`, uh, matches

`match` with `line` and `ensure => absent` make no sense. Use either `line` or `match` with `ensure => absent`, but not both.

If a `match` with a `line` and `ensure => present` are given, when a match is found a substitution is performed. `line` is the replacement and can use regex backreferences.

What happens in the above scenario, when the match _isn't_ found? Consider the example below:

``` text
# Contents of test.txt
test line
```

``` puppet
ext_file_line { 'replace the test line':
  ensure   => present,
  path     => 'test.txt',
  match    => '^(test.*|something)$',
  line     => 'something',
}
```

- Puppet run 1: `test line` matches and becomes `something`
- Puppet run 2: `something` matches and becomes `something` => the resource doesn't need updating

This works only because the regex is built to mach both with the "before and after". Without a specially crafted regex Puppet would never converge.

``` puppet
ext_file_line { 'replace the test line':
  ensure   => present,
  path     => 'test.txt',
  match    => '^test.*$',
  line     => 'something',
}
```

- Puppet run 1: `test line` matches and becomes `something`
- Puppet run 2: `something` doesn't match => the resource needs updating but no substitution is performed
- Puppet run n: `something` doesn't match => the resource needs updating but no substitution is performed

The `match_only_one_run` parameter avoids the need for special "before/after" regexes. If `match` stops matching, the resource is considered up-to-date.


---

# Puppet extended file line resource

ext_file_line derives from the original file_line resource found in the Puppet standard library (https://github.com/puppetlabs/puppetlabs-stdlib)

The main advantage compared to the original file_line is the ability to use regex backreferences in the line attribute.

Additionally, a diff of the changes applied (or what would when in noop mode) will be displayed.

This resource is generally useful when a specific file format is not supported by any of the Augeas lenses. It's also particularly handy when you do not want to manage the full content of files as templates in Puppet.

## Usage
A typical example would be something like the following:

```
$value = "yes"
ext_file_line {"nscd_enable_cache_passwd":
  path => "/etc/nscd.conf",
  line => "\\1$value",
  match => '^(.*?enable-cache.*?passwd.*?)(yes|no)$';
}
```

## Contact
Matteo Cerutti - matteo.cerutti@hotmail.co.uk
