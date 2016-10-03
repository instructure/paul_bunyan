[![Gem Version](https://badge.fury.io/rb/paul_bunyan.svg)](https://rubygems.org/gems/paul_bunyan)

# Paul Bunyan (formerly: Logging)

[![Build Status](https://secure.travis-ci.org/instructure/paul_bunyan.png)](http://travis-ci.org/instructure/paul_bunyan)

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
goodness. This has been tested with Rails 4.2 but should compatible with
Rails 3 or newer since that's when Railties were introduced.

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
