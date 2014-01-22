#r509-ca-http

r509-ca-http is an HTTP server that runs a certificate authority, for signing SSL certificates. It supports issuance and revocation, and is intended to be part of a complete certificate authority for use in production environments.

##Requirements/Installation

You need r509 and sinatra. For development/tests you need rack-test and rspec.

## API

### GET /1/crl/:ca/get

Deprecated; will be removed in a future version. Use generate instead.


### GET /1/crl/:ca/generate

Generate and get a new CRL for the given ```:ca```.

### POST /1/certificate/issue

Issue a certificate.

Required POST parameters:

- ca
- profile
- validityPeriod (in days)
- csr (or spki)
- subject

The subject is provided like so:

    subject[CN]=domain.com&subject[O]=orgname&subject[L]=locality

Optional POST parameters:

- extensions[subjectAlternativeName]
- message\_digest

SAN names are provided like so:

    extensions[subjectAlternativeName][]=domain1.com&extensions[subjectAlternativeName][]=domain2.com

The issue method will return the PEM text of the issued certificate.

Please note that all fields subject/extension request fields encoded in a CSR are ignored in favor of the POST parameters.

### POST /1/certificate/revoke

Revoke a certificate.

Required POST parameters:

- ca
- serial

Optional POST parameters:

- reason (must be an integer or nil. nil by default)

The revoke method returns the newly generated CRL, after revocation.

### POST /1/certificate/unrevoke

Unrevoke a certificate. (IE, remove it from the CRL and return its OCSP status to valid.)

Required POST parameters:

- ca
- serial

The unrevoke method returns the newly generated CRL, after the certificate was removed from it.

## Helper pages

These pages are present on the server, for you to work with the CA with a basic web interface. You should _not_ expose these endpoints to anyone.

- /test/certificate/issue

- /test/certificate/revoke

- /test/certificate/unrevoke

## certificate\_authorities (config.yaml)

You use the ```config.yaml``` file to specify information about your certificate authority. You can operate multiple certificate authorities, each of which can have multiple profiles, with one instance of r509-ca-http.

Information about how to construct the YAML can be found at [the official r509 documentation](https://github.com/reaperhulk/r509).

## Middleware (config.ru)

Running r509-ca-http will let you issue and revoke certificates. But that's not everything you need to do, if you're going to run a CA. You're going to need information about validity, and you may want to save a record of issued certificates to the filesystem.

For that, we've created a few pieces of Rack middleware for your use.

- [r509-middleware-validity](https://github.com/sirsean/r509-middleware-validity)
- [r509-middleware-certwriter](https://github.com/sirsean/r509-middleware-certwriter)

After installing one or both of them, you'll have to edit your ```config.ru`` and/or ```config.yaml``` files.

##Support

You can file bugs on GitHub or join the #r509 channel on irc.freenode.net to ask questions.

## Rake tasks

There are a few things you can do with Rake.

```rake spec```

Run all the tests.

```rake gem:build```

Build a gem file.

```rake gem:install```

Install the gem you just built.

```rake gem:uninstall```

Uninstall r509-ca-http.

```rake yard```

Generate documentation.
