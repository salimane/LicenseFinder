License Finder
==============

[![Build Status](https://secure.travis-ci.org/pivotal/LicenseFinder.png)](http://travis-ci.org/pivotal/LicenseFinder)[![Code Climate](https://codeclimate.com/github/pivotal/LicenseFinder.png)](https://codeclimate.com/github/pivotal/LicenseFinder)

LicenseFinder works with your package managers to find dependencies, detect the licenses of the packages in them, compare those licenses against a user-defined whitelist, and give you an actionable exception report.

-	code: https://github.com/pivotal/LicenseFinder
-	support:
	-	license-finder@googlegroups.com
	-	https://groups.google.com/forum/#!forum/license-finder
-	backlog: https://www.pivotaltracker.com/s/projects/234851

### Supported project types

-	Ruby Gems (via `bundler`\)
-	Python Eggs (via `pip`\)
-	Node.js (via `npm`\)
-	Bower

### Experimental project types

-	Java (via `maven`\)
-	Java (via `gradle`\)
-	Objective-C (+ CocoaPods)

Installation
------------

The easiest way to use `license_finder` is to install it as a command line tool, like brew, awk, gem or bundler:

```sh
$ gem install license_finder
```

Though it's less preferable, if you are using bundler in a Ruby project, you can add `license_finder` to your Gemfile:

```ruby
gem 'license_finder', :group => :development
```

This approach helps you remember to install `license_finder`, but can pull in unwanted dependencies, including `bundler`. To mitigate this problem, see [Excluding Dependencies](#excluding-dependencies).

Usage
-----

The first time you run `license_finder` it will output a report of all your project's packages.

```sh
$ license_finder
```

Or, if you installed with bundler:

```sh
$ bundle exec license_finder
```

The output will report that none of your packages have been approved. Over time you will tell `license_finder` which packages are approved, so when you run this command in the future, it will report current action items; i.e., packages that are new or have never been approved.

If you don't wish to see progressive output "dots", use the `--quiet` option.

If you'd like to see debugging output, use the `--debug` option. `license_finder` will then output info about packages, their dependencies, and where and how each license was discovered. This can be useful when you need to track down an unexpected package or license.

Run `license_finder help` to see other available commands, and`license_finder help [COMMAND]` for detailed help on a specific command.

### Activation

`license_finder` will find and include packages for all supported languages, as long as that language has a package definition in the project directory:

-	`Gemfile` (for `bundler`\)
-	`requirements.txt` (for `pip`\)
-	`package.json` (for `npm`\)
-	`pom.xml` (for `maven`\)
-	`build.gradle` (for `gradle`\)
-	`bower.json` (for `bower`\)
-	`Podfile` (for CocoaPods)

### Continuous Integration

`license_finder` will also return a non-zero exit status if there are unapproved dependencies. This can be useful for inclusion in a CI environment to alert you if someone adds an unapproved dependency to the project.

Configuration
-------------

`license_finder` looks for the file in `config/license_finder.yml` for its configuration. It should be a valid YAML formatted config file. This file must be committed to version control. It has multiple sections

### Project Name

```yaml
project_name: ProjectName
```

This specifies which project name to set at the top of the reports.

### Gradle Command

```yaml
gradle_command: gradle
```

This is only meaningful if used with a Java/gradle project. Defaults to "gradle".

### Whitelisting

Approving packages one-by-one can be tedious. Usually your business has blanket policies about which packages are approved. To tell `license_finder` that any package with the MIT license should be approved, update your configuration file `config/license_finder.yml` with:

```yaml
whitelist:
  'MIT':
```

Any current or future packages with the MIT license will be excluded from the output of `license_finder`.

You can also add `who`, `why` and `when` when changing the whitelist, or making any other config about your project.

```yaml
whitelist:
  'MIT':
    who: 'CTO'
    why: 'Reason'
    when: 2015-01-01
```

When `license_finder` reports that a dependency's license is 'other', you should manually research what the actual license is. When you have established the real license, you can specify it with:

```yaml
whitelist:
  'MIT':
    include:
      my_unknown_dependency:
        who: 'CTO'
        why: 'Reason'
        when: 2015-01-01
```

This command would assign the MIT license to the dependency `my_unknown_dependency`.

### Approving Dependencies

Whenever you have an unapproved dependency, `license_finder` will tell you. If your business decides that this is an acceptable risk, update your configuration file `config/license_finder.yml` to specify so.

For example, let's assume you've added the `awesome_gpl_gem` to your Gemfile, which `license_finder` reports is unapproved:

```sh
$ license_finder
Dependencies that need approval:
awesome_gpl_gem, 1.0.0, GPL
```

Your business tells you that in this case, it's acceptable to use this gem. You now run:

```yaml
approvals:
  awesome_gpl_gem:
```

If you rerun `license_finder`, you should no longer see `awesome_gpl_gem` in the output.

To record who approved the dependency and why:

```yaml
approvals:
  awesome_gpl_gem:
    who: 'CTO'
    why: 'Reason'
    when: 2015-01-01
```

### Excluding Dependencies

Sometimes a project will have development or test dependencies which you don't want to track. You can exclude theses dependencies by doing the following: (Currently this only works for Bundler.)

```yaml
ignore_groups:
  development:
```

On rare occasions a package manager will report an individual dependency that you want to exclude from all reports, even though it is approved. Think carefully before adding dependencies to this list. A likely item to exclude is `bundler`, since it is a common dependency whose version changes from machine to machine. Adding it to the `ignored_dependencies` would prevent it (and its oscillating versions) from appearing in reports.

```yaml
ignore_dependencies:
  xpath:
```

### Example Configuration

As an example, `config/license_finder.yml` might look like this:

```yaml
default_approval: &default_approval
  who: 'WHO'
  why: 'REASON'
  when: 2015-01-01

project_name: ProjectName
gradle_command: # only meaningful if used with a Java/gradle project. Defaults to "gradle".
whitelist:
  'BSD':
    <<: *default_approval
  'MIT':
    <<: *default_approval
    include:
      rake:
        <<: *default_approval
approvals:
  rb-fchange:
    who: 'ANOTHER_WHO'
    why: 'ANOTHER_REASON'
    when: 2015-01-01
ignore_groups:
  development:
    <<: *default_approval
ignore_dependencies:
  xpath:
    <<: *default_approval
    when: 2015-01-02
```

### Output from `action_items`

You could expect `license_finder`, which is an alias for `license_finder
action_items` to output something like the following on a Rails project where MIT had been whitelisted:

```
Dependencies that need approval:

highline, 1.6.14, ruby
json, 1.7.5, ruby
mime-types, 1.19, ruby
rails, 3.2.8, other
rdoc, 3.12, other
rubyzip, 0.9.9, ruby
xml-simple, 1.1.1, other
```

### Output from `report`

The `license_finder report` command will output human-readable reports that you could send to your non-technical business partners, lawyers, etc. You can choose the format of the report (text, csv, html or markdown); see`license_finder --help report` for details. The output is sent to STDOUT, so you can save the reports wherever you want them. You can commit them to version control if you like.

The HTML report generated by `license_finder report --format html` summarizes all of your project's dependencies and includes information about which need to be approved. The project name at the top of the report can be set with`license_finder project_name add`.

### Gradle Projects

You need to install the license gradle plugin:[https://github.com/hierynomus/license-gradle-plugin](https://github.com/hierynomus/license-gradle-plugin)

LicenseFinder assumes that gradle is in your shell's command path and can be invoked by just calling `gradle`. If you must invoke gradle some other way (e.g., with a custom `gradlew` script), pass `--gradle_command` to `license_finder` or `license_finder report`.

By default, `license_finder` will report on gradle's "runtime" dependencies. If you want to generate a report for some other dependency configuration (e.g. Android projects will sometimes specify their meaningful dependencies in the "compile" group), you can specify it in your project's `build.gradle`:

```
// Must come *after* the 'apply plugin: license' line

downloadLicenses {
  dependencyConfiguration "compile"
}
```

Requirements
------------

`license_finder` requires ruby >= 1.9, or jruby.

Upgrading
---------

To upgrade from `license_finder` version ~1.2 to 2.0, see[`license_finder_upgrade`](https://github.com/mainej/license_finder_upgrade)\.

A Plea to Package Authors and Maintainers
-----------------------------------------

Please add a license to your package specs! Most packaging systems allow for the specification of one or more licenses.

For example, Ruby Gems can specify a license by name:

```ruby
Gem::Specification.new do |s|
  s.name = "my_great_gem"
  s.license = "MIT"
end
```

And save a `LICENSE` file which contains your license text in your repo.

Support
-------

-	Send an email to the list: [license-finder@googlegroups.com](license-finder@googlegroups.com)
-	View the project backlog at Pivotal Tracker: [https://www.pivotaltracker.com/s/projects/234851](https://www.pivotaltracker.com/s/projects/234851)

Contributing
------------

-	Fork the project from https://github.com/pivotal/LicenseFinder
-	Create a feature branch.
-	Make your feature addition or bug fix. Please make sure there is appropriate test coverage.
-	Rebase on top of master.
-	Send a pull request.

To successfully run the test suite, you will need node.js, python, pip and gradle installed. If you run `rake check_dependencies`, you'll see exactly what you're missing.

You'll need a gradle version >= 1.8.

For the python dependency tests you will want to have virtualenv installed, to allow pip to work without sudo. For more details, see this [post on virtualenv](http://hackercodex.com/guide/python-development-environment-on-mac-osx/#virtualenv).

If you're running the test suite with jruby, you're probably going to want to set up some environment variables:

```
JAVA_OPTS='-client -XX:+TieredCompilation -XX:TieredStopAtLevel=1' JRUBY_OPTS='-J-Djruby.launch.inproc=true'
```

License
-------

LicenseFinder is released under the MIT License. http://www.opensource.org/licenses/mit-license
