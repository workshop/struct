# Xcodegen
[![Latest Gem Release](https://img.shields.io/gem/v/xcodegen.svg)](https://rubygems.org/gems/xcodegen) 
[![Git Version](https://img.shields.io/github/tag/lyptt/xcodegen.svg)](https://github.com/lyptt/xcodegen/releases/tag/0.1.2) 
[![Git Version](https://img.shields.io/github/commits-since/lyptt/xcodegen/0.1.2.svg)](https://github.com/lyptt/xcodegen/commits/master)

Xcodegen comes in two parts - a file watcher that auto-generates
a project based on a simple project specification written in YAML or JSON, and options to assist in adding 
new files and targets to your dynamic project.

Project files are automatically included into the project from a source directory,
with Swift files going into the compilation phase, and everything else going to the
resource phase, so there's no IDE fiddling necessary.

Xcodegen can take a project spec like this:

```yaml
---
version: 1.0.0
configurations:
  debug:
    profiles:
    - general:debug
    - ios:debug
  release:
    profiles:
    - general:release
    - ios:release
targets:
  MyApp:
    sources: src
    i18n-resources: res
    platform: ios
    type: ":application"
    configuration:
      ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
      INFOPLIST_FILE: Info.plist
      PRODUCT_BUNDLE_IDENTIFIER: uk.lyptt.MyApp
```

And transform it into a fully formed Xcode project.

You can find a documented example of the project specification in the examples folder.

## Installation

To install from a checked out version of this gem, run:

    $ bundle install

Then run:

    $ rake install && gem install --local pkg/path-to-gem.gem
    
Or install it directly from rubygems by running:

    $ gem install xcodegen
    
## Usage

To generate an Xcode project from your spec file, run the following from your project directory:

    $ xcodegen --generate

To start the file watcher, run the following from your project directory:

    $ xcodegen --watch
    
The project will be automatically regenerated whenever the project or any source files change.

![usage example](https://github.com/lyptt/xcodegen/raw/master/readme_files/usage_example.gif)

## To do

Xcodegen is still under development, so it's not yet feature complete. Notable features missing include:
- Project generation support for subproject dependencies
- Project generation support for subproject linking
- Project generation support for file exclusion globs
- CLI support for generating common files and targets

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lyptt/xcodegen.