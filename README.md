# GraphQL Converter
A way to make graphql types safe accross services.

## Motivation
### Why?

GraphQL is pretty great. It allows us to create and maintain strict contracts
between the backend and frontend. The backend exposes a set of queries and
mutations with GraphQL types that come with a set of queryable fields -- with
types and validation!

However... things can get messy and complicated pretty easily when you start
considering services. Data might live on multiple different services, and not
every service knows every detail about a piece of data. Some services use REST,
and some have custom endpoints that return the same data in different shapes.

In the end, this can eliminate the benefits we get from GraphQL. When we make a
request from the frontend for a particular piece of data, we expect that the
contract defined by our GraphQL schema to be accurate, but when our services
return data in unpredictable ways, we lose those guarentees.

### How?

GraphQL Converter attempts to solve this issue by allowing you to create
_converters_ that can convert data from one shape to another! There are two
types of converters: the `BaseConverter` and the `BaseHashConverter`.

* `BaseConverter` converts an object of one type to another.
* `BaseHashConverter` converts a hash to an object.

## Usage
### Installation

You can simply add `graphql_converter` to your Gemfile:

```
source 'http://gems.ncsasports.org'

gem "graphql_converter"
```

## Examples
### 1.1 Using `BaseConverter`

Let's say we're trying to setup converters for the following `AthleteType`:
```ruby
module Types
  class AthleteType < Types::BaseObject
    field :client_id, ID, null: false
    field :name, String, null: false
    field :height, Int, null: true
    field :weight, Int, null: true
    field :profile_image, String, null: true
  end
end
```

So far this is just your regular ruby GraphQL type definition. In our ruby
application this will eventually get called through a query or mutation, and at
that point it'll get passed a single `Athlete` active record object (assuming
you're using rails). This might look something like this:

```ruby
def athlete(client_id:)
  Client.find(client_id)
end
```

When that happens, all the fields included in our query will be called against
that object (i.e. `athlete.client_id`, `athlete.name`, etc.).

Let's say that the field `profile_image` isn't directly on the `athlete` object,
but is instead accessible through some relation. Typically in GraphQL could
solve this by: (1) creating types for each of the relations leading to that
particular piece of data, or (2) creating a resolved in the type definition
that performs those calls. While solving this with option (1) is arguably more
correct, we will often go with (2) and simply create a resolver method.

If we're using GraphQL Converter, then our goal will be to keep our `Type`
definition as simple as possible, and instead create a converter that
implements these resolvers. So, for the example above we can create the
following converter:

```ruby
require "graphql_converter/base_converter"

module Converters
  class AthleteActiveRecordConverter < ::GraphQLConverter::BaseConverter
    type_class Types::AthleteType

    def profile_image
      object.client_photo.image.url(:profile)
    end
  end
end

```

The main thing to notice is the DSL method `type_class` that passes
`Types::AthleteType` to our converter class. Providing this type allows the
converter to know which fields are defined and determine how to resolve them.

With our converter defined, we'll also need to change the instances where
GraphQL is receiving an active record object to use the converter instead:

```ruby
def athlete(client_id:)
  client = Client.find(client_id)
  Converters::AthleteActiveRecordConverter.new(client).result
end
```

### 1.2 Using `BaseHashConverter`

Now, let's say that somewhere else in our application we're fetching data from
an external service, and we want to return that data through GraphQL. In order
to accomodate this, we'll need a `BaseHashConverter`.

The `BaseHashConverter` does the following:
1. Takes a hash with keys matching the fields defined in the corresponding
  GraphQL type
2. Returns the values from that hash if they are present in the hash and were
  requested by the GraphQL request
3. Falls back to a `base_converter` if a requested field is not present in the
  provided hash

Luckily this is quite simple to set up!

```ruby
require "graphql_converter/base_hash_converter"

module Converters
  class AthleteHashConverter < ::GraphQLConverter::BaseHashConverter
    type_class Types::AthleteType

    def client
      @_client ||= Client.find(object[:client_id])
    end

    def base_converter
      @_base_converter ||= AthleteActiveRecordConverter.new(client, context)
    end
  end
end

```

Similar to the `BaseConverter` example from above, we still need to provide the
desired output type with the `type_class` method.

However, we are now also required to define a `base_converter` method. In this
example we're using the previously defined `AthleteActiveRecordConverter` and
passing it a `client` based off of the provided hash.

Finally, when we're ready to use this converter, we can consume it as follows:

```ruby
data = method_that_requests_particular_athlete_data
Converters::AthleteHashConverter.new(
  client_id: data[:client_id],
  name: data[:name]
).result
```

You can see that the hash we provided doesn't contain all the fields we defined
in our `Types::AthleteType`. Despite that, the hash converter will know how to
find the requested data, first checking the provided hash and then falling back
to the bash converter.
