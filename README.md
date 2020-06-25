![Struct logo](https://s3.eu-central-1.amazonaws.com/struct.tools/images/StructLogo_Colour_Headline.png)

# Struct
[![Latest Gem Release](https://img.shields.io/gem/v/struct.svg)](https://rubygems.org/gems/struct) 
[![Git Version](https://img.shields.io/github/tag/lyptt/struct.svg)](https://github.com/lyptt/struct/releases/tag/4.0.1)
[![Git Version](https://img.shields.io/github/commits-since/lyptt/struct/4.0.1.svg)](https://github.com/lyptt/struct/commits/master)
[![Build status](https://api.travis-ci.org/lyptt/struct.svg?branch=master)](https://travis-ci.org/lyptt/struct)
[![Coverage Status](https://coveralls.io/repos/github/lyptt/struct/badge.svg)](https://coveralls.io/github/lyptt/struct)
[![Help Contribute to Open Source](https://www.codetriage.com/lyptt/struct/badges/users.svg)](https://www.codetriage.com/lyptt/struct)

# Introduction

`struct` is a tool for iOS and Mac developers to automate the creation and management of Xcode projects.

Ever lamented over your unorganised project files? `struct` solves that by _making your filesystem be your project structure_. How it is on disk is how it is in your project. Simple.

Need to have multiple variants of a project depending on how you're distributing to your customers? `struct`'s got you covered with target variants. Now you get a project for each variant, with the ability to add additional source files and resources. Great for whitelabelling and multiple distribution channels!

`struct` makes working with Xcode easy. You get simple, predictable project files that any developer can understand. Just treat your Xcode projects as a build artifact and feel the weight lift off your shoulders.

Use a spec file to define your project:

```yaml
---
version: 3.0.0
configurations:
  debug:
  release:
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

Then just run `struct generate` and `struct` will do the rest.

You can find documented examples of the project specification in the examples folder.

## Installation

`struct` requires a minimum of Ruby 2.6.3, which is available in macOS Catalina.
You can install a higher version of Ruby with [RVM](https://rvm.io/) on an older macOS version.

Install `struct` from Rubygems:

_You may need to use sudo when using the system-provided Ruby_

    $ gem install struct

## Quick Start

Get started with adding `struct` to your app:

[Create your first spec file](https://github.com/lyptt/struct/wiki/Quick-Start)

## Available Commands

To generate an Xcode project from your spec file, run the following from your project directory:

    $ struct generate

To start the file watcher, run the following from your project directory:

    $ struct watch
    
The project will be automatically regenerated whenever the project or any source files change.

Other commands can be discovered by viewing help:

    $ struct help

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lyptt/struct.
