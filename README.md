# react-native-mutual-tls

Mutual TLS authentication for HTTP requests in React Native.

Only iOS is supported at this time, but pull requests are welcome if anyone wants to help add support for Android.

## Getting started

Install it as a dependency for your react-native project:

```
yarn add react-native-mutual-tls
npx pod-install
```

In XCode project settings, in the "Build Phases" section, in the "Copy Bundle Resources" phase, add your certificate file(s). The `example` folder in this project uses a client certificate downloaded from the [BadSSL testing website](https://badssl.com/download/), but you should use whatever client certificate that your server is expecting.

## Usage
```javascript
import MutualTLS from 'react-native-mutual-tls';

// TODO: What to do with the module?
MutualTLS;
```
