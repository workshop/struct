# Xcodegen


Xcodegen comes in two parts - a file watcher that auto-generates
a project based on a simple YAML specification that targets a
dynamic source files directory, and options to assist in adding
new files and targets to your dynamic project.

## Installation

To install from a checked out version of this gem, run:

    $ bundle install

Then run:

    $ rake install && gem install --local pkg/path-to-gem.gem
    
Or install it directly from rubygems by running:

    $ gem install xcodegen

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lyptt/xcodegen.