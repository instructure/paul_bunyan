# Logging

Logging is a re-usable component with a globally accessible Logger, e.g.

```
include Logging::Logger
logger.warn "blah"
```

## Installation

Add this line to your application's Gemfile:

    gem 'logging'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install logging

## Usage

```
require 'logging'

include Logging::Logger

Logging.set_logger(options[:logger])

logger.warn "blah"
```
