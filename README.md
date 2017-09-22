# Paul Bunyan (formerly: Logging)

[![Gem](https://badge.fury.io/rb/paul_bunyan.svg)](https://rubygems.org/gems/paul_bunyan)
[![Build Status](https://secure.travis-ci.org/instructure/paul_bunyan.svg)](http://travis-ci.org/instructure/paul_bunyan)
[![Dependency Status](https://gemnasium.com/badges/github.com/instructure/paul_bunyan.svg)](https://gemnasium.com/github.com/instructure/paul_bunyan)

PaulBunyan is a re-usable component with a globally accessible Logger with extra
support for handling logging in Rails.

```
class Foo
  include PaulBunyan

  def bar
    logger.warn "blah"
  end
end
```

Also included is a Railtie that overrides the default rails logger to always
print to STDOUT as well as format the messages to JSON for machine readable
goodness. This has been tested with Rails 4.2 through 5.1, older versions of
Rails may work but are not guaranteed to and will not receive support.

## Installation

Add this line to your application's Gemfile:

    gem 'paul_bunyan'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paul_bunyan

## Usage

### Non-Rails projects:

```
require 'paul_bunyan'

include PaulBunyan::Logger

PaulBunyan.set_logger(STDOUT)

logger.warn "blah"
```

### Rails projects:

Nothing after it's added to your Gemfile, the Railtie takes care of the rest.

### Adding metadata to JSON logs
The default logger includes the ability to accept arbitrary metadata, the
primary use case for this functionality is to add context to log lines generated
in the course of processing a Rails request. There is an example for adding
the request host to the metadata in the examples directory. There are a few
keys that are used internally that will be overwritten when added to user
supplied metadata, this list can be found in the `#call` method of
`PaulBunyan::JSONFormatter`.
