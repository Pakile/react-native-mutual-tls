# react-native-mutual-tls

Mutual TLS authentication for HTTP requests in React Native.

The client certificate and associated password are stored securely in the native Keychain.

Once the module is set up, it applies to all normal react-native HTTP requests (e.g. through `fetch`, `XMLHttpRequest`, or any library that uses these) for HTTPS connections that ask for a client certificate. There is no overhead for connections that do not request a client certificate.

Only iOS is supported at this time, but pull requests are welcome if anyone wants to help add support for Android.

## Getting started

Install it as a dependency for your react-native project. You'll probably also need the native module for `Keychain` unless you have some other way of getting the secrets into the keychain:

```sh
yarn add react-native-mutual-tls
yarn add react-native-keychain
npx pod-install
```

## Prerequisites

In order to use this module, you'll need a client certificate encoded as a `p12` file, encrypted with a password.

The [example project in this repository](./example) uses [this test certificate from `badssl.com`](https://badssl.com/download/), but you'll need to provide your own.

The certificate and password are expected to be loaded into the native Keychain at runtime, because it's considered bad practice to hard-code them or embed them as static resources in your app bundle. You'll need to expect the user to supply these, or download them at runtime from some secure source.

## Usage

Import the `MutualTLS` module, as well as the `Keychain` module.

```javascript
import MutualTLS from 'react-native-mutual-tls';
import Keychain from 'react-native-keychain';
```

Optionally, set up debug information and errors from this module to go to the console for troubleshooting purposes. You could also provide different functions here if you wanted to do something else with the events.

If you don't do this, there will be no logging of such events.

```javascript
MutualTLS.onDebug(console.debug);
MutualTLS.onError(console.error);
```

Before making a request, you'll need to load the secrets into the `Keychain`.

Refer to [the documentation for the `Keychain` module](https://github.com/oblador/react-native-keychain) for more information about managing secrets in the keychain, how to clear the secrets, and how to check whether the secrets are already loaded to avoid doing work to load them every time the app starts.

```javascript
const myP12DataBase64 = "YOUR P12 FILE ENCODED AS BASE64 GOES HERE";
const myPassword = "THE PASSWORD TO DECRYPT THE P12 FILE GOES HERE";

await Promise.all([
  Keychain.setGenericPassword('', myP12DataBase64, { service: "my-tls.client.p12" }),
  Keychain.setGenericPassword('', myPassword, { service: "my-tls.client.p12.password" }),
]);
```

Next you need to call `MutualTLS.configure` to tell the module where to find the secrets in the keychain.

`MutualTLS` will not pre-load the secrets when configured - they will be loaded on the fly each time they are needed by an authentication challenge, so there is no need to call `MutualTLS.configure` more than once even if the secret values change.

If you do not call `MutualTLS.configure`, then the following defaults are used:
- `keychainServiceForP12`: `mutual-tls.client.p12`
- `keychainServiceForPassword`: `mutual-tls.client.p12.password`

```javascript
// Use the same service names that were used in `Keychain.setGenericPassword`
await MutualTLS.configure({
  keychainServiceForP12: 'my-tls.client.p12',
  keychainServiceForPassword: 'my-tls.client.p12.password',
});
```

Assuming you've done all that setup, then you're ready to make secure Mutual TLS requests with a server that is configured to trust the client certificate you provided.

As stated before, any normal react-native HTTP request (e.g. through `fetch`, `XMLHttpRequest`, or any library that uses these) for HTTPS connections that ask for a client certificate will work, with no special options needed at request time.

```javascript
const response = await fetch('https://my-secure.example.com/');
```

To see and run a fully working demonstration using `https://client.badssl.com/` as the test server, see [the example project in this repository](./example).
