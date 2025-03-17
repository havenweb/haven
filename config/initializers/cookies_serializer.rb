# Be sure to restart your server when you modify this file.

# Specify a serializer for the signed and encrypted cookie jars.
# Valid options are :json, :marshal, and :hybrid.

# If you're upgrading and haven't set `cookies_serializer` previously, your cookie serializer
# is `:marshal`. The default for new apps is `:json`.
#
# To migrate an existing application to the `:json` serializer, use the `:hybrid` option.
#
# Rails transparently deserializes existing (Marshal-serialized) cookies on read and
# re-writes them in the JSON format.
#
# It is fine to use `:hybrid` long term; you should do that until you're confident *all* your cookies
# have been converted to JSON.
Rails.application.config.action_dispatch.cookies_serializer = :hybrid
