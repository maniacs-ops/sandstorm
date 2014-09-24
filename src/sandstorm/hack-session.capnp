# Sandstorm - Personal Cloud Sandbox
# Copyright (c) 2014 Sandstorm Development Group, Inc. and contributors
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

@0xbf6889795837d1e0;
# This file defines some hacks added on top of the grain session protocol designed to expose some
# basic ways to communicate with the outside world (such as e-mail) without requiring persistent
# capabilities nor the Powerbox (which will take some time to implement). Once the Powerbox is
# available, these hacks should go away. Consider them pre-deprecated.

$import "/capnp/c++.capnp".namespace("sandstorm");

using Grain = import "grain.capnp";
using Email = import "email.capnp";

interface HackSessionContext @0xe14c1f5321159b8f
    extends(Grain.SessionContext, Email.EmailSendPort) {
  # The SessionContext passed to a grain when newSession() is called is actually of type
  # HackSessionContext. This is the case both when opening HackEmailSessions (below) and regular
  # WebSessions.

  getPublicId @0 () -> (publicId :Text, hostname :Text, autoUrl :Text, isDemoUser :Bool);
  # Get the grain's public ID, assigning one if it isn't already assigned. The public ID is used
  # as the e-mail address and for serving static content.
  #
  # If `autoUrl` is non-null, it is an automatically-assigned URL at which the grain's public
  # web content is already visible.
  #
  # If `isDemoUser` is true, the user is a temporary demo account. In this case the app probably
  # should *not* suggest setting up DNS because the grain will disappear soon anyway. (Also our
  # main demo server doesn't support web publishing to arbitrary domains due to sharing an IP
  # address with the alpha server.)
  #
  # Warning: Allocating a public ID means that the /var/www and /var/mail directories become
  #   special. Do not create these directories unless you intend for them to serve their respective
  #   purposes.

  httpGet @1 (url: Text) -> (mimeType :Text, content :Data);
  # Perform a simple HTTP GET request, returning the content. Note that this hack is especially
  # temporary because it allows apps to trivially leak data. Longer-term, we want the user to
  # explicitly approve communications with external servers. However, since we don't have the
  # infrastrucutre for that yet, and we really want an RSS reader on Sandstorm, we're temporarily
  # adding this. As of this writing, it's possible to issue arbitrary HTTP requests from the client
  # side anyway.
  #
  # This interface is very limited currently -- e.g. it does not support arbitrary headers, POSTs,
  # etc. If you need any of these things, talk to the Sandstorm developers and we'll consider
  # adding some more hacks, but, again, this will all go away once the Powerbox is implemented.

  getUserAddress @2 () -> Email.EmailAddress;
  # Returns the address of the user logged into Sandstorm

  generateApiToken @3 () -> (token :Text, endpointUrl :Text, userInfo :Grain.UserInfo);
  # Generates a new API token which can be used to access an HTTP API exported by this application.
  # The method also returns the URL at which the API is exported.
  #
  # To access the API, a client may send requests to `endpointUrl` (or sub-paths thereof) and pass
  # the following header, replacing <token> with the returned `token`:
  #
  #     Authorization: Bearer <token>
  #
  # To handle such a request, Sandstorm will open a new session of type `HackHttpApiSession`.
  #
  # `userInfo` contains the `UserInfo` struct which should be passed back to the application
  # verbatim when this token is used. There is no need to fill this struct with accurate
  # information as it will only be passed back to the app. You are encouraged to replace the
  # `userId` field with some sort of token that grants a narrow permission rather than use an
  # actual user's ID. This is a temporary hack. Eventually, when we have persistent Cap'n Proto
  # capabilities, we will not use `newSession()` with capability tokens; we will persist and
  # restore the WebSession capability instead.
}

interface HackEmailSession @0xc3b5ced7344b04a6 extends(Grain.UiSession, Email.EmailSendPort) {
  # UiView.newSession() may be called with this type as the session type in order to deliver
  # SMTP instead of HTTP requests. Of course, this doesn't actually implement a UI at all; it is
  # abusing the UI session API only because the correct way to open non-UI communications
  # channels -- i.e. persistent capabilities and Powerbox interactions -- is not implemented.
}
